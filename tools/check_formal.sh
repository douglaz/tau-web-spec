#!/usr/bin/env bash
# The formal companion's gate (ADR-0032): refuse a module under TauWeb/ the build never
# reads, build every Lean module, then run `lake exe gate`, which refuses a @[req]
# declaration whose proof depends on an axiom outside propext / Classical.choice /
# Quot.sound -- so `sorry` and a project `axiom` are red -- refuses `native_decide`
# outside TauWeb.Explore, and refuses an empty index. The index it writes is what the
# citations gate resolves `TauWeb.*` names against, so check-all.sh runs this first.
#
# Needs `lake` and `lean` on PATH: run under `nix develop` (flake.nix). A missing tool
# is a failure, not a skip.
set -uo pipefail

# Before anything that needs a PATH, so that an empty one is reported as this.
for tool in lake lean; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "FAIL: $tool not on PATH -- run under 'nix develop' (see flake.nix)"
    exit 1
  fi
done

cd "$(dirname "$0")/formal" || exit 2

# A theorem is never conformance: no CNF identifier anywhere in the formal tree.
if grep -rnE 'CNF-[0-9]+' --exclude-dir=.lake . ; then
  echo "FAIL: a CNF identifier in tools/formal/ -- a theorem is never conformance (ADR-0032)"
  exit 1
fi

lake build || exit 1

# Every module under TauWeb/ must be reachable from TauWeb.lean through imports, read by
# Lean itself (`lean --deps`) rather than a grep a commented-out `import` would fool. After
# the build, because `lean --deps` resolves imports through the built .olean files.
reached="TauWeb"
queue="TauWeb.lean"
while [ -n "$queue" ]; do
  next=""
  for f in $queue; do
    deps="$(lake env lean --deps "$f")" || { echo "FAIL: lean --deps $f failed: $deps"; exit 1; }
    for olean in $(echo "$deps" | grep -oE 'TauWeb(/[A-Za-z0-9_]+)*\.olean$'); do
      m="$(echo "${olean%.olean}" | tr / .)"
      case " $reached " in *" $m "*) ;; *) reached="$reached $m"; next="$next $(echo "$m" | tr . /).lean";; esac
    done
  done
  queue="$next"
done
while IFS= read -r f; do
  m="$(echo "${f%.lean}" | tr / .)"
  case " $reached " in *" $m "*) ;; *)
    echo "FAIL: $f exists but nothing imports $m from TauWeb.lean -- the build never reads it"
    exit 1;;
  esac
done < <(find TauWeb -name '*.lean' | sort)

# Written only on a green run: a red run must not leave an index the citations gate resolves
# against as if it were this run's truth.
lake exe gate > .lake/index.new
rc=$?
[ "$rc" -eq 0 ] || { rm -f .lake/index.new; exit "$rc"; }
mv .lake/index.new .lake/index.jsonl
echo "index: $(wc -l < .lake/index.jsonl) tagged declarations -> tools/formal/.lake/index.jsonl"
