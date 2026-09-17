#!/usr/bin/env bash
# Negative controls: prove each specification gate can fail, for the reason it
# exists (CNF-3's rule, applied to this repository's own gates).
#
# Each control copies the tree to a scratch directory, breaks one thing, and
# requires the gate to go red with exactly one finding, naming that thing. A red
# for another reason -- a mutation that did not apply, a second finding the
# mutation caused by accident -- is not evidence the check works, and fails the
# control. `.github/workflows/ci.yml` runs this after check-all.sh on every push.
#
# Exit status 0 = every control passed.

set -uo pipefail

cd "$(dirname "$0")/.." || exit 2

fail=0
passed=0
expected=0

# control NAME GATE MUTATION LABEL TOKEN
#   MUTATION is evaluated inside the scratch copy; it must exit 0 or the control
#   fails as "did not apply". LABEL is the gate's finding line that must carry
#   TOKEN; every other finding line must read "none".
control() {
  local name="$1" gate="$2" mutate="$3" label="$4" token="$5"
  expected=$((expected + 1))
  local tmp
  tmp="$(mktemp -d)"
  cp -r . "$tmp/repo"
  if ! (cd "$tmp/repo" && eval "$mutate"); then
    echo "::error::$name: the mutation did not apply"; fail=1; rm -rf "$tmp"; return
  fi
  local out rc
  out="$(cd "$tmp/repo" && python3 "$gate" 2>&1)"
  rc=$?
  rm -rf "$tmp"
  local findings
  findings="$(grep -E '^[A-Z ]+:' <<<"$out" | grep -vc ': none$')"
  if [ "$rc" -eq 0 ]; then
    echo "::error::$name: $gate passed"; echo "$out"; fail=1
  elif ! grep -qE "^$label: .*$token" <<<"$out"; then
    echo "::error::$name: the red is not under '$label' naming $token"; echo "$out"; fail=1
  elif [ "$findings" -ne 1 ]; then
    echo "::error::$name: $findings findings, expected exactly one"; echo "$out"; fail=1
  else
    echo "ok: $name -> $label names $token"
    passed=$((passed + 1))
  fi
}

IDS=tools/check_ids.py

control "identifiers: a dangling citation" "$IDS" \
  "printf '\nA citation to \`STA-9999\`, which nothing defines.\n' >> 00-overview.md" \
  "DANGLING" "STA-9999"

control "identifiers: a dangling citation with no backticks" "$IDS" \
  "printf '\nA Mermaid note cannot backtick, so STA-9998 is a citation too.\n' >> 00-overview.md" \
  "DANGLING" "STA-9998"

control "identifiers: a duplicate definition" "$IDS" \
  "printf '\n**ARC-1** A second definition of an identifier already defined.\n' >> 00-overview.md" \
  "DUPES" "ARC-1"

# STA-12 is defined, cited nowhere, and not its family's highest number, so
# removing its definition opens a gap and nothing else.
control "identifiers: an unlisted gap" "$IDS" \
  "sed -i 's/^\*\*STA-12\*\*/**gone**/' 03-state-and-recovery.md && grep -q '^\*\*gone\*\*' 03-state-and-recovery.md" \
  "NUMBER GAPS" "'STA-': \[12\]"

control "identifiers: an id far above its neighbours" "$IDS" \
  "printf '\n**ARC-9999** An identifier far above its neighbours.\n' >> 01-architecture.md" \
  "OUTLIER IDS" "'ARC-': \[9999\]"

control "identifiers: a reference to an ADR that does not exist" "$IDS" \
  "printf '\nDecided in ADR-9999, which does not exist.\n' >> 00-overview.md" \
  "BAD ADR REFS" "ADR-9999"

control "identifiers: a withdrawn identifier defined again" "$IDS" \
  "printf '\n**STG-8** A withdrawn identifier defined again.\n' >> 06-first-stage.md" \
  "WITHDRAWN BUT DEFINED" "STG-8"

control "identifiers: a pointer to nothing" "$IDS" \
  "sed -i 's/^\*\*ARC-23\*\* Members MUST/**gone ARC-23** Members MUST/' docs/tenants/btc-policy/profile.md && grep -q '^\*\*gone ARC-23\*\*' docs/tenants/btc-policy/profile.md" \
  "POINTER TO NOTHING" "ARC-23"

# The tier is re-tagged off an existing item rather than appended as CNF-9999,
# which would be refused as an outlier whether or not the tier check existed.
control "identifiers: a conformance item with no tier" "$IDS" \
  "sed -i 's/^- \[ \] \*\*CNF-5 · BLOCKING\*\*/- [ ] **CNF-5**/' 07-conformance.md && grep -q '^- \[ \] \*\*CNF-5\*\*' 07-conformance.md" \
  "UNTIERED CNF ITEMS" "CNF-5"

control "identifiers: a conformance item with a misspelt tier" "$IDS" \
  "sed -i 's/^- \[ \] \*\*CNF-5 · BLOCKING\*\*/- [ ] **CNF-5 · BLOKING**/' 07-conformance.md && grep -q '^- \[ \] \*\*CNF-5 · BLOKING\*\*' 07-conformance.md" \
  "UNTIERED CNF ITEMS" "CNF-5"

CITES=tools/check_citations.py

control "citations: a quoted phrase its target never contained" "$CITES" \
  "printf '\n\`STA-24\` says \"a phrase its target never contained anywhere\".\n' >> 00-overview.md" \
  "UNVERIFIED QUOTES" "00-overview.md:STA-24"

control "citations: a new unquoted attribution above the baseline" "$CITES" \
  "printf '\n\`STA-24\` says something this sentence does not quote.\n' >> 00-overview.md" \
  "NEW UNQUOTED ATTRIBUTIONS" "00-overview.md:STA-24"

COV=tools/check_coverage.py

# STA-25 is the family's next number; the coverage gate alone runs here, so the
# identifier gate's gap and outlier checks are not what goes red.
control "coverage: a requirement appended with no conformance item" "$COV" \
  "printf '\n**STA-25** A requirement no conformance item exercises.\n' >> 03-state-and-recovery.md" \
  "ABOVE BASELINE" "uncovered > "

# CHN-13 is cited by exactly one item, on CNF-43's continuation line: the
# parser reads a real item line, and its citation is what keeps CHN-13 covered.
control "coverage: a citation removed from a real CNF line" "$COV" \
  "sed -i 's/(\`CHN-13\`)\./(the relay row rule)./' 07-conformance.md && grep -q 'the relay row rule' 07-conformance.md" \
  "ABOVE BASELINE" "uncovered > "

echo
if [ "$passed" -ne "$expected" ]; then
  echo "::error::$passed of $expected controls passed"; fail=1
else
  echo "All $passed controls passed."
fi
exit "$fail"
