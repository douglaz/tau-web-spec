#!/usr/bin/env python3
"""Reject local paths in the tracked issue export.

The export is public. `br create` records the absolute path of the checkout that made an
issue under `source_repo_path`; that path names one machine's layout and nothing any other
reader can use, so the key is refused on any record. Every string value of every record --
comments included -- is also read for a home-directory or scratch-directory path. Findings
name the issue and the field, never the value.

Exit 0 = no local path, 1 = local paths, 2 = cannot read the export.
"""

import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
EXPORT = Path(".beads/issues.jsonl")
KEY = "source_repo_path"
# A home directory or a scratch root followed by a name: "/home/alice", "/Users/alice",
# "/tmp/run.1", "/var/tmp/lane". The character before the slash must not continue a word or
# another path, so "lib/tmp/x" and "https://host/home/x" are not local paths of this machine.
# Two forms put a local path right after such a character and are read anyway: a label
# ("path:/home/alice", a colon with no slash before it) and a file URL ("file:///tmp/run",
# "file://localhost/tmp/run").
LOCAL = re.compile(r"(?:(?<![\w.~/:-])|(?<=(?<!/):)|(?i:(?<=file://)|(?<=file://localhost)))"
                   r"/(?:home|Users|var/tmp|tmp)/\w")


def walk(value, path, keyed, local):
    """Record the field path of every KEY (whatever its value) and of every string value
    holding a local path. A KEY's own value is not read again: one finding per field."""
    if isinstance(value, dict):
        for key, item in value.items():
            field = f"{path}.{key}" if path else key
            if key == KEY:
                keyed.append(field)
            else:
                walk(item, field, keyed, local)
    elif isinstance(value, list):
        for position, item in enumerate(value, start=1):
            walk(item, f"{path}[{position}]", keyed, local)
    elif isinstance(value, str) and LOCAL.search(value):
        local.append(path)


def findings(path):
    keyed, local = set(), set()
    with path.open(encoding="utf-8") as export:
        for line in export:
            if not line.strip():
                continue
            issue = json.loads(line)
            identifier = issue["id"]
            if type(identifier) is not str:
                raise TypeError("issue identifier must be a string")
            issue_keyed, issue_local = [], []
            walk(issue, "", issue_keyed, issue_local)
            keyed.update((identifier, field) for field in issue_keyed)
            local.update((identifier, field) for field in issue_local)
    return sorted(keyed), sorted(local)


def main():
    try:
        keyed, local = findings(ROOT / EXPORT)
    except (OSError, UnicodeError, json.JSONDecodeError, KeyError, TypeError, AttributeError):
        # Extraction failures fail closed without echoing record data.
        print(f"TRACKER EXPORT ERROR: {EXPORT}: cannot read the issue export")
        return 2
    if not keyed:
        print("SOURCE REPO PATH: none")
    for identifier, field in keyed:
        print(f"SOURCE REPO PATH: {json.dumps(identifier)} {field}")
    if not local:
        print("LOCAL PATH: none")
    for identifier, field in local:
        print(f"LOCAL PATH: {json.dumps(identifier)} {field}")
    return 1 if keyed or local else 0


if __name__ == "__main__":
    sys.exit(main())
