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

# Keep one copy at a time inside this repository. Exclude private run material and the
# scratch root itself; the source tree may contain other runs' scratch too.
scratch_root="$(mktemp -d "$PWD/.control-scratch.XXXXXXXX")" || exit 2
readonly scratch_root
trap 'rm -rf -- "$scratch_root"' EXIT

copy_tree() {
  local destination="$1" entry
  mkdir "$destination/repo" || exit 2
  while IFS= read -r -d '' entry; do
    # Copy only top-level entries that hold tracked files: the gates read the tree git
    # tracks (plus build caches inside it), never local records, scratch or .git itself.
    [ -n "$(git ls-files -- "${entry#./}" | head -n 1)" ] || continue
    cp -a --reflink=auto -- "$entry" "$destination/repo/" || exit 2
  done < <(find . -mindepth 1 -maxdepth 1 -print0)
}

# control NAME GATE MUTATION LABEL TOKEN
#   MUTATION is evaluated inside the scratch copy; it must exit 0 or the control
#   fails as "did not apply". LABEL is the gate's finding line that must carry
#   TOKEN; every other finding line must read "none".
control() {
  local name="$1" gate="$2" mutate="$3" label="$4" token="$5"
  expected=$((expected + 1))
  local tmp
  tmp="$(mktemp -d -p "$scratch_root")"
  copy_tree "$tmp"
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
  tmp="$(mktemp -d -p "$scratch_root")"
  copy_tree "$tmp"
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
FORMAL=tools/check_formal.sh

formal_control() {
  local name="$1" mutate="$2" token="$3" absent="${4:-}"
  expected=$((expected + 1))
  local tmp
  tmp="$(mktemp -d -p "$scratch_root")"
  copy_tree "$tmp"
  if ! (cd "$tmp/repo" && eval "$mutate"); then
    echo "::error::$name: the mutation did not apply"; fail=1; rm -rf "$tmp"; return
  fi
  local out rc
  out="$(cd "$tmp/repo" && bash "$FORMAL" 2>&1)"
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
tmp="$(mktemp -d -p "$scratch_root")"
copy_tree "$tmp"
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
tmp="$(mktemp -d -p "$scratch_root")"
copy_tree "$tmp"
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

PINS=tools/formal/TauWeb/Pins.lean

# The admission source is a type, and a source added without the scopes it may pin is a missing
# case in TauWeb.Pins.admits before anything else -- so a new way for a value to reach the
# harness admits nothing until someone decides what it may pin.
formal_control "formal: a pin source added without what it may pin" \
  "sed -i 's/^  | modelText\$/  | modelText\n  | vendorNotify/' $PINS && grep -q '^  | vendorNotify\$' $PINS" \
  "Source.vendorNotify"

# A mutation must fail in exactly the named property declarations of one module, once each.
# Checking the source locations also rejects syntax/type errors, stale anchors and unrelated
# failed proofs. decl_control FILE NAME MUTATION DECLARATION...
decl_control() {
  local source="$1" name="$2" mutate="$3"
  shift 3
  expected=$((expected + 1))
  local tmp rc
  tmp="$(mktemp -d -p "$scratch_root")"
  copy_tree "$tmp"
  if ! (cd "$tmp/repo" && eval "$mutate"); then
    echo "::error::$name: the mutation did not apply"; fail=1; rm -rf "$tmp"; return
  fi
  (cd "$tmp/repo" && bash "$FORMAL") > "$tmp/output" 2>&1
  rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "::error::$name: the formal gate passed"; fail=1
  elif python3 - "$tmp/repo/$source" "$tmp/output" "$@" <<'PYCONTROL'
import re
import sys
from pathlib import Path
source = Path(sys.argv[1]).read_text().splitlines()
lines = Path(sys.argv[2]).read_text().splitlines()
actual = []
for i, line in enumerate(lines):
    if not line.startswith("error: "):
        continue
    if line in ("error: Lean exited with code 1", "error: build failed"):
        continue
    match = re.fullmatch(r"error: TauWeb/%s:(\d+):\d+: (.*)" % re.escape(Path(sys.argv[1]).name),
                         line)
    if not match:
        print("Unexpected failure:", line)
        sys.exit(1)
    preceding = "\n".join(source[:int(match[1])])
    declarations = re.findall(r"(?:^|\] )(?:theorem|def) (\w+)", preceding, re.MULTILINE)
    decl = declarations[-1] if declarations else "<none>"
    tail = lines[i + 1:]
    # A warning or Lake progress line is outside this error's diagnostic. Keep the
    # proposition or residual goal complete; only recognized diagnostic boundaries end it.
    boundaries = ("error: ", "warning: ", "info: ", "trace: ", "✔ ", "✖ ",
                  "⚠ ", "ℹ ",
                  "Build completed", "Some required targets logged failures:",
                  "- TauWeb.", "LEAN_PATH=")
    end = next((n for n, text in enumerate(tail) if text.startswith(boundaries)), len(tail))
    body = tail[:end]
    if match[2] == "Tactic `decide` proved that the proposition":
        if len(body) < 2 or not any(text.strip() for text in body[:-1]) or body[-1] != "is false":
            print("The decision did not report a false proposition:", line)
            sys.exit(1)
    elif match[2] == "unsolved goals":
        # These exact residual goals are the counterexamples to universal source and
        # durability theorems. Generic open goals, resource failures and printer errors
        # remain unacceptable.
        open_goals = {
            ("no_rescue_session_before_fill", "case boot.attest",
             "⊢ Source.attest author = Source.rescueLast"),
            ("no_rescue_session_before_fill", "case boot.published",
             "⊢ Source.published = Source.rescueLast"),
            ("attest_acceptance_consumes", "case isTrue", "⊢ m ∈ k.consumed"),
            ("consumed_step", "case restart", "⊢ m ∈ []"),
        }
        if (not body or (decl, body[0], body[-1]) not in open_goals or
                sum(text.lstrip().startswith("case ") for text in body) != 1 or
                sum(text.lstrip().startswith("⊢ ") for text in body) != 1):
            print("Unexpected open goal:", line, body[:2], body[-2:])
            sys.exit(1)
        if decl == "no_rescue_session_before_fill" and "hadm : True" not in body:
            print("The source branch did not reach its forbidden admission:", line)
            sys.exit(1)
    else:
        print("Unexpected failure:", line)
        sys.exit(1)
    actual.append(decl)
if sorted(actual) != sorted(sys.argv[3:]):
    print("Expected property failures:", sys.argv[3:])
    print("Actual property failures:", actual)
    sys.exit(1)
PYCONTROL
  then
    echo "ok: $name -> exactly $*"
    passed=$((passed + 1))
  else
    echo "::error::$name: wrong property failures"; cat "$tmp/output"; fail=1
  fi
  rm -rf "$tmp"
}

pins_control() { decl_control "$PINS" "$@"; }
dispatch_control() { decl_control "$DISP" "$@"; }

expected=$((expected + 1))
if python3 tools/test_pins_control_diagnostics.py "$scratch_root"; then
  echo "ok: formal: pin diagnostic parser regressions"
  passed=$((passed + 1))
else
  echo "::error::formal: pin diagnostic parser regressions"; fail=1
fi

# Collapsing source admission permits model text and bypasses author matching as well.
# The dedicated ceremony and valid attest traces must remain green; only these refusals and
# the independent bounded property turn red. The rescue-source witness fixes its own guard.
pins_control "formal: the admission source collapsed" \
  "sed -i 's/^@\[req \"ARC-43\"\] def current : Params := { sourceAdmitsPin := true }$/@[req \"ARC-43\"] def current : Params := { sourceAdmitsPin := false }/' $PINS && grep -q 'def current : Params := { sourceAdmitsPin := false }' $PINS" \
  installed_pin_from_model_text_refused published_rescue_refused wrong_author_refused wrong_author_then_valid bounded

pins_control "formal: attest admits a forbidden rescue pin" \
  "sed -i 's/| .attest _, .boot _ => false/| .attest _, .boot _ => true/' $PINS && grep -q '| .attest _, .boot _ => true' $PINS" \
  no_rescue_session_before_fill attest_rescue_refused

pins_control "formal: recorded-empty rescue baseline refused" \
  "sed -i 's/old.getD \[\]/old.getD fresh/' $PINS && grep -q 'old.getD fresh' $PINS" \
  recorded_empty_rescue_admitted

pins_control "formal: rescue confirmation weakened to inequality" \
  "sed -i 's/!fresh.isEmpty \&\& fresh.all (fun key => !(old.getD \[\]).contains key)/!fresh.isEmpty \&\& fresh != old.getD []/' $PINS && grep -qF 'fresh != old.getD []' $PINS" \
  reordered_rescue_refused overlapping_rescue_refused

pins_control "formal: unread rescue baseline treated as recorded empty" \
  "sed -i 's/(k.snapshot.lookup m).any (fun old =>/(some ((k.snapshot.lookup m).getD none)).any (fun old =>/' $PINS && grep -qF '(some ((k.snapshot.lookup m).getD none)).any (fun old =>' $PINS" \
  unread_rescue_baseline_refused

# An always-refusing attest source is not safe admission. Its positive traces, including each
# guard-removed acceptance, must fail while the universal refusal properties remain provable.
# The earlier-attest-pin refusal also changes because its initial pin is no longer admitted.
pins_control "formal: valid attest admission disabled" \
  "sed -i 's/| .attest author, .machine => !p.attestAuthorMatches || author == plantedSender m/| .attest author, .machine => false/' $PINS && grep -q '| .attest author, .machine => false' $PINS" \
  attest_admits_and_connects wrong_author_admitted wrong_author_then_valid repeat_attest_refused \
  repeat_attest_admitted attest_per_machine failed_attest_admitted failed_append_then_valid \
  attest_after_job_pin_admitted unused_attest_after_reinstall_admitted \
  consumed_attest_after_reinstall_refused earlier_attest_overlap_refused bounded_lifecycle_reachable

pins_control "formal: attest author matching disabled" \
  "sed -i 's/attestAuthorMatches : Bool := true/attestAuthorMatches : Bool := false/' $PINS && grep -q 'attestAuthorMatches : Bool := false' $PINS" \
  wrong_author_refused wrong_author_then_valid bounded

pins_control "formal: attest single use disabled" \
  "sed -i 's/attestSingleUse : Bool := true/attestSingleUse : Bool := false/' $PINS && grep -q 'attestSingleUse : Bool := false' $PINS" \
  repeat_attest_refused consumed_attest_after_reinstall_refused

pins_control "formal: attest admits before a durable append" \
  "sed -i 's/attestDurable : Bool := true/attestDurable : Bool := false/' $PINS && grep -q 'attestDurable : Bool := false' $PINS" \
  failed_attest_refused

# Attest is a first contact only (CHN-5): with the guard removed an introduction replaces a job
# pin, which its refused witness sees and bounded sees through its firstContactOnly clause -- the
# one control that makes that clause false.
pins_control "formal: attest after an installed pin" \
  "sed -i 's/attestFirstContact : Bool := true/attestFirstContact : Bool := false/' $PINS && grep -q 'attestFirstContact : Bool := false' $PINS" \
  attest_after_job_pin_refused bounded

# A pin journaled without its consumption recorded: bounded reds through its consumed-introduction
# clause -- an attest pin has a consumed introduction -- on the first attest pin, beside the
# witnesses that assert consumption. It exercises that clause alone: under current the first-contact
# guard refuses a second attest whatever consumed holds, so this never reaches firstContactOnly.
pins_control "formal: attest pin without a consumed introduction" \
  "sed -i 's/consumed := if pin.source.isAttest then pin.entry :: k.consumed else k.consumed/consumed := if pin.source.isAttest \&\& false then pin.entry :: k.consumed else k.consumed/' $PINS && grep -q 'isAttest && false then' $PINS" \
  attest_acceptance_consumes attest_admits_and_connects wrong_author_admitted wrong_author_then_valid \
  repeat_attest_refused attest_per_machine failed_attest_admitted failed_append_then_valid \
  attest_after_job_pin_admitted unused_attest_after_reinstall_admitted \
  consumed_attest_after_reinstall_refused bounded

pins_control "formal: restart forgets consumed introductions" \
  "sed -i 's/| .restart => { k with sessions := \[\], halts := \[\] }/| .restart => { k with consumed := [], sessions := [], halts := [] }/' $PINS && grep -q '| .restart => { k with consumed := \[\]' $PINS" \
  consumed_step consumed_attest_after_reinstall_refused repeat_attest_refused bounded

# Both directions of the new source branch: admitting a rescue pin violates source scope,
# while an always-refusing installed branch fails successful publication evidence. The new
# older-job trace needs its intermediate publication, and the machine-isolation and disjoint
# traces need their positive publication contacts.
pins_control "formal: LNVPS publication admits a rescue pin" \
  "sed -i 's/| .published, .boot _ => false/| .published, .boot _ => true/' $PINS && grep -q '| .published, .boot _ => true' $PINS" \
  no_rescue_session_before_fill published_rescue_refused bounded

pins_control "formal: valid LNVPS publication disabled" \
  "sed -i 's/| .published, .machine => true/| .published, .machine => false/' $PINS && grep -q '| .published, .machine => false' $PINS" \
  published_source_admitted partial_then_complete_admitted \
  complete_contradiction_admitted_without_guard incomplete_publication_admitted_without_guard \
  overlapping_publication_admitted_without_guard old_pin_admitted_without_reinstall_guard \
  old_pin_admitted_after_restart_without_reinstall_guard pending_restart_then_fresh_admitted \
  pending_restart_per_machine fresh_reinstall_admitted publication_history_per_machine \
  replacement_without_reinstall_refused replacement_without_reinstall_admitted_without_guard \
  cross_source_replacement_refused cross_source_replacement_admitted_without_guard \
  cross_source_after_reinstall_admitted compact_history_keeps_boundary \
  split_partial_completion_admitted \
  partial_polls_complete_after_restart refused_observation_blocks_later_installation \
  duplicate_observation_does_not_restore_pin historic_session_survives_reinstall \
  older_job_after_restart_refused other_machine_job_history_admitted disjoint_after_job_admitted

pins_control "formal: incomplete LNVPS publication admitted" \
  "sed -i 's/publishedComplete : Bool := true/publishedComplete : Bool := false/' $PINS && grep -q 'publishedComplete : Bool := false' $PINS" \
  incomplete_publication_refused empty_publication_refused partial_then_complete_admitted \
  complete_contradiction_after_incomplete_refused complete_contradiction_admitted_without_guard \
  incomplete_history_refuses_after_reinstall_restart older_incomplete_history_refuses \
  compact_history_keeps_boundary split_partial_completion_admitted bounded

# Removing the whole freshness guard also admits the new earlier job/attest overlaps.
pins_control "formal: overlapping LNVPS publication admitted" \
  "sed -i 's/publishedFresh : Bool := true/publishedFresh : Bool := false/' $PINS && grep -q 'publishedFresh : Bool := false' $PINS" \
  incomplete_history_refuses_after_reinstall_restart \
  older_incomplete_history_refuses overlapping_publication_refused \
  older_publication_still_refused_after_restart \
  refused_complete_publication_remains_history \
  refused_observation_blocks_later_installation duplicate_observation_does_not_restore_pin bounded \
  earlier_job_exact_refused earlier_job_overlap_refused earlier_attest_overlap_refused \
  older_job_after_restart_refused

# This removes only the earlier installed-pin comparison. Earlier publication groups stay
# checked, so the job/attest refusals and the independent bounded property isolate the gap.
pins_control "formal: earlier installed pins omitted from publication freshness" \
  "sed -i 's/^  freshAgainstPriorPins k m keys$/  true/' $PINS && grep -q '^  true$' $PINS" \
  earlier_job_exact_refused earlier_job_overlap_refused earlier_attest_overlap_refused \
  older_job_after_restart_refused bounded

pins_control "formal: current installation contradicts an observation" \
  "sed -i 's/publishedWithin : Bool := true/publishedWithin : Bool := false/' $PINS && grep -q 'publishedWithin : Bool := false' $PINS" \
  complete_contradiction_after_incomplete_refused older_incomplete_history_refuses \
  refused_complete_publication_remains_history bounded

pins_control "formal: incomplete LNVPS publications lost from history" \
  "sed -i 's/if pr == .machine then/if pr == .machine \&\& complete keys then/' $PINS && grep -q 'if pr == .machine && complete keys then' $PINS" \
  partial_then_complete_admitted complete_contradiction_after_incomplete_refused \
  incomplete_history_refuses_after_reinstall_restart older_incomplete_history_refuses \
  compact_history_keeps_boundary partial_polls_complete_after_restart \
  split_partial_completion_admitted

# The dedicated second ceremony and all new cross-installation traces need a boundary;
# without it, their installation ordinals, pin admissions or contacts change.
pins_control "formal: reinstall keeps old installed pin active" \
  "sed -i 's/reinstallRetiresPin : Bool := true/reinstallRetiresPin : Bool := false/' $PINS && grep -q 'reinstallRetiresPin : Bool := false' $PINS" \
  incomplete_history_refuses_after_reinstall_restart \
  overlapping_publication_refused overlapping_publication_admitted_without_guard \
  older_publication_still_refused_after_restart refused_complete_publication_remains_history \
  old_pin_refused_pending_reinstall old_pin_refused_after_pending_restart \
  pending_restart_then_fresh_admitted pending_restart_per_machine \
  fresh_reinstall_admitted publication_history_per_machine bounded \
  job_pin_after_reinstall_admitted unused_attest_after_reinstall_admitted \
  consumed_attest_after_reinstall_refused cross_source_after_reinstall_admitted \
  compact_history_keeps_boundary refused_observation_blocks_later_installation \
  duplicate_observation_does_not_restore_pin historic_session_survives_reinstall \
  dedicated_reinstall_admitted earlier_job_exact_refused earlier_job_overlap_refused \
  earlier_attest_overlap_refused older_job_after_restart_refused disjoint_after_job_admitted

# The older job-read pin remains earlier only if restart keeps the ordinal.
pins_control "formal: restart loses installed generation" \
  "sed -i 's/| .restart => { k with sessions := \[\], halts := \[\] }/| .restart => { k with installedGeneration := [], sessions := [], halts := [] }/' $PINS && grep -q '| .restart => { k with installedGeneration := \[\]' $PINS" \
  job_pin_after_reinstall_admitted unused_attest_after_reinstall_admitted \
  consumed_attest_after_reinstall_refused older_publication_still_refused_after_restart \
  old_pin_refused_after_pending_restart pending_restart_then_fresh_admitted pending_restart_per_machine \
  older_job_after_restart_refused

pins_control "formal: restart loses publication history" \
  "sed -i 's/| .restart => { k with sessions := \[\], halts := \[\] }/| .restart => { k with publicationGroups := [], sessions := [], halts := [] }/' $PINS && grep -q '| .restart => { k with publicationGroups := \[\]' $PINS" \
  partial_polls_complete_after_restart incomplete_history_refuses_after_reinstall_restart \
  older_publication_still_refused_after_restart

# The second dedicated job read without a reinstall is an additional same-installation trap.
pins_control "formal: installed pin replaces another source without reinstall" \
  "sed -i 's/installedFirstContact : Bool := true/installedFirstContact : Bool := false/' $PINS && grep -q 'installedFirstContact : Bool := false' $PINS" \
  cross_source_replacement_refused second_job_without_reinstall_refused bounded

# The barrier's carve-out is what is dispatched, not what is outstanding: an unresolved box-plane
# command still bars a cloud-plane operation (STA-24's general rule; STA-20b "waits for all
# tracked commands to end"). Narrowed to cloud-plane callers, the bounded property -- which is
# stated without `bars`, so it decides what `bars` reads -- must go red, beside the two traces in
# which a command's barrier is what refuses a cloud-plane operation: the reinstall a stray command
# pre-empts, and the rescue activation that waits for the command still running. The resource
# key's own witnesses, which this mutation does not touch, stay green.
dispatch_control "formal: an unresolved box-plane command barring nothing" \
  "sed -i \"s/^  else if cloudPlane k' then true\$/  else if cloudPlane k' then cloudPlane k/\" $DISP && grep -q \"else if cloudPlane k' then cloudPlane k\" $DISP" \
  command_preempts_reinstall_without_guard reset_waits_for_other_commands bounded

# STA-24's resource key is one field of TauWeb.Dispatch.current. Switched to the call id -- STA-8
# alone, which "speaks of a call", and every request carries a fresh one -- the barrier refuses
# nothing across call ids. Exactly these go red: the two witnesses the key is for; the two other
# refusals it holds up; the disposition's admitted side, which the key changes too; `bounded`,
# which closes over the barrier; and every trace that states a refusal by the barrier of a call
# under another id -- the reinstall's and the reset's own barrier after a disposition ends, the
# command that pre-empts a reinstall, the reset behind a disposition that was refused or is read
# as never recorded, and the activation behind a command still running. The reset offer's
# witness, which is the durability rule's and not the key's, stays green.
dispatch_control "formal: the barrier keyed on the call id" \
  "sed -i 's/{ resourceKey := .entry,/{ resourceKey := .call,/' $DISP && grep -q '{ resourceKey := .call,' $DISP" \
  same_action_new_call_id_refused second_index_same_entry_refused \
  boot_id_change_not_success_refused resolution_append_failed_refused \
  disposition_unrestricted_admitted destructive_choice_stops_commands \
  command_preempts_reinstall_without_guard disposition_names_own_unresolved_calls \
  replayed_invalid_disposition_means_nothing return_to_rescue_trace \
  reset_waits_for_other_commands bounded

# A disposition's reach, its end and what it may name (STA-24, 2026-10-13) are fields of
# TauWeb.Dispatch.Params, each control one bad edit of one field's rule value. A red set also
# holds another guard's without-guard side where the edit changes what that trace was built to
# show; each comment names the trace the edit is for.

# The reach taken from the resource instead of from the disposed calls: a command after a
# disposed activation that continues must dispatch, and is refused. Two more see it: the
# inference request under a disposition on its own resource, and the command the stop's
# without-guard side expected to go out.
dispatch_control "formal: a disposition's reach taken from the resource" \
  "sed -i 's/reach : Reach := .disposed/reach : Reach := .resource/' $DISP && grep -q 'reach : Reach := .resource' $DISP" \
  continuing_permits_what_was_barred command_preempts_reinstall_without_guard \
  read_and_inference_never_restricted

# The reach applied to every dispatch, the read exemption dropped: a read under a standing
# destructive disposition must dispatch, and is refused -- in the trace that is for it and in the
# abandonment trace, on both of that one's sides.
dispatch_control "formal: a disposition's reach applied to every dispatch" \
  "sed -i 's/reach : Reach := .disposed/reach : Reach := .everyDispatch/' $DISP && grep -q 'reach : Reach := .everyDispatch' $DISP" \
  read_does_not_lift_abandonment read_lifts_abandonment_without_guard \
  continuing_permits_what_was_barred command_preempts_reinstall_without_guard \
  read_and_inference_never_restricted

# The reach computed from the calls still unresolved instead of the disposed ones: it collapses
# to no restriction but the destructive stop, so every cloud-plane operation a disposition
# refused by its reach goes out -- the replaced continuation, the destroy under a reinstall, and
# the reset with no rescue activation.
dispatch_control "formal: a disposition's reach computed from calls still unresolved" \
  "sed -i 's/reach : Reach := .disposed/reach : Reach := .stillUnresolved/' $DISP && grep -q 'reach : Reach := .stillUnresolved' $DISP" \
  disposition_one_continuation_refused replacement_in_force reset_without_rescue_refused \
  return_to_rescue_trace

# The lapse taken at any later intent: reset, disposition, read, command must end refused, and
# the read's own intent ends the restriction. Every trace that states a disposition still
# standing after a later intent sees it.
dispatch_control "formal: a disposition's restriction ended at any later intent" \
  "sed -i 's/lapse : Lapse := .continuation/lapse : Lapse := .anyIntent/' $DISP && grep -q 'lapse : Lapse := .anyIntent' $DISP" \
  read_does_not_lift_abandonment continuing_permits_what_was_barred \
  disposed_activation_bars_commands_without_guard read_and_inference_never_restricted \
  preparation_keeps_restriction return_to_rescue_trace

# The destructive stop dropped: a command after a disposed command with a destructive
# continuation must be refused, and so must one after a disposed activation. Neither disposed
# call bars a command, so the stop is all that refuses either.
dispatch_control "formal: the destructive stop dropped" \
  "sed -i 's/destructiveStops : Bool := true/destructiveStops : Bool := false/' $DISP && grep -q 'destructiveStops : Bool := false' $DISP" \
  destructive_choice_stops_commands_after_activation destructive_choice_stops_commands

# The resource check on a disposition's named calls dropped: one recorded against the sibling
# entry is accepted and ends this entry's call, at recording and on replay alike.
dispatch_control "formal: a disposition matched to a call by call id alone" \
  "sed -i 's/dispositionOwnResource : Bool := true/dispositionOwnResource : Bool := false/' $DISP && grep -q 'dispositionOwnResource : Bool := false' $DISP" \
  disposition_names_own_unresolved_calls replayed_invalid_disposition_means_nothing

# The lapse taken at the reinstall's first operation: a command after the rescue activation must
# be refused, and the activation ends the restriction instead.
dispatch_control "formal: a disposition's restriction ended at the reinstall's first operation" \
  "sed -i 's/lapse : Lapse := .continuation/lapse : Lapse := .firstOperation/' $DISP && grep -q 'lapse : Lapse := .firstOperation' $DISP" \
  preparation_keeps_restriction return_to_rescue_trace

# Any reset ending the restriction: a reset with no rescue activation dispatched since the
# disposition must be refused by the disposition itself. The reset the return-to-rescue trace
# requests before the activation is confirmed is refused by the activation's barrier with or
# without this edit; what that trace loses is its first reset, the one with no activation at all.
dispatch_control "formal: any reset taken for the reinstall" \
  "sed -i 's/resetIntoRescueOnly : Bool := true/resetIntoRescueOnly : Bool := false/' $DISP && grep -q 'resetIntoRescueOnly : Bool := false' $DISP" \
  reset_without_rescue_refused return_to_rescue_trace

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
PINSWIT=docs/design/pins-witnesses-v4.json
PINSEMIT=tools/formal/.lake/witnesses/pins-witnesses-v4.json

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

# The renamed pins file is checked in both directions; each obsolete name must be visible
# as an orphan. Each mutation gives the witness gate exactly one finding.
passes "witnesses: unchanged v1 modules and pins v4" "$WIT" \
  "test -f $WITFILE && test -f $PINSWIT && test -f $PINSEMIT"

control "witnesses: pins v4 committed drift" "$WIT" \
  "sed -i 's/\"schema\": 4/\"schema\": 1/' $PINSWIT && ! cmp -s $PINSWIT $PINSEMIT" \
  "WITNESS DRIFT" "module pins"

control "witnesses: pins v4 missing committed counterpart" "$WIT" \
  "rm $PINSWIT && test ! -e $PINSWIT" \
  "WITNESS DRIFT" "pins-witnesses-v4.json is not committed"

control "witnesses: obsolete pins v2 orphan" "$WIT" \
  "cp $PINSWIT docs/design/pins-witnesses-v2.json" \
  "WITNESS DRIFT" "pins-witnesses-v2.json is committed but no module emits it"

control "witnesses: obsolete pins v3 orphan" "$WIT" \
  "cp $PINSWIT docs/design/pins-witnesses-v3.json" \
  "WITNESS DRIFT" "pins-witnesses-v3.json is committed but no module emits it"

# The dispatch file was renamed with its schema too: its old name is an orphan.
control "witnesses: obsolete dispatch v1 orphan" "$WIT" \
  "cp docs/design/dispatch-witnesses-v2.json docs/design/dispatch-witnesses-v1.json" \
  "WITNESS DRIFT" "dispatch-witnesses-v1.json is committed but no module emits it"

control "witnesses: pins v4 emission carrying a CNF identifier" "$WIT" \
  "sed -i 's/\"module\": \"pins\"/\"module\": \"pins\", \"exercised_by\": \"CNF-18\"/' $PINSEMIT && grep -q CNF-18 $PINSEMIT" \
  "WITNESS DRIFT" "module pins carries a CNF identifier"

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
