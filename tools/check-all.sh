#!/usr/bin/env bash
# Run every specification gate this repository has (ADR-0032).
#
# Each gate runs to completion and its exit status is captured directly -- never
# through a pipe, which would report the status of the last command in the
# pipeline rather than the gate's own.
#
# Exit status 0 = every gate passed.

set -uo pipefail

cd "$(dirname "$0")/.." || exit 2

declare -a NAMES=()
declare -a CODES=()
overall=0

run() {
  local name="$1"; shift
  echo
  echo "=============================================================="
  echo "  $name"
  echo "=============================================================="
  "$@"
  local rc=$?
  NAMES+=("$name")
  CODES+=("$rc")
  [ "$rc" -ne 0 ] && overall=1
  return 0
}

# The formal gate runs first: the citations gate resolves `TauWeb.*` names against the
# index it writes, and a stale index is a gate reading last week's truth.
run "formal       (Lean build, axiom policy, @[req] index, witness emission; needs the nix develop shell)" bash tools/check_formal.sh
run "witnesses    (a committed witness file under docs/design/ that differs from the emission)" python3 tools/check_witnesses.py
run "regions      (a marked region in a document that is not what its declaration emits)" python3 tools/check_regions.py
run "identifiers  (duplicates, dangling, pointers, gaps, ADR refs, CNF tiers)" python3 tools/check_ids.py
run "fixtures     (every JSON example parses; every Mermaid block is structurally whole)" python3 tools/check_fixtures.py
run "obligations  (a duty assigned to a requirement whose own text names none of the machinery)" python3 tools/check_obligations.py
run "citations    (a quoted attribution its target does not contain; unquoted ones ratcheted; TauWeb.* names)" python3 tools/check_citations.py
run "coverage     (requirements exercised by at least one CNF item, ratcheted)" python3 tools/check_coverage.py

echo
echo "=============================================================="
echo "  SUMMARY"
echo "=============================================================="
for i in "${!NAMES[@]}"; do
  if [ "${CODES[$i]}" -eq 0 ]; then status="PASS"; else status="FAIL"; fi
  printf '  %-4s  %s\n' "$status" "${NAMES[$i]}"
done
echo

if [ "$overall" -eq 0 ]; then
  echo "All gates passed."
else
  echo "One or more gates FAILED."
fi
exit "$overall"
