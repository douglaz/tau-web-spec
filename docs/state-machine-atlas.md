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

Evidence: conceptual navigation, with checked owner quotations below.
Applicability: same approved resource, typed vendor and current installed
machine unless qualified. External outcomes remain unknown without admissible
evidence.

Each cell points directly to the defining document for the relevant requirement,
or to the existing decision record. It contains no separately maintained dispatch
decision. Read all applicable owners together; the [quoted passages](#authority)
below help locate their authority, barrier, command-hold and disposition clauses.
Publication routes to its own owners rather than acquiring a dispatch decision
from the witness projection.

The reading vocabulary remains distinct: **allowed subject to other guards**,
**refused**, **held**, and **not specified**. The owners supply permissions,
refusals and waits; the [open records](#open-owners-and-deliberate-boundaries)
retain undecided cases. A pointer in this matrix supplies no permission by itself.

| Action class | Current session / binding / approval authority | Unresolved create/order, activation or key registration | Unresolved reset / reinstall / destroy or stand-in stop | Unresolved box-plane command | Standing destructive disposition |
|---|---|---|---|---|---|
| Typed mutation on the approved entry, including create/order | [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock), [SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved), [STA-23](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state), [STA-20](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Adapter reconciliation read | [SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved), [STA-23](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-20](../03-state-and-recovery.md#durable-state), [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Ordinary `exec`, including a read through `exec` | [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock), [STA-23](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-20](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Harness-owned box-plane job, including a harness-composed read | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [STA-23](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-20](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Job-record collection (not a new job) | [STA-20](../03-state-and-recovery.md#durable-state), [STA-23](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-20](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Pin-checked connection (not permission to execute) | [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked), [STA-23](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) | [STA-24](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) | [STA-20](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) | [STA-24](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) |
| Inference request | [ARC-31a](../01-architecture.md#money), [STA-23](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [ARC-31a](../01-architecture.md#money), [STA-20](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state), [ARC-31a](../01-architecture.md#money) |
| Actionable publication | [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) | [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [tw-pkn](../.beads/issues.jsonl) |

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
| `{"bound": {"alphabet": [{"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}, {"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 2, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}, {"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}, {"appended": true, "kind": "read", "operation": "reset", "provenance": "adapter observation", "reports": "succeeded", "resource": {"machine_entry": 1}, "source": "adapter_read"}, {"appended": true, "calls": [1], "continuation": "destructive_reinstall", "kind": "dispose", "provenance": "disposition", "resource": {"machine_entry": 1}}, {"kind": "replay", "provenance": "replay"}, {"appended": true, "approved": {"facts": 5, "receipt_binding": null, "session": 1}, "call": 10, "facts": 5, "kind": "request", "operation": "activate", "provenance": "model request", "session": 1, "target": {"entry": 1}}, {"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}], "declaration": "TauWeb.Dispatch.bound", "events": 3, "start": {"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": []}}, "module": "dispatch", "namespace": "TauWeb.Dispatch", "schema": 8}` |

### same action new call id refused

Evidence: generated witness projection — same_action_new_call_id_refused.
Applicability: Typed resource barrier; reset requests, absent terminal evidence.

| Source metadata | Value |
|---|---|
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.same_action_new_call_id_refused"], "pair": {"side": "refused", "with": "TauWeb.Dispatch.same_action_new_call_id_admitted"}}` |
| Starting knowledge (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": []}` |

Evidence: generated witness projection — same_action_new_call_id_refused steps.
Applicability: Typed resource barrier; reset requests, absent terminal evidence. Source steps.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies to every source dispatch result.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}]}` |
| 2 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 2, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"calls": [1], "reason": "barrier"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}]}` |

### same action new call id admitted

Evidence: generated witness projection — same_action_new_call_id_admitted.
Applicability: Withdrawn-guard counterexample; resourceKey = call. Not a permissible continuation.

| Source metadata | Value |
|---|---|
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "call", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.same_action_new_call_id_admitted"], "pair": {"side": "admitted", "with": "TauWeb.Dispatch.same_action_new_call_id_refused"}}` |
| Starting knowledge (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": []}` |

Evidence: generated witness projection — same_action_new_call_id_admitted steps.
Applicability: Withdrawn-guard counterexample; resourceKey = call. Not a permissible continuation. Source steps.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies to every source dispatch result.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}]}` |
| 2 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 2, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 2, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [1, 2], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [2, 1], "resource": {"machine_entry": 1}}]}` |

### lnvps receipt confirms

Evidence: generated witness projection — lnvps_receipt_confirms.
Applicability: Stage-1 typed LNVPS restart receipt; vendor confirmation only, no guest/service/delivery evidence.

| Source metadata | Value |
|---|---|
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.lnvps_receipt_confirms"]}` |
| Starting knowledge (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": []}` |

Evidence: generated witness projection — lnvps_receipt_confirms steps.
Applicability: Stage-1 typed LNVPS restart receipt; vendor confirmation only, no guest/service/delivery evidence. Source steps.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies to every source dispatch result.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "restart", "signed_request": 73}, "session": 1}, "call": 1, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "restart", "signed_request": 73}, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}]}` |
| 2 | `{"appended": true, "kind": "receive", "provenance": "adapter observation", "receipt": {"binding": {"account": 41, "operation": "restart", "signed_request": 73}, "call": 1, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": false, "source": "browser_vendor_tls", "target": {"vendor_machine_id": 10}, "validated": true}}` | `{"settled": [1]}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "restart", "signed_request": 73}, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "restart", "signed_request": 73}, "call": 1, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": false, "source": "browser_vendor_tls", "target": {"vendor_machine_id": 10}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}]}` |
| 3 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "restart", "signed_request": 73}, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "restart", "signed_request": 73}, "call": 1, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": false, "source": "browser_vendor_tls", "target": {"vendor_machine_id": 10}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}]}` |

### second command held

Evidence: generated witness projection — second_command_held.
Applicability: Installed-system command hold; actual refusal reason is barrier.

| Source metadata | Value |
|---|---|
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.second_command_held"], "pair": {"side": "refused", "with": "TauWeb.Dispatch.second_command_without_hold"}}` |
| Starting knowledge (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": []}` |

Evidence: generated witness projection — second_command_held steps.
Applicability: Installed-system command hold; actual refusal reason is barrier. Source steps.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies to every source dispatch result.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}]}` |
| 2 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"calls": [7], "reason": "barrier"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}]}` |

### second command without hold

Evidence: generated witness projection — second_command_without_hold.
Applicability: Withdrawn-guard counterexample; commandHold = false. Not a permissible continuation.

| Source metadata | Value |
|---|---|
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": false, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.second_command_without_hold"], "pair": {"side": "admitted", "with": "TauWeb.Dispatch.second_command_held"}}` |
| Starting knowledge (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": []}` |

Evidence: generated witness projection — second_command_without_hold steps.
Applicability: Withdrawn-guard counterexample; commandHold = false. Not a permissible continuation. Source steps.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies to every source dispatch result.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}]}` |
| 2 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [7, 12], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [12, 7], "resource": {"machine_entry": 1}}]}` |

### hold reads and other machines

Evidence: generated witness projection — hold_reads_and_other_machines.
Applicability: Command collection and successor session; other-machine steps are stage-1 fixtures, not multi-machine admission. Named trace exceeds the enumeration bound.

| Source metadata | Value |
|---|---|
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.hold_reads_and_other_machines"]}` |
| Starting knowledge (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": []}` |

Evidence: generated witness projection — hold_reads_and_other_machines steps.
Applicability: Command collection and successor session; other-machine steps are stage-1 fixtures, not multi-machine admission. Named trace exceeds the enumeration bound. Source steps.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies to every source dispatch result.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}]}` |
| 2 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}]}` |
| 3 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 12, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "session": 2, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"calls": [7], "reason": "barrier"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}]}` |
| 4 | `{"appended": true, "approved": {"facts": 9, "receipt_binding": null, "session": 2}, "call": 13, "facts": 9, "kind": "request", "operation": "read", "provenance": "model request", "session": 2, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 9, "receipt_binding": null, "session": 2}, "call": 13, "operation": "read", "resource": {"machine_entry": 1}, "session": 2, "state": "no_effect", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [7, 13], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}]}` |
| 5 | `{"appended": true, "approved": {"facts": 10, "receipt_binding": null, "session": 2}, "call": 14, "facts": 10, "kind": "request", "operation": "inference", "provenance": "model request", "session": 2, "target": {"inference_cap": true}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 9, "receipt_binding": null, "session": 2}, "call": 13, "operation": "read", "resource": {"machine_entry": 1}, "session": 2, "state": "no_effect", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 10, "receipt_binding": null, "session": 2}, "call": 14, "operation": "inference", "resource": {"inference": true}, "session": 2, "state": "unresolved", "target": {"inference_cap": true}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [7, 13, 14], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [14], "resource": {"inference": true}}, {"calls": [7], "resource": {"machine_entry": 1}}]}` |
| 6 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 17, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "session": 2, "target": {"entry": 2}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 9, "receipt_binding": null, "session": 2}, "call": 13, "operation": "read", "resource": {"machine_entry": 1}, "session": 2, "state": "no_effect", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 10, "receipt_binding": null, "session": 2}, "call": 14, "operation": "inference", "resource": {"inference": true}, "session": 2, "state": "unresolved", "target": {"inference_cap": true}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 17, "operation": "exec", "resource": {"machine_entry": 2}, "session": 2, "state": "unresolved", "target": {"entry": 2}}], "current_installations": [{"entry": 2, "installation": 0}, {"entry": 1, "installation": 0}], "dispatched": [7, 13, 14, 17], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 2, "records": []}, {"entry": 1, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [17], "resource": {"machine_entry": 2}}, {"calls": [14], "resource": {"inference": true}}, {"calls": [7], "resource": {"machine_entry": 1}}]}` |
| 7 | `{"appended": true, "kind": "read", "operation": "exec", "provenance": "adapter observation", "reports": "succeeded", "resource": {"machine_entry": 1}, "source": "job_record"}` | `{"settled": [7]}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 9, "receipt_binding": null, "session": 2}, "call": 13, "operation": "read", "resource": {"machine_entry": 1}, "session": 2, "state": "no_effect", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 10, "receipt_binding": null, "session": 2}, "call": 14, "operation": "inference", "resource": {"inference": true}, "session": 2, "state": "unresolved", "target": {"inference_cap": true}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 17, "operation": "exec", "resource": {"machine_entry": 2}, "session": 2, "state": "unresolved", "target": {"entry": 2}}], "current_installations": [{"entry": 2, "installation": 0}, {"entry": 1, "installation": 0}], "dispatched": [7, 13, 14, 17], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 2, "records": []}, {"entry": 1, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [17], "resource": {"machine_entry": 2}}, {"calls": [14], "resource": {"inference": true}}, {"calls": [], "resource": {"machine_entry": 1}}]}` |
| 8 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 20, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "session": 2, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 9, "receipt_binding": null, "session": 2}, "call": 13, "operation": "read", "resource": {"machine_entry": 1}, "session": 2, "state": "no_effect", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 10, "receipt_binding": null, "session": 2}, "call": 14, "operation": "inference", "resource": {"inference": true}, "session": 2, "state": "unresolved", "target": {"inference_cap": true}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 17, "operation": "exec", "resource": {"machine_entry": 2}, "session": 2, "state": "unresolved", "target": {"entry": 2}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 20, "operation": "exec", "resource": {"machine_entry": 1}, "session": 2, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "dispatched": [7, 13, 14, 17, 20], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "standing": [], "unresolved": [{"calls": [20], "resource": {"machine_entry": 1}}, {"calls": [17], "resource": {"machine_entry": 2}}, {"calls": [14], "resource": {"inference": true}}]}` |
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
Cells display JSON in code spans, with control bytes and `<` escaped as JSON
and literal pipes protected for the table parser. The tests
and positive adversarial control parse tables with the Nix shell's pinned
`cmark-gfm` (table, strikethrough and autolink extensions), reject markup inside
code cells, and compare the displayed data with source.
The source header includes the complete bound context, not an assertion that its
alphabet covers every event or that finite evaluation proves implementation safety.

Evidence: implementation evidence boundary. Applicability: this change provides
presentation checks only. No live vendor/device, downstream companion comparison,
effect ordering, concurrency or browser conformance evidence is claimed.
