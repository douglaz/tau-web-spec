#!/usr/bin/env python3
"""Requirement-identifier gate.

Enforces README.md's "Requirement conventions" mechanically:

  * every requirement id is defined exactly once        (duplicate ids)
  * every cited id is defined or listed as withdrawn    (dangling citations)
  * a "Moved to" pointer points at a definition          (pointer to nothing)
  * no id is missing from a family's sequence           (renumbering / gaps)
  * no id sits far above its neighbours                 (a mistyped id)
  * every cited ADR exists on disk                      (bad ADR references)
  * a withdrawn id is not defined again                 (reintroduced)
  * a conformance item carries a tier where it must     (untiered item)

Identifiers are append-only. Deleting a requirement is permitted -- the gap in
the sequence IS the tombstone -- so a withdrawn id may be absent, but it must be
listed in README.md's withdrawn-identifier table, which this gate reads.

Ported from provisiond-spec's tools/check_ids.py and adapted to this corpus's
shapes: `**STA-22 Title.**`, `**TRU-E8a — title**`, `### SEC-1 — title`,
`## SEC-CLAIM`, `- [ ] **CNF-5 · BLOCKING**`, and the "Moved to" pointer a
relocated requirement leaves behind (ADR-0030).

Run from anywhere; it locates the repository root from its own path.
Exit status 0 = clean, 1 = failures.
"""

import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

NAMESPACES = ["OVR", "ARC", "CHN", "STA", "SEC", "TRU", "STG", "CNF", "OPN"]
NS = "|".join(NAMESPACES)

# An identifier: namespace, dash, then either a number with an optional amendment
# suffix (`STA-22`, `STA-22a`), a lettered family with a number (`CHN-R1`,
# `SEC-T1`, `TRU-E8a`), or the one word (`SEC-CLAIM`).
ID = r"(?:%s)-(?:[A-Z]?\d+[a-z]?|CLAIM)" % NS

# A requirement is *defined* where its id opens a bold span at the start of a
# line (optionally as a checkbox bullet), or opens a heading. The lookahead
# refuses `**CNF-17's ...` and keeps `STA-22` from matching inside `STA-22a`.
DEF_RE = re.compile(
    r"^(?:[-*]\s+(?:\[[ x]\]\s+)?)?\*\*(%s)(?=\*\*|\s)|^#{1,6}\s+(%s)(?=\s|$)" % (ID, ID),
    re.M,
)
BOLD_RE = re.compile(r"\*\*(%s)\*\*" % ID)
# Any occurrence of an identifier is a citation, backticked or not: a Mermaid
# note cannot backtick, and `SEC-1, STA-22` inside one must still resolve.
CITE_RE = re.compile(r"(?<![A-Za-z0-9-])(%s)(?![A-Za-z0-9])" % ID)
ADR_RE = re.compile(r"`?ADR-(\d{4})`?")
WITHDRAWN_RE = re.compile(r"^\|\s*`?(%s)`?\s*\|" % ID, re.M)
# A requirement moved to a tenant profile leaves a one-line pointer behind so
# old citations resolve (ADR-0030). A pointer is not a definition.
POINTER_RE = re.compile(r"\*\*\s+Moved to\b")

# A conformance item MUST carry a tier, except in the two sections the checklist
# itself puts outside tiering: "Build and gate" precedes the tiering rule, and
# "Measurements" is "Not pass/fail". The item is matched before its tag so that
# a misspelt tier is an untiered item rather than an invisible one.
ITEM_RE = re.compile(r"^- \[[ x]\] \*\*(CNF-\d+[a-z]?)([^*]*)\*\*")
TIER_RE = re.compile(r"^ · (BLOCKING|PRE-SCALE|DEFERRED)$")
UNTIERED_SECTIONS = {"Build and gate", "Measurements"}

# Requirements are defined in the topic files and the tenant profiles; an ADR
# that opened a bold `**ARC-1**` would be a second definition and is read too.
DEFINING = ["*.md", "docs/adr/*.md", "docs/tenants/*/profile.md"]
CITING = ["*.md", "docs/**/*.md", "bundle/*.md", "prototypes/**/*.md"]
EXCLUDED = ("docs/archive/",)


def files(patterns):
    seen = []
    for p in patterns:
        seen.extend(glob.glob(p, recursive=True))
    return sorted(f for f in set(seen) if not f.startswith(EXCLUDED))


def family(rid):
    """`TRU-E8a` -> ("TRU-E", 8); `STA-22` -> ("STA-", 22); `SEC-CLAIM` -> None."""
    m = re.match(r"([A-Z]+-[A-Z]?)(\d+)[a-z]?$", rid)
    return (m.group(1), int(m.group(2))) if m else None


def main():
    os.chdir(ROOT)
    defining, citing = files(DEFINING), files(CITING)

    defined, dupes, pointers = {}, [], {}
    for f in defining:
        text = open(f).read()
        for m in DEF_RE.finditer(text):
            rid = m.group(1) or m.group(2)
            line = text[m.start():].split("\n", 1)[0]
            if POINTER_RE.search(line):
                for p in BOLD_RE.findall(line):
                    pointers[p] = f
            elif rid in defined:
                dupes.append((rid, defined[rid], f))
            else:
                defined[rid] = f

    withdrawn = set()
    readme = open("README.md").read()
    idx = readme.find("### Withdrawn identifiers")
    if idx != -1:
        withdrawn = {m.group(1) for m in WITHDRAWN_RE.finditer(readme[idx:])}

    cited = set()
    for f in citing:
        cited.update(CITE_RE.findall(open(f).read()))
    # A pointer resolves a citation to a location; whether the location holds a
    # definition is the pointer check's finding, reported once.
    dangling = sorted(cited - set(defined) - withdrawn - set(pointers))
    orphan_pointers = sorted(p for p in pointers if p not in defined)
    reintroduced = sorted(withdrawn & set(defined))

    # A single mistyped identifier (**ARC-9999**) would otherwise make every
    # integer below it "missing" and bury the real finding. An id far above its
    # neighbours is itself the anomaly; report it and compute gaps on the rest.
    # A pointer holds its number; whether it resolves is the pointer check's.
    numbered = {}
    for rid in set(defined) | set(pointers):
        fam = family(rid)
        if fam:
            numbered.setdefault(fam[0], set()).add(fam[1])
    gaps, outliers = {}, {}
    for fam, nums in sorted(numbered.items()):
        body = sorted(nums)
        while len(body) > 1 and body[-1] - body[-2] > 50:
            outliers.setdefault(fam, []).append(body.pop())
        missing = [n for n in range(1, max(body) + 1)
                   if n not in body and f"{fam}{n}" not in withdrawn]
        if missing:
            gaps[fam] = missing

    items, untiered, section = 0, [], ""
    for line in open("07-conformance.md"):
        if line.startswith("## "):
            section = line[3:].strip()
        m = ITEM_RE.match(line)
        if m:
            items += 1
            if not TIER_RE.match(m.group(2)) and section not in UNTIERED_SECTIONS:
                untiered.append(m.group(1))

    adrs = {os.path.basename(p)[:4] for p in glob.glob("docs/adr/*.md")}
    bad_adrs = set()
    for f in citing:
        for m in ADR_RE.finditer(open(f).read()):
            if m.group(1) not in adrs:
                bad_adrs.add((f, "ADR-" + m.group(1)))

    print(f"requirements: {len(defined)} | defining files: {len(defining)} | "
          f"citing files: {len(citing)} | ADRs: {len(adrs)}")
    print(f"withdrawn ids indexed: {len(withdrawn)} | pointers: {len(pointers)} | "
          f"conformance items: {items}")
    print("DUPES:", dupes or "none")
    print("DANGLING:", dangling or "none")
    print("POINTER TO NOTHING:", orphan_pointers or "none")
    print("NUMBER GAPS:", gaps or "none")
    print("OUTLIER IDS:", outliers or "none")
    print("BAD ADR REFS:", sorted(bad_adrs) or "none")
    print("WITHDRAWN BUT DEFINED:", reintroduced or "none")
    print("UNTIERED CNF ITEMS:", untiered or "none")

    return 1 if (dupes or dangling or orphan_pointers or gaps or outliers
                 or bad_adrs or reintroduced or untiered) else 0


if __name__ == "__main__":
    sys.exit(main())
