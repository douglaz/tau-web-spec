#!/usr/bin/env python3
"""Conformance-coverage gate.

`07-conformance.md` is this specification's test suite -- there is no code
here (ADR-0031). So "which requirements does nothing ever demonstrate?" is the
question "what is untested?", and it is not answerable by reading: a requirement
with no conformance item contradicts nothing, so every review pass walks past
it.

A requirement is COVERED when at least one `CNF` item cites it. The number of
uncovered requirements may not rise above `coverage-baseline.json`, recorded
with a date and a reason. Ported from provisiond-spec, which recorded the
failure twice: a session adding requirements faster than conformance items,
noticed only when somebody counted.

What is credited:

  * every identifier cited on a `- [ ] **CNF-n · TIER**` line or its
    continuation lines, up to the next item or the next heading;
  * a cited range `` `STA-1`–`STA-4` `` within one family, both ends included.

What is not: prose under a heading before its first item, so the tiering and
applicability sections are never credited to the item that preceded them
(provisiond's 2026-08-31 bug: `current` not cleared at a heading inflated the
figure by eight points); a "Moved to" pointer, which defines nothing (ADR-0030);
anything under `tools/formal/`, which is not a definition of a requirement.

Excluded from the ratchet and reported separately, with the reason:

  OPN-*            an open question is a question, not a rule an implementation
                   demonstrates;
  docs/tenants/    a rule defined in a tenant profile (ADR-0030) is the tenant's
                   to demonstrate; the harness checklist exercises the harness.

Usage: check_coverage.py [--write-baseline DATE REASON]
Exit 0 = at or below baseline, 1 = regression, 2 = no baseline recorded.
"""

import collections
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_ids import (CITE_RE, DEF_RE, DEFINING, ITEM_RE, NAMESPACES, NS,  # noqa: E402
                       POINTER_RE, ROOT, family, files)

BASELINE = os.path.join(ROOT, "tools", "coverage-baseline.json")
CHECKLIST = "07-conformance.md"
EXCLUDED = {"OPN-*": "an open question is not a rule an implementation demonstrates",
            "docs/tenants/": "a rule in a tenant profile (ADR-0030) is the tenant's to demonstrate"}

# `STA-1`–`STA-4` credits STA-2 and STA-3 as surely as the two it names.
# Credited only within one family and only when the endpoints ascend.
RANGE_RE = re.compile(r"`((?:%s)-[A-Z]?)(\d+)`\s*[–—-]\s*`\1(\d+)`" % NS)


def cited(line):
    found = set(CITE_RE.findall(line))
    for fam, low, high in RANGE_RE.findall(line):
        if int(low) < int(high):
            found.update(f"{fam}{n}" for n in range(int(low), int(high) + 1))
    return found


def order(rid):
    return (family(rid) or (rid, 0), rid)


def measure():
    """({id: defining file} minus CNF items, [uncovered ids])."""
    os.chdir(ROOT)
    reqs = {}
    for f in files(DEFINING):
        text = open(f).read()
        for m in DEF_RE.finditer(text):
            rid = m.group(1) or m.group(2)
            line = text[m.start():].split("\n", 1)[0]
            if not POINTER_RE.search(line) and not rid.startswith("CNF-"):
                reqs.setdefault(rid, f)

    covered, current = set(), None
    for line in open(CHECKLIST):
        if line.startswith("#"):
            current = None
        m = ITEM_RE.match(line)
        if m:
            current = m.group(1)
        if current:
            covered |= cited(line)
    return reqs, sorted((r for r in reqs if r not in covered), key=order)


def excluded_reason(rid, f):
    if rid.startswith("OPN-"):
        return "OPN-*"
    if f.startswith("docs/tenants/"):
        return "docs/tenants/"
    return None


def main():
    reqs, uncovered = measure()
    ratcheted = [r for r in uncovered if not excluded_reason(r, reqs[r])]
    excluded = collections.defaultdict(list)
    for r in uncovered:
        if excluded_reason(r, reqs[r]):
            excluded[excluded_reason(r, reqs[r])].append(r)

    print(f"requirements: {len(reqs)} | covered by >=1 CNF item: {len(reqs) - len(uncovered)} | "
          f"uncovered (ratcheted): {len(ratcheted)} | uncovered (excluded): "
          f"{sum(len(v) for v in excluded.values())}")
    for ns in NAMESPACES:
        ids = [r for r in ratcheted if r.startswith(ns + "-")]
        if ids:
            print(f"  uncovered {ns} ({len(ids)}): {' '.join(ids)}")
    for key, why in EXCLUDED.items():
        if excluded[key]:
            print(f"  excluded {key} ({len(excluded[key])}), {why}: {' '.join(excluded[key])}")

    if "--write-baseline" in sys.argv:
        i = sys.argv.index("--write-baseline")
        json.dump({"max_uncovered_ratcheted": len(ratcheted),
                   "recorded": sys.argv[i + 1], "reason": sys.argv[i + 2],
                   "note": "Lower is better. Raise only deliberately, with a reason."},
                  open(BASELINE, "w"), indent=2)
        open(BASELINE, "a").write("\n")
        print(f"baseline written: {len(ratcheted)} uncovered")
        return 0

    if not os.path.exists(BASELINE):
        print(f"FAIL: no baseline at {BASELINE} -- run with --write-baseline DATE REASON")
        return 2
    base = json.load(open(BASELINE))
    limit = base["max_uncovered_ratcheted"]
    print(f"baseline: {limit} uncovered (recorded {base['recorded']}: {base['reason']})")
    over = len(ratcheted) > limit
    print("ABOVE BASELINE:", f"{len(ratcheted)} uncovered > {limit}" if over else "none")
    return 1 if over else 0


if __name__ == "__main__":
    sys.exit(main())
