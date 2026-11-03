#!/usr/bin/env python3
"""Emission gate (ADR-0032, "How the implementation is compared"): a committed witness
file is what the companion emits, with its marked pairs checked corpus-wide.

`lake exe witnesses` writes one file per module under `tools/formal/.lake/witnesses/`;
the copy the implementation reads is committed under `docs/design/`. Two copies drift,
so this gate compares them byte for byte and refuses a difference, a committed file no
module emits, and an emitted file not committed. It also refuses an emission carrying a
`CNF` identifier: the rule is path-independent (ADR-0032, "What it never carries") and
`check_formal.sh`'s grep stops at `.lake/`. `--write` copies the emission over the
committed files, deliberately, after a reviewed change to the module.

Reads what `tools/check_formal.sh` writes, so `check-all.sh` runs that gate first. A
missing emission is a red gate, not a skipped one (`AGENTS.md`).

WITNESS PAIRS checks the pair structure owned by ADR-0032 and witness-file-v1.md;
it compares inputs, never evaluates protocol outcomes or strengthens the emitter's
name-based theorem tie. Locations identify occurrences, including repeated declarations.

Exit 0 = emission equality and valid pairs, 1 = findings, 2 = emission missing.
"""

import difflib
import glob
import json
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EMITTED = os.path.join(ROOT, "tools", "formal", ".lake", "witnesses")
COMMITTED = os.path.join(ROOT, "docs", "design")
SUFFIX_GLOB = "*-witnesses-v*.json"
CNF = re.compile(r"CNF-[0-9]+")


def structural(value):
    """JSON equality with scalar types intact, array order intact, keys unordered."""
    if type(value) is dict:
        return (dict, tuple((k, structural(v)) for k, v in sorted(value.items())))
    if type(value) is list:
        return (list, tuple(map(structural, value)))
    return (type(value), value)


def marked_traces(value, at="$"):
    """Walk the emitted corpus rather than maintaining a list of trace arrays."""
    if type(value) is dict:
        if "pair" in value:
            yield at, value
            return
        # An unmarked trace is also a leaf: its input and output objects may
        # themselves have fields named pair, which are not trace metadata.
        if {"declarations", "assumptions", "start", "steps"} <= value.keys():
            return
        for key, child in sorted(value.items()):
            yield from marked_traces(child, f"{at}[{json.dumps(key)}]")
    elif type(value) is list:
        for index, child in enumerate(value):
            yield from marked_traces(child, f"{at}[{index}]")


def trace_errors(trace):
    errors = []
    pair = trace["pair"]
    if (type(pair) is not dict or set(pair) != {"side", "with"}
            or pair.get("side") not in ("refused", "admitted")
            or type(pair.get("with")) is not str or not pair["with"].strip()):
        errors.append("malformed pair metadata: expected side refused/admitted and with declaration")
    declarations = trace.get("declarations")
    if (type(declarations) is not list or not declarations
            or any(type(d) is not str or not d.strip() for d in declarations)):
        errors.append("malformed declarations: expected nonempty array of declaration names")
    for field in ("start", "assumptions"):
        if type(trace.get(field)) is not dict:
            errors.append(f"malformed {field}: expected object")
    steps = trace.get("steps")
    if (type(steps) is not list
            or any(type(s) is not dict or type(s.get("event")) is not dict for s in steps)):
        errors.append("malformed steps: expected ordered objects with event objects")
    return errors


def pair_findings(corpus, name):
    traces = list(marked_traces(corpus))
    errors = [trace_errors(t) for _, t in traces]

    def refers(i, j):
        a, b = traces[i][1], traces[j][1]
        pair, declarations = a.get("pair"), b.get("declarations")
        return (type(pair) is dict and type(pair.get("with")) is str
                and type(declarations) is list and pair["with"] in declarations)

    def reciprocal(i, j):
        return refers(i, j) and refers(j, i)

    def same_start(i, j):
        return structural(traces[i][1]["start"]) == structural(traces[j][1]["start"])

    def same_events(i, j):
        return structural([s["event"] for s in traces[i][1]["steps"]]) == structural(
            [s["event"] for s in traces[j][1]["steps"]])

    def opposite(i, j):
        return traces[i][1]["pair"]["side"] != traces[j][1]["pair"]["side"]

    # Edges are occurrence-to-occurrence, never a declaration-name dictionary.
    candidates = [set() for _ in traces]
    for i in range(len(traces)):
        for j in range(i):
            if (not errors[i] and not errors[j] and reciprocal(i, j)
                    and opposite(i, j) and same_start(i, j) and same_events(i, j)):
                candidates[i].add(j)
                candidates[j].add(i)

    findings = []

    def report(indices, reasons):
        locations = "; ".join(f"{traces[i][0]} declarations={traces[i][1].get('declarations')!r}"
                              for i in sorted(indices))
        findings.append(f"docs/design/{name}: {locations}: " + "; ".join(sorted(set(reasons))))

    remaining = set(range(len(traces)))
    for i, edges in enumerate(candidates):
        if len(edges) != 1:
            continue
        j = next(iter(edges))
        if j <= i or len(candidates[j]) != 1:
            continue
        remaining.difference_update((i, j))
        if structural(traces[i][1]["assumptions"]) == structural(traces[j][1]["assumptions"]):
            report((i, j), ["equal assumptions"])

    # Group unresolved reference-connected endpoints once. Resolve sound pairs first
    # so an intact repeated occurrence cannot hide or absorb a damaged occurrence.
    while remaining:
        component, pending = set(), [min(remaining)]
        while pending:
            i = pending.pop()
            if i not in remaining:
                continue
            remaining.remove(i)
            component.add(i)
            pending.extend(j for j in sorted(remaining)
                           if refers(i, j) or refers(j, i))
        reasons = [error for i in component for error in errors[i]]
        if any(len(candidates[i]) > 1 for i in component):
            reasons.append("ambiguous counterparts: one-to-one accounting failed")
        for i in sorted(component):
            if errors[i] or candidates[i]:
                continue
            partners = [j for j in component if j != i and refers(i, j)]
            if not partners:
                incoming = [j for j in component if j != i and refers(j, i)]
                if not any(errors[j] for j in incoming):
                    reasons.append("nonreciprocal declaration references" if incoming
                                   else "missing marked counterpart")
                continue
            partners = [j for j in partners if not errors[j]]
            if not partners:
                continue  # The malformed endpoint already explains this pair.
            reciprocal_partners = [j for j in partners if reciprocal(i, j)]
            if not reciprocal_partners:
                reasons.append("nonreciprocal declaration references")
                continue
            opposite_partners = [j for j in reciprocal_partners if opposite(i, j)]
            if not opposite_partners:
                reasons.append("same-side counterparts")
                continue
            starts = [j for j in opposite_partners if same_start(i, j)]
            if not starts:
                reasons.append("changed complete start")
            elif not any(same_events(i, j) for j in starts):
                reasons.append("changed ordered event inputs (complete event objects)")
        report(component, reasons)
    return findings


def main():
    if not os.path.isdir(EMITTED):
        print(f"FAIL: {EMITTED} missing -- run tools/check_formal.sh first "
              f"(check-all.sh orders it before this gate)")
        return 2
    emitted = sorted(glob.glob(os.path.join(EMITTED, SUFFIX_GLOB)))
    committed = sorted(glob.glob(os.path.join(COMMITTED, SUFFIX_GLOB)))
    if "--write" in sys.argv:
        # Copy only current emissions; a later check still rejects obsolete committed files.
        for e in emitted:
            shutil.copyfile(e, os.path.join(COMMITTED, os.path.basename(e)))
            print(f"wrote docs/design/{os.path.basename(e)}")
        return 0
    drift = []
    pairs = []
    for e in emitted:
        name = os.path.basename(e)
        module = name.split("-witnesses-v", 1)[0]
        with open(e) as source:
            emission = source.read()
        if CNF.search(emission):
            drift.append(f"the emission for module {module} carries a CNF identifier "
                         f"({CNF.search(emission).group()}); a theorem is never conformance")
            continue
        try:
            pairs.extend(pair_findings(json.loads(emission), name))
        except (ValueError, RecursionError) as exc:
            pairs.append(f"docs/design/{name}: malformed JSON corpus: {exc}")
        c = os.path.join(COMMITTED, name)
        if not os.path.exists(c):
            drift.append(f"docs/design/{name} is not committed (module {module}; "
                         f"tools/check_witnesses.py --write)")
            continue
        with open(c) as source:
            committed_text = source.read()
        if committed_text != emission:
            diff = difflib.unified_diff(committed_text.splitlines(), emission.splitlines(),
                                        f"docs/design/{name}", "emission", lineterm="", n=0)
            for line in list(diff)[:12]:
                print(f"  {line[:160]}")
            drift.append(f"docs/design/{name} differs from the emission (module {module}; "
                         f"tools/check_witnesses.py --write after review)")
    emitted_names = {os.path.basename(e) for e in emitted}
    for c in committed:
        if os.path.basename(c) not in emitted_names:
            drift.append(f"docs/design/{os.path.basename(c)} is committed but no module emits it")
    print(f"witness files checked: {len(emitted)}")
    print("WITNESS DRIFT:", drift or "none")
    print("WITNESS PAIRS:", pairs or "none")
    return 1 if drift or pairs else 0


if __name__ == "__main__":
    sys.exit(main())
