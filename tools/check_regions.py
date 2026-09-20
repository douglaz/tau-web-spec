#!/usr/bin/env python3
"""Rendering gate (ADR-0032): a marked region in a document is what its declaration emits.

ADR-0032 adopted provisiond-spec's formal layer and deferred this one check --- "This corpus
has no formalized table to render on the day of this decision; the gate is ported when the
first one exists". The first are `TauWeb.Declaration.row`, the field table of
`delivery-declaration-v1.md`, and `TauWeb.Allocation.row`, the role table of
`credential-format-v1.md`. Inside a marked region the declaration is authoritative and the
Markdown renders it; outside one the transitional rule holds and the Markdown is.

A region is the lines between two markers, each on a line of its own:

    <!-- formal: TauWeb.Render.roleTable -->
    | Role | ... |
    <!-- /formal -->

The name is a declaration `lake exe gate` indexed, so it is tagged with the requirement it
formalizes, and `lake exe render` emits its text. Two kinds:

  render  Pure computation --- a worked table, a diagram. Compared line for line. No region
          is of this kind yet, so nothing regenerates one; the first one brings `--write`
          with it rather than shipping a flag with nothing to do.

  match   A table whose cells carry prose and citations the declaration does not emit --- and
          in this corpus may never emit, since a `CNF` identifier never appears in anything
          the companion produces. The first column is the row's key: its emitted tokens must
          appear in the document's cell, in order. Every other column is compared on the
          tokens the declaration determines --- backticked and bold spans drawn from the
          vocabulary the emitted table uses --- and those must match exactly. A row's
          rationale is free; its outcome is not. A `match` region holds the table and nothing
          else: a line that is not a table row is refused.

Placement. provisiond requires a region to sit inside the requirement its declaration is
tagged with. Here a normative companion under `docs/design/` carries the table and the
requirement points at it (`ARC-39`, `STA-22a`), so a region may also sit in a document that
requirement's body links --- resolved from the Markdown, with no hand-kept map. The test is
directional: another document linking the same file grants nothing.

WHAT THIS DOES NOT CATCH, stated because a gate's limits are part of its contract:
the header row, which is never compared, so a column's title may say anything; prose in a
cell that contradicts the token beside it ("an empty list means nothing to check" written
next to `**nothing may**`); and a key token that is a required *subsequence* rather than an
exclusive identity, so a cell holding `` `9` `` and `` `0` `` still satisfies an emitted key
of `` `0` ``. The first two are why the Presence rule names this table's column instead of
restating its fields.

Reads what `tools/check_formal.sh` writes, so `check-all.sh` runs that gate first. A missing
emission is a red gate, not a skipped one (`AGENTS.md`).

Exit 0 = every region is what its declaration emits, 1 = a finding, 2 = the emission is
missing.
"""

import difflib
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_ids import DEF_RE, POINTER_RE, ROOT, files  # noqa: E402
from check_citations import owners, read_index  # noqa: E402  -- one index and body reader, not two
from check_witnesses import CNF  # noqa: E402  -- one spelling of the conformance prefix

REGIONS = os.path.join(ROOT, "tools", "formal", ".lake", "regions.jsonl")
SCANNED = ["*.md", "docs/adr/*.md", "docs/design/*.md", "docs/tenants/*/profile.md"]

BEGIN = re.compile(r"^<!-- formal: (TauWeb\.[A-Za-z0-9_.]+) -->$")
END = "<!-- /formal -->"
TOKEN = re.compile(r"`[^`\n]+`|\*\*[^*\n]+\*\*")
LINK = re.compile(r"\]\(([^)\s]+)")
SEPARATOR = re.compile(r"\|(?:\s*:?-+:?\s*\|)+")
KINDS = ("render", "match")


def read_regions():
    if not os.path.exists(REGIONS):
        print(f"FAIL: {REGIONS} missing -- run tools/check_formal.sh first "
              f"(check-all.sh orders it before this gate)")
        sys.exit(2)
    out = {}
    for line in open(REGIONS):
        if line.strip():
            row = json.loads(line)
            out[row["decl"]] = (row["kind"], row["text"].split("\n"))
    return out


def split_cells(row):
    """A Markdown table row's cells, splitting on unescaped pipes only. Two Value cells of the
    delivery declaration carry `\\|` inside a code span; splitting on every pipe reads them as
    column boundaries and the row arrives with cells nobody wrote."""
    out, cur, i = [], [], 0
    while i < len(row):
        if row[i] == "\\" and i + 1 < len(row):
            cur.append(row[i:i + 2])
            i += 2
        elif row[i] == "|":
            out.append("".join(cur))
            cur = []
            i += 1
        else:
            cur.append(row[i])
            i += 1
    out.append("".join(cur))
    return out


def cells(row):
    parts = [c.strip() for c in split_cells(row.strip())]
    return parts[1:-1] if len(parts) >= 2 else parts


def table_body(lines):
    """The data rows of a Markdown table: everything after the |---| separator."""
    rows = [l for l in lines if l.lstrip().startswith("|")]
    for k, r in enumerate(rows):
        if SEPARATOR.fullmatch(r.strip()):
            return rows[k + 1:]
    return rows


def find_regions(lines):
    """Yield (decl, begin_index, end_index) for each marked region; end is the END line."""
    open_at = None
    for i, line in enumerate(lines):
        m = BEGIN.match(line.rstrip("\n"))
        if m:
            if open_at is not None:
                raise ValueError(f"line {i + 1}: a region opened inside the one at line {open_at[1] + 1}")
            open_at = (m.group(1), i)
        elif line.rstrip("\n") == END:
            if open_at is None:
                raise ValueError(f"line {i + 1}: '{END}' with no open region")
            yield open_at[0], open_at[1], i
            open_at = None
    if open_at is not None:
        raise ValueError(f"line {open_at[1] + 1}: region {open_at[0]} is never closed")


def requirement_at(lines, i):
    """The requirement whose body holds line i, or None. A companion document has no
    requirement heads, so None there is the ordinary case and the link rule decides."""
    for j in range(i, -1, -1):
        m = DEF_RE.match(lines[j])
        if m and not POINTER_RE.search(lines[j]):
            return m.group(1) or m.group(2)
    return None


def links(req, target, owned):
    """True when `req`'s own body links `target`, a repository-relative path. Resolved from
    the directory of the file that defines `req`, since that is what its links are relative
    to."""
    where = owned.get(req)
    if where is None:
        return False
    base = os.path.dirname(where[0])
    for m in LINK.finditer(where[1]):
        dest = m.group(1).split("#")[0].strip()
        if not dest or "://" in dest:
            continue
        if os.path.normpath(os.path.join(base, dest)) == os.path.normpath(target):
            return True
    return False


def match_table(doc_lines, emitted_lines):
    """The drift messages for a `match` region, and the structural ones separately."""
    stray = [l for l in doc_lines if l.strip() and not l.lstrip().startswith("|")]
    if stray:
        return [], [f"a line that is not a table row: {stray[0].strip()[:80]!r}"]
    doc, want = table_body(doc_lines), [l for l in emitted_lines if l.strip()]
    if len(doc) != len(want):
        return [f"{len(doc)} row(s) in the document, {len(want)} emitted"], []
    vocab = {t for row in want for c in cells(row)[1:] for t in TOKEN.findall(c)}
    out = []
    for n, (d, w) in enumerate(zip(doc, want), 1):
        dc, wc = cells(d), cells(w)
        if len(dc) != len(wc):
            out.append(f"row {n}: {len(dc)} cell(s), {len(wc)} emitted")
            continue
        key, dkey = TOKEN.findall(wc[0]), TOKEN.findall(dc[0])
        it = iter(dkey)
        if not all(any(t == k for t in it) for k in key):
            out.append(f"row {n}, key column: expected {key} in order, document has {dkey}")
        for col in range(1, len(wc)):
            got = [t for t in TOKEN.findall(dc[col]) if t in vocab]
            exp = TOKEN.findall(wc[col])
            if got != exp:
                out.append(f"row {n}, column {col + 1}: the declaration says {exp}, "
                           f"the document says {got}")
    return out, []


def main():
    os.chdir(ROOT)
    index, regions = read_index(), read_regions()
    owned = owners()
    drift, placement, structure, cnf = [], [], [], []
    seen, tainted = {}, set()

    for decl, (kind, emitted) in sorted(regions.items()):
        if kind not in KINDS:
            structure.append(f"{decl} is emitted with kind {kind!r}, which is not one of {KINDS}")
            tainted.add(decl)
        hit = CNF.search("\n".join(emitted))
        if hit:
            cnf.append(f"the emission for {decl} carries {hit.group()}; "
                       f"a theorem is never conformance")
            tainted.add(decl)

    for f in files(SCANNED):
        lines = open(f).read().split("\n")
        try:
            found = list(find_regions(lines))
        except ValueError as exc:
            structure.append(f"{f}: {exc}")
            continue
        for decl, b, e in found:
            where = f"{f}:{b + 1}"
            if decl not in regions:
                placement.append(f"{where}: the region names {decl}, "
                                 f"which the declarations do not emit")
                continue
            if decl in seen:
                structure.append(f"{where}: {decl} is already rendered at {seen[decl]}")
                continue
            seen[decl] = where
            req = index.get(decl)
            if req is None:
                placement.append(f"{where}: {decl} is not in the index -- "
                                 f"a region's declaration is tagged @[req]")
            else:
                holder = requirement_at(lines, b)
                if holder != req and not links(req, f, owned):
                    placement.append(f"{where}: {decl} is tagged {req}, which neither defines "
                                     f"this file nor links it (it sits in {holder})")
            kind, emitted = regions[decl]
            if decl in tainted:
                # Refused above; comparing a refused emission would report its drift twice.
                continue
            body = lines[b + 1:e]
            if kind == "render":
                doc, want = [l.rstrip() for l in body], [l.rstrip() for l in emitted]
                if doc != want:
                    for d in difflib.unified_diff(doc, want, "document", "declaration",
                                                  lineterm="", n=0):
                        print(f"  {d[:160]}")
                    drift.append(f"{where}: {decl} differs from its declaration")
            elif kind == "match":
                bad, broken = match_table(body, emitted)
                for msg in bad:
                    print(f"  {where}: {decl}: {msg}")
                    drift.append(f"{where}: {decl}: {msg[:60]}")
                for msg in broken:
                    structure.append(f"{where}: {decl}: {msg}")

    unrendered = sorted(set(regions) - set(seen))
    print(f"marked regions: {len(seen)} rendered, {len(regions)} emitted")
    print("REGION DRIFT:", drift or "none")
    print("REGION PLACEMENT:", placement or "none")
    print("REGION STRUCTURE:", structure or "none")
    print("UNRENDERED REGIONS:", unrendered or "none")
    print("CNF IN A REGION:", cnf or "none")
    return 1 if (drift or placement or structure or unrendered or cnf) else 0


if __name__ == "__main__":
    sys.exit(main())
