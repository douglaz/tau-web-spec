#!/usr/bin/env python3
"""Emission gate (ADR-0032, "How the implementation is compared"): a committed witness
file is what the companion emits.

`lake exe witnesses` writes one file per module under `tools/formal/.lake/witnesses/`;
the copy the implementation reads is committed under `docs/design/`. Two copies drift,
so this gate compares them byte for byte and refuses a difference, a committed file no
module emits, and an emitted file not committed. It also refuses an emission carrying a
`CNF` identifier: the rule is path-independent (ADR-0032, "What it never carries") and
`check_formal.sh`'s grep stops at `.lake/`. `--write` copies the emission over the
committed files, deliberately, after a reviewed change to the module.

Reads what `tools/check_formal.sh` writes, so `check-all.sh` runs that gate first. A
missing emission is a red gate, not a skipped one (`AGENTS.md`).

Exit 0 = every committed file is the emission, 1 = drift, 2 = the emission is missing.
"""

import difflib
import glob
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EMITTED = os.path.join(ROOT, "tools", "formal", ".lake", "witnesses")
COMMITTED = os.path.join(ROOT, "docs", "design")
SUFFIX = "-witnesses-v1.json"
CNF = re.compile(r"CNF-[0-9]+")


def main():
    if not os.path.isdir(EMITTED):
        print(f"FAIL: {EMITTED} missing -- run tools/check_formal.sh first "
              f"(check-all.sh orders it before this gate)")
        return 2
    emitted = sorted(glob.glob(os.path.join(EMITTED, "*" + SUFFIX)))
    committed = sorted(glob.glob(os.path.join(COMMITTED, "*" + SUFFIX)))
    if "--write" in sys.argv:
        for e in emitted:
            shutil.copyfile(e, os.path.join(COMMITTED, os.path.basename(e)))
            print(f"wrote docs/design/{os.path.basename(e)}")
        return 0
    drift = []
    for e in emitted:
        name = os.path.basename(e)
        module = name[: -len(SUFFIX)]
        emission = open(e).read()
        if CNF.search(emission):
            drift.append(f"the emission for module {module} carries a CNF identifier "
                         f"({CNF.search(emission).group()}); a theorem is never conformance")
            continue
        c = os.path.join(COMMITTED, name)
        if not os.path.exists(c):
            drift.append(f"docs/design/{name} is not committed (module {module}; "
                         f"tools/check_witnesses.py --write)")
            continue
        committed_text = open(c).read()
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
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
