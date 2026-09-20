#!/usr/bin/env bash
# Controls: prove each specification gate can fail, for the reason it exists
# (CNF-3's rule, applied to this repository's own gates) -- and, where a gate
# could pass by refusing everything, that it still accepts what it must.
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

# passes NAME GATE MUTATION
#   The other direction: a gate that reddens on everything is not a check. The
#   mutation must apply and the gate must stay green.
passes() {
  local name="$1" gate="$2" mutate="$3"
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
  if [ "$rc" -ne 0 ]; then
    echo "::error::$name: $gate went red"; echo "$out"; fail=1
  else
    echo "ok: $name -> stays green"
    passed=$((passed + 1))
  fi
}

# formal_control NAME MUTATION TOKEN [ABSENT]
#   The formal gate's shape differs: no labelled finding lines, one FAIL. The gate must go
#   red naming TOKEN, and must not name ABSENT (the neighbour the mutation leaves within
#   policy). Runs on the scratch copy's own .lake, so the rebuild is incremental.
formal_control() {
  local name="$1" mutate="$2" token="$3" absent="${4:-}"
  expected=$((expected + 1))
  local tmp
  tmp="$(mktemp -d)"
  cp -r . "$tmp/repo"
  if ! (cd "$tmp/repo" && eval "$mutate"); then
    echo "::error::$name: the mutation did not apply"; fail=1; rm -rf "$tmp"; return
  fi
  local out rc
  out="$(cd "$tmp/repo" && bash tools/check_formal.sh 2>&1)"
  rc=$?
  rm -rf "$tmp"
  if [ "$rc" -eq 0 ]; then
    echo "::error::$name: the formal gate passed"; echo "$out"; fail=1
  elif ! grep -qF "$token" <<<"$out"; then
    echo "::error::$name: the red does not name $token"; echo "$out"; fail=1
  elif [ -n "$absent" ] && grep -qF "$absent" <<<"$out"; then
    echo "::error::$name: the red also names $absent, which is within policy"; echo "$out"; fail=1
  else
    echo "ok: $name -> $token"
    passed=$((passed + 1))
  fi
}

FORMAL=tools/check_formal.sh
ALLOC=tools/formal/TauWeb/Allocation.lean

# `lake build` accepts a sorry with a warning; only the gate's axiom walk sees sorryAx.
formal_control "formal: a sorry the build accepts" \
  "sed -i 's/^@\[req \"STA-22a\"\] theorem total : ∀ n, n < count → (row n).isSome := by decide$/@[req \"STA-22a\"] theorem total : ∀ n, n < count → (row n).isSome := by sorry/' $ALLOC && grep -q ':= by sorry' $ALLOC" \
  "TauWeb.Allocation.total (STA-22a) depends on [sorryAx]"

# The same proof inside and outside Explore: only the outside one is refused.
formal_control "formal: native_decide outside Explore" \
  "printf '\nnamespace TauWeb.Explore\ntheorem in_explore : TauWeb.Allocation.count = 5 := by native_decide\nend TauWeb.Explore\ntheorem TauWeb.Allocation.outside_explore : TauWeb.Allocation.count = 5 := by native_decide\n' >> $ALLOC" \
  "TauWeb.Allocation.outside_explore uses native_decide outside TauWeb.Explore" \
  "in_explore"

# Reachability is read through Lean: a commented-out import does not count.
formal_control "formal: a module file the umbrella does not import" \
  "printf 'import TauWeb.Req\nnamespace TauWeb.Orphan\ndef unread : Nat := 1\nend TauWeb.Orphan\n' > tools/formal/TauWeb/Orphan.lean && printf '\n-- import TauWeb.Orphan\n' >> tools/formal/TauWeb.lean" \
  "nothing imports TauWeb.Orphan"

formal_control "formal: a CNF identifier in the formal tree" \
  "printf '\n-- exercised by CNF-83\n' >> $ALLOC" \
  "a CNF identifier in tools/formal/"

# The restored-seed guard (STA-22b, 2026-09-09) is one field of TauWeb.Allocation.current.
# Flipped, `lake build` must go red with exactly one error, in the allocation module, and it
# must be `decide` refuting stale_sheet_refused's own proposition -- a second error would
# mean a neighbouring witness asserts what this guard decides, and a red elsewhere would
# mean the mutation broke something other than the property it targets.
expected=$((expected + 1))
tmp="$(mktemp -d)"
cp -r . "$tmp/repo"
if ! (cd "$tmp/repo" && sed -i 's/^@\[req "STA-22b"\] def current : Params := { restoredAllocatesNone := true }$/@[req "STA-22b"] def current : Params := { restoredAllocatesNone := false }/' $ALLOC && grep -q 'def current : Params := { restoredAllocatesNone := false }$' $ALLOC); then
  echo "::error::formal: the guard flip did not apply"; fail=1
else
  out="$(cd "$tmp/repo" && bash "$FORMAL" 2>&1)"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "::error::formal: the formal gate passed with the restored-seed guard removed"; echo "$out"; fail=1
  elif [ "$(grep -c '^error: TauWeb/' <<<"$out")" -ne 1 ]; then
    echo "::error::formal: the guard flip did not produce exactly one error"; echo "$out"; fail=1
  elif ! grep -qE "^error: TauWeb/Allocation.lean:[0-9]+:[0-9]+: Tactic .decide. proved that the proposition" <<<"$out" \
       || ! grep -A1 'proved that the proposition' <<<"$out" | grep -q '(staleSheetTrace current).issued = \[m1, m0\]'; then
    echo "::error::formal: the red is not decide refuting stale_sheet_refused in the allocation module"; echo "$out"; fail=1
  else
    echo "ok: formal: the restored-seed guard flipped -> stale_sheet_refused"; passed=$((passed + 1))
  fi
fi
rm -rf "$tmp"

# A decided witness no trace in the emitter names (Witnesses.lean) is red, naming it, before
# any file is written.
formal_control "formal: a tagged witness the emitter does not reach" \
  "printf '\n@[req \"STA-22b\"] theorem TauWeb.Allocation.unreached : TauWeb.Allocation.init.journal.epoch = 0 := by decide\n' >> $ALLOC" \
  "witness TauWeb.Allocation.unreached is tagged but no trace in the emitter reaches it (module allocation)"

DECL=tools/formal/TauWeb/Declaration.lean

# The field table (ARC-39) is a function over TauWeb.Declaration.Field with no wildcard: a
# field added without its row is a missing case, red at the table before anything else.
formal_control "formal: a declaration field added without its row" \
  "sed -i 's/^  | defaultCredentials$/  | defaultCredentials\n  | added/' $DECL && grep -q '^  | added$' $DECL" \
  "Field.added"

# The 2026-09-16 rule -- what an empty list means is the field's own -- is one field of
# TauWeb.Declaration.current. Flipped, the build must go red with decide refuting
# empty_inbound_refused's own proposition: the empty inbound list with a socket answering
# is a finding.
formal_control "formal: the empty-list rule flipped" \
  "sed -i 's/^@\[req \"ARC-39\"\] def current : Params := { emptyMeansPerField := true }$/@[req \"ARC-39\"] def current : Params := { emptyMeansPerField := false }/' $DECL && grep -q 'def current : Params := { emptyMeansPerField := false }$' $DECL" \
  "r.verdict Field.listenersInbound = some Verdict.finding ∧ r.delivered = false
is false"

RELAY=tools/formal/TauWeb/Relay.lean

# The 2026-09-16 fix -- two orderings where the shorthand named one -- is one field of
# TauWeb.Relay.current. Flipped, the relay's only order is against OK, which collapses
# authAccepted and okSent into one gate. `lake build` must go red with exactly two errors, both
# the first ordering: `decide` refuting dial_before_auth_refused, whose dial before the AUTH now
# reaches the dialer, and `decide` refuting `bounded`, which closes over that same property
# within the bound. A third error, or a red naming the second ordering -- which the shorthand
# keeps, and which needs no guard -- would mean the flip broke something other than the property
# it targets.
expected=$((expected + 1))
tmp="$(mktemp -d)"
cp -r . "$tmp/repo"
if ! (cd "$tmp/repo" && sed -i 's/^@\[req "CHN-15"\] def current : Params := { dialRequiresAuthAccepted := true }$/@[req "CHN-15"] def current : Params := { dialRequiresAuthAccepted := false }/' $RELAY && grep -q 'def current : Params := { dialRequiresAuthAccepted := false }$' $RELAY); then
  echo "::error::formal: the ordering flip did not apply"; fail=1
else
  out="$(cd "$tmp/repo" && bash "$FORMAL" 2>&1)"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "::error::formal: the formal gate passed with the two orderings collapsed"; echo "$out"; fail=1
  elif [ "$(grep -c '^error: TauWeb/' <<<"$out")" -ne 2 ]; then
    echo "::error::formal: the ordering flip did not produce exactly two errors"; echo "$out"; fail=1
  elif ! grep -qF 's.dialed = [] ∧ s.okSent = false ∧ s.phase = Phase.authAccepted ∧ s.accepted = true' <<<"$out" \
       || ! grep -qF '(s.dialed.isEmpty || s.accepted)' <<<"$out"; then
    echo "::error::formal: the reds are not dial_before_auth_refused and bounded"; echo "$out"; fail=1
  elif grep -qF 's.forwarded = 0 ∧ s.okSent = false ∧ s.phase = Phase.closed' <<<"$out"; then
    echo "::error::formal: a red also names the second ordering, which the shorthand keeps"; echo "$out"; fail=1
  else
    echo "ok: formal: the two orderings collapsed -> dial_before_auth_refused and bounded"; passed=$((passed + 1))
  fi
fi
rm -rf "$tmp"

# The dialer takes the classified address and nothing else: a hostname passed to it is a type
# error, so "without a second resolution inside the dialer" is checked by the elaborator rather
# than asserted in prose.
formal_control "formal: a hostname passed to the dialer" \
  "printf '\ndef TauWeb.Relay.dialsAName : TauWeb.Relay.Addr := TauWeb.Relay.dial (TauWeb.Relay.Host.dns 1)\n' >> $RELAY" \
  "Host.dns 1"

DISP=tools/formal/TauWeb/Dispatch.lean

# The planes are functions over TauWeb.Dispatch.Kind with no wildcard: an operation added without
# one is a missing case, red at the plane before anything else.
formal_control "formal: a dispatch operation added without a plane" \
  "sed -i 's/^  | create$/  | added\n  | create/' $DISP && grep -q '^  | added$' $DISP" \
  "Kind.added"

# The barrier's carve-out is what is dispatched, not what is outstanding: an unresolved box-plane
# command still bars a cloud-plane operation (STA-24's general rule; STA-20b "waits for all
# tracked commands to end"). Narrowed to cloud-plane callers, the bounded property -- which is
# stated without `bars`, so it decides what `bars` reads -- must go red, and must not name the
# resource key's own witness, which this mutation does not touch.
formal_control "formal: an unresolved box-plane command barring nothing" \
  "sed -i \"s/^  else if cloudPlane k' then true\$/  else if cloudPlane k' then cloudPlane k/\" $DISP && grep -q \"else if cloudPlane k' then cloudPlane k\" $DISP" \
  "atMostOneOutstanding current" \
  "init sameActionEvents"

# STA-24's resource key is one field of TauWeb.Dispatch.current. Switched to the call id -- STA-8
# alone, which "speaks of a call", and every request carries a fresh one -- the barrier refuses
# nothing across call ids. `lake build` must go red with exactly six errors: the two witnesses the
# key is for, the two other refusals it holds up, the disposition's admitted side, which the key
# changes too, and `bounded`, which closes over the barrier. A red naming the reset offer's
# witness, which is the durability rule's and not the key's, would mean the flip broke something
# other than the property it targets.
expected=$((expected + 1))
tmp="$(mktemp -d)"
cp -r . "$tmp/repo"
if ! (cd "$tmp/repo" && sed -i 's/{ resourceKey := .entry,/{ resourceKey := .call,/' $DISP && grep -q '{ resourceKey := .call,' $DISP); then
  echo "::error::formal: the resource key switch did not apply"; fail=1
else
  out="$(cd "$tmp/repo" && bash "$FORMAL" 2>&1)"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "::error::formal: the formal gate passed with the barrier keyed on the call id"; echo "$out"; fail=1
  elif [ "$(grep -c '^error: TauWeb/' <<<"$out")" -ne 6 ]; then
    echo "::error::formal: the resource key switch did not produce exactly six errors"; echo "$out"; fail=1
  elif ! grep -qF 'init sameActionEvents' <<<"$out" || ! grep -qF 'init secondIndexEvents' <<<"$out" \
       || ! grep -qF 'atMostOneOutstanding current' <<<"$out"; then
    echo "::error::formal: the reds are not the two key witnesses and bounded"; echo "$out"; fail=1
  elif grep -qF 'init resetOfferEvents' <<<"$out"; then
    echo "::error::formal: a red also names the reset offer, which the key does not decide"; echo "$out"; fail=1
  else
    echo "ok: formal: the barrier keyed on the call id -> the barrier witnesses and bounded"
    passed=$((passed + 1))
  fi
fi
rm -rf "$tmp"

PINS=tools/formal/TauWeb/Pins.lean

# The admission source is a type, and a source added without the scopes it may pin is a missing
# case in TauWeb.Pins.admits before anything else -- so a new way for a value to reach the
# harness admits nothing until someone decides what it may pin.
formal_control "formal: a pin source added without what it may pin" \
  "sed -i 's/^  | modelText\$/  | modelText\n  | vendorNotify/' $PINS && grep -q '^  | vendorNotify\$' $PINS" \
  "Source.vendorNotify"

# ARC-43's rule -- the source decides what it may pin -- is one field of TauWeb.Pins.current.
# Collapsed, any source may pin anything. `lake build` must go red with exactly two errors: the
# model-text witness, whose set is now journaled as the installed system's pin and admits a
# session, and `bounded`, which closes over the same rule within the bound. A red naming the
# ceremony would mean the flip broke something other than the property it targets, since
# /rescue/last and the job record are admitted under both settings.
expected=$((expected + 1))
tmp="$(mktemp -d)"
cp -r . "$tmp/repo"
if ! (cd "$tmp/repo" && sed -i 's/^@\[req "ARC-43"\] def current : Params := { sourceAdmitsPin := true }$/@[req "ARC-43"] def current : Params := { sourceAdmitsPin := false }/' $PINS && grep -q '^@\[req "ARC-43"\] def current : Params := { sourceAdmitsPin := false }$' $PINS); then
  echo "::error::formal: the source collapse did not apply"; fail=1
else
  out="$(cd "$tmp/repo" && bash "$FORMAL" 2>&1)"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "::error::formal: the formal gate passed with the admission source collapsed"; echo "$out"; fail=1
  elif [ "$(grep -c '^error: TauWeb/' <<<"$out")" -ne 2 ]; then
    echo "::error::formal: the source collapse did not produce exactly two errors"; echo "$out"; fail=1
  elif ! grep -qF 'init modelTextEvents' <<<"$out" \
       || ! grep -qF 'wellPinned (run current start es)' <<<"$out"; then
    echo "::error::formal: the reds are not the model-text witness and bounded"; echo "$out"; fail=1
  elif grep -qF 'init ceremonyEvents' <<<"$out"; then
    echo "::error::formal: a red also names the ceremony, which the source does not decide"; echo "$out"; fail=1
  else
    echo "ok: formal: the admission source collapsed -> the model-text witness and bounded"
    passed=$((passed + 1))
  fi
fi
rm -rf "$tmp"

# A missing toolchain is a red gate, not a skip.
expected=$((expected + 1))
if out="$(env PATH=/nonexistent "$(command -v bash)" "$FORMAL" 2>&1)"; then
  echo "::error::formal: the gate passed with no toolchain on PATH"; echo "$out"; fail=1
elif ! grep -q 'lake not on PATH' <<<"$out"; then
  echo "::error::formal: the red is not the missing toolchain"; echo "$out"; fail=1
else
  echo "ok: formal: a missing toolchain -> lake not on PATH"; passed=$((passed + 1))
fi

WIT=tools/check_witnesses.py
WITFILE=docs/design/allocation-witnesses-v1.json

# Compared against the emission the formal gate wrote before this script ran: one expected
# outcome flipped by hand in the committed file is red, naming the module.
control "witnesses: a committed file edited by hand" "$WIT" \
  "sed -i '0,/\"allocation\":\"admitted\"/s//\"allocation\":\"refused\"/' $WITFILE && ! cmp -s $WITFILE tools/formal/.lake/witnesses/allocation-witnesses-v1.json" \
  "WITNESS DRIFT" "module allocation"

# The emission itself: a CNF identifier in it is refused before the comparison, so the one
# finding is that and not the drift the mutation also causes.
control "witnesses: an emission carrying a CNF identifier" "$WIT" \
  "sed -i 's/\"module\": \"allocation\"/\"module\": \"allocation\", \"exercised_by\": \"CNF-83\"/' tools/formal/.lake/witnesses/allocation-witnesses-v1.json && grep -q CNF-83 tools/formal/.lake/witnesses/allocation-witnesses-v1.json" \
  "WITNESS DRIFT" "module allocation carries a CNF identifier"

control "witnesses: a committed file no module emits" "$WIT" \
  "cp $WITFILE docs/design/orphan-witnesses-v1.json" \
  "WITNESS DRIFT" "orphan-witnesses-v1.json is committed but no module emits it"

REG=tools/check_regions.py
CRED=docs/design/credential-format-v1.md
DECL=docs/design/delivery-declaration-v1.md
RELAY=docs/design/relay-protocol-v1.md
REGJSON=tools/formal/.lake/regions.jsonl
BLOCK='/<!-- formal: TauWeb.Render.roleTable -->/,/<!-- \/formal -->/'

# Compared against the emission the formal gate wrote before this script ran. One outcome token
# changed by hand in the document is red, naming the row and column -- and the prose beside it,
# which the declaration does not determine, is not what the gate reads.
control "regions: an outcome token edited by hand" "$REG" \
  "sed -i 's/^| \`3\` | \*\*pass\*\*/| \`3\` | **handoff**/' \$CRED && grep -q '^| \`3\` | \*\*handoff\*\*' \$CRED" \
  "REGION DRIFT" "row 4, column 2"

# The other direction: a gate that reddens on everything is not a check.
passes "regions: a sentence one line outside a region" "$REG" \
  "sed -i '/^<!-- \/formal -->$/a A sentence one line outside the region.' \$CRED && grep -q '^A sentence one line outside the region.$' \$CRED"

# A region may sit in the requirement its declaration is tagged with or in a document that
# requirement's body links. relay-protocol-v1.md is neither, for STA-22a.
control "regions: a region in a file its requirement does not link" "$REG" \
  "sed -n \"\$BLOCK p\" \$CRED >> \$RELAY && sed -i \"\$BLOCK d\" \$CRED && grep -q 'TauWeb.Render.roleTable' \$RELAY" \
  "REGION PLACEMENT" "neither defines this file nor links it"

control "regions: an outcome token edited in the other region" "$REG" \
  "sed -i 's/| \*\*number\*\* |/| **flag** |/' \$DECL && grep -q '| \*\*flag\*\* |$' \$DECL" \
  "REGION DRIFT" "row 1, column 4"

control "regions: a key column that no longer names its row" "$REG" \
  "sed -i 's/^| \`required\` |/| \`requiredx\` |/' \$DECL && grep -q '^| \`requiredx\` |' \$DECL" \
  "REGION DRIFT" "row 8, key column"

# A region's declaration is tagged, and the index is the list of what is. Dropped from the
# index, the region names a declaration no requirement owns.
control "regions: a region whose declaration the index does not carry" "$REG" \
  "sed -i '/TauWeb.Render.declarationTable/d' tools/formal/.lake/index.jsonl && ! grep -q 'TauWeb.Render.declarationTable' tools/formal/.lake/index.jsonl" \
  "REGION PLACEMENT" "is not in the index"

control "regions: a marker naming a declaration nothing emits" "$REG" \
  "printf '\n<!-- formal: TauWeb.Render.absent -->\n<!-- /formal -->\n' >> \$RELAY" \
  "REGION PLACEMENT" "the declarations do not emit"

control "regions: one declaration rendered in two places" "$REG" \
  "sed -n \"\$BLOCK p\" \$CRED >> \$RELAY && grep -q 'TauWeb.Render.roleTable' \$RELAY" \
  "REGION STRUCTURE" "is already rendered at"

control "regions: a marker never closed" "$REG" \
  "printf '\n<!-- formal: TauWeb.Render.roleTable -->\n' >> \$RELAY" \
  "REGION STRUCTURE" "is never closed"

control "regions: an end marker with no region open" "$REG" \
  "printf '\n<!-- /formal -->\n' >> \$RELAY" \
  "REGION STRUCTURE" "with no open region"

control "regions: a region opened inside another" "$REG" \
  "printf '\n<!-- formal: TauWeb.Render.roleTable -->\n<!-- formal: TauWeb.Render.declarationTable -->\n<!-- /formal -->\n' >> \$RELAY" \
  "REGION STRUCTURE" "a region opened inside the one at line"

# A match region holds the table and nothing else: prose inside it is refused rather than
# silently compared as a row.
control "regions: a line that is not a table row inside a match region" "$REG" \
  "sed -i '/^| \`2\` |/i A sentence inside the region.' \$CRED && grep -q '^A sentence inside the region.$' \$CRED" \
  "REGION STRUCTURE" "a line that is not a table row"

control "regions: an emitted region no document renders" "$REG" \
  "sed -i \"\$BLOCK d\" \$CRED && ! grep -q 'TauWeb.Render.roleTable' \$CRED" \
  "UNRENDERED REGIONS" "TauWeb.Render.roleTable"

# The emitted JSON is a boundary between two programs: an inductive in Lean cannot stop a kind
# the Python gate has no branch for.
control "regions: an emission with a kind the gate does not know" "$REG" \
  "sed -i '0,/\"kind\":\"match\"/s//\"kind\":\"tokens\"/' \$REGJSON && grep -q '\"kind\":\"tokens\"' \$REGJSON" \
  "REGION STRUCTURE" "which is not one of"

# Refused before the comparison, so the one finding is that and not the drift it also causes.
control "regions: an emission carrying a CNF identifier" "$REG" \
  "sed -i 's/\*\*number\*\*/**number** CNF-83/' \$REGJSON && grep -q CNF-83 \$REGJSON" \
  "CNF IN A REGION" "carries CNF-83"

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

# Resolved against the index the formal gate wrote before this script ran.
control "citations: a TauWeb.* name the index does not carry" "$CITES" \
  "printf '\nFormalized as \`TauWeb.Allocation.renamedAway\`.\n' >> 00-overview.md" \
  "UNRESOLVED TAUWEB NAMES" "00-overview.md:TauWeb.Allocation.renamedAway"

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

OBL=tools/check_obligations.py

# STA-12 cites nothing; the sentence is appended to its body so that the duty
# is read inside a requirement, where the gate looks, and STA-24 never mentions
# the machinery it names.
control "obligations: a duty naming machinery its target never mentions" "$OBL" \
  "sed -i 's/^\*\*STA-12\*\*/**STA-12** \`STA-24\` MUST write \`orphaned_column\` before dispatch./' 03-state-and-recovery.md && grep -q 'orphaned_column' 03-state-and-recovery.md" \
  "ORPHANED OBLIGATIONS" "STA-12->STA-24"

FIX=tools/check_fixtures.py
DECL=docs/design/delivery-declaration-v1.md

control "fixtures: a JSON example with a placeholder" "$FIX" \
  "sed -i 's/^  \"drift_checks\": \[\],/  \"drift_checks\": ...,/' $DECL && grep -q '\"drift_checks\": \.\.\.,' $DECL" \
  "BAD JSON" "placeholder"

control "fixtures: a JSON example with a repeated member" "$FIX" \
  "sed -i 's/^  \"required\": \[\],/  \"required\": [], \"required\": [],/' $DECL && grep -q '\"required\": \[\], \"required\"' $DECL" \
  "BAD JSON" "duplicate object member 'required'"

control "fixtures: a JSON example that does not parse" "$FIX" \
  "sed -i 's/^  \"services\": \[\],/  \"services\": [,/' $DECL && grep -q '\"services\": \[,' $DECL" \
  "BAD JSON" "Expecting value"

# Added as a member of the first example only: "version" opens both.
control "fixtures: a JSON example with a malformed digest" "$FIX" \
  "sed -i '0,/^  \"version\": 1,/s//  \"version\": 1, \"sha256\": \"abc\",/' $DECL && grep -q '\"sha256\": \"abc\"' $DECL" \
  "BAD JSON" "sha256 digest is exactly 64 hex"

control "fixtures: a JSON example with a malformed fingerprint" "$FIX" \
  "sed -i '0,/^  \"version\": 1,/s//  \"version\": 1, \"host_fingerprint\": \"nope\",/' $DECL && grep -q '\"host_fingerprint\": \"nope\"' $DECL" \
  "BAD JSON" "not an MD5 colon-hex or SHA256 base64 fingerprint"

control "fixtures: a Mermaid block declaring no diagram type" "$FIX" \
  "sed -i 's/^flowchart LR$/flowchat LR/' 05-trust.md && grep -q '^flowchat LR$' 05-trust.md" \
  "BAD MERMAID" "no known diagram type"

control "fixtures: a Mermaid block with an unbalanced bracket" "$FIX" \
  "sed -i 's/^        U1\[The operator.s device\]$/        U1[The operator\x27s device/' 05-trust.md && grep -q '^        U1\[The operator.s device$' 05-trust.md" \
  "BAD MERMAID" "unbalanced \[\]"

control "fixtures: a Mermaid block with an unpaired quote" "$FIX" \
  "sed -i 's/^    subgraph U\[\"Unavoidable/    subgraph U[Unavoidable/' 05-trust.md && grep -q '^    subgraph U\[Unavoidable' 05-trust.md" \
  "BAD MERMAID" "odd number of double quotes"

control "fixtures: a Mermaid block with a dangling edge" "$FIX" \
  "sed -i 's/^    U --> WORLD$/    U -->/' 05-trust.md && grep -q '^    U -->$' 05-trust.md" \
  "BAD MERMAID" "dangling edge"

control "fixtures: a Mermaid block with an unclosed subgraph" "$FIX" \
  "sed -i '0,/^    end$/{/^    end$/d}' 05-trust.md && [ \$(grep -c '^    end$' 05-trust.md) -eq 2 ]" \
  "BAD MERMAID" "unclosed subgraph"

echo
if [ "$passed" -ne "$expected" ]; then
  echo "::error::$passed of $expected controls passed"; fail=1
else
  echo "All $passed controls passed."
fi
exit "$fail"
