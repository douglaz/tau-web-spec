#!/usr/bin/env python3
"""Reject global comment identifier collisions in the tracked issue export.

Read JSONL directly, including closed issues. Occurrences use one-based positions
in each issue's comments array, so findings survive issue-record reordering and
retain repeated comments within one issue. No comment text is printed.

Exit 0 = distinct identifiers, 1 = collisions, 2 = cannot read identifiers.
"""

from collections import defaultdict
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
EXPORT = Path(".beads/issues.jsonl")


def duplicates(path):
    owners = defaultdict(list)
    with path.open(encoding="utf-8") as export:
        for line in export:
            if not line.strip():
                continue
            issue = json.loads(line)
            for position, comment in enumerate(issue.get("comments", []), start=1):
                identifier = comment["id"]
                if type(identifier) is not int:
                    raise TypeError("comment identifier must be an integer")
                owners[identifier].append((issue["id"], position))
    return sorted(((identifier, sorted(occurrences))
                   for identifier, occurrences in owners.items() if len(occurrences) > 1),
                  key=lambda group: json.dumps(group[0]))


def main():
    try:
        collisions = duplicates(ROOT / EXPORT)
    except (OSError, UnicodeError, json.JSONDecodeError, KeyError, TypeError, AttributeError):
        # Extraction failures must fail closed without echoing private record data.
        print(f"COMMENT EXPORT ERROR: {EXPORT}: cannot read comment identifiers")
        return 2
    if not collisions:
        print("DUPLICATE COMMENT IDS: none")
    for identifier, occurrences in collisions:
        owners = ", ".join(f"{json.dumps(issue)} comments[{position}]"
                           for issue, position in occurrences)
        print(f"DUPLICATE COMMENT IDS: {json.dumps(identifier)} -> {owners}")
    return 1 if collisions else 0


if __name__ == "__main__":
    sys.exit(main())
