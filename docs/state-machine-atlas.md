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
[transition reference](#transition-reference) to follow an event, the
[combined matrix](#combined-matrix) to identify overlapping restrictions, the
[observation-to-authority reference](#observation-to-authority-reference) to interpret evidence, and the
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

The identity here is the origin-local store and its one live writer, not a session
or a recovered seed. The authoritative sources are the owners above and
[protected evidence §5](design/protected-evidence-v1.md#5-scan-reservations-and-attempt-fences)
for append eligibility and counted restart. Replay/derived-view references:
[STA-7/8](../03-state-and-recovery.md#durable-state). Access, writer ownership and
retirement reference: [STA-23](../03-state-and-recovery.md#durable-state).

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
  revive on return.” Pre-send/post-await fences and historical approvals:
  [STA-23](../03-state-and-recovery.md#durable-state). Procured-inference admission,
  cap and expiry: [ARC-31a](../01-architecture.md#money). Jump-host/Replace exceptions:
  [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock).
  Abandonment authorization: [SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved).

The identity is the rendering session and its bound machine entries; a typed
approval also names its approved facts. ARC-12 is the session owner, SEC-1 the
binding owner, SEC-4 the approval owner, and STA-23 the live-authority owner.
Durable history versus live authority: [STA-23](../03-state-and-recovery.md#durable-state).
Dedicated-path standing reinstall approvals:
[STG-20](../06-first-stage.md#what-the-first-stage-does-not-test).
`STG-20` says “An approval **stands** from its record until its reset is dispatched,
a matching withdrawal is recorded, or the session it was rendered for ends”.
`STG-20` says “This approval exists only on the dedicated path; at LNVPS the reinstall
call is itself the dispatch, so no approval waits.” Procured-key limits:
[ARC-31a](../01-architecture.md#money).

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

For authoritative identity and acceptance use STA-24's approved entry plus
[protected evidence §3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary);
unavailable literals, risk records and admitted mappings are distinct. Durable
intents and accepted evidence outlive transient adapter requests. Unresolved,
blocking, settlement and the standing continuation are derived journal views.
Confirmation, disposition and late-evidence reference: STA-24, *When the
restriction ends*. Independent restrictions route through the
[combined matrix](#combined-matrix). `STA-24` says “it neither reopens the call
nor removes the disposition”.

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
  LNVPS typed restart confirmation: [STG-21a](../06-first-stage.md#the-stages).
  Destructive dispositions and pending delivery check: [combined matrix](#combined-matrix).

The command key is machine plus tracked call/job, with the record's boot identity;
it is not the service the command launched. Browser intent and durably collected
advisory evidence differ from the transient collector and remotely reported process
state. STA-20/20b and [protected job replay](design/protected-evidence-v1.md#2-job-schema-and-replay)
own these representations. Liveness and hold are derived, not a universal completion
state. Terminal, ended-without-exit, missing-record and stopped-collection
references: [STA-20](../03-state-and-recovery.md#durable-state).
`STA-20` says “after a stopped wait only the operator resumes that flow, and nothing
left armed survives replay.”

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
  fingerprint, and a key that does not match MUST halt the session.” Command
  admission: [STA-20/24](../03-state-and-recovery.md#durable-state). Unavailable
  identity: [protected evidence §3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary).
  Encoding/scanning: [protected evidence §§1–5](design/protected-evidence-v1.md#1-decoder-boundary-and-facts).

The key is machine, installation group and pin source; rescue additionally keys
its pin by boot. Durable publication history, admitted pins and active/retired
status differ from transient polling and SSH connection state. CHN-R7 and SEC-11
are authoritative; [ADR-0043](adr/0043-lnvps-published-host-keys-admit-installed-system-pins.md)
and [ADR-0045](adr/0045-the-installation-label-moves-at-reinstall-dispatch.md)
route the installation decision and dispatch timing. Candidate completeness,
freshness, containment and active-pin eligibility are derived from retained
history. `CHN-R7` says “Without a reinstall, no installed-system pin from any
source replaces an active pin on that machine”. Vendor-resource mapping is the
separate §3a identity, not a host pin. Restored LNVPS pin contact additionally
routes to [STA-16](../03-state-and-recovery.md#recovery-by-access-model-and-vendor)
and the [pin re-entry reference](#pin-retirement-and-admission) below.

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
- **Permitted next actions / retirement:** pending-check and output references:
  [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) and
  [SEC-5](../04-security-model.md#sec-5--the-credential-inventory).
  `SEC-5` says “Unscanned bytes MUST be withheld”. Placement, finding clearance
  and delivery references: [ARC-17](../01-architecture.md#what-a-session-delivers).

The keys are the machine's declaration in force, each declared service/boot, and
placement identity (machine, application, secret name and path). ARC-39 and the
[declaration format](design/delivery-declaration-v1.md#shape) own the declaration;
ARC-17/43 own findings, placement gates, evidence labels and the pending check;
SEC-5 and [protected evidence §§1–5](design/protected-evidence-v1.md#1-decoder-boundary-and-facts)
own references, custody and release. Local scan material, sheet exclusion and
live arming: [SEC-5 row 23](../04-security-model.md#sec-5--the-credential-inventory)
and [protected evidence §5](design/protected-evidence-v1.md#5-scan-reservations-and-attempt-fences).
Derived-predicate references: delivery and placement at ARC-17/43; scan readiness
at SEC-5 and protected evidence §5. Placement inventory, finding retirement and
rotation/destruction references: ARC-17/43 and protected evidence §5.
`SEC-5` says “re-arm replaces it with a fresh key/reference”. `ARC-43` says “Re-arming neither reapproves the restored declaration
nor any weaker mode”.

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

STA-22b and the [seed/child-key format](design/credential-format-v1.md#seed-and-child-keys)
own the seed-id, derivation-version, family/index association; the
[recovery sheet format](design/credential-format-v1.md#recovery-sheet) owns its
export representation. Counters, tombstones and recovered metadata are durable;
unwrapped keys, bindings and session authority are transient. Allocation
eligibility is derived from generated/imported origin, ceremony record and consumed
indices. `STA-22b` says “old records are retained until migration is complete”.
Remote-key replacement: [STA-17](../03-state-and-recovery.md#recovery-by-access-model-and-vendor).
Restore labels/findings and LNVPS pin contact:
[STA-16](../03-state-and-recovery.md#recovery-by-access-model-and-vendor).
Scan re-arm: [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular).
Unknown pre-loss commands: [tw-ub7](../.beads/issues.jsonl).
`STA-16` says “Only a complete set equal to the pin keeps it active”. The
current-publication re-read reference is [below](#pin-retirement-and-admission).

## Transition reference

Evidence: conceptual navigation in every entry below. Applicability is local to
each entry. These are routes to owner clauses, not a transition schema or checked
composite trace. Available per-step Dispatch outcomes remain generated in
[Dispatch traces](#dispatch-traces); no prose guard is computed here.

### Dispatch and re-entry

Applicability: typed stage-1 requests and maintained-cloud re-entry; named operator flows retain their own authorization.

Event/key: a session request names a machine, or an operator flow names its target;
the worker resolves the approved entry under [STA-24, *The resource*](../03-state-and-recovery.md#durable-state).
Preconditions route to [SEC-1/4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved),
[STA-23](../03-state-and-recovery.md#durable-state) and
[the applicable matrix owners](#combined-matrix). Newly composed reads, adapter
reconciliation and record collection route to [STA-20/24](../03-state-and-recovery.md#durable-state). `STA-4` says “The record is appended immediately before the bytes
leave”. `STA-3` says “If the append fails, the transition does not occur.”
Recorded intent versus remote outcome: [STA-8/9](../03-state-and-recovery.md#durable-state).

Lost reply/interruption/re-entry route to STA-7/8 and STA-24's dispatch recheck;
`STA-5` says “No unresolved mutation is automatically replayed”.
Call identity, successor requests and the entry barrier: [STA-24](../03-state-and-recovery.md#durable-state).
`STA-20` says “A held request is not run and records no intent.” Evidence:
`TauWeb.Dispatch.dispatched_only_if` is the general admission property, while
`TauWeb.Dispatch.same_action_new_call_id_refused` and its generated pair expose the
resource-key trap. `TauWeb.Dispatch.replay_same_unresolved` assumes durable-before-apply
and initially matching memory/journal. Single writer, session termination and
external transmission ordering remain assumptions, not browser proofs.

### Result acceptance

Applicability: LNVPS operation evidence and installed jobs; Robot evidence only on its dedicated route.

Event/key: an adapter observation or exact-call receipt targets an earlier intent,
or an advisory machine record targets its own command. Preconditions/evidence
route to [STA-24, *What clears it*](../03-state-and-recovery.md#durable-state),
[STG-21a](../06-first-stage.md#the-stages), and
[protected evidence §3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary);
dedicated Robot reads use [STG-4](../06-first-stage.md#acceptance).
`STA-24` says “Confirmation evidence MUST identify the expected account, machine
and operation and be durably appended before taking effect.” `STA-24` says “Failed
append, timeout and operator disposition establish no success.” Settlement and
mapping admission: [protected evidence §3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary).
Independent pending-check, scan, session and pin references:
[combined matrix](#combined-matrix).

Failed append/lost reply and landed-record replay:
[protected evidence §3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary).
That section states “Landed-then-error latches the old writer; fresh authenticated
replay applies the landed evidence once without resend.” Duplicate, withheld,
quarantined, stale and replayed evidence: §3a's historical-admission and idempotence
clauses. Late evidence after disposition:
[STA-24, *When the restriction ends*](../03-state-and-recovery.md#durable-state).
For session-end publication, `STA-23` says “A stale message or late result MUST NOT
revive ended authority or publish an actionable result under stale authority.” Coverage:
`TauWeb.Dispatch.failed_append_keeps_barrier`,
`TauWeb.Dispatch.cloud_observation_sources`,
`TauWeb.Dispatch.cloud_receipt_correlated` and
`TauWeb.Dispatch.evidence_after_disposition_changes_nothing` carry their named
properties. Authenticated transport and genuine validation are assumptions;
operation-specific listing, subscription, deletion and freshness predicates and
protected byte encodings remain prose-only in the Dispatch opening boundary.

### Job-record collection

Applicability: installed stage-1 jobs; the rescue persistence and non-LNVPS delivery-reboot exceptions apply only on their named routes.

Event/key: collection on reconnect or while a held request waits, for the original
machine/call/job and its boot. [STA-20/20b/21](../03-state-and-recovery.md#durable-state)
and [protected job schema/replay](design/protected-evidence-v1.md#2-job-schema-and-replay)
own preconditions, machine agreement and advisory classification. `STA-20` says
“Only a terminal record releases the hold”. Missing/incomplete, running and
proven-ended classifications: [STA-20](../03-state-and-recovery.md#durable-state).
`STA-21` says “The job record is machine-reported and advisory.” Service evidence:
[ARC-43](../01-architecture.md#box-plane-execution-is-command-granular).
Cloud confirmation: [STA-24](../03-state-and-recovery.md#durable-state).

Failed/malformed, duplicate, late and already-settled reads:
[protected job replay §2](design/protected-evidence-v1.md#2-job-schema-and-replay).
Failed append: [STA-3](../03-state-and-recovery.md#durable-state).
`STA-20` says “stopping settles nothing, and a machine that cannot be reached is
answered at once”. Re-entry and installed/rescue persistence:
[STA-20/20b](../03-state-and-recovery.md#durable-state). Coverage:
`TauWeb.Dispatch.hold_reads_and_other_machines` and the generated held pair show
collection versus new commands. The wait, stopped flow and collection procedure
are prose-only. The dedicated exception is
`TauWeb.Dispatch.deliveryRebootResult`, with
`TauWeb.Dispatch.delivery_reboot_new_boot_settles` and
`TauWeb.Dispatch.delivery_reboot_failed_append_holds`: the own-record/new-boot
result settles the dedicated reboot, not LNVPS's typed restart.

### Operator disposition

Applicability: typed stage-1 resources; dedicated preparation only where explicitly named; untyped boundaries remain separate.

Event/key: the operator names unresolved calls on one resource, or replaces its
standing disposition. Preconditions and replay validity live at
[STA-24, *What a disposition may name* / *On replay*](../03-state-and-recovery.md#durable-state).
`STA-24` says “A disposition keeps the outcome *unknown*” and “A disposition is a
terminal record of its own kind”. Durable recording, replacement, unnamed calls
and identity exclusions: [STA-24](../03-state-and-recovery.md#durable-state).
Failed append: [STA-3](../03-state-and-recovery.md#durable-state). `STA-24` says
“every call it names MUST be unresolved, on the disposition's own resource, in the
journal as it stands before the disposition.” `STA-24` says “Otherwise it is refused
and nothing is recorded”.

Effects route to *What a disposition reaches*, *A destructive continuation stops
every box-plane job* and *When the restriction ends*, with
[ADR-0044's amendments](adr/0044-a-disposition-limits-what-its-calls-barred.md),
[ADR-0048](adr/0048-an-unresolved-command-holds-its-machine.md) and
[ADR-0050](adr/0050-destructive-dispositions-stop-every-box-plane-job.md).
`STA-24` says “The restriction ends when the continuation it names is dispatched,
its intent durably appended”. Preparation, reads, interruption and late evidence:
[STA-24, *When the restriction ends*](../03-state-and-recovery.md#durable-state).
Coverage: `TauWeb.Dispatch.replayed_invalid_disposition_means_nothing`,
`TauWeb.Dispatch.read_and_inference_unrestricted`,
`TauWeb.Dispatch.preparation_keeps_restriction` and
`TauWeb.Dispatch.destructive_choice_stops_commands` name the relevant properties.
They do not carry untyped pause/hold, re-arm or the entire continuation flow.

### Session end

Applicability: every local session; procured-key limits only on the procured inference path.

Event/key: individual session end or the processed Lock/pagehide/reload/shutdown
boundary in [STA-23](../03-state-and-recovery.md#durable-state); session, bindings,
pending approvals and channels route also to [SEC-1/4](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock)
and [ARC-12](../01-architecture.md#sessions-binding-and-diversity) /
[ARC-31a](../01-architecture.md#money).
`STA-23` says “The actual end fence is irreversible and MUST NOT be reset to
implement continuation.” Begun appends and possibly sent effects:
[STA-3/8](../03-state-and-recovery.md#durable-state).
`STA-23` says “Already accepted remote work may continue even after local Lock or
loss.” Individual-session versus store-wide end:
[STA-23](../03-state-and-recovery.md#durable-state). Procured-key expiry/cap/clock:
[ARC-31a](../01-architecture.md#money).

Lost replies, stale results, repeated lifecycle notifications, worker restart and
historical approvals: [STA-23](../03-state-and-recovery.md#durable-state) and the
[session/approval region](#sessions-and-approvals). Coverage: prose-only end
fence; Dispatch assumes ended sessions send no requests and successor sessions
act after replay. `TauWeb.Dispatch.ended_session_approval_refused` exercises an
approval bound to an ended rendering session under that convention; it is no
proof of browser termination. The separate assurance owner is
[tw-237.4](../.beads/issues.jsonl).

### Processed suspension and validated continuation

Applicability: every surviving local worker/session; the backup ceremony has its separate hide behavior.

Event/key: a processed freeze/suspension or interruption, then continuation of the
same surviving worker/session. [STA-23](../03-state-and-recovery.md#durable-state)
owns the distinction from ordinary hide, the backup ceremony's exceptional hide,
and actual session end. `STA-23` says “A begun durable append MUST finish whole
rather than be cancelled partway.” Binding/writer ownership and continuation
fences: [STA-23](../03-state-and-recovery.md#durable-state). Its validation list
is quoted in [Authority](#authority). Remote uncertainty:
[STA-8/24](../03-state-and-recovery.md#durable-state). Pin admission:
[SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked). Procured-key
limits: [ARC-31a](../01-architecture.md#money).

`STA-23` says “if it cannot identify one it MUST show reconciliation or required
operator action and wait.” Failure/re-entry references: [STA-3/8/23](../03-state-and-recovery.md#durable-state)
for failed append, lost reply and duplicate/stale messages. `STA-23` says “Phones
may freeze or discard the page without a final callback; no background execution
window, memory survival, socket continuity or timely cleanup is promised.” Coverage: prose-only lifecycle validation; Dispatch's session
convention and the separate tw-237.4 assurance seam are the limits, not a checked
suspension/dispatch composition.

### Pin retirement and admission

Applicability: stage-1 LNVPS reinstall/Restore; the reset-into-rescue and other pin-source routes remain route-specific.

Event/key: operator-chosen destructive reinstall dispatch; candidate pin
observation and its route provenance. Preconditions, evidence and authority route to
[STG-20](../06-first-stage.md#what-the-first-stage-does-not-test),
[CHN-R7 and the other routes](../02-channel.md#the-routes-to-a-fingerprint),
[SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked),
[ADR-0045](adr/0045-the-installation-label-moves-at-reinstall-dispatch.md) and
STA-3. `STG-20` says the reinstall “opens a new installation when it is
**dispatched**”. Installation identity, retirement, comparison-before-retention
and candidate completeness/freshness/containment:
[CHN-R7](../02-channel.md#the-routes-to-a-fingerprint). Reinstall confirmation:
[STG-21a](../06-first-stage.md#the-stages). Contact versus command admission:
[SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) and
[STA-20/24](../03-state-and-recovery.md#durable-state).

Failed append/lost reply: [STA-3/8/24](../03-state-and-recovery.md#durable-state).
`CHN-R7` says “A refused or repeated observation cannot rewrite the active pin or
its provenance.” Publication, re-entry and unavailable-wire identity:
[CHN-R7](../02-channel.md#the-routes-to-a-fingerprint) and
[protected evidence §3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting).
Restored LNVPS contact: [STA-16](../03-state-and-recovery.md#recovery-by-access-model-and-vendor).
`STA-16` says “before an active `lnvps_retrieve` pin restored from it admits a contact,
the harness MUST read the machine's current published set by `CHN-R7`'s direct fetch.”
`STA-16` says “Only a complete set equal to the pin keeps it active.” Empty, partial,
different or failed reads and reinstall/abandonment:
[STA-16](../03-state-and-recovery.md#recovery-by-access-model-and-vendor) and
[ARC-22](../01-architecture.md#post-harness-machinery-and-finishing-a-setup).
This restored-sheet contact check is prose-only, not added to the Pins properties below.

Coverage: `TauWeb.Pins.retired_pin_not_active`,
`TauWeb.Pins.installed_pin_from_authorized_source`,
`TauWeb.Pins.complete`, `TauWeb.Pins.fresh` and
`TauWeb.Pins.withinInstallation` carry symbolic history/source/handshake properties;
they do not prove a vendor publication true. No cross-module composition with
Dispatch is asserted, and jump-host first contact is outside Pins's sources.

### Delivery publication, placement and re-check

Applicability: stage-1 LNVPS delivery/re-entry; non-LNVPS delivery reboot remains its separate route.

Event/key: harness-composed check observations for the machine's declaration in
force and declared service/boot; operator declaration amendment/placement approval
have separate provenance. [ARC-17/39](../01-architecture.md#what-a-session-delivers),
[ARC-43](../01-architecture.md#box-plane-execution-is-command-granular),
[SEC-5](../04-security-model.md#sec-5--the-credential-inventory) and
[protected evidence](design/protected-evidence-v1.md#1-decoder-boundary-and-facts)
own authority, durable verdict, scan/custody and publication preconditions.
`ARC-43` says the pending hold runs “until the delivery check's verdict is durably
journaled”; it also says “A stop settles no verdict and is shown as a stopped
check, never as a pass.” Failed verdict append: [STA-3](../03-state-and-recovery.md#durable-state).
Lost/interrupted, refused/held or missing reads:
[ARC-43](../01-architecture.md#box-plane-execution-is-command-granular).
Duplicate/stale publication: [STA-23](../03-state-and-recovery.md#durable-state).
Re-entry service reads/restored labels: [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular)
and [STA-16](../03-state-and-recovery.md#recovery-by-access-model-and-vendor).

Findings, lifecycle labels, scan arming and permission-to-place references:
[ARC-17/43](../01-architecture.md#what-a-session-delivers) and
[SEC-5](../04-security-model.md#sec-5--the-credential-inventory).
`ARC-17` says “Every other finding, a lockdown finding included, still refuses
placement” and “placement itself clears no finding.” Lifecycle-only placement,
fixed lockdown prerequisites, re-check and placing-session demonstration:
[ARC-17](../01-architecture.md#what-a-session-delivers). Labels and report-only
checks route to the [observation reference](#boot-and-service-observations) below.
Coverage: `TauWeb.Declaration.delivered_specified` covers field presence under
Declaration's own transitions, not real service evidence. Pending-check hold,
lifecycle reads/labels, placement, re-arm and publication fences remain prose-only;
neither Dispatch nor Declaration proves this combined flow.

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

| Action class | Current session / binding / approval authority | Unresolved create/order, activation, key registration or renewal-off | Unresolved reset / reinstall / destroy or stand-in stop | Unresolved box-plane command | Standing destructive disposition |
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
session.” `SEC-4` says “What is dispatched is the approved record.”
`SEC-4` says “A session's vendor operations reach the machines of its own set and
account-level creation, nothing else.”
`STA-23` says “A stale message or late
result MUST NOT revive ended authority or publish an actionable result under stale
authority.” `STA-23` says “current authority, bindings, holds, connection state
and scan readiness.” Continuation validation reference:
[STA-23](../03-state-and-recovery.md#durable-state).

### Cloud barrier

Evidence: conceptual navigation. Applicability: resource-local typed operations;
untyped vendor scopes have the wider, prose-only pause/hold at STA-24.

Owner: [STA-24](../03-state-and-recovery.md#durable-state).

`STA-24` says “the harness worker MUST NOT
dispatch a side-effecting operation naming that resource” while a call is
unresolved. `STA-24` says “An unresolved activation or key registration touches
no running system and blocks nothing on the box.” `STA-24` says “stops box-plane
dispatch to that machine from its intent until its confirmation.”
`STA-24` says “Reads naming the resource — the adapter's status queries, the pinned
SSH attempt that is `STG-4`'s third predicate, the collection of job records — are
permitted”. For inference, `STA-24` says “does **not** bar the next request”.
Operation-specific evidence and durable acceptance:
[STG-21a](../06-first-stage.md#the-stages), dedicated
[STG-4](../06-first-stage.md#acceptance), and [STA-24](../03-state-and-recovery.md#durable-state).

### Command hold

Evidence: conceptual navigation. Applicability: every unresolved box-plane
command on the machine, including session succession.

Owner: [STA-20](../03-state-and-recovery.md#durable-state).

`STA-20` says “a read through `exec` is a
command, and a job the harness composes is held too.” `STA-20` says “Collecting a job
record is not held, and other machines are unaffected” and “A held request is not
run and records no intent.” Terminal-record release:
[STA-20](../03-state-and-recovery.md#durable-state). Standing dispositions:
[STA-24](../03-state-and-recovery.md#durable-state). The generated
held trace retains the source result `dispatch: refused`, `reason: barrier`.
The wait and flow-resumption procedure are prose-only; see
[ADR-0048](adr/0048-an-unresolved-command-holds-its-machine.md).

### Destructive disposition

Evidence: conceptual navigation. Applicability: typed machines, every requester;
untyped harness-started-job reach remains the separate question below.

Owner: [STA-24](../03-state-and-recovery.md#durable-state).

`STA-24` says “A standing disposition
restricts, to its continuation, what the calls it names barred while they were
unresolved.” `STA-24` says “the harness worker MUST refuse every
box-plane job to that machine, whatever the disposed call was and whoever starts
it”. `STA-24` says “Reads stay permitted throughout” and “A session's request for
that destroy or stop under a standing abandonment MUST be refused”. Preparation
and the operation that ends the restriction route to STA-24's *When the
restriction ends*. New-intent barriers and late evidence:
[STA-24](../03-state-and-recovery.md#durable-state). See
[ADR-0044, with amendments](adr/0044-a-disposition-limits-what-its-calls-barred.md)
and [ADR-0050](adr/0050-destructive-dispositions-stop-every-box-plane-job.md).

### Pins, output and pending check

Evidence: conceptual navigation. Applicability: all apparent permissions in the
matrix, with the local qualifications in the extension below.

For pin admission use [CHN-R7](../02-channel.md#the-routes-to-a-fingerprint)
and [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked).
For output use [SEC-5](../04-security-model.md#sec-5--the-credential-inventory).
`SEC-5` says “Unscanned bytes MUST be withheld”. See also
[protected evidence](design/protected-evidence-v1.md#1-decoder-boundary-and-facts).
For new-order exclusion use its [§3a](design/protected-evidence-v1.md#3a-protected-operation-evidence).
For the [pending-check hold](../01-architecture.md#box-plane-execution-is-command-granular),
`ARC-43` says “until the delivery check's verdict is durably
journaled”. `ARC-43` says “holds the model's box-plane commands to that machine”.
`ARC-43` says “A stop settles no verdict and is shown as a stopped check, never as a pass.”
That hold, scan readiness and actionable publication are outside the Dispatch
projection below. LNVPS restart, guest boot, service survival, final verdict and
pin admission references: [observation-to-authority reference](#observation-to-authority-reference).

### Pending check, scanning and identity overlaps

Evidence: conceptual navigation, prose-only except §3a's symbolic identity guards
carried by Dispatch. Applicability: typed stage-1 installed machine in the first
three columns; the last column is deferred untyped-vendor material. Each cell
points to the owning clauses or existing decision record. Read their scope in
the checked quotations below; the table maintains no separate classifications.

| Action class | Pending post-restart delivery check | Required scan reference unarmed / protected release | Vendor identity unavailable, quarantined or excluded | Untyped vendor pause / destructive hold |
|---|---|---|---|---|
| Typed mutation | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [STA-24](../03-state-and-recovery.md#durable-state) | [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [§§1–5](design/protected-evidence-v1.md#1-decoder-boundary-and-facts) | [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Adapter reconciliation read | [STA-24](../03-state-and-recovery.md#durable-state) | [§§1–5](design/protected-evidence-v1.md#1-decoder-boundary-and-facts) | [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Ordinary `exec` | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) | [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Harness-owned job | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [§3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary) | [tw-pgp](../.beads/issues.jsonl), [STA-24](../03-state-and-recovery.md#durable-state) |
| Job-record collection | [STA-20](../03-state-and-recovery.md#durable-state), [STA-24](../03-state-and-recovery.md#durable-state) | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting) | [STA-20](../03-state-and-recovery.md#durable-state), [STA-24](../03-state-and-recovery.md#durable-state) |
| Pin-checked connection | [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) | [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) | [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting), [CHN-R7](../02-channel.md#the-routes-to-a-fingerprint) | [STA-24](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) |
| Inference request | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [ARC-31a](../01-architecture.md#money) | [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [§3](design/protected-evidence-v1.md#3-protected-inference-terminals) | [ARC-31a](../01-architecture.md#money) | [STA-24](../03-state-and-recovery.md#durable-state), [ARC-31a](../01-architecture.md#money) |
| Actionable publication | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) | [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [§3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary) | [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [tw-pkn](../.beads/issues.jsonl) |

The decisive owner passages, rather than the matrix pointers, are:

- `ARC-43` says “holds the model's
  box-plane commands to that machine”. Its pending-check hold and lifecycle reads
  are **prose-only**. STA-20's broader command hold is not silently substituted.
- `ARC-43` says “Model `exec` across the bound set MUST wait while any known required
  placement reference is unarmed” and “Only harness jobs whose output goes to
  **neither** model nor transcript are exempt”. `ARC-43` says “release their
  verdict and findings, never their raw output”. Additional job-admission references:
  [STA-20/24](../03-state-and-recovery.md#durable-state).
  `SEC-5` says “Unscanned bytes MUST be withheld”. Settlement reference:
  [protected evidence §3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary).
- `STA-24` says “reads, dispositions and
  operations through already admitted mappings are unaffected” by the unavailable-
  identity order exclusion. [Protected evidence §3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary)
  states “No current predicate discharges it.” Its exact-target boundary states
  “A withheld ID, quarantine, marker, receipt or association number, or independently
  generated handle resolves nothing.”
- `STA-24` says “no further call under that scope is dispatched
  while it is unresolved” and “nothing under a scope counts as a read, because nothing types it”
  and, for destructive untyped hold, “keeps the model's box-plane commands to the
  machines of the session's bound set at that vendor stopped until the operator
  replaces it”. The typed every-requester stop does not settle
  [tw-pgp](../.beads/issues.jsonl). These untyped restrictions are prose-only and
  retain the later-route applicability in the admission list.
  For the open-call pause, `STA-24` says “while a call under that scope is open — sent, and not yet
  answered — or unresolved, the harness worker MUST NOT dispatch a box-plane command to any
  machine of the session's bound set at that vendor.”

For overlapping restrictions, follow these owner routes together:

- Command-terminal collection versus cloud uncertainty/disposition:
  [Command hold](#command-hold), [Cloud barrier](#cloud-barrier),
  [Destructive disposition](#destructive-disposition).
- LNVPS restart confirmation versus pending delivery check:
  [STG-21a](../06-first-stage.md#the-stages) and
  [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular).
- Scan re-arm/local paste versus destructive continuation:
  [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) and
  [STA-24](../03-state-and-recovery.md#durable-state).
- Renewal-off versus running-system mutations:
  [STG-21](../06-first-stage.md#the-stages) and
  [STA-24](../03-state-and-recovery.md#durable-state).
  `STA-24` says “Box-plane dispatch to the machine is governed by `STA-20` and
  `STA-20b`, not by this rule”. For the exception, see [Cloud barrier](#cloud-barrier).
- Failure/successor allocation:
  [tw-sfu/tw-hwl/tw-nj8](../.beads/issues.jsonl). Installation/recovery:
  [tw-l1l/tw-lq8/tw-yhd](../.beads/issues.jsonl). Restored-command boundary:
  [tw-ub7](../.beads/issues.jsonl).

These are navigation routes, not additional checked traces or a first-error order.

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
  jobs ([tw-yuo](../.beads/issues.jsonl)). At the reviewed `d00c735` baseline, the
  requirement amendments for these recovery and privilege decisions remain
  outstanding. These entries describe that baseline, rather than amendments on
  other branches. No post-Restore sweep/hold or privilege route is added.
- **Not specified:** LNVPS's third recovery rung ([tw-ae7](../.beads/issues.jsonl));
  destruction/output ([tw-pkn](../.beads/issues.jsonl)); rescue activation beside
  delivery reboot ([tw-z99](../.beads/issues.jsonl)). The recovery figures are
  conceptual navigation, with their existing policy and stand-ins retained.
- Allocation questions stay with [tw-sfu, tw-hwl, tw-nj8](../.beads/issues.jsonl);
  installation/recovery questions with [tw-lq8, tw-l1l, tw-yhd](../.beads/issues.jsonl).
  This outline chooses no answers to them.
- [tw-316](../.beads/issues.jsonl) owns corpus-wide witness-pair validation;
  [tw-itv](../.beads/issues.jsonl) retains approval-facts and bounded-description
  work. The renderer below validates only the selected projection inputs.

## Observation-to-authority reference

Evidence: conceptual navigation throughout this reference. Applicability: typed
LNVPS unless a route is explicitly named. Every observation still meets its
owner's source, identity, validation, custody and durable-acceptance conditions.
A successful-looking sequence supplies no additional authority.

### Vendor receipts and status reads

| Observation | Predicate owners | Boundary owners |
|---|---|---|
| Exact-call vendor receipt | [STA-24](../03-state-and-recovery.md#durable-state), [STG-21a](../06-first-stage.md#the-stages) | [§3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) |
| Authenticated status/listing | [STG-21/21a](../06-first-stage.md#the-stages) | [STG-21a](../06-first-stage.md#the-stages), [STA-24](../03-state-and-recovery.md#durable-state) |
| Protected receipt/association | [§3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary) | [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting), [STA-24](../03-state-and-recovery.md#durable-state) |

`STA-24` says “A generic 2xx, an unrelated response or an unvalidated/malformed body
is insufficient.” `STG-21a` says order confirmation “establishes no host creation,
IP allocation, invoice production, payment, boot or contact readiness.”
For restart, `STG-21a` says “Only a recorded successful response correlated to this exact
restart request confirms the vendor’s report of successful hard-reset task
completion” and “It does not establish a completed guest boot or service survival.”
Guest-boot read versus restart confirmation:
[ARC-43](../01-architecture.md#box-plane-execution-is-command-granular).
`ARC-43` says “Operation-confirmation evidence admitted by STA-24 supplies
authority only for that operation’s result, not for delivery checks or host-key
pins.” For stop, `STG-21a` says “no currently identified status-read-only predicate
qualifies”. Dedicated Robot observable-state predicates:
[STG-4](../06-first-stage.md#acceptance).

Coverage boundary: Dispatch carries abstract source/correlation and symbolic
identity guards. Its opening assumptions leave the detailed STG-21a predicates,
protected encodings and listing selection in prose. The generated receipt trace
below establishes no live vendor or device evidence.

### Job records and model-written reports

[STA-20/21](../03-state-and-recovery.md#durable-state) own command/boot classification,
and [protected evidence §2](design/protected-evidence-v1.md#2-job-schema-and-replay)
owns retained/withheld facts and truthful advisory comparison. `STA-20` says “A
record with no exit code and a proven-ended command means it died; the call stays
unresolved”. Terminal command acceptance:
[STA-20/24](../03-state-and-recovery.md#durable-state). Measured values and service
liveness: [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular).
`STA-24` says a job record “cannot clear a cloud-plane barrier”.

Report-only checks: [ARC-39](../01-architecture.md#what-a-session-delivers).
`ARC-39` says “Neither success nor failure counts toward Delivered, creates or clears a
finding, or blocks delivery or secret placement.” `ARC-43` says “never from model text”.
Typed values and measuring procedures: [declaration format](design/delivery-declaration-v1.md#shape).
Coverage: Dispatch carries selected command classification/settlement; actual
job truth, output protection, delivery authority and report-only treatment remain
prose/implementation obligations, not proven by the command witnesses.

### Host-key publications

[CHN-R7](../02-channel.md#the-routes-to-a-fingerprint) owns complete/fresh/contained
publication history and installed-pin admission. Direct-fetch provenance:
[CHN-R7](../02-channel.md#the-routes-to-a-fingerprint).
`CHN-R7` says “This is a vendor-published observation, not an attestation.”
Reinstall baseline/post-dispatch evidence:
[STG-21a](../06-first-stage.md#the-stages). Empty-group pin admission versus
reinstall confirmation: [CHN-R7](../02-channel.md#the-routes-to-a-fingerprint)
and [STA-24](../03-state-and-recovery.md#durable-state). Operation confirmation,
session authority and service evidence: [combined matrix](#combined-matrix).
Rescue/attest producers, boot/sender identity and acceptance:
[CHN-R1/R5](../02-channel.md#the-routes-to-a-fingerprint). Pins carries
symbolic admission/history; vendor/address-scan truth and integrated absence of
contact remain outside that property.

### Boot and service observations

`STA-20` says “a PID from another boot cannot establish liveness”. Ordinary
changed-boot evidence: [STA-20](../03-state-and-recovery.md#durable-state).
Non-LNVPS `delivery_reboot`, own-job/own-machine/new-boot and ordinary `exec`:
[ARC-43](../01-architecture.md#box-plane-execution-is-command-granular).
`ARC-43` says “claims the observed boot change, never an exit status or a cause.”
LNVPS restart confirmation: [STG-21a](../06-first-stage.md#the-stages).

For delivery, use [ARC-43's evidence clauses](../01-architecture.md#box-plane-execution-is-command-granular)
and [ARC-17's placing-session demonstration](../01-architecture.md#what-a-session-delivers):

| Observation or local condition | Evidence owners | Independent-boundary owners |
|---|---|---|
| Enablement read without demonstrated reboot | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) |
| New guest boot plus active unit after the approved reboot | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [STG-21a](../06-first-stage.md#the-stages), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) |
| `running-at-delivery` found running | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) |
| Stopped after a changed boot, previously running there | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [ARC-17](../01-architecture.md#what-a-session-delivers) |
| Failed/held/refused/no-record check | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [STA-20/24](../03-state-and-recovery.md#durable-state), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) |
| Lifecycle finding versus another finding | [ARC-17](../01-architecture.md#what-a-session-delivers) | [ARC-17](../01-architecture.md#what-a-session-delivers), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) |

`ARC-43` says “That labelled state is no difference from the declaration, raises
no lifecycle finding, and leaves the machine Delivered when its checks otherwise
pass.” `ARC-43` says “enabled, restart not demonstrated” and
“stopped since a restart, as approved”. For `running-at-delivery`, `ARC-43` says
“A boot change never clears a standing lifecycle finding”. `ARC-17` says
“A finding is cleared by a re-check and by nothing else” and “placement itself clears no finding.”
For a machine-derived scan reference, `ARC-43` says “re-armed from the machine's report”.
`ARC-43` says “It covers no forgotten placement.” Reapproval, original-value evidence
and rotation references: [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular)
and [SEC-5](../04-security-model.md#sec-5--the-credential-inventory). Coverage: these lifecycle/placement/re-arm
boundaries are prose-only, distinct from Declaration's coarse field predicates
and Dispatch's dedicated-reboot terminal property.

### Notifications

Applicability: notify/attest routes; stage-1 LNVPS uses no notify channel.
Owner: [CHN-17](../02-channel.md#the-attest-sequence).
`CHN-17` says “a machine may send the harness an event, and an event is an observation.”
`CHN-17` says “never gates a step, never triggers an action”. Attest introduction,
planted-sender identity and single-use browser acceptance:
[CHN-R5](../02-channel.md#the-routes-to-a-fingerprint) and
[CHN-5](../02-channel.md#the-attest-sequence). Candidate notification uses:
[CHN-17](../02-channel.md#the-attest-sequence). The relay companion's historical profile is not a proof of
current relay `/v2/`, notify delivery or these composition boundaries; the port
remains [TASKS.md T30](../TASKS.md).

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
