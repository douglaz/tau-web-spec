import TauWeb.Dispatch
/-! Processed local authority composed with Dispatch, a checking interpretation of `STA-23`,
`SEC-1`, `SEC-4` and the conditional `ARC-31a` boundary (ADR-0032).

The single writer and current store custody are assumptions, as in Dispatch. A processed End
stands for an already durably committed End with stopped workers and closed channels; it
proves none of those implementation facts. Failed End append supplies no processed End input. Identities are symbolic,
never credentials. Operator admission/binding, connection/scan readiness, safe-unsent evidence
and issuer facts enter explicitly. No browser scheduling, complete lifecycle notification,
transport cancellation, erasure, issuer enforcement or arithmetic is established here.

Validation names one proposed request, its approval, resolved binding, worker/session incarnation,
revision and current Dispatch verdict. It never supplies Dispatch permission: requests delegate
unchanged to Dispatch.step, and publication checks Dispatch.admit anew. Holds need not all be
empty. Growing an unrelated binding does not invalidate an applicable approval or validation.

A publication pairs an original issued call with a separately named proposed continuation.
Only the latter is checked as unsent. Origin correlation is this interface's convention, not a
ban on later independently authorized historical use. Received records are not read transmissions;
the recording interface admits no request, and requires explicit authorization and writer/store
custody. Non-session flows, cleanup, display duties, goal semantics, pending delivery checks and
untyped-scope holds retain their owners and are not implemented here.

Procured evidence is symbolic and conditional, with unchanged original key/limits, issuer
acceptance, interval/rate/arithmetic/continuity and BOTH wall/monotonic discrepancy checks.
There is no clock simulation, mint protocol, local spend reservation or production admission.
Already accepted remote work may continue after local end. -/
namespace TauWeb.Authority

open TauWeb.Dispatch (Request Approval Resource Entry Intent)

structure Identity where
  incarnation : Nat
  worker : Nat
  session : Dispatch.SessionId
  deriving DecidableEq, Repr

/-- Opaque identities of the original key, origin, limit and absolute expiry; not timer values. -/
structure Limits where
  key : Nat
  origin : Nat
  cap : Nat
  expiry : Nat
  deriving DecidableEq, Repr

inductive Path
  | independent
  | procured (original : Limits)
  deriving DecidableEq, Repr

inductive KeyState
  | valid | uncertain | expired | exhausted | incompatible
  deriving DecidableEq, Repr

/-- Each true field is an external evidence hypothesis under the full `ARC-31a` contract.
`anchorCheck` and `pairCheck` are distinct; neither substitutes for the other. A false evidence
field means the fact has not been established, not proof of its negation. Established upper-bound
equality/passage is `.expired`, and established cap exhaustion is `.exhausted`; neither is `.valid`. -/
structure KeyEvidence where
  original : Limits
  state : KeyState
  issuerAcceptance : Bool
  authenticatedInterval : Bool
  evidencedRates : Bool
  monotonicContinuity : Bool
  exactArithmetic : Bool
  anchorCheck : Bool
  pairCheck : Bool
  upperBeforeExpiry : Bool
  allowanceEstablished : Bool
  deriving DecidableEq, Repr

@[req "ARC-31a"] def KeyEvidence.valid (e : KeyEvidence) : Bool :=
  e.state == .valid && e.issuerAcceptance && e.authenticatedInterval && e.evidencedRates &&
  e.monotonicContinuity && e.exactArithmetic && e.anchorCheck && e.pairCheck &&
  e.upperBeforeExpiry && e.allowanceEstablished

structure Evidence where
  connected : Bool
  scanReady : Bool
  /-- Evidence about THIS proposed continuation, never inferred from its new call id. -/
  safeUnsent : Bool
  key : Option KeyEvidence := none
  deriving DecidableEq, Repr

structure Work where
  who : Identity
  request : Request
  approval : Approval
  deriving DecidableEq, Repr

structure Validation where
  work : Work
  resource : Resource
  revision : Nat
  /-- Evaluated by Dispatch, even when its verdict refuses the proposed work. -/
  checked : Dispatch.Verdict
  deriving DecidableEq, Repr

structure Actor where
  who : Identity
  bound : List Entry
  path : Path
  /-- A processed interruption makes each subsequent work require particular validation. -/
  interrupted : Bool := false
  revision : Nat := 0
  validation : Option Validation := none
  keyWithheld : Bool := false
  paused : Bool := false
  sealedTerminal : Bool := false
  lostKey : Bool := false
  deriving DecidableEq, Repr

structure Candidate where
  who : Identity
  bound : List Entry
  path : Path := .independent
  deriving DecidableEq, Repr

structure Issued where
  work : Work
  resource : Resource
  deriving DecidableEq, Repr

@[req "STA-23"] structure Params where
  endFence : Bool := true
  pauseRequired : Bool := true
  resumeTerminal : Bool := true
  sealedTerminalRequired : Bool := true
  executionFresh : Bool := true
  bindingSessionLifetime : Bool := true
  resumeValidation : Bool := true
  resumeAuthorized : Bool := true
  resumeUnlocked : Bool := true
  lostKeySticky : Bool := true
  ceremonyPending : Bool := true
  ceremonyCompletion : Bool := true
  ceremonyAppend : Bool := true
  ceremonyActive : Bool := true
  ceremonyRelease : Bool := true
  ceremonyUnlocked : Bool := true
  sealUnlocked : Bool := true
  workerIdentity : Bool := true
  requestSession : Bool := true
  machineMembership : Bool := true
  growthExclusive : Bool := true
  growthAvailable : Bool := true
  requestOriginal : Bool := true
  hidePreserves : Bool := true
  ceremonyHideLocks : Bool := true
  unsentContinuation : Bool := true
  validationTerminal : Bool := true
  validationRequired : Bool := true
  validationMatches : Bool := true
  publicationDispatch : Bool := true
  publicationOrigin : Bool := true
  individualOnly : Bool := true
  exclusiveBinding : Bool := true
  procuredEligibility : Bool := true
  scopedExpiry : Bool := true
  /-- Counterfactual: lifecycle validation fabricates a confirming observation. -/
  preserveKnowledge : Bool := true
  deriving DecidableEq, Repr

@[req "STA-23"] def current : Params := {}

structure World where
  dispatch : Dispatch.World
  actors : List Actor := []
  /-- Append-only fences, including identities not presently admitted. Never replayed as keys. -/
  fenced : List Identity := []
  /-- Admitted durable session-End projection, separate from incarnation fences. -/
  ended : List Dispatch.SessionId := []
  locked : Bool := true
  ceremony : Bool := false
  /-- This active/interrupted ceremony only; stored completion records are outside this state. -/
  ceremonyOwed : Bool := false
  issued : List Issued := []
  published : List Issued := []
  deriving DecidableEq, Repr

/-- Lookup is exact in production; the counterfactual forgets worker/incarnation identity. -/
def actor (p : Params) (w : World) (who : Identity) : Option Actor :=
  w.actors.find? fun a => if p.workerIdentity then a.who == who else a.who.session == who.session

def updateActor (w : World) (who : Identity) (f : Actor → Actor) : World :=
  { w with actors := w.actors.map fun a => if a.who == who then f a else a }

@[req "STA-23"] def endOne (w : World) (who : Identity) : World :=
  { w with fenced := who :: w.fenced, ended := who.session :: w.ended }

@[req "STA-23"] def endAll (w : World) : World :=
  { w with fenced := w.actors.map (·.who) ++ w.fenced, ended := w.actors.map (·.who.session) ++ w.ended, locked := true, ceremony := false }

/-- Pausing retains bindings and approvals; no End is applied. -/
@[req "STA-23"] def pauseAll (w : World) : World :=
  { w with locked := true, ceremony := false, actors := w.actors.map fun a =>
      { a with paused := true, interrupted := true, revision := a.revision + 1, validation := none } }

/-- Incarnation names may not collide with current or retired executions.
Fresh symbolic names are an input convention, but reuse is also checked here. -/
@[req "STA-23"] def freshExecution (p : Params) (w : World) (next : Identity) : Bool :=
  !p.executionFresh ||
    !(w.actors.any fun a => a.who.incarnation == next.incarnation) &&
    !(w.fenced.any fun i => i.incarnation == next.incarnation)

def ceremonyFree (p : Params) (w : World) : Bool :=
  !w.ceremony && (!p.ceremonyPending || !w.ceremonyOwed)

def available (p : Params) (w : World) : Bool := !w.locked && ceremonyFree p w

/-- Resume replaces an execution incarnation, never the session's authority or limits.
The authorization input includes stopped predecessor/single-writer custody as an assumption. -/
@[req "STA-23"] def resume (p : Params) (w : World) (old : Identity) (incarnation : Nat) (ok : Bool) : World :=
  let next := { old with incarnation, worker := incarnation }
  match actor p w old with
  | none => w
  | some a =>
    if (!p.resumeAuthorized || ok) && (!p.resumeUnlocked || !w.locked) &&
        ceremonyFree p w && freshExecution p w next &&
        (!p.endFence || (!w.ended.contains next.session && !w.fenced.contains next)) then
      { w with fenced := old :: w.fenced, actors := w.actors.map fun b =>
          if b.who == a.who then
            { b with who := next, paused := false, interrupted := p.resumeValidation, revision := b.revision + 1, validation := none, lostKey := (p.lostKeySticky && b.lostKey) || (match b.path with
                | .independent => false | .procured _ => !b.sealedTerminal), keyWithheld := (match b.path with | .independent => false | .procured _ => true) }
          else b }
    else w

@[req "SEC-1"] def bindingFree (p : Params) (w : World) (who : Identity) (entries : List Entry) : Bool :=
  w.actors.all fun a => a.who == who ||
    (if p.bindingSessionLifetime then w.ended.contains a.who.session else w.fenced.contains a.who) ||
    !(entries.any fun e => a.bound.contains e)

/-- Approval equality remains Dispatch's; this is live authority and actual symbolic binding. -/
@[req "STA-23"] def authority (p : Params) (w : World) (work : Work) : Bool :=
  available p w &&
  match actor p w work.who, Dispatch.resolve w.dispatch.memory work.request.target with
  | some a, some r =>
    (!p.endFence || (!w.fenced.contains a.who && !w.ended.contains a.who.session)) &&
    (!p.pauseRequired || !a.paused) &&
    (!p.requestSession || work.request.session == a.who.session) &&
    match r with
    | .machine e => !p.machineMembership || a.bound.contains e
    | .inference => true
  | _, _ => false

@[req "ARC-31a"] def keyEligible (p : Params) (a : Actor) (ev : Evidence) : Bool :=
  if !p.procuredEligibility then true else
  match a.path with
  | .independent => true
  | .procured original => (!p.sealedTerminalRequired || a.sealedTerminal) &&
    (!p.resumeTerminal || !a.lostKey) && !a.keyWithheld &&
    match ev.key with
    | some k => (!p.requestOriginal || k.original == original) && k.valid
    | none => false

@[req "STA-23"] def validationCurrent (p : Params) (dp : Dispatch.Params) (w : World)
    (a : Actor) (work : Work) (ev : Evidence) : Bool :=
  if !a.interrupted || !p.validationRequired then true else
  ev.safeUnsent && match a.validation with
  | none => false
  | some v => !p.validationMatches ||
    (v.work == work && v.revision == a.revision &&
     Dispatch.resolve w.dispatch.memory work.request.target == some v.resource &&
     v.checked == Dispatch.admit dp w.dispatch.memory work.request work.approval)

/-- Absence from these histories is NOT unsent evidence: the separate current safeUnsent
hypothesis is still required after interruption. Known issued calls cannot contradict it. -/
@[req "STA-23"] def notPreviouslyIssued (p : Params) (w : World) (work : Work) : Bool :=
  !p.unsentContinuation ||
    (!(w.issued.any fun i => i.work.request.call == work.request.call) &&
     !(w.dispatch.dispatched.any fun i => i.call == work.request.call))

/-- Connection, scan and key facts here are CURRENT boundary hypotheses, not a cached Ready bit. -/
@[req "STA-23"] def eligible (p : Params) (dp : Dispatch.Params) (w : World)
    (work : Work) (ev : Evidence) : Bool :=
  notPreviouslyIssued p w work &&
  (authority p w work && ev.connected && ev.scanReady &&
    match actor p w work.who with
    | none => false
    | some a => keyEligible p a ev && validationCurrent p dp w a work ev)

/-- Only already received evidence/operator records; no request or synthetic query send. -/
inductive Record
  | observation (source : Dispatch.Provenance) (resource : Resource) (kind : Dispatch.Kind) (appended : Bool)
  | receipt (receipt : Dispatch.Receipt) (appended : Bool)
  | reboot (call : Dispatch.CallId) (resource : Resource) (boot : Option Nat) (appended : Bool)
  | disposition (d : Dispatch.Disposition) (appended : Bool)
  deriving DecidableEq, Repr

def Record.event : Record → Dispatch.Event
  | .observation s r k ok => .observe s r k ok
  | .receipt r ok => .receive r ok
  | .reboot c r b ok => .collectReboot c r b ok
  | .disposition d ok => .dispose d ok

/-- Explicit assumptions: safe finalization authorization and current single-writer/store access.
Neither an ended actor nor receipt of evidence supplies either permission. -/
structure Custody where
  authorized : Bool
  writerOwnsStore : Bool
  storeAccess : Bool
  deriving DecidableEq, Repr

inductive EndReason
  | explicit | replace | expiry | capExhaustion | abandon
  deriving DecidableEq, Repr

inductive PauseReason
  | lock | pagehide | reload | shutdown | discard
  deriving DecidableEq, Repr

/-- “Check all words” supplies the same-seed validation hypothesis; “Skip check” supplies no
word check. Neither choice establishes backup safety. The explanatory action text stays in
the Markdown; the full-reentry fact is a validation hypothesis, not cryptography. -/
inductive Completion
  | fullReentry (sameSeed : Bool)
  | skipped
  deriving DecidableEq, Repr

def Completion.valid : Completion → Bool
  | .fullReentry sameSeed => sameSeed
  | .skipped => true

inductive Local
  | hide | visible
  | suspend (who : Identity)
  | invalidate (who : Identity)
  | validate (work : Work) (evidence : Evidence)
  | endSession (who : Identity) (reason : EndReason)
  /-- Replace is the only global End path; other causes name affected sessions. -/
  | replace
  | pause (reason : PauseReason)
  | resume (old : Identity) (incarnation : Nat) (authorized : Bool)
  | sealTerminal (who : Identity) (appended : Bool)
  | enterCeremony
  | finishCeremony (completion : Completion) (appended : Bool)
  | unlock (authorized : Bool)
  | admit (candidate : Candidate) (authorized : Bool)
  | grow (who : Identity) (entry : Entry) (authorized : Bool)
  | assessKey (who : Identity) (evidence : KeyEvidence)
  deriving DecidableEq, Repr

/-- Assessment never replaces original limits. Expiry/cap end only the affected procured actor;
uncertainty/incompatibility withhold. Valid repair invalidates prior continuation validation. -/
@[req "ARC-31a"] def assess (p : Params) (w : World) (who : Identity) (k : KeyEvidence) : World :=
  match actor p w who with
  | none => w
  | some a =>
    if w.fenced.contains a.who then w else
    match a.path with
    | .independent =>
      if !p.scopedExpiry && (k.state == .expired || k.state == .exhausted) then endAll w else w
    | .procured original =>
      if !p.procuredEligibility then w else
      if k.original == original && (k.state == .expired || k.state == .exhausted) then
        if p.scopedExpiry then endOne w a.who else endAll w
      else updateActor w a.who fun a =>
        { a with keyWithheld := !(k.original == original && k.valid), revision := a.revision + 1, validation := none }

/-- A processed boundary carrying established expiry/cap evidence fences before admission.
Other assessments have explicit local events; current key evidence is checked afresh below. -/
def boundary (p : Params) (w : World) (work : Work) (ev : Evidence) : World :=
  match ev.key with
  | some k => if k.state == .expired || k.state == .exhausted then assess p w work.who k else w
  | none => w


/-- Local state only. End fences are separate from history and never cleared by admission.
The Markdown owns the pre-display app-switch/unlock warning and local unlock explanation;
this transition checks processed interruption and unlock authority, not their display. -/
def localAuthorityStep (p : Params) (dp : Dispatch.Params) (w : World) : Local → World
  | .hide => if w.ceremony then
      if p.ceremonyHideLocks then pauseAll w else w
    else if p.hidePreserves then w else endAll w
  | .visible => w
  | .suspend who | .invalidate who => updateActor w who fun a =>
      { a with interrupted := true, revision := a.revision + 1, validation := none }
  | .validate work ev =>
    let w := if p.validationTerminal then boundary p w work ev else w
    if authority p w work && notPreviouslyIssued p w work && ev.connected && ev.scanReady && ev.safeUnsent then
      match actor p w work.who, Dispatch.resolve w.dispatch.memory work.request.target with
      | some a, some r => if keyEligible p a ev then updateActor w a.who fun a =>
          { a with validation := some ⟨work, r, a.revision,
              Dispatch.admit dp w.dispatch.memory work.request work.approval⟩ }
        else w
      | _, _ => w
    else w
  | .endSession who _ => if p.individualOnly then endOne w who else endAll w
  | .replace => endAll w
  | .pause _ => pauseAll w
  | .resume old incarnation ok => resume p w old incarnation ok
  -- A seal stands for a durably committed, validated terminal, sealed under the data key, which
  -- a locked store does not hold (`STA-23`), so it waits for `.unlock true`. As an input
  -- convention, a terminal append begun before Lock is presented after the next unlock and
  -- before resume, however it finishes; this interpretation makes no storage-ordering claim.
  | .sealTerminal who ok => if ok && !(p.sealUnlocked && w.locked) then updateActor w who fun a =>
      { a with sealedTerminal := true } else w
  -- `.unlock true` stands for the local passphrase entry; ceremony entry or re-display while
  -- locked waits for it. Entry from an already unlocked store needs no further event here.
  | .enterCeremony => if (p.ceremonyUnlocked && w.locked) then w
    else { pauseAll w with locked := false, ceremony := true, ceremonyOwed := true }
  | .finishCeremony choice ok =>
    if (!p.ceremonyActive || w.ceremony) && (!p.ceremonyCompletion || choice.valid) && (!p.ceremonyAppend || ok) then
      { w with ceremony := false, ceremonyOwed := !p.ceremonyRelease }
    else w
  | .unlock ok => if ok then { w with locked := false } else w
  | .admit c ok =>
    if ok && available p w && freshExecution p w c.who &&
      (!p.endFence || (!w.fenced.contains c.who && !w.ended.contains c.who.session)) &&
      !(w.actors.any fun a => a.who.session == c.who.session) &&
      (!p.exclusiveBinding || bindingFree p w c.who c.bound) then
      { w with actors := { who := c.who, bound := c.bound, path := c.path, keyWithheld := (match c.path with | .independent => false | .procured _ => true) } :: w.actors }
    else w
  | .grow who entry ok =>
    if ok && !w.fenced.contains who &&
      (!p.growthAvailable || (available p w && !(w.actors.any fun a => a.who == who && a.paused))) &&
      (!p.exclusiveBinding || !p.growthExclusive || bindingFree p w who [entry]) then
      updateActor w who fun a => { a with bound := (entry :: a.bound).eraseDups }
    else w
  | .assessKey who ev => assess p w who ev

@[req "STA-23"] def localStep (p : Params) (dp : Dispatch.Params) (x : Dispatch.External)
    (w : World) (event : Local) : World :=
  let next := localAuthorityStep p dp w event
  if p.preserveKnowledge then next else
    match event with
    | .validate work _ => match Dispatch.resolve w.dispatch.memory work.request.target with
      | some r => { next with dispatch := Dispatch.step dp x next.dispatch (.observe .adapterRead r .reset true) }
      | none => next
    | _ => next


inductive Event
  | lifecycle (event : Local)
  | request (work : Work) (evidence : Evidence) (appended : Bool)
  | publish (origin : Issued) (continuation : Work) (evidence : Evidence)
  | record (record : Record) (custody : Custody)
  | replay
  deriving DecidableEq, Repr

/-- An original transmitted call need not be unsent. Only the proposed continuation is.
`admit` checks its current holds/facts; the interface asserts no cross-layer reason precedence. -/
@[req "STA-23"] def publishable (p : Params) (dp : Dispatch.Params) (w : World)
    (origin : Issued) (next : Work) (ev : Evidence) : Bool :=
  w.issued.contains origin &&
  (!p.publicationOrigin || (origin.work.who == next.who && authority p w origin.work &&
    Dispatch.resolve w.dispatch.memory origin.work.request.target == some origin.resource)) &&
  eligible p dp w next ev &&
  (!p.publicationDispatch || match Dispatch.admit dp w.dispatch.memory next.request next.approval with
  | .dispatched _ => true
  | .refused _ => false)

@[req "STA-23"] def step (p : Params) (dp : Dispatch.Params) (x : Dispatch.External)
    (w : World) : Event → World
  | .lifecycle e => localStep p dp x w e
  | .request work ev ok =>
    let ready := boundary p w work ev
    if eligible p dp ready work ev then
      let d := Dispatch.step dp x ready.dispatch (.request work.request work.approval ok)
      let issued := match d.verdict with
        | some (.dispatched i) => { work, resource := i.resource } :: ready.issued
        | _ => ready.issued
      { ready with dispatch := d, issued }
    else ready
  | .publish origin work ev =>
    let ready := boundary p w work ev
    if publishable p dp ready origin work ev then { ready with published := origin :: ready.published }
    else ready
  | .record rec custody =>
    if custody.authorized && custody.writerOwnsStore && custody.storeAccess then
      { w with dispatch := Dispatch.step dp x w.dispatch rec.event }
    else w
  | .replay => { pauseAll w with dispatch := Dispatch.step dp x w.dispatch .replay }

def run (p : Params) (dp : Dispatch.Params) (x : Dispatch.External) (w : World) : List Event → World
  | [] => w
  | e :: es => run p dp x (step p dp x w e) es

/-! General properties over arbitrary symbolic states/histories. -/

private theorem update_fence (w : World) (who : Identity) (f : Actor → Actor) :
    (updateActor w who f).fenced = w.fenced := rfl

private theorem assess_fence (p : Params) (w : World) (who : Identity) (k : KeyEvidence)
    (i : Identity) (h : i ∈ w.fenced) : i ∈ (assess p w who k).fenced := by
  unfold assess
  split
  · exact h
  · split
    · exact h
    · split
      · split <;> simp_all [endAll, List.mem_append]
      · split
        · exact h
        · split
          · split <;> simp_all [endOne, endAll, List.mem_append]
          · exact h

private theorem boundary_fence (p : Params) (w : World) (work : Work) (ev : Evidence)
    (i : Identity) (h : i ∈ w.fenced) : i ∈ (boundary p w work ev).fenced := by
  unfold boundary
  split
  · split
    · exact assess_fence p w _ _ i h
    · exact h
  · exact h


private theorem local_fence (p : Params) (dp : Dispatch.Params) (x : Dispatch.External)
    (w : World) (e : Local) (i : Identity) (h : i ∈ w.fenced) :
    i ∈ (localStep p dp x w e).fenced := by
  have ha : i ∈ (localAuthorityStep p dp w e).fenced := by
    cases e <;> simp only [localAuthorityStep]
    all_goals first | exact h | (apply assess_fence; exact h) | skip
    all_goals repeat first | split | exact h | (apply boundary_fence; exact h) | simp_all [endOne, endAll, resume, List.mem_append]
  unfold localStep
  split
  · exact ha
  · split <;> try exact ha
    split <;> exact ha


@[req "STA-23"] theorem fence_step (p : Params) (dp : Dispatch.Params) (x : Dispatch.External)
    (w : World) (e : Event) (i : Identity) (h : i ∈ w.fenced) :
    i ∈ (step p dp x w e).fenced := by
  cases e with
  | lifecycle e => exact local_fence p dp x w e i h
  | request work ev ok =>
    have hb := boundary_fence p w work ev i h
    simp only [step]; split <;> exact hb
  | publish origin work ev =>
    have hb := boundary_fence p w work ev i h
    simp only [step]; split <;> exact hb
  | record rec custody => simp only [step]; split <;> exact h
  | replay => exact h

@[req "STA-23"] theorem fence_history (p : Params) (dp : Dispatch.Params) (x : Dispatch.External)
    (w : World) (es : List Event) (i : Identity) (h : i ∈ w.fenced) :
    i ∈ (run p dp x w es).fenced := by
  induction es generalizing w with
  | nil => exact h
  | cons e es ih => exact ih (step p dp x w e) (fence_step p dp x w e i h)

private theorem update_session_end (w : World) (who : Identity) (f : Actor → Actor) :
    (updateActor w who f).ended = w.ended := rfl

private theorem assess_session_end (p : Params) (w : World) (who : Identity) (k : KeyEvidence)
    (i : Dispatch.SessionId) (h : i ∈ w.ended) : i ∈ (assess p w who k).ended := by
  unfold assess
  split
  · exact h
  · split
    · exact h
    · split
      · split <;> simp_all [endAll, List.mem_append]
      · split
        · exact h
        · split
          · split <;> simp_all [endOne, endAll, List.mem_append]
          · exact h

private theorem boundary_session_end (p : Params) (w : World) (work : Work) (ev : Evidence)
    (i : Dispatch.SessionId) (h : i ∈ w.ended) : i ∈ (boundary p w work ev).ended := by
  unfold boundary
  split
  · split
    · exact assess_session_end p w _ _ i h
    · exact h
  · exact h


private theorem local_session_end (p : Params) (dp : Dispatch.Params) (x : Dispatch.External)
    (w : World) (e : Local) (i : Dispatch.SessionId) (h : i ∈ w.ended) :
    i ∈ (localStep p dp x w e).ended := by
  have ha : i ∈ (localAuthorityStep p dp w e).ended := by
    cases e <;> simp only [localAuthorityStep]
    all_goals first | exact h | (apply assess_session_end; exact h) | skip
    all_goals repeat first | split | exact h | (apply boundary_session_end; exact h) | simp_all [endOne, endAll, resume, List.mem_append]
  unfold localStep
  split
  · exact ha
  · split <;> try exact ha
    split <;> exact ha


@[req "STA-23"] theorem session_end_step (p : Params) (dp : Dispatch.Params) (x : Dispatch.External)
    (w : World) (e : Event) (i : Dispatch.SessionId) (h : i ∈ w.ended) :
    i ∈ (step p dp x w e).ended := by
  cases e with
  | lifecycle e => exact local_session_end p dp x w e i h
  | request work ev ok =>
    have hb := boundary_session_end p w work ev i h
    simp only [step]; split <;> exact hb
  | publish origin work ev =>
    have hb := boundary_session_end p w work ev i h
    simp only [step]; split <;> exact hb
  | record rec custody => simp only [step]; split <;> exact h
  | replay => exact h

@[req "STA-23"] theorem session_end_history (p : Params) (dp : Dispatch.Params) (x : Dispatch.External)
    (w : World) (es : List Event) (i : Dispatch.SessionId) (h : i ∈ w.ended) :
    i ∈ (run p dp x w es).ended := by
  induction es generalizing w with
  | nil => exact h
  | cons e es ih => exact ih (step p dp x w e) (session_end_step p dp x w e i h)

@[req "STA-23"] theorem hide_identity (p : Params) (dp : Dispatch.Params) (x : Dispatch.External)
    (w : World) (hp : p.hidePreserves = true) (hk : p.preserveKnowledge = true)
    (hc : w.ceremony = false) : localStep p dp x w .hide = w := by
  simp [localStep, localAuthorityStep, hp, hk, hc]

private theorem assess_dispatch (p : Params) (w : World) (who : Identity) (k : KeyEvidence) :
    (assess p w who k).dispatch = w.dispatch := by
  unfold assess
  repeat first | split | rfl

private theorem boundary_dispatch (p : Params) (w : World) (work : Work) (ev : Evidence) :
    (boundary p w work ev).dispatch = w.dispatch := by
  unfold boundary
  split
  · split
    · exact assess_dispatch p w _ _
    · rfl
  · rfl

private theorem local_dispatch (p : Params) (dp : Dispatch.Params) (w : World) (e : Local) :
    (localAuthorityStep p dp w e).dispatch = w.dispatch := by
  cases e <;> simp only [localAuthorityStep]
  all_goals repeat first | split | rfl | apply boundary_dispatch | apply assess_dispatch
  all_goals unfold resume; dsimp only; split <;> (repeat first | split | rfl)

@[req "STA-8"] theorem lifecycle_knowledge (p : Params) (dp : Dispatch.Params) (x : Dispatch.External)
    (w : World) (e : Local) (hp : p.preserveKnowledge = true) :
    (localStep p dp x w e).dispatch = w.dispatch := by
  simp only [localStep, hp, if_true]
  exact local_dispatch p dp w e

/-- A useful refinement: a newly admitted effect has current authority AND is exactly the
existing Dispatch request transition. Dispatch's own theorem supplies durability and guards. -/
@[req "STA-4"] theorem ordinary_refinement (p : Params) (dp : Dispatch.Params)
    (hp : dp.durableBeforeApply = true) (x : Dispatch.External) (w : World)
    (work : Work) (ev : Evidence) (ok : Bool) (i : Intent)
    (hi : i ∈ (step p dp x w (.request work ev ok)).dispatch.dispatched)
    (hnew : i ∉ w.dispatch.dispatched) :
    eligible p dp (boundary p w work ev) work ev = true ∧
    (step p dp x w (.request work ev ok)).dispatch =
      Dispatch.step dp x w.dispatch (.request work.request work.approval ok) ∧
    Dispatch.Rec.intent i ∈ (step p dp x w (.request work ev ok)).dispatch.journal ∧
    i.approval = work.approval ∧ i.session = work.approval.session ∧
    work.approval.facts = work.request.facts ∧ Dispatch.blocking dp w.dispatch.memory i = [] ∧
    ∀ s, dp.dispositionBindsContinuation = true →
      Dispatch.standing dp w.dispatch.memory i.resource = some s →
      Dispatch.stops dp s.1.continuation i.kind = false ∧
      (Dispatch.reaches dp (Dispatch.inEffect dp w.dispatch.memory) s i.kind = true →
        Dispatch.permits dp (Dispatch.inEffect dp w.dispatch.memory) s i.kind = true) := by
  have hb := boundary_dispatch p w work ev
  simp only [step] at hi ⊢
  split at hi
  · rename_i he
    simp only [he, if_true, hb] at hi ⊢
    exact ⟨True.intro, True.intro, Dispatch.dispatched_only_if dp hp x w.dispatch work.request work.approval ok i hi hnew⟩
  · simp only [hb] at hi
    exact False.elim (hnew hi)

@[req "STA-7"] theorem replay_knowledge (p : Params) (dp : Dispatch.Params) (x : Dispatch.External)
    (w : World) :
    (step p dp x w .replay).dispatch.journal = w.dispatch.journal ∧
    (step p dp x w .replay).dispatch.memory = w.dispatch.journal := by
  exact ⟨rfl, rfl⟩

/-- Abstract current evidence alone never stands in for suspension validation. -/
@[req "STA-23"] theorem missing_validation (p : Params) (dp : Dispatch.Params) (w : World)
    (work : Work) (ev : Evidence) (a : Actor) (hp : p.validationRequired = true)
    (ha : actor p w work.who = some a) (hi : a.interrupted = true)
    (hv : a.validation = none) : eligible p dp w work ev = false := by
  simp [eligible, ha, validationCurrent, hp, hi, hv]

/-- Exact lookup supplies worker/session/incarnation equality, independently of approvals. -/
private theorem actor_exact (p : Params) (w : World) (who : Identity) (a : Actor)
    (hp : p.workerIdentity = true) (ha : actor p w who = some a) : a.who = who := by
  have hf := List.find?_some ha
  simpa [hp] using hf

@[req "STA-23"] theorem fenced_authority (p : Params) (w : World) (work : Work)
    (hf : p.endFence = true) (hw : p.workerIdentity = true)
    (h : work.who ∈ w.fenced) : authority p w work = false := by
  unfold authority
  split
  · rename_i a r ha hr
    have he := actor_exact p w work.who a hw ha
    simp [hf, he, h]
  · simp

@[req "STA-23"] theorem fenced_eligibility (p : Params) (dp : Dispatch.Params) (w : World)
    (work : Work) (ev : Evidence) (hf : p.endFence = true) (hw : p.workerIdentity = true)
    (h : work.who ∈ w.fenced) : eligible p dp w work ev = false := by
  simp [eligible, fenced_authority p w work hf hw h]

@[req "STA-23"] theorem ended_no_send (p : Params) (dp : Dispatch.Params) (x : Dispatch.External)
    (w : World) (work : Work) (ev : Evidence) (ok : Bool)
    (hf : p.endFence = true) (hw : p.workerIdentity = true) (h : work.who ∈ w.fenced) :
    (step p dp x w (.request work ev ok)).dispatch = w.dispatch := by
  have h' := boundary_fence p w work ev work.who h
  simp only [step, fenced_eligibility p dp _ work ev hf hw h', Bool.false_eq_true, if_false]
  exact boundary_dispatch p w work ev

@[req "STA-23"] theorem ended_no_publication (p : Params) (dp : Dispatch.Params)
    (x : Dispatch.External) (w : World) (origin : Issued) (work : Work) (ev : Evidence)
    (hf : p.endFence = true) (hw : p.workerIdentity = true) (h : work.who ∈ w.fenced) :
    (step p dp x w (.publish origin work ev)).published = w.published := by
  have h' := boundary_fence p w work ev work.who h
  have he := fenced_eligibility p dp (boundary p w work ev) work ev hf hw h'
  have hb : (boundary p w work ev).published = w.published := by
    unfold boundary assess
    repeat first | split | rfl
  simp [step, publishable, he, hb]

@[req "STA-4"] theorem record_no_send (p : Params) (dp : Dispatch.Params) (x : Dispatch.External)
    (w : World) (r : Record) (c : Custody) :
    (step p dp x w (.record r c)).dispatch.dispatched = w.dispatch.dispatched := by
  simp only [step]
  split
  · cases r <;> simp only [Record.event, Dispatch.step, Dispatch.append]
    all_goals repeat first | split | rfl
  · rfl

@[req "STA-23"] theorem continuation_not_issued (p : Params) (dp : Dispatch.Params)
    (w : World) (work : Work) (ev : Evidence) (hp : p.unsentContinuation = true)
    (h : eligible p dp w work ev = true) :
    (w.issued.any fun i => i.work.request.call == work.request.call) = false ∧
    (w.dispatch.dispatched.any fun i => i.call == work.request.call) = false := by
  simp only [eligible, Bool.and_eq_true] at h
  have hf := h.1
  simpa [notPreviouslyIssued, hp] using hf

/-- Publication-to-origin correlation is an explicit convention of this narrow interface. -/
@[req "STA-23"] theorem publication_origin (p : Params) (dp : Dispatch.Params) (w : World)
    (origin : Issued) (work : Work) (ev : Evidence) (hp : p.publicationOrigin = true)
    (hd : p.publicationDispatch = true) (h : publishable p dp w origin work ev = true) :
    origin.work.who = work.who ∧ authority p w origin.work = true ∧
    eligible p dp w work ev = true ∧
    ∃ i, Dispatch.admit dp w.dispatch.memory work.request work.approval = .dispatched i := by
  unfold publishable at h
  simp only [hd, Bool.not_true, Bool.false_or] at h
  cases ha : Dispatch.admit dp w.dispatch.memory work.request work.approval with
  | refused r => simp [ha] at h
  | dispatched i =>
    simp only [ha, Bool.and_true, hp, Bool.not_true, Bool.false_or, Bool.and_eq_true, beq_iff_eq] at h
    exact ⟨h.1.2.1.1, h.1.2.1.2, h.2, i, rfl⟩

/-- The next call is distinct from its issued origin even if other publication guards weaken. -/
@[req "STA-23"] theorem publication_distinct_call (p : Params) (dp : Dispatch.Params)
    (w : World) (origin : Issued) (work : Work) (ev : Evidence)
    (hp : p.unsentContinuation = true) (h : publishable p dp w origin work ev = true) :
    origin.work.request.call ≠ work.request.call := by
  simp only [publishable, Bool.and_eq_true] at h
  have hm : origin ∈ w.issued := by simpa using h.1.1.1
  have hf := continuation_not_issued p dp w work ev hp h.1.2
  intro hc
  have hs : (w.issued.any fun i => i.work.request.call == work.request.call) = true :=
    List.any_eq_true.mpr ⟨origin, hm, by simp [hc]⟩
  rw [hf.1] at hs
  cases hs

/-! Named finite histories, decided in the kernel; no exhaustive browser alphabet. -/

def alice : Identity := ⟨1, 10, Dispatch.sessionA⟩
def bob : Identity := ⟨2, 20, Dispatch.sessionB⟩
def sibling : Identity := ⟨3, 30, Dispatch.sessionC⟩
def candidateA : Candidate := ⟨alice, [Dispatch.entryA], .independent⟩
def candidateB : Candidate := ⟨bob, [Dispatch.entryA], .independent⟩
def candidateSibling : Candidate := ⟨sibling, [Dispatch.entryB], .independent⟩
def initial : World := { dispatch := Dispatch.init }
def ready : Evidence := ⟨true, true, true, none⟩
def custody : Custody := ⟨true, true, true⟩
def readA : Work := ⟨alice, Dispatch.readRequest, Dispatch.approvalRead⟩
def execA : Work := ⟨alice, Dispatch.execRequest, Dispatch.approvalExec⟩
def resetA : Work := ⟨alice, Dispatch.resetRequest1, Dispatch.approvalReset⟩
def execB : Work := ⟨bob, Dispatch.execRequestB, Dispatch.approvalExecB⟩
def readB : Work := ⟨bob, { Dispatch.readRequest with call := 113, session := Dispatch.sessionB }, Dispatch.approvalReadB⟩
def readSibling : Work := ⟨sibling, { Dispatch.readRequest with target := .entry Dispatch.entryB, call := 114, session := Dispatch.sessionC }, ⟨Dispatch.sessionC, Dispatch.factsRead, none⟩⟩
def nextReadA : Work := ⟨alice, { Dispatch.readRequest with call := 115 }, Dispatch.approvalRead⟩
def originalRead : Issued := ⟨readA, Dispatch.machineA⟩
def originalReset : Issued := ⟨resetA, Dispatch.machineA⟩
def startEvents : List Event := [.lifecycle (.unlock true), .lifecycle (.admit candidateA true)]

def result (events : List Event) (p : Params := current) (dp : Dispatch.Params := Dispatch.current) : World :=
  run p dp Dispatch.farDone.external initial events

def sent (w : World) (call : Dispatch.CallId) : Bool := w.dispatch.dispatched.any (·.call == call)

/-- The actor remains Alice; request and approval agree with each other on Bob. -/
def borrowedSessionWork : Work := { readB with who := alice }
def borrowedSessionEvents : List Event := startEvents ++ [.request borrowedSessionWork ready true]
@[req "SEC-4"] theorem borrowed_session_refused :
    (actor current (result startEvents) alice).map (·.bound) = some [Dispatch.entryA] ∧
    Dispatch.admit Dispatch.current (result startEvents).dispatch.memory
      borrowedSessionWork.request borrowedSessionWork.approval =
        .dispatched (Dispatch.intentOf borrowedSessionWork.request Dispatch.machineA borrowedSessionWork.approval) ∧
    sent (result borrowedSessionEvents) borrowedSessionWork.request.call = false := by decide +kernel
@[req "SEC-4"] theorem borrowed_session_without_check :
    sent (result borrowedSessionEvents { current with requestSession := false }) borrowedSessionWork.request.call = true := by decide +kernel

/-- The other approved entry is already mapped in the shared starting journal. -/
def unboundWork : Work := { readA with request := { readA.request with target := .index Dispatch.index2 } }
def unboundEvents : List Event := startEvents ++ [.request unboundWork ready true]
@[req "SEC-1"] theorem unbound_entry_refused :
    Dispatch.resolve (result startEvents).dispatch.memory unboundWork.request.target = some Dispatch.machineB ∧
    (actor current (result startEvents) alice).map (·.bound) = some [Dispatch.entryA] ∧
    sent (result unboundEvents) unboundWork.request.call = false := by decide +kernel
@[req "SEC-1"] theorem unbound_entry_without_check :
    sent (result unboundEvents { current with machineMembership := false }) unboundWork.request.call = true := by decide +kernel

def matchingRequestEvents : List Event := startEvents ++ [.request readA ready true]
@[req "SEC-4"] theorem matching_session_bound_entry_progress :
    sent (result matchingRequestEvents) readA.request.call = true := by decide +kernel

/-- Both admissions succeed on disjoint entries before any growth attempt. -/
def disjointStart : List Event := startEvents ++ [
  .lifecycle (.admit { candidateB with bound := [Dispatch.entryB] } true)]
def contestedGrowthEvents : List Event := disjointStart ++ [
  .lifecycle (.grow bob Dispatch.entryA true), .request readB ready true]
@[req "SEC-1"] theorem live_entry_growth_refused :
    (actor current (result disjointStart) alice).map (·.bound) = some [Dispatch.entryA] ∧
    (actor current (result disjointStart) bob).map (·.bound) = some [Dispatch.entryB] ∧
    (result disjointStart).fenced = [] ∧
    (actor current (result contestedGrowthEvents) bob).map (·.bound) = some [Dispatch.entryB] ∧
    sent (result contestedGrowthEvents) readB.request.call = false := by decide +kernel
@[req "SEC-1"] theorem live_entry_growth_without_check :
    (actor { current with growthExclusive := false }
      (result contestedGrowthEvents { current with growthExclusive := false }) bob).map (·.bound) =
        some [Dispatch.entryA, Dispatch.entryB] ∧
    sent (result contestedGrowthEvents { current with growthExclusive := false }) readB.request.call = true := by decide +kernel

/-- With the same live actors, a further authorized binding to a free entry permits work. -/
def freeGrowthWork : Work := { readB with request := { readB.request with target := .entry 3 } }
def freeGrowthEvents : List Event := disjointStart ++ [
  .lifecycle (.grow bob 3 true), .request freeGrowthWork ready true]
@[req "SEC-1"] theorem free_entry_growth_progress :
    (actor current (result freeGrowthEvents) bob).map (·.bound) = some [3, Dispatch.entryB] ∧
    sent (result freeGrowthEvents) freeGrowthWork.request.call = true := by decide +kernel

/-- Lock stops the old execution incarnation and returns locked: the dormant session keeps its
machines, and its bound set grows only after it resumes. -/
def pausedGrowthWho : Identity := { alice with incarnation := 100, worker := 100 }
def pausedGrowthWork : Work := { readA with who := pausedGrowthWho, request := { readA.request with target := .entry 3 } }
def pausedGrowthEvents (afterResume : Bool) : List Event := startEvents ++ [.lifecycle (.pause .lock)] ++
  (if afterResume then [] else [.lifecycle (.grow alice 3 true)]) ++
  [.lifecycle (.unlock true), .lifecycle (.resume alice 100 true)] ++
  (if afterResume then [.lifecycle (.grow pausedGrowthWork.who 3 true)] else []) ++
  [.lifecycle (.validate pausedGrowthWork ready), .request pausedGrowthWork ready true]
@[req "STA-23"] theorem paused_growth_refused :
    (actor current (result (pausedGrowthEvents false)) pausedGrowthWork.who).map (·.bound) = some [Dispatch.entryA] ∧
    sent (result (pausedGrowthEvents false)) pausedGrowthWork.request.call = false := by decide +kernel
@[req "STA-23"] theorem paused_growth_without_check :
    (actor { current with growthAvailable := false }
      (result (pausedGrowthEvents false) { current with growthAvailable := false }) pausedGrowthWork.who).map (·.bound) =
        some [3, Dispatch.entryA] ∧
    sent (result (pausedGrowthEvents false) { current with growthAvailable := false }) pausedGrowthWork.request.call = true := by decide +kernel
/-- In the model, `.unlock` leaves the dormant session paused, and the `.grow` guard refuses a paused
session until it resumes. -/
def unlockedPausedGrowthEvents : List Event := startEvents ++
  [.lifecycle (.pause .lock), .lifecycle (.unlock true), .lifecycle (.grow alice 3 true),
    .lifecycle (.resume alice 100 true), .lifecycle (.validate pausedGrowthWork ready), .request pausedGrowthWork ready true]
@[req "STA-23"] theorem unlocked_paused_growth_refused :
    (actor current (result unlockedPausedGrowthEvents) pausedGrowthWork.who).map (·.bound) = some [Dispatch.entryA] ∧
    sent (result unlockedPausedGrowthEvents) pausedGrowthWork.request.call = false := by decide +kernel
@[req "STA-23"] theorem resumed_growth_progress :
    (actor current (result (pausedGrowthEvents true)) pausedGrowthWork.who).map (·.bound) = some [3, Dispatch.entryA] ∧
    sent (result (pausedGrowthEvents true)) pausedGrowthWork.request.call = true := by decide +kernel

def endEvents : List Event := startEvents ++ [.lifecycle (.endSession alice .explicit), .request readA ready true]
@[req "STA-23"] theorem ended_refused :
    sent (result endEvents) readA.request.call = false ∧
    Dispatch.admit Dispatch.current (result endEvents).dispatch.memory readA.request readA.approval =
      .dispatched (Dispatch.intentOf readA.request Dispatch.machineA readA.approval) := by decide +kernel
@[req "STA-23"] theorem ended_admitted_without_fence :
    sent (result endEvents { current with endFence := false }) readA.request.call = true := by decide +kernel

def lateEvents : List Event := startEvents ++ [.request readA ready true,
  .lifecycle (.endSession alice .explicit), .publish originalRead nextReadA ready]
@[req "STA-23"] theorem late_publication_refused : (result lateEvents).published = [] := by decide +kernel
@[req "STA-23"] theorem late_publication_without_fence :
    (result lateEvents { current with endFence := false }).published = [originalRead] := by decide +kernel

def transferEvents : List Event := startEvents ++ [.request readA ready true,
  .lifecycle (.endSession alice .explicit), .lifecycle (.admit candidateB true), .publish originalRead readB ready]
@[req "STA-23"] theorem stale_origin_refused : (result transferEvents).published = [] := by decide +kernel
@[req "STA-23"] theorem stale_origin_transferred_without_guard :
    (result transferEvents { current with publicationOrigin := false }).published = [originalRead] := by decide +kernel

def workerEvents : List Event := startEvents ++ [.request { readA with who := { alice with worker := 99 } } ready true]
@[req "STA-23"] theorem stale_worker_refused : sent (result workerEvents) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem stale_worker_without_guard :
    sent (result workerEvents { current with workerIdentity := false }) readA.request.call = true := by decide +kernel

def hideEvents : List Event := startEvents ++ [.lifecycle .hide, .request readA ready true, .lifecycle .visible]
@[req "STA-23"] theorem hidden_progress : sent (result hideEvents) readA.request.call = true := by decide +kernel
@[req "STA-23"] theorem hide_ends_without_preservation :
    sent (result hideEvents { current with hidePreserves := false }) readA.request.call = false := by decide +kernel

def pendingEvents : List Event := startEvents ++ [.lifecycle .hide,
  .request { readA with approval := Dispatch.approvalReadB } ready true]
@[req "SEC-4"] theorem hidden_cross_session_approval_refused :
    sent (result pendingEvents) readA.request.call = false := by decide +kernel

def suspensionEvents : List Event := startEvents ++ [.lifecycle (.suspend alice), .request readA ready true]
@[req "STA-23"] theorem suspension_refused : sent (result suspensionEvents) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem suspension_without_validation_guard :
    sent (result suspensionEvents { current with validationRequired := false }) readA.request.call = true := by decide +kernel

def validatedEvents : List Event := startEvents ++ [.lifecycle (.suspend alice),
  .lifecycle (.validate readA ready), .request readA ready true,
  .lifecycle (.validate execA ready), .publish originalRead execA ready]
@[req "STA-23"] theorem validated_progress_and_publication :
    sent (result validatedEvents) readA.request.call = true ∧
    (result validatedEvents).published = [originalRead] := by decide +kernel

def wrongContinuationEvents : List Event := startEvents ++ [.lifecycle (.suspend alice),
  .lifecycle (.validate readA ready), .request execA ready true]
@[req "STA-23"] theorem wrong_continuation_refused : sent (result wrongContinuationEvents) execA.request.call = false := by decide +kernel
@[req "STA-23"] theorem wrong_continuation_without_match :
    sent (result wrongContinuationEvents { current with validationMatches := false }) execA.request.call = true := by decide +kernel

def invalidatedEvents : List Event := startEvents ++ [.lifecycle (.suspend alice),
  .lifecycle (.validate readA ready), .lifecycle (.invalidate alice), .request readA ready true,
  .lifecycle (.validate readA ready), .request readA ready true]
@[req "STA-23"] theorem invalidation_requires_new_validation :
    sent (result (invalidatedEvents.take 6)) readA.request.call = false ∧
    sent (result invalidatedEvents) readA.request.call = true := by decide +kernel

def unsafeEvents : List Event := startEvents ++ [.lifecycle (.suspend alice),
  .lifecycle (.validate readA { ready with safeUnsent := false }), .request readA ready true]
@[req "STA-23"] theorem unsafe_validation_refused : sent (result unsafeEvents) readA.request.call = false := by decide +kernel

def endedValidationEvents : List Event := startEvents ++ [.lifecycle (.endSession alice .explicit),
  .lifecycle (.validate readA ready), .lifecycle (.unlock true), .lifecycle (.admit candidateA true), .request readA ready true]
@[req "STA-23"] theorem validation_and_readmission_cannot_revive :
    sent (result endedValidationEvents) readA.request.call = false ∧
    (result endedValidationEvents).fenced.contains alice = true := by decide +kernel

def growthEvents : List Event := startEvents ++ [.lifecycle (.suspend alice),
  .lifecycle (.validate readA ready), .lifecycle (.grow alice Dispatch.entryB true), .request readA ready true]
@[req "SEC-1"] theorem bound_growth_preserves_applicable_approval : sent (result growthEvents) readA.request.call = true := by decide +kernel

def doubleBindingEvents : List Event := startEvents ++ [.lifecycle (.admit candidateB true), .request readB ready true]
@[req "SEC-1"] theorem live_predecessor_refuses_successor : sent (result doubleBindingEvents) readB.request.call = false := by decide +kernel
@[req "SEC-1"] theorem live_predecessor_without_exclusion :
    sent (result doubleBindingEvents { current with exclusiveBinding := false }) readB.request.call = true := by decide +kernel

def isolationEvents : List Event := startEvents ++ [.lifecycle (.admit candidateSibling true),
  .lifecycle (.endSession alice .explicit), .request readSibling ready true]
@[req "STA-23"] theorem individual_end_keeps_sibling : sent (result isolationEvents) readSibling.request.call = true := by decide +kernel
@[req "STA-23"] theorem individual_end_global_without_guard :
    sent (result isolationEvents { current with individualOnly := false }) readSibling.request.call = false := by decide +kernel

def ceremonyEvents : List Event := startEvents ++ [.lifecycle .enterCeremony, .lifecycle .hide]
@[req "STA-23"] theorem ceremony_hide_locks :
    (result ceremonyEvents).locked = true ∧ (result ceremonyEvents).ceremonyOwed = true := by decide +kernel
@[req "STA-23"] theorem ceremony_hide_without_lock :
    (result ceremonyEvents { current with ceremonyHideLocks := false }).locked = false := by decide +kernel

def ceremonyResumeEvents : List Event := startEvents ++ [.lifecycle .enterCeremony,
  .lifecycle (.finishCeremony .skipped true), .lifecycle (.resume alice 100 true),
  .lifecycle (.validate { readA with who := { alice with incarnation := 100, worker := 100 } } ready),
  .request { readA with who := { alice with incarnation := 100, worker := 100 } } ready true]
@[req "STA-23"] theorem ceremony_pause_preserves_session :
    sent (result ceremonyResumeEvents) readA.request.call = true ∧
    (result ceremonyResumeEvents).ended = [] := by decide +kernel

def resumedAlice : Identity := { alice with incarnation := 100, worker := 100 }
def resumedRead : Work := { readA with who := resumedAlice }
def pausePrefix (r : PauseReason) : List Event := startEvents ++ [
  .lifecycle (.pause r), .lifecycle (.unlock true),
  .lifecycle (.resume alice resumedAlice.incarnation true)]
def resumeEvents (r : PauseReason) : List Event := pausePrefix r ++ [
  .lifecycle (.validate resumedRead ready), .request resumedRead ready true]
@[req "STA-23"] theorem eligible_same_session_resume :
    ([PauseReason.lock, .pagehide, .reload, .shutdown, .discard].all fun r =>
      sent (result (resumeEvents r)) readA.request.call) = true := by decide +kernel
def staleResumeEvents : List Event := pausePrefix .reload ++ [
  .lifecycle (.validate readA ready), .request readA ready true]
@[req "STA-23"] theorem incarnation_fence_after_resume :
    sent (result staleResumeEvents) readA.request.call = false ∧
    sent (result (startEvents ++ [.replay, .lifecycle (.unlock true),
      .lifecycle (.validate readA ready), .request readA ready true])) readA.request.call = false := by decide +kernel
def pausedEvents : List Event := startEvents ++ [.lifecycle (.pause .lock),
  .lifecycle (.unlock true), .lifecycle (.validate readA ready), .request readA ready true]
@[req "STA-23"] theorem pause_requires_resume :
    sent (result pausedEvents) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem pause_without_resume_guard :
    sent (result pausedEvents { current with pauseRequired := false }) readA.request.call = true := by decide +kernel
def endedResumeEvents : List Event := startEvents ++ [.lifecycle (.endSession alice .explicit),
  .lifecycle (.resume alice resumedAlice.incarnation true), .lifecycle (.validate resumedRead ready), .request resumedRead ready true]
@[req "STA-23"] theorem end_cannot_resume :
    sent (result endedResumeEvents) readA.request.call = false ∧
    actor current (result endedResumeEvents) resumedAlice = none := by decide +kernel
@[req "STA-23"] theorem end_resumes_without_fence :
    sent (result endedResumeEvents { current with endFence := false }) readA.request.call = true := by decide +kernel

/-- Shared seam: Robot reset, lost response, predecessor end/replay, legitimate successor,
processed interruption and matching operation-specific validation. -/
def seamPrefix : List Event := startEvents ++ [.request resetA ready true,
  .lifecycle (.endSession alice .explicit), .replay, .lifecycle (.unlock true),
  .lifecycle (.admit candidateB true), .lifecycle (.suspend bob), .lifecycle (.validate execB ready)]
def seamEvents : List Event := seamPrefix ++ [.request execB ready true]
@[req "STA-24"] theorem successor_barrier_refused :
    eligible current Dispatch.current (result seamPrefix) execB ready = true ∧
    sent (result seamEvents) execB.request.call = false ∧
    (result seamEvents).fenced.contains alice = true := by decide +kernel
@[req "STA-24"] theorem successor_barrier_without_entry_key :
    sent (result seamEvents current { Dispatch.current with resourceKey := .call }) execB.request.call = true := by decide +kernel

/-- The query is an ordinary successor request; receiving its observation is a separate event.
A failed terminal append leaves the barrier, then matching validation still cannot waive it. -/
def settlementEvents (ok : Bool) : List Event := seamPrefix ++ [
  .lifecycle (.validate readB ready), .request readB ready true,
  .record (.observation .adapterRead Dispatch.machineA .reset ok) custody,
  .lifecycle (.validate execB ready), .request execB ready true]
@[req "STA-3"] theorem failed_confirmation_keeps_barrier :
    sent (result (settlementEvents false)) readB.request.call = true ∧
    sent (result (settlementEvents false)) execB.request.call = false := by decide +kernel
@[req "STA-3"] theorem failed_confirmation_without_durability :
    sent (result (settlementEvents false) current { Dispatch.current with durableBeforeApply := false }) execB.request.call = true := by decide +kernel
@[req "STA-24"] theorem durable_confirmation_opens_successor :
    sent (result (settlementEvents true)) execB.request.call = true ∧
    (result (settlementEvents true)).fenced.contains alice = true := by decide +kernel
@[req "STA-8"] theorem validation_preserves_uncertainty :
    Dispatch.unresolved Dispatch.current (result seamPrefix).dispatch.memory Dispatch.machineA = [resetA.request.call] := by decide +kernel
@[req "STA-8"] theorem fabricated_validation_settles_without_guard :
    Dispatch.unresolved Dispatch.current (result seamPrefix { current with preserveKnowledge := false }).dispatch.memory Dispatch.machineA = [] := by decide +kernel

def historicalEvents : List Event := startEvents ++ [.request resetA ready true,
  .request readA ready true, .lifecycle (.endSession alice .explicit),
  .record (.observation .adapterRead Dispatch.machineA .reset true) custody,
  .publish originalReset nextReadA ready]
@[req "STA-23"] theorem historical_record_without_revival :
    Dispatch.unresolved Dispatch.current (result historicalEvents).dispatch.memory Dispatch.machineA = [] ∧
    (result historicalEvents).published = [] ∧ (result historicalEvents).fenced.contains alice = true := by decide +kernel

def recordCustodyEvents (c : Custody) : List Event := startEvents ++ [.request resetA ready true,
  .lifecycle (.endSession alice .explicit), .record (.observation .adapterRead Dispatch.machineA .reset true) c]
def noCustodyEvents : List Event := recordCustodyEvents { custody with writerOwnsStore := false }
@[req "STA-1"] theorem historical_record_requires_custody :
    Dispatch.unresolved Dispatch.current (result noCustodyEvents).dispatch.memory Dispatch.machineA = [resetA.request.call] := by decide +kernel
@[req "STA-23"] theorem historical_record_requires_authorization :
    Dispatch.unresolved Dispatch.current (result (recordCustodyEvents { custody with authorized := false })).dispatch.memory Dispatch.machineA = [resetA.request.call] := by decide +kernel
@[req "STA-23"] theorem historical_record_requires_store_access :
    Dispatch.unresolved Dispatch.current (result (recordCustodyEvents { custody with storeAccess := false })).dispatch.memory Dispatch.machineA = [resetA.request.call] := by decide +kernel

def originalLimits : Limits := ⟨1, 1, 1, 1⟩
def validKey : KeyEvidence := ⟨originalLimits, .valid, true, true, true, true, true, true, true, true, true⟩
/-- Coherent terminal/uncertain evidence for the named histories. -/
def keyEvidenceFor : KeyState → KeyEvidence
  | .valid => validKey
  | .expired => { validKey with state := .expired, upperBeforeExpiry := false }
  | .exhausted => { validKey with state := .exhausted, allowanceEstablished := false }
  | .uncertain => { validKey with state := .uncertain, authenticatedInterval := false, monotonicContinuity := false, upperBeforeExpiry := false }
  | .incompatible => { validKey with state := .incompatible, issuerAcceptance := false }
def keyReady : Evidence := { ready with key := some validKey }
def procuredStart : List Event := [.lifecycle (.unlock true),
  .lifecycle (.admit { candidateA with path := .procured originalLimits } true),
  .lifecycle (.assessKey alice validKey), .lifecycle (.sealTerminal alice true)]
/-- Valid assessment uses the original tuple; only the later request presents a changed cap. -/
def changedRequestKey : KeyEvidence := { validKey with original := { originalLimits with cap := 2 } }
def changedRequestLimitsEvents : List Event := procuredStart ++ [
  .request readA { keyReady with key := some changedRequestKey } true]
@[req "ARC-31a"] theorem request_original_limits_refused :
    (actor current (result procuredStart) alice).map (·.keyWithheld) = some false ∧
    changedRequestKey.valid = true ∧
    sent (result changedRequestLimitsEvents) readA.request.call = false := by decide +kernel
@[req "ARC-31a"] theorem request_original_limits_without_check :
    sent (result changedRequestLimitsEvents { current with requestOriginal := false }) readA.request.call = true := by decide +kernel

def originalRequestLimitsEvents : List Event := procuredStart ++ [.request readA keyReady true]
@[req "ARC-31a"] theorem request_unchanged_limits_progress :
    sent (result originalRequestLimitsEvents) readA.request.call = true := by decide +kernel

def expiryEvents : List Event := procuredStart ++ [.request execA { keyReady with key := some (keyEvidenceFor .expired) } true]
@[req "ARC-31a"] theorem expired_session_ssh_refused :
    sent (result expiryEvents) execA.request.call = false ∧ (result expiryEvents).fenced.contains alice = true := by decide +kernel
@[req "ARC-31a"] theorem expired_session_ssh_without_gate :
    sent (result expiryEvents { current with procuredEligibility := false }) execA.request.call = true := by decide +kernel

def expiryIsolationEvents : List Event := procuredStart ++ [.lifecycle (.admit candidateSibling true),
  .lifecycle (.assessKey alice (keyEvidenceFor .expired)), .request readSibling ready true]
@[req "ARC-31a"] theorem procured_expiry_keeps_independent_session : sent (result expiryIsolationEvents) readSibling.request.call = true := by decide +kernel
@[req "ARC-31a"] theorem expiry_spreads_without_scope :
    sent (result expiryIsolationEvents { current with scopedExpiry := false }) readSibling.request.call = false := by decide +kernel

def repairEvents : List Event := procuredStart ++ [
  .lifecycle (.suspend alice), .lifecycle (.assessKey alice (keyEvidenceFor .uncertain)),
  .lifecycle (.validate readA keyReady), .request readA keyReady true,
  .lifecycle (.assessKey alice validKey), .lifecycle (.validate readA keyReady), .request readA keyReady true]
@[req "ARC-31a"] theorem uncertain_clock_then_unchanged_repair :
    sent (result (repairEvents.take 8)) readA.request.call = false ∧
    sent (result repairEvents) readA.request.call = true := by decide +kernel

def changedLimitsEvents : List Event := procuredStart ++ [
  .lifecycle (.assessKey alice { validKey with original := { originalLimits with expiry := 2 } }), .request readA keyReady true]
@[req "ARC-31a"] theorem repair_cannot_renew : sent (result changedLimitsEvents) readA.request.call = false := by decide +kernel

def clockCheckEvents (anchor pair : Bool) : List Event := procuredStart ++ [
  .request readA { keyReady with key := some { validKey with anchorCheck := anchor, pairCheck := pair } } true]
@[req "ARC-31a"] theorem both_clock_discrepancies_required :
    sent (result (clockCheckEvents false true)) readA.request.call = false ∧
    sent (result (clockCheckEvents true false)) readA.request.call = false ∧
    sent (result (clockCheckEvents true true)) readA.request.call = true := by decide +kernel

def capEvents : List Event := procuredStart ++ [.lifecycle (.assessKey alice (keyEvidenceFor .exhausted)),
  .lifecycle (.assessKey alice validKey), .request readA keyReady true]
@[req "ARC-31a"] theorem cap_end_cannot_repair :
    sent (result capEvents) readA.request.call = false ∧ (result capEvents).fenced.contains alice = true := by decide +kernel

def incompatibleEvents : List Event := procuredStart ++ [.lifecycle (.assessKey alice (keyEvidenceFor .incompatible)), .request readA keyReady true]
@[req "ARC-31a"] theorem incompatible_acceptance_withheld : sent (result incompatibleEvents) readA.request.call = false := by decide +kernel

def independentExpiryEvents : List Event := startEvents ++ [.lifecycle (.assessKey alice (keyEvidenceFor .expired)), .request readA ready true]
@[req "ARC-31a"] theorem independent_has_no_procured_deadline : sent (result independentExpiryEvents) readA.request.call = true := by decide +kernel

def inferenceEvents : List Event := startEvents ++ [
  .request ⟨alice, Dispatch.inferenceRequest1, Dispatch.approvalInference⟩ ready true,
  .request ⟨alice, Dispatch.inferenceRequest2, Dispatch.approvalInference⟩ ready true]
@[req "STA-24"] theorem inference_uncertainty_not_machine_barrier :
    sent (result inferenceEvents) Dispatch.inferenceRequest2.call = true := by decide +kernel

def readinessEvents : List Event := startEvents ++ [.request readA { ready with connected := false } true,
  .request readA { ready with scanReady := false } true]
@[req "STA-23"] theorem current_connection_and_scan_required :
    sent (result readinessEvents) readA.request.call = false := by decide +kernel

def holdChangeBeforeRetryEvents : List Event := seamPrefix ++ [.lifecycle (.validate readB ready), .request readB ready true,
  .lifecycle (.validate execB ready), .record (.observation .adapterRead Dispatch.machineA .reset true) custody,
  .request execB ready true]
def holdChangeEvents : List Event := holdChangeBeforeRetryEvents ++ [
  .lifecycle (.validate execB ready), .request execB ready true]
@[req "STA-23"] theorem changed_dispatch_requires_current_validation :
    sent (result holdChangeBeforeRetryEvents) execB.request.call = false ∧
    sent (result holdChangeEvents) execB.request.call = true := by decide +kernel

def failedIntentEvents : List Event := startEvents ++ [.request readA ready false]
@[req "STA-3"] theorem ordinary_append_failure_refused : sent (result failedIntentEvents) readA.request.call = false := by decide +kernel
@[req "STA-3"] theorem ordinary_append_failure_without_durability :
    sent (result failedIntentEvents current { Dispatch.current with durableBeforeApply := false }) readA.request.call = true := by decide +kernel

def validationEndEvents (state : KeyState) : List Event := procuredStart ++ [
  .lifecycle (.suspend alice),
  .lifecycle (.validate readA { keyReady with key := some (keyEvidenceFor state) }),
  .lifecycle (.validate readA keyReady), .request readA keyReady true]
@[req "ARC-31a"] theorem validation_terminal_ends :
    ([KeyState.expired, .exhausted].all fun state =>
      !sent (result (validationEndEvents state)) readA.request.call &&
      (result (validationEndEvents state)).fenced.contains alice) = true := by decide +kernel
@[req "ARC-31a"] theorem validation_terminal_without_guard :
    ([KeyState.expired, .exhausted].all fun state =>
      sent (result (validationEndEvents state) { current with validationTerminal := false }) readA.request.call) = true := by decide +kernel

def originalReadB : Issued := ⟨readB, Dispatch.machineA⟩
def publicationBarrierEvents : List Event := seamPrefix ++ [
  .lifecycle (.validate readB ready), .request readB ready true,
  .lifecycle (.validate execB ready), .publish originalReadB execB ready]
@[req "STA-24"] theorem publication_barrier_refused :
    (result publicationBarrierEvents).published = [] := by decide +kernel
@[req "STA-24"] theorem publication_barrier_without_dispatch :
    (result publicationBarrierEvents { current with publicationDispatch := false }).published = [originalReadB] := by decide +kernel

def publicationReleasedEvents : List Event := publicationBarrierEvents ++ [
  .record (.observation .adapterRead Dispatch.machineA .reset true) custody,
  .lifecycle (.validate execB ready), .publish originalReadB execB ready]
@[req "STA-24"] theorem publication_after_durable_confirmation :
    (result publicationReleasedEvents).published = [originalReadB] := by decide +kernel

def unsafeBoundaryEvents : List Event := startEvents ++ [.lifecycle (.suspend alice),
  .lifecycle (.validate readA ready), .request readA { ready with safeUnsent := false } true]
@[req "STA-23"] theorem unsafe_boundary_refused : sent (result unsafeBoundaryEvents) readA.request.call = false := by decide +kernel

def issuedContinuationEvents : List Event := startEvents ++ [.request readA ready true,
  .lifecycle (.suspend alice), .lifecycle (.validate readA ready), .request readA ready true,
  .publish originalRead readA ready]
@[req "STA-23"] theorem issued_continuation_refused :
    ((result issuedContinuationEvents).dispatch.dispatched.filter fun i => i.call == readA.request.call).length = 1 ∧
    (result issuedContinuationEvents).published = [] := by decide +kernel
@[req "STA-23"] theorem issued_continuation_without_guard :
    ((result issuedContinuationEvents { current with unsentContinuation := false }).dispatch.dispatched.filter fun i => i.call == readA.request.call).length = 2 ∧
    (result issuedContinuationEvents { current with unsentContinuation := false }).published = [originalRead] := by decide +kernel

def sealedResumePrefix (sealed : Bool) : List Event := procuredStart.take 3 ++ [
  .lifecycle (.sealTerminal alice sealed), .lifecycle (.pause .reload),
  .lifecycle (.unlock true), .lifecycle (.resume alice resumedAlice.incarnation true),
  .lifecycle (.assessKey resumedAlice validKey),
  .lifecycle (.validate resumedRead keyReady)]
/-- A late terminal does not repair a key already lost at resume. -/
def lostSealEvents : List Event := sealedResumePrefix false ++ [
  .lifecycle (.sealTerminal resumedAlice true), .lifecycle (.validate resumedRead keyReady),
  .request resumedRead keyReady true]
@[req "ARC-31a"] theorem resume_without_sealed_terminal_withholds :
    sent (result lostSealEvents) readA.request.call = false := by decide +kernel
@[req "ARC-31a"] theorem resume_without_terminal_guard :
    sent (result lostSealEvents { current with resumeTerminal := false }) readA.request.call = true := by decide +kernel
@[req "ARC-31a"] theorem sealed_terminal_resume_progress :
    sent (result (sealedResumePrefix true ++ [.request resumedRead keyReady true])) readA.request.call = true := by decide +kernel
def lostUntilEndEvents : List Event := lostSealEvents ++ [
  .lifecycle (.sealTerminal resumedAlice true), .lifecycle (.assessKey resumedAlice validKey),
  .lifecycle (.validate resumedRead keyReady), .request resumedRead keyReady true,
  .lifecycle (.endSession resumedAlice .explicit), .lifecycle (.assessKey resumedAlice validKey),
  .request resumedRead keyReady true]
@[req "ARC-31a"] theorem lost_terminal_stays_withheld_until_end :
    sent (result lostUntilEndEvents) readA.request.call = false ∧
    (result lostUntilEndEvents).ended.contains alice.session = true := by decide +kernel

def initialWithoutTerminalEvents : List Event := procuredStart.take 3 ++ [
  .request ⟨alice, Dispatch.inferenceRequest1, Dispatch.approvalInference⟩ keyReady true]
@[req "ARC-31a"] theorem initial_without_terminal_refused :
    sent (result initialWithoutTerminalEvents) Dispatch.inferenceRequest1.call = false := by decide +kernel
@[req "ARC-31a"] theorem initial_without_terminal_guard :
    sent (result initialWithoutTerminalEvents { current with sealedTerminalRequired := false }) Dispatch.inferenceRequest1.call = true := by decide +kernel
def noTerminalResumeEvents : List Event := sealedResumePrefix false ++ [.request resumedRead keyReady true]
@[req "ARC-31a"] theorem no_terminal_resume_stays_held :
    sent (result noTerminalResumeEvents) readA.request.call = false := by decide +kernel

/-- Paid end causes require a procured path; only Replace is global. -/
def globalEvents (r : EndReason) : List Event :=
  let historyStart := match r with
    | .expiry => procuredStart ++ [.lifecycle (.assessKey alice (keyEvidenceFor .expired))]
    | .capExhaustion => procuredStart ++ [.lifecycle (.assessKey alice (keyEvidenceFor .exhausted))]
    | .replace => startEvents ++ [.lifecycle .replace]
    | .explicit | .abandon => startEvents ++ [.lifecycle (.endSession alice r)]
  historyStart ++ [.lifecycle .visible, .lifecycle (.unlock true), .request readA keyReady true]
@[req "STA-23"] theorem session_end_paths_fence :
    ([EndReason.explicit, .replace, .expiry, .capExhaustion, .abandon].all fun r =>
      !sent (result (globalEvents r)) readA.request.call) = true := by decide +kernel

def scopedEndEvents (r : EndReason) : List Event :=
  let historyStart := match r with
    | .expiry => procuredStart ++ [.lifecycle (.admit candidateSibling true),
        .lifecycle (.assessKey alice (keyEvidenceFor .expired))]
    | .capExhaustion => procuredStart ++ [.lifecycle (.admit candidateSibling true),
        .lifecycle (.assessKey alice (keyEvidenceFor .exhausted))]
    | _ => startEvents ++ [.lifecycle (.admit candidateSibling true), .lifecycle (.endSession alice r)]
  historyStart ++ [.request readSibling ready true]
@[req "STA-23"] theorem scoped_end_keeps_nonholders :
    ([EndReason.expiry, .capExhaustion, .abandon].all fun r =>
      sent (result (scopedEndEvents r)) readSibling.request.call) = true := by decide +kernel

/-! Correction witnesses: execution retirement never releases a session's bindings. -/

def twiceAlice : Identity := { alice with incarnation := 101, worker := 101 }
def twiceRead : Work := { readA with who := twiceAlice }
def overlapEvents : List Event := pausePrefix .reload ++ [
  .lifecycle (.pause .reload), .lifecycle (.unlock true),
  .lifecycle (.resume resumedAlice 100 true), .lifecycle (.admit candidateB true),
  .lifecycle (.resume resumedAlice 101 true), .lifecycle (.validate twiceRead ready),
  .request twiceRead ready true, .request readB ready true]
@[req "SEC-1"] theorem incarnation_retirement_keeps_binding :
    (result overlapEvents).ended = [] ∧
    sent (result overlapEvents) readA.request.call = true ∧
    sent (result overlapEvents) readB.request.call = false := by decide +kernel

def repeatedResumeEvents : List Event := pausePrefix .reload ++ [
  .lifecycle (.grow resumedAlice 3 true), .lifecycle (.resume resumedAlice 101 true),
  .lifecycle (.validate twiceRead ready), .request twiceRead ready true,
  .lifecycle (.admit candidateSibling true), .request readSibling ready true]
@[req "STA-23"] theorem repeated_resume_retains_authority :
    (actor current (result repeatedResumeEvents) twiceAlice).map (·.bound) = some [3, Dispatch.entryA] ∧
    (result repeatedResumeEvents).ended = [] ∧
    sent (result repeatedResumeEvents) readA.request.call = true ∧
    sent (result repeatedResumeEvents) readSibling.request.call = true := by decide +kernel

def reuseEvents : List Event := pausePrefix .reload ++ [
  .lifecycle (.resume resumedAlice 100 true), .lifecycle (.validate resumedRead ready),
  .request resumedRead ready true]
@[req "STA-23"] theorem self_resume_refused :
    sent (result reuseEvents) readA.request.call = true := by decide +kernel
@[req "STA-23"] theorem self_resume_fences_without_check :
    sent (result reuseEvents { current with executionFresh := false }) readA.request.call = false := by decide +kernel

def collisionEvents (inc : Nat) : List Event := disjointStart ++ [
  .lifecycle (.resume alice inc true),
  .lifecycle (.validate { readA with who := { alice with incarnation := inc, worker := inc } } ready),
  .request { readA with who := { alice with incarnation := inc, worker := inc } } ready true]
@[req "STA-23"] theorem execution_collision_refused :
    sent (result (collisionEvents 2)) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem execution_collision_without_check :
    sent (result (collisionEvents 2) { current with executionFresh := false }) readA.request.call = true := by decide +kernel

def retiredReuseEvents (inc : Nat := 1) : List Event := pausePrefix .reload ++ [
  .lifecycle (.resume resumedAlice inc true),
  .lifecycle (.validate { readA with who := { alice with incarnation := inc, worker := inc } } ready),
  .request { readA with who := { alice with incarnation := inc, worker := inc } } ready true]
@[req "STA-23"] theorem retired_execution_refused :
    sent (result (retiredReuseEvents 1)) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem retired_execution_without_check :
    sent (result (retiredReuseEvents 1) { current with executionFresh := false }) readA.request.call = true := by decide +kernel

def reusedCandidate : Candidate := { candidateB with who := { bob with incarnation := 1 }, bound := [Dispatch.entryB] }
def reusedAdmissionWork : Work := { readB with who := reusedCandidate.who, request := { readB.request with target := .entry Dispatch.entryB } }
def reusedAdmissionEvents : List Event := pausePrefix .reload ++ [
  .lifecycle (.admit reusedCandidate true), .request reusedAdmissionWork ready true]
@[req "SEC-1"] theorem retired_admission_refused :
    sent (result reusedAdmissionEvents) readB.request.call = false := by decide +kernel
@[req "SEC-1"] theorem retired_admission_without_check :
    sent (result reusedAdmissionEvents { current with executionFresh := false }) readB.request.call = true := by decide +kernel

/-- Arbitrary-state boundary probes: even an already fenced dormant execution retains its
binding. The transition checks do not assume such an input away. -/
def fencedDormant : World := { result (pausePrefix .reload) with fenced := [resumedAlice] }
def fromWorld (w : World) (events : List Event) (p : Params := current) : World :=
  run p Dispatch.current Dispatch.farDone.external w events
def fencedAdmissionEvents : List Event := [.lifecycle (.admit candidateB true), .request readB ready true]
@[req "SEC-1"] theorem fenced_binding_admission_refused :
    sent (fromWorld fencedDormant fencedAdmissionEvents) readB.request.call = false := by decide +kernel
@[req "SEC-1"] theorem fenced_binding_admission_without_check :
    sent (fromWorld fencedDormant fencedAdmissionEvents { current with bindingSessionLifetime := false }) readB.request.call = true := by decide +kernel
def fencedGrowthWorld : World := { result disjointStart with fenced := [alice] }
def fencedGrowthEvents : List Event := [.lifecycle (.grow bob Dispatch.entryA true), .request readB ready true]
@[req "SEC-1"] theorem fenced_binding_growth_refused :
    sent (fromWorld fencedGrowthWorld fencedGrowthEvents) readB.request.call = false := by decide +kernel
@[req "SEC-1"] theorem fenced_binding_growth_without_check :
    sent (fromWorld fencedGrowthWorld fencedGrowthEvents { current with bindingSessionLifetime := false }) readB.request.call = true := by decide +kernel

/-- No archived actor or exact execution fence can substitute for the durable session End. -/
def endedProjection : World := { result (startEvents ++ [.lifecycle (.endSession alice .explicit)]) with actors := [] }
def freshEndedEvents : List Event := [
  .lifecycle (.admit { candidateA with who := resumedAlice } true),
  .request resumedRead ready true]
@[req "STA-23"] theorem fresh_identity_end_refused :
    !endedProjection.fenced.contains resumedAlice ∧
    actor current (fromWorld endedProjection freshEndedEvents) resumedAlice = none ∧
    sent (fromWorld endedProjection freshEndedEvents) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem fresh_identity_without_session_end :
    sent (fromWorld endedProjection freshEndedEvents { current with endFence := false }) readA.request.call = true := by decide +kernel

def endedFreshActor : World := fromWorld endedProjection (freshEndedEvents.take 1) { current with endFence := false }
def freshEndedRequest : List Event := [.request resumedRead ready true]
@[req "STA-23"] theorem fresh_actor_end_authority_refused :
    !endedFreshActor.fenced.contains resumedAlice ∧
    sent (fromWorld endedFreshActor freshEndedRequest) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem fresh_actor_without_session_end :
    sent (fromWorld endedFreshActor freshEndedRequest { current with endFence := false }) readA.request.call = true := by decide +kernel

def unauthorizedResumeEvents : List Event := startEvents ++ [
  .lifecycle (.resume alice 100 false), .lifecycle (.validate resumedRead ready), .request resumedRead ready true]
@[req "STA-23"] theorem unauthorized_resume_refused :
    sent (result unauthorizedResumeEvents) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem unauthorized_resume_without_check :
    sent (result unauthorizedResumeEvents { current with resumeAuthorized := false }) readA.request.call = true := by decide +kernel
def lockedResumeEvents : List Event := startEvents ++ [
  .lifecycle (.pause .lock), .lifecycle (.resume alice 100 true), .lifecycle (.unlock true),
  .lifecycle (.validate resumedRead ready), .request resumedRead ready true]
@[req "STA-23"] theorem locked_resume_refused :
    sent (result lockedResumeEvents) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem locked_resume_without_check :
    sent (result lockedResumeEvents { current with resumeUnlocked := false }) readA.request.call = true := by decide +kernel

def unvalidatedResumeEvents : List Event := startEvents ++ [
  .lifecycle (.resume alice 100 true), .request resumedRead ready true]
@[req "STA-23"] theorem resume_validation_refused :
    sent (result unvalidatedResumeEvents) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem resume_without_validation_reset :
    sent (result unvalidatedResumeEvents { current with resumeValidation := false }) readA.request.call = true := by decide +kernel
def validatedResumeEvents : List Event := unvalidatedResumeEvents.take 3 ++ [
  .lifecycle (.validate resumedRead ready), .request resumedRead ready true,
  .publish ⟨resumedRead, Dispatch.machineA⟩ { nextReadA with who := resumedAlice } ready,
  .lifecycle (.validate { nextReadA with who := resumedAlice } ready),
  .publish ⟨resumedRead, Dispatch.machineA⟩ { nextReadA with who := resumedAlice } ready]
@[req "STA-23"] theorem fresh_resume_validation_progress :
    sent (result validatedResumeEvents) readA.request.call = true ∧
    (result (validatedResumeEvents.take 6)).published = [] ∧
    (result validatedResumeEvents).published.length = 1 := by decide +kernel

def lostAgainEvents (sealed : Bool) : List Event := sealedResumePrefix sealed ++ [
  .lifecycle (.sealTerminal resumedAlice true), .lifecycle (.pause .reload),
  .lifecycle (.unlock true), .lifecycle (.resume resumedAlice 101 true),
  .lifecycle (.assessKey twiceAlice validKey), .lifecycle (.validate twiceRead keyReady),
  .request twiceRead keyReady true]
@[req "ARC-31a"] theorem lost_key_second_resume_refused :
    sent (result (lostAgainEvents false)) readA.request.call = false := by decide +kernel
@[req "ARC-31a"] theorem lost_key_second_resume_without_latch :
    sent (result (lostAgainEvents false) { current with lostKeySticky := false }) readA.request.call = true := by decide +kernel
@[req "ARC-31a"] theorem sealed_key_repeated_resume_progress :
    sent (result (lostAgainEvents true)) readA.request.call = true := by decide +kernel

def interruptedCeremonyEvents (interruption : Event) : List Event := startEvents ++ [
  .lifecycle .enterCeremony, interruption, .lifecycle (.unlock true),
  .lifecycle (.resume alice 100 true), .lifecycle (.validate resumedRead ready),
  .request resumedRead ready true]
@[req "STA-23"] theorem interrupted_ceremony_refused :
    ([Event.lifecycle .hide, .replay].all fun e =>
      !sent (result (interruptedCeremonyEvents e)) readA.request.call) = true := by decide +kernel
@[req "STA-23"] theorem interrupted_ceremony_without_guard :
    ([Event.lifecycle .hide, .replay].all fun e =>
      sent (result (interruptedCeremonyEvents e) { current with ceremonyPending := false }) readA.request.call) = true := by decide +kernel
@[req "STA-23"] theorem ceremony_pause_paths_refused :
    ([PauseReason.lock, .pagehide, .reload, .shutdown, .discard].all fun r =>
      !sent (result (interruptedCeremonyEvents (.lifecycle (.pause r)))) readA.request.call) = true := by decide +kernel

def completedCeremonyEvents (choice : Completion) (ok : Bool) : List Event :=
  (interruptedCeremonyEvents .replay).take 5 ++ [
    .lifecycle .enterCeremony, .lifecycle (.finishCeremony choice ok),
    .replay, .lifecycle (.unlock true),
    .lifecycle (.resume alice 100 true), .lifecycle (.validate resumedRead ready),
    .request resumedRead ready true]
@[req "STA-23"] theorem completed_ceremony_progress :
    ([Completion.fullReentry true, .skipped].all fun c =>
      sent (result (completedCeremonyEvents c true)) readA.request.call) = true ∧
    (result (completedCeremonyEvents .skipped true)).ended = [] ∧
    (actor current (result (completedCeremonyEvents .skipped true)) resumedAlice).map (·.bound) = some [Dispatch.entryA] := by decide +kernel
@[req "STA-23"] theorem completed_ceremony_without_release :
    sent (result (completedCeremonyEvents .skipped true) { current with ceremonyRelease := false }) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem failed_ceremony_append_refused :
    (result (completedCeremonyEvents .skipped false)).ceremonyOwed = true ∧
    sent (result (completedCeremonyEvents .skipped false)) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem failed_ceremony_append_without_guard :
    sent (result (completedCeremonyEvents .skipped false) { current with ceremonyAppend := false }) readA.request.call = true := by decide +kernel
@[req "STA-23"] theorem mismatched_ceremony_refused :
    sent (result (completedCeremonyEvents (.fullReentry false) true)) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem mismatched_ceremony_without_guard :
    sent (result (completedCeremonyEvents (.fullReentry false) true) { current with ceremonyCompletion := false }) readA.request.call = true := by decide +kernel

def inactiveCompletionEvents : List Event := (interruptedCeremonyEvents (.lifecycle .hide)).take 5 ++ [
  .lifecycle (.finishCeremony .skipped true), .lifecycle (.resume alice 100 true),
  .lifecycle (.validate resumedRead ready), .request resumedRead ready true]
@[req "STA-23"] theorem inactive_ceremony_completion_refused :
    sent (result inactiveCompletionEvents) readA.request.call = false := by decide +kernel
@[req "STA-23"] theorem inactive_ceremony_without_guard :
    sent (result inactiveCompletionEvents { current with ceremonyActive := false }) readA.request.call = true := by decide +kernel

def lockedCeremonyEvents (ok : Bool) : List Event := startEvents ++ [
  .lifecycle (.pause .lock), .lifecycle (.unlock ok), .lifecycle .enterCeremony,
  .lifecycle (.finishCeremony .skipped true), .lifecycle (.resume alice 100 true),
  .lifecycle (.validate resumedRead ready), .request resumedRead ready true]
@[req "STA-23"] theorem locked_ceremony_entry_refused :
    sent (result (lockedCeremonyEvents false)) readA.request.call = false ∧
    (result (lockedCeremonyEvents false)).locked = true := by decide +kernel
@[req "STA-23"] theorem locked_ceremony_entry_without_check :
    sent (result (lockedCeremonyEvents false) { current with ceremonyUnlocked := false }) readA.request.call = true := by decide +kernel
@[req "STA-23"] theorem unlocked_ceremony_entry_progress :
    sent (result (lockedCeremonyEvents true)) readA.request.call = true ∧
    (result (lockedCeremonyEvents true)).ended = [] := by decide +kernel

/-- A seal processed while locked supplies no terminal; the same seal after unlock and before
resume keeps the paid key. -/
def lockedSealEvents (ok : Bool) : List Event := procuredStart.take 3 ++ [
  .lifecycle (.pause .lock), .lifecycle (.unlock ok), .lifecycle (.sealTerminal alice true),
  .lifecycle (.unlock true), .lifecycle (.resume alice resumedAlice.incarnation true),
  .lifecycle (.assessKey resumedAlice validKey),
  .lifecycle (.validate resumedRead keyReady), .request resumedRead keyReady true]
@[req "ARC-31a"] theorem locked_seal_refused :
    sent (result (lockedSealEvents false)) readA.request.call = false ∧
    (actor current (result (lockedSealEvents false)) resumedAlice).map (·.sealedTerminal) = some false := by decide +kernel
@[req "ARC-31a"] theorem locked_seal_without_check :
    sent (result (lockedSealEvents false) { current with sealUnlocked := false }) readA.request.call = true := by decide +kernel
@[req "ARC-31a"] theorem unlocked_seal_progress :
    sent (result (lockedSealEvents true)) readA.request.call = true := by decide +kernel

def paidCeremonyEvents (choice : Completion) : List Event := procuredStart ++ [
  .lifecycle .enterCeremony, .lifecycle .hide, .lifecycle (.unlock true),
  .lifecycle .enterCeremony, .lifecycle (.finishCeremony choice true),
  .lifecycle (.resume alice 100 true), .lifecycle (.assessKey resumedAlice validKey),
  .lifecycle (.validate resumedRead keyReady), .request resumedRead keyReady true]
@[req "ARC-31a"] theorem paid_ceremony_preserves_key_and_approval :
    ([Completion.fullReentry true, .skipped].all fun c =>
      sent (result (paidCeremonyEvents c)) readA.request.call) = true ∧
    (actor current (result (paidCeremonyEvents .skipped)) resumedAlice).map (·.path) = some (.procured originalLimits) ∧
    (result (paidCeremonyEvents .skipped)).ended = [] := by decide +kernel

/-- Maximum length of these named histories, not an exhaustive event-alphabet bound. -/
@[req "STA-23"] def witnessBound : Nat := 26

end TauWeb.Authority
