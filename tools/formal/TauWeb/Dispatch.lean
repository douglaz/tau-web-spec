import TauWeb.Req
/-! Module 4, dispatch and the unresolved barrier (ADR-0032's inventory): `STA-3`, `STA-4`,
`STA-7`, `STA-8`, `STA-24`, `SEC-12`, `STA-20b` and `STG-4`'s confirmation predicates. What this
module encodes was decided by a two-reader panel on 2026-09-16
(`docs/review/2026-09-16-barrier-panel.md`), and `STA-24` is what came out of it.

**Two kinds of state, two types.** `Journal` is harness knowledge — what was durably authorized,
attempted and observed — and `External` is external state, what a vendor or machine may actually
have done. Every dispatch function below takes the journal alone — external state reaches the
trace only as what a read reported — so no dispatch decision reads it and no theorem's statement
speaks for it (`CONTEXT.md`, *Formal companion*). A response is
not modelled at all, which is the assumption a lost response leaves the effect done or not done:
the harness learns an outcome from a read and from nothing else, since `STG-4` confirms every
Robot mutation "by observable state, never by its own response and never by a clock".

**The barrier is derived.** `unresolved` is an intent with no terminal record, computed from the
journal, never an event of its own — "an event recording 'became unresolved' is exactly what a
crash could fail to write" (`STA-24`) — which is why it survives replay and session succession.
A disposition is a terminal record of its own kind whose outcome stays unknown, so a disposed
call is not an open one and the barrier stays one derivation.

**A disposition is read through one test.** What a disposition may name is `acceptable`, decided
against the journal before it. `step` refuses a disposition that fails it and records nothing,
and `inEffect` reads a journal that already holds one "as if it had never been recorded"
(`STA-24`), so recording and replay cannot disagree. What a standing disposition restricts is
`restricted`: the reach, computed from the calls it disposed through `bars`, and beside it the
stop a destructive continuation puts on `exec`. It stands until its continuation is dispatched
(`standingIn`) or a later one replaces it.

**In memory and in the journal.** `World` carries both, because `STA-3` — "A canonical event
MUST be durably appended **before** it is applied to in-memory state. If the append fails, the
transition does not occur" — is exactly the statement that they never diverge. Dispatch reads
the running worker's memory (`STA-2`: in-memory state "is authoritative only while a worker is
running"), and `replay` throws it away and rebuilds it from the journal.

`Params` lists the parameters this module's decisions turn on; each is one field, so removing
one is a one-token change, and each has its refused-and-admitted pair.

Amended 2026-10-17: a destructive reinstall's journaled approval names its reset call,
entry and approved facts. It supplies no generation. The approval-bound reset is refused
unless a rescue activation dispatched since the approval is still confirmed by its newest
durable read. Only a matching withdrawal since that approval withdraws it; dispositions do
not. Dispatch remains subject to the barrier and standing disposition. Other resets retain
their checks and the single reset kind is unchanged. The companion cannot carry immediately
preceding reads or refusal after a failed read append.
For `ready_to_reset`, the durable per-command record
(`ARC-8`, `STA-4`) precedes collection; `resetCollection` carries that record here. A missing
durable prerequisite result after it withholds the offer across replay, per entry and current
installation. No failed result is applied as knowledge, and a later durable read restores the
offer only when its keys match the first durable read and no earlier installation's prerequisite
set is identical. Transmission and collection of this command are abstracted into `resetPrereqs`;
its prior command-record append is taken as given.

What the module omits: the snapshot and the compaction of `STA-2`, since a snapshot is the
journal's replay and adds no case here; the lock `STA-7` acquires and the single writer `STA-1`
is, taken as given rather than modelled, so that nothing here is a claim about concurrency
(ADR-0032, "Evidence"); the half of `STA-7`'s classification that cancels — an intent is built
here only where an approval was checked, so "an intent with no journaled approval decision was
never dispatched" (`STA-4`) has no counterpart, and what is carried is that replay reads back the
barrier it had; the untyped call, whose resource is the scope (`SEC-12`, `STA-24`) and whose rules
are its own — nothing under a scope counts as a read, and only the operator's disposition clears
it — since no witness of this module's inventory row exercises one, and with it the pause and
the hold `STA-24` states for an untyped vendor scope; the spend cap an unresolved
inference intent is shown against (`ARC-31a`), a number and not a gate; the screens `ARC-22`
requires, which state what the journal already holds. Robot's predicates have no negative
transition (`STG-4`: "None of these has a negative form"), so there is no observation meaning
*it did not happen*: that reading arrives only as a disposition.

ponytail: `openIntents` rescans the journal for every intent it reads, which is quadratic in the
trace, and `inEffect` reads the journal again for every disposition; the bound is three events,
and an index from call id to terminal record arrives when a longer enumeration needs one. -/

namespace TauWeb.Dispatch

/-! ## What a call names -/

/-- The approved machine entry of the setup (`ARC-15`'s batch), opaque: which machines the
operator approved is the batch's business, and the barrier reads only which entry a call is
against. -/
abbrev Entry := Nat

/-- A call id, fresh per request. `STA-24`'s trap is that "a model does not retry a call: it
requests the action again, and every request carries a fresh call id". -/
abbrev CallId := Nat

abbrev SessionId := Nat

/-- The structured facts a cloud-plane operation is approved on (`SEC-4`), opaque. An
implementation maps each to one concrete record of arguments, cost bound and bundle commit; what
is at stake here is only whether the dispatched facts are the approved ones. -/
abbrev Facts := Nat

/-- What a model may name. `STA-24`: the resource is "what the intent record named, assigned or
checked by the harness and never taken from the model", so a request carries one of these and
the harness resolves it — the approved entry itself, a reserved allocation index (`STA-22b`),
the immutable vendor machine id once learned, or the inference account's cap (`ARC-31a`). -/
inductive Target
  | entry (e : Entry)
  | index (n : Nat)
  | vendor (v : Nat)
  | inferenceCap
  deriving DecidableEq, Repr

/-- The resource the barrier holds per (`STA-24`). For a machine it is the approved entry, "to
which the reserved allocation index (`STA-22b`) and, once learned, the immutable vendor machine
id are associated — so a create and the machine it produced are one resource". The inference
request's is its own, and it is the one nothing bars. The untyped call's, which `STA-24` makes
"the **scope** itself, since no adapter can say what the call touched (`SEC-4`)", is not carried:
its rules are its own and the module's docstring says so. -/
inductive Resource
  | machine (e : Entry)
  | inference
  deriving DecidableEq, Repr

/-- What a call does. The first six are cloud-plane typed operations (`STG-4`, `ARC-22`).
`reinstall` is the vendor's own reinstall call, where the vendor has one (`ARC-22`: "stop,
renewal control and reinstall are available"). `destroy` is the abandonment flow's operation
naming the machine: "the destroy, or the stop that stands in for it" (`STA-24`), since where the
vendor offers no destroy route the harness "stops that machine, turns automatic renewal off"
(`ARC-22`). `exec` is box-plane work (`ARC-8`) as a whole; `read` is what `STA-24` keeps
permitted — "the adapter's status queries, the pinned SSH attempt that is `STG-4`'s third
predicate, the collection of job records"; `inference` is `ARC-31a`'s own off-machine call. -/
inductive Kind
  | create
  | reset
  | reinstall
  | destroy
  | activate
  | registerKey
  | exec
  | read
  | inference
  deriving DecidableEq, Repr

/-- The two planes of ADR-0002. No wildcard: a kind added without a plane does not build. -/
def cloudPlane : Kind → Bool
  | .create | .reset | .reinstall | .destroy | .activate | .registerKey => true
  | .exec | .read | .inference => false

/-- `STA-24`'s one exception for the box plane: "a cloud-plane operation that **changes what the
machine is running** — a reset, a reinstall, a destroy, or the stop that stands in for a destroy
(`ARC-22`) — stops box-plane dispatch to that machine from its intent until its confirmation".
The stop is carried by `destroy`. These are also the operations a destructive continuation is
dispatched at (`dispatchesContinuation`). -/
@[req "STA-24"] def changesRunning : Kind → Bool
  | .reset | .reinstall | .destroy => true
  | .create | .activate | .registerKey | .exec | .read | .inference => false

/-- A read is not side-effecting: it is permitted whatever the barrier says, and it never becomes
an unresolved call of its own. Everything else is side-effecting and carries `SEC-12`'s record. -/
@[req "SEC-12"] def sideEffecting : Kind → Bool
  | .read => false
  | .create | .reset | .reinstall | .destroy | .activate | .registerKey | .exec | .inference => true

/-! ## The two kinds of state -/

/-- What a record establishes about the call it settles. The lattice is `unknown` below `ended`
below `succeeded`: a changed boot ID "proves the old command cannot still be running; it does
**not** prove its effects or exit status" (`STA-20b`), and a disposition "keeps the outcome
*unknown*" (`STA-24`). -/
inductive Standing
  | unknown
  | ended
  | succeeded
  deriving DecidableEq, Repr

/-- **External state** (`CONTEXT.md`): what a vendor or machine may actually have done. It enters
as an assumption and never as data this module owns (ADR-0032, "What is not Lean's to carry
enters as a hypothesis, never an axiom"): `reports` is what a read of the far side returns for an
operation on a resource — `STG-4`'s predicates, read from the vendor's API or from a pin-checked
handshake. Nothing here is harness knowledge, and nothing below reads it: the dispatch functions
take the journal alone, so a theorem about the first never speaks for the second. -/
structure External where
  reports : Resource → Kind → Standing

/-- Where an observation came from. `STA-24` reads evidence at its provenance: from the vendor
or from a pin-checked handshake; "A job record can settle the box-plane command it records, as
`STA-20` says and with the standing `STA-21` gives it; it cannot clear a cloud-plane barrier, and
neither can model text (`SEC-8`)". A notify event is the machine's word too — `CHN-17`: "a
machine may send the harness an event, and an event is an observation", typed untrusted. -/
inductive Provenance
  | adapterRead
  | pinCheckedHandshake
  | jobRecord
  | notifyEvent
  | modelText
  deriving DecidableEq, Repr

/-- An observation as the journal records it: where it came from, the resource and the operation
it is a predicate for, and what it established. Robot's mutations "return nothing that identifies
the request" (`STA-5`), so an observation names the resource and never a call id; it settles the
outstanding calls on that resource whose operation its predicate is for. -/
structure Observation where
  provenance : Provenance
  resource : Resource
  kind : Kind
  standing : Standing
  deriving DecidableEq, Repr

/-- The approval decision journaled with the intent (`STA-4`). `SEC-4` makes it two properties
rather than one: a typed operation naming an existing machine is "authorized against the calling
session's binding", and "What is dispatched is the approved record" — the facts as they were
approved and journaled, "never a request rebuilt at dispatch". -/
structure Approval where
  session : SessionId
  facts : Facts
  deriving DecidableEq, Repr

/-- `STA-4`'s record: "A side-effecting call MUST have a durable record, an approval decision,
and an idempotency identity **before execution begins**", appended "immediately before the bytes
leave". The resource is the harness's and the target is what the model named, both kept, since
the barrier reads the first and the panel's rejected key reads the second. -/
structure Intent where
  call : CallId
  target : Target
  resource : Resource
  kind : Kind
  session : SessionId
  approval : Approval
  deriving DecidableEq, Repr

/-- The continuation a disposition names, the operator's four choices (`STA-24`): "a destructive
reinstall (`STG-20`), abandonment (`ARC-21`), continuing as if done, continuing as if not done".
A choice and never an operation: what a destructive one is dispatched at is
`dispatchesContinuation`. The two that continue differ only in the assumption the operator
recorded, which no function here reads. -/
@[req "STA-24"] inductive Continuation
  | reinstall
  | abandon
  | asIfDone
  | asIfNotDone
  deriving DecidableEq, Repr

/-- The two destructive choices. No wildcard: a choice added without this does not build. -/
@[req "STA-24"] def destructive : Continuation → Bool
  | .reinstall | .abandon => true
  | .asIfDone | .asIfNotDone => false

/-- The operator's disposition (`STA-24`): "a record of its own kind naming the unresolved calls
it ends, the continuation the operator chose — a destructive reinstall (`STG-20`), abandonment
(`ARC-21`), continuing as if done, continuing as if not done — and the uncertainty accepted". -/
structure Disposition where
  resource : Resource
  calls : List CallId
  continuation : Continuation
  deriving DecidableEq, Repr

/-- One journal record. `STA-2`: canonical state is "an **append-only event journal** with
replayable transitions". An association is the harness's own mapping of what a model may name to
the approved entry; the reset prerequisites are `ready_to_reset`'s (`ARC-43`) installed pins and
reset intent, which `STA-20b` requires durable before a planned reset into the installed
system. -/
inductive Rec
  | intent (i : Intent)
  | observation (o : Observation)
  | disposition (d : Disposition)
  | association (t : Target) (e : Entry)
  | resetPrereqs (e : Entry) (installation : Nat) (keys : Nat)
  | reinstallApproval (e : Entry) (call : CallId) (approval : Approval)
  | resetCollection (e : Entry) (installation : Nat)
  | reinstallWithdrawal (e : Entry) (call : CallId) (approval : Approval)
  deriving DecidableEq, Repr

/-- **Harness knowledge**: the journal, newest first. Nothing else is knowledge here — what a
vendor did is `External`'s. -/
abbrev Journal := List Rec

/-! ## The parameters -/

/-- What the barrier is keyed on. `entry` is the rule: `STA-24` says "The unresolved barrier
holds per resource, not per call", and for a machine the resource is the approved entry. `index`
is the reading the panel rejected — "A fresh allocation index would have been the same hole one
level up, which is why the resource is the approved entry and not the index". `call` is `STA-8`
alone, and the trap it leaves: "nothing keyed on the first call id refuses the second". -/
inductive Key
  | entry
  | index
  | call
  deriving DecidableEq, Repr

/-- Where a standing disposition's reach is taken from. `disposed` is the rule: `STA-24` says "A
standing disposition restricts, to its continuation, what the calls it names barred while they
were unresolved". The others are the readings it retains as traps. `resource` restricts every
side-effecting operation naming the resource, so a disposed activation begins to bar the box
plane. `everyDispatch` restricts every request, a read included, which is what this module did
until 2026-10-13. `stillUnresolved` reads the calls still unresolved, and a disposed call is not
one, so nothing is in reach. -/
inductive Reach
  | disposed
  | resource
  | everyDispatch
  | stillUnresolved
  deriving DecidableEq, Repr

/-- Where a standing disposition's restriction ends. `continuation` is the rule: `STA-24` says
"The restriction ends when the continuation it names is dispatched". `anyIntent` ends it at any
later intent naming the resource, a read's included, which is what this module did until
2026-10-13: a status read lifted an abandonment. `firstOperation` ends it at the first operation
of the continuation's flow, so a command is admitted between a rescue activation and the reset. -/
inductive Lapse
  | continuation
  | anyIntent
  | firstOperation
  deriving DecidableEq, Repr

/-- The parameters this module's decisions turn on, each one field so that changing one is a
one-token change, and each with its refused-and-admitted pair (ADR-0032, "Every guard a dated
amendment added is a parameter"). The tag is the requirement the module is for; each field's own
clause has its own owner, named in that field's docstring and carried by its pair's tags, since
authority is per clause and this structure is not one. -/
@[req "STA-24"] structure Params where
  /-- The resource key, written 2026-09-16 as `STA-24`. Its pairs are
  `same_action_new_call_id_refused` / `_admitted` and `second_index_same_entry_refused` /
  `_admitted`. -/
  resourceKey : Key
  /-- `STA-3`: "A canonical event MUST be durably appended **before** it is applied to in-memory
  state. If the append fails, the transition does not occur." It is the reset offer's
  precondition — `STA-20b`'s durable pins and intent, "checked against those durable
  prerequisites at the moment it is made" — and the rule that leaves the barrier standing when a
  resolution's own append fails. Its pairs are `reset_offered_after_failed_append_refused` /
  `_admitted` and `resolution_append_failed_refused` / `_admitted`. -/
  durableBeforeApply : Bool
  /-- The observation lattice, `ended` below `succeeded`. Its pair is
  `boot_id_change_not_success_refused` / `_admitted`. -/
  endedBelowSucceeded : Bool
  /-- `STA-24`: "A standing disposition restricts, to its continuation, what the calls it names
  barred while they were unresolved". Without the rule a disposition ends the calls it names and
  restricts nothing, whatever the operator chose. Its pair is
  `disposition_one_continuation_refused` / `disposition_unrestricted_admitted`. -/
  dispositionBindsContinuation : Bool
  /-- Where the restriction's reach is taken from (`STA-24`, 2026-10-13). Its pairs are
  `continuing_permits_what_was_barred` / `disposed_activation_bars_commands_without_guard` for
  `resource`, `read_and_inference_never_restricted` / `read_and_inference_restricted_without_guard`
  for `everyDispatch`, and `replacement_in_force` / `replaced_continuation_dispatched_without_guard`
  for `stillUnresolved`. -/
  reach : Reach := .disposed
  /-- `STA-24`: when the continuation is destructive "the harness worker MUST refuse the model's
  box-plane commands to that machine, whatever the disposed call was". Its pair is
  `destructive_choice_stops_commands` / `command_preempts_reinstall_without_guard`. -/
  destructiveStops : Bool := true
  /-- Where the restriction ends (`STA-24`, 2026-10-13). Its pairs are
  `read_does_not_lift_abandonment` / `read_lifts_abandonment_without_guard` for `anyIntent` and
  `preparation_keeps_restriction` / `preparation_lifts_restriction_without_guard` for
  `firstOperation`. -/
  lapse : Lapse := .continuation
  /-- `STA-24`: the reset a destructive reinstall is dispatched at is "a reset dispatched after
  that rescue activation is confirmed", and "Any other reset is refused while the disposition
  stands". Without it any reset is the reinstall. Its pair is `reset_without_rescue_refused` /
  `reset_without_rescue_admitted`. -/
  resetIntoRescueOnly : Bool := true
  /-- `STA-24`: "while the newest read of that activation still confirms it". The companion
  reads which admissible activation observation is newest in the journal before the reset's
  intent; it does not carry the duty to read again, which is `STG-4`'s. Its pair is
  `spent_activation_not_counted` / `spent_activation_counted_without_guard`. -/
  newestActivationRead : Bool := true
  /-- `STA-24`: "every call it names MUST be unresolved, on the disposition's own resource, in
  the journal as it stands before the disposition". Without the resource a disposition is matched
  to a call by call id alone, and one recorded against a machine ends a call on another. Its
  pair is `disposition_names_own_unresolved_calls` /
  `disposition_ends_call_elsewhere_without_guard`. -/
  dispositionOwnResource : Bool := true
  /-- A session cannot send the abandonment flow's destroy. Its pair is
  `session_destroy_under_abandonment_refused` / `session_destroy_lifts_abandonment_without_guard`. -/
  sessionDestroyRefused : Bool := true
  /-- The reset offer reads the current installation and compares the newest prerequisite keys
  with its first durable prerequisite keys. Its pairs cover a predecessor record and a changed key. -/
  resetOfferCurrentInstallation : Bool := true
  /-- `STG-20`, 2026-10-17: the approved dedicated reinstall opens at its own rescue reset,
  even without a disposition. Pair: `approved_reinstall_boundary_refused` /
  `approved_reinstall_boundary_admitted_without_guard`. -/
  approvedReinstallBoundary : Bool := true
  /-- `STA-20b`, 2026-10-17: a collection's durable command record with no durable result
  withholds the reset offer, including on replay. Pair: `failed_prerequisite_withdrawal_refused`
  / `failed_prerequisite_withdrawal_admitted_without_guard`. -/
  failedPrerequisiteWithdraws : Bool := true
  /-- `STG-20`, 2026-10-17: an approval-bound reset requires a confirmed rescue activation
  dispatched since the approval. Pair: `approval_reset_requires_rescue_refused` /
  `approval_reset_requires_rescue_admitted_without_guard`. Other resets are unchanged. -/
  approvalResetRequiresRescue : Bool := true
  /-- `STA-20b`, 2026-10-17: the first current prerequisite keys must differ from every
  earlier installation's prerequisite keys. Opaque ordinals carry identical sets only.
  Pair: `kept_keys_reset_offer_refused` / `kept_keys_reset_offer_admitted_without_guard`. -/
  resetOfferFreshKeys : Bool := true
  /-- `STG-20`, 2026-10-17: a matching withdrawal since the newest approval withdraws it.
  Without this guard the record withdraws nothing. Pair: `withdrawn_approval_reset_refused` /
  `withdrawn_approval_reset_admitted_without_guard`. -/
  reinstallWithdrawalEffective : Bool := true
  deriving DecidableEq, Repr

/-- The rules as they stand. -/
@[req "STA-24"] def current : Params :=
  { resourceKey := .entry, durableBeforeApply := true, endedBelowSucceeded := true,
    dispositionBindsContinuation := true }

/-! ## What the journal says -/

/-- The entry a journaled association gives for a target, newest first. -/
def associated (j : Journal) (t : Target) : Option Entry :=
  j.findSome? fun rec => match rec with
    | .association t' e => if t' == t then some e else none
    | _ => none

/-- The resource a target names. `STA-24`: for a machine it is "the **approved machine entry** of
the setup (`ARC-15`'s batch), to which the reserved allocation index (`STA-22b`) and, once
learned, the immutable vendor machine id are associated". A target the harness has associated
with nothing resolves to nothing and is dispatched against nothing — `ARC-22`'s unresolved create
that "cannot be destroyed from here and may still exist and bill", since "an allocation index is
not a deletion target". No wildcard: a target the corpus adds without a resolution does not
build. -/
@[req "STA-24"] def resolve (j : Journal) : Target → Option Resource
  | .entry e => some (.machine e)
  | .index n => (associated j (.index n)).map Resource.machine
  | .vendor v => (associated j (.vendor v)).map Resource.machine
  | .inferenceCap => some .inference

/-- Whether an observation of the given standing confirms the call it settles. Under the lattice
only the top does. Flattened, every standing confirms — which is a `boot_id` change read as
success, the trap the lattice retains. A disposition settles by naming the call and not by this,
since it "keeps the outcome *unknown*" (`STA-24`). -/
@[req "STA-20b"] def confirms (p : Params) (s : Standing) : Bool :=
  if p.endedBelowSucceeded then s == .succeeded else true

/-- `STA-24`, "What clears it": an observation is evidence only from the vendor or a pin-checked
handshake; a job record settles the box-plane command it records and "cannot clear a cloud-plane
barrier, and neither can model text". A notify event is the machine's word under `CHN-17` and
clears nothing either. -/
@[req "STA-24"] def admissible (o : Observation) : Bool :=
  match o.provenance with
  | .adapterRead | .pinCheckedHandshake => true
  | .jobRecord => !cloudPlane o.kind
  | .notifyEvent | .modelText => false

/-- Whether a record is a terminal record for an intent. An admissible observation for that
resource and operation whose standing confirms it, or a disposition on the intent's resource
naming the call — `STA-24`: "**A disposition is a terminal record of its own kind**: it ends the
call's unresolved state with the outcome recorded as unknown, so the barrier stays one derivation
— an intent with no terminal record — and a disposed call is not an open one." This reads one
record; whether a disposition counts at all is not decided from the record alone, and every
reader below takes a journal `inEffect` has already read. -/
@[req "STA-8"] def settles (p : Params) (i : Intent) : Rec → Bool
  | .observation o =>
    admissible o && o.resource == i.resource && o.kind == i.kind && confirms p o.standing
  | .disposition d =>
    (d.resource == i.resource || !p.dispositionOwnResource) && d.calls.contains i.call
  | .intent _ => false
  | .association _ _ => false
  | .resetPrereqs _ _ _ => false
  | .reinstallApproval _ _ _ => false
  | .resetCollection _ _ => false
  | .reinstallWithdrawal _ _ _ => false

/-- The unresolved intents of a journal's tail, given `later`, the records appended after it. An
intent is unresolved while nothing appended **after** it settles it: a read settles the calls that
were outstanding when it was taken, never one dispatched afterwards. Newest first. -/
def openFrom (p : Params) (r : Resource) (later : Journal) : Journal → List Intent
  | [] => []
  | rec :: rest =>
    let tail := openFrom p r (rec :: later) rest
    match rec with
    | .intent i =>
      if i.resource == r && sideEffecting i.kind && !later.any (settles p i) then i :: tail
      else tail
    | _ => tail

/-- The unresolved intents naming a resource, in a journal `inEffect` has read. -/
def openIn (p : Params) (e : Journal) (r : Resource) : List Intent := openFrom p r [] e

/-- Whether a call is unresolved on a resource, in a journal `inEffect` has read. -/
def unresolvedIn (p : Params) (e : Journal) (r : Resource) (c : CallId) : Bool :=
  (openIn p e r).any (·.call == c)

/-- Every intent the journal holds, newest first. -/
def intentsOf (j : Journal) : List Intent :=
  j.filterMap fun rec => match rec with | .intent i => some i | _ => none

/-- The resources the journal names. -/
def resourcesOf (j : Journal) : List Resource := ((intentsOf j).map Intent.resource).eraseDups

/-- Whether a record is a disposition on a resource. -/
def disposes (r : Resource) : Rec → Bool
  | .disposition d => d.resource == r
  | .intent _ => false
  | .observation _ => false
  | .association _ _ => false
  | .resetPrereqs _ _ _ => false
  | .reinstallApproval _ _ _ => false
  | .resetCollection _ _ => false
  | .reinstallWithdrawal _ _ _ => false

/-- Whether the machine's return to rescue is ready for its reset, read in the journal before
that reset. `STA-24`: while a destructive reinstall's disposition stands "the operations of that
machine's return to rescue that touch no running system — the rescue activation, and a key
registration where one is owed — are admitted and do not end the restriction", and the reset the
reinstall is dispatched at is "a reset dispatched after that rescue activation is confirmed".
*That* rescue activation is one admitted while this disposition stands: an activation naming the
machine whose intent is newer than the standing disposition's record, that is confirmed, and that
no reset intent on the machine follows. It counts only while the newest admissible `.activate`
observation on the resource, journaled before the reset's intent at its dispatch check, still
confirms it. This is a read of the activation predicate, not the reset's `/rescue/last` predicate.
A read whose append failed is absent; a later read after the reset's intent cannot change where
`standingIn` ended the restriction. The companion reads which read is newest, and does not carry
the duty to read again, which is `STG-4`'s. An activation confirmed before the disposition, or
dispatched under a disposition since replaced, does not count: the scan stops at the newest
disposition on the resource, which is the standing one, so the reset is refused and a new
activation is admitted. -/
@[req "STA-24"] def rescueConfirmed (p : Params) (e : Journal) (r : Resource) : Bool :=
  go none (e.takeWhile fun rec => !disposes r rec)
where
  go (read : Option Standing) : Journal → Bool
    | [] => false
    | .intent i :: rest =>
      if i.resource == r && i.kind == .reset then false
      else if i.resource == r && i.kind == .activate && !unresolvedIn p e r i.call then
        !p.newestActivationRead || (match read with | some s => confirms p s | none => false)
      else go read rest
    | .observation o :: rest =>
      go (if read.isNone && admissible o && o.resource == r && o.kind == .activate
          then some o.standing else read) rest
    | .disposition _ :: rest => go read rest
    | .association _ _ :: rest => go read rest
    | .resetPrereqs _ _ _ :: rest => go read rest
    | .reinstallApproval _ _ _ :: rest => go read rest
    | .resetCollection _ _ :: rest => go read rest
    | .reinstallWithdrawal _ _ _ :: rest => go read rest

/-- Whether an operation is the one a continuation is dispatched at, read in the journal before
it. `STA-24`: a continuation "is dispatched at the one that changes what the machine is running".
For a destructive reinstall that is the vendor's reinstall call or the reset into rescue
(`rescueConfirmed`); without `resetIntoRescueOnly` any reset is. For abandonment it is "the
destroy, or the stop that stands in for it", both carried by `destroy`. A continuation that
continues has no operation to be dispatched at. No wildcard over the choices.

`Request` is a session request. This function also reads an intent appended by the
abandonment flow outside `admit` and `step`: its destroy ends the restriction, while `permits`
refuses that operation to a session under abandonment. No sender type is carried. -/
@[req "STA-24"] def dispatchesContinuation (p : Params) (e : Journal) (r : Resource) :
    Continuation → Kind → Bool
  | .reinstall, k =>
    k == .reinstall || (k == .reset && (!p.resetIntoRescueOnly || rescueConfirmed p e r))
  | .abandon, k => k == .destroy
  | .asIfDone, _ => false
  | .asIfNotDone, _ => false

/-- The operations of a continuation's flow that are admitted and do not end the restriction:
under a destructive reinstall, "the rescue activation, and a key registration where one is owed"
(`STA-24`). Neither changes what the machine is running. Whether a registration is owed is not
carried: the journal holds nothing that says so, and this answers for the operation alone. -/
@[req "STA-24"] def prepares (c : Continuation) (k : Kind) : Bool :=
  c == .reinstall && (k == .activate || k == .registerKey)

/-- Whether an intent of kind `k` on the resource, appended to the journal `e`, ends the
restriction of a standing disposition whose continuation is `c`. -/
@[req "STA-24"] def lapsesAt (p : Params) (e : Journal) (r : Resource) (c : Continuation)
    (k : Kind) : Bool :=
  match p.lapse with
  | .continuation => dispatchesContinuation p e r c k
  | .firstOperation => dispatchesContinuation p e r c k || prepares c k
  | .anyIntent => true

/-- The disposition standing over a resource, with the journal as it stood before it, in a
journal `inEffect` has read. `STA-24`: "One disposition stands per resource, the latest", and
"The restriction ends when the continuation it names is dispatched" — at that intent and at no
other record: "An operation outside that reach is neither restricted by it nor ends it", and
evidence about the calls the disposition names arriving afterwards "neither reopens the call nor
removes the disposition". Activation reads before a reset's intent determine which reset counts
in `lapsesAt`; observations after that intent do not change its lapse. -/
def standingIn (p : Params) (r : Resource) : Journal → Option (Disposition × Journal)
  | [] => none
  | .disposition d :: rest => if d.resource == r then some (d, rest) else standingIn p r rest
  | .intent i :: rest =>
    match standingIn p r rest with
    | none => none
    | some s =>
      if i.resource == r && lapsesAt p rest r s.1.continuation i.kind then none else some s
  | .observation _ :: rest => standingIn p r rest
  | .association _ _ :: rest => standingIn p r rest
  | .resetPrereqs _ _ _ :: rest => standingIn p r rest
  | .reinstallApproval _ _ _ :: rest => standingIn p r rest
  | .resetCollection _ _ :: rest => standingIn p r rest
  | .reinstallWithdrawal _ _ _ :: rest => standingIn p r rest

/-- What a disposition may name, against the journal before it (`STA-24`): it "names at least one
call, and every call it names MUST be unresolved, on the disposition's own resource, in the
journal as it stands before the disposition", with one exception — "a new disposition may name
the calls the standing one disposed". Each named call is one or the other. The test for `step`
and for `inEffect` alike: "The same test decides at recording and at replay". -/
@[req "STA-24"] def acceptable (p : Params) (e : Journal) (d : Disposition) : Bool :=
  !d.calls.isEmpty && d.calls.all fun c =>
    (if p.dispositionOwnResource then unresolvedIn p e d.resource c
     else (resourcesOf e).any fun r => unresolvedIn p e r c)
    || (standingIn p d.resource e).any fun s => s.1.calls.contains c

/-- The journal as it is read. `STA-24`: a disposition in a replayed journal that the test would
have refused "is read as if it had never been recorded: it ends no call and restricts nothing".
The record stays in the journal; it is dropped from the reading, oldest first, so that each
disposition is tested against the reading of what came before it. -/
@[req "STA-24"] def inEffect (p : Params) : Journal → Journal
  | [] => []
  | .disposition d :: rest =>
    if acceptable p (inEffect p rest) d then .disposition d :: inEffect p rest
    else inEffect p rest
  | .intent i :: rest => .intent i :: inEffect p rest
  | .observation o :: rest => .observation o :: inEffect p rest
  | .association t e :: rest => .association t e :: inEffect p rest
  | .resetPrereqs e n keys :: rest => .resetPrereqs e n keys :: inEffect p rest
  | .reinstallApproval e c ap :: rest => .reinstallApproval e c ap :: inEffect p rest
  | .resetCollection e n :: rest => .resetCollection e n :: inEffect p rest
  | .reinstallWithdrawal e c ap :: rest => .reinstallWithdrawal e c ap :: inEffect p rest

/-- Whether the harness records a disposition the operator offers (`acceptable`, against the
journal as it is read). Where it does not, "it is refused and nothing is recorded" (`STA-24`). -/
@[req "STA-24"] def accepts (p : Params) (j : Journal) (d : Disposition) : Bool :=
  acceptable p (inEffect p j) d

/-- `STA-8`'s unresolved calls naming a resource, as their intents and newest first. Derived —
"The barrier is a fact of the journal — an intent with no terminal record" (`STA-24`) — so it
survives replay and session succession "without an event of its own". A read is not among them:
it has no effect to be unresolved about. -/
@[req "STA-8"] def openIntents (p : Params) (j : Journal) (r : Resource) : List Intent :=
  openIn p (inEffect p j) r

/-- The barrier set: the call ids `STA-24` shows in a refused request's place. -/
@[req "STA-8"] def unresolved (p : Params) (j : Journal) (r : Resource) : List CallId :=
  (openIntents p j r).map (·.call)

/-- Whether an unresolved call of kind `k` bars a new operation of kind `k'` on the same
resource. `STA-24`'s rule is that a side-effecting operation naming the resource is refused
"whatever its call id, through whichever tool, and whichever session or model requests it"; three
carve-outs are stated there and are the whole of this function. Reads "are permitted and are how
the barrier clears". Box-plane dispatch "is governed by `STA-20` and `STA-20b`, not by this rule,
with one exception stated here" — the cloud-plane operation that changes what the machine is
running — so "An unresolved activation or key registration touches no running system and blocks
nothing on the box". That carve-out is what is dispatched and not what is outstanding: an
unresolved box-plane command still bars a cloud-plane operation, which is the general rule above
and is what `STA-20b` asks for when it "waits for all tracked commands to end" before a planned
reset. And the inference request "does **not** bar the next request", nor does an unresolved one
bar anything: "its only effect is bounded spend, and the next request is the session's only way
to continue". -/
@[req "STA-24"] def bars (k k' : Kind) : Bool :=
  if !sideEffecting k' || k' == .inference || k == .inference then false
  else if cloudPlane k' then true
  else changesRunning k

/-- The unresolved calls on the intent's resource whose operation bars it. -/
def barring (p : Params) (j : Journal) (i : Intent) : List Intent :=
  (openIntents p j i.resource).filter fun o => bars o.kind i.kind

/-- The unresolved calls that bar an intent, at the key in force. Under `entry` — the rule —
every unresolved call naming the resource bars, which is what makes a second attempt at the same
approved entry sit behind the same barrier "even if it would reserve another index". Under
`index` only a call naming the same target bars, so a fresh index walks through. Under `call`
only a call with the same id bars, and every request carries a fresh one. -/
@[req "STA-24"] def blocking (p : Params) (j : Journal) (i : Intent) : List CallId :=
  (match p.resourceKey with
   | .entry => barring p j i
   | .index => (barring p j i).filter fun o => o.target == i.target
   | .call => (barring p j i).filter fun o => o.call == i.call).map Intent.call

/-- The disposition standing over a resource, with the journal as it stood before it. -/
@[req "STA-24"] def standing (p : Params) (j : Journal) (r : Resource) :
    Option (Disposition × Journal) :=
  standingIn p r (inEffect p j)

/-- The calls a standing disposition disposed, as their intents: those it names on its resource
in the journal as it stood before it. A replacement names "the calls the standing one disposed"
(`STA-24`), which are there too. -/
def disposed (s : Disposition × Journal) : List Intent :=
  (intentsOf s.2).filter fun i => i.resource == s.1.resource && s.1.calls.contains i.call

/-- The reach of a standing disposition, for an operation of kind `k`: "what the calls it names
barred while they were unresolved" (`STA-24`), which is `bars` read over the disposed calls and
neither the resource, the continuation nor the calls still unresolved. `bars` already answers no
for a read and for the inference request, so "A read and the inference request are never
restricted". The other cases of `Reach` are the readings retained as traps. -/
@[req "STA-24"] def reaches (p : Params) (e : Journal) (s : Disposition × Journal) (k : Kind) :
    Bool :=
  match p.reach with
  | .disposed => (disposed s).any fun o => bars o.kind k
  | .resource => sideEffecting k
  | .everyDispatch => true
  | .stillUnresolved =>
    ((disposed s).filter fun o => unresolvedIn p e o.resource o.call).any fun o => bars o.kind k

/-- What a continuation permits within the reach (`STA-24`). "A destructive reinstall permits
only the reinstall, abandonment only the abandonment flow": the operation the continuation is
dispatched at, and the preparation admitted before it. The two that continue restrict nothing,
and by rule rather than outright: "everything the disposed calls barred is permitted again, a
re-issue of the same operation included", which is the reach itself. A permission is not a
dispatch: `admit` has checked the binding, the approved record and the barrier before it reads
this. -/
@[req "STA-24"] def permits (p : Params) (e : Journal) (s : Disposition × Journal) (k : Kind) :
    Bool :=
  if p.sessionDestroyRefused && s.1.continuation == .abandon then false
  else if destructive s.1.continuation then
    dispatchesContinuation p e s.1.resource s.1.continuation k || prepares s.1.continuation k
  else (disposed s).any fun o => bars o.kind k

/-- The stop a destructive continuation adds beside the reach (`STA-24`): "the harness worker
MUST refuse the model's box-plane commands to that machine, whatever the disposed call was". It
is `exec` and nothing else, so reads stay permitted throughout. -/
@[req "STA-24"] def stops (p : Params) (c : Continuation) (k : Kind) : Bool :=
  p.destructiveStops && destructive c && k == .exec

/-- Whether a standing disposition refuses an operation of kind `k` on the resource, and under
which continuation: the destructive stop, or an operation within the reach that the continuation
does not permit. Without `dispositionBindsContinuation` a disposition ends the calls it names and
restricts nothing, which is the disposition read as unrestricted dispatch. -/
@[req "STA-24"] def restricted (p : Params) (j : Journal) (r : Resource) (k : Kind) :
    Option Continuation :=
  if !p.dispositionBindsContinuation then none
  else match standing p j r with
    | none => none
    | some s =>
      if stops p s.1.continuation k
         || (reaches p (inEffect p j) s k && !permits p (inEffect p j) s k)
      then some s.1.continuation else none

/-- The continuation in force over a resource: the standing disposition's, where one stands. -/
@[req "STA-24"] def restriction (p : Params) (j : Journal) (r : Resource) : Option Continuation :=
  if p.dispositionBindsContinuation then (standing p j r).map (·.1.continuation) else none

/-- Records since the newest approval matching the entry, reset call, session and approved facts.
No match leaves the whole journal, so its length also distinguishes an absent approval. -/
def sinceApproval (j : Journal) (i : Intent) : Journal :=
  j.takeWhile fun rec => match rec with
    | .reinstallApproval e c ap =>
      !(i.resource == .machine e && i.call == c && i.approval == ap)
    | _ => true

/-- Only a reset with a matching separately journaled approval is approval-bound. -/
def approvalBound (j : Journal) (i : Intent) : Bool :=
  i.kind == .reset && (sinceApproval j i).length < j.length

/-- A matching withdrawal after the newest approval; other approvals remain independent. -/
def approvalWithdrawn (p : Params) (j : Journal) (i : Intent) : Bool :=
  p.reinstallWithdrawalEffective && approvalBound j i && (sinceApproval j i).any fun rec =>
    match rec with
    | .reinstallWithdrawal e c ap =>
      i.resource == .machine e && i.call == c && i.approval == ap
    | _ => false

/-- A withdrawal is refused only after that approval's reset was dispatched. Missing approvals
and repeated withdrawals record an act that withdraws nothing further. -/
def acceptsWithdrawal (j : Journal) (e : Entry) (c : CallId) (ap : Approval) : Bool :=
  let i : Intent := ⟨c, .entry e, .machine e, .reset, ap.session, ap⟩
  !(approvalBound j i && (intentsOf (sinceApproval j i)).any fun prior =>
    prior.resource == i.resource && prior.kind == .reset && prior.call == c && prior.approval == ap)

/-- The approval is tied to this reset's call, resource, session and approved facts. Only records
since its newest matching approval supply the activation and its newest durable confirming read.
A matching withdrawal there refuses it, even under a reinstall disposition. Re-approval starts
again; a disposition does not withdraw an approval. No generation is supplied by the approval.
Other reset calls cannot consume it; a dispatched reset cannot consume it twice. -/
def approvedRescueReset (p : Params) (j : Journal) (i : Intent) : Bool :=
  let since := sinceApproval j i
  since.length < j.length && !approvalWithdrawn p j i &&
    !(intentsOf since).any (fun prior => prior.call == i.call) &&
    go since none since
where
  go (since : Journal) (read : Option Standing) : Journal → Bool
    | [] => false
    | .intent prior :: rest =>
      if prior.resource == i.resource && prior.kind == .reset then false
      else if prior.resource == i.resource && prior.kind == .activate &&
          !unresolvedIn p since i.resource prior.call then
        !p.newestActivationRead || (match read with | some s => confirms p s | none => false)
      else go since read rest
    | .observation o :: rest =>
      go since (if read.isNone && admissible o && o.resource == i.resource && o.kind == .activate
          then some o.standing else read) rest
    | _ :: rest => go since read rest

/-- The installation boundary is derived from dispatched intents, never from a choice or
from an event-supplied verdict. The reset that dispatches a standing reinstall counts too,
as does the reset bound to a separately journaled destructive-reinstall approval. -/
@[req "STG-20"] def installationOf (p : Params) (j : Journal) (e : Entry) : Nat :=
  go (inEffect p j)
where
  go : Journal → Nat
    | [] => 0
    | .intent i :: rest =>
      go rest + (if i.resource == .machine e &&
        (i.kind == .reinstall || (i.kind == .reset && (
          (p.approvedReinstallBoundary && approvedRescueReset p rest i) ||
          ((standingIn p (.machine e) rest).any fun s =>
            s.1.continuation == .reinstall &&
              dispatchesContinuation p rest (.machine e) .reinstall .reset)))) then 1 else 0)
    | _ :: rest => go rest

/-- The durable prerequisite reads of this installation, newest first. The first one, read
oldest first, anchors the offer; the newest must still match it. An anchor repeating an earlier
installation's prerequisite keys withholds the offer. Keys are opaque ordinals, never a
trace-supplied comparison verdict. -/
@[req "STA-20b"] def prerequisiteKeys (p : Params) (j : Journal) (e : Entry) : List Nat :=
  j.filterMap fun rec => match rec with
    | .resetPrereqs m n keys =>
      if m == e && n == installationOf p j e then some keys else none
    | _ => none

/-- The installed-system reset offer reads durable prerequisites in the current installation,
with the newest keys equal to that installation's first durable read. A changed key withholds
it; a predecessor's record cannot make it. A first set identical to any earlier installation's
prerequisite set also withholds it before reboot. Partial overlap and installed-pin comparison
are Markdown-only. The running memory is the durable journal under the append guard. A newer
`resetCollection` with no durable result after it withholds the offer for that entry and
installation. This is not a dispatch check for the single `reset` kind: the approval-bound
rescue reset's activation check is in `admit`, while `STG-4`'s
immediately preceding re-read duty is not carried here. -/
@[req "STA-20b"] def offersReset (p : Params) (j : Journal) (e : Entry) : Bool :=
  let latest := j.findSome? fun rec => match rec with
    | .resetCollection m n =>
      if m == e && n == installationOf p j e then some false else none
    | .resetPrereqs m n _ =>
      if m == e && n == installationOf p j e then some true else none
    | _ => none
  if p.failedPrerequisiteWithdraws && latest == some false then false
  else if p.resetOfferCurrentInstallation then
    let keys := prerequisiteKeys p j e
    !keys.isEmpty && keys.head? == keys.getLast? &&
      (!p.resetOfferFreshKeys || !j.any fun rec => match rec with
        | .resetPrereqs m n old =>
          m == e && n < installationOf p j e && keys.getLast? == some old
        | _ => false)
  else j.any fun rec => match rec with | .resetPrereqs m _ _ => m == e | _ => false

/-! ## The dispatch decision -/

/-- What the model sees in a refused request's place (`STA-24`: "The request is refused and the
unresolved call is shown in its place: to the model as the tool result, to the operator on the
screen"). -/
inductive Refusal
  /-- The target names no resource the harness assigned (`ARC-22`). -/
  | unmapped
  /-- `SEC-4`: the approval binds another session. -/
  | binding
  /-- `SEC-4`: "What is dispatched is the approved record", and this request is not it. -/
  | facts
  /-- `STA-3`: the intent's own append failed, so "the transition does not occur". -/
  | append
  /-- `STA-24`: the unresolved calls the barrier stands on. -/
  | barrier (calls : List CallId)
  /-- `STA-24`: a disposition stands over the resource, and its continuation, shown here, does
  not permit this operation. -/
  | continuation (inForce : Continuation)
  /-- `STG-20`: no confirming activation dispatched since the matching approval, or the
  approval's reset was already dispatched and the same call is requested again. -/
  | approvalActivation
  /-- `STG-20`: the refusal names the matching withdrawal, not an activation. -/
  | withdrawnApproval (resource : Resource) (call : CallId) (approval : Approval)
  deriving DecidableEq, Repr

inductive Verdict
  | dispatched (i : Intent)
  | refused (r : Refusal)
  deriving DecidableEq, Repr

/-- What a model sends (ADR-0032: "Requests carry what a model would send; the file never
supplies an already-correct resource key, so the request-to-entry mapping is what gets
compared"): a fresh call id, the target it names, the operation, the session it runs in, and the
facts it asks for. The resource is not here. -/
structure Request where
  call : CallId
  target : Target
  kind : Kind
  session : SessionId
  facts : Facts
  deriving DecidableEq, Repr

/-- The intent record a request becomes once the harness has resolved its resource. -/
def intentOf (rq : Request) (r : Resource) (ap : Approval) : Intent :=
  { call := rq.call, target := rq.target, resource := r, kind := rq.kind,
    session := rq.session, approval := ap }

/-- The dispatch check, in the order the requirements put it: the harness resolves what the model
named (`STA-24`), `SEC-4`'s binding and approved record are checked, and only then `STA-24`'s
barrier — "An approval already rendered does not clear the barrier; it is checked again at
dispatch" — then a matching withdrawal, and then what a standing disposition restricts.
Otherwise an approval-bound reset also needs `approvedRescueReset`.
Every other reset retains its previous checks. Total, with refusal order defined here.

A request here is a session's. Under a standing abandonment `permits` refuses its destroy;
the operator flow's destroy intent may end the restriction when appended outside this function.
The flow's authorization is `SEC-4`'s and is not carried here. -/
@[req "STA-4"] def admit (p : Params) (j : Journal) (rq : Request) (ap : Approval) : Verdict :=
  match resolve j rq.target with
  | none => .refused .unmapped
  | some r =>
    if ap.session != rq.session then .refused .binding
    else if ap.facts != rq.facts then .refused .facts
    else match blocking p j (intentOf rq r ap) with
      | c :: cs => .refused (.barrier (c :: cs))
      | [] =>
        if approvalWithdrawn p j (intentOf rq r ap) then
          .refused (.withdrawnApproval r rq.call ap)
        else match restricted p j r rq.kind with
        | some c => .refused (.continuation c)
        | none =>
          if p.approvalResetRequiresRescue && approvalBound j (intentOf rq r ap) &&
              !approvedRescueReset p j (intentOf rq r ap) then .refused .approvalActivation
          else .dispatched (intentOf rq r ap)

/-! ## The trace -/

/-- The worker as a trace runs it: the durable journal, the running worker's in-memory state, the
effects dispatched and the last request's verdict. `STA-2` makes the second authoritative "only
while a worker is running", and `STA-3` makes it equal to the first. -/
structure World where
  journal : Journal
  memory : Journal
  /-- The effects the harness dispatched, newest first. -/
  dispatched : List Intent
  /-- What the last request was answered with. -/
  verdict : Option Verdict
  deriving DecidableEq, Repr

/-- `STA-3`. Under the rule a failed append changes neither the journal nor in-memory state;
without it the record reaches memory alone, which a replay then discards — and in between the
worker acts on a fact the journal does not hold. -/
@[req "STA-3"] def append (p : Params) (w : World) (rec : Rec) : Bool → World
  | true => { w with journal := rec :: w.journal, memory := rec :: w.memory }
  | false => if p.durableBeforeApply then w else { w with memory := rec :: w.memory }

inductive Event
  /-- A request, with the storage outcome of the intent's own append (`STA-3`). -/
  | request (rq : Request) (ap : Approval) (appended : Bool)
  /-- A read of the far side: its provenance, the resource and the operation it is a predicate
  for, and the storage outcome of its append. What it reports is external state's. -/
  | observe (provenance : Provenance) (resource : Resource) (kind : Kind) (appended : Bool)
  /-- The operator disposes (`STA-24`), with the storage outcome of the record's own append. -/
  | dispose (d : Disposition) (appended : Bool)
  /-- The harness associates what a model may name with the approved entry. -/
  | associate (t : Target) (e : Entry)
  /-- `ready_to_reset` (`ARC-43`) records the installed pins and the reset intent (`STA-20b`). -/
  | resetPrereqs (e : Entry) (keys : Nat) (appended : Bool)
  /-- The existing journaled typed approval of a destructive reinstall, bound to its reset. -/
  | approveReinstall (e : Entry) (call : CallId) (approval : Approval) (appended : Bool)
  /-- The operator's withdrawal of a dedicated reinstall approval (`STG-20`). -/
  | withdrawReinstall (e : Entry) (call : CallId) (approval : Approval) (appended : Bool)
  /-- The worker is killed and replays the journal (`STA-7`). -/
  | replay
  deriving DecidableEq, Repr

/-- One event. A request that `admit` accepts is journaled "immediately before the bytes leave"
(`STA-4`) and dispatched; if that append fails the transition does not occur and nothing leaves
(`STA-3`). A read's standing is what the far side reports and never this module's. A disposition
that `accepts` refuses is not recorded. A replay throws in-memory state away and rebuilds it from
the journal (`STA-2`, `STA-7`). -/
@[req "STA-4"] def step (p : Params) (x : External) (w : World) : Event → World
  | .request rq ap ok =>
    match admit p w.memory rq ap with
    | .refused reason => { w with verdict := some (.refused reason) }
    | .dispatched i =>
      if ok || !p.durableBeforeApply then
        { append p w (.intent i) ok with
          dispatched := i :: w.dispatched, verdict := some (.dispatched i) }
      else { w with verdict := some (.refused .append) }
  | .observe prov r k ok =>
    { append p w (.observation ⟨prov, r, k, x.reports r k⟩) ok with verdict := none }
  | .dispose d ok =>
    if accepts p w.memory d then { append p w (.disposition d) ok with verdict := none }
    else { w with verdict := none }
  | .associate t e => { append p w (.association t e) true with verdict := none }
  | .resetPrereqs e keys ok =>
    let n := installationOf p w.memory e
    let started := append p w (.resetCollection e n) true
    { append p started (.resetPrereqs e n keys) ok with verdict := none }
  | .approveReinstall e c ap ok =>
    { append p w (.reinstallApproval e c ap) ok with verdict := none }
  | .withdrawReinstall e c ap ok =>
    if acceptsWithdrawal w.memory e c ap then
      { append p w (.reinstallWithdrawal e c ap) ok with verdict := none }
    else { w with verdict := none }
  | .replay => { w with memory := w.journal, verdict := none }

def run (p : Params) (x : External) (w : World) : List Event → World
  | [] => w
  | e :: es => run p x (step p x w e) es

/-! ## Over every trace -/

/-- `STA-3`, read off `append`: a failed append leaves the world as it was. -/
theorem append_failed (p : Params) (hp : p.durableBeforeApply = true) (w : World) (rec : Rec) :
    append p w rec false = w := by
  show (if p.durableBeforeApply = true then w else _) = w
  rw [hp, if_pos rfl]

/-- Under `STA-3` the running worker holds exactly what was durably appended. -/
theorem append_memory_eq (p : Params) (hp : p.durableBeforeApply = true) (w : World)
    (hw : w.memory = w.journal) (rec : Rec) (ok : Bool) :
    (append p w rec ok).memory = (append p w rec ok).journal := by
  cases ok with
  | true => simp only [append]; exact congrArg (rec :: ·) hw
  | false => rw [append_failed p hp]; exact hw

/-- What `admit` established when it dispatched: the intent it built is the request under the
approval, the binding holds, the approved facts are the requested ones, no unresolved call bars
it, and no standing disposition restricts it. -/
theorem admit_dispatched (p : Params) (j : Journal) (rq : Request) (ap : Approval) (i : Intent)
    (h : admit p j rq ap = .dispatched i) :
    i.call = rq.call ∧ i.kind = rq.kind ∧ i.approval = ap ∧ i.session = ap.session ∧
    ap.facts = rq.facts ∧ blocking p j i = [] ∧ restricted p j i.resource i.kind = none := by
  unfold admit at h
  split at h
  · exact nomatch h
  · split at h
    · exact nomatch h
    · split at h
      · exact nomatch h
      · rename_i hses hfacts
        simp only [Bool.not_eq_true, bne_eq_false_iff_eq] at hses hfacts
        split at h
        · exact nomatch h
        · rename_i hblock
          split at h
          · exact nomatch h
          · split at h
            · exact nomatch h
            · rename_i hnone
              split at h
              · exact nomatch h
              · injection h with h
                subst h
                exact ⟨rfl, rfl, rfl, hses.symm, hfacts, hblock, hnone⟩

/-- What it is for a standing disposition not to restrict an operation: the destructive stop does
not apply to it, and if it is within the reach the continuation permits it. -/
theorem restricted_none (p : Params) (j : Journal) (r : Resource) (k : Kind)
    (s : Disposition × Journal) (hb : p.dispositionBindsContinuation = true)
    (hs : standing p j r = some s) (h : restricted p j r k = none) :
    stops p s.1.continuation k = false ∧
    (reaches p (inEffect p j) s k = true → permits p (inEffect p j) s k = true) := by
  simp only [restricted, hb, hs, Bool.not_true, Bool.false_eq_true, if_false] at h
  split at h
  · exact nomatch h
  · rename_i hc
    simp only [Bool.or_eq_true, Bool.and_eq_true, Bool.not_eq_true', not_or, not_and,
      Bool.not_eq_true, Bool.not_eq_false] at hc
    exact ⟨hc.1, hc.2⟩

/-- **The principal theorem.** Over every journal, every request, every approval and every
external state: an effect is dispatched only if its intent and approval are durable — the intent
record, carrying the approval, is in the journal the step appended — the binding still holds, the
approved facts are what is dispatched, no unresolved call bars it, and under a standing
disposition it is not one of the model's commands a destructive continuation stops and, where it
is within the disposition's reach, the continuation permits it.

Restated 2026-10-13. Until then the last clause read that every dispatch under a standing
disposition is the continuation it names, whatever the operation: a read was refused, and so was
a command a disposed activation never barred. The clause is now over the reach. -/
@[req "STA-4"] theorem dispatched_only_if (p : Params) (hp : p.durableBeforeApply = true)
    (x : External) (w : World) (rq : Request) (ap : Approval) (ok : Bool) (i : Intent)
    (hi : i ∈ (step p x w (.request rq ap ok)).dispatched) (hnew : i ∉ w.dispatched) :
    Rec.intent i ∈ (step p x w (.request rq ap ok)).journal ∧
    i.approval = ap ∧ i.session = ap.session ∧ ap.facts = rq.facts ∧
    blocking p w.memory i = [] ∧
    ∀ s, p.dispositionBindsContinuation = true → standing p w.memory i.resource = some s →
      stops p s.1.continuation i.kind = false ∧
      (reaches p (inEffect p w.memory) s i.kind = true →
        permits p (inEffect p w.memory) s i.kind = true) := by
  simp only [step] at hi ⊢
  split at hi
  · exact absurd hi hnew
  · rename_i i' hadm
    split at hi
    · rename_i hcond
      have hok : ok = true := by
        simp only [hp, Bool.not_true, Bool.or_false] at hcond; exact hcond
      subst hok
      simp only [append] at hi ⊢
      rcases List.mem_cons.mp hi with rfl | hi
      · obtain ⟨_, _, ha, hs, hf, hb, hc⟩ := admit_dispatched p w.memory rq ap i hadm
        exact ⟨List.mem_cons_self .., ha, hs, hf, hb,
          fun s hbind hst => restricted_none p w.memory i.resource i.kind s hbind hst hc⟩
      · exact absurd hi hnew
    · exact absurd hi hnew

/-- **A read and the inference request are never restricted**, over every journal, every resource
and every standing disposition, under the rule's reach: `bars` answers no for both, so neither is
within any disposition's reach, and the destructive stop is on `exec` alone. -/
@[req "STA-24"] theorem read_and_inference_unrestricted (p : Params) (hp : p.reach = .disposed)
    (j : Journal) (r : Resource) :
    restricted p j r .read = none ∧ restricted p j r .inference = none := by
  have hread : ∀ k, bars k .read = false := fun k => by cases k <;> rfl
  have hinf : ∀ k, bars k .inference = false := fun k => by cases k <;> rfl
  constructor <;>
  · unfold restricted
    split
    · rfl
    · split
      · rfl
      · simp [stops, reaches, hp, hread, hinf]

/-- **A failed append leaves the barrier standing.** `STA-24`: evidence is "durably appended
before dispatch resumes (`STA-3`): a status read followed by a failed append leaves the barrier
standing." Over every journal, every read and every resource: the step changes nothing. -/
@[req "STA-3"] theorem failed_append_keeps_barrier (p : Params) (hp : p.durableBeforeApply = true)
    (x : External) (w : World) (prov : Provenance) (r' : Resource) (k : Kind) (r : Resource) :
    unresolved p (step p x w (.observe prov r' k false)).memory r = unresolved p w.memory r := by
  have h : step p x w (.observe prov r' k false) = { w with verdict := none } := by
    simp only [step, append_failed p hp]
  rw [h]

/-- **Only an adapter read or a pin-checked handshake confirms a cloud-plane intent.** `STA-24`:
a job record "cannot clear a cloud-plane barrier, and neither can model text (`SEC-8`)", and
`CHN-17`'s notify event is the machine's word as well. -/
@[req "STA-24"] theorem cloud_confirmed_by_read_only (p : Params) (i : Intent)
    (hc : cloudPlane i.kind = true) (o : Observation) (h : settles p i (.observation o) = true) :
    o.provenance = .adapterRead ∨ o.provenance = .pinCheckedHandshake := by
  simp only [settles, Bool.and_eq_true, admissible] at h
  obtain ⟨⟨⟨hadm, hres⟩, hkind⟩, _⟩ := h
  simp only [beq_iff_eq] at hkind
  cases hp : o.provenance with
  | adapterRead => exact Or.inl rfl
  | pinCheckedHandshake => exact Or.inr rfl
  | jobRecord =>
    rw [hp] at hadm
    simp only [Bool.not_eq_eq_eq_not, Bool.not_true] at hadm
    rw [hkind, hc] at hadm
    exact Bool.noConfusion hadm
  | notifyEvent => rw [hp] at hadm; exact Bool.noConfusion hadm
  | modelText => rw [hp] at hadm; exact Bool.noConfusion hadm

/-- **The inference request is unbarred**, and an unresolved one bars nothing. `STA-24`: it
"keeps its unresolved intent under `STA-8`, shown as unaccounted spend against the session key's
cap, and does **not** bar the next request: its only effect is bounded spend, and the next
request is the session's only way to continue." -/
@[req "STA-24"] theorem inference_unbarred (p : Params) (j : Journal) (i : Intent)
    (h : i.kind = .inference) :
    blocking p j i = [] ∧ ∀ k, bars .inference k = false := by
  have hb : ∀ k, bars k .inference = false := fun k => by cases k <;> rfl
  refine ⟨?_, fun k => by cases k <;> rfl⟩
  have hnil : barring p j i = [] :=
    List.filter_eq_nil_iff.mpr fun o _ => by simp [h, hb]
  simp only [blocking, hnil]
  cases p.resourceKey <;> rfl

theorem step_memory_eq (p : Params) (hp : p.durableBeforeApply = true) (x : External)
    (w : World) (hw : w.memory = w.journal) (e : Event) :
    (step p x w e).memory = (step p x w e).journal := by
  cases e with
  | request rq ap ok =>
    simp only [step]
    split
    · exact hw
    · split
      · exact append_memory_eq p hp w hw _ ok
      · exact hw
  | observe prov r k ok => exact append_memory_eq p hp w hw _ ok
  | dispose d ok =>
    simp only [step]
    split
    · exact append_memory_eq p hp w hw _ ok
    · exact hw
  | associate t e => exact append_memory_eq p hp w hw _ true
  | resetPrereqs e keys ok =>
    exact append_memory_eq p hp _ (append_memory_eq p hp w hw _ true) _ ok
  | approveReinstall e c ap ok => exact append_memory_eq p hp w hw _ ok
  | withdrawReinstall e c ap ok =>
    simp only [step]
    split
    · exact append_memory_eq p hp w hw _ ok
    · exact hw
  | replay => exact rfl

theorem run_memory_eq (p : Params) (hp : p.durableBeforeApply = true) (x : External)
    (w : World) (hw : w.memory = w.journal) (es : List Event) :
    (run p x w es).memory = (run p x w es).journal := by
  induction es generalizing w with
  | nil => exact hw
  | cons e es ih => exact ih (step p x w e) (step_memory_eq p hp x w hw e)

/-- **Replay yields the same unresolved set.** `STA-24`: the barrier "is a fact of the journal —
an intent with no terminal record — and survives replay (`STA-7`) and session succession without
an event of its own, because an event recording 'became unresolved' is exactly what a crash could
fail to write." Over every trace and every resource: the worker that is killed and replays reads
the barrier it read before. -/
@[req "STA-7"] theorem replay_same_unresolved (p : Params) (hp : p.durableBeforeApply = true)
    (x : External) (w : World) (hw : w.memory = w.journal) (es : List Event) (r : Resource) :
    unresolved p (step p x (run p x w es) .replay).memory r =
      unresolved p (run p x w es).memory r := by
  simp only [step]
  rw [run_memory_eq p hp x w hw es]

/-! ## The witnesses, decided -/

/-- What the far side reports, as data, so that a witness file can carry the adapter's answer per
read. The module's functions take `External`, of which this is one value: what a vendor or
machine actually did stays an assumption and never a table this module owns. -/
structure Far where
  succeeded : List (Resource × Kind)
  ended : List (Resource × Kind)
  deriving DecidableEq, Repr

def Far.external (f : Far) : External :=
  { reports := fun r k =>
      if f.succeeded.contains (r, k) then .succeeded
      else if f.ended.contains (r, k) then .ended
      else .unknown }

/-- Two approved machine entries of one setup batch (`ARC-15`): the one every witness works
against, and a sibling, which `STA-24` makes independent — "A different approved entry is
independent, and creating it while a sibling is unresolved is permitted under its own approval".
The values are opaque. -/
def entryA : Entry := 1
def entryB : Entry := 2

def machineA : Resource := .machine entryA
def machineB : Resource := .machine entryB

/-- The immutable vendor machine id once learned, and the reserved allocation indices — the first
attempt's, the one a second attempt at the same entry would reserve, and the sibling entry's
(`STA-22b`). -/
def vendorA : Nat := 10
def index0 : Nat := 0
def index1 : Nat := 1
def index2 : Nat := 2

/-- The bound session (`SEC-1`) and its successor, which `STA-24` makes no difference to:
"including a session that re-enters or succeeds the one that raised it". -/
def sessionA : SessionId := 1
def sessionB : SessionId := 2

def factsReset : Facts := 1
def factsCreate : Facts := 2
def factsExec : Facts := 3
def factsRegister : Facts := 4
def factsActivate : Facts := 5
def factsDestroy : Facts := 6
def factsCreateB : Facts := 7
def factsReinstall : Facts := 8
def factsRead : Facts := 9
def factsInference : Facts := 10

/-- The associations the harness journaled: the reserved allocation indices and the immutable
vendor machine id, each against the approved entry. The mapping is the harness's — `STA-24`: the
resource is "assigned or checked by the harness and never taken from the model" — so it is here
and never in a request. -/
def associations : Journal :=
  [.association (.vendor vendorA) entryA, .association (.index index1) entryA,
   .association (.index index0) entryA, .association (.index index2) entryB]

/-- The worker as the witnesses start it: the associations journaled, nothing dispatched. -/
def init : World :=
  { journal := associations, memory := associations, dispatched := [], verdict := none }

/-- The far side of the ceremony: every operation on the approved entry succeeded, and the
sibling's create did too. -/
def farDone : Far :=
  { succeeded := [(machineA, .reset), (machineA, .create), (machineA, .registerKey),
                  (machineA, .activate), (machineA, .exec), (machineA, .reinstall),
                  (machineB, .create)],
    ended := [] }

/-- The far side after an unexpected rescue reboot: the reset's boot ID changed, which "proves
the old command cannot still be running" and nothing more (`STA-20b`). -/
def farEnded : Far := { succeeded := [], ended := [(machineA, .reset)] }

def approvalReset : Approval := { session := sessionA, facts := factsReset }
/-- The same facts approved for the successor session: `SEC-4` binds an approval to the calling
session, so a successor carries its own. -/
def approvalResetB : Approval := { session := sessionB, facts := factsReset }
def approvalCreate : Approval := { session := sessionA, facts := factsCreate }
/-- The sibling entry's own approval: `STA-24` permits creating it while a sibling is unresolved
"under its own approval, whose card shows the unresolved sibling and that it may be billing". -/
def approvalCreateB : Approval := { session := sessionA, facts := factsCreateB }
def approvalExec : Approval := { session := sessionA, facts := factsExec }
def approvalRegister : Approval := { session := sessionA, facts := factsRegister }
def approvalActivate : Approval := { session := sessionA, facts := factsActivate }
def approvalDestroy : Approval := { session := sessionA, facts := factsDestroy }
/-- The vendor's reinstall call approved for the successor session. -/
def approvalReinstallB : Approval := { session := sessionB, facts := factsReinstall }
def approvalRead : Approval := { session := sessionA, facts := factsRead }
def approvalInference : Approval := { session := sessionA, facts := factsInference }

/-- The destructive call: a reset of the machine the vendor id names. Its second request is the
same action under a fresh call id, which is what a model sends when no confirmation arrives. -/
def resetRequest1 : Request :=
  { call := 1, target := .vendor vendorA, kind := .reset, session := sessionA,
    facts := factsReset }
def resetRequest2 : Request := { resetRequest1 with call := 2 }
/-- The vendor's reinstall call, which the disposition below names, requested by the successor
session: the barrier holds "whichever session or model requests it" (`STA-24`), and so does what
a disposition permits. -/
def reinstallRequest : Request :=
  { call := 3, target := .vendor vendorA, kind := .reinstall, session := sessionB,
    facts := factsReinstall }
/-- The ceremony's second reset, into the installed system, whose predicate is sshd answering
with the installed pin (`STG-4`). -/
def resetRequest4 : Request := { resetRequest1 with call := 11 }
/-- Two further requests for a reset during a return to rescue, each under a fresh call id. -/
def resetRequest5 : Request := { resetRequest1 with call := 18 }
def resetRequest6 : Request := { resetRequest1 with call := 19 }

/-- The create at the first reserved index, and a second attempt at the same approved entry,
which would reserve another. -/
def createRequest0 : Request :=
  { call := 4, target := .index index0, kind := .create, session := sessionA,
    facts := factsCreate }
def createRequest1 : Request := { createRequest0 with call := 5, target := .index index1 }
/-- The sibling entry's create: a different approved entry, under its own approval. -/
def createRequestB : Request :=
  { createRequest0 with call := 6, target := .index index2, facts := factsCreateB }

/-- Box-plane work on the machine, which a reset stops "from its intent until its confirmation"
(`STA-24`). -/
def execRequest : Request :=
  { call := 7, target := .vendor vendorA, kind := .exec, session := sessionA, facts := factsExec }
/-- Ordinary work on the installed system, after the second reset is confirmed. -/
def execRequest2 : Request := { execRequest with call := 12 }
/-- Further commands, each under a fresh call id. -/
def execRequest3 : Request := { execRequest with call := 17 }
def execRequest4 : Request := { execRequest with call := 20 }

/-- A destroy of the machine, which a disposition naming a destructive reinstall does not
permit. -/
def destroyRequest : Request :=
  { call := 8, target := .vendor vendorA, kind := .destroy, session := sessionA,
    facts := factsDestroy }

def registerRequest : Request :=
  { call := 9, target := .entry entryA, kind := .registerKey, session := sessionA,
    facts := factsRegister }
def activateRequest : Request :=
  { call := 10, target := .entry entryA, kind := .activate, session := sessionA,
    facts := factsActivate }

/-- The same activation requested again under a fresh call id: a re-issue, which under a
continuation that continues is the operator's explicit choice. -/
def activateRequest2 : Request := { activateRequest with call := 16 }

/-- A read naming the machine: a status query, the pinned SSH attempt or the collection of job
records (`STA-24`). -/
def readRequest : Request :=
  { call := 13, target := .vendor vendorA, kind := .read, session := sessionA, facts := factsRead }

/-- The inference request (`ARC-31a`), and the next one. -/
def inferenceRequest1 : Request :=
  { call := 14, target := .inferenceCap, kind := .inference, session := sessionA,
    facts := factsInference }
def inferenceRequest2 : Request := { inferenceRequest1 with call := 15 }

/-- The operator's disposition of the unresolved reset: it names the call and a destructive
reinstall (`STG-20`). -/
def dispositionA : Disposition :=
  { resource := machineA, calls := [resetRequest1.call], continuation := .reinstall }

/-- The same call disposed toward abandonment (`ARC-21`). After `dispositionA` it is a
replacement: it names the call the standing disposition disposed. -/
def abandonA : Disposition := { dispositionA with continuation := .abandon }

/-- An unresolved activation disposed to continue as if not done. -/
def continueAfterActivation : Disposition :=
  { resource := machineA, calls := [activateRequest.call], continuation := .asIfNotDone }

/-- An unresolved activation disposed toward a destructive reinstall. -/
def reinstallAfterActivation : Disposition :=
  { resource := machineA, calls := [activateRequest.call], continuation := .reinstall }

/-- An unresolved box-plane command disposed toward a destructive reinstall. -/
def reinstallAfterCommand : Disposition :=
  { resource := machineA, calls := [execRequest.call], continuation := .reinstall }

/-- An unresolved inference request disposed on its own resource, with a destructive choice so
that the request after it is made under one. -/
def abandonInference : Disposition :=
  { resource := .inference, calls := [inferenceRequest1.call], continuation := .abandon }

/-- A disposition naming a call that was never dispatched. -/
def namesNoUnresolvedCall : Disposition :=
  { resource := machineA, calls := [resetRequest2.call], continuation := .abandon }

/-- A disposition naming no call at all. -/
def namesNoCall : Disposition := { resource := machineA, calls := [], continuation := .abandon }

/-- A disposition naming an unresolved activation and, beside it, a key registration a read has
already settled. -/
def namesSettledCallToo : Disposition :=
  { resource := machineA, calls := [activateRequest.call, registerRequest.call],
    continuation := .abandon }

/-- A disposition recorded against the sibling entry and naming the first entry's call. -/
def onAnotherResource : Disposition :=
  { resource := machineB, calls := [resetRequest1.call], continuation := .abandon }

/-! Each witness's events are one named list, so that the theorem and the emitter
(`Witnesses.lean`) run the same trace. -/

def sameActionEvents : List Event :=
  [.request resetRequest1 approvalReset true, .request resetRequest2 approvalReset true]

def secondIndexEvents : List Event :=
  [.request createRequest0 approvalCreate true, .request createRequestB approvalCreateB true,
   .request createRequest1 approvalCreate true]

def resetOfferEvents : List Event := [.resetPrereqs entryA 101 false]

def bootIdEvents : List Event :=
  [.request resetRequest1 approvalReset true, .observe .adapterRead machineA .reset true,
   .request execRequest approvalExec true]

def appendFailedEvents : List Event :=
  [.request resetRequest1 approvalReset true, .observe .adapterRead machineA .reset false,
   .request execRequest approvalExec true, .replay]

def dispositionEvents : List Event :=
  [.request resetRequest1 approvalReset true, .dispose dispositionA true,
   .request destroyRequest approvalDestroy true, .request reinstallRequest approvalReinstallB true]

/-- The dispositions a journal holds, newest first, whether or not they are in effect. -/
def dispositionsOf (j : Journal) : List Disposition :=
  j.filterMap fun rec => match rec with | .disposition d => some d | _ => none

/-- An unresolved reset, a disposition naming abandonment, a read, a command. -/
def abandonReadEvents : List Event :=
  [.request resetRequest1 approvalReset true, .dispose abandonA true,
   .request readRequest approvalRead true, .request execRequest approvalExec true]

/-- An unresolved activation, a disposition that continues, the activation re-issued, a
command. -/
def continueEvents : List Event :=
  [.request activateRequest approvalActivate true, .dispose continueAfterActivation true,
   .request activateRequest2 approvalActivate true, .request execRequest approvalExec true]

/-- An unresolved activation, a disposition naming a destructive reinstall, a command. -/
def activationReinstallEvents : List Event :=
  [.request activateRequest approvalActivate true, .dispose reinstallAfterActivation true,
   .request execRequest approvalExec true]

/-- An unresolved command, a disposition naming a destructive reinstall, a second command, the
vendor's reinstall call, a third command, the reinstall's confirmation, a fourth command. -/
def commandReinstallEvents : List Event :=
  [.request execRequest approvalExec true, .dispose reinstallAfterCommand true,
   .request execRequest2 approvalExec true, .request reinstallRequest approvalReinstallB true,
   .request execRequest3 approvalExec true, .observe .adapterRead machineA .reinstall true,
   .request execRequest4 approvalExec true]

/-- An unresolved reset and an unresolved inference request, each disposed with a destructive
choice on its own resource, then a read and the next inference request. -/
def readInferenceEvents : List Event :=
  [.request resetRequest1 approvalReset true, .request inferenceRequest1 approvalInference true,
   .dispose abandonA true, .dispose abandonInference true,
   .request readRequest approvalRead true, .request inferenceRequest2 approvalInference true]

/-- An unresolved reset, a disposition naming a call never dispatched, one recorded against
another resource, and the same reset under a fresh call id. -/
def otherResourceEvents : List Event :=
  [.request resetRequest1 approvalReset true, .dispose namesNoUnresolvedCall true,
   .dispose onAnotherResource true, .request resetRequest2 approvalReset true]

/-- An unresolved reset and a disposition naming no call. -/
def noCallEvents : List Event :=
  [.request resetRequest1 approvalReset true, .dispose namesNoCall true]

/-- A key registration and its confirmation, an unresolved activation, a disposition naming both
calls, and the activation under a fresh call id. -/
def settledCallEvents : List Event :=
  [.request registerRequest approvalRegister true,
   .observe .adapterRead machineA .registerKey true,
   .request activateRequest approvalActivate true, .dispose namesSettledCallToo true,
   .request activateRequest2 approvalActivate true]

/-- An unresolved reset, a disposition naming a destructive reinstall, its replacement naming
abandonment, a replay, and the vendor's reinstall call. -/
def replacementEvents : List Event :=
  [.request resetRequest1 approvalReset true, .dispose dispositionA true, .dispose abandonA true,
   .replay, .request reinstallRequest approvalReinstallB true]

/-- A killed worker replays, and a command is requested. Run from `replayStart`. -/
def replayEvents : List Event := [.replay, .request execRequest approvalExec true]

/-- An unresolved reset, a disposition naming abandonment, evidence that the reset succeeded, a
command. -/
def evidenceAfterEvents : List Event :=
  [.request resetRequest1 approvalReset true, .dispose abandonA true,
   .observe .adapterRead machineA .reset true, .request execRequest approvalExec true]

/-- An unresolved reset, a disposition naming a destructive reinstall, and a reset with no rescue
activation dispatched since. -/
def strayResetEvents : List Event :=
  [.request resetRequest1 approvalReset true, .dispose dispositionA true,
   .request resetRequest2 approvalReset true]

/-- An unresolved reset, a disposition naming a destructive reinstall, the rescue activation, a
command. -/
def preparationEvents : List Event :=
  [.request resetRequest1 approvalReset true, .dispose dispositionA true,
   .request activateRequest approvalActivate true, .request execRequest approvalExec true]

/-- An unresolved reset and a disposition naming a destructive reinstall, with nothing requested
under it. -/
def reinstallStandingEvents : List Event :=
  [.request resetRequest1 approvalReset true, .dispose dispositionA true]

/-- A dedicated server's return to rescue under a disposition naming a destructive reinstall: a
reset before any rescue activation, the activation, a command, a reset before the activation is
confirmed, the confirmation, the reset into rescue, a command. -/
def returnToRescueEvents : List Event :=
  [.request resetRequest1 approvalReset true, .dispose dispositionA true,
   .request resetRequest2 approvalReset true,
   .request activateRequest approvalActivate true,
   .request execRequest approvalExec true,
   .request resetRequest5 approvalReset true,
   .observe .adapterRead machineA .activate true,
   .request resetRequest6 approvalReset true,
   .request execRequest2 approvalExec true]

/-- A rescue activation and its confirmation with no reset after it, a command left unresolved,
a disposition naming that command and a destructive reinstall, a reset, a rescue activation. -/
def earlierActivationEvents : List Event :=
  [.request activateRequest approvalActivate true,
   .observe .adapterRead machineA .activate true,
   .request execRequest approvalExec true, .dispose reinstallAfterCommand true,
   .request resetRequest1 approvalReset true,
   .request activateRequest2 approvalActivate true]

/-- An unresolved reset, a disposition naming a destructive reinstall, the rescue activation and
its confirmation, that disposition replaced by one naming abandonment and that one by a
destructive reinstall again, a reset, a rescue activation. -/
def replacedActivationEvents : List Event :=
  [.request resetRequest1 approvalReset true, .dispose dispositionA true,
   .request activateRequest approvalActivate true,
   .observe .adapterRead machineA .activate true,
   .dispose abandonA true, .dispose dispositionA true,
   .request resetRequest2 approvalReset true,
   .request activateRequest2 approvalActivate true]

/-- A server already in rescue: two commands unresolved, a disposition naming the first and a
destructive reinstall, the rescue activation requested while the second still runs, the second's
job record, the activation again, its confirmation, the reset into rescue. -/
def rescueCommandEvents : List Event :=
  [.request execRequest approvalExec true, .request execRequest2 approvalExec true,
   .dispose reinstallAfterCommand true,
   .request activateRequest approvalActivate true,
   .observe .jobRecord machineA .exec true,
   .request activateRequest2 approvalActivate true,
   .observe .adapterRead machineA .activate true,
   .request resetRequest2 approvalReset true]

/-- `STG-4`'s four confirmation predicates in order, each mutation dispatched once its
predecessor is confirmed: the key registered and confirmed by the account's key listing, the
activation by `GET /boot/{n}/rescue`, the reset into rescue by a host-key set sharing no fingerprint with the
journaled one (`CHN-R1`), the install run as box-plane work and settled by its own job record (`STA-20`,
advisory under `STA-21`), the reset into the installed system by sshd answering with the pin, and
only then ordinary work. -/
def ceremonyEvents : List Event :=
  [.request registerRequest approvalRegister true,
   .observe .adapterRead machineA .registerKey true,
   .request activateRequest approvalActivate true,
   .observe .adapterRead machineA .activate true,
   .request resetRequest1 approvalReset true,
   .observe .adapterRead machineA .reset true,
   .request execRequest approvalExec true,
   .observe .jobRecord machineA .exec true,
   .request resetRequest4 approvalReset true,
   .observe .pinCheckedHandshake machineA .reset true,
   .request execRequest2 approvalExec true]

/-- The activation confirmed under the reinstall disposition. -/
def spentActivationStartEvents : List Event :=
  reinstallStandingEvents ++ [.request activateRequest approvalActivate true,
    .observe .adapterRead machineA .activate true]

/-- A later read that does not confirm the activation, then the reset attempted under it. -/
def spentActivationReadEvents : List Event :=
  [.observe .adapterRead machineA .activate true, .request resetRequest2 approvalReset true]

/-- A fresh activation confirmed, followed by the reset into rescue. -/
def freshActivationEvents : List Event :=
  [.request activateRequest2 approvalActivate true, .observe .adapterRead machineA .activate true,
   .request resetRequest5 approvalReset true]

/-- Reports nothing about the activation. `unknown` asserts no negative outcome; the earlier
confirmation keeps the activation call terminal. -/
def activationNotConfirmed : Far :=
  { farDone with succeeded := farDone.succeeded.filter fun rk => rk != (machineA, .activate) }

def onCall : Params := { current with resourceKey := .call }
def onIndex : Params := { current with resourceKey := .index }
def noDurability : Params := { current with durableBeforeApply := false }
def flatLattice : Params := { current with endedBelowSucceeded := false }
def unboundDisposition : Params := { current with dispositionBindsContinuation := false }
def reachFromResource : Params := { current with reach := .resource }
def reachEveryDispatch : Params := { current with reach := .everyDispatch }
def reachStillUnresolved : Params := { current with reach := .stillUnresolved }
def noDestructiveStop : Params := { current with destructiveStops := false }
def lapseAnyIntent : Params := { current with lapse := .anyIntent }
def lapseFirstOperation : Params := { current with lapse := .firstOperation }
def anyResetReinstalls : Params := { current with resetIntoRescueOnly := false }
def staleActivationCounts : Params := { current with newestActivationRead := false }
def dispositionByCallId : Params := { current with dispositionOwnResource := false }

/-- A journal a replay finds, which no trace of `step` under the rules in force can write: the
reset's intent, unresolved, and a disposition recorded against the sibling entry that names it.
`acceptable` refuses that disposition, so `step` would have recorded nothing. -/
def replayJournal : Journal :=
  .disposition onAnotherResource ::
  .intent (intentOf resetRequest1 machineA approvalReset) :: associations

/-- The worker over that journal, the reset dispatched. -/
def replayStart : World :=
  { journal := replayJournal, memory := replayJournal,
    dispatched := [intentOf resetRequest1 machineA approvalReset], verdict := none }

/-- **The same destructive action under a new call id, refused.** The reset's response is lost,
so nothing settles it; the model asks again and its request carries a fresh call id. The barrier
is read at the approved entry, so the second request is refused with the first call shown in its
place, and one effect went out. -/
@[req "STA-24"] theorem same_action_new_call_id_refused :
    let w := run current farDone.external init sameActionEvents
    w.dispatched.map (·.call) = [1] ∧ w.verdict = some (.refused (.barrier [1])) ∧
    unresolved current w.memory machineA = [1] := by decide +kernel

/-- Keyed on the call instead — `STA-8` alone, which "speaks of a call, and a model does not
retry a call" — nothing refuses the second request: `POST /reset` "returns `running` with no
request identity", so "a second reset lands on a disk being written". -/
@[req "STA-24"] theorem same_action_new_call_id_admitted :
    let w := run onCall farDone.external init sameActionEvents
    w.dispatched.map (·.call) = [2, 1] ∧ unresolved onCall w.memory machineA = [2, 1] := by
  decide +kernel

/-- **A second allocation index for the same approved entry, refused.** The create at the first
index is unresolved; the sibling entry's create is dispatched beside it, since "A different
approved entry is independent"; and the second attempt at the same entry, which would reserve
another index, is refused with the first call in its place. -/
@[req "STA-24"] theorem second_index_same_entry_refused :
    let w := run current farDone.external init secondIndexEvents
    w.dispatched.map (·.call) = [6, 4] ∧ w.verdict = some (.refused (.barrier [4])) ∧
    unresolved current w.memory machineA = [4] := by decide +kernel

/-- Keyed on the allocation index, "the same hole one level up": the second attempt reserves
another index, nothing refuses it, and "A second create is a second billed machine". -/
@[req "STA-24"] theorem second_index_same_entry_admitted :
    let w := run onIndex farDone.external init secondIndexEvents
    w.dispatched.map (·.call) = [5, 6, 4] ∧ unresolved onIndex w.memory machineA = [5, 4] := by
  decide +kernel

/-- **A planned reset offered after a failed append, refused.** `ready_to_reset` read the pins
and the append failed, so the transition did not occur: neither the journal nor the running
worker holds the prerequisites, and the reset is not offered. -/
@[req "STA-20b"] theorem reset_offered_after_failed_append_refused :
    let w := run current farDone.external init resetOfferEvents
    offersReset current w.memory entryA = false ∧ offersReset current w.journal entryA = false ∧
    w.memory = w.journal := by decide +kernel

/-- Without `STA-3`'s rule the record reaches in-memory state alone, and the offer — "checked
against those durable prerequisites at the moment it is made" — is made against a fact the
journal does not hold. -/
@[req "STA-20b"] theorem reset_offered_after_failed_append_admitted :
    let w := run noDurability farDone.external init resetOfferEvents
    offersReset current w.memory entryA = true ∧ offersReset current w.journal entryA = false := by decide +kernel

/-- **A `boot_id` change read as success, refused.** The reset is unresolved and the vendor read
reports that the old command ended and nothing more. Under the lattice that does not confirm it,
so the barrier stands and the box-plane command that would race the reset is refused. -/
@[req "STA-20b"] theorem boot_id_change_not_success_refused :
    let w := run current farEnded.external init bootIdEvents
    w.dispatched.map (·.call) = [1] ∧ w.verdict = some (.refused (.barrier [1])) ∧
    unresolved current w.memory machineA = [1] := by decide +kernel

/-- Flattened, the same read confirms the reset, the barrier clears and the disk-writing command
goes out against a reset whose effects and exit status nothing established. -/
@[req "STA-20b"] theorem boot_id_change_not_success_admitted :
    let w := run flatLattice farEnded.external init bootIdEvents
    w.dispatched.map (·.call) = [7, 1] ∧ unresolved flatLattice w.memory machineA = [7] := by
  decide +kernel

/-- **A resolution observed but its append failed, refused.** The vendor read says the reset
succeeded and the append fails, so the barrier stands, the box-plane command is refused, and the
replay that follows reads the same barrier. -/
@[req "STA-3"] theorem resolution_append_failed_refused :
    let w := run current farDone.external init appendFailedEvents
    w.dispatched.map (·.call) = [1] ∧ w.verdict = none ∧
    unresolved current w.memory machineA = [1] ∧ w.memory = w.journal := by decide +kernel

/-- Without the rule dispatch resumes on a resolution the journal never took: the command goes
out, and the replay — which rebuilds in-memory state from the journal — puts the barrier back,
with the command already sent. -/
@[req "STA-3"] theorem resolution_append_failed_admitted :
    let w := run noDurability farDone.external init appendFailedEvents
    w.dispatched.map (·.call) = [7, 1] ∧ unresolved noDurability w.memory machineA = [7, 1] := by
  decide +kernel

/-- **A destructive continuation permits only itself.** The operator disposes of the unresolved
reset naming a destructive reinstall: the call is terminal with its outcome unknown, so it is no
longer an open one, and a destroy — which the reset barred and the reinstall is not — is refused
with the continuation in force shown. The vendor's reinstall call is dispatched, by the successor
session; from its intent the restriction is gone and its own barrier stands. -/
@[req "STA-24"] theorem disposition_one_continuation_refused :
    let w := run current farDone.external init dispositionEvents
    w.dispatched.map (·.call) = [3, 1] ∧ unresolved current w.memory machineA = [3] ∧
    restriction current w.memory machineA = none := by decide +kernel

/-- Without the rule the disposition restricts nothing: the destroy is dispatched against a
machine whose reset may have landed, and the continuation the operator did name is then barred by
it. -/
@[req "STA-24"] theorem disposition_unrestricted_admitted :
    let w := run unboundDisposition farDone.external init dispositionEvents
    w.dispatched.map (·.call) = [8, 1] ∧
    unresolved unboundDisposition w.memory machineA = [8] := by decide +kernel

/-- **A read does not lift an abandonment.** The reset is disposed naming abandonment. The read
that follows is outside the reach: it is dispatched, and it does not end the restriction, so the
command after it is still refused and the disposition still stands. -/
@[req "STA-24"] theorem read_does_not_lift_abandonment :
    let w := run current farDone.external init abandonReadEvents
    w.dispatched.map (·.call) = [13, 1] ∧
    w.verdict = some (.refused (.continuation .abandon)) ∧
    restriction current w.memory machineA = some .abandon := by decide +kernel

/-- The operation kinds an intent may carry, exhausted by `kinds_total`. -/
def kinds : List Kind :=
  [.create, .reset, .reinstall, .destroy, .activate, .registerKey, .exec, .read, .inference]

@[req "STA-24"] theorem kinds_total : ∀ k, k ∈ kinds := by intro k; cases k <;> decide

/-- **Abandonment ends at its destroy alone among operation kinds.** Read `restriction` over the
journal with an intent appended: the appended destroy is the abandonment flow's destroy as the
journal holds it, and only its resource and kind are read. The appended intent goes through neither
`admit` nor `step`; a session's destroy is restricted under abandonment: `ARC-21` runs abandonment "never through a
session", and `STA-24` says "abandonment only the abandonment flow". The
other intent fields are inert here and carry nothing of who sends a request. Restated 2026-10-16: the first conjunct refuses a destroy request; the appended flow intent
still ends the restriction. A replacement can still end the abandonment: it is a disposition, not an operation kind. -/
@[req "STA-24"] theorem abandonment_ends_at_its_destroy_alone : ∀ k ∈ kinds,
    let w := run current farDone.external init (abandonReadEvents.take 2)
    (k = .destroy → restricted current w.memory machineA k = some .abandon) ∧
    restriction current
      (.intent { call := 0, target := .entry entryA, resource := machineA, kind := k,
                 session := 0, approval := ⟨0, 0⟩ } :: w.memory) machineA =
      (if k = .destroy then none else some .abandon) := by decide +kernel

/-- With the restriction ended at any later intent, the read's own intent ends it: the command
goes out to a machine the operator chose to abandon. -/
@[req "STA-24"] theorem read_lifts_abandonment_without_guard :
    let w := run lapseAnyIntent farDone.external init abandonReadEvents
    w.dispatched.map (·.call) = [7, 13, 1] ∧
    restriction lapseAnyIntent w.memory machineA = none := by decide +kernel

/-- **A continuation that continues restricts nothing.** An unresolved activation is disposed to
continue as if not done. What it barred is permitted again: the activation is re-issued, under a
fresh call id and by the operator's choice. A command, which the activation never barred, was
never in reach and is dispatched too. The disposition still stands, restricting nothing. -/
@[req "STA-24"] theorem continuing_permits_what_was_barred :
    let w := run current farDone.external init continueEvents
    w.dispatched.map (·.call) = [7, 16, 10] ∧ unresolved current w.memory machineA = [7, 16] ∧
    restriction current w.memory machineA = some .asIfNotDone := by decide +kernel

/-- With the reach taken from the resource, the disposed activation begins to bar the box plane,
which the unresolved activation never did: the command is refused. -/
@[req "STA-24"] theorem disposed_activation_bars_commands_without_guard :
    let w := run reachFromResource farDone.external init continueEvents
    w.dispatched.map (·.call) = [16, 10] ∧
    w.verdict = some (.refused (.continuation .asIfNotDone)) := by decide +kernel

/-- **A destructive continuation stops the model's commands, whatever was disposed.** The disposed
call is an activation, which bars nothing on the box, and the command is refused all the same: the
continuation is a destructive reinstall. -/
@[req "STA-24"] theorem destructive_choice_stops_commands_after_activation :
    let w := run current farDone.external init activationReinstallEvents
    w.dispatched.map (·.call) = [10] ∧
    w.verdict = some (.refused (.continuation .reinstall)) ∧
    unresolved current w.memory machineA = [] := by decide +kernel

/-- **A destructive continuation stops the model's commands, and ends at its dispatch.** A command
is unresolved and disposed naming a destructive reinstall. A second command is refused by the
disposition, though an unresolved command bars no other. The vendor's reinstall call is
dispatched. From its intent the restriction is gone and the reinstall's own barrier holds the box
plane: a third command is refused by that barrier, and after the reinstall's confirmation a
fourth is dispatched. -/
@[req "STA-24"] theorem destructive_choice_stops_commands :
    let w := run current farDone.external init commandReinstallEvents
    let afterThird := run current farDone.external init (commandReinstallEvents.take 5)
    w.dispatched.map (·.call) = [20, 3, 7] ∧
    (run current farDone.external init (commandReinstallEvents.take 3)).verdict =
      some (.refused (.continuation .reinstall)) ∧
    afterThird.verdict = some (.refused (.barrier [3])) ∧
    restriction current afterThird.memory machineA = none ∧
    unresolved current w.memory machineA = [20] := by decide +kernel

/-- Without the stop the second command is dispatched between the choice and the reinstall, is
unresolved when the reinstall is requested, and bars it. -/
@[req "STA-24"] theorem command_preempts_reinstall_without_guard :
    let w := run noDestructiveStop farDone.external init commandReinstallEvents
    w.dispatched.map (·.call) = [20, 17, 12, 7] ∧
    (run noDestructiveStop farDone.external init (commandReinstallEvents.take 4)).verdict =
      some (.refused (.barrier [12])) := by decide +kernel

/-- **A read and the inference request are never restricted.** A destructive disposition stands
over the machine and another over the inference account. The read naming the machine and the next
inference request are both dispatched, and both dispositions still stand. -/
@[req "STA-24"] theorem read_and_inference_never_restricted :
    let w := run current farDone.external init readInferenceEvents
    w.dispatched.map (·.call) = [15, 13, 14, 1] ∧
    restriction current w.memory machineA = some .abandon ∧
    restriction current w.memory .inference = some .abandon := by decide +kernel

/-- With the restriction applied to every dispatch both are refused: the read that is how the
operator learns what happened, and the request that is the session's only way to continue. -/
@[req "STA-24"] theorem read_and_inference_restricted_without_guard :
    let w := run reachEveryDispatch farDone.external init readInferenceEvents
    w.dispatched.map (·.call) = [14, 1] ∧
    w.verdict = some (.refused (.continuation .abandon)) := by decide +kernel

/-- **A disposition names unresolved calls on its own resource, or it is not recorded.** One names
a call that was never dispatched and one is recorded against the sibling entry while naming this
entry's reset. Both are refused and the journal holds neither, so the reset is still unresolved
and the same action under a fresh call id is still refused. -/
@[req "STA-24"] theorem disposition_names_own_unresolved_calls :
    let w := run current farDone.external init otherResourceEvents
    w.dispatched.map (·.call) = [1] ∧ w.verdict = some (.refused (.barrier [1])) ∧
    dispositionsOf w.journal = [] ∧ unresolved current w.memory machineA = [1] := by
  decide +kernel

/-- Matched to a call by call id alone, the disposition recorded against the sibling entry ends
this entry's reset and restricts nothing here: the second reset lands. -/
@[req "STA-24"] theorem disposition_ends_call_elsewhere_without_guard :
    let w := run dispositionByCallId farDone.external init otherResourceEvents
    w.dispatched.map (·.call) = [2, 1] ∧ dispositionsOf w.journal = [onAnotherResource] ∧
    unresolved dispositionByCallId w.memory machineA = [2] := by decide +kernel

/-- **A disposition names at least one call, or it is not recorded.** The reset is unresolved and
the disposition offered names no call at all. It is refused and the journal does not hold it:
nothing stands over the machine, and the reset is still unresolved. -/
@[req "STA-24"] theorem disposition_names_at_least_one_call :
    let w := run current farDone.external init noCallEvents
    dispositionsOf w.journal = [] ∧ restriction current w.memory machineA = none ∧
    unresolved current w.memory machineA = [1] := by decide +kernel

/-- **Every call a disposition names is unresolved, or it is not recorded.** The key registration
is confirmed and the activation after it is unresolved; the disposition offered names both. One
unresolved call among those it names is not enough: it is refused and the journal does not hold
it, so the activation is still unresolved and the same activation under a fresh call id is
refused by its barrier. -/
@[req "STA-24"] theorem disposition_names_every_call_unresolved :
    let w := run current farDone.external init settledCallEvents
    w.dispatched.map (·.call) = [10, 9] ∧ w.verdict = some (.refused (.barrier [10])) ∧
    dispositionsOf w.journal = [] ∧ unresolved current w.memory machineA = [10] := by
  decide +kernel

/-- **A replacement is the disposition in force.** The standing disposition names a destructive
reinstall; the operator replaces it, naming the call it disposed and abandonment. The replacement
is recorded, and after a replay it is still the one in force: the vendor's reinstall call, the
former continuation, is refused under it. -/
@[req "STA-24"] theorem replacement_in_force :
    let w := run current farDone.external init replacementEvents
    w.dispatched.map (·.call) = [1] ∧
    w.verdict = some (.refused (.continuation .abandon)) ∧
    dispositionsOf w.journal = [abandonA, dispositionA] ∧
    restriction current w.memory machineA = some .abandon := by decide +kernel

/-- With the reach read from the calls still unresolved, nothing is in reach — a disposed call is
not unresolved — and the continuation the operator replaced is dispatched. -/
@[req "STA-24"] theorem replaced_continuation_dispatched_without_guard :
    let w := run reachStillUnresolved farDone.external init replacementEvents
    w.dispatched.map (·.call) = [3, 1] ∧
    unresolved reachStillUnresolved w.memory machineA = [3] := by decide +kernel

/-- **A disposition the test refuses, found on replay, means nothing.** The journal already holds
a disposition recorded against the sibling entry and naming this entry's reset. The record stays
in the journal and is not in the reading: the reset is still unresolved, nothing is restricted on
either entry, and the command is refused by the reset's barrier. -/
@[req "STA-24"] theorem replayed_invalid_disposition_means_nothing :
    let w := run current farDone.external replayStart replayEvents
    dispositionsOf w.journal = [onAnotherResource] ∧
    dispositionsOf (inEffect current w.memory) = [] ∧
    unresolved current w.memory machineA = [1] ∧
    restriction current w.memory machineA = none ∧
    restriction current w.memory machineB = none ∧
    w.verdict = some (.refused (.barrier [1])) := by decide +kernel

/-- **Evidence about a disposed reset neither reopens it nor removes its disposition.** The reset is disposed naming
abandonment, and a vendor read then reports that it succeeded. The read is journaled; the call
was terminal already, the disposition still stands, and the command is still refused under it. -/
@[req "STA-24"] theorem evidence_after_disposition_changes_nothing :
    let w := run current farDone.external init evidenceAfterEvents
    w.dispatched.map (·.call) = [1] ∧
    w.verdict = some (.refused (.continuation .abandon)) ∧
    restriction current w.memory machineA = some .abandon ∧
    unresolved current w.memory machineA = [] := by decide +kernel

/-- **A reset with no rescue activation, refused.** Under a disposition naming a destructive
reinstall, a reset with no rescue activation dispatched since is not the reset into rescue. It is
refused by the disposition itself, which still stands. -/
@[req "STA-24"] theorem reset_without_rescue_refused :
    let w := run current farDone.external init strayResetEvents
    w.dispatched.map (·.call) = [1] ∧
    w.verdict = some (.refused (.continuation .reinstall)) ∧
    restriction current w.memory machineA = some .reinstall := by decide +kernel

/-- With any reset taken for the reinstall, it is dispatched and ends the restriction: it boots
the installed system and hands back the machine the operator chose to wipe. -/
@[req "STA-24"] theorem reset_without_rescue_admitted :
    let w := run anyResetReinstalls farDone.external init strayResetEvents
    w.dispatched.map (·.call) = [2, 1] ∧
    restriction anyResetReinstalls w.memory machineA = none := by decide +kernel

/-- **An activation whose newest read does not confirm it is not counted.** Chained runs use
per-segment far sides because `External.reports` is fixed within one run; each read journals only
its own report. The middle segment reports `unknown`, asserting no external event or negative
outcome. The activation remains terminal, but the reset is refused by the standing reinstall
disposition. A fresh activation confirmed admits the later reset and ends the restriction. -/
@[req "STA-24"] theorem spent_activation_not_counted :
    let activated := run current farDone.external init spentActivationStartEvents
    let refused := run current activationNotConfirmed.external activated spentActivationReadEvents
    let fresh := run current farDone.external refused freshActivationEvents
    refused.dispatched.map (·.call) = [10, 1] ∧
    refused.verdict = some (.refused (.continuation .reinstall)) ∧
    restriction current refused.memory machineA = some .reinstall ∧
    !unresolvedIn current (inEffect current refused.memory) machineA activateRequest.call = true ∧
    fresh.dispatched.map (·.call) = [18, 16, 10, 1] ∧
    (fresh.verdict matches some (.dispatched _)) ∧
    restriction current fresh.memory machineA = none := by decide +kernel

/-- With the newest-read guard off, the same chained trace dispatches the reset as the
continuation despite a newest activation read reporting `unknown`. Chained runs keep the changing
reports on reads alone, as in `spent_activation_not_counted`; they claim no external outcome. -/
@[req "STA-24"] theorem spent_activation_counted_without_guard :
    let activated := run staleActivationCounts farDone.external init spentActivationStartEvents
    let w := run staleActivationCounts activationNotConfirmed.external activated spentActivationReadEvents
    let fresh := run staleActivationCounts farDone.external w freshActivationEvents
    w.dispatched.map (·.call) = [2, 10, 1] ∧
    (w.verdict matches some (.dispatched _)) ∧
    restriction staleActivationCounts w.memory machineA = none ∧
    fresh.dispatched.map (·.call) = [2, 10, 1] := by decide +kernel

/-- **The preparation is admitted and does not end the restriction.** Under a disposition naming
a destructive reinstall the rescue activation is dispatched, the disposition still stands, and
the command after it is refused. -/
@[req "STA-24"] theorem preparation_keeps_restriction :
    let w := run current farDone.external init preparationEvents
    w.dispatched.map (·.call) = [10, 1] ∧
    w.verdict = some (.refused (.continuation .reinstall)) ∧
    restriction current w.memory machineA = some .reinstall := by decide +kernel

/-- With the restriction ended at the reinstall's first operation, the activation ends it. An
activation holds nothing on the box, so the command is dispatched before the reset and bars
it. -/
@[req "STA-24"] theorem preparation_lifts_restriction_without_guard :
    let w := run lapseFirstOperation farDone.external init preparationEvents
    w.dispatched.map (·.call) = [7, 10, 1] ∧
    restriction lapseFirstOperation w.memory machineA = none := by decide +kernel

/-- **A destructive reinstall does not refuse a key registration.** A disposition naming a
destructive reinstall stands over the machine. Its restriction does not refuse a key
registration, which the disposed reset barred, and it still stands over the journal with a
registration's intent appended. That is the whole of the claim. `STA-24` admits "a key
registration where one is owed", and the companion does not carry *owed*: the journal holds
nothing that says a registration is. So the trace requests none, and no trace of this module
dispatches one under a disposition. -/
@[req "STA-24"] theorem reinstall_does_not_refuse_key_registration :
    let w := run current farDone.external init reinstallStandingEvents
    restricted current w.memory machineA .registerKey = none ∧
    restriction current
      (.intent (intentOf registerRequest machineA approvalRegister) :: w.memory) machineA =
      some .reinstall := by decide +kernel

/-- **A rescue activation confirmed before the disposition does not count.** The activation is
confirmed and no reset follows it; a command is then left unresolved and disposed naming a
destructive reinstall. That activation is older than the disposition, so a reset is not the reset
into rescue: it is refused by the disposition, and a new rescue activation is dispatched. -/
@[req "STA-24"] theorem activation_before_disposition_not_counted :
    let w := run current farDone.external init earlierActivationEvents
    w.dispatched.map (·.call) = [16, 7, 10] ∧
    (run current farDone.external init (earlierActivationEvents.take 5)).verdict =
      some (.refused (.continuation .reinstall)) := by decide +kernel

/-- **Nor does one dispatched under a disposition since replaced.** The rescue activation is
dispatched and confirmed under a disposition naming a destructive reinstall. The operator
replaces that disposition with one naming abandonment, and that one with a destructive reinstall
again. The activation is older than the disposition now standing: a reset is refused by it, and a
new rescue activation is dispatched. -/
@[req "STA-24"] theorem activation_under_replaced_disposition_not_counted :
    let w := run current farDone.external init replacedActivationEvents
    w.dispatched.map (·.call) = [16, 10, 1] ∧
    (run current farDone.external init (replacedActivationEvents.take 7)).verdict =
      some (.refused (.continuation .reinstall)) := by decide +kernel

/-- **The return to rescue, whole.** A disposed reset and a disposition naming a destructive
reinstall. A reset with no rescue activation dispatched is refused by the disposition. The rescue
activation is dispatched and the disposition still stands: a command is refused by it. A reset
requested before the activation is confirmed is refused too, by the activation's own barrier and
not by the disposition. Once the activation is confirmed the reset into rescue is dispatched: the
restriction is gone, and that reset's barrier refuses the command after it. -/
@[req "STA-24"] theorem return_to_rescue_trace :
    let w := run current farDone.external init returnToRescueEvents
    let afterCommand := run current farDone.external init (returnToRescueEvents.take 5)
    w.dispatched.map (·.call) = [19, 10, 1] ∧
    (run current farDone.external init (returnToRescueEvents.take 3)).verdict =
      some (.refused (.continuation .reinstall)) ∧
    afterCommand.verdict = some (.refused (.continuation .reinstall)) ∧
    restriction current afterCommand.memory machineA = some .reinstall ∧
    (run current farDone.external init (returnToRescueEvents.take 6)).verdict =
      some (.refused (.barrier [10])) ∧
    w.verdict = some (.refused (.barrier [19])) ∧
    restriction current w.memory machineA = none ∧
    unresolved current w.memory machineA = [19] := by decide +kernel

/-- **The reset waits for the other command and not for the disposed one.** Two commands are
unresolved in rescue; the disposition names the first and a destructive reinstall. The rescue
activation is refused while the second still runs, by the second's barrier alone: the first is
disposed and bars nothing. Once the second's job record is collected the activation is
dispatched and confirmed, and the reset into rescue goes out with no record of the first — which
`STA-20b` calls the uncertainty the operator accepted. -/
@[req "STA-20b"] theorem reset_waits_for_other_commands :
    let w := run current farDone.external init rescueCommandEvents
    w.dispatched.map (·.call) = [2, 16, 12, 7] ∧
    (run current farDone.external init (rescueCommandEvents.take 4)).verdict =
      some (.refused (.barrier [12])) ∧
    restriction current w.memory machineA = none ∧
    unresolved current w.memory machineA = [2] := by decide +kernel

/-- **The ceremony, whole** — `STG-4`'s four predicates in order, each mutation "confirmed by
observable state, never by its own response and never by a clock". The barrier is not safe by
refusing everything: all six effects go out, each once its predecessor is confirmed, the install
follows the reset into rescue and the reset into the installed system follows the install's own
job record — which is `STA-20b` waiting "for all tracked commands to end" before a planned reset.
Only the last call is still open when the trace ends. -/
@[req "STG-4"] theorem ceremony_trace :
    let w := run current farDone.external init ceremonyEvents
    w.dispatched.map (·.call) = [12, 11, 7, 1, 10, 9] ∧
    unresolved current w.memory machineA = [12] ∧ (intentsOf w.memory).length = 6 := by
  decide +kernel

/-- A session's destroy under a standing abandonment, with no other barrier. -/
def sessionDestroyEvents : List Event :=
  [.request resetRequest1 approvalReset true, .dispose abandonA true,
   .request destroyRequest approvalDestroy true]

def sessionDestroyAllowed : Params := { current with sessionDestroyRefused := false }

@[req "STA-24"] theorem session_destroy_under_abandonment_refused :
    let w := run current farDone.external init sessionDestroyEvents
    w.dispatched.map (·.call) = [1] ∧
    w.verdict = some (.refused (.continuation .abandon)) ∧
    restriction current w.memory machineA = some .abandon := by decide +kernel

@[req "STA-24"] theorem session_destroy_lifts_abandonment_without_guard :
    let w := run sessionDestroyAllowed farDone.external init sessionDestroyEvents
    w.dispatched.map (·.call) = [8, 1] ∧
    restriction sessionDestroyAllowed w.memory machineA = none := by decide +kernel

/-- Disposing only one of two commands cannot free the flow's destroy intent. -/
def partialAbandonEvents : List Event :=
  [.request execRequest approvalExec true, .request execRequest2 approvalExec true,
   .dispose { reinstallAfterCommand with continuation := .abandon } true]

@[req "STA-24"] theorem undisposed_command_bars_flow_destroy :
    let w := run current farDone.external init partialAbandonEvents
    blocking current w.memory (intentOf destroyRequest machineA approvalDestroy) = [12] := by
  decide +kernel

/-- Replacing a disposition with a narrower continuing choice does not unsettle omitted calls. -/
def omittedCallEvents : List Event :=
  [.request execRequest approvalExec true, .request execRequest2 approvalExec true,
   .dispose { reinstallAfterCommand with calls := [7, 12] } true,
   .dispose { reinstallAfterCommand with calls := [12], continuation := .asIfNotDone } true,
   .dispose { reinstallAfterCommand with continuation := .asIfDone } true]

@[req "STA-24"] theorem omitted_call_stays_settled :
    let w := run current farDone.external init omittedCallEvents
    unresolved current w.memory machineA = [] ∧
    (dispositionsOf w.memory).length = 2 ∧
    restriction current w.memory machineA = some .asIfNotDone ∧
    restricted current w.memory machineA .exec = none := by decide +kernel

/-- A predecessor's prerequisites are not the successor installation's. -/
def predecessorOfferEvents : List Event :=
  [.resetPrereqs entryA 101 true, .request reinstallRequest approvalReinstallB true, .replay]

/-- A second read in one installation reports keys different from its first durable read. -/
def changedKeysOfferEvents : List Event :=
  [.resetPrereqs entryA 101 true, .resetPrereqs entryA 102 true, .replay]

def oldResetOffer : Params := { current with resetOfferCurrentInstallation := false }

@[req "STA-20b"] theorem predecessor_reset_offer_refused :
    let w := run current farDone.external init predecessorOfferEvents
    offersReset current w.memory entryA = false := by decide +kernel

@[req "STA-20b"] theorem predecessor_reset_offer_admitted_without_guard :
    let w := run oldResetOffer farDone.external init predecessorOfferEvents
    offersReset oldResetOffer w.memory entryA = true := by decide +kernel

@[req "STA-20b"] theorem changed_keys_reset_offer_refused :
    let w := run current farDone.external init changedKeysOfferEvents
    offersReset current w.memory entryA = false := by decide +kernel

@[req "STA-20b"] theorem changed_keys_reset_offer_admitted_without_guard :
    let w := run oldResetOffer farDone.external init changedKeysOfferEvents
    offersReset oldResetOffer w.memory entryA = true := by decide +kernel

/-- Fresh matching prerequisites after dispatch restore the offer; another entry is independent. -/
def currentOfferEvents : List Event := predecessorOfferEvents ++
  [.resetPrereqs entryA 102 true, .resetPrereqs entryA 102 true,
   .resetPrereqs entryB 103 true, .replay]

@[req "STA-20b"] theorem current_installation_reset_offered :
    let w := run current farDone.external init currentOfferEvents
    installationOf current w.memory entryA = 1 ∧
    offersReset current w.memory entryA = true ∧ offersReset current w.memory entryB = true := by
  decide +kernel

/-- The dedicated reinstall boundary is its rescue reset, not its choice or activation. -/
def dedicatedOfferEvents : List Event := [.resetPrereqs entryA 101 true] ++
  spentActivationStartEvents ++ [.request resetRequest2 approvalReset true]

@[req "STA-20b"] theorem dedicated_reset_retires_prerequisites :
    let before := run current farDone.external init (dedicatedOfferEvents.dropLast)
    let after := run current farDone.external init dedicatedOfferEvents
    installationOf current before.memory entryA = 0 ∧ offersReset current before.memory entryA = true ∧
    installationOf current after.memory entryA = 1 ∧ offersReset current after.memory entryA = false := by
  decide +kernel

/-- A delivered dedicated machine, with no unresolved call or disposition, chooses a
destructive reinstall. Its approval is bound to reset 1; activation and its read follow. -/
def approvedReinstallEvents : List Event :=
  [.resetPrereqs entryA 101 true,
   .approveReinstall entryA resetRequest1.call approvalReset true,
   .request activateRequest approvalActivate true,
   .observe .adapterRead machineA .activate true,
   .request resetRequest1 approvalReset true,
   .resetPrereqs entryA 102 true, .replay]

def uncarriedApproval : Params := { current with approvedReinstallBoundary := false }

/-- A key registration remains unresolved after the approved rescue activation. A continuing
disposition settles that call without withdrawing the separately journaled approval. -/
def approvedContinuingDispositionEvents (c : Continuation) : List Event :=
  approvedReinstallEvents.take 4 ++
  [.request registerRequest approvalRegister true,
   .dispose { resource := machineA, calls := [9], continuation := c } true,
   .request resetRequest1 approvalReset true,
   .resetPrereqs entryA 102 true, .replay]

@[req "STG-20"] theorem approved_reinstall_after_done_disposition :
    let events := approvedContinuingDispositionEvents .asIfDone
    let reset := run current farDone.external init (events.take 7)
    let fresh := run current farDone.external init events
    reset.dispatched.map (·.call) = [1, 9, 10] ∧
    installationOf current reset.memory entryA = 1 ∧
    offersReset current reset.memory entryA = false ∧
    offersReset current fresh.memory entryA = true := by decide +kernel

@[req "STG-20"] theorem approved_reinstall_after_not_done_disposition :
    let events := approvedContinuingDispositionEvents .asIfNotDone
    let reset := run current farDone.external init (events.take 7)
    let fresh := run current farDone.external init events
    reset.dispatched.map (·.call) = [1, 9, 10] ∧
    installationOf current reset.memory entryA = 1 ∧
    offersReset current reset.memory entryA = false ∧
    offersReset current fresh.memory entryA = true := by decide +kernel

/-- A destructive disposition still requires a new activation after its own record. The
approved reset also dispatches that disposition, but advances the installation only once. -/
def approvedReinstallDispositionEvents : List Event :=
  approvedReinstallEvents.take 4 ++
  [.request registerRequest approvalRegister true,
   .dispose { resource := machineA, calls := [9], continuation := .reinstall } true,
   .request resetRequest2 approvalReset true,
   .request activateRequest2 approvalActivate true,
   .observe .adapterRead machineA .activate true,
   .request resetRequest1 approvalReset true,
   .observe .adapterRead machineA .reset true,
   .request resetRequest4 approvalReset true, .replay]

@[req "STG-20"] theorem approved_reinstall_keeps_disposition_activation_boundary :
    let refused := run current farDone.external init (approvedReinstallDispositionEvents.take 7)
    let activated := run current farDone.external init (approvedReinstallDispositionEvents.take 8)
    let reset := run current farDone.external init (approvedReinstallDispositionEvents.take 10)
    let later := run current farDone.external init approvedReinstallDispositionEvents
    refused.verdict = some (.refused (.continuation .reinstall)) ∧
    installationOf current refused.memory entryA = 0 ∧
    restriction current activated.memory machineA = some .reinstall ∧
    admit current activated.memory resetRequest1 approvalReset = .refused (.barrier [16]) ∧
    reset.dispatched.map (·.call) = [1, 16, 9, 10] ∧
    installationOf current reset.memory entryA = 1 ∧
    offersReset current reset.memory entryA = false ∧
    restriction current reset.memory machineA = none ∧
    later.dispatched.map (·.call) = [11, 1, 16, 9, 10] ∧
    installationOf current later.memory entryA = 1 := by decide +kernel

/-- The approval and activation leave the predecessor current; dispatch alone retires it.
Disjoint successor keys establish a new pin and restore the offer, including on replay. -/
@[req "STG-20"] theorem approved_reinstall_boundary_refused :
    let chosen := run current farDone.external init (approvedReinstallEvents.take 2)
    let activated := run current farDone.external init (approvedReinstallEvents.take 3)
    let reset := run current farDone.external init (approvedReinstallEvents.take 5)
    let fresh := run current farDone.external init approvedReinstallEvents
    unresolved current chosen.memory machineA = [] ∧ dispositionsOf chosen.memory = [] ∧
    installationOf current chosen.memory entryA = 0 ∧
    installationOf current activated.memory entryA = 0 ∧
    installationOf current reset.memory entryA = 1 ∧
    offersReset current reset.memory entryA = false ∧
    offersReset current fresh.memory entryA = true := by decide +kernel

@[req "STG-20"] theorem approved_reinstall_boundary_admitted_without_guard :
    let reset := run uncarriedApproval farDone.external init (approvedReinstallEvents.take 5)
    let fresh := run uncarriedApproval farDone.external init approvedReinstallEvents
    installationOf uncarriedApproval reset.memory entryA = 0 ∧
    offersReset uncarriedApproval reset.memory entryA = true ∧
    offersReset uncarriedApproval fresh.memory entryA = false := by decide +kernel

def approvedWithoutActivationEvents : List Event :=
  [.approveReinstall entryA resetRequest1.call approvalReset true,
   .request resetRequest1 approvalReset true]

/-- Restated 2026-10-17: the approval-bound reset is refused without a confirming activation
since approval; formerly it dispatched without opening an installation. -/
@[req "STG-20"] theorem approved_reset_without_activation_opens_nothing :
    let w := run current farDone.external init approvedWithoutActivationEvents
    w.dispatched = [] ∧ w.verdict = some (.refused .approvalActivation) ∧
    installationOf current w.memory entryA = 0 := by decide +kernel

def secondRescueResetEvents : List Event := approvedReinstallEvents.take 5 ++
  [.observe .adapterRead machineA .reset true,
   .request activateRequest2 approvalActivate true,
   .observe .adapterRead machineA .activate true,
   .request resetRequest2 approvalReset true]

@[req "STG-20"] theorem second_rescue_reset_opens_nothing_more :
    let w := run current farDone.external init secondRescueResetEvents
    w.dispatched.map (·.call) = [2, 16, 1, 10] ∧
    installationOf current w.memory entryA = 1 := by decide +kernel

/-- An approval never dispatched cannot be consumed by another reset, even into rescue. -/
def unrelatedRescueResetEvents : List Event := approvedReinstallEvents.take 4 ++
  [.request resetRequest2 approvalReset true]

@[req "STG-20"] theorem unrelated_rescue_reset_opens_nothing :
    let w := run current farDone.external init unrelatedRescueResetEvents
    w.dispatched.map (·.call) = [2, 10] ∧ installationOf current w.memory entryA = 0 := by
  decide +kernel

/-- The newest activation read is not confirmation, even after an older confirming read.
The approval-bound reset is refused. -/
def approvedSpentReadEvents : List Event :=
  [.observe .adapterRead machineA .activate true,
   .request resetRequest1 approvalReset true]

/-- Restated 2026-10-17: the non-confirming newest read refuses the approval-bound reset;
formerly it dispatched without opening an installation. -/
@[req "STG-20"] theorem approved_spent_activation_opens_nothing :
    let start := run current farDone.external init (approvedReinstallEvents.take 4)
    let w := run current activationNotConfirmed.external start approvedSpentReadEvents
    w.dispatched.map (·.call) = [10] ∧ w.verdict = some (.refused .approvalActivation) ∧
    installationOf current w.memory entryA = 0 := by decide +kernel

/-- A kept-root trace: the first successor prerequisite read repeats a predecessor's keys. -/
def keptKeysOfferEvents : List Event := predecessorOfferEvents ++ [.resetPrereqs entryA 101 true]

def reusedOfferKeys : Params := { current with resetOfferFreshKeys := false }

@[req "STA-20b"] theorem kept_keys_reset_offer_refused :
    let w := run current farDone.external init keptKeysOfferEvents
    installationOf current w.memory entryA = 1 ∧
    offersReset current w.memory entryA = false := by decide +kernel

@[req "STA-20b"] theorem kept_keys_reset_offer_admitted_without_guard :
    let w := run reusedOfferKeys farDone.external init keptKeysOfferEvents
    offersReset reusedOfferKeys w.memory entryA = true := by decide +kernel

/-- A stale first durable read remains the offer's anchor even after a different later read.
A key seen in an earlier prerequisite read, not merely its first, also withholds the offer. -/
def earlierKeysOfferEvents : List Event :=
  [.resetPrereqs entryA 101 true, .resetPrereqs entryA 102 true,
   .request reinstallRequest approvalReinstallB true,
   .resetPrereqs entryA 102 true, .resetPrereqs entryA 103 true, .replay]

@[req "STA-20b"] theorem stale_first_prerequisite_keeps_offer_withheld :
    let first := run current farDone.external init (earlierKeysOfferEvents.take 4)
    let later := run current farDone.external init earlierKeysOfferEvents
    offersReset current first.memory entryA = false ∧
    prerequisiteKeys current later.memory entryA = [103, 102] ∧
    offersReset current later.memory entryA = false := by decide +kernel

def uncheckedApprovalReset : Params := { current with approvalResetRequiresRescue := false }

/-- The guard's trace includes an activation confirmed before approval: it cannot qualify. -/
def approvalResetGuardEvents : List Event :=
  [.request activateRequest approvalActivate true,
   .observe .adapterRead machineA .activate true] ++ approvedWithoutActivationEvents

@[req "STG-20"] theorem approval_reset_requires_rescue_refused :
    let w := run current farDone.external init approvalResetGuardEvents
    w.dispatched.map (·.call) = [10] ∧ w.verdict = some (.refused .approvalActivation) ∧
    installationOf current w.memory entryA = 0 := by decide +kernel

@[req "STG-20"] theorem approval_reset_requires_rescue_admitted_without_guard :
    let w := run uncheckedApprovalReset farDone.external init approvalResetGuardEvents
    w.dispatched.map (·.call) = [1, 10] ∧
    installationOf uncheckedApprovalReset w.memory entryA = 0 := by decide +kernel

/-- Replacing the reinstall disposition preserves the separate approval until its own act. -/
def replacedReinstallApprovalEvents : List Event := approvedReinstallDispositionEvents.take 6 ++
  [.dispose { resource := machineA, calls := [9], continuation := .asIfDone } true]

def keptReinstallApprovalEvents : List Event := replacedReinstallApprovalEvents ++
  [.request resetRequest1 approvalReset true]

def withdrawnReinstallApprovalEvents : List Event := replacedReinstallApprovalEvents ++
  [.withdrawReinstall entryA resetRequest1.call approvalReset true, .replay,
   .request resetRequest1 approvalReset true]

@[req "STG-20"] theorem replaced_reinstall_keeps_approval :
    let before := run current farDone.external init replacedReinstallApprovalEvents
    let w := run current farDone.external init keptReinstallApprovalEvents
    approvalBound before.memory (intentOf resetRequest1 machineA approvalReset) = true ∧
    approvalWithdrawn current before.memory (intentOf resetRequest1 machineA approvalReset) = false ∧
    w.dispatched.map (·.call) = [1, 9, 10] ∧
    installationOf current w.memory entryA = 1 ∧ offersReset current w.memory entryA = false := by
  decide +kernel

@[req "STG-20"] theorem replaced_reinstall_withdraws_approval :
    let w := run current farDone.external init withdrawnReinstallApprovalEvents
    w.dispatched.map (·.call) = [9, 10] ∧
    w.verdict = some (.refused (.withdrawnApproval machineA 1 approvalReset)) ∧
    installationOf current w.memory entryA = 0 ∧ offersReset current w.memory entryA = true := by
  decide +kernel

/-- Approval-only change of mind, with no disposition. -/
def approvalOnlyWithdrawalEvents : List Event := approvedReinstallEvents.take 4 ++
  [.withdrawReinstall entryA resetRequest1.call approvalReset true,
   .request resetRequest1 approvalReset true]

def ignoredWithdrawal : Params := { current with reinstallWithdrawalEffective := false }

@[req "STG-20"] theorem withdrawn_approval_reset_refused :
    let w := run current farDone.external init approvalOnlyWithdrawalEvents
    w.dispatched.map (·.call) = [10] ∧
    w.verdict = some (.refused (.withdrawnApproval machineA 1 approvalReset)) ∧
    installationOf current w.memory entryA = 0 := by decide +kernel

@[req "STG-20"] theorem withdrawn_approval_reset_admitted_without_guard :
    let w := run ignoredWithdrawal farDone.external init approvalOnlyWithdrawalEvents
    Rec.reinstallWithdrawal entryA 1 approvalReset ∈ w.journal ∧
    w.dispatched.map (·.call) = [1, 10] ∧
    installationOf ignoredWithdrawal w.memory entryA = 1 := by decide +kernel

/-- After dispatch a withdrawal is refused without changing the journal or any projection. -/
def withdrawalAfterDispatchEvents : List Event := approvedReinstallEvents.take 5 ++
  [.withdrawReinstall entryA resetRequest1.call approvalReset true]

@[req "STG-20"] theorem withdrawal_after_dispatch_refused :
    let before := run current farDone.external init (approvedReinstallEvents.take 5)
    let w := run current farDone.external init withdrawalAfterDispatchEvents
    acceptsWithdrawal before.memory entryA 1 approvalReset = false ∧
    w.journal = before.journal ∧ w.memory = before.memory ∧ w.dispatched = before.dispatched ∧
    installationOf current w.memory entryA = 1 := by decide +kernel

/-- A disposition's confirmed activation cannot dispatch a withdrawn approval's reset.
The disposition still opens the installation through its own, different reset call. -/
def withdrawnUnderDispositionEvents : List Event := approvedReinstallDispositionEvents.take 9 ++
  [.withdrawReinstall entryA resetRequest1.call approvalReset true,
   .request resetRequest1 approvalReset true, .request resetRequest4 approvalReset true]

@[req "STG-20"] theorem withdrawn_reset_under_reinstall_refused :
    let refused := run current farDone.external init (withdrawnUnderDispositionEvents.take 11)
    let w := run current farDone.external init withdrawnUnderDispositionEvents
    refused.verdict = some (.refused (.withdrawnApproval machineA 1 approvalReset)) ∧
    installationOf current refused.memory entryA = 0 ∧
    restriction current refused.memory machineA = some .reinstall ∧
    w.dispatched.map (·.call) = [11, 16, 9, 10] ∧
    installationOf current w.memory entryA = 1 := by decide +kernel

/-- Withdrawal is named even when no activation since approval would confirm either. -/
def withdrawalWithoutActivationEvents : List Event :=
  [.approveReinstall entryA 1 approvalReset true,
   .withdrawReinstall entryA 1 approvalReset true, .request resetRequest1 approvalReset true]

@[req "STG-20"] theorem withdrawal_before_activation_named :
    let w := run current farDone.external init withdrawalWithoutActivationEvents
    w.verdict = some (.refused (.withdrawnApproval machineA 1 approvalReset)) ∧
    w.dispatched = [] := by decide +kernel

/-- An unresolved activation is shown before the withdrawal of the reset's approval. -/
def withdrawalWithUnresolvedActivationEvents : List Event :=
  [.approveReinstall entryA 1 approvalReset true,
   .request activateRequest approvalActivate true,
   .withdrawReinstall entryA 1 approvalReset true, .request resetRequest1 approvalReset true]

@[req "STA-24"] theorem unresolved_activation_before_withdrawal_shown :
    let w := run current farDone.external init withdrawalWithUnresolvedActivationEvents
    w.verdict = some (.refused (.barrier [10])) ∧
    w.dispatched.map (·.call) = [10] := by decide +kernel

/-- Not issuing the reset is no withdrawal; replay retains the approval and rescue boundary. -/
def replayApprovalEvents : List Event := approvedReinstallEvents.take 4 ++
  [.replay, .request resetRequest1 approvalReset true]

@[req "STG-20"] theorem undispatched_approval_survives_replay :
    let w := run current farDone.external init replayApprovalEvents
    w.dispatched.map (·.call) = [1, 10] ∧ installationOf current w.memory entryA = 1 := by
  decide +kernel

/-- A new approval after withdrawal needs its own newer activation, then opens the boundary. -/
def reapprovalEvents : List Event := approvedReinstallEvents.take 4 ++
  [.withdrawReinstall entryA 1 approvalReset true,
   .approveReinstall entryA 1 approvalReset true,
   .request activateRequest2 approvalActivate true, .observe .adapterRead machineA .activate true,
   .request resetRequest1 approvalReset true]

@[req "STG-20"] theorem reapproval_requires_new_activation :
    let before := run current farDone.external init (reapprovalEvents.take 6)
    let w := run current farDone.external init reapprovalEvents
    admit current before.memory resetRequest1 approvalReset = .refused .approvalActivation ∧
    w.dispatched.map (·.call) = [1, 16, 10] ∧ installationOf current w.memory entryA = 1 := by
  decide +kernel

/-- A failed withdrawal append leaves approval standing; another entry's or another approval's
withdrawal does not withdraw this one. -/
def withdrawalIdentityEvents : List Event := approvedReinstallEvents.take 4 ++
  [.withdrawReinstall entryB 1 approvalReset true,
   .withdrawReinstall entryA 2 approvalReset true,
   .withdrawReinstall entryA 1 approvalReset false, .replay,
   .request resetRequest1 approvalReset true]

@[req "STG-20"] theorem withdrawal_identity_and_failed_append :
    let w := run current farDone.external init withdrawalIdentityEvents
    w.dispatched.map (·.call) = [1, 10] ∧ installationOf current w.memory entryA = 1 := by
  decide +kernel

def repeatedWithdrawalEvents : List Event := withdrawalWithoutActivationEvents.take 2 ++
  [.withdrawReinstall entryA 1 approvalReset true]

@[req "STG-20"] theorem repeated_withdrawal_records :
    let w := run current farDone.external init repeatedWithdrawalEvents
    (w.journal.filter fun rec => rec == .reinstallWithdrawal entryA 1 approvalReset).length = 2 := by
  decide +kernel

def failedPrerequisiteEvents : List Event :=
  [.resetPrereqs entryA 101 true, .resetPrereqs entryA 102 false, .replay,
   .resetPrereqs entryA 101 true, .resetPrereqs entryA 101 false, .replay,
   .resetPrereqs entryA 101 true]

def failedPrerequisiteKeepsOffer : Params := { current with failedPrerequisiteWithdraws := false }

/-- Changed and unchanged failed reads both withhold the offer; durable command records
carry withholding on replay, and only a later durable prerequisite result restores it. -/
@[req "STA-20b"] theorem failed_prerequisite_withdrawal_refused :
    let first := run current farDone.external init (failedPrerequisiteEvents.take 1)
    let failed := run current farDone.external init (failedPrerequisiteEvents.take 2)
    let replayed := run current farDone.external init (failedPrerequisiteEvents.take 3)
    let restored := run current farDone.external init (failedPrerequisiteEvents.take 4)
    let sameFailed := run current farDone.external init (failedPrerequisiteEvents.take 6)
    let final := run current farDone.external init failedPrerequisiteEvents
    offersReset current first.memory entryA = true ∧
    offersReset current failed.memory entryA = false ∧
    offersReset current failed.journal entryA = false ∧ failed.memory = failed.journal ∧
    offersReset current replayed.memory entryA = false ∧
    offersReset current restored.memory entryA = true ∧
    offersReset current sameFailed.memory entryA = false ∧
    offersReset current final.memory entryA = true := by decide +kernel

@[req "STA-20b"] theorem failed_prerequisite_withdrawal_admitted_without_guard :
    let failed := run failedPrerequisiteKeepsOffer farDone.external init
      (failedPrerequisiteEvents.take 2)
    let replayed := run failedPrerequisiteKeepsOffer farDone.external init
      (failedPrerequisiteEvents.take 3)
    offersReset failedPrerequisiteKeepsOffer failed.memory entryA = true ∧
    failed.memory = failed.journal ∧
    offersReset failedPrerequisiteKeepsOffer replayed.memory entryA = true := by decide +kernel

def failedCollectionIsolationEvents : List Event :=
  [.resetPrereqs entryA 101 true, .resetPrereqs entryB 103 true,
   .resetPrereqs entryA 101 false,
   .request reinstallRequest approvalReinstallB true,
   .resetPrereqs entryA 102 true, .replay]

@[req "STA-20b"] theorem failed_collection_per_entry_and_installation :
    let failed := run current farDone.external init (failedCollectionIsolationEvents.take 3)
    let fresh := run current farDone.external init failedCollectionIsolationEvents
    offersReset current failed.memory entryA = false ∧
    offersReset current failed.memory entryB = true ∧
    installationOf current fresh.memory entryA = 1 ∧
    offersReset current fresh.memory entryA = true ∧
    offersReset current fresh.memory entryB = true := by decide +kernel

/-! ## The bound -/

/-- The bound (`CONTEXT.md`): every trace of at most this many events over `alphabet`, from
`init`, filtered to distinct request call ids. Stated once, here, for `bounded` and for the witness file; beyond it is the theorems'
statements, not the file's. -/
@[req "STA-24"] def bound : Nat := 3

/-- The events the bounded enumeration draws from: the destructive call and the same action under
a fresh call id, box-plane work on the same machine, the vendor read that settles the reset, the
operator's disposition, a replay, and a rescue activation, which an unresolved command may stand
beside. -/
def alphabet : List Event :=
  [.request resetRequest1 approvalReset true, .request resetRequest2 approvalReset true,
   .request execRequest approvalExec true, .observe .adapterRead machineA .reset true,
   .dispose dispositionA true, .replay, .request activateRequest approvalActivate true]

/-- Every trace of exactly `n` events over `alphabet`. -/
def tracesOf : Nat → List (List Event)
  | 0 => [[]]
  | n + 1 => (tracesOf n).flatMap fun es => alphabet.map (es ++ [·])

/-- Fresh request identities, including requests refused before dispatch. -/
def freshRequests (es : List Event) : Bool :=
  let calls := es.filterMap fun e => match e with | .request rq _ _ => some rq.call | _ => none
  calls.eraseDups.length == calls.length

/-- Every trace of at most `n` events over `alphabet` with distinct request call ids,
shortest first. Both the decided property and the emitter read this filter. -/
@[req "STA-24"] def tracesUpTo (n : Nat) : List (List Event) :=
  ((List.range (n + 1)).flatMap tracesOf).filter freshRequests

/-- What may be unresolved together on one resource. `STA-24`: "On one machine at most one
cloud-plane call is unresolved at a time, it is older than every box-plane command unresolved
beside it, and a call that changes what the machine is running is unresolved alone". Stated
without `bars`, so that it decides what `bars` reads rather than agreeing with it. Box-plane
commands are `STA-20`'s tracked jobs, plural by design — "waits for all tracked commands to end"
— and an unresolved activation or key registration "blocks nothing on the box", so a command may
be unresolved beside one. Until 2026-10-13 this said that a second unresolved call needs every
unresolved call to be box-plane, which an activation beside a command refutes. -/
@[req "STA-24"] def unresolvedTogether (p : Params) (j : Journal) : Bool :=
  (resourcesOf j).all fun r =>
    let open_ := openIntents p j r
    (open_.dropLast.all fun i => !cloudPlane i.kind) &&
    (decide (open_.length ≤ 1) || open_.all fun i => !changesRunning i.kind)

/-- What may be unresolved together, decided within the bound, with distinct request call ids
checked independently of the filter. Narrowed 2026-10-16 to reachable request identities: the
enumeration the witness file carries is one the companion itself closed over. -/
@[req "STA-24"] theorem bounded :
    (tracesUpTo bound).all (fun es =>
      freshRequests es && unresolvedTogether current (run current farDone.external init es).memory) = true := by
  decide +kernel

end TauWeb.Dispatch
