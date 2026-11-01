# State-machine atlas

An informational navigation aid for **stage-1 typed LNVPS and maintained-cloud
recovery**. The owning requirements remain the place to implement a rule. This
atlas adds no behavior, dispatch authority or combined protocol. Authority stays
per clause under [ADR-0032](adr/0032-the-formal-companion-follows-provisiond-spec.md#what-is-adopted):
“until a rendering gate covers a clause the Markdown stays authoritative and the
Lean is a checking interpretation.” The informational projection below is distinct
from the authority-bearing `formal:` marked regions defined in
[CONTEXT.md](../CONTEXT.md#the-specifications-own-artifacts).

Use the [region outline](#region-outline) to find an owner, the
[combined matrix](#combined-matrix) to identify overlapping restrictions, and the
[Dispatch traces](#dispatch-traces) to inspect serialized harness knowledge.
There is no global Ready/Blocked/Completed state: journal authority, session
authority, remote uncertainty, command hold, pins, scan readiness and delivery
are separate dimensions.

Evidence vocabulary used locally in each view:

- **Conceptual navigation**: checked owner quotations and pointers; no executable
  guard or checked composition is implied.
- **Generated witness projection**: complete selected source events, outcomes and
  knowledge from the committed witness file; presentation evidence only.
- **General theorem**: the named proposition under its explicit premises, beyond
  the finite enumeration where its signature quantifies over all traces.
- **Implementation evidence**: observations from an implementation or its companion
  comparison. None is produced by this change. The source list for admission is
  [Stage applicability and admission](../07-conformance.md#stage-applicability-and-admission).

## Region outline

### Store and writer ownership

Evidence: conceptual navigation. Applicability: every local store, including recovery.

Owner: [STA-1–STA-3 and STA-7](../03-state-and-recovery.md#durable-state),
[STA-23](../03-state-and-recovery.md#durable-state).

- **Recorded knowledge / identity:** the local store's append-only journal and
  snapshots; the live worker's memory is transient. `STA-1` says “A single
  **harness worker** MUST be the only writer of durable state.” `STA-3` says
  “If the append fails, the transition does not occur.” Replay and unresolved
  derivation route to STA-7/STA-8, rather than a separately recorded blocked flag.
- **External possibilities:** storage loss and remote work are separate; replay
  is not evidence of remote completion. Writer retirement is not inferred from a
  missing heartbeat: `STA-23` says “missing heartbeat or a timeout is not confirmed
  predecessor termination.”
- **Permitted next actions:** follow STA-23's unlock, writer ownership and lifecycle
  fences before ordinary work. `STA-23` says “A second tab or instance MUST show
  in-use and wait”.

### Sessions and approvals

Evidence: conceptual navigation. Applicability: stage-1 single-machine sessions;
multi-machine admission belongs to the separate stage-2 row in the admission list.

Owners: [STA-23](../03-state-and-recovery.md#durable-state),
[SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock),
[SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved),
[ARC-12](../01-architecture.md#sessions-binding-and-diversity),
[ARC-31a](../01-architecture.md#money).

- **Recorded knowledge / identity:** approved structured facts are journaled;
  the rendering session, exclusive machine binding, credential buffers and runtime
  authority are distinct. `SEC-4` says “The adapter executes the structured facts
  as they were approved and journaled”. `SEC-1` says “The key is the machine's,
  not the session's, and a binding is exclusive.”
- **External possibilities:** a surviving hidden worker may still act, while a
  remote command may outlive a locally ended session. `STA-23` says “An ordinary
  visibility-only hide MUST NOT end or pause an unlocked session, clear its runtime
  authority, or invalidate its approvals.”
- **Permitted next actions / retirement:** `STA-23` says “Individual session end
  destroys that session's runtime authority and pending approvals; it does not
  revive on return.” Use its pre-send/post-await fences and ARC-31a's admission,
  cap and absolute-expiry contract; durable approval history is not live authority.
  SEC-1's jump-host and Replace key-holding exceptions and SEC-4's abandonment
  authorization have their own owners, not a generic session bypass.

### Cloud and reconciliation

Evidence: conceptual navigation. Applicability: typed LNVPS now; Robot/rescue
confirmation predicates are dedicated-route material, not LNVPS predicates.

Owners: [STA-4, STA-8, STA-24](../03-state-and-recovery.md#durable-state),
[STG-21/21a](../06-first-stage.md#the-stages), and dedicated
[STG-4](../06-first-stage.md#acceptance).

- **Recorded knowledge / identity:** approved setup entry, reserved index and
  admitted vendor mapping identify a resource; call id alone does not. Durable
  intents, observations, receipts and dispositions feed the unresolved predicate.
  `STA-24` says “The unresolved barrier holds per resource, not per call.”
- **External possibilities:** an intent without a terminal record leaves remote
  success, failure and non-execution unknown. `STA-8` says “It MUST NOT be retried
  automatically and no timer may clear it.” A disposition retires uncertainty as
  an open call, not as an external outcome: `STA-24` says “A disposition keeps the
  outcome *unknown*”.
- **Permitted next actions:** use admissible evidence or operator disposition;
  see the matrix and the operation-specific predicates. For restart, `STG-21a`
  says “It does not establish a completed guest boot or service survival.”
  The [protected-operation evidence boundary](design/protected-evidence-v1.md#3a-protected-operation-evidence)
  also controls unavailable identity, exact targeting, quarantine and new-order
  exclusion. No matrix permission grants an unavailable vendor literal.

### Commands

Evidence: conceptual navigation. Applicability: installed systems in stage 1;
rescue's persistence exception and reset prerequisites are dedicated-route material.

Owners: [STA-20/20b](../03-state-and-recovery.md#durable-state),
[ARC-43](../01-architecture.md#box-plane-execution-is-command-granular).

- **Recorded knowledge / identity:** browser command intent and the machine's
  advisory job record name the machine and command; boot identity distinguishes
  process liveness across boots. `STA-20` says “A missing record is unresolved,
  never proof of death.” Installed records persist on disk; `STA-20b` says rescue
  jobs “survive an SSH disconnect, not a reboot.”
- **External possibilities:** a sent command may still run, and a finished command
  can have launched a surviving service. `STA-20` says “The job record tracks the
  command; service lifecycle is declared, checked and owned elsewhere.”
- **Permitted next actions / retirement:** `STA-20` says “Collecting a job record
  is not held, and other machines are unaffected.” It also says “Only a terminal
  record releases the hold”. See ARC-43 for the dedicated delivery-reboot result;
  LNVPS typed restart confirmation is separate. The command hold does not subsume
  destructive dispositions or the pending delivery check.

### Identity and pins

Evidence: conceptual navigation. Applicability: CHN-R7 for stage-1 LNVPS;
CHN-R1 is dedicated/rescue, CHN-R5 attest is route-specific, CHN-R6 jump-host
contact is later-stage material. CHN-R2/3/4 retain their rejected-route status.

Owners: [CHN-R* routes](../02-channel.md#the-routes-to-a-fingerprint),
[SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked),
[protected evidence](design/protected-evidence-v1.md).

- **Recorded knowledge / identity:** a machine's installation-group history and
  active pin are durable facts, distinct from current transport state and from an
  admitted vendor-resource mapping. `CHN-R7` says “restart and Restore do not”
  open another installation group. It also says “the old installed pin authorizes
  no new contact” after an operator-chosen destructive reinstall.
- **External possibilities:** a vendor publication is an observation with its
  route's trust boundary, not service survival or an independently attested machine.
  `CHN-R7` says “This is a vendor-published observation, not an attestation.”
- **Permitted next actions:** follow pin admission and retirement before contact;
  `SEC-11` says “An SSH session MUST check the host key against the stored
  fingerprint, and a key that does not match MUST halt the session.” A permitted
  connection still grants no command permission. The protected companion §3a
  owns unavailable identity; §§1–5 own protected encoding and scan boundaries.

### Delivery and secrets

Evidence: conceptual navigation. Applicability: stage-1 LNVPS and re-entry;
`delivery_reboot` is the distinct non-LNVPS route.

Owners: [ARC-17/39](../01-architecture.md#what-a-session-delivers),
[ARC-43](../01-architecture.md#box-plane-execution-is-command-granular),
[SEC-5](../04-security-model.md#sec-5--the-credential-inventory).

- **Recorded knowledge / identity:** the journaled declaration in force, findings,
  per-machine placements and pending check are durable facts; scan references and
  current scan readiness have their separate protected-evidence boundary. `ARC-17`
  says “A finding is cleared by a re-check and by nothing else”.
- **External possibilities:** operation confirmation, observed guest boot, service
  survival and delivery verdict are different evidence. `ARC-43` says
  “Operation-confirmation evidence admitted by STA-24 supplies authority only for
  that operation’s result, not for delivery checks or host-key pins.”
- **Permitted next actions / retirement:** follow ARC-43's pending-check hold and
  SEC-5's output restrictions even after a command settles. `SEC-5` says “Unscanned
  bytes MUST be withheld”. Placement, finding clearance and delivery are separate;
  the matrix does not waive any of them. Expanded composition belongs to tw-237.2.

### Allocation and recovery

Evidence: conceptual navigation. Applicability: maintained-cloud recovery in
stage 1; dedicated relabel/rescue migration is route-specific.

Owners: [STA-17](../03-state-and-recovery.md#recovery-by-access-model-and-vendor),
[STA-22/22a/22b](../03-state-and-recovery.md#what-survives-a-lost-phone),
[credential format](design/credential-format-v1.md).

- **Recorded knowledge / identity:** seed id, role-family indices, version,
  allocation tombstones and exported metadata identify recoverable credentials;
  keys in memory and current live authority are separate. `STA-22b` says
  “Reserve it durably before any external effect, including registering a key for
  an already-rented server.”
- **External possibilities:** a recovered sheet can predate remote activity;
  restored access is no evidence that an old command ended. `STA-22b` says
  “every imported seed may restore listed identities but MUST NOT allocate new ones”.
- **Permitted next actions / retirement:** follow Restore versus Replace at STA-17;
  `STA-17` says Restore is “explicitly presented as non-revoking”. Replace's new
  identity and removal of old remote keys are separate from local seed retirement.
  Missing metadata and LNVPS's third recovery rung stay with their open owners below.

## Combined matrix

Evidence: conceptual navigation, checked owner quotations below; no executable
guard logic. Applicability: same approved resource, typed vendor and current
installed machine unless qualified. Other resources are independent only under
their own guards. The restrictions in different columns **accumulate**.
The columns describe recorded harness knowledge and current authority; external
outcomes remain unknown without admissible evidence. Each cell describes only
the permitted next action through that restriction.

**Allowed subject to other guards** means this restriction supplies a permission,
not dispatch authority. **Refused** means the owner refuses the request. **Held**
means STA-20's command wait, with no intent for the held request. **Not specified**
marks a boundary, not a refusal or permission.

| Action class | Current session / binding / approval authority | Unresolved create/order, activation or key registration | Unresolved reset / reinstall / destroy or stand-in stop | Unresolved box-plane command | Standing destructive disposition |
|---|---|---|---|---|---|
| Typed mutation on the approved entry, including create/order | **Refused** when approved facts/authority are unusable or an existing machine is outside binding; account-level creation requires its own approval [A](#authority), and new-order exclusions still apply [P](#pins-output-and-pending-check); abandonment uses its own dispatch authorization | **Refused** [B](#cloud-barrier) | **Refused** [B](#cloud-barrier) | **Refused** [B](#cloud-barrier), [C](#command-hold) | **Refused** within the disposed calls' reach except the permitted continuation/preparation; session destroy under abandonment is refused [D](#destructive-disposition) |
| Adapter reconciliation read | **Allowed subject to other guards**, under its current authorized session or named harness flow [A](#authority) | **Allowed subject to other guards** [B](#cloud-barrier) | **Allowed subject to other guards** [B](#cloud-barrier) | **Allowed subject to other guards** [C](#command-hold) | **Allowed subject to other guards** [D](#destructive-disposition) |
| Ordinary `exec`, including a read through `exec` | **Refused** under ended/stale session authority or outside binding [A](#authority) | **Allowed subject to other guards** [B](#cloud-barrier) | **Refused** while cloud stop stands [B](#cloud-barrier) | **Held**, source Dispatch refusal is `barrier` [C](#command-hold) | **Refused** [D](#destructive-disposition) |
| Harness-owned box-plane job, including a harness-composed read | **Allowed subject to other guards** only through its owner's authorized flow; session work meets [A](#authority) | **Allowed subject to other guards** [B](#cloud-barrier) | **Refused** while cloud stop stands [B](#cloud-barrier) | **Held** regardless of requester [C](#command-hold) | **Refused** regardless of requester [D](#destructive-disposition) |
| Job-record collection (not a new job) | **Allowed subject to other guards** under current collection authority [A](#authority) | **Allowed subject to other guards** [B](#cloud-barrier) | **Allowed subject to other guards** [B](#cloud-barrier) | **Allowed subject to other guards** [C](#command-hold) | **Allowed subject to other guards** [D](#destructive-disposition) |
| Pin-checked connection (not permission to execute) | **Allowed subject to other guards** only after binding or the exact named key-holding exception [A](#authority), [P](#pins-output-and-pending-check) | **Allowed subject to other guards** [B](#cloud-barrier) | **Allowed subject to other guards**, including the dedicated confirming pinned SSH attempt [B](#cloud-barrier) | **Allowed subject to other guards** for collection [C](#command-hold) | **Allowed subject to other guards** for permitted reads [D](#destructive-disposition) |
| Inference request | **Refused** under ended/stale session authority; procured limits remain separate [A](#authority) | **Allowed subject to other guards** [B](#cloud-barrier) | **Allowed subject to other guards** [B](#cloud-barrier) | **Allowed subject to other guards** [C](#command-hold) | **Allowed subject to other guards** [D](#destructive-disposition) |
| Actionable publication | **Refused** under stale authority [A](#authority); output fences [P](#pins-output-and-pending-check) | **Not specified** by Dispatch; publication is outside its trace contract [P](#pins-output-and-pending-check) | **Not specified** by Dispatch; [P](#pins-output-and-pending-check) | **Not specified** by Dispatch; [P](#pins-output-and-pending-check) | **Not specified** by Dispatch; destruction/output question remains tw-pkn [open owners](#open-owners-and-deliberate-boundaries), with SEC-5 fences still applicable |

### Authority

Evidence: conceptual navigation. Applicability: session requests; named harness
flows keep their own authorization.

Owners: [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock),
[SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved),
[STA-23](../03-state-and-recovery.md#durable-state).

`SEC-1` says “Binding is an operator act in the browser, made before any channel access
to that machine.” `SEC-4` says “A typed operation that names an existing machine MUST be authorized against
the calling session's binding” and “The abandonment flow is authorized outside any
session.” It also says “What is dispatched is the approved record.”
`SEC-4` says “A session's vendor operations reach the machines of its own set and
account-level creation, nothing else.”
`STA-23` says “A stale message or late
result MUST NOT revive ended authority or publish an actionable result under stale
authority.” Its continuation check includes “current authority, bindings, holds,
connection state and scan readiness.” An approval and a permitted read do not
supply any of these other facts.

### Cloud barrier

Evidence: conceptual navigation. Applicability: resource-local typed operations;
untyped vendor scopes have the wider, prose-only pause/hold at STA-24.

Owner: [STA-24](../03-state-and-recovery.md#durable-state).

`STA-24` says “the harness worker MUST NOT
dispatch a side-effecting operation naming that resource” while a call is
unresolved. It qualifies box-plane work: “An unresolved activation or key
registration touches no running system and blocks nothing on the box.” The
running-system exception “stops box-plane dispatch to that machine from its intent
until its confirmation.” For reads it says “Reads naming the resource — the
adapter's status queries, the pinned SSH attempt that is `STG-4`'s third predicate,
the collection of job records — are permitted”. For inference it says “does
**not** bar the next request”. Read permission alone supplies no confirmation:
operation evidence must satisfy [STG-21a](../06-first-stage.md#the-stages), or
dedicated [STG-4](../06-first-stage.md#acceptance), and survive durable append.

### Command hold

Evidence: conceptual navigation. Applicability: every unresolved box-plane
command on the machine, including session succession.

Owner: [STA-20](../03-state-and-recovery.md#durable-state).

`STA-20` says “a read through `exec` is a
command, and a job the harness composes is held too.” It says “Collecting a job
record is not held, and other machines are unaffected” and “A held request is not
run and records no intent.” Collection of a terminal record can release this hold;
it cannot release an independent standing destructive disposition. The generated
held trace retains the source result `dispatch: refused`, `reason: barrier`.
The wait and flow-resumption procedure are prose-only; see
[ADR-0048](adr/0048-an-unresolved-command-holds-its-machine.md).

### Destructive disposition

Evidence: conceptual navigation. Applicability: typed machines, every requester;
untyped harness-started-job reach remains the separate question below.

Owner: [STA-24](../03-state-and-recovery.md#durable-state).

`STA-24` says “A standing disposition
restricts, to its continuation, what the calls it names barred while they were
unresolved.” The exception says “the harness worker MUST refuse every
box-plane job to that machine, whatever the disposed call was and whoever starts
it”. It also says “Reads stay permitted throughout” and “A session's request for
that destroy or stop under a standing abandonment MUST be refused”. Preparation
and the operation that ends the restriction route to STA-24's *When the
restriction ends* and the continuation's own owner; the new intent has its own
barrier. Late evidence is shown and removes no standing disposition. See
[ADR-0044, with amendments](adr/0044-a-disposition-limits-what-its-calls-barred.md)
and [ADR-0050](adr/0050-destructive-dispositions-stop-every-box-plane-job.md).

### Pins, output and pending check

Evidence: conceptual navigation. Applicability: all apparent permissions in the
matrix; detailed composition is deferred to tw-237.2.

For pin admission use [CHN-R7](../02-channel.md#the-routes-to-a-fingerprint)
and [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked), not a cleared
barrier. For output use [SEC-5](../04-security-model.md#sec-5--the-credential-inventory),
which says “Unscanned bytes MUST be withheld”, and
[protected evidence](design/protected-evidence-v1.md#1-decoder-boundary-and-facts).
For new-order exclusion use its [§3a](design/protected-evidence-v1.md#3a-protected-operation-evidence).
For the [pending-check hold](../01-architecture.md#box-plane-execution-is-command-granular),
`ARC-43` says “until the delivery check's verdict is durably
journaled” it “holds the model's box-plane commands to that machine”. It says
“A stop settles no verdict and is shown as a stopped check, never as a pass.”
That hold, scan readiness and actionable publication are outside the Dispatch
projection below. A settled restart or command supplies none of their release
conditions. LNVPS vendor restart confirmation, guest boot observation, service
survival, final durable verdict and pin admission remain separate.

### Admission ordering and replay

Evidence: conceptual navigation of [Dispatch admission](../tools/formal/TauWeb/Dispatch.lean).
Applicability: the current companion function, not universal first-error precedence.

`TauWeb.Dispatch.admit` checks target resolution, approval session, approved facts,
blocking calls, withdrawn approval, standing continuation, approval-bound rescue
activation, then identity exclusion. The request step's append can still fail.
`TauWeb.Dispatch.barring` combines `TauWeb.Dispatch.bars` and
`TauWeb.Dispatch.commandHold`; the latter adds the independent command-to-command
hold. This ordering supplies no ordering between unrelated prose guards.

Evidence: general theorem. Applicability: harness knowledge over every trace and
resource, with `durableBeforeApply = true` and initial `memory = journal`.

`TauWeb.Dispatch.replay_same_unresolved` equates the unresolved set before and
after replay of the resulting journal. `STA-7` says “Cancelling the calls that were
never dispatched is not carried there.” See the [owner](../03-state-and-recovery.md#durable-state). The
theorem also proves no session termination or browser lifecycle behavior; those
are explicit assumptions/omissions in Dispatch's opening notes. The trace convention
is that ended sessions send no requests and successor sessions act after replay.

### Open owners and deliberate boundaries

Evidence: conceptual navigation. Applicability: unresolved design questions, not
new permissions. The source records are the [committed tracker](../.beads/issues.jsonl);
inspect a named record with `br show ID --json --no-auto-flush --no-auto-import`.

- **Not specified:** older restored journal versus a possibly live pre-loss command
  ([tw-ub7](../.beads/issues.jsonl)); untyped destructive hold versus harness-started
  jobs in stage 2 ([tw-pgp](../.beads/issues.jsonl)); stage-1 Arch login to root-only
  jobs ([tw-yuo](../.beads/issues.jsonl)). No privilege escalation is implied here.
- **Not specified:** LNVPS's third recovery rung ([tw-ae7](../.beads/issues.jsonl));
  destruction/output ([tw-pkn](../.beads/issues.jsonl)); rescue activation beside
  delivery reboot ([tw-z99](../.beads/issues.jsonl)). The existing recovery figures
  remain unchanged in this slice.
- Allocation questions stay with [tw-sfu, tw-hwl, tw-nj8](../.beads/issues.jsonl);
  installation/recovery questions with [tw-lq8, tw-l1l, tw-yhd](../.beads/issues.jsonl).
  This outline chooses no answers to them.
- [tw-316](../.beads/issues.jsonl) owns corpus-wide witness-pair validation;
  [tw-itv](../.beads/issues.jsonl) retains approval-facts and bounded-description
  work. The renderer below validates only the selected projection inputs.

## Dispatch traces

The source is [Dispatch schema 8](design/dispatch-witnesses-v8.json), with its
[schema and abstraction limits](design/witness-file-v1.md#dispatch) and
[formal companion assumptions/omissions](../tools/formal/TauWeb/Dispatch.lean).
Every table inside the informational markers carries its own evidence and
applicability label. Metadata, starting knowledge and every source step are
projected whole; no outcomes are calculated by Python. A pair's `side` is metadata,
not the dispatch result of any step.

The fresh-call pair differs in `resourceKey` (`entry` versus `call`). It has two
reset requests, calls 1 and 2, and **no explicit lost-response or replay event**.
Terminal evidence is absent; lost response is a driver absence, not an observed
external outcome. Both sides are shown whole, without invented crash, timestamp,
vendor success or scheduler evidence. The admitted side removes the resource guard
and is not legitimate progress. Nearby, `TauWeb.Dispatch.lnvps_receipt_confirms`
shows the useful evidence dependency: a validated, correlated, durably appended
restart receipt settles call 1 and that knowledge survives replay. At the recorded
LNVPS baseline, `STG-21a` says “Without that response,
the available status predicate cannot confirm restart.” For missing receipt the
operator's disposition, or genuinely qualifying future evidence, remains necessary;
the receipt trace does not pretend a missing receipt arrived. See the
[confirmation owner](../06-first-stage.md#the-stages).

The command pair differs in `commandHold` (true versus false), with exec calls 7
then 12. Its admitted side is another withdrawn-guard counterexample.
`TauWeb.Dispatch.hold_reads_and_other_machines` is legitimate progress: exec 7,
replay, successor-session exec 12 refused, read request 13, inference 14, exec 17
on entry 2, durable job-record observation settling 7, then exec 20 on the original
machine. The read request does not itself collect a terminal record. The independent
inference and entry-2 calls remain visible. Other-machine events are stage-1
fixtures under the admission list, not admission of multi-machine sessions.
This named trace exceeds the three-event bound; it is not exhaustively covered by
that enumeration. These are separate intact traces, not a checked composition.

<!-- atlas-info: dispatch-v8 -->
Evidence: generated witness projection; informational, source-attributed harness knowledge.
Applicability: Dispatch selected typed traces; stage-1 fixtures where another machine appears.
External possibilities: not recorded here. Permitted next actions: consult the owner matrix; source dispatch results alone supply no authority.

| Source header and bound context (complete) |
|---|
| <code>{&quot;bound&quot;: {&quot;alphabet&quot;: &#91;{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 1, &quot;facts&quot;: 1, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;reset&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 2, &quot;facts&quot;: 1, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;reset&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;facts&quot;: 3, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;exec&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;appended&quot;: true, &quot;kind&quot;: &quot;read&quot;, &quot;operation&quot;: &quot;reset&quot;, &quot;provenance&quot;: &quot;adapter observation&quot;, &quot;reports&quot;: &quot;succeeded&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;source&quot;: &quot;adapter&#95;read&quot;}, {&quot;appended&quot;: true, &quot;calls&quot;: &#91;1&#93;, &quot;continuation&quot;: &quot;destructive&#95;reinstall&quot;, &quot;kind&quot;: &quot;dispose&quot;, &quot;provenance&quot;: &quot;disposition&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}, {&quot;kind&quot;: &quot;replay&quot;, &quot;provenance&quot;: &quot;replay&quot;}, {&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 5, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 10, &quot;facts&quot;: 5, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;activate&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;entry&quot;: 1}}, {&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 12, &quot;facts&quot;: 3, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;exec&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;declaration&quot;: &quot;TauWeb.Dispatch.bound&quot;, &quot;events&quot;: 3, &quot;start&quot;: {&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;&#93;}}, &quot;module&quot;: &quot;dispatch&quot;, &quot;namespace&quot;: &quot;TauWeb.Dispatch&quot;, &quot;schema&quot;: 8}</code> |

### same action new call id refused

Evidence: generated witness projection — same_action_new_call_id_refused.
Applicability: Typed resource barrier; reset requests, absent terminal evidence.

| Source metadata | Value |
|---|---|
| Declarations, assumptions, pair (when present) | <code>{&quot;assumptions&quot;: {&quot;approvalResetRequiresRescue&quot;: true, &quot;approvedReinstallBoundary&quot;: true, &quot;commandHold&quot;: true, &quot;destructiveStops&quot;: true, &quot;dispositionBindsContinuation&quot;: true, &quot;dispositionOwnResource&quot;: true, &quot;durableBeforeApply&quot;: true, &quot;endedBelowSucceeded&quot;: true, &quot;failedPrerequisiteWithdraws&quot;: true, &quot;identityExclusion&quot;: true, &quot;lapse&quot;: &quot;continuation&quot;, &quot;newestActivationRead&quot;: true, &quot;orderAssociation&quot;: true, &quot;reach&quot;: &quot;disposed&quot;, &quot;rebootBootChange&quot;: true, &quot;reinstallWithdrawalEffective&quot;: true, &quot;resetIntoRescueOnly&quot;: true, &quot;resetOfferCurrentInstallation&quot;: true, &quot;resetOfferFreshKeys&quot;: true, &quot;resourceKey&quot;: &quot;entry&quot;, &quot;sessionDestroyRefused&quot;: true}, &quot;declarations&quot;: &#91;&quot;TauWeb.Dispatch.same&#95;action&#95;new&#95;call&#95;id&#95;refused&quot;&#93;, &quot;pair&quot;: {&quot;side&quot;: &quot;refused&quot;, &quot;with&quot;: &quot;TauWeb.Dispatch.same&#95;action&#95;new&#95;call&#95;id&#95;admitted&quot;}}</code> |
| Starting knowledge (complete) | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;&#93;}</code> |

Evidence: generated witness projection — same_action_new_call_id_refused steps.
Applicability: Typed resource barrier; reset requests, absent terminal evidence. Source steps.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies to every source dispatch result.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 1, &quot;facts&quot;: 1, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;reset&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}</code> | <code>{&quot;dispatch&quot;: &quot;dispatched&quot;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 1, &quot;operation&quot;: &quot;reset&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;1&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;1&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |
| 2 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 2, &quot;facts&quot;: 1, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;reset&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}</code> | <code>{&quot;dispatch&quot;: &quot;refused&quot;, &quot;refusal&quot;: {&quot;calls&quot;: &#91;1&#93;, &quot;reason&quot;: &quot;barrier&quot;}}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 1, &quot;operation&quot;: &quot;reset&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;1&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;1&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |

### same action new call id admitted

Evidence: generated witness projection — same_action_new_call_id_admitted.
Applicability: Withdrawn-guard counterexample; resourceKey = call. Not a permissible continuation.

| Source metadata | Value |
|---|---|
| Declarations, assumptions, pair (when present) | <code>{&quot;assumptions&quot;: {&quot;approvalResetRequiresRescue&quot;: true, &quot;approvedReinstallBoundary&quot;: true, &quot;commandHold&quot;: true, &quot;destructiveStops&quot;: true, &quot;dispositionBindsContinuation&quot;: true, &quot;dispositionOwnResource&quot;: true, &quot;durableBeforeApply&quot;: true, &quot;endedBelowSucceeded&quot;: true, &quot;failedPrerequisiteWithdraws&quot;: true, &quot;identityExclusion&quot;: true, &quot;lapse&quot;: &quot;continuation&quot;, &quot;newestActivationRead&quot;: true, &quot;orderAssociation&quot;: true, &quot;reach&quot;: &quot;disposed&quot;, &quot;rebootBootChange&quot;: true, &quot;reinstallWithdrawalEffective&quot;: true, &quot;resetIntoRescueOnly&quot;: true, &quot;resetOfferCurrentInstallation&quot;: true, &quot;resetOfferFreshKeys&quot;: true, &quot;resourceKey&quot;: &quot;call&quot;, &quot;sessionDestroyRefused&quot;: true}, &quot;declarations&quot;: &#91;&quot;TauWeb.Dispatch.same&#95;action&#95;new&#95;call&#95;id&#95;admitted&quot;&#93;, &quot;pair&quot;: {&quot;side&quot;: &quot;admitted&quot;, &quot;with&quot;: &quot;TauWeb.Dispatch.same&#95;action&#95;new&#95;call&#95;id&#95;refused&quot;}}</code> |
| Starting knowledge (complete) | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;&#93;}</code> |

Evidence: generated witness projection — same_action_new_call_id_admitted steps.
Applicability: Withdrawn-guard counterexample; resourceKey = call. Not a permissible continuation. Source steps.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies to every source dispatch result.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 1, &quot;facts&quot;: 1, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;reset&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}</code> | <code>{&quot;dispatch&quot;: &quot;dispatched&quot;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 1, &quot;operation&quot;: &quot;reset&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;1&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;1&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |
| 2 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 2, &quot;facts&quot;: 1, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;reset&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}</code> | <code>{&quot;dispatch&quot;: &quot;dispatched&quot;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 1, &quot;operation&quot;: &quot;reset&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 2, &quot;operation&quot;: &quot;reset&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;1, 2&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;2, 1&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |

### lnvps receipt confirms

Evidence: generated witness projection — lnvps_receipt_confirms.
Applicability: Stage-1 typed LNVPS restart receipt; vendor confirmation only, no guest/service/delivery evidence.

| Source metadata | Value |
|---|---|
| Declarations, assumptions, pair (when present) | <code>{&quot;assumptions&quot;: {&quot;approvalResetRequiresRescue&quot;: true, &quot;approvedReinstallBoundary&quot;: true, &quot;commandHold&quot;: true, &quot;destructiveStops&quot;: true, &quot;dispositionBindsContinuation&quot;: true, &quot;dispositionOwnResource&quot;: true, &quot;durableBeforeApply&quot;: true, &quot;endedBelowSucceeded&quot;: true, &quot;failedPrerequisiteWithdraws&quot;: true, &quot;identityExclusion&quot;: true, &quot;lapse&quot;: &quot;continuation&quot;, &quot;newestActivationRead&quot;: true, &quot;orderAssociation&quot;: true, &quot;reach&quot;: &quot;disposed&quot;, &quot;rebootBootChange&quot;: true, &quot;reinstallWithdrawalEffective&quot;: true, &quot;resetIntoRescueOnly&quot;: true, &quot;resetOfferCurrentInstallation&quot;: true, &quot;resetOfferFreshKeys&quot;: true, &quot;resourceKey&quot;: &quot;entry&quot;, &quot;sessionDestroyRefused&quot;: true}, &quot;declarations&quot;: &#91;&quot;TauWeb.Dispatch.lnvps&#95;receipt&#95;confirms&quot;&#93;}</code> |
| Starting knowledge (complete) | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;&#93;}</code> |

Evidence: generated witness projection — lnvps_receipt_confirms steps.
Applicability: Stage-1 typed LNVPS restart receipt; vendor confirmation only, no guest/service/delivery evidence. Source steps.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies to every source dispatch result.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: {&quot;account&quot;: 41, &quot;operation&quot;: &quot;restart&quot;, &quot;signed&#95;request&quot;: 73}, &quot;session&quot;: 1}, &quot;call&quot;: 1, &quot;facts&quot;: 1, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;reset&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}</code> | <code>{&quot;dispatch&quot;: &quot;dispatched&quot;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: {&quot;account&quot;: 41, &quot;operation&quot;: &quot;restart&quot;, &quot;signed&#95;request&quot;: 73}, &quot;session&quot;: 1}, &quot;call&quot;: 1, &quot;operation&quot;: &quot;reset&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;1&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;1&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |
| 2 | <code>{&quot;appended&quot;: true, &quot;kind&quot;: &quot;receive&quot;, &quot;provenance&quot;: &quot;adapter observation&quot;, &quot;receipt&quot;: {&quot;binding&quot;: {&quot;account&quot;: 41, &quot;operation&quot;: &quot;restart&quot;, &quot;signed&#95;request&quot;: 73}, &quot;call&quot;: 1, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;returned&#95;vendor&quot;: null, &quot;returned&#95;withheld&quot;: false, &quot;source&quot;: &quot;browser&#95;vendor&#95;tls&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}, &quot;validated&quot;: true}}</code> | <code>{&quot;settled&quot;: &#91;1&#93;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: {&quot;account&quot;: 41, &quot;operation&quot;: &quot;restart&quot;, &quot;signed&#95;request&quot;: 73}, &quot;session&quot;: 1}, &quot;call&quot;: 1, &quot;operation&quot;: &quot;reset&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;terminal&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;1&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;{&quot;binding&quot;: {&quot;account&quot;: 41, &quot;operation&quot;: &quot;restart&quot;, &quot;signed&#95;request&quot;: 73}, &quot;call&quot;: 1, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;returned&#95;vendor&quot;: null, &quot;returned&#95;withheld&quot;: false, &quot;source&quot;: &quot;browser&#95;vendor&#95;tls&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}, &quot;validated&quot;: true}&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |
| 3 | <code>{&quot;kind&quot;: &quot;replay&quot;, &quot;provenance&quot;: &quot;replay&quot;}</code> | <code>{}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 1, &quot;receipt&#95;binding&quot;: {&quot;account&quot;: 41, &quot;operation&quot;: &quot;restart&quot;, &quot;signed&#95;request&quot;: 73}, &quot;session&quot;: 1}, &quot;call&quot;: 1, &quot;operation&quot;: &quot;reset&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;terminal&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;1&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;{&quot;binding&quot;: {&quot;account&quot;: 41, &quot;operation&quot;: &quot;restart&quot;, &quot;signed&#95;request&quot;: 73}, &quot;call&quot;: 1, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;returned&#95;vendor&quot;: null, &quot;returned&#95;withheld&quot;: false, &quot;source&quot;: &quot;browser&#95;vendor&#95;tls&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}, &quot;validated&quot;: true}&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |

### second command held

Evidence: generated witness projection — second_command_held.
Applicability: Installed-system command hold; actual refusal reason is barrier.

| Source metadata | Value |
|---|---|
| Declarations, assumptions, pair (when present) | <code>{&quot;assumptions&quot;: {&quot;approvalResetRequiresRescue&quot;: true, &quot;approvedReinstallBoundary&quot;: true, &quot;commandHold&quot;: true, &quot;destructiveStops&quot;: true, &quot;dispositionBindsContinuation&quot;: true, &quot;dispositionOwnResource&quot;: true, &quot;durableBeforeApply&quot;: true, &quot;endedBelowSucceeded&quot;: true, &quot;failedPrerequisiteWithdraws&quot;: true, &quot;identityExclusion&quot;: true, &quot;lapse&quot;: &quot;continuation&quot;, &quot;newestActivationRead&quot;: true, &quot;orderAssociation&quot;: true, &quot;reach&quot;: &quot;disposed&quot;, &quot;rebootBootChange&quot;: true, &quot;reinstallWithdrawalEffective&quot;: true, &quot;resetIntoRescueOnly&quot;: true, &quot;resetOfferCurrentInstallation&quot;: true, &quot;resetOfferFreshKeys&quot;: true, &quot;resourceKey&quot;: &quot;entry&quot;, &quot;sessionDestroyRefused&quot;: true}, &quot;declarations&quot;: &#91;&quot;TauWeb.Dispatch.second&#95;command&#95;held&quot;&#93;, &quot;pair&quot;: {&quot;side&quot;: &quot;refused&quot;, &quot;with&quot;: &quot;TauWeb.Dispatch.second&#95;command&#95;without&#95;hold&quot;}}</code> |
| Starting knowledge (complete) | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;&#93;}</code> |

Evidence: generated witness projection — second_command_held steps.
Applicability: Installed-system command hold; actual refusal reason is barrier. Source steps.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies to every source dispatch result.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;facts&quot;: 3, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;exec&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}</code> | <code>{&quot;dispatch&quot;: &quot;dispatched&quot;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;7&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;7&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |
| 2 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 12, &quot;facts&quot;: 3, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;exec&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}</code> | <code>{&quot;dispatch&quot;: &quot;refused&quot;, &quot;refusal&quot;: {&quot;calls&quot;: &#91;7&#93;, &quot;reason&quot;: &quot;barrier&quot;}}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;7&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;7&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |

### second command without hold

Evidence: generated witness projection — second_command_without_hold.
Applicability: Withdrawn-guard counterexample; commandHold = false. Not a permissible continuation.

| Source metadata | Value |
|---|---|
| Declarations, assumptions, pair (when present) | <code>{&quot;assumptions&quot;: {&quot;approvalResetRequiresRescue&quot;: true, &quot;approvedReinstallBoundary&quot;: true, &quot;commandHold&quot;: false, &quot;destructiveStops&quot;: true, &quot;dispositionBindsContinuation&quot;: true, &quot;dispositionOwnResource&quot;: true, &quot;durableBeforeApply&quot;: true, &quot;endedBelowSucceeded&quot;: true, &quot;failedPrerequisiteWithdraws&quot;: true, &quot;identityExclusion&quot;: true, &quot;lapse&quot;: &quot;continuation&quot;, &quot;newestActivationRead&quot;: true, &quot;orderAssociation&quot;: true, &quot;reach&quot;: &quot;disposed&quot;, &quot;rebootBootChange&quot;: true, &quot;reinstallWithdrawalEffective&quot;: true, &quot;resetIntoRescueOnly&quot;: true, &quot;resetOfferCurrentInstallation&quot;: true, &quot;resetOfferFreshKeys&quot;: true, &quot;resourceKey&quot;: &quot;entry&quot;, &quot;sessionDestroyRefused&quot;: true}, &quot;declarations&quot;: &#91;&quot;TauWeb.Dispatch.second&#95;command&#95;without&#95;hold&quot;&#93;, &quot;pair&quot;: {&quot;side&quot;: &quot;admitted&quot;, &quot;with&quot;: &quot;TauWeb.Dispatch.second&#95;command&#95;held&quot;}}</code> |
| Starting knowledge (complete) | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;&#93;}</code> |

Evidence: generated witness projection — second_command_without_hold steps.
Applicability: Withdrawn-guard counterexample; commandHold = false. Not a permissible continuation. Source steps.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies to every source dispatch result.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;facts&quot;: 3, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;exec&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}</code> | <code>{&quot;dispatch&quot;: &quot;dispatched&quot;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;7&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;7&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |
| 2 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 12, &quot;facts&quot;: 3, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;exec&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}</code> | <code>{&quot;dispatch&quot;: &quot;dispatched&quot;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 12, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;7, 12&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;12, 7&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |

### hold reads and other machines

Evidence: generated witness projection — hold_reads_and_other_machines.
Applicability: Command collection and successor session; other-machine steps are stage-1 fixtures, not multi-machine admission. Named trace exceeds the enumeration bound.

| Source metadata | Value |
|---|---|
| Declarations, assumptions, pair (when present) | <code>{&quot;assumptions&quot;: {&quot;approvalResetRequiresRescue&quot;: true, &quot;approvedReinstallBoundary&quot;: true, &quot;commandHold&quot;: true, &quot;destructiveStops&quot;: true, &quot;dispositionBindsContinuation&quot;: true, &quot;dispositionOwnResource&quot;: true, &quot;durableBeforeApply&quot;: true, &quot;endedBelowSucceeded&quot;: true, &quot;failedPrerequisiteWithdraws&quot;: true, &quot;identityExclusion&quot;: true, &quot;lapse&quot;: &quot;continuation&quot;, &quot;newestActivationRead&quot;: true, &quot;orderAssociation&quot;: true, &quot;reach&quot;: &quot;disposed&quot;, &quot;rebootBootChange&quot;: true, &quot;reinstallWithdrawalEffective&quot;: true, &quot;resetIntoRescueOnly&quot;: true, &quot;resetOfferCurrentInstallation&quot;: true, &quot;resetOfferFreshKeys&quot;: true, &quot;resourceKey&quot;: &quot;entry&quot;, &quot;sessionDestroyRefused&quot;: true}, &quot;declarations&quot;: &#91;&quot;TauWeb.Dispatch.hold&#95;reads&#95;and&#95;other&#95;machines&quot;&#93;}</code> |
| Starting knowledge (complete) | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;&#93;}</code> |

Evidence: generated witness projection — hold_reads_and_other_machines steps.
Applicability: Command collection and successor session; other-machine steps are stage-1 fixtures, not multi-machine admission. Named trace exceeds the enumeration bound. Source steps.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies to every source dispatch result.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;facts&quot;: 3, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;exec&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}</code> | <code>{&quot;dispatch&quot;: &quot;dispatched&quot;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;7&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;7&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |
| 2 | <code>{&quot;kind&quot;: &quot;replay&quot;, &quot;provenance&quot;: &quot;replay&quot;}</code> | <code>{}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;7&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;7&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |
| 3 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 12, &quot;facts&quot;: 3, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;exec&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 2, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}</code> | <code>{&quot;dispatch&quot;: &quot;refused&quot;, &quot;refusal&quot;: {&quot;calls&quot;: &#91;7&#93;, &quot;reason&quot;: &quot;barrier&quot;}}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;7&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;7&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |
| 4 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 9, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 13, &quot;facts&quot;: 9, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;read&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 2, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}</code> | <code>{&quot;dispatch&quot;: &quot;dispatched&quot;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;approved&quot;: {&quot;facts&quot;: 9, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 13, &quot;operation&quot;: &quot;read&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 2, &quot;state&quot;: &quot;no&#95;effect&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;7, 13&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;7&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |
| 5 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 10, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 14, &quot;facts&quot;: 10, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;inference&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 2, &quot;target&quot;: {&quot;inference&#95;cap&quot;: true}}</code> | <code>{&quot;dispatch&quot;: &quot;dispatched&quot;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;approved&quot;: {&quot;facts&quot;: 9, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 13, &quot;operation&quot;: &quot;read&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 2, &quot;state&quot;: &quot;no&#95;effect&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;approved&quot;: {&quot;facts&quot;: 10, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 14, &quot;operation&quot;: &quot;inference&quot;, &quot;resource&quot;: {&quot;inference&quot;: true}, &quot;session&quot;: 2, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;inference&#95;cap&quot;: true}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;7, 13, 14&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;14&#93;, &quot;resource&quot;: {&quot;inference&quot;: true}}, {&quot;calls&quot;: &#91;7&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |
| 6 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 17, &quot;facts&quot;: 3, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;exec&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 2, &quot;target&quot;: {&quot;entry&quot;: 2}}</code> | <code>{&quot;dispatch&quot;: &quot;dispatched&quot;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;approved&quot;: {&quot;facts&quot;: 9, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 13, &quot;operation&quot;: &quot;read&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 2, &quot;state&quot;: &quot;no&#95;effect&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;approved&quot;: {&quot;facts&quot;: 10, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 14, &quot;operation&quot;: &quot;inference&quot;, &quot;resource&quot;: {&quot;inference&quot;: true}, &quot;session&quot;: 2, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;inference&#95;cap&quot;: true}}, {&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 17, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 2}, &quot;session&quot;: 2, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;entry&quot;: 2}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 2, &quot;installation&quot;: 0}, {&quot;entry&quot;: 1, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;7, 13, 14, 17&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;17&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 2}}, {&quot;calls&quot;: &#91;14&#93;, &quot;resource&quot;: {&quot;inference&quot;: true}}, {&quot;calls&quot;: &#91;7&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |
| 7 | <code>{&quot;appended&quot;: true, &quot;kind&quot;: &quot;read&quot;, &quot;operation&quot;: &quot;exec&quot;, &quot;provenance&quot;: &quot;adapter observation&quot;, &quot;reports&quot;: &quot;succeeded&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;source&quot;: &quot;job&#95;record&quot;}</code> | <code>{&quot;settled&quot;: &#91;7&#93;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;terminal&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;approved&quot;: {&quot;facts&quot;: 9, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 13, &quot;operation&quot;: &quot;read&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 2, &quot;state&quot;: &quot;no&#95;effect&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;approved&quot;: {&quot;facts&quot;: 10, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 14, &quot;operation&quot;: &quot;inference&quot;, &quot;resource&quot;: {&quot;inference&quot;: true}, &quot;session&quot;: 2, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;inference&#95;cap&quot;: true}}, {&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 17, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 2}, &quot;session&quot;: 2, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;entry&quot;: 2}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 2, &quot;installation&quot;: 0}, {&quot;entry&quot;: 1, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;7, 13, 14, 17&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;17&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 2}}, {&quot;calls&quot;: &#91;14&#93;, &quot;resource&quot;: {&quot;inference&quot;: true}}, {&quot;calls&quot;: &#91;&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}&#93;}</code> |
| 8 | <code>{&quot;appended&quot;: true, &quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 20, &quot;facts&quot;: 3, &quot;kind&quot;: &quot;request&quot;, &quot;operation&quot;: &quot;exec&quot;, &quot;provenance&quot;: &quot;model request&quot;, &quot;session&quot;: 2, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}</code> | <code>{&quot;dispatch&quot;: &quot;dispatched&quot;}</code> | <code>{&quot;associations&quot;: &#91;{&quot;entry&quot;: 2, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 2}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 0}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;allocation&#95;index&quot;: 1}}, {&quot;entry&quot;: 1, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;calls&quot;: &#91;{&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 1}, &quot;call&quot;: 7, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 1, &quot;state&quot;: &quot;terminal&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;approved&quot;: {&quot;facts&quot;: 9, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 13, &quot;operation&quot;: &quot;read&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 2, &quot;state&quot;: &quot;no&#95;effect&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}, {&quot;approved&quot;: {&quot;facts&quot;: 10, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 14, &quot;operation&quot;: &quot;inference&quot;, &quot;resource&quot;: {&quot;inference&quot;: true}, &quot;session&quot;: 2, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;inference&#95;cap&quot;: true}}, {&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 17, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 2}, &quot;session&quot;: 2, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;entry&quot;: 2}}, {&quot;approved&quot;: {&quot;facts&quot;: 3, &quot;receipt&#95;binding&quot;: null, &quot;session&quot;: 2}, &quot;call&quot;: 20, &quot;operation&quot;: &quot;exec&quot;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}, &quot;session&quot;: 2, &quot;state&quot;: &quot;unresolved&quot;, &quot;target&quot;: {&quot;vendor&#95;machine&#95;id&quot;: 10}}&#93;, &quot;current&#95;installations&quot;: &#91;{&quot;entry&quot;: 1, &quot;installation&quot;: 0}, {&quot;entry&quot;: 2, &quot;installation&quot;: 0}&#93;, &quot;dispatched&quot;: &#91;7, 13, 14, 17, 20&#93;, &quot;dispositions&quot;: &#91;&#93;, &quot;durable&quot;: true, &quot;identity&#95;exclusions&quot;: &#91;{&quot;entry&quot;: 1, &quot;records&quot;: &#91;&#93;}, {&quot;entry&quot;: 2, &quot;records&quot;: &#91;&#93;}&#93;, &quot;prerequisite&#95;records&quot;: &#91;&#93;, &quot;quarantined&quot;: &#91;&#93;, &quot;reboot&#95;results&quot;: &#91;&#93;, &quot;receipts&quot;: &#91;&#93;, &quot;reinstall&#95;approvals&quot;: &#91;&#93;, &quot;reinstall&#95;withdrawals&quot;: &#91;&#93;, &quot;reset&#95;offer&quot;: &#91;&#93;, &quot;standing&quot;: &#91;&#93;, &quot;unresolved&quot;: &#91;{&quot;calls&quot;: &#91;20&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 1}}, {&quot;calls&quot;: &#91;17&#93;, &quot;resource&quot;: {&quot;machine&#95;entry&quot;: 2}}, {&quot;calls&quot;: &#91;14&#93;, &quot;resource&quot;: {&quot;inference&quot;: true}}&#93;}</code> |
<!-- /atlas-info -->

## Regeneration and checks

The informational region is maintained by
[`tools/render_state_machine_atlas.py`](../tools/render_state_machine_atlas.py).
It reads only committed witness data and the current formal-gate declaration index.
Run from the repository root:

```sh
nix develop --command bash tools/check-all.sh
nix develop --command python3 tools/render_state_machine_atlas.py --write
nix develop --command python3 tools/render_state_machine_atlas.py --check
nix develop --command python3 -m unittest discover -s tools/tests -v
nix develop --command bash tools/check-controls.sh
```

Check-all builds the declaration index before checking this projection. After an
intentional source change, regenerate and rerun check-all. Missing index, unsupported
schema/selected shape, ambiguous selection, unresolved declaration, incomplete
selected pair, missing local labels, malformed markers and stale output fail.
Write mode validates before changing the document and preserves prose outside its
markers. New fields/events or nonempty unsupported knowledge collections need
explicit renderer support; unrelated receipt cases may reuse declarations.
The source header includes the complete bound context, not an assertion that its
alphabet covers every event or that finite evaluation proves implementation safety.

Evidence: implementation evidence boundary. Applicability: this change provides
presentation checks only. No live vendor/device, downstream companion comparison,
effect ordering, concurrency or browser conformance evidence is claimed.
