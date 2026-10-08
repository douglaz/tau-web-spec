import TauWeb.Req
/-! Module 5, the host-pin lifecycle (ADR-0032's inventory): `SEC-11`, `CHN-R1`, `CHN-R5`, `CHN-5` and `ARC-43`.

**What a pin is held per is a type.** `CHN-R1`: "Every rescue boot has fresh host keys, so the
pin is per boot, not per machine", and the installed system's keys are "generated there, per
machine, and read before reboot". `Per` is those two cases and has no third, so a pin cannot be
held without saying which it is, and the boot case carries the boot that published it.

**A pin's admission source is a type.** `Source` distinguishes the vendor's `/rescue/last`,
the harness's `ready_to_reset` output, the author observed on an attest seal, and model text.
`admits` pairs sources with what they may pin and checks an attest author against the sender
planted for that machine. `journal` enforces single use and durable acceptance before use.
Each guard has a refused-and-admitted witness pair; model text remains the source guard's pair.

**Assumptions, not cryptographic or storage proofs.** Sender and host-key sets are opaque
ordinals. `plantedSender` represents the browser's fixed per-machine sender association, not
an author supplied by the introduction. An attest event reports the seal author after unwrap
and the storage outcome if appending the machine, keys and consumed state together is attempted.
A successful append is assumed durable and atomic; a failed append writes none of them. `restart` retains
that journal and drops session/handshake records. This proves the acceptance rule across such
restarts, not real browser durability, signature verification, first-boot timing, or window expiry.
Attest events are delivered while the browser's introduction window is open; timing remains T40.

**A connection is checked against the pin for that machine, that system and — in rescue — that
boot.** `pinFor` looks the pin up at `perNow`, what the machine's pins are held per now, so a pin
from the previous rescue boot is in the journal and admits nothing: the reset into rescue begins
the next boot as far as the harness is concerned, and until `/rescue/last` publishes that boot's
set there is no pin to check against and the client "MUST wait" (`CHN-R1`). That is the whole of
"Never trust-on-first-use" here: no branch of `check` admits an unpinned handshake.

**A halt against the old pin is not the error.** `SEC-11` halts the session on a key that does
not match, and `STA-20b` says the probe on resume "uses the pin the reset intent named as its
expected next pin, since two pins are journaled at that point and a halt against the old one
means the reset landed" — which `Awaited` carries, read when the intent is journaled. So `Halt`
separates `mismatch`, the error, from `confirmsReset`, which is `STG-4`'s
"The reset into the installed system is confirmed when sshd answers with the installed pin" met
while the probe was reading the old pin. Neither is a session: a halt admits nothing either way.

What the module omits: the fingerprints. A host-key set is an ordinal and never SHA-256 bytes or
key material, the vendor's `authorized_key[]` input side is another rule's, and the poll that
waits some eighty seconds for `/rescue/last` is a timer, which never enters a witness file
(ADR-0032, "What it never carries"). The dispatch of a reset is module 4's — whether the
operation may be dispatched at all is `TauWeb.Dispatch.admit`, and whether a planned reset may be
offered is `TauWeb.Dispatch.offersReset` — so a `reset` here is one already dispatched, and this
module carries only what it does to the pins. The SSH session past the handshake, the relay hop
underneath it (`TauWeb.Relay.start`) and `CHN-R6`'s first contact from a jump host
(owed as a source by T45) are outside it too; `CHN-R4`'s trust on first use is refused, and
no branch here admits it.

ponytail: `boot` and `snapshot` are association lists that only grow, and a lookup reads the
newest entry; the bound is three events, and a map arrives when a longer enumeration needs
one. -/

namespace TauWeb.Pins

/-! ## What a pin is -/

/-- The approved machine entry a pin is held for (`STA-24`'s resource), opaque. -/
abbrev Entry := Nat

/-- The ordinal of a rescue boot on one machine: `0` before the first reset into rescue, and the
next one for each reset dispatched. Never the vendor's `boot_id` and never a clock. -/
abbrev Boot := Nat

/-- A host-key set, opaque. `CHN-R1`: the field "holds **SHA-256 fingerprints, one per host-key
algorithm, and no public key material**"; an ordinal here, so that what is compared is which set
was presented and never its bytes. -/
abbrev Keys := Nat

/-- Symbolic public sender identity, never key bytes. -/
abbrev Sender := Nat

/-- The sender the browser planted for a machine. Distinct ordinals stand for distinct
per-machine keys; derivation and correct planting are assumptions, not proved here. -/
@[req "CHN-R5"] def plantedSender (m : Entry) : Sender := m

/-- Which system a connection is made to, and which of a machine's two key sets answers it. -/
inductive System
  | rescue
  | installed
  deriving DecidableEq, Repr

/-- What a pin is held for. `CHN-R1`: "the pin is per boot, not per machine" for the rescue
system, and the installed system's keys are "generated there, per machine". Two cases and no
third, so a pin cannot be journaled without saying which it is. -/
@[req "CHN-R1"] inductive Per
  | boot (n : Boot)
  | machine
  deriving DecidableEq, Repr

/-- The system a pin held this way answers for. No wildcard: a case added without a system
does not build. -/
def Per.system : Per → System
  | .boot _ => .rescue
  | .machine => .installed

/-- Admission provenance, including the observed seal author. Model text remains expressible
so the production rule can refuse it. -/
@[req "ARC-43"] inductive Source
  | rescueLast
  | readyToReset
  | attest (author : Sender)
  | modelText
  deriving DecidableEq, Repr

def Source.isAttest : Source → Bool
  | .attest _ => true
  | .rescueLast | .readyToReset | .modelText => false

/-- A pin as the harness journals it. -/
structure Pin where
  entry : Entry
  per : Per
  keys : Keys
  source : Source
  deriving DecidableEq, Repr

/-- The rule `ARC-43` makes, as one field, so that removing it is a one-token change. With it the
source decides what it may pin; without it any source may, which is a host key pinned from what a
model said. Its pair is `installed_pin_from_model_text_refused` and
`installed_pin_from_model_text_admitted`. -/
@[req "ARC-43"] structure Params where
  sourceAdmitsPin : Bool
  attestAuthorMatches : Bool := true
  attestSingleUse : Bool := true
  attestDurable : Bool := true
  deriving DecidableEq, Repr

/-- The rule as it stands. -/
@[req "ARC-43"] def current : Params := { sourceAdmitsPin := true }

/-- Which source may pin what: `/rescue/last` publishes the booted rescue system's set, the
`ready_to_reset` job reads the installed system's before unmounting, and attest admits installed
keys only under the planted sender. Total, and the pairing is the function's, so a source added
without what it may pin admits nothing rather than everything. -/
@[req "ARC-43"] def admits (p : Params) (src : Source) (pr : Per) (m : Entry) : Bool :=
  if !p.sourceAdmitsPin then true
  else match src, pr with
    | .rescueLast, .boot _ => true
    | .readyToReset, .machine => true
    | .rescueLast, .machine => false
    | .readyToReset, .boot _ => false
    | .attest author, .machine => !p.attestAuthorMatches || author == plantedSender m
    | .attest _, .boot _ => false
    | .modelText, _ => false

/-! ## What the harness knows -/

/-- An admitted connection, as the record of what it was checked against. -/
structure Session where
  entry : Entry
  system : System
  /-- The rescue boot the machine was in when the connection was made. -/
  boot : Boot
  /-- The set the far sshd presented, which the pin's is. -/
  keys : Keys
  /-- The pin it was admitted against. -/
  pin : Pin
  deriving DecidableEq, Repr

/-- Why a session was halted. `SEC-11`: "a key that does not match MUST halt the session", and
`CHN-R1`: "a client that connects before `/rescue/last` fills has nothing to check against and
MUST wait". `confirmsReset` is the third, which `STA-20b` distinguishes from the error. -/
inductive Halt
  | noPin
  | mismatch
  | confirmsReset
  deriving DecidableEq, Repr

/-- A halted handshake, as the harness records it. -/
structure Halted where
  entry : Entry
  system : System
  keys : Keys
  reason : Halt
  deriving DecidableEq, Repr

/-- A reset intent dispatched and not yet confirmed: the system it resets into and, for the
reset into the installed system, `STA-20b`'s "pin the reset intent named as its expected next
pin" — read when the intent is journaled and never again, since a pin journaled after it is not
the one the reset was approved against. A reset into rescue names none: what that boot will
publish is unknown until `/rescue/last` fills. -/
structure Awaited where
  entry : Entry
  into : System
  expect : Option Keys
  deriving DecidableEq, Repr

/-- Harness knowledge for the pin lifecycle, and nothing about the far side: what the machine's
sshd will present next is external state, and reaches a trace only as what a handshake or a read
reported (`CONTEXT.md`, *Formal companion*). -/
structure Knowledge where
  /-- Machines whose attest introduction was durably accepted. Never cleared on restart. -/
  consumed : List Entry
  /-- The pins journaled, newest first. -/
  pins : List Pin
  /-- What `/rescue/last` showed for a machine when the harness read it, `none` for the empty
  field — `STG-4`'s "one journaled before the reset", which the confirmation is read against.
  A machine whose field the harness never read is absent from this list. Newest first. -/
  snapshot : List (Entry × Option Keys)
  /-- The rescue boot the harness counts for a machine. Newest first. -/
  boot : List (Entry × Boot)
  /-- The reset intents dispatched whose confirmation is outstanding. Newest first. -/
  awaiting : List Awaited
  /-- The resets confirmed, by the system each reset into. -/
  confirmed : List (Entry × System)
  /-- The connections admitted, newest first. -/
  sessions : List Session
  /-- The handshakes halted, newest first. -/
  halts : List Halted
  deriving DecidableEq, Repr

/-- Nothing known: no pin, no boot counted, nothing outstanding. -/
def init : Knowledge :=
  { consumed := [], pins := [], snapshot := [], boot := [], awaiting := [], confirmed := [], sessions := [],
    halts := [] }

/-- The rescue boot the harness counts for a machine: `0` until the first reset into rescue. -/
def bootOf (k : Knowledge) (m : Entry) : Boot := (k.boot.lookup m).getD 0

/-- What a machine's pins are held per now: in the rescue system the boot it is in, in the
installed system the machine itself. -/
def perNow (k : Knowledge) (m : Entry) : System → Per
  | .rescue => .boot (bootOf k m)
  | .installed => .machine

/-- The pin the harness holds for a machine, held per what is asked, if it holds one. -/
def pinAt (k : Knowledge) (m : Entry) (pr : Per) : Option Pin :=
  k.pins.find? fun pin => pin.entry == m && pin.per == pr

/-- The pin a connection to that system is checked against: for that machine, and in rescue for
the boot the machine is in. A pin from the previous boot is still in the journal and is not this;
`CHN-R1` makes that the whole rule — "**with a set different from the one snapshotted before the
reset**" is a new pin, not the old one reused. -/
@[req "SEC-11"] def pinFor (k : Knowledge) (m : Entry) (sys : System) : Option Pin :=
  pinAt k m (perNow k m sys)

/-- `CHN-R1`'s confirmation of the reset into rescue: the field fills "with a set different from
the one snapshotted before the reset". Three halves and not one — the reset is outstanding, the
field holds a set, and there is a snapshot taken before it for that set to differ from. A field
nobody read before the reset is no comparison at all, and a reading taken after it is not the
baseline either, which is why `step` leaves the snapshot alone while the reset is outstanding:
otherwise the field going empty and coming back with the old boot's keys would read as a new
boot, and "`/rescue/last` unchanged means the same" (`STG-4`) would be lost. -/
@[req "CHN-R1"] def confirmsRescue (k : Knowledge) (m : Entry) (keys : Option Keys) : Bool :=
  k.awaiting.any (fun a => a.entry == m && a.into == System.rescue) && keys.isSome &&
    (k.snapshot.lookup m).any (· != keys)

/-- The pin the reset intent named as its expected next pin (`STA-20b`), while a reset into the
installed system is outstanding: the installed pin `ready_to_reset` journaled before it. -/
@[req "STA-20b"] def expectedNext (k : Knowledge) (m : Entry) : Option Keys :=
  (k.awaiting.find? fun a => a.entry == m && a.into == System.installed).bind (·.expect)

/-- `STG-4`: "The reset into the installed system is confirmed when sshd answers with the
installed pin." Read of the handshake and not of the probe: which pin the harness was checking
against does not change what the far side presented. -/
@[req "STA-20b"] def confirmsInstalled (k : Knowledge) (m : Entry) (keys : Keys) : Bool :=
  (expectedNext k m).any (· == keys)

/-- What a handshake comes to. -/
inductive Check
  | admitted (pin : Pin)
  | halted (h : Halt)
  deriving DecidableEq, Repr

/-- `SEC-11`, whole: the presented set is checked against the stored pin, "and a key that does
not match MUST halt the session"; with no pin stored there is nothing to check against, which
`CHN-R1` makes a wait and never a first-use acceptance. A halt the reset explains — the presented
set is the pin the reset intent named — is `STA-20b`'s confirmation and not the error. Total, and
the order is the function's, so no halt can be answered out of its place. -/
@[req "SEC-11"] def check (k : Knowledge) (m : Entry) (sys : System) (keys : Keys) : Check :=
  match pinFor k m sys with
  | some pin =>
    if keys == pin.keys then .admitted pin
    else if confirmsInstalled k m keys then .halted .confirmsReset
    else .halted .mismatch
  | none => if confirmsInstalled k m keys then .halted .confirmsReset else .halted .noPin

/-! ## The trace -/

inductive Event
  /-- A reset, already dispatched (`TauWeb.Dispatch.admit`), into the rescue system or into the
  installed one. -/
  | reset (entry : Entry) (into : System)
  /-- `GET /boot/{n}/rescue/last`: the host-key set the field holds, or `none` while it is
  empty — "its `host_key` is empty" until the booted rescue publishes (`CHN-R1`). -/
  | rescueLast (entry : Entry) (keys : Option Keys)
  /-- The harness's `ready_to_reset` job record (`ARC-43`), with the installed host keys it read
  from the mounted target before unmounting it. -/
  | readyToReset (entry : Entry) (keys : Keys)
  /-- First-boot observation and the outcome if its atomic journal append is attempted. The author is
  untrusted input; the planted sender is read independently through `plantedSender`. -/
  | attest (entry : Entry) (per : Per) (keys : Keys) (author : Sender) (durable : Bool)
  /-- Restart from the durable journal, without volatile session/handshake records. -/
  | restart
  /-- A host-key set named in model text, held per what the model says. -/
  | claim (entry : Entry) (per : Per) (keys : Keys)
  /-- A connection attempt: the system it is made to, and the set the far sshd presents. -/
  | connect (entry : Entry) (system : System) (keys : Keys)
  deriving DecidableEq, Repr

/-- The one place a pin enters the journal, so that the source decides in one place. -/
@[req "ARC-43"] def journal (p : Params) (k : Knowledge) (pin : Pin)
    (durable : Bool := true) : Knowledge :=
  if admits p pin.source pin.per pin.entry &&
      (!pin.source.isAttest || ((!p.attestSingleUse || !k.consumed.contains pin.entry) &&
        (!p.attestDurable || durable))) then
    { k with pins := pin :: k.pins,
             consumed := if pin.source.isAttest then pin.entry :: k.consumed else k.consumed }
  else k

/-- The reset into the installed system, recorded confirmed where the handshake confirmed it
(`STG-4`) — which is read of the presented set and not of the pin the probe was checking
against, so an admitted session and a halt against the old pin record it alike. -/
@[req "STA-20b"] def confirmIfReset (k : Knowledge) (m : Entry) (keys : Keys) : Knowledge :=
  if confirmsInstalled k m keys then
    { k with awaiting := k.awaiting.filter (fun a => !(a.entry == m && a.into == System.installed)),
             confirmed := (m, System.installed) :: k.confirmed }
  else k

/-- One event. A reset into rescue begins the next boot the harness counts, which is what retires
the pin published for the last one. A read of `/rescue/last` is the snapshot while no reset is
outstanding and the comparison once one is: it pins the set and confirms the reset where
`confirmsRescue` holds, and otherwise leaves the baseline where it was, since "the previous
boot's keys are still there until the new boot publishes" (`CHN-R1`). A handshake is `check`, and
the presented set is the reset's confirmation or is not, whichever pin the probe was reading. -/
@[req "SEC-11"] def step (p : Params) (k : Knowledge) : Event → Knowledge
  | .reset m into =>
    let expect := if into == System.installed then (pinAt k m .machine).map (·.keys) else none
    let k := if into == System.rescue then { k with boot := (m, bootOf k m + 1) :: k.boot } else k
    { k with awaiting := ⟨m, into, expect⟩ :: k.awaiting }
  | .rescueLast m keys =>
    match keys, confirmsRescue k m keys with
    | some f, true =>
      let k := { k with snapshot := (m, keys) :: k.snapshot }
      { journal p k ⟨m, .boot (bootOf k m), f, .rescueLast⟩ with
        awaiting := k.awaiting.filter (fun a => !(a.entry == m && a.into == System.rescue)),
        confirmed := (m, System.rescue) :: k.confirmed }
    | _, _ =>
      if k.awaiting.any (fun a => a.entry == m && a.into == System.rescue) then k
      else { k with snapshot := (m, keys) :: k.snapshot }
  | .readyToReset m f => journal p k ⟨m, .machine, f, .readyToReset⟩
  | .attest m pr f author durable => journal p k ⟨m, pr, f, .attest author⟩ durable
  | .restart => { k with sessions := [], halts := [] }
  | .claim m pr f => journal p k ⟨m, pr, f, .modelText⟩
  | .connect m sys keys =>
    let k' := confirmIfReset k m keys
    match check k m sys keys with
    | .admitted pin => { k' with sessions := ⟨m, sys, bootOf k m, keys, pin⟩ :: k'.sessions }
    | .halted h => { k' with halts := ⟨m, sys, keys, h⟩ :: k'.halts }

def run (p : Params) (k : Knowledge) : List Event → Knowledge
  | [] => k
  | e :: es => run p (step p k e) es

/-! ## Over every trace -/

theorem find?_sound {p : Pin → Bool} : ∀ {l : List Pin} {a : Pin},
    l.find? p = some a → a ∈ l ∧ p a = true := by
  intro l
  induction l with
  | nil => intro a h; exact nomatch h
  | cons x xs ih =>
    intro a h
    simp only [List.find?] at h
    split at h
    · rename_i hx
      injection h with h
      subst h
      exact ⟨by simp, hx⟩
    · exact ⟨List.mem_cons_of_mem x (ih h).1, (ih h).2⟩

/-- What a stored pin is: one the harness journaled, for that machine, held per what is in
force now. -/
theorem pinFor_sound {k : Knowledge} {m : Entry} {sys : System} {pin : Pin}
    (h : pinFor k m sys = some pin) :
    pin ∈ k.pins ∧ pin.entry = m ∧ pin.per = perNow k m sys := by
  obtain ⟨hmem, hpred⟩ := find?_sound h
  simp only [Bool.and_eq_true, beq_iff_eq] at hpred
  exact ⟨hmem, hpred.1, hpred.2⟩

/-- A halt the reset explains is one the presented set earned: `check` answers `confirmsReset`
only where the set is the pin the reset intent named. -/
@[req "STA-20b"] theorem confirmsReset_earned {k : Knowledge} {m : Entry} {sys : System}
    {keys : Keys} (h : check k m sys keys = .halted .confirmsReset) :
    confirmsInstalled k m keys = true := by
  unfold check at h
  split at h
  · split at h
    · exact nomatch h
    · split at h
      · assumption
      · exact nomatch h
  · split at h
    · assumption
    · exact nomatch h

/-- **A pin halt against the old pin is never read as an error.** Over every state of the
harness: where the presented set is the pin the reset intent named, the halt `SEC-11` requires is
`STA-20b`'s confirmation, and `mismatch` — the error — is answered only where it is not. -/
@[req "STA-20b"] theorem mismatch_not_the_reset {k : Knowledge} {m : Entry} {sys : System}
    {keys : Keys} (h : check k m sys keys = .halted .mismatch) :
    confirmsInstalled k m keys = false := by
  unfold check at h
  split at h
  · split at h
    · exact nomatch h
    · split at h
      · exact nomatch h
      · simpa using ‹¬(confirmsInstalled k m keys = true)›
  · split at h
    · exact nomatch h
    · exact nomatch h

/-- What holds of harness knowledge after every trace: every session was admitted against a pin
the harness holds, for that machine, for the system it connected to and — in the rescue system —
for the boot it was made in; every pin the harness holds was admitted by its source; and every
halt the reset explains was recorded as its confirmation. -/
def Inv (p : Params) (k : Knowledge) : Prop :=
  (∀ s ∈ k.sessions, s.pin ∈ k.pins ∧ s.pin.entry = s.entry ∧ s.pin.keys = s.keys ∧
      s.pin.per.system = s.system ∧ ∀ b, s.pin.per = .boot b → b = s.boot) ∧
  (∀ pin ∈ k.pins, admits p pin.source pin.per pin.entry = true) ∧
  (∀ h ∈ k.halts, h.reason = .confirmsReset → (h.entry, System.installed) ∈ k.confirmed)

theorem inv_init (p : Params) : Inv p init := by
  refine ⟨?_, ?_, ?_⟩ <;> intro x hx <;> exact nomatch hx

/-- Journaling changes pins and, for attest, consumption; sessions, halts and reset
confirmations are untouched. -/
theorem journal_parts (p : Params) (k : Knowledge) (pin : Pin) (durable : Bool := true) :
    (journal p k pin durable).sessions = k.sessions ∧ (journal p k pin durable).halts = k.halts ∧
    (journal p k pin durable).confirmed = k.confirmed := by
  unfold journal; split <;> exact ⟨rfl, rfl, rfl⟩

/-- Journaling a pin preserves it: the sessions and halts are untouched, the pins grow, and the
one added is one `admits` accepted. -/
theorem inv_journal (p : Params) (k : Knowledge) (pin : Pin) (h : Inv p k)
    (durable : Bool := true) :
    Inv p (journal p k pin durable) := by
  obtain ⟨hs, hp, hh⟩ := h
  unfold journal
  split
  · rename_i hadm
    refine ⟨fun s hsm => ?_, fun q hq => ?_, hh⟩
    · exact ⟨List.mem_cons_of_mem pin (hs s hsm).1, (hs s hsm).2.1, (hs s hsm).2.2.1,
             (hs s hsm).2.2.2.1, (hs s hsm).2.2.2.2⟩
    · rcases List.mem_cons.mp hq with rfl | hq
      · simp only [Bool.and_eq_true] at hadm
        exact hadm.1
      · exact hp q hq
  · exact ⟨hs, hp, hh⟩

/-- What `check` established when it admitted the handshake: the pin it read is the one stored
for that machine and system, and the presented set is that pin's. -/
theorem check_admitted {k : Knowledge} {m : Entry} {sys : System} {keys : Keys} {pin : Pin}
    (h : check k m sys keys = .admitted pin) : pinFor k m sys = some pin ∧ pin.keys = keys := by
  unfold check at h
  split at h
  · rename_i q hq
    split at h
    · rename_i heq
      injection h with h
      subst h
      exact ⟨hq, (beq_iff_eq.mp heq).symm⟩
    · split at h <;> exact nomatch h
  · split at h <;> exact nomatch h

/-- Recording the confirmation touches the pins, the sessions and the halts not at all, and the
resets confirmed only by growing. -/
theorem confirmIfReset_parts (k : Knowledge) (m : Entry) (keys : Keys) :
    (confirmIfReset k m keys).pins = k.pins ∧
    (confirmIfReset k m keys).sessions = k.sessions ∧
    (confirmIfReset k m keys).halts = k.halts ∧
    (∀ x ∈ k.confirmed, x ∈ (confirmIfReset k m keys).confirmed) ∧
    (confirmsInstalled k m keys = true →
      (m, System.installed) ∈ (confirmIfReset k m keys).confirmed) := by
  unfold confirmIfReset
  split
  · exact ⟨rfl, rfl, rfl, fun _ hx => List.mem_cons_of_mem _ hx, fun _ => by simp⟩
  · rename_i hno
    exact ⟨rfl, rfl, rfl, fun _ hx => hx, fun hc => absurd hc (by simp_all)⟩

theorem inv_step (p : Params) (k : Knowledge) (hk : Inv p k) (e : Event) : Inv p (step p k e) := by
  obtain ⟨hs, hp, hh⟩ := hk
  cases e with
  | reset m into =>
    simp only [step]
    split <;> exact ⟨hs, hp, hh⟩
  | rescueLast m keys =>
    simp only [step]
    split
    · rename_i f _
      obtain ⟨hs', hp', hh'⟩ := inv_journal p { k with snapshot := (m, some f) :: k.snapshot }
        ⟨m, .boot (bootOf { k with snapshot := (m, some f) :: k.snapshot } m), f, .rescueLast⟩
        ⟨hs, hp, hh⟩
      obtain ⟨_, _, hconf⟩ := journal_parts p { k with snapshot := (m, some f) :: k.snapshot }
        ⟨m, .boot (bootOf { k with snapshot := (m, some f) :: k.snapshot } m), f, .rescueLast⟩
      exact ⟨hs', hp', fun x hx hr => List.mem_cons_of_mem _ (hconf ▸ hh' x hx hr)⟩
    · split <;> exact ⟨hs, hp, hh⟩
  | readyToReset m f => exact inv_journal p k ⟨m, .machine, f, .readyToReset⟩ ⟨hs, hp, hh⟩
  | attest m pr f author durable =>
    exact inv_journal p k ⟨m, pr, f, .attest author⟩ ⟨hs, hp, hh⟩ durable
  | restart => exact ⟨by simp [step], hp, by simp [step]⟩
  | claim m pr f => exact inv_journal p k ⟨m, pr, f, .modelText⟩ ⟨hs, hp, hh⟩
  | connect m sys keys =>
    obtain ⟨hcp, hcs, hch, hcmono, hcconf⟩ := confirmIfReset_parts k m keys
    simp only [step]
    split
    · rename_i pin hchk
      obtain ⟨hfor, hkeys⟩ := check_admitted hchk
      obtain ⟨hmem, hmach, hper⟩ := pinFor_sound hfor
      have hsys : pin.per.system = sys := by rw [hper]; cases sys <;> rfl
      have hboot : ∀ b, pin.per = Per.boot b → b = bootOf k m := by
        intro b hb
        rw [hb] at hper
        cases sys with
        | rescue => simpa only [perNow, Per.boot.injEq] using hper
        | installed => simp [perNow] at hper
      refine ⟨fun s hsm => ?_, fun q hq => ?_, fun x hx hr => ?_⟩
      · rcases List.mem_cons.mp hsm with rfl | hsm
        · exact ⟨hcp ▸ hmem, hmach, hkeys, hsys, hboot⟩
        · obtain ⟨h1, h2, h3, h4, h5⟩ := hs s (hcs ▸ hsm)
          exact ⟨hcp ▸ h1, h2, h3, h4, h5⟩
      · exact hp q (hcp ▸ hq)
      · exact hcmono _ (hh x (hch ▸ hx) hr)
    · rename_i reason hchk
      refine ⟨fun s hsm => ?_, fun q hq => ?_, fun x hx hr => ?_⟩
      · obtain ⟨h1, h2, h3, h4, h5⟩ := hs s (hcs ▸ hsm)
        exact ⟨hcp ▸ h1, h2, h3, h4, h5⟩
      · exact hp q (hcp ▸ hq)
      · rcases List.mem_cons.mp hx with rfl | hx
        · have hr' : reason = Halt.confirmsReset := hr
          exact hcconf (confirmsReset_earned (by rw [hchk, hr']))
        · exact hcmono _ (hh x (hch ▸ hx) hr)

theorem inv_run (p : Params) (k : Knowledge) (hk : Inv p k) (es : List Event) :
    Inv p (run p k es) := by
  induction es generalizing k with
  | nil => exact hk
  | cons e es ih => exact ih (step p k e) (inv_step p k hk e)

theorem inv (p : Params) (es : List Event) : Inv p (run p init es) :=
  inv_run p init (inv_init p) es

/-- **A rescue pin is never reused across boots.** Over every trace: a session in the rescue
system was admitted against a pin published for the boot that session was made in, never one from
a boot before it. `CHN-R1`'s "Every rescue boot has fresh host keys, so the pin is per boot, not
per machine" is `Per` and this together: the pin the last boot published stays in the journal
and admits nothing, because the reset that ended that boot began the next one. -/
@[req "CHN-R1"] theorem rescue_pin_per_boot (p : Params) (es : List Event) :
    ∀ s ∈ (run p init es).sessions, ∀ b, s.pin.per = .boot b → b = s.boot :=
  fun s hs b hb => ((inv p es).1 s hs).2.2.2.2 b hb

/-- Every installed pin has an authorized source: job output or an attest seal by this
machine's planted sender. Model text and rescue publication remain excluded. Single use and
durability are enforced by `journal`, independently of this source proposition. -/
@[req "ARC-43"] theorem installed_pin_from_authorized_source (p : Params)
    (hp : p.sourceAdmitsPin = true) (ha : p.attestAuthorMatches = true) (es : List Event) :
    ∀ pin ∈ (run p init es).pins, pin.per = .machine →
      pin.source = .readyToReset ∨ pin.source = .attest (plantedSender pin.entry) := by
  intro pin hmem hsc
  have hadm := (inv p es).2.1 pin hmem
  cases hsrc : pin.source with
  | readyToReset => exact Or.inl rfl
  | rescueLast => simp [admits, hp, hsrc, hsc] at hadm
  | modelText => simp [admits, hp, hsrc, hsc] at hadm
  | attest author =>
    simp [admits, hp, ha, hsrc, hsc] at hadm
    all_goals exact Or.inr (congrArg Source.attest hadm)

/-- **No connection before `/rescue/last` fills.** Over every trace, under `ARC-43`'s rule: a
session in the rescue system was admitted against a pin the harness holds for that machine and
that boot, whose set the far side presented, and which only the vendor's published field put
there. `CHN-R1`: "a client that connects before `/rescue/last` fills has nothing to check against
and MUST wait". -/
@[req "CHN-R1"] theorem no_rescue_session_before_fill (p : Params) (hp : p.sourceAdmitsPin = true)
    (es : List Event) :
    ∀ s ∈ (run p init es).sessions, s.system = .rescue →
      ∃ pin ∈ (run p init es).pins, pin.entry = s.entry ∧ pin.per = .boot s.boot ∧
        pin.keys = s.keys ∧ pin.source = .rescueLast := by
  intro s hs hsysEq
  obtain ⟨hmem, hmach, hkeys, hsys, hboot⟩ := (inv p es).1 s hs
  rw [hsysEq] at hsys
  cases hsc : s.pin.per with
  | machine => rw [hsc] at hsys; exact nomatch hsys
  | boot b =>
    have hb := hboot b hsc
    have hadm := (inv p es).2.1 s.pin hmem
    unfold admits at hadm
    rw [hp] at hadm
    refine ⟨s.pin, hmem, hmach, by rw [hsc, hb], hkeys, ?_⟩
    cases hsrc : s.pin.source with
    | rescueLast => rfl
    | readyToReset => rw [hsrc, hsc] at hadm; exact nomatch hadm
    | modelText => rw [hsrc, hsc] at hadm; exact nomatch hadm
    | attest author => simp [hsrc, hsc] at hadm

/-- **A pin halt against the old pin on the installed system is the reset's confirmation.** Over
every trace: every halt recorded as one is the machine's reset into the installed system,
confirmed — `STA-20b`'s resume rule, where "two pins are journaled at that point and a halt
against the old one means the reset landed". That it is not the error is
`mismatch_not_the_reset`, over every state rather than over every trace. -/
@[req "STA-20b"] theorem halt_on_expected_pin_confirms (p : Params) (es : List Event) :
    ∀ h ∈ (run p init es).halts, h.reason = .confirmsReset →
      (h.entry, System.installed) ∈ (run p init es).confirmed :=
  fun h hmem hr => (inv p es).2.2 h hmem hr

/-- Accepted attest pins consume the machine's introduction in the same journal transition. -/
@[req "CHN-5"] theorem attest_acceptance_consumes (p : Params) (k : Knowledge)
    (m : Entry) (pr : Per) (keys : Keys) (author : Sender) (durable : Bool)
    (h : (step p k (.attest m pr keys author durable)).pins ≠ k.pins) :
    m ∈ (step p k (.attest m pr keys author durable)).consumed := by
  simp only [step, journal] at h ⊢
  split at h <;> simp_all [Source.isAttest]

/-- A failed append admits nothing, independently of the source or single-use settings. -/
@[req "CHN-5"] theorem attest_failed_append_refused (p : Params) (hd : p.attestDurable = true)
    (k : Knowledge) (m : Entry) (pr : Per) (keys : Keys) (author : Sender) :
    step p k (.attest m pr keys author false) = k := by
  simp [step, journal, Source.isAttest, hd]

/-- Once consumed, another attest introduction changes nothing, even if author and keys match. -/
@[req "CHN-5"] theorem attest_consumed_refused (p : Params) (hu : p.attestSingleUse = true)
    (k : Knowledge) (m : Entry) (hm : m ∈ k.consumed) (pr : Per) (keys : Keys)
    (author : Sender) (durable : Bool) :
    step p k (.attest m pr keys author durable) = k := by
  simp [step, journal, Source.isAttest, hu, hm]

theorem journal_consumed (p : Params) (k : Knowledge) (pin : Pin) (durable : Bool)
    (m : Entry) (hm : m ∈ k.consumed) : m ∈ (journal p k pin durable).consumed := by
  unfold journal
  split
  · dsimp; split
    · exact List.mem_cons_of_mem _ hm
    · exact hm
  · exact hm

/-- No event, including restart, forgets a consumed introduction. -/
theorem consumed_step (p : Params) (k : Knowledge) (m : Entry) (hm : m ∈ k.consumed)
    (e : Event) : m ∈ (step p k e).consumed := by
  cases e with
  | reset n into => simp only [step]; split <;> exact hm
  | rescueLast n keys =>
    simp only [step]; split
    · exact journal_consumed _ _ _ _ _ hm
    · split <;> exact hm
  | readyToReset n keys => exact journal_consumed _ _ _ _ _ hm
  | attest n pr keys author durable => exact journal_consumed _ _ _ _ _ hm
  | claim n pr keys => exact journal_consumed _ _ _ _ _ hm
  | restart => simp_all only [step]
  | connect n sys keys =>
    simp only [step]; split <;> simp only [confirmIfReset] <;> split <;> exact hm

@[req "CHN-5"] theorem consumed_survives (p : Params) (k : Knowledge) (m : Entry)
    (hm : m ∈ k.consumed) (es : List Event) : m ∈ (run p k es).consumed := by
  induction es generalizing k with
  | nil => exact hm
  | cons e es ih => exact ih _ (consumed_step p k m hm e)

/-- After acceptance, every later trace (including restarts) still refuses this machine's
introduction. The premise can be obtained from `attest_acceptance_consumes`. -/
@[req "CHN-5"] theorem no_later_attest (p : Params) (hu : p.attestSingleUse = true)
    (k : Knowledge) (m : Entry) (hm : m ∈ k.consumed) (es : List Event)
    (pr : Per) (keys : Keys) (author : Sender) (durable : Bool) :
    step p (run p k es) (.attest m pr keys author durable) = run p k es :=
  attest_consumed_refused p hu _ m (consumed_survives p k m hm es) pr keys author durable

/-! ## The witnesses, decided -/

/-- Two approved machine entries, opaque. -/
def entryA : Entry := 1
def entryB : Entry := 2

/-- Four host-key sets, opaque: the set the rescue endpoint showed before the reset, the one the
new rescue boot published, the installed system's as `ready_to_reset` read them, and a set a
model named. -/
def oldRescueKeys : Keys := 10
def rescueKeys : Keys := 11
def installedKeys : Keys := 21
def claimedKeys : Keys := 31

/-! Each witness's events are one named list, so that the theorem and the emitter
(`Witnesses.lean`) run the same trace. -/

/-- The ceremony's pin half, in `STG-4`'s order: the set `/rescue/last` shows before the reset is
snapshotted; the reset is dispatched; the field still shows that set, which is the reset not yet
landed; then it shows a different one, which is the confirmation and the boot's pin; the rescue
session runs against it; `ready_to_reset` reads the installed keys; the reset into the installed
system is dispatched; and sshd answers with the installed pin. -/
def ceremonyEvents : List Event :=
  [.rescueLast entryA (some oldRescueKeys),
   .reset entryA .rescue,
   .rescueLast entryA (some oldRescueKeys),
   .rescueLast entryA (some rescueKeys),
   .connect entryA .rescue rescueKeys,
   .readyToReset entryA installedKeys,
   .reset entryA .installed,
   .connect entryA .installed installedKeys]

/-- The ceremony to the rescue session, then a second reset into rescue and a connection
presenting the set the last boot published. -/
def reuseEvents : List Event :=
  [.rescueLast entryA (some oldRescueKeys),
   .reset entryA .rescue,
   .rescueLast entryA (some rescueKeys),
   .connect entryA .rescue rescueKeys,
   .reset entryA .rescue,
   .connect entryA .rescue rescueKeys]

/-- The reset dispatched, the field empty, then the field showing the set journaled before the
reset — and a connection made to the rescue system anyway. -/
def beforeFillEvents : List Event :=
  [.rescueLast entryA (some oldRescueKeys),
   .reset entryA .rescue,
   .rescueLast entryA none,
   .rescueLast entryA (some oldRescueKeys),
   .connect entryA .rescue oldRescueKeys]

/-- A host-key set for the installed system named in model text, and a connection presenting
it. -/
def modelTextEvents : List Event :=
  [.claim entryA .machine claimedKeys,
   .connect entryA .installed claimedKeys]

/-- The ceremony to the reset into the installed system, and then the probe that reads the old
pin: the rescue pin is what it checks against, and sshd answers with the installed keys. -/
def resumeProbeEvents : List Event :=
  [.rescueLast entryA (some oldRescueKeys),
   .reset entryA .rescue,
   .rescueLast entryA (some rescueKeys),
   .readyToReset entryA installedKeys,
   .reset entryA .installed,
   .connect entryA .rescue installedKeys]

/-- Entry A pinned, and a connection to machine B presenting A's set. -/
def otherMachineEvents : List Event :=
  [.rescueLast entryA (some oldRescueKeys),
   .reset entryA .rescue,
   .rescueLast entryA (some rescueKeys),
   .connect entryB .rescue rescueKeys]

/-- Entry A pinned, and a handshake presenting a set that is no pin of its. -/
def mismatchEvents : List Event :=
  [.rescueLast entryA (some oldRescueKeys),
   .reset entryA .rescue,
   .rescueLast entryA (some rescueKeys),
   .connect entryA .rescue claimedKeys]

/-- `ARC-43`'s rule removed: any source may pin anything. -/
def anySource : Params := { current with sourceAdmitsPin := false }

/-- **The ceremony, whole.** The admission is not safe by refusing everything: the rescue boot's
published set is pinned and admits the rescue session, the job record's read pins the installed
system, and the installed pin admits the session that confirms the second reset. The unchanged
field pinned nothing, and no handshake halted. -/
@[req "CHN-R1"] theorem pin_ceremony_trace :
    let k := run current init ceremonyEvents
    k.pins.map (·.source) = [.readyToReset, .rescueLast] ∧
    k.sessions.map (·.keys) = [installedKeys, rescueKeys] ∧
    k.confirmed = [(entryA, .installed), (entryA, .rescue)] ∧ k.halts = [] := by
  decide +kernel

/-- **A rescue pin reused across boots, refused.** The second reset into rescue begins the next
boot, so the set the last boot published is a pin the harness still holds and no longer the one
for this machine now: the connection presenting it is halted with nothing to check against, and
the session of the boot before it stands. -/
@[req "CHN-R1"] theorem rescue_pin_not_reused_across_boots :
    let k := run current init reuseEvents
    k.pins.map (·.per) = [.boot 1] ∧ k.sessions.map (·.boot) = [1] ∧
    k.halts.map (·.reason) = [.noPin] := by decide +kernel

/-- **A connection before `/rescue/last` fills, refused.** The field is empty, and then it shows
the set journaled before the reset — "the previous boot's keys are still there until the new boot
publishes" — so nothing is pinned for the boot the harness is now counting, and the connection
presenting that set is halted rather than trusted at first contact. -/
@[req "CHN-R1"] theorem connection_before_fill_refused :
    let k := run current init beforeFillEvents
    k.pins = [] ∧ k.sessions = [] ∧ k.confirmed = [] ∧ k.halts.map (·.reason) = [.noPin] := by
  decide +kernel

/-- **An installed pin from model text, refused.** The source rule refuses model text, so the
set the model named is not journaled, and the connection presenting it has nothing to check
against. -/
@[req "ARC-43"] theorem installed_pin_from_model_text_refused :
    let k := run current init modelTextEvents
    k.pins = [] ∧ k.sessions = [] ∧ k.halts.map (·.reason) = [.noPin] := by decide +kernel

/-- Without the rule the source decides nothing: the set the model named is pinned as the
installed system's and admits the session, which is a host key pinned from model text and a
machine identified by whatever said it was. -/
@[req "ARC-43"] theorem installed_pin_from_model_text_admitted :
    let k := run anySource init modelTextEvents
    k.pins.map (·.source) = [.modelText] ∧ k.sessions.map (·.keys) = [claimedKeys] := by
  decide +kernel

/-- **The pin halt is the reset's confirmation.** The probe on resume reads the rescue pin while
the machine has come back as the installed system: the presented set does not match it, so
`SEC-11` halts the session — and the set is the pin the reset intent named, so the halt is
`STA-20b`'s confirmation rather than the error, and the reset is confirmed by it. -/
@[req "STA-20b"] theorem pin_halt_is_confirmation :
    let k := run current init resumeProbeEvents
    k.halts.map (·.reason) = [.confirmsReset] ∧ k.sessions = [] ∧
    k.confirmed = [(entryA, .installed), (entryA, .rescue)] ∧ k.awaiting = [] := by
  decide +kernel

/-- A pin is for one machine: the set another machine's rescue boot published is not a pin for
this one, and the connection is halted with nothing to check against. -/
@[req "SEC-11"] theorem other_machine_pin_refused :
    let k := run current init otherMachineEvents
    k.sessions = [] ∧ k.halts.map (·.entry) = [entryB] ∧
    k.halts.map (·.reason) = [.noPin] := by decide +kernel

/-- `SEC-11`'s own rule: a presented set that is not the pin's halts the session, and no reset
explains it, so it is the error and not a confirmation. -/
@[req "SEC-11"] theorem mismatched_key_halts :
    let k := run current init mismatchEvents
    k.sessions = [] ∧ k.halts.map (·.reason) = [.mismatch] ∧ k.confirmed = [(entryA, .rescue)]
    := by decide +kernel

/-! Attest witnesses use an observed author, compared with the independent planted association.
The same bad traces are admitted only with their own guard removed. -/

def attestEvents : List Event :=
  [.attest entryA .machine installedKeys (plantedSender entryA) true,
   .connect entryA .installed installedKeys,
   .connect entryA .installed claimedKeys,
   .connect entryB .installed installedKeys]

def wrongAuthorEvents : List Event :=
  [.attest entryA .machine claimedKeys (plantedSender entryB) true,
   .connect entryA .installed claimedKeys]

def wrongThenValidEvents : List Event := wrongAuthorEvents ++ attestEvents

def attestRescueEvents : List Event :=
  [.attest entryA (.boot 0) rescueKeys (plantedSender entryA) true,
   .connect entryA .rescue rescueKeys]

def repeatAttestEvents : List Event :=
  [.attest entryA .machine installedKeys (plantedSender entryA) true,
   .restart,
   .attest entryA .machine claimedKeys (plantedSender entryA) true,
   .connect entryA .installed claimedKeys,
   .connect entryA .installed installedKeys]

def independentAttestEvents : List Event :=
  [.attest entryA .machine installedKeys (plantedSender entryA) true,
   .attest entryB .machine rescueKeys (plantedSender entryB) true,
   .connect entryA .installed installedKeys,
   .connect entryB .installed rescueKeys]

def failedAttestEvents : List Event :=
  [.attest entryA .machine installedKeys (plantedSender entryA) false,
   .connect entryA .installed installedKeys]

def failedThenValidEvents : List Event := failedAttestEvents ++ [.restart] ++ attestEvents

def anyAuthor : Params := { current with attestAuthorMatches := false }
def repeatAttest : Params := { current with attestSingleUse := false }
def volatileAttest : Params := { current with attestDurable := false }

@[req "CHN-R5"] theorem attest_admits_and_connects :
    let k := run current init attestEvents
    k.pins.map (·.source) = [.attest (plantedSender entryA)] ∧
    k.consumed = [entryA] ∧ k.sessions.map (·.keys) = [installedKeys] ∧
    k.halts.map (·.reason) = [.noPin, .mismatch] := by decide +kernel

@[req "CHN-R5"] theorem wrong_author_refused :
    let k := run current init wrongAuthorEvents
    k.pins = [] ∧ k.consumed = [] ∧ k.sessions = [] ∧
    k.halts.map (·.reason) = [.noPin] := by decide +kernel

@[req "CHN-R5"] theorem wrong_author_admitted :
    let k := run anyAuthor init wrongAuthorEvents
    k.consumed = [entryA] ∧ k.sessions.map (·.keys) = [claimedKeys] := by decide +kernel

@[req "CHN-R5"] theorem wrong_author_then_valid :
    let k := run current init wrongThenValidEvents
    k.pins.map (·.keys) = [installedKeys] ∧ k.consumed = [entryA] ∧
    k.sessions.map (·.keys) = [installedKeys] := by decide +kernel

/-- Source-specific refusal, independent of the production parameter value. -/
@[req "CHN-R5"] theorem attest_rescue_refused :
    let k := run { current with sourceAdmitsPin := true } init attestRescueEvents
    k.pins = [] ∧ k.consumed = [] ∧ k.sessions = [] ∧
    k.halts.map (·.reason) = [.noPin] := by decide +kernel

@[req "CHN-5"] theorem repeat_attest_refused :
    let k := run current init repeatAttestEvents
    k.pins.map (·.keys) = [installedKeys] ∧ k.consumed = [entryA] ∧
    k.sessions.map (·.keys) = [installedKeys] ∧
    k.halts.map (·.reason) = [.mismatch] := by decide +kernel

@[req "CHN-5"] theorem repeat_attest_admitted :
    let k := run repeatAttest init repeatAttestEvents
    k.pins.map (·.keys) = [claimedKeys, installedKeys] ∧
    k.sessions.map (·.keys) = [claimedKeys] := by decide +kernel

@[req "CHN-5"] theorem attest_per_machine :
    let k := run current init independentAttestEvents
    k.consumed = [entryB, entryA] ∧
    k.sessions.map (·.entry) = [entryB, entryA] := by decide +kernel

@[req "CHN-5"] theorem failed_attest_refused :
    let k := run current init failedAttestEvents
    k.pins = [] ∧ k.consumed = [] ∧ k.sessions = [] := by decide +kernel

@[req "CHN-5"] theorem failed_attest_admitted :
    let k := run volatileAttest init failedAttestEvents
    k.consumed = [entryA] ∧ k.sessions.map (·.keys) = [installedKeys] := by decide +kernel

@[req "CHN-5"] theorem failed_append_then_valid :
    let k := run current init failedThenValidEvents
    k.pins.map (·.keys) = [installedKeys] ∧ k.consumed = [entryA] ∧
    k.sessions.map (·.keys) = [installedKeys] := by decide +kernel

/-! ## The bound -/

/-- The bound (`CONTEXT.md`): every trace of at most this many events over `alphabet`, from
`start`. Stated once, here, for `bounded` and for the witness file; beyond it is the
theorems' statements, not the file's. -/
@[req "SEC-11"] def bound : Nat := 3

/-- Where every trace of the enumeration runs from: the field read once, which is the snapshot
the confirmation is read against — "the one snapshotted before the reset" (`CHN-R1`), which a
trace of three events has no room to take for itself and without which no rescue boot in the
enumeration could ever be confirmed. Nothing else is known. -/
def start : Knowledge := step current init (.rescueLast entryA (some oldRescueKeys))

/-- The events the bounded enumeration draws from: the reset into rescue and the reset into the
installed system, the vendor's field showing the set the snapshot holds and showing a new one,
the job record's read, a set named in model text, a connection to each system answered by that
system's own set, and the probe on resume — a connection to the rescue system answered by the
installed set, which is the halt the reset explains where it is outstanding and the error where
it is not. Attest adds a valid and a wrong-author introduction, plus restart. The longer
named witnesses cover failed appends, rescue refusal, repetition and per-machine independence. -/
def alphabet : List Event :=
  [.reset entryA .rescue, .reset entryA .installed,
   .rescueLast entryA (some oldRescueKeys), .rescueLast entryA (some rescueKeys),
   .readyToReset entryA installedKeys,
   .claim entryA .machine claimedKeys, .connect entryA .rescue rescueKeys,
   .connect entryA .installed installedKeys, .connect entryA .rescue installedKeys,
   .attest entryA .machine installedKeys (plantedSender entryA) true,
   .attest entryA .machine claimedKeys (plantedSender entryB) true, .restart]

/-- Every trace of exactly `n` events over `alphabet`. -/
def tracesOf : Nat → List (List Event)
  | 0 => [[]]
  | n + 1 => (tracesOf n).flatMap fun es => alphabet.map (es ++ [·])

/-- Every trace of at most `n` events over `alphabet`, shortest first. -/
def tracesUpTo (n : Nat) : List (List Event) := (List.range (n + 1)).flatMap tracesOf

/-- The lifecycle in the requirements' own terms, and stated without `admits`, `pinFor` or
`check`, so that it decides what they read rather than agreeing with them: no pin the harness
holds came from model text; attest pins name the planted sender, are per machine and have a
consumed introduction, and no introduction is consumed twice; every session was admitted
against a pin it holds for that machine,
for the system it connected to and, in rescue, for the boot it was made in; and every halt
recorded as the reset's confirmation is a reset confirmed. -/
@[req "SEC-11"] def wellPinned (k : Knowledge) : Bool :=
  k.pins.all (fun pin => pin.source != Source.modelText &&
    match pin.source with
    | .attest author => pin.per == Per.machine && author == plantedSender pin.entry &&
        k.consumed.contains pin.entry
    | _ => true) &&
  k.consumed.eraseDups == k.consumed &&
  k.sessions.all (fun s =>
    k.pins.contains s.pin && s.pin.entry == s.entry && s.pin.keys == s.keys &&
    s.pin.per == (if s.system == System.rescue then Per.boot s.boot else Per.machine)) &&
  k.halts.all (fun h =>
    h.reason != Halt.confirmsReset || k.confirmed.contains (h.entry, System.installed))

/-- The lifecycle, decided within the bound: the enumeration the witness file carries is one the
companion itself closed over. -/
@[req "SEC-11"] theorem bounded :
    (tracesUpTo bound).all (fun es => wellPinned (run current start es)) = true := by
  decide +kernel

end TauWeb.Pins
