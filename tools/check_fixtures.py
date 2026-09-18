#!/usr/bin/env python3
"""Fixture gate: every JSON example parses, every Mermaid block is structurally
whole.

A JSON example in the specification is a test input, not an illustration: an
implementation's tests read the delivery declaration's examples as documents.
An example with a `...` placeholder, a repeated object member, or a syntax
error is one no implementation can use, and nothing else notices, because the
Markdown renders it fine.

Mermaid renders on GitHub but there is no offline parser here, so a diagram
broken in source looks fine in source and fails in the browser. This is a
structural sanity check, not a parser: it catches the errors that actually
happen -- a block declaring no diagram type, unbalanced brackets or quotes in
a label, an edge with nothing on one end, a `subgraph` (or a sequence
diagram's `loop`, `alt`, ...) never closed by `end`.

Ported from provisiond-spec and adapted: no timestamp or integer-bound rules,
which were that corpus's wire profile; the digest and fingerprint shapes are
this corpus's (a 64-hex sha256; Robot's MD5 colon-hex or SHA256 base64
fingerprint).

NOT CAUGHT, or caught wrongly, stated because a gate's limits are part of its
contract: a `---` front-matter block reads as a dangling edge and a missing
diagram type; an asymmetric node shape (`A>flag]`) reads as an unbalanced
bracket; a node whose id is a block opener (`alt`, `box`) reads as an unclosed
block. None of the corpus's diagrams uses these; the first that does extends
the check.

Scanned for JSON: the root documents, `docs/design/` and the tenant profiles.
Scanned for Mermaid: those, the decision records and the review records.

Exit 0 = clean, 1 = failures.
"""

import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_ids import ROOT, files  # noqa: E402

JSON_FILES = ["*.md", "docs/design/*.md", "docs/tenants/*/profile.md"]
MERMAID_FILES = JSON_FILES + ["docs/adr/*.md", "docs/review/*.md"]

JSON_RE = re.compile(r"^```json\s*\n(.*?)^```", re.M | re.S)
MERMAID_RE = re.compile(r"^```mermaid\s*\n(.*?)^```", re.M | re.S)

HEX64 = re.compile(r"[0-9a-f]{64}")
FINGERPRINT = re.compile(r"(?:[0-9a-f]{2}:){15}[0-9a-f]{2}|(?:SHA256:)?[A-Za-z0-9+/]{43}")

MERMAID_KINDS = (
    "flowchart", "graph", "sequenceDiagram", "stateDiagram-v2", "stateDiagram",
    "erDiagram", "classDiagram", "journey", "gantt", "pie", "mindmap", "timeline",
)
# An edge arrow: `-->`, `-.->`, `==>`, `<-->`, `->>`, `-->>`, `-x`, `-)`, `--o`.
ARROW = r"<?(?:-\.-+[>xo)]?>?|-{2,3}[>xo)]?>?|={2,3}>?|-[>x)]>?)"
# An arrow with nothing on its left, or nothing (bar an edge label) on its right.
DANGLING_RE = re.compile(r"^%s|%s\s*(?:\|[^|]*\|)?\s*$" % (ARROW, ARROW))
OPEN_RE = re.compile(r"^(?:subgraph|loop|alt|opt|par|critical|break|rect|box)\b")
# A state diagram's multi-line note holds prose, where a line may open with `--`.
NOTE_RE = re.compile(r"^note\s+(?:left|right) of\b[^:]*$")


def no_duplicate_keys(pairs):
    seen = {}
    for k, v in pairs:
        if k in seen:
            raise ValueError(f"duplicate object member {k!r}")
        seen[k] = v
    return seen


def walk(node, path, problems):
    if isinstance(node, dict):
        for k, v in node.items():
            walk(v, f"{path}.{k}", problems)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            walk(v, f"{path}[{i}]", problems)
    elif isinstance(node, str):
        key = path.rsplit(".", 1)[-1]
        if key.endswith(("sha256", "digest")) and not HEX64.fullmatch(node):
            problems.append(f"{path}: a sha256 digest is exactly 64 hex characters")
        if key.endswith("fingerprint") and not FINGERPRINT.fullmatch(node):
            problems.append(f"{path}: not an MD5 colon-hex or SHA256 base64 fingerprint")


def check_json():
    bad, count = [], 0
    for f in files(JSON_FILES):
        text = open(f).read()
        for m in JSON_RE.finditer(text):
            count += 1
            body, where = m.group(1), f"{f}:{text.count(chr(10), 0, m.start()) + 1}"
            if "..." in body:
                bad.append(f"{where}: contains a `...` placeholder")
                continue
            try:
                doc = json.loads(body, object_pairs_hook=no_duplicate_keys)
            except ValueError as e:
                bad.append(f"{where}: {e}")
                continue
            problems = []
            walk(doc, "$", problems)
            bad.extend(f"{where}: {p}" for p in problems)
    return bad, count


def check_mermaid():
    bad, count = [], 0
    for f in files(MERMAID_FILES):
        text = open(f).read()
        for m in MERMAID_RE.finditer(text):
            count += 1
            body, where = m.group(1), f"{f}:{text.count(chr(10), 0, m.start()) + 1}"
            lines = [line.strip() for line in body.splitlines()
                     if line.strip() and not line.strip().startswith("%%")]
            first = lines[0] if lines else ""
            if not first.startswith(MERMAID_KINDS):
                bad.append(f"{where}: declares no known diagram type (starts {first[:40]!r})")
            # erDiagram's crow's-foot notation (||--o{, }o--o|) uses braces as
            # syntax rather than as pairs, so brace balance is meaningless there.
            pairs = [("[", "]"), ("(", ")")] + ([] if first.startswith("erDiagram") else [("{", "}")])
            for o, c in pairs:
                if body.count(o) != body.count(c):
                    bad.append(f"{where}: unbalanced {o}{c} ({body.count(o)} vs {body.count(c)})")
            if body.count('"') % 2:
                bad.append(f"{where}: odd number of double quotes")
            in_note = False
            for line in lines[1:]:
                if NOTE_RE.match(line) or line == "end note":
                    in_note = NOTE_RE.match(line) is not None
                elif not in_note and DANGLING_RE.search(line):
                    bad.append(f"{where}: dangling edge {line!r}")
            opened = sum(1 for line in lines if OPEN_RE.match(line))
            closed = sum(1 for line in lines if line == "end")
            if opened != closed:
                bad.append(f"{where}: unclosed subgraph or block ({opened} opened, {closed} `end`)")
    return bad, count


def main():
    os.chdir(ROOT)
    bad_json, n_json = check_json()
    bad_mermaid, n_mermaid = check_mermaid()
    for b in bad_json + bad_mermaid:
        print(f"  {b}")
    print(f"json fixtures checked: {n_json} | mermaid diagrams checked: {n_mermaid}")
    print("BAD JSON:", bad_json or "none")
    print("BAD MERMAID:", bad_mermaid or "none")
    return 1 if (bad_json or bad_mermaid) else 0


if __name__ == "__main__":
    sys.exit(main())
