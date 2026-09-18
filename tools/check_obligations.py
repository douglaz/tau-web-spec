#!/usr/bin/env python3
"""Orphaned-obligation gate.

A requirement that assigns a duty to ANOTHER requirement's subject -- "`STA-24`
MUST write `x` before dispatch" -- states that duty in the wrong document.
Nobody implementing `STA-24` from `03-state-and-recovery.md` reads the
requirement that assigned it, so the duty is never built, and the requirement
that depends on it is quietly false.

Ported from provisiond-spec, where this shipped on 2026-08-31 and survived until
2026-09-02: its `OPS-42`, the fence protecting a paying customer's machine from
an in-flight cancellation, stated `LDG-62`'s half of the contention, and
`LDG-62` did not contain the string `destroy_committed` at all. The fence did
not fence. Two full-set cross-model reviews read past it.

The other gates cannot see this class. `check_ids.py` is satisfied -- the
citation resolves. `check_coverage.py` is satisfied -- both requirements have
conformance items. `check_citations.py` is satisfied -- nothing is quoted. Only
the RELATIONSHIP is broken, and only a check that follows it can tell.

THE RULE: where requirement A says "`B` MUST <clause>" and the clause names
concrete machinery in backticks -- a field, a state, a path -- B's own body must
mention at least one of those names. B is free to phrase its duty however it
likes; it is not free to be silent about it. "`B` requires <clause>" is read
the same way: this corpus assigns duties in that form, and never in
provisiond's "`B` MUST" form, so a gate reading only the latter would examine
no sentence at all. The count of sentences examined is printed so that a green
over nothing is visible as one.

Deliberately conservative. It fires only when the target mentions NONE of the
clause's identifiers, because a partial match is usually a requirement that
discharges its duty in its own vocabulary. Against provisiond's whole set at
the commit where the fence bug existed, it reported exactly one finding.

Scanned: every requirement body, as `check_citations.py` delimits them.

Exit 0 = clean, 1 = at least one orphaned obligation.
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_citations import bodies  # noqa: E402
from check_ids import DEF_RE, DEFINING, ID, POINTER_RE, ROOT, files  # noqa: E402

# The clause runs to the sentence end; a dot inside a name (`journal.intent`)
# is not one.
OBLIG_RE = re.compile(r"`(%s)`\s+(?:MUST|SHOULD|requires)\b((?:[^.]|\.(?!\s|$)){0,300})" % ID)

# An identifier-shaped token inside a backtick span: `destroy_committed IS NULL`
# yields destroy_committed. Requiring the WHOLE span to be a bare identifier
# misses exactly that case -- which is the case this gate exists for. Three
# characters, so that `pin`, `job` and `uid` count: inside backticks a short
# word is machinery, not prose.
TOKEN_RE = re.compile(r"\b([a-z][a-z_0-9]{2,})\b")

# Words that appear in prose as often as in schemas; a target "mentioning" one of
# these proves nothing.
NOISE = {
    "where", "which", "there", "these", "those", "while", "would", "should",
    "about", "after", "every", "other", "under", "being", "their", "whether",
    "because", "within", "against", "though", "rather", "cannot", "already",
    "before", "during", "however", "instead", "itself", "either", "neither",
}


def find():
    reqs = bodies()
    where = {}
    for f in files(DEFINING):
        text = open(f).read()
        for m in DEF_RE.finditer(text):
            if not POINTER_RE.search(text[m.start():].split("\n", 1)[0]):
                where.setdefault(m.group(1) or m.group(2), f)
    hits, duties = [], 0
    for rid, body in sorted(reqs.items()):
        for m in OBLIG_RE.finditer(body):
            duties += 1
            target, clause = m.group(1), m.group(2)
            if target == rid or target not in reqs:
                continue
            toks = set()
            for span in re.findall(r"`([^`]+)`", clause):
                toks.update(TOKEN_RE.findall(span))
            toks -= NOISE
            if toks and not any(t in reqs[target] for t in toks):
                hits.append((rid, where[rid], target, where[target], sorted(toks),
                             " ".join(clause.split())[:120]))
    return hits, len(reqs), duties


def main():
    os.chdir(ROOT)
    hits, n_reqs, n_duties = find()
    for rid, f, tgt, tf, miss, clause in hits:
        print(f"  {rid} ({f}) says {tgt} MUST … {clause}")
        print(f"      but {tgt} ({tf}) mentions none of: {', '.join(miss)}")
    if hits:
        print("  Either write the duty into the requirement that owns the actor, "
              "or state it in terms that requirement already uses.")
    print(f"requirement bodies scanned: {n_reqs} | duty sentences examined: {n_duties}")
    print("ORPHANED OBLIGATIONS:", [f"{r}->{t}" for r, _, t, _, _, _ in hits] or "none")
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main())
