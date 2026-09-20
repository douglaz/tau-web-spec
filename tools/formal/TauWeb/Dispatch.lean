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

**In memory and in the journal.** `World` carries both, because `STA-3` — "A canonical event
MUST be durably appended **before** it is applied to in-memory state. If the append fails, the
transition does not occur" — is exactly the statement that they never diverge. Dispatch reads
the running worker's memory (`STA-2`: in-memory state "is authoritative only while a worker is
running"), and `replay` throws it away and rebuilds it from the journal.

`Params` lists the parameters this module's decisions turn on; each is one field, so removing
one is a one-token change, and each has its refused-and-admitted pair.

What the module omits: the snapshot and the compaction of `STA-2`, since a snapshot is the
journal's replay and adds no case here; the lock `STA-7` acquires and the single writer `STA-1`
is, taken as given rather than modelled, so that nothing here is a claim about concurrency
(ADR-0032, "Evidence"); the half of `STA-7`'s classification that cancels — an intent is built
here only where an approval was checked, so "an intent with no journaled approval decision was
never dispatched" (`STA-4`) has no counterpart, and what is carried is that replay reads back the
barrier it had; the untyped call, whose resource is the scope (`SEC-12`, `STA-24`) and whose rules
are its own — nothing under a scope counts as a read, and only the operator's disposition clears
it — since no witness of this module's inventory row exercises one; the spend cap an unresolved
inference intent is shown against (`ARC-31a`), a number and not a gate; the screens `ARC-22`
requires, which state what the journal already holds. Robot's predicates have no negative
transition (`STG-4`: "None of these has a negative form"), so there is no observation meaning
*it did not happen*: that reading arrives only as a disposition.

ponytail: `openIntents` rescans the journal for every intent it reads, which is quadratic in the
trace; the bound is three events, and an index from call id to terminal record arrives when a
longer enumeration needs one. -/

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

/-- What a call does. The first five are cloud-plane typed operations (`STG-4`); `exec` is
box-plane work (`ARC-8`); `read` is what `STA-24` keeps permitted — "the adapter's status
queries, the pinned SSH attempt that is `STG-4`'s third predicate, the collection of job
records"; `inference` is `ARC-31a`'s own off-machine call. -/
inductive Kind
  | create
  | reset
  | destroy
  | activate
  | registerKey
  | exec
  | read
  | inference
  deriving DecidableEq, Repr

/-- The two planes of ADR-0002. No wildcard: a kind added without a plane does not build. -/
def cloudPlane : Kind → Bool
  | .create | .reset | .destroy | .activate | .registerKey => true
  | .exec | .read | .inference => false

/-- `STA-24`'s one exception for the box plane: "a cloud-plane operation that **changes what the
machine is running** — a reset, a reinstall, a destroy — stops box-plane dispatch to that machine
from its intent until its confirmation or disposition". A destructive reinstall (`STG-20`) is a
reset of an installed system and is that case. -/
@[req "STA-24"] def changesRunning : Kind → Bool
  | .reset | .destroy => true
  | .create | .activate | .registerKey | .exec | .read | .inference => false

/-- A read "has no effect": it is permitted whatever the barrier says, and it never becomes an
unresolved call of its own. Everything else is side-effecting and carries `SEC-12`'s record. -/
@[req "SEC-12"] def sideEffecting : Kind → Bool
  | .read => false
  | .create | .reset | .destroy | .activate | .registerKey | .exec | .inference => true

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

/-- The operator's disposition (`STA-24`): "a record of its own kind naming the outstanding
calls, the one continuation it permits — a destructive reinstall (`STG-20`), abandonment
(`ARC-21`), continuing as if done, continuing as if not done — and the uncertainty accepted". -/
structure Disposition where
  resource : Resource
  calls : List CallId
  continuation : Kind
  deriving DecidableEq, Repr

/-- One journal record. `STA-2`: canonical state is "an **append-only event journal** with
replayable transitions". An association is the harness's own mapping of what a model may name to
the approved entry; the reset prerequisites are `ready_to_reset`'s (`ARC-43`) installed pins and
reset intent, which `STA-20b` requires durable before a planned reset. -/
inductive Rec
  | intent (i : Intent)
  | observation (o : Observation)
  | disposition (d : Disposition)
  | association (t : Target) (e : Entry)
  | resetPrereqs (e : Entry)
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
  /-- `STA-24`: a disposition "permits only the continuation it names, and a new unresolved call
  stops that continuation again". Its pair is `disposition_one_continuation_refused` /
  `_admitted`. -/
  dispositionBindsContinuation : Bool
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
resource and operation whose standing confirms it, or a disposition naming the call — `STA-24`:
"**A disposition is a terminal record of its own kind**: it ends the call's unresolved state with
the outcome recorded as unknown, so the barrier stays one derivation — an intent with no terminal
record — and a disposed call is not an open one." -/
@[req "STA-8"] def settles (p : Params) (i : Intent) : Rec → Bool
  | .observation o =>
    admissible o && o.resource == i.resource && o.kind == i.kind && confirms p o.standing
  | .disposition d => d.calls.contains i.call
  | .intent _ => false
  | .association _ _ => false
  | .resetPrereqs _ => false

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

/-- `STA-8`'s unresolved calls naming a resource, as their intents and newest first. Derived —
"The barrier is a fact of the journal — an intent with no terminal record" (`STA-24`) — so it
survives replay and session succession "without an event of its own". A read is not among them:
it has no effect to be unresolved about. -/
@[req "STA-8"] def openIntents (p : Params) (j : Journal) (r : Resource) : List Intent :=
  openFrom p r [] j

/-- The barrier set: the call ids `STA-24` shows in a refused request's place. -/
@[req "STA-8"] def unresolved (p : Params) (j : Journal) (r : Resource) : List CallId :=
  (openIntents p j r).map (·.call)

/-- Every intent the journal holds, newest first. -/
def intentsOf (j : Journal) : List Intent :=
  j.filterMap fun rec => match rec with | .intent i => some i | _ => none

/-- The resources the journal names. -/
def resourcesOf (j : Journal) : List Resource := ((intentsOf j).map Intent.resource).eraseDups

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

/-- The disposition standing over a resource: the most recent one, unless a later intent on that
resource has been journaled since — "a new unresolved call stops that continuation again"
(`STA-24`). -/
def latestDisposition (r : Resource) : Journal → Option Disposition
  | [] => none
  | .intent i :: rest => if i.resource == r then none else latestDisposition r rest
  | .disposition d :: rest => if d.resource == r then some d else latestDisposition r rest
  | .observation _ :: rest => latestDisposition r rest
  | .association _ _ :: rest => latestDisposition r rest
  | .resetPrereqs _ :: rest => latestDisposition r rest

/-- What a standing disposition permits: `STA-24`'s "it permits only the continuation it names".
Without the rule a disposition clears the barrier and restricts nothing, which is the disposition
read as unrestricted dispatch. -/
@[req "STA-24"] def restriction (p : Params) (j : Journal) (r : Resource) : Option Kind :=
  if p.dispositionBindsContinuation then (latestDisposition r j).map (·.continuation) else none

/-- `STA-20b`: before a planned reset the harness "durably records installed host-key pins and
the reset intent. If collection or the durable append fails, it does not reset — and it does not
*offer* the reset either: the offer is checked against those durable prerequisites at the moment
it is made". The prerequisites are `ready_to_reset`'s record (`ARC-43`), and the offer reads what
the running worker holds — which `STA-3` makes exactly what was appended. -/
@[req "STA-20b"] def offersReset (j : Journal) (e : Entry) : Bool :=
  j.contains (.resetPrereqs e)

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
  /-- `STA-24`: a disposition stands over the resource and permits only the kind it names. -/
  | continuation (permitted : Kind)
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
dispatch." Total, and the order is the function's, so no refusal can be answered out of its
place. -/
@[req "STA-4"] def admit (p : Params) (j : Journal) (rq : Request) (ap : Approval) : Verdict :=
  match resolve j rq.target with
  | none => .refused .unmapped
  | some r =>
    if ap.session != rq.session then .refused .binding
    else if ap.facts != rq.facts then .refused .facts
    else match blocking p j (intentOf rq r ap) with
      | c :: cs => .refused (.barrier (c :: cs))
      | [] =>
        match restriction p j r with
        | some k =>
          if k == rq.kind then .dispatched (intentOf rq r ap) else .refused (.continuation k)
        | none => .dispatched (intentOf rq r ap)

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
  /-- The operator disposes (`STA-24`). -/
  | dispose (d : Disposition) (appended : Bool)
  /-- The harness associates what a model may name with the approved entry. -/
  | associate (t : Target) (e : Entry)
  /-- `ready_to_reset` (`ARC-43`) records the installed pins and the reset intent (`STA-20b`). -/
  | resetPrereqs (e : Entry) (appended : Bool)
  /-- The worker is killed and replays the journal (`STA-7`). -/
  | replay
  deriving DecidableEq, Repr

/-- One event. A request that `admit` accepts is journaled "immediately before the bytes leave"
(`STA-4`) and dispatched; if that append fails the transition does not occur and nothing leaves
(`STA-3`). A read's standing is what the far side reports and never this module's. A replay
throws in-memory state away and rebuilds it from the journal (`STA-2`, `STA-7`). -/
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
  | .dispose d ok => { append p w (.disposition d) ok with verdict := none }
  | .associate t e => { append p w (.association t e) true with verdict := none }
  | .resetPrereqs e ok => { append p w (.resetPrereqs e) ok with verdict := none }
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
it, and a standing disposition, if any, named this continuation. -/
theorem admit_dispatched (p : Params) (j : Journal) (rq : Request) (ap : Approval) (i : Intent)
    (h : admit p j rq ap = .dispatched i) :
    i.call = rq.call ∧ i.kind = rq.kind ∧ i.approval = ap ∧ i.session = ap.session ∧
    ap.facts = rq.facts ∧ blocking p j i = [] ∧
    ∀ k, restriction p j i.resource = some k → k = i.kind := by
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
          · rename_i k hk
            split at h
            · rename_i hkind
              injection h with h
              subst h
              refine ⟨rfl, rfl, rfl, hses.symm, hfacts, hblock, ?_⟩
              intro k' hk'
              simp only [intentOf] at hk' ⊢
              rw [hk] at hk'
              injection hk' with hk'
              subst hk'
              simpa only [beq_iff_eq] using hkind
            · exact nomatch h
          · rename_i hnone
            injection h with h
            subst h
            exact ⟨rfl, rfl, rfl, hses.symm, hfacts, hblock,
                   fun k' hk' => by
                     simp only [intentOf] at hk'; rw [hnone] at hk'; exact nomatch hk'⟩

/-- **The principal theorem.** Over every journal, every request, every approval and every
external state: an effect is dispatched only if its intent and approval are durable — the intent
record, carrying the approval, is in the journal the step appended — the binding still holds, the
approved facts are what is dispatched, and no unresolved call names its resource except under a
durable disposition naming that continuation. -/
@[req "STA-4"] theorem dispatched_only_if (p : Params) (hp : p.durableBeforeApply = true)
    (x : External) (w : World) (rq : Request) (ap : Approval) (ok : Bool) (i : Intent)
    (hi : i ∈ (step p x w (.request rq ap ok)).dispatched) (hnew : i ∉ w.dispatched) :
    Rec.intent i ∈ (step p x w (.request rq ap ok)).journal ∧
    i.approval = ap ∧ i.session = ap.session ∧ ap.facts = rq.facts ∧
    blocking p w.memory i = [] ∧
    ∀ k, restriction p w.memory i.resource = some k → k = i.kind := by
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
        exact ⟨List.mem_cons_self .., ha, hs, hf, hb, hc⟩
      · exact absurd hi hnew
    · exact absurd hi hnew

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
  | dispose d ok => exact append_memory_eq p hp w hw _ ok
  | associate t e => exact append_memory_eq p hp w hw _ true
  | resetPrereqs e ok => exact append_memory_eq p hp w hw _ ok
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
                  (machineA, .activate), (machineA, .exec), (machineB, .create)],
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

/-- The destructive call: a reset of the machine the vendor id names. Its second request is the
same action under a fresh call id, which is what a model sends when no confirmation arrives. -/
def resetRequest1 : Request :=
  { call := 1, target := .vendor vendorA, kind := .reset, session := sessionA,
    facts := factsReset }
def resetRequest2 : Request := { resetRequest1 with call := 2 }
/-- The named continuation of the disposition below, requested by the successor session: the
barrier holds "whichever session or model requests it" (`STA-24`), and so does the permission. -/
def resetRequest3 : Request := { resetRequest1 with call := 3, session := sessionB }
/-- The ceremony's second reset, into the installed system, whose predicate is sshd answering
with the installed pin (`STG-4`). -/
def resetRequest4 : Request := { resetRequest1 with call := 11 }

/-- The create at the first reserved index, and a second attempt at the same approved entry,
which would reserve another. -/
def createRequest0 : Request :=
  { call := 4, target := .index index0, kind := .create, session := sessionA,
    facts := factsCreate }
def createRequest1 : Request := { createRequest0 with call := 5, target := .index index1 }
/-- The sibling entry's create: a different approved entry, under its own approval. -/
def createRequestB : Request :=
  { createRequest0 with call := 6, target := .index index2, facts := factsCreateB }

/-- Box-plane work on the machine, which a planned reset stops "from its intent until its
confirmation or disposition" (`STA-24`). -/
def execRequest : Request :=
  { call := 7, target := .vendor vendorA, kind := .exec, session := sessionA, facts := factsExec }
/-- Ordinary work on the installed system, after the second reset is confirmed. -/
def execRequest2 : Request := { execRequest with call := 12 }

/-- Abandonment (`ARC-21`), which the disposition below does not name. -/
def destroyRequest : Request :=
  { call := 8, target := .vendor vendorA, kind := .destroy, session := sessionA,
    facts := factsDestroy }

def registerRequest : Request :=
  { call := 9, target := .entry entryA, kind := .registerKey, session := sessionA,
    facts := factsRegister }
def activateRequest : Request :=
  { call := 10, target := .entry entryA, kind := .activate, session := sessionA,
    facts := factsActivate }

/-- The operator's disposition of the outstanding reset: it names the call and permits one
continuation, a destructive reinstall (`STG-20`), which here is the reset again. -/
def dispositionA : Disposition :=
  { resource := machineA, calls := [resetRequest1.call], continuation := .reset }

/-! Each witness's events are one named list, so that the theorem and the emitter
(`Witnesses.lean`) run the same trace. -/

def sameActionEvents : List Event :=
  [.request resetRequest1 approvalReset true, .request resetRequest2 approvalReset true]

def secondIndexEvents : List Event :=
  [.request createRequest0 approvalCreate true, .request createRequestB approvalCreateB true,
   .request createRequest1 approvalCreate true]

def resetOfferEvents : List Event := [.resetPrereqs entryA false]

def bootIdEvents : List Event :=
  [.request resetRequest1 approvalReset true, .observe .adapterRead machineA .reset true,
   .request execRequest approvalExec true]

def appendFailedEvents : List Event :=
  [.request resetRequest1 approvalReset true, .observe .adapterRead machineA .reset false,
   .request execRequest approvalExec true, .replay]

def dispositionEvents : List Event :=
  [.request resetRequest1 approvalReset true, .dispose dispositionA true,
   .request destroyRequest approvalDestroy true, .request resetRequest3 approvalResetB true]

/-- `STG-4`'s four confirmation predicates in order, each mutation dispatched once its
predecessor is confirmed: the key registered and confirmed by the account's key listing, the
activation by `GET /boot/{n}/rescue`, the reset into rescue by a host-key set different from the
journaled one, the install run as box-plane work and settled by its own job record (`STA-20`,
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

def onCall : Params := { current with resourceKey := .call }
def onIndex : Params := { current with resourceKey := .index }
def noDurability : Params := { current with durableBeforeApply := false }
def flatLattice : Params := { current with endedBelowSucceeded := false }
def unboundDisposition : Params := { current with dispositionBindsContinuation := false }

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
    offersReset w.memory entryA = false ∧ offersReset w.journal entryA = false ∧
    w.memory = w.journal := by decide +kernel

/-- Without `STA-3`'s rule the record reaches in-memory state alone, and the offer — "checked
against those durable prerequisites at the moment it is made" — is made against a fact the
journal does not hold. -/
@[req "STA-20b"] theorem reset_offered_after_failed_append_admitted :
    let w := run noDurability farDone.external init resetOfferEvents
    offersReset w.memory entryA = true ∧ offersReset w.journal entryA = false := by decide +kernel

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

/-- **A disposition permits only the continuation it names.** The operator disposes of the
outstanding reset: the call is terminal with its outcome unknown, so it is no longer an open one,
and abandonment — which the disposition does not name — is refused with the permitted
continuation shown. The reinstall it does name is dispatched, by the successor session. -/
@[req "STA-24"] theorem disposition_one_continuation_refused :
    let w := run current farDone.external init dispositionEvents
    w.dispatched.map (·.call) = [3, 1] ∧ unresolved current w.memory machineA = [3] ∧
    restriction current w.memory machineA = none := by decide +kernel

/-- Without the rule the disposition restricts nothing: abandonment is dispatched against a
machine whose reset may have landed, and the continuation the operator did name is then barred by
it. -/
@[req "STA-24"] theorem disposition_unrestricted_admitted :
    let w := run unboundDisposition farDone.external init dispositionEvents
    w.dispatched.map (·.call) = [8, 1] ∧
    unresolved unboundDisposition w.memory machineA = [8] := by decide +kernel

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

/-! ## The bound -/

/-- The bound (`CONTEXT.md`): every trace of at most this many events over `alphabet`, from
`init`. Stated once, here, for `bounded` and for the witness file; beyond it is the theorems'
statements, not the file's. -/
@[req "STA-24"] def bound : Nat := 3

/-- The events the bounded enumeration draws from: the destructive call and the same action under
a fresh call id, box-plane work on the same machine, the vendor read that settles the reset, the
operator's disposition, and a replay. -/
def alphabet : List Event :=
  [.request resetRequest1 approvalReset true, .request resetRequest2 approvalReset true,
   .request execRequest approvalExec true, .observe .adapterRead machineA .reset true,
   .dispose dispositionA true, .replay]

/-- Every trace of exactly `n` events over `alphabet`. -/
def tracesOf : Nat → List (List Event)
  | 0 => [[]]
  | n + 1 => (tracesOf n).flatMap fun es => alphabet.map (es ++ [·])

/-- Every trace of at most `n` events over `alphabet`, shortest first. -/
def tracesUpTo (n : Nat) : List (List Event) := (List.range (n + 1)).flatMap tracesOf

/-- `STA-24`: "The worker admits at most one outstanding effect per resource: admission,
reservation and the dispatch check are serialized by the single writer (`STA-1`), so two requests
cannot both pass before either is unresolved." Stated without `bars`, so that it decides what
`bars` reads rather than agreeing with it: one resource carries a second outstanding call only
where every outstanding call on it is box-plane, which is `STA-20`'s tracked jobs, plural by
design — "waits for all tracked commands to end". No cloud-plane call is ever outstanding beside
another call of any kind. -/
@[req "STA-24"] def atMostOneOutstanding (p : Params) (j : Journal) : Bool :=
  (resourcesOf j).all fun r =>
    let open_ := openIntents p j r
    decide (open_.length ≤ 1) || open_.all fun i => !cloudPlane i.kind

/-- At most one outstanding effect per resource, decided within the bound: the enumeration the
witness file carries is one the companion itself closed over. -/
@[req "STA-24"] theorem bounded :
    (tracesUpTo bound).all (fun es =>
      atMostOneOutstanding current (run current farDone.external init es).memory) = true := by
  decide +kernel

end TauWeb.Dispatch
