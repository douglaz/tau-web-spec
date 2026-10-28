#!/usr/bin/env python3
"""Exercise the exact diagnostic parser embedded in check-controls.sh."""

from pathlib import Path
import subprocess
import sys


root = Path(__file__).resolve().parent.parent
scratch = Path(sys.argv[1]) / "parser-regression"
scratch.mkdir()
controls = (root / "tools/check-controls.sh").read_text()
parser = controls.split("<<'PYCONTROL'\n", 1)[1].split("\nPYCONTROL", 1)[0]
parser_path = scratch / "parser.py"
parser_path.write_text(parser)
source_path = root / "tools/formal/TauWeb/Pins.lean"
source = source_path.read_text().splitlines()


def location(name):
    return next(i for i, line in enumerate(source, 1)
                if f"theorem {name} " in line and
                (line.startswith("@[req ") or line.startswith("theorem ")))


decided = "overlapping_publication_refused"
open_goal = "no_rescue_session_before_fill"
proposition = (f"error: TauWeb/Pins.lean:{location(decided)}:1: "
               "Tactic `decide` proved that the proposition\nTrue\nis false\n")
goal = (f"error: TauWeb/Pins.lean:{location(open_goal)}:1: unsolved goals\n"
        "case boot.published\nhadm : True\n⊢ Source.published = Source.rescueLast\n")
noise = ("warning: unrelated warning\n✔ Built TauWeb.Pins\n"
         "Some required targets logged failures:\n- TauWeb.Pins\n")
progress = (
    ("warning", "⚠ [5/27] Built TauWeb.Other\n"
     "warning: TauWeb/Other.lean:1:1: declaration uses sorry\n"),
    ("info", "ℹ [5/27] Built TauWeb.Other\n"
     "info: TauWeb/Other.lean:1:1: 1\n"),
)
cases = [
    ("decided clean", proposition, decided, True),
    ("decided with warning and build output", proposition + noise, decided, True),
    ("multiline proposition", proposition.replace("True\nis false", "False ∧\n  True\nis false"),
     decided, True),
    ("open goal clean", goal, open_goal, True),
    ("open goal with warning and build output", goal + noise, open_goal, True),
    ("multiline context", goal.replace("hadm : True", "h : ∀ x,\n  x = x\nhadm : True"),
     open_goal, True),
    ("attest source goal", goal.replace("boot.published", "boot.attest")
     .replace("Source.published", "Source.attest author"), open_goal, True),
    ("attest consumption goal",
     f"error: TauWeb/Pins.lean:{location('attest_acceptance_consumes')}:1: unsolved goals\n"
     "case isTrue\n⊢ m ∈ k.consumed\n", "attest_acceptance_consumes", True),
    ("restart durability goal",
     f"error: TauWeb/Pins.lean:{location('consumed_step')}:1: unsolved goals\n"
     "case restart\n⊢ m ∈ []\n", "consumed_step", True),
    ("truncated proposition", proposition.removesuffix("is false\n") + noise, decided, False),
    ("missing proposition", proposition.replace("True\n", ""), decided, False),
    ("blank proposition", proposition.replace("True\n", "  \n"), decided, False),
    ("unrelated error", proposition + "error: TauWeb/Other.lean:1:1: failed\n", decided, False),
    ("syntax failure", f"error: TauWeb/Pins.lean:{location(decided)}:1: unexpected token\n", decided, False),
    ("type failure", f"error: TauWeb/Pins.lean:{location(decided)}:1: type mismatch\n", decided, False),
    ("resource failure", proposition +
     f"error: TauWeb/Pins.lean:{location(decided)}:1: maximum recursion depth has been reached\n",
     decided, False),
    ("printer failure", proposition +
     f"error: TauWeb/Pins.lean:{location(decided)}:1: failed to pretty print expression\n",
     decided, False),
    ("arbitrary open goal", goal.replace("⊢ Source.published = Source.rescueLast", "⊢ False"),
     open_goal, False),
    ("additional case", goal.replace("⊢ Source.published = Source.rescueLast",
      "⊢ False\ncase unexpected\n⊢ Source.published = Source.rescueLast"), open_goal, False),
    ("additional goal without case", goal.replace("⊢ Source.published = Source.rescueLast",
      "⊢ False\n⊢ Source.published = Source.rescueLast"), open_goal, False),
    ("source goal without admission", goal.replace("hadm : True\n", ""), open_goal, False),
    ("incomplete open goal", goal.removesuffix("⊢ Source.published = Source.rescueLast\n"),
     open_goal, False),
    ("generic open goal",
     f"error: TauWeb/Pins.lean:{location(open_goal)}:1: unsolved goals\n"
     "case unexpected\n⊢ False\n", open_goal, False),
    ("missing property", "warning: only a warning\n", decided, False),
    ("duplicate property", proposition + proposition, decided, False),
]
for name, header in progress:
    cases.extend(((f"decided with {name} progress", proposition + header, decided, True),
                  (f"open goal with {name} progress", goal + header, open_goal, True)))

for name, diagnostic, expected, allowed in cases:
    log = scratch / "diagnostic.log"
    log.write_text(diagnostic)
    result = subprocess.run([sys.executable, str(parser_path), str(source_path),
                             str(log), expected], capture_output=True, text=True)
    if (result.returncode == 0) != allowed:
        print(f"FAIL: {name}: exit {result.returncode}: {result.stdout}{result.stderr}")
        sys.exit(1)
print(f"pin diagnostic parser: {len(cases)} cases passed")

# Dispatch retains the exact residual equality after the additional refusal branch. A
# neighboring case or arbitrary equality is still rejected; no generic open-goal rule exists.
source_path = root / "tools/formal/TauWeb/Dispatch.lean"
source = source_path.read_text().splitlines()
binding_goal = (f"error: TauWeb/Dispatch.lean:{location('admit_dispatched')}:1: unsolved goals\n"
                "case h_2.isFalse.isFalse\np : Params\n⊢ rq.session = ap.session\n")
dispatch_cases = [
    ("exact binding goal", binding_goal, True),
    ("binding goal with build output", binding_goal + noise, True),
    ("old binding case", binding_goal.replace("h_2.isFalse.isFalse", "h_2.isFalse"), False),
    ("arbitrary binding goal", binding_goal.replace("rq.session = ap.session", "False"), False),
    ("additional binding goal", binding_goal + "⊢ False\n", False),
    ("duplicate binding diagnostic", binding_goal + binding_goal, False),
]
for name, diagnostic, allowed in dispatch_cases:
    log = scratch / "dispatch-diagnostic.log"
    log.write_text(diagnostic)
    result = subprocess.run([sys.executable, str(parser_path), str(source_path),
                             str(log), "admit_dispatched"], capture_output=True, text=True)
    if (result.returncode == 0) != allowed:
        print(f"FAIL: {name}: exit {result.returncode}: {result.stdout}{result.stderr}")
        sys.exit(1)
print(f"dispatch diagnostic parser: {len(dispatch_cases)} cases passed")
