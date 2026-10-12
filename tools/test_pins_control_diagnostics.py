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
                if line.startswith("@[req ") and f"theorem {name} " in line)


decided = "overlapping_publication_refused"
open_goal = "no_rescue_session_before_fill"
proposition = (f"error: TauWeb/Pins.lean:{location(decided)}:1: "
               "Tactic `decide` proved that the proposition\nTrue\nis false\n")
goal = (f"error: TauWeb/Pins.lean:{location(open_goal)}:1: unsolved goals\n"
        "case boot.published\nhadm : True\n⊢ Source.published = Source.rescueLast\n")
noise = ("warning: unrelated warning\n✔ Built TauWeb.Pins\n"
         "Some required targets logged failures:\n- TauWeb.Pins\n")
cases = [
    ("decided clean", proposition, decided, True),
    ("decided with warning and build output", proposition + noise, decided, True),
    ("open goal clean", goal, open_goal, True),
    ("open goal with warning and build output", goal + noise, open_goal, True),
    ("truncated proposition", proposition.removesuffix("is false\n") + noise, decided, False),
    ("unrelated error", proposition + "error: TauWeb/Other.lean:1:1: failed\n", decided, False),
    ("syntax failure", f"error: TauWeb/Pins.lean:{location(decided)}:1: unexpected token\n", decided, False),
    ("arbitrary open goal", goal.replace("⊢ Source.published = Source.rescueLast", "⊢ False"),
     open_goal, False),
    ("missing property", "warning: only a warning\n", decided, False),
    ("duplicate property", proposition + proposition, decided, False),
]

for name, diagnostic, expected, allowed in cases:
    log = scratch / "diagnostic.log"
    log.write_text(diagnostic)
    result = subprocess.run([sys.executable, str(parser_path), str(source_path),
                             str(log), expected], capture_output=True, text=True)
    if (result.returncode == 0) != allowed:
        print(f"FAIL: {name}: exit {result.returncode}: {result.stdout}{result.stderr}")
        sys.exit(1)
print(f"pin diagnostic parser: {len(cases)} cases passed")
