#!/usr/bin/env python3
"""Citation-attribution gate.

A sentence reporting what another requirement SAYS is a checkable claim about a
specific span of text, and `AGENTS.md` ("Quote the sentence") requires it to
carry that text; that section also records, from `lean-01.md` section A, what
an unchecked one cost.

`check_ids.py` cannot see this class: the citation resolves. Only the relation
between the claim and the cited text is broken.

TWO RULES, deliberately narrow, ported from provisiond-spec:

  QUOTED   A quoted phrase attributed to `X` -- `` `X` says "..." `` -- must
           appear in X's own body. Hard failure: it occurs there or it does not.

  UNQUOTED "`X` says/states ..." with no quote is unverifiable by construction.
           Ratcheted against `citation-baseline.json` rather than failed
           outright, because such sentences exist and a gate that fails a clean
           tree is a gate someone deletes. The baseline holds one count per
           `file:id`, so a second unquoted sentence about the same requirement
           in the same file is new; rewording a standing one is not. The count
           lives in that file and nowhere else.

  LEAN     A backticked `TauWeb.*` name is a citation of a Lean declaration
           (ADR-0032, "The tags are the record") and must resolve against the
           index `lake exe gate` writes: a tagged declaration, a namespace or
           module holding one, or `TauWeb.Explore`. A renamed declaration
           leaves a dangling citation, and this is where it goes red. A missing
           index is exit 2, never a skip: `check-all.sh` runs the formal gate
           first so the index is this run's.

Summary verbs are OUT OF SCOPE by design. "`STA-8` forbids automatic retry" is
a paraphrase; demanding a quote there fires on legitimate prose. Past-tense
attributions ("`STA-8` said *terminal event* until 2026-09-16") report a former
text and are skipped: the current body cannot be expected to contain them.

NOT CAUGHT, stated because a gate's limits are part of its contract: a wrong
SUMMARY. "`STA-24` forbids the per-resource barrier" reverses `STA-24`, uses a
summary verb and carries no quote. That stays a review problem.

Scanned: the topic files and root documents, the decision records, the tenant
profiles and `docs/design/`. Not scanned: `docs/review/` and `docs/findings/`,
which are dated records of what a text said when they were written.

Usage: check_citations.py [--write-baseline DATE REASON]
Exit 0 = clean, 1 = an unverifiable quote, an unresolved `TauWeb.*` name or a
rise above the baseline, 2 = no baseline recorded or no index written.
"""

import collections
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_ids import DEF_RE, DEFINING, ID, POINTER_RE, ROOT, files  # noqa: E402

BASELINE = os.path.join(ROOT, "tools", "citation-baseline.json")
CITING = ["*.md", "docs/adr/*.md", "docs/tenants/*/*.md", "docs/design/*.md"]

# Direct-speech attribution only, present tense. Two shapes: the verb form
# ("`STA-24` says ...") and the possessive form ("`STA-24`'s rule that ..."),
# which claims what a requirement contains just as directly.
SPEECH = r"says|states|reads"
NOUN = r"rule|claim|wording|statement|sentence|words|text"
ATTRIB = re.compile(
    r"`(%s)`\s+(?:own\s+)?(%s)\b|`(%s)`'s\s+(?:own\s+)?(%s)\s+that\b"
    % (ID, SPEECH, ID, NOUN)
)
# "reads" is two verbs. "`STA-20` reads \"...\"" attributes text; "`STA-16`
# reads it from the sheet" means CONSULTS, which never carries a quote. Checked
# when a quote is present, ignored when one is not.
CONSULTS = {"reads"}
# A bullet whose items end in ";" is one sentence to any splitter, which lets
# one item's attribution collect the next item's quote. Break on list markers
# and blank lines as well as sentence enders.
SPLIT = re.compile(r"(?<=[.!?])\s+|\n\s*[-*]\s+|\n\s*\n|\n(?=\|)")
# Paired quotes only: an unpaired quote character makes every span between two
# of them look like a quotation.
QUOTE = re.compile(r'“([^”]{8,400})”|"((?:[^"\n]|\n(?!\s*\n)){8,400})"')
LEAN = re.compile(r"`(TauWeb\.[A-Za-z0-9_.]+)`(?<!\.lean`)")  # `TauWeb.lean` is a file
INDEX = os.path.join(ROOT, "tools", "formal", ".lake", "index.jsonl")
MODULES = os.path.join(ROOT, "tools", "formal", "TauWeb.lean")


def lean_names():
    """Every name a document may cite: tagged declarations, their namespaces, the
    modules the umbrella imports, and `TauWeb.Explore`, which holds untagged scratch.
    Not caught: a declaration renamed and a new one tagged under the old name."""
    if not os.path.exists(INDEX):
        print(f"FAIL: {INDEX} missing -- run tools/check_formal.sh first "
              f"(check-all.sh orders it before this gate)")
        sys.exit(2)
    names = {"TauWeb.Explore"}
    for line in open(INDEX):
        if line.strip():
            parts = json.loads(line)["decl"].split(".")
            names.update(".".join(parts[:k]) for k in range(1, len(parts) + 1))
    for line in open(MODULES):
        if line.startswith("import "):
            names.add(line.split()[1])
    return names


def unresolved():
    names = lean_names()
    return sorted({(f, n) for f in files(CITING)
                   for n in LEAN.findall(open(f).read()) if n not in names})


def norm(s):
    s = (s.replace("“", '"').replace("”", '"').replace("’", "'").replace("‘", "'")
          .replace("—", "-").replace("–", "-"))
    s = re.sub(r"[*`~\"']", "", s)
    return re.sub(r"\s+", " ", s).lower().strip(" .,;:")


def bodies():
    """{id: body}: a definition line and what follows it, up to the next
    definition or heading. A "Moved to" pointer defines nothing (ADR-0030)."""
    out = {}
    for f in files(DEFINING):
        cur, buf = None, []
        for line in open(f).read().splitlines(True):
            m = DEF_RE.match(line)
            if m or line.startswith("#"):
                if cur:
                    out.setdefault(cur, "".join(buf))
                cur, buf = None, []
                if m and not POINTER_RE.search(line):
                    cur, buf = (m.group(1) or m.group(2)), [line]
            elif cur:
                buf.append(line)
        if cur:
            out.setdefault(cur, "".join(buf))
    return out


def find():
    """Return (unverified_quotes, unquoted_attributions)."""
    reqs = {k: norm(v) for k, v in bodies().items()}
    bad, unquoted = [], []
    for f in files(CITING):
        for sent in SPLIT.split(open(f).read()):
            attribs = list(ATTRIB.finditer(sent))
            for m, nxt in zip(attribs, attribs[1:] + [None]):
                rid = m.group(1) or m.group(3)
                verb = (m.group(2) or "").lower()
                # The verb introduces the first quote after it and before the
                # next attribution, and no other: a quote earlier in the chunk
                # belongs to whatever introduced it, and a later one to whatever
                # stands between (AGENTS.md shows a checkable attribution beside
                # an assertion in one sentence).
                end = nxt.start() if nxt else len(sent)
                quote = next((q.group(1) or q.group(2) for q in QUOTE.finditer(sent)
                              if m.start() < q.start() < end
                              and len(norm(q.group(0)).split()) >= 4), None)
                if quote is None:
                    if verb not in CONSULTS:
                        unquoted.append((f, rid, " ".join(sent.split())[:100]))
                    continue
                frags = [x for x in (p.strip() for p in re.split(r"\.\.\.|…", norm(quote))) if x]
                if not all(fr in reqs.get(rid, "") for fr in frags):
                    bad.append((f, rid, norm(quote)[:95]))
    return bad, unquoted


def main():
    os.chdir(ROOT)
    bad, unquoted = find()
    counts = collections.Counter(f"{f}:{rid}" for f, rid, _ in unquoted)

    if "--write-baseline" in sys.argv:
        i = sys.argv.index("--write-baseline")
        json.dump({"unquoted_attributions": dict(sorted(counts.items())),
                   "recorded": sys.argv[i + 1], "reason": sys.argv[i + 2],
                   "note": "Sentences reporting what a requirement SAYS with no quote to check, "
                           "counted per file:id. Ratchet: may shrink, never grow."},
                  open(BASELINE, "w"), indent=2)
        open(BASELINE, "a").write("\n")
        print(f"baseline written: {sum(counts.values())} unquoted attribution(s)")
        return 0

    if not os.path.exists(BASELINE):
        print(f"FAIL: no baseline at {BASELINE} -- run with --write-baseline DATE REASON")
        return 2
    base = json.load(open(BASELINE))
    limit = base["unquoted_attributions"]
    new = sorted(sig for sig, n in counts.items() if n > limit.get(sig, 0))
    dangling = unresolved()

    for f, rid, q in bad:
        print(f'  {f} attributes to {rid} a phrase {rid} does not contain: "{q}"')
    for f, n in dangling:
        print(f"  {f} cites `{n}`, which the index does not carry")
    for sig in new:
        f, rid = sig.split(":", 1)
        print(f"  {f} reports what {rid} says without quoting it: "
              + next(s for g, r, s in unquoted if g == f and r == rid))
    print(f"unquoted attributions: {sum(counts.values())} against baseline "
          f"{sum(limit.values())} (recorded {base['recorded']}: {base['reason']})")
    print("UNVERIFIED QUOTES:", sorted(f"{f}:{rid}" for f, rid, _ in bad) or "none")
    print("NEW UNQUOTED ATTRIBUTIONS:", new or "none")
    print("UNRESOLVED TAUWEB NAMES:", [f"{f}:{n}" for f, n in dangling] or "none")
    return 1 if (bad or new or dangling) else 0


if __name__ == "__main__":
    sys.exit(main())
