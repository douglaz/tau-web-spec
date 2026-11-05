# State-machine atlas

An informational navigation aid for **the typed LNVPS path and maintained-cloud
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
[Dispatch traces](#dispatch-traces), [Allocation traces](#allocation-traces),
[Pins traces](#pins-traces) and [Declaration traces](#declaration-traces) to inspect
serialized harness knowledge.
The [source-finding record](review/2026-11-03-atlas-source-finding.md) records checked
answers and dispositions; the [implementation evidence handoff](design/atlas-implementation-handoff.md)
names the immutable fixture contract and downstream evidence still owed.
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
  [Capability applicability and admission](../07-conformance.md#capability-applicability-and-admission).

## Region outline

### Store and writer ownership

Evidence: conceptual navigation. Applicability: every local store, including recovery.

Owner: [STA-1–STA-3 and STA-7](../03-state-and-recovery.md#durable-state),
[STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone).

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
retirement reference: [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone).

### Sessions and approvals

Evidence: conceptual navigation. Applicability: LNVPS-path single-machine sessions;
multi-machine admission belongs to the separate untyped-scope, jump-host and sets-above-one row in the admission list.

Owners: [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone),
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
  [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone). Procured-inference admission,
  cap and expiry: [ARC-31a](../01-architecture.md#money). Jump-host/Replace exceptions:
  [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock).
  Abandonment authorization: [SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved).

The identity is the rendering session and its bound machine entries; a typed
approval also names its approved facts. ARC-12 is the session owner, SEC-1 the
binding owner, SEC-4 the approval owner, and STA-23 the live-authority owner.
Durable history versus live authority: [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone).
Dedicated-path standing reinstall approvals:
[STG-20](../06-first-stage.md#what-the-lnvps-path-does-not-test).
`STG-20` says “An approval **stands** from its record until its reset is dispatched,
a matching withdrawal is recorded, or the session it was rendered for ends”.
`STG-20` says “This approval exists only on the dedicated path; at LNVPS the reinstall
call is itself the dispatch, so no approval waits.” Procured-key limits:
[ARC-31a](../01-architecture.md#money).

### Cloud and reconciliation

Evidence: conceptual navigation. Applicability: typed LNVPS now; Robot/rescue
confirmation predicates are dedicated-route material, not LNVPS predicates.

Owners: [STA-4, STA-8, STA-24](../03-state-and-recovery.md#durable-state),
[STG-21/21a](../06-first-stage.md#the-paths-and-their-gates), and dedicated
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

Evidence: conceptual navigation. Applicability: installed systems on the LNVPS path;
rescue's persistence exception and reset prerequisites are dedicated-route material.

Owners: [STA-20/20b](../03-state-and-recovery.md#durable-state),
[ARC-43](../01-architecture.md#box-plane-execution-is-command-granular).

LNVPS root access: [STG-21](../06-first-stage.md#the-paths-and-their-gates),
[STA-20](../03-state-and-recovery.md#durable-state).

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
  LNVPS typed restart confirmation: [STG-21a](../06-first-stage.md#the-paths-and-their-gates).
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

Evidence: conceptual navigation. Applicability: CHN-R7 for the LNVPS path;
CHN-R1 is dedicated/rescue, CHN-R5 attest is route-specific, CHN-R6 jump-host
contact belongs to the jump-host row. CHN-R2/3/4 retain their rejected-route status.

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

Evidence: conceptual navigation. Applicability: the LNVPS path and re-entry;
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

Evidence: conceptual navigation. Applicability: maintained-cloud recovery on
the LNVPS path; dedicated relabel/rescue migration is route-specific.

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
Journal-only command protection and lost-journal/backup boundary:
[STA-20/STA-24](../03-state-and-recovery.md#durable-state).
`STA-20` says “The command hold is journal-only.”
`STA-16` says “Only a complete set equal to the pin keeps it active”. The
current-publication re-read reference is [below](#pin-retirement-and-admission).

## Transition reference

Evidence: conceptual navigation in every entry below. Applicability is local to
each entry. These are routes to owner clauses, not a transition schema or checked
composite trace. Available per-step Dispatch outcomes remain generated in
[Dispatch traces](#dispatch-traces); no prose guard is computed here.

### Dispatch and re-entry

Applicability: typed LNVPS-path requests and maintained-cloud re-entry; named operator flows retain their own authorization.

Event/key: a session request names a machine, or an operator flow names its target;
the worker resolves the approved entry under [STA-24, *The resource*](../03-state-and-recovery.md#durable-state).
Preconditions route to [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock) and
[SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved),
[STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone) and
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
[STG-21a](../06-first-stage.md#the-paths-and-their-gates), and
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

Applicability: installed LNVPS-path jobs; the rescue persistence and non-LNVPS delivery-reboot exceptions apply only on their named routes.

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

Applicability: typed LNVPS-path resources; dedicated preparation only where explicitly named; untyped boundaries remain separate.

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

Event/key: irreversible session End, distinct from the processed Lock/pagehide/reload/shutdown
boundary in [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone); session, bindings,
pending approvals and channels route also to [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock) and
[SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved)
and [ARC-12](../01-architecture.md#sessions-binding-and-diversity) /
[ARC-31a](../01-architecture.md#money).
`STA-23` says “The actual end fence is irreversible and MUST NOT be reset to
implement continuation.” Begun appends and possibly sent effects:
[STA-3/8](../03-state-and-recovery.md#durable-state).
`STA-23` says “Already accepted remote work may continue even after local Lock or
loss.” Individual-session versus store-wide end:
[STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone). Procured-key expiry/cap/clock:
[ARC-31a](../01-architecture.md#money).

Lost replies, stale results, repeated lifecycle notifications, worker restart and
historical approvals: [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone) and the
[session/approval region](#sessions-and-approvals). Coverage: the [processed-authority composition](#processed-authority-composition)
checks the symbolic end fence; standalone Dispatch still assumes ended sessions send no requests
while replay alone permits eligible same-session resume under STA-23. `TauWeb.Dispatch.ended_session_approval_refused` exercises an
approval bound to an ended rendering session under that convention; it is no
proof of browser termination. The separate assurance owner is
[tw-237.4](../.beads/issues.jsonl).

### Processed suspension and validated continuation

Applicability: every surviving local worker/session; the backup ceremony has its separate hide behavior.

Event/key: a processed freeze/suspension or interruption, then continuation of the
same surviving worker/session. [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone)
owns the distinction from ordinary hide, the backup ceremony's exceptional hide,
and actual session end. `STA-23` says “A begun durable append MUST finish whole
rather than be cancelled partway.” Binding/writer ownership and continuation
fences: [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone). Its validation list
is quoted in [Authority](#authority). Remote uncertainty:
[STA-8/24](../03-state-and-recovery.md#durable-state). Pin admission:
[SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked). Procured-key
limits: [ARC-31a](../01-architecture.md#money).

`STA-23` says “if it cannot identify one it MUST show reconciliation or required
operator action and wait.” Failure/re-entry references: [STA-3/8](../03-state-and-recovery.md#durable-state) and
[STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone)
for failed append, lost reply and duplicate/stale messages. `STA-23` says “Phones
may freeze or discard the page without a final callback; no background execution
window, memory survival, socket continuity or timely cleanup is promised.” Coverage:
[processed-authority composition](#processed-authority-composition) checks particular symbolic
continuations. Actual notification, readiness and browser fences remain downstream evidence.

### Processed-authority composition

Evidence: general theorems and named finite witnesses in a checking interpretation, not browser
or implementation evidence. Authority remains per clause under
[ADR-0032](adr/0032-the-formal-companion-follows-provisiond-spec.md).
The interpretation, its assumptions and omitted facts have one description at
[STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone); binding and approved-record owners remain
[SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock) and
[SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved),
and conditional procured limits remain [ARC-31a](../01-architecture.md#money).

`TauWeb.Authority.ordinary_refinement` checks the explicit shared request interface: symbolic
eligibility and the unchanged Dispatch transition, with Dispatch's durable-before-apply premise.
The [authority witness file](design/authority-witnesses-v4.json) contains the finite Robot
reset/read-confirmation composition. Its successor passes authority validation while Dispatch
refuses behind the predecessor's unresolved reset. A failed confirmation append retains that
refusal; durable qualifying confirmation and current validation admit fresh successor work.
Changing only Dispatch's resource key to call id exposes the bad send. The same file retains
stale-publication, hide/progress, suspension, succession and conditional-key counterfactual pairs.
Additional named histories cover the reported incarnation-overlap trace, safe repeated resumes,
current/retired execution collisions, retained-binding admission/growth, fresh-identity End
fences, missing resume validation, latched loss across a second resume, and interrupted versus
durably completed ceremonies. Their full initial projections distinguish arbitrary-state
boundary probes from histories run from the initial world; see the witness schema.
This extends no claim to LNVPS receipts, browser termination or production inference admission.

The [witness schema](design/witness-file-v1.md#authority-schema-4) labels the hypotheses and
finite-history bound. Downstream acceptance remains in [CNF-7/69/82/102](../07-conformance.md):
there is no new comparison result, phone test or conformance completion here.

### Pin retirement and admission

Applicability: LNVPS-path reinstall/Restore; the reset-into-rescue and other pin-source routes remain route-specific.

Event/key: operator-chosen destructive reinstall dispatch; candidate pin
observation and its route provenance. Preconditions, evidence and authority route to
[STG-20](../06-first-stage.md#what-the-lnvps-path-does-not-test),
[CHN-R7 and the other routes](../02-channel.md#the-routes-to-a-fingerprint),
[SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked),
[ADR-0045](adr/0045-the-installation-label-moves-at-reinstall-dispatch.md) and
STA-3. `STG-20` says the reinstall “opens a new installation when it is
**dispatched**”. Installation identity, retirement, comparison-before-retention
and candidate completeness/freshness/containment:
[CHN-R7](../02-channel.md#the-routes-to-a-fingerprint). Reinstall confirmation:
[STG-21a](../06-first-stage.md#the-paths-and-their-gates). Contact versus command admission:
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

Applicability: LNVPS-path delivery/re-entry; non-LNVPS delivery reboot remains its separate route.

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
Duplicate/stale publication: [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone).
Re-entry service reads/restored labels: [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular)
and [STA-16](../03-state-and-recovery.md#recovery-by-access-model-and-vendor).

Findings, lifecycle labels, scan arming and permission-to-place references:
[ARC-17](../01-architecture.md#what-a-session-delivers),
[ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) and
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
| Typed mutation on the approved entry, including create/order | [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock), [SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved), [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state), [STA-20](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Adapter reconciliation read | [SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved), [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-20](../03-state-and-recovery.md#durable-state), [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Ordinary `exec`, including a read through `exec` | [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock), [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-20](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Harness-owned box-plane job, including a harness-composed read | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-20](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Job-record collection (not a new job) | [STA-20](../03-state-and-recovery.md#durable-state), [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-20](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Pin-checked connection (not permission to execute) | [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked), [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone) | [STA-24](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) | [STA-24](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) | [STA-20](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) | [STA-24](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) |
| Inference request | [ARC-31a](../01-architecture.md#money), [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone) | [STA-24](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state) | [ARC-31a](../01-architecture.md#money), [STA-20](../03-state-and-recovery.md#durable-state) | [STA-24](../03-state-and-recovery.md#durable-state), [ARC-31a](../01-architecture.md#money) |
| Actionable publication | [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) | [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [tw-pkn](../.beads/issues.jsonl) |

### Authority

Pause/resume and durable End are owned by [STA-23](../03-state-and-recovery.md#durable-state).
The separate [authority witness file](design/authority-witnesses-v4.json) distinguishes stale
incarnations, eligible same-session resume and permanent End, including withheld paid keys.
Import restores ended history under [STA-16](../03-state-and-recovery.md#recovery-by-access-model-and-vendor).
Abandon's named holder Ends and deterministic continuation belong to
[ARC-21](../01-architecture.md#post-harness-machinery-and-finishing-a-setup).

Evidence: conceptual navigation. Applicability: session requests; named harness
flows keep their own authorization.

Owners: [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock),
[SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved),
[STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone).

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
[STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone).

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
[STG-21a](../06-first-stage.md#the-paths-and-their-gates), dedicated
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
carried by Dispatch. Applicability: typed LNVPS-path installed machine in the first
three columns; the last column is deferred untyped-vendor material. Each cell
points to the owning clauses or existing decision record. Read their scope in
the checked quotations below; the table maintains no separate classifications.

| Action class | Pending post-restart delivery check | Required scan reference unarmed / protected release | Vendor identity unavailable, quarantined or excluded | Untyped vendor pause / destructive hold |
|---|---|---|---|---|
| Typed mutation | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [STA-24](../03-state-and-recovery.md#durable-state) | [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [§§1–5](design/protected-evidence-v1.md#1-decoder-boundary-and-facts) | [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Adapter reconciliation read | [STA-24](../03-state-and-recovery.md#durable-state) | [§§1–5](design/protected-evidence-v1.md#1-decoder-boundary-and-facts) | [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Ordinary `exec` | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) | [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting) | [STA-24](../03-state-and-recovery.md#durable-state) |
| Harness-owned job | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [§3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary) | [STA-24](../03-state-and-recovery.md#durable-state), [ADR-0054](adr/0054-the-untyped-scope-hold-refuses-every-new-job.md) |
| Job-record collection | [STA-20](../03-state-and-recovery.md#durable-state), [STA-24](../03-state-and-recovery.md#durable-state) | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting) | [STA-20](../03-state-and-recovery.md#durable-state), [STA-24](../03-state-and-recovery.md#durable-state) |
| Pin-checked connection | [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) | [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) | [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting), [CHN-R7](../02-channel.md#the-routes-to-a-fingerprint) | [STA-24](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) |
| Inference request | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [ARC-31a](../01-architecture.md#money) | [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [§3](design/protected-evidence-v1.md#3-protected-inference-terminals) | [ARC-31a](../01-architecture.md#money) | [STA-24](../03-state-and-recovery.md#durable-state), [ARC-31a](../01-architecture.md#money) |
| Actionable publication | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) | [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [§3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary) | [STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [tw-pkn](../.beads/issues.jsonl) |

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
  and, for the destructive untyped hold, “the harness worker MUST refuse every new
  box-plane job to a machine the hold covers, whoever starts it”. That hold is its own
  rule, not the typed every-requester stop
  ([ADR-0054](adr/0054-the-untyped-scope-hold-refuses-every-new-job.md)); its coverage,
  successor reach and same-origin inheritance are at `STA-24`. These untyped restrictions are prose-only and
  retain the later-route applicability in the admission list.
  For the open-call pause, `STA-24` says “while a call under that scope is open — sent, and not yet
  answered — or unresolved, the harness worker MUST NOT dispatch a box-plane command to any
  machine of the session's bound set at that vendor.”

For overlapping restrictions, follow these owner routes together:

- Command-terminal collection versus cloud uncertainty/disposition:
  [Command hold](#command-hold), [Cloud barrier](#cloud-barrier),
  [Destructive disposition](#destructive-disposition).
- LNVPS restart confirmation versus pending delivery check:
  [STG-21a](../06-first-stage.md#the-paths-and-their-gates) and
  [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular).
- Scan re-arm/local paste versus destructive continuation:
  [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) and
  [STA-24](../03-state-and-recovery.md#durable-state).
- Renewal-off versus running-system mutations:
  [STG-21](../06-first-stage.md#the-paths-and-their-gates) and
  [STA-24](../03-state-and-recovery.md#durable-state).
  `STA-24` says “Box-plane dispatch to the machine is governed by `STA-20` and
  `STA-20b`, not by this rule”. For the exception, see [Cloud barrier](#cloud-barrier).
- Failure/successor allocation:
  [tw-sfu/tw-hwl/tw-nj8](../.beads/issues.jsonl). Installation/recovery:
  [tw-l1l/tw-lq8/tw-yhd](../.beads/issues.jsonl). Restored-command boundary:
  [STA-20/STA-24](../03-state-and-recovery.md#durable-state).

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
is that ended sessions send no requests while replay alone permits eligible same-session resume under STA-23.

### Open owners and deliberate boundaries

Evidence: conceptual navigation. Applicability: open questions and settled boundaries, not
new permissions. The source records are the [committed tracker](../.beads/issues.jsonl);
inspect a named record with `br show ID --json --no-auto-flush --no-auto-import`.

- Journal-only recovery boundary:
  [STA-20/STA-24](../03-state-and-recovery.md#durable-state).
  `STA-24` says “Settlement of one retained call under its own contract supplies no
  completeness or completion evidence about omitted sends”.
- Untyped destructive hold versus harness-started jobs: settled at
  [STA-24](../03-state-and-recovery.md#durable-state)
  ([ADR-0054](adr/0054-the-untyped-scope-hold-refuses-every-new-job.md); [tw-pgp](../.beads/issues.jsonl)).
- **Not enabled:** the in-setup replacement order at LNVPS, until its row of the
  [admission table](../07-conformance.md#capability-applicability-and-admission) passes;
  until then LNVPS's third recovery rung takes the form `STG-17` gives it
  ([tw-ae7](../.beads/issues.jsonl)).
- **Not specified:** destruction/output ([tw-pkn](../.beads/issues.jsonl)). The recovery figures are
  conceptual navigation, with their existing policy and stand-ins retained.
- Rescue activation beside the delivery reboot: coverage, not new behavior
  ([tw-z99](../.beads/issues.jsonl)). The existing installed-pin halt owns it:
  [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) and
  [ARC-41](../01-architecture.md#machine-networking). `SEC-11` says “a key that does not
  match MUST halt the session”; `ARC-41` says “the harness does not reconnect on its own”.
  [CNF-53](../07-conformance.md)'s dedicated rescue-return case exercises it.
- Allocation questions stay with [tw-sfu, tw-hwl, tw-nj8](../.beads/issues.jsonl);
  installation/recovery questions with [tw-lq8, tw-l1l, tw-yhd](../.beads/issues.jsonl).
  This outline chooses no answers to them.
- [The witness gate](../tools/check_witnesses.py) checks corpus-wide marked pair
  structure under [ADR-0032](adr/0032-the-formal-companion-follows-provisiond-spec.md) and the
  [witness schema](design/witness-file-v1.md).
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
| Exact-call vendor receipt | [STA-24](../03-state-and-recovery.md#durable-state), [STG-21a](../06-first-stage.md#the-paths-and-their-gates) | [§3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) |
| Authenticated status/listing | [STG-21/21a](../06-first-stage.md#the-paths-and-their-gates) | [STG-21a](../06-first-stage.md#the-paths-and-their-gates), [STA-24](../03-state-and-recovery.md#durable-state) |
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
[STG-21a](../06-first-stage.md#the-paths-and-their-gates). Empty-group pin admission versus
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
LNVPS restart confirmation: [STG-21a](../06-first-stage.md#the-paths-and-their-gates).

For delivery, use [ARC-43's evidence clauses](../01-architecture.md#box-plane-execution-is-command-granular)
and [ARC-17's placing-session demonstration](../01-architecture.md#what-a-session-delivers):

| Observation or local condition | Evidence owners | Independent-boundary owners |
|---|---|---|
| Enablement read without demonstrated reboot | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) |
| New guest boot plus active unit after the approved reboot | [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | [STG-21a](../06-first-stage.md#the-paths-and-their-gates), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) |
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

Applicability: notify/attest routes; the LNVPS path uses no notify channel.
Owner: [CHN-17](../02-channel.md#the-attest-sequence).
`CHN-17` says “a machine may send the harness an event, and an event is an observation.”
`CHN-17` says “never gates a step, never triggers an action”. Attest introduction,
planted-sender identity and single-use browser acceptance:
[CHN-R5](../02-channel.md#the-routes-to-a-fingerprint) and
[CHN-5](../02-channel.md#the-attest-sequence). Candidate notification uses:
[CHN-17](../02-channel.md#the-attest-sequence). The relay companion's historical profile is not a proof of
current relay `/v2/`, notify delivery or these composition boundaries; the port
remains [TASKS.md open T30](../TASKS.md#open-t30-relay-port).

## Dispatch traces

The source is [Dispatch schema 10](design/dispatch-witnesses-v10.json), with its
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
[confirmation owner](../06-first-stage.md#the-paths-and-their-gates).

The command pair differs in `commandHold` (true versus false), with exec calls 7
then 12. Its admitted side is another withdrawn-guard counterexample.
`TauWeb.Dispatch.hold_reads_and_other_machines` is legitimate progress: exec 7,
replay, successor-session exec 12 refused, read request 13, inference 14, exec 17
on entry 2, durable job-record observation settling 7, then exec 20 on the original
machine. The read request does not itself collect a terminal record. The independent
inference and entry-2 calls remain visible. Other-machine events are LNVPS-path
fixtures under the admission list, not admission of multi-machine sessions.
This named trace exceeds the three-event bound; it is not exhaustively covered by
that enumeration. These are separate intact traces, not a checked composition.

### Additional Dispatch stories and dependencies

Evidence: conceptual navigation to separate generated witness projections below.
Applicability: typed routes only; a dedicated Robot reset or `delivery_reboot`
is not LNVPS typed-restart evidence. Every selected trace remains intact.

- **Confirmation observed, terminal append failed:** the resolution-append pair
  uses a Robot `adapter_read` reporting `succeeded` with `appended: false`, then
  an exec request and replay. The refused side retains call 1 unresolved; the
  admitted side is the withdrawn durability guard. Neither trace contains a later
  successful observation. Its dependency is further admissible, durably accepted
  operation evidence or operator disposition under
  [STA-3/8/24](../03-state-and-recovery.md#durable-state), not an automatic retry.
  The separate `delivery_reboot_failed_append_holds` history does include a later
  durable collection, but for a dedicated box-plane reboot, not that Robot reset.
- **Command versus harness work:** the command/reboot pair uses the harness's
  operator-labelled `delivery_reboot` request. The failed-append collection history
  then shows a different reboot history through replay, successor refusal, durable
  collection and later exec. Its final exec assumes the omitted pending delivery
  verdict, as [witness-file v1](design/witness-file-v1.md#events) specifies. A
  harness-composed read remains a command; a `job_record` observation is collection.
  [STA-20](../03-state-and-recovery.md#durable-state) says “a read through `exec` is a
  command, and a job the harness composes is held too.” The distinct reboot-approval
  facts and bounded-description remainder stay with [tw-itv](../.beads/issues.jsonl).
- **Destructive continuation versus harness work:** the destructive-reboot pair
  retains its standing reinstall and unknown disposed-command outcome. The separate
  destructive-command pair includes actual progress: reinstall dispatch, an exec
  still refused behind it, admissible reinstall confirmation, then exec. It supplies
  no evidence that a held harness flow resumes itself. The continuation procedure
  and stopped wait stay with [STA-20/24](../03-state-and-recovery.md#durable-state)
  and [ADR-0050](adr/0050-destructive-dispositions-stop-every-box-plane-job.md).
- **Received identity withholding and quarantine:** the excluded-order pair retains
  `identity_exclusions.records`; its admitted partner withdraws the identity guard.
  In `quarantine_has_no_target`, both emitted declarations remain visible, including
  `retained_quarantine_conflict`. The separate association views distinguish a
  withheld target from absence and an admitted map from quarantined evidence.
  `unavailable_receipt_never_settles` includes a later retained same-entry mapping;
  its earlier receipt's settled vector stays empty and the risk remains. The
  separately discriminated order/association success under `receipt_operation_limit`
  starts without unavailable evidence; it does not repair the refused history.
  Independently admissible evidence, operator action and already admitted mappings
  follow [protected evidence §3a](design/protected-evidence-v1.md#3a-protected-operation-evidence)
  and [STA-24](../03-state-and-recovery.md#durable-state). No selected view clears
  retained identity risk, reconstructs a withheld literal or checks listing selection.

### Restart receipt before delivery completion — illustrative prose-only

Evidence: illustrative prose-only narrative, with a separate generated receipt view.
Applicability: the typed LNVPS path; Dispatch has no pending-check state or service
lifecycle events. This narrative extends no source verdict or checked composition.

Read `lnvps_receipt_confirms` only through receipt settlement and replay. For a
separate delivery narrative, suppose the operator approved the survival reboot.
[STG-21a](../06-first-stage.md#the-paths-and-their-gates) says “It does not establish a completed
guest boot or service survival.” Operation confirmation therefore leads the reader
to [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) for the
subsequent guest boot and active-service observations, then the delivery verdict.
`ARC-43` says “until the delivery check's verdict is durably journaled” and “A stop
settles no verdict and is shown as a stopped check, never as a pass.” Pending check,
boot/service evidence, scan readiness and output publication are prose-only here;
there is no fabricated post-replay session request or guest observation in the
receipt table.

### Hide, suspension, Lock and late results — illustrative prose-only

Evidence: illustrative prose-only narrative; no lifecycle transition table is generated.
Applicability: surviving LNVPS-path worker and session, under
[STA-23](../03-state-and-recovery.md#what-survives-a-lost-phone),
[SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock)
and [SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved).
Standalone Dispatch assumes session termination and one writer. The
[processed-authority composition](#processed-authority-composition) records the checked symbolic
boundary and its limits. Real scheduling, callbacks and mobile cleanup are not proved.

Start with an unlocked eligible session and an ordinary visibility-only hide outside
seed backup. `STA-23` says “An ordinary visibility-only hide MUST NOT end or pause
an unlocked session, clear its runtime authority, or invalidate its approvals.”
Before a continuation after processed suspension, use the separate validation
boundary: `STA-23` says “Before further ordinary sends or actionable result publication
after a processed suspension or interruption, the surviving worker MUST validate its
current authority, bindings, holds, connection state and scan readiness.” This is
not a fence at an unobserved physical freeze. Binding and approval remain their
owners' checks; `SEC-4` says “What is dispatched is the approved record.”

Follow explicit Lock or pagehide along the pause, incarnation-fence and eligible resume path
at STA-23; only an actual End permanently destroys session authority.
Its seed-backup exception is local: `STA-23` says “During the seed-backup ceremony
an ordinary hide MUST take this full Lock path too”. It also says “A stale message
or late result MUST NOT revive ended authority or publish an actionable result under
stale authority.” A later callback supplies neither renewed approval nor an outcome
for a possibly sent remote command. This narrative adds no lifecycle engine, event,
or checked seam to the source traces.

<!-- atlas-info: dispatch-v10 -->
Evidence: generated witness projection; dispatch source header and complete bound context.
Applicability: Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: not recorded here. Permitted next actions: consult the owning rules; no source outcome supplies extra authority.
Bound: finite source context only, neither completeness nor implementation evidence. Named traces are not claims about the enumeration.

| Source header and bound context (complete) |
|---|
| `{"bound": {"alphabet": [{"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "connection": null, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}, {"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 2, "connection": null, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}, {"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}, {"appended": true, "kind": "read", "operation": "reset", "provenance": "adapter observation", "reports": "succeeded", "resource": {"machine_entry": 1}, "source": "adapter_read"}, {"appended": true, "calls": [1], "continuation": "destructive_reinstall", "kind": "dispose", "provenance": "disposition", "resource": {"machine_entry": 1}}, {"kind": "replay", "provenance": "replay"}, {"appended": true, "approved": {"facts": 5, "receipt_binding": null, "session": 1}, "call": 10, "connection": null, "facts": 5, "kind": "request", "operation": "activate", "provenance": "model request", "read_route": null, "session": 1, "target": {"entry": 1}}, {"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}], "declaration": "TauWeb.Dispatch.bound", "events": 3, "start": {"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}}, "module": "dispatch", "namespace": "TauWeb.Dispatch", "schema": 10, "source": "docs/design/dispatch-witnesses-v10.json"}` |

### same action new call id refused

Evidence: generated witness projection — same_action_new_call_id_refused.
Applicability: Typed resource barrier; reset requests, absent terminal evidence. Evidence/operator dependency: see the separate receipt view; no replay event here. View: same_action_new_call_id_refused. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace; bound alphabet membership and exhaustive coverage are not implied.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.same_action_new_call_id_refused", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.same_action_new_call_id_refused"], "pair": {"side": "refused", "with": "TauWeb.Dispatch.same_action_new_call_id_admitted"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — same_action_new_call_id_refused steps.
Applicability: Typed resource barrier; reset requests, absent terminal evidence. Evidence/operator dependency: see the separate receipt view; no replay event here. View: same_action_new_call_id_refused. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "connection": null, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 2, "connection": null, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"calls": [1], "reason": "barrier"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### same action new call id admitted

Evidence: generated witness projection — same_action_new_call_id_admitted.
Applicability: Withdrawn-guard trap; resourceKey = call. Never a production-success target. View: same_action_new_call_id_admitted. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace; bound alphabet membership and exhaustive coverage are not implied.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.same_action_new_call_id_admitted", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "call", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.same_action_new_call_id_admitted"], "pair": {"side": "admitted", "with": "TauWeb.Dispatch.same_action_new_call_id_refused"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — same_action_new_call_id_admitted steps.
Applicability: Withdrawn-guard trap; resourceKey = call. Never a production-success target. View: same_action_new_call_id_admitted. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "connection": null, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 2, "connection": null, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 2, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1, 2], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [2, 1], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### lnvps receipt confirms

Evidence: generated witness projection — lnvps_receipt_confirms.
Applicability: LNVPS-path typed restart receipt only; no guest/service/delivery verdict. Replay is last, with no post-replay request. View: lnvps_receipt_confirms. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace; bound alphabet membership and exhaustive coverage are not implied.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.lnvps_receipt_confirms", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.lnvps_receipt_confirms"]}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — lnvps_receipt_confirms steps.
Applicability: LNVPS-path typed restart receipt only; no guest/service/delivery verdict. Replay is last, with no post-replay request. View: lnvps_receipt_confirms. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "restart", "signed_request": 73}, "session": 1}, "call": 1, "connection": null, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "restart", "signed_request": 73}, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "kind": "receive", "provenance": "adapter observation", "receipt": {"binding": {"account": 41, "operation": "restart", "signed_request": 73}, "call": 1, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": false, "source": "browser_vendor_tls", "target": {"vendor_machine_id": 10}, "validated": true}}` | `{"settled": [1]}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "restart", "signed_request": 73}, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "restart", "signed_request": 73}, "call": 1, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": false, "source": "browser_vendor_tls", "target": {"vendor_machine_id": 10}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "restart", "signed_request": 73}, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "restart", "signed_request": 73}, "call": 1, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": false, "source": "browser_vendor_tls", "target": {"vendor_machine_id": 10}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### second command held

Evidence: generated witness projection — second_command_held.
Applicability: Installed command hold; source refusal reason is barrier. Separate collection/successor continuation follows. View: second_command_held. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace; bound alphabet membership and exhaustive coverage are not implied.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.second_command_held", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.second_command_held"], "pair": {"side": "refused", "with": "TauWeb.Dispatch.second_command_without_hold"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — second_command_held steps.
Applicability: Installed command hold; source refusal reason is barrier. Separate collection/successor continuation follows. View: second_command_held. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"calls": [7], "reason": "barrier"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### second command without hold

Evidence: generated witness projection — second_command_without_hold.
Applicability: Withdrawn-guard trap; commandHold = false. Never a production-success target. View: second_command_without_hold. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace; bound alphabet membership and exhaustive coverage are not implied.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.second_command_without_hold", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": false, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.second_command_without_hold"], "pair": {"side": "admitted", "with": "TauWeb.Dispatch.second_command_held"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — second_command_without_hold steps.
Applicability: Withdrawn-guard trap; commandHold = false. Never a production-success target. View: second_command_without_hold. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 12], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [12, 7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### hold reads and other machines

Evidence: generated witness projection — hold_reads_and_other_machines.
Applicability: Command replay, successor refusal, collection and new command. Other-machine and inference steps are fixtures, not admission evidence; no waiter/flow-resumption proof. View: hold_reads_and_other_machines. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.hold_reads_and_other_machines", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.hold_reads_and_other_machines"]}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — hold_reads_and_other_machines steps.
Applicability: Command replay, successor refusal, collection and new command. Other-machine and inference steps are fixtures, not admission evidence; no waiter/flow-resumption proof. View: hold_reads_and_other_machines. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 12, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 2, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"calls": [7], "reason": "barrier"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 4 | `{"appended": true, "approved": {"facts": 9, "receipt_binding": null, "session": 2}, "call": 13, "connection": null, "facts": 9, "kind": "request", "operation": "read", "provenance": "model request", "read_route": "machine", "session": 2, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 9, "receipt_binding": null, "session": 2}, "call": 13, "operation": "read", "resource": {"machine_entry": 1}, "session": 2, "state": "no_effect", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 13], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 5 | `{"appended": true, "approved": {"facts": 10, "receipt_binding": null, "session": 2}, "call": 14, "connection": null, "facts": 10, "kind": "request", "operation": "inference", "provenance": "model request", "read_route": null, "session": 2, "target": {"inference_cap": true}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 9, "receipt_binding": null, "session": 2}, "call": 13, "operation": "read", "resource": {"machine_entry": 1}, "session": 2, "state": "no_effect", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 10, "receipt_binding": null, "session": 2}, "call": 14, "operation": "inference", "resource": {"inference": true}, "session": 2, "state": "unresolved", "target": {"inference_cap": true}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 13, 14], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [14], "resource": {"inference": true}}, {"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 6 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 17, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 2, "target": {"entry": 2}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 9, "receipt_binding": null, "session": 2}, "call": 13, "operation": "read", "resource": {"machine_entry": 1}, "session": 2, "state": "no_effect", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 10, "receipt_binding": null, "session": 2}, "call": 14, "operation": "inference", "resource": {"inference": true}, "session": 2, "state": "unresolved", "target": {"inference_cap": true}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 17, "operation": "exec", "resource": {"machine_entry": 2}, "session": 2, "state": "unresolved", "target": {"entry": 2}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 2, "installation": 0}, {"entry": 1, "installation": 0}], "deleted_machines": [], "dispatched": [7, 13, 14, 17], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 2, "records": []}, {"entry": 1, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [17], "resource": {"machine_entry": 2}}, {"calls": [14], "resource": {"inference": true}}, {"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 7 | `{"appended": true, "kind": "read", "operation": "exec", "provenance": "adapter observation", "reports": "succeeded", "resource": {"machine_entry": 1}, "source": "job_record"}` | `{"settled": [7]}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 9, "receipt_binding": null, "session": 2}, "call": 13, "operation": "read", "resource": {"machine_entry": 1}, "session": 2, "state": "no_effect", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 10, "receipt_binding": null, "session": 2}, "call": 14, "operation": "inference", "resource": {"inference": true}, "session": 2, "state": "unresolved", "target": {"inference_cap": true}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 17, "operation": "exec", "resource": {"machine_entry": 2}, "session": 2, "state": "unresolved", "target": {"entry": 2}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 2, "installation": 0}, {"entry": 1, "installation": 0}], "deleted_machines": [], "dispatched": [7, 13, 14, 17], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 2, "records": []}, {"entry": 1, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [17], "resource": {"machine_entry": 2}}, {"calls": [14], "resource": {"inference": true}}, {"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 8 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 20, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 2, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 9, "receipt_binding": null, "session": 2}, "call": 13, "operation": "read", "resource": {"machine_entry": 1}, "session": 2, "state": "no_effect", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 10, "receipt_binding": null, "session": 2}, "call": 14, "operation": "inference", "resource": {"inference": true}, "session": 2, "state": "unresolved", "target": {"inference_cap": true}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 17, "operation": "exec", "resource": {"machine_entry": 2}, "session": 2, "state": "unresolved", "target": {"entry": 2}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 20, "operation": "exec", "resource": {"machine_entry": 1}, "session": 2, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 13, 14, 17, 20], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [20], "resource": {"machine_entry": 1}}, {"calls": [17], "resource": {"machine_entry": 2}}, {"calls": [14], "resource": {"inference": true}}], "waiting_connections": []}` |

### resolution append failed refused

Evidence: generated witness projection — resolution_append_failed_refused.
Applicability: Robot read-confirmed reset, not LNVPS restart. Failed observation append retains barrier; further qualifying durable evidence or operator action needed. View: resolution_append_failed_refused. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.resolution_append_failed_refused", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.resolution_append_failed_refused"], "pair": {"side": "refused", "with": "TauWeb.Dispatch.resolution_append_failed_admitted"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — resolution_append_failed_refused steps.
Applicability: Robot read-confirmed reset, not LNVPS restart. Failed observation append retains barrier; further qualifying durable evidence or operator action needed. View: resolution_append_failed_refused. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "connection": null, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": false, "kind": "read", "operation": "reset", "provenance": "adapter observation", "reports": "succeeded", "resource": {"machine_entry": 1}, "source": "adapter_read"}` | `{"settled": []}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"calls": [1], "reason": "barrier"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 4 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### resolution append failed admitted

Evidence: generated witness projection — resolution_append_failed_admitted.
Applicability: Withdrawn durableBeforeApply trap; in-memory settlement despite failed append. Never a production-success target. View: resolution_append_failed_admitted. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.resolution_append_failed_admitted", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": false, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.resolution_append_failed_admitted"], "pair": {"side": "admitted", "with": "TauWeb.Dispatch.resolution_append_failed_refused"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — resolution_append_failed_admitted steps.
Applicability: Withdrawn durableBeforeApply trap; in-memory settlement despite failed append. Never a production-success target. View: resolution_append_failed_admitted. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "connection": null, "facts": 1, "kind": "request", "operation": "reset", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": false, "kind": "read", "operation": "reset", "provenance": "adapter observation", "reports": "succeeded", "resource": {"machine_entry": 1}, "source": "adapter_read"}` | `{"settled": [1]}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": false, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1, 7], "dispositions": [], "durable": false, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 4 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": null, "session": 1}, "call": 1, "operation": "reset", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1, 7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7, 1], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### command holds delivery reboot

Evidence: generated witness projection — command_holds_delivery_reboot.
Applicability: Dedicated reboot held behind exec; not LNVPS-path typed-restart evidence. Collection progress is a separate history below. View: command_holds_delivery_reboot. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace; bound alphabet membership and exhaustive coverage are not implied.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.command_holds_delivery_reboot", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.command_holds_delivery_reboot"], "pair": {"side": "refused", "with": "TauWeb.Dispatch.delivery_reboot_without_hold"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — command_holds_delivery_reboot steps.
Applicability: Dedicated reboot held behind exec; not LNVPS-path typed-restart evidence. Collection progress is a separate history below. View: command_holds_delivery_reboot. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "connection": null, "facts": 11, "kind": "request", "operation": "delivery_reboot", "provenance": "operator act", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"calls": [7], "reason": "barrier"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### delivery reboot without hold

Evidence: generated witness projection — delivery_reboot_without_hold.
Applicability: Withdrawn commandHold trap for a dedicated harness reboot. Never a production-success target. View: delivery_reboot_without_hold. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace; bound alphabet membership and exhaustive coverage are not implied.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.delivery_reboot_without_hold", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": false, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.delivery_reboot_without_hold"], "pair": {"side": "admitted", "with": "TauWeb.Dispatch.command_holds_delivery_reboot"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — delivery_reboot_without_hold steps.
Applicability: Withdrawn commandHold trap for a dedicated harness reboot. Never a production-success target. View: delivery_reboot_without_hold. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "connection": null, "facts": 11, "kind": "request", "operation": "delivery_reboot", "provenance": "operator act", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "operation": "delivery_reboot", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 30], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [30, 7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### delivery reboot failed append holds

Evidence: generated witness projection — delivery_reboot_failed_append_holds.
Applicability: Dedicated boot-change result: failed append, replay/successor refusal, durable collection and later exec. That exec assumes the omitted delivery verdict; no pending-check proof. View: delivery_reboot_failed_append_holds. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.delivery_reboot_failed_append_holds", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.delivery_reboot_failed_append_holds"]}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — delivery_reboot_failed_append_holds steps.
Applicability: Dedicated boot-change result: failed append, replay/successor refusal, durable collection and later exec. That exec assumes the omitted delivery verdict; no pending-check proof. View: delivery_reboot_failed_append_holds. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "connection": null, "facts": 11, "kind": "request", "operation": "delivery_reboot", "provenance": "operator act", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "operation": "delivery_reboot", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [30], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [30], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": false, "call": 30, "kind": "collect_reboot", "observed_boot": 2, "provenance": "adapter observation", "record_boot": 1, "resource": {"machine_entry": 1}}` | `{"settled": []}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "operation": "delivery_reboot", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [30], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [30], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "operation": "delivery_reboot", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [30], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [30], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 4 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 2}, "call": 7, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 2, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"calls": [30], "reason": "barrier"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "operation": "delivery_reboot", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [30], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [30], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 5 | `{"appended": true, "call": 30, "kind": "collect_reboot", "observed_boot": 2, "provenance": "adapter observation", "record_boot": 1, "resource": {"machine_entry": 1}}` | `{"settled": [30]}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "operation": "delivery_reboot", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [30], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [{"call": 30, "observed_boot": 2, "record_boot": 1, "resource": {"machine_entry": 1}}], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 6 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "operation": "delivery_reboot", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [30], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [{"call": 30, "observed_boot": 2, "record_boot": 1, "resource": {"machine_entry": 1}}], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 7 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 3}, "call": 12, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 3, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "operation": "delivery_reboot", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 3}, "call": 12, "operation": "exec", "resource": {"machine_entry": 1}, "session": 3, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [30, 12], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [{"call": 30, "observed_boot": 2, "record_boot": 1, "resource": {"machine_entry": 1}}], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [12], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### delivery reboot exec approval refused

Evidence: generated witness projection — delivery_reboot_exec_approval_refused.
Applicability: Dedicated harness reboot refuses same-session ordinary exec approval facts at the request, with no intent or journal change. Unpaired: valid reboot approval is a different input under the same assumptions; the separate failed-append history carries admitted progress. Symbolic facts do not prove fresh consent or re-asking after a held first issue. View: delivery_reboot_exec_approval_refused. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace; bound alphabet membership and exhaustive coverage are not implied.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.delivery_reboot_exec_approval_refused", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.delivery_reboot_exec_approval_refused"]}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — delivery_reboot_exec_approval_refused steps.
Applicability: Dedicated harness reboot refuses same-session ordinary exec approval facts at the request, with no intent or journal change. Unpaired: valid reboot approval is a different input under the same assumptions; the separate failed-append history carries admitted progress. Symbolic facts do not prove fresh consent or re-asking after a held first issue. View: delivery_reboot_exec_approval_refused. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 30, "connection": null, "facts": 11, "kind": "request", "operation": "delivery_reboot", "provenance": "operator act", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"reason": "facts"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

### destructive choice stops delivery reboot

Evidence: generated witness projection — destructive_choice_stops_delivery_reboot.
Applicability: Dedicated harness reboot under standing destructive reinstall; outcome unknown. Reinstall/evidence progress is a separate command history below. View: destructive_choice_stops_delivery_reboot. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace; bound alphabet membership and exhaustive coverage are not implied.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.destructive_choice_stops_delivery_reboot", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.destructive_choice_stops_delivery_reboot"], "pair": {"side": "refused", "with": "TauWeb.Dispatch.delivery_reboot_dispatched_without_destructive_stop"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — destructive_choice_stops_delivery_reboot steps.
Applicability: Dedicated harness reboot under standing destructive reinstall; outcome unknown. Reinstall/evidence progress is a separate command history below. View: destructive_choice_stops_delivery_reboot. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "calls": [7], "continuation": "destructive_reinstall", "kind": "dispose", "provenance": "disposition", "resource": {"machine_entry": 1}}` | `{"disposition": "recorded"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}}], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"appended": true, "approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "connection": null, "facts": 11, "kind": "request", "operation": "delivery_reboot", "provenance": "operator act", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"in_force": "destructive_reinstall", "reason": "continuation"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}}], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### delivery reboot dispatched without destructive stop

Evidence: generated witness projection — delivery_reboot_dispatched_without_destructive_stop.
Applicability: Withdrawn destructiveStops trap; requester cannot make this production success. View: delivery_reboot_dispatched_without_destructive_stop. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace; bound alphabet membership and exhaustive coverage are not implied.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.delivery_reboot_dispatched_without_destructive_stop", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": false, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.delivery_reboot_dispatched_without_destructive_stop"], "pair": {"side": "admitted", "with": "TauWeb.Dispatch.destructive_choice_stops_delivery_reboot"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — delivery_reboot_dispatched_without_destructive_stop steps.
Applicability: Withdrawn destructiveStops trap; requester cannot make this production success. View: delivery_reboot_dispatched_without_destructive_stop. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "calls": [7], "continuation": "destructive_reinstall", "kind": "dispose", "provenance": "disposition", "resource": {"machine_entry": 1}}` | `{"disposition": "recorded"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}}], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"appended": true, "approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "connection": null, "facts": 11, "kind": "request", "operation": "delivery_reboot", "provenance": "operator act", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 11, "receipt_binding": null, "session": 1}, "call": 30, "operation": "delivery_reboot", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 30], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}}], "unresolved": [{"calls": [30], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### destructive choice stops commands

Evidence: generated witness projection — destructive_choice_stops_commands.
Applicability: Separate destructive-command history: reinstall dispatch then confirmation then exec; no waiter or automatic harness-flow resumption evidence. View: destructive_choice_stops_commands. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.destructive_choice_stops_commands", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.destructive_choice_stops_commands"], "pair": {"side": "refused", "with": "TauWeb.Dispatch.command_preempts_reinstall_without_guard"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — destructive_choice_stops_commands steps.
Applicability: Separate destructive-command history: reinstall dispatch then confirmation then exec; no waiter or automatic harness-flow resumption evidence. View: destructive_choice_stops_commands. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "calls": [7], "continuation": "destructive_reinstall", "kind": "dispose", "provenance": "disposition", "resource": {"machine_entry": 1}}` | `{"disposition": "recorded"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}}], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"in_force": "destructive_reinstall", "reason": "continuation"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}}], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 4 | `{"appended": true, "approved": {"facts": 8, "receipt_binding": null, "session": 2}, "call": 3, "connection": null, "facts": 8, "kind": "request", "operation": "reinstall", "provenance": "model request", "read_route": null, "session": 2, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 8, "receipt_binding": null, "session": 2}, "call": 3, "operation": "reinstall", "resource": {"machine_entry": 1}, "session": 2, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 1}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 3], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [3], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 5 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 17, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"calls": [3], "reason": "barrier"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 8, "receipt_binding": null, "session": 2}, "call": 3, "operation": "reinstall", "resource": {"machine_entry": 1}, "session": 2, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 1}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 3], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [3], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 6 | `{"appended": true, "kind": "read", "operation": "reinstall", "provenance": "adapter observation", "reports": "succeeded", "resource": {"machine_entry": 1}, "source": "adapter_read"}` | `{"settled": [3]}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 8, "receipt_binding": null, "session": 2}, "call": 3, "operation": "reinstall", "resource": {"machine_entry": 1}, "session": 2, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 1}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 3], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 7 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 20, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 8, "receipt_binding": null, "session": 2}, "call": 3, "operation": "reinstall", "resource": {"machine_entry": 1}, "session": 2, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 20, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 1}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 3, 20], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [20], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### command preempts reinstall without guard

Evidence: generated witness projection — command_preempts_reinstall_without_guard.
Applicability: Withdrawn destructiveStops partner; retain uncertainty and standing continuation. Never a production-success target. View: command_preempts_reinstall_without_guard. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.command_preempts_reinstall_without_guard", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": false, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.command_preempts_reinstall_without_guard"], "pair": {"side": "admitted", "with": "TauWeb.Dispatch.destructive_choice_stops_commands"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — command_preempts_reinstall_without_guard steps.
Applicability: Withdrawn destructiveStops partner; retain uncertainty and standing continuation. Never a production-success target. View: command_preempts_reinstall_without_guard. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [7], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "calls": [7], "continuation": "destructive_reinstall", "kind": "dispose", "provenance": "disposition", "resource": {"machine_entry": 1}}` | `{"disposition": "recorded"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}}], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 12], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}}], "unresolved": [{"calls": [12], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 4 | `{"appended": true, "approved": {"facts": 8, "receipt_binding": null, "session": 2}, "call": 3, "connection": null, "facts": 8, "kind": "request", "operation": "reinstall", "provenance": "model request", "read_route": null, "session": 2, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"calls": [12], "reason": "barrier"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 12], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}}], "unresolved": [{"calls": [12], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 5 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 17, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"calls": [12], "reason": "barrier"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 12], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}}], "unresolved": [{"calls": [12], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 6 | `{"appended": true, "kind": "read", "operation": "reinstall", "provenance": "adapter observation", "reports": "succeeded", "resource": {"machine_entry": 1}, "source": "adapter_read"}` | `{"settled": []}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 12], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}}], "unresolved": [{"calls": [12], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 7 | `{"appended": true, "approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 20, "connection": null, "facts": 3, "kind": "request", "operation": "exec", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "refused", "refusal": {"calls": [12], "reason": "barrier"}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 7, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}, {"approved": {"facts": 3, "receipt_binding": null, "session": 1}, "call": 12, "operation": "exec", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [7, 12], "dispositions": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}, "valid": true}], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [{"calls": [7], "continuation": "destructive_reinstall", "resource": {"machine_entry": 1}}], "unresolved": [{"calls": [12], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### excluded order refused

Evidence: generated witness projection — excluded_order_refused.
Applicability: Received-present withheld identity; identity_exclusion.records retained through replay. Identity exclusion is an exception to resource independence; a new entry supplies no reorder authority. View: excluded_order_refused. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.excluded_order_refused", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.excluded_order_refused"], "pair": {"side": "refused", "with": "TauWeb.Dispatch.excluded_order_sent_without_guard"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — excluded_order_refused steps.
Applicability: Received-present withheld identity; identity_exclusion.records retained through replay. Identity exclusion is an exception to resource independence; a new entry supplies no reorder authority. View: excluded_order_refused. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "connection": null, "facts": 1, "kind": "request", "operation": "create", "provenance": "model request", "read_route": null, "session": 1, "target": {"entry": 1}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "kind": "receive", "provenance": "adapter observation", "receipt": {"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}}` | `{"settled": []}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [10]}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [10]}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 4 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 2}, "call": 902, "connection": null, "facts": 1, "kind": "request", "operation": "create", "provenance": "model request", "read_route": null, "session": 2, "target": {"entry": 2}}` | `{"dispatch": "refused", "refusal": {"reason": "identity_exclusion", "records": [10]}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [10]}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### excluded order sent without guard

Evidence: generated witness projection — excluded_order_sent_without_guard.
Applicability: Withdrawn identityExclusion trap. Never a production-success target. View: excluded_order_sent_without_guard. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.excluded_order_sent_without_guard", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": false, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.excluded_order_sent_without_guard"], "pair": {"side": "admitted", "with": "TauWeb.Dispatch.excluded_order_refused"}}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — excluded_order_sent_without_guard steps.
Applicability: Withdrawn identityExclusion trap. Never a production-success target. View: excluded_order_sent_without_guard. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "connection": null, "facts": 1, "kind": "request", "operation": "create", "provenance": "model request", "read_route": null, "session": 1, "target": {"entry": 1}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "kind": "receive", "provenance": "adapter observation", "receipt": {"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}}` | `{"settled": []}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [10]}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [10]}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 4 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 2}, "call": 902, "connection": null, "facts": 1, "kind": "request", "operation": "create", "provenance": "model request", "read_route": null, "session": 2, "target": {"entry": 2}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}, {"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 2}, "call": 902, "operation": "create", "resource": {"machine_entry": 2}, "session": 2, "state": "unresolved", "target": {"entry": 2}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 2, "installation": 0}, {"entry": 1, "installation": 0}], "deleted_machines": [], "dispatched": [901, 902], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 2, "records": [10]}, {"entry": 1, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [902], "resource": {"machine_entry": 2}}, {"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### quarantine has no target

Evidence: generated witness projection — quarantine_has_no_target.
Applicability: Both source declarations retained: quarantine grants no target; retained quarantine conflicts remain. Progress needs independently admissible evidence/operator action; no risk-clearing event exists. View: quarantine_has_no_target. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.quarantine_has_no_target", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.quarantine_has_no_target", "TauWeb.Dispatch.retained_quarantine_conflict"]}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — quarantine_has_no_target steps.
Applicability: Both source declarations retained: quarantine grants no target; retained quarantine conflicts remain. Progress needs independently admissible evidence/operator action; no risk-clearing event exists. View: quarantine_has_no_target. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "connection": null, "facts": 1, "kind": "request", "operation": "create", "provenance": "model request", "read_route": null, "session": 1, "target": {"entry": 1}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "kind": "receive", "provenance": "adapter observation", "receipt": {"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}}` | `{"settled": []}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [10]}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"appended": true, "entry": 2, "kind": "associate_evidence", "provenance": "adapter observation", "vendor": 707, "withheld": false}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 2, "installation": 0}, {"entry": 1, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 2, "records": [10]}, {"entry": 1, "records": []}], "prerequisite_records": [], "quarantined": [{"entry": 2, "vendor": 707}], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 4 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 2, "installation": 0}, {"entry": 1, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 2, "records": [10]}, {"entry": 1, "records": []}], "prerequisite_records": [], "quarantined": [{"entry": 2, "vendor": 707}], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 5 | `{"appended": true, "entry": 1, "kind": "associate_evidence", "provenance": "adapter observation", "vendor": 707, "withheld": false}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 2, "installation": 0}, {"entry": 1, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 2, "records": [10]}, {"entry": 1, "records": []}], "prerequisite_records": [], "quarantined": [{"entry": 2, "vendor": 707}], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 6 | `{"appended": true, "entry": 1, "kind": "associate_evidence", "provenance": "adapter observation", "vendor": 708, "withheld": false}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}, {"entry": 1, "target": {"vendor_machine_id": 708}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [10]}], "prerequisite_records": [], "quarantined": [{"entry": 2, "vendor": 707}], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 7 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}, {"entry": 1, "target": {"vendor_machine_id": 708}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [10]}], "prerequisite_records": [], "quarantined": [{"entry": 2, "vendor": 707}], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### withheld association excludes

Evidence: generated witness projection — withheld_association_excludes.
Applicability: Withheld association and replay retain cross-entry exclusion. Reads, dispositions and already admitted maps have separate authority; no invented clearing. View: withheld_association_excludes. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace; bound alphabet membership and exhaustive coverage are not implied.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.withheld_association_excludes", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.withheld_association_excludes"]}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — withheld_association_excludes steps.
Applicability: Withheld association and replay retain cross-entry exclusion. Reads, dispositions and already admitted maps have separate authority; no invented clearing. View: withheld_association_excludes. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "entry": 1, "kind": "associate_evidence", "provenance": "adapter observation", "vendor": 709, "withheld": true}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [9]}], "prerequisite_records": [], "quarantined": [{"entry": 1, "vendor": null}], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |
| 2 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [9]}], "prerequisite_records": [], "quarantined": [{"entry": 1, "vendor": null}], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |
| 3 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 2}, "call": 902, "connection": null, "facts": 1, "kind": "request", "operation": "create", "provenance": "model request", "read_route": null, "session": 2, "target": {"entry": 2}}` | `{"dispatch": "refused", "refusal": {"reason": "identity_exclusion", "records": [9]}}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [9]}], "prerequisite_records": [], "quarantined": [{"entry": 1, "vendor": null}], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

### unavailable receipt never settles

Evidence: generated witness projection — unavailable_receipt_never_settles.
Applicability: Later independently admissible same-entry mapping supplies a target, never reconstructed receipt equality or risk discharge. Earlier receipt remains unsettled. View: unavailable_receipt_never_settles. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Dispatch.unavailable_receipt_never_settles", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.unavailable_receipt_never_settles"]}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — unavailable_receipt_never_settles steps.
Applicability: Later independently admissible same-entry mapping supplies a target, never reconstructed receipt equality or risk discharge. Earlier receipt remains unsettled. View: unavailable_receipt_never_settles. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "connection": null, "facts": 1, "kind": "request", "operation": "create", "provenance": "model request", "read_route": null, "session": 1, "target": {"entry": 1}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"appended": true, "kind": "receive", "provenance": "adapter observation", "receipt": {"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}}` | `{"settled": []}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [10]}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"appended": true, "entry": 1, "kind": "associate_evidence", "provenance": "adapter observation", "vendor": 710, "withheld": false}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}, {"entry": 1, "target": {"vendor_machine_id": 710}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [10]}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 4 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}, {"entry": 1, "target": {"vendor_machine_id": 710}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 901}, "session": 1}, "call": 901, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"entry": 1}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [901], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": [10]}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 901}, "call": 901, "resource": {"machine_entry": 1}, "returned_vendor": null, "returned_withheld": true, "source": "browser_vendor_tls", "target": {"entry": 1}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [901], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |

### receipt operation limit

Evidence: generated witness projection — receipt_operation_limit.
Applicability: Separate retained-ID order/association/receipt success; no unavailable identity in this history and no repair of quarantine. Explicit source-event discriminator below. View: receipt_operation_limit. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": [{"kind": "request", "operation": "create"}, {"entry": 1, "kind": "associate", "target": {"vendor_machine_id": 307}}], "declaration": "TauWeb.Dispatch.receipt_operation_limit", "order": "curated across traces; source order within each trace", "source": "docs/design/dispatch-witnesses-v10.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"approvalResetRequiresRescue": true, "approvedReinstallBoundary": true, "commandHold": true, "deletionContact": true, "destructiveStops": true, "dispositionBindsContinuation": true, "dispositionOwnResource": true, "durableBeforeApply": true, "endedBelowSucceeded": true, "failedPrerequisiteWithdraws": true, "identityExclusion": true, "lapse": "continuation", "newestActivationRead": true, "orderAssociation": true, "pendingCleared": true, "reach": "disposed", "rebootBootChange": true, "reinstallWithdrawalEffective": true, "resetIntoRescueOnly": true, "resetOfferCurrentInstallation": true, "resetOfferFreshKeys": true, "resourceKey": "entry", "sessionDestroyRefused": true}, "declarations": ["TauWeb.Dispatch.receipt_operation_limit"]}` |
| Starting projection (complete) | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [], "waiting_connections": []}` |

Evidence: generated witness projection — receipt_operation_limit steps.
Applicability: Separate retained-ID order/association/receipt success; no unavailable identity in this history and no repair of quarantine. Explicit source-event discriminator below. View: receipt_operation_limit. Source steps. Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"appended": true, "approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 73}, "session": 1}, "call": 1, "connection": null, "facts": 1, "kind": "request", "operation": "create", "provenance": "model request", "read_route": null, "session": 1, "target": {"vendor_machine_id": 10}}` | `{"dispatch": "dispatched"}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 73}, "session": 1}, "call": 1, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 2 | `{"entry": 1, "kind": "associate", "provenance": "operator act", "target": {"vendor_machine_id": 307}}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}, {"entry": 1, "target": {"vendor_machine_id": 307}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 73}, "session": 1}, "call": 1, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "unresolved", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [1], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 3 | `{"appended": true, "kind": "receive", "provenance": "adapter observation", "receipt": {"binding": {"account": 41, "operation": "order", "signed_request": 73}, "call": 1, "resource": {"machine_entry": 1}, "returned_vendor": 307, "returned_withheld": false, "source": "browser_vendor_tls", "target": {"vendor_machine_id": 10}, "validated": true}}` | `{"settled": [1]}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}, {"entry": 1, "target": {"vendor_machine_id": 307}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 73}, "session": 1}, "call": 1, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 73}, "call": 1, "resource": {"machine_entry": 1}, "returned_vendor": 307, "returned_withheld": false, "source": "browser_vendor_tls", "target": {"vendor_machine_id": 10}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
| 4 | `{"kind": "replay", "provenance": "replay"}` | `{}` | `{"associations": [{"entry": 2, "target": {"allocation_index": 2}}, {"entry": 1, "target": {"allocation_index": 0}}, {"entry": 1, "target": {"allocation_index": 1}}, {"entry": 1, "target": {"vendor_machine_id": 10}}, {"entry": 1, "target": {"vendor_machine_id": 307}}], "calls": [{"approved": {"facts": 1, "receipt_binding": {"account": 41, "operation": "order", "signed_request": 73}, "session": 1}, "call": 1, "operation": "create", "resource": {"machine_entry": 1}, "session": 1, "state": "terminal", "target": {"vendor_machine_id": 10}}], "contact_mappings": [{"target": {"entry": 2}, "vendor": 20}, {"target": {"allocation_index": 2}, "vendor": 20}, {"target": {"entry": 1}, "vendor": 10}, {"target": {"allocation_index": 1}, "vendor": 10}, {"target": {"allocation_index": 0}, "vendor": 10}], "current_installations": [{"entry": 1, "installation": 0}, {"entry": 2, "installation": 0}], "deleted_machines": [], "dispatched": [1], "dispositions": [], "durable": true, "identity_exclusions": [{"entry": 1, "records": []}, {"entry": 2, "records": []}], "prerequisite_records": [], "quarantined": [], "reboot_results": [], "receipts": [{"binding": {"account": 41, "operation": "order", "signed_request": 73}, "call": 1, "resource": {"machine_entry": 1}, "returned_vendor": 307, "returned_withheld": false, "source": "browser_vendor_tls", "target": {"vendor_machine_id": 10}, "validated": true}], "reinstall_approvals": [], "reinstall_withdrawals": [], "reset_offer": [], "session_ends": [], "standing": [], "unresolved": [{"calls": [], "resource": {"machine_entry": 1}}], "waiting_connections": []}` |
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

## Allocation traces

Evidence: conceptual navigation to generated allocation projections.
Applicability: maintained-cloud Restore/Replace allocation; the source is
[Allocation schema 3](design/allocation-witnesses-v3.json), with
[Allocation.lean](../tools/formal/TauWeb/Allocation.lean)'s assumptions and omissions.
These are allocation identities and journal counters, not full recovery-store replay.

The stale-sheet pair preserves the imported listed identity and refuses or, under
the withdrawn guard, repeats a formerly allocated identity. The intact
`replace_allocates_again` continuation includes that same refusal, Replace, the fresh
seed's durable ceremony and allocation under the new seed. It abstracts neither
removing old machine keys nor handling commands missing from a backup.
[STA-22b](../03-state-and-recovery.md#what-survives-a-lost-phone) says “every imported
seed may restore listed identities but MUST NOT allocate new ones” and “MUST be
refused until that seed id has the journaled ceremony record of `STA-23`.”
Imported-identity knowledge, allocation authority and generated-seed ceremony are
separate. Migration stays with [STA-17](../03-state-and-recovery.md#recovery-by-access-model-and-vendor);
pre-loss command handling remains outside this selection and with its existing
[owner record](../.beads/issues.jsonl) (`tw-ub7`).

<!-- atlas-info: allocation-v3 -->
Evidence: generated witness projection; allocation source header and complete bound context.
Applicability: Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed.
External possibilities: not recorded here. Permitted next actions: consult the owning rules; no source outcome supplies extra authority.
Bound: finite source context only, neither completeness nor implementation evidence. Named traces are not claims about the enumeration.

| Source header and bound context (complete) |
|---|
| `{"bound": {"alphabet": [{"family": "machines", "kind": "allocate", "provenance": "model request"}, {"identity": {"derivation_version": 1, "family": "machines", "index": 0, "seed": 0}, "kind": "created", "provenance": "adapter observation"}, {"append": {"durable": true, "provenance": "storage outcome of an append"}, "checked_sequence": 1, "identity": {"derivation_version": 1, "family": "machines", "index": 0, "seed": 0}, "kind": "failed", "provenance": "local writer decision"}, {"identity": {"derivation_version": 1, "family": "machines", "index": 0, "seed": 0}, "kind": "destroyed", "provenance": "adapter observation"}, {"kind": "export_sheet", "provenance": "operator act"}, {"kind": "restore", "provenance": "import or restore"}, {"kind": "replace", "provenance": "operator act"}, {"append": {"durable": true, "provenance": "storage outcome of an append"}, "completion": "full_reentry", "kind": "seed_backup", "provenance": "operator act"}], "declaration": "TauWeb.Allocation.bound", "events": 4}, "module": "allocation", "namespace": "TauWeb.Allocation", "schema": 3, "source": "docs/design/allocation-witnesses-v3.json"}` |

### stale sheet refused

Evidence: generated witness projection — stale_sheet_refused.
Applicability: Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed. View: stale_sheet_refused. Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Allocation.stale_sheet_refused", "order": "curated across traces; source order within each trace", "source": "docs/design/allocation-witnesses-v3.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"backupRecorded": true, "failureDurable": true, "restoredAllocatesNone": true, "senderFence": true, "unsentFailure": true}, "declarations": ["TauWeb.Allocation.stale_sheet_refused"], "pair": {"side": "refused", "with": "TauWeb.Allocation.stale_sheet_admitted"}}` |
| Starting projection (complete) | `{"create_intents": [], "derivation_version": 1, "entries": [], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 0, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "none", "sequence": 0}` |

Evidence: generated witness projection — stale_sheet_refused steps.
Applicability: Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed. View: stale_sheet_refused. Source steps. Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source journal after step (complete) |
|---|---|---|---|
| 1 | `{"append": {"durable": true, "provenance": "storage outcome of an append"}, "completion": "full_reentry", "kind": "seed_backup", "provenance": "operator act"}` | `{"recorded": true}` | `{"create_intents": [], "derivation_version": 1, "entries": [], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 0, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 0}` |
| 2 | `{"family": "machines", "kind": "allocate", "provenance": "model request"}` | `{"allocation": "admitted", "identity": {"derivation_version": 1, "family": "machines", "index": 0, "seed": 0}}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "reserved"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |
| 3 | `{"identity": {"derivation_version": 1, "family": "machines", "index": 0, "seed": 0}, "kind": "created", "provenance": "adapter observation"}` | `{}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |
| 4 | `{"kind": "export_sheet", "provenance": "operator act"}` | `{}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |
| 5 | `{"family": "machines", "kind": "allocate", "provenance": "model request"}` | `{"allocation": "admitted", "identity": {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0}}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}, {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0, "status": "reserved"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 2, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 2}` |
| 6 | `{"identity": {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0}, "kind": "created", "provenance": "adapter observation"}` | `{}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}, {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 2, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 2}` |
| 7 | `{"kind": "restore", "provenance": "import or restore"}` | `{}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": true, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |
| 8 | `{"family": "machines", "kind": "allocate", "provenance": "model request"}` | `{"allocation": "refused"}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": true, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |

### stale sheet admitted

Evidence: generated witness projection — stale_sheet_admitted.
Applicability: Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed. Withdrawn-guard historical trap, never a production-success target. View: stale_sheet_admitted. Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Allocation.stale_sheet_admitted", "order": "curated across traces; source order within each trace", "source": "docs/design/allocation-witnesses-v3.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"backupRecorded": true, "failureDurable": true, "restoredAllocatesNone": false, "senderFence": true, "unsentFailure": true}, "declarations": ["TauWeb.Allocation.stale_sheet_admitted"], "pair": {"side": "admitted", "with": "TauWeb.Allocation.stale_sheet_refused"}}` |
| Starting projection (complete) | `{"create_intents": [], "derivation_version": 1, "entries": [], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 0, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "none", "sequence": 0}` |

Evidence: generated witness projection — stale_sheet_admitted steps.
Applicability: Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed. Withdrawn-guard historical trap, never a production-success target. View: stale_sheet_admitted. Source steps. Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source journal after step (complete) |
|---|---|---|---|
| 1 | `{"append": {"durable": true, "provenance": "storage outcome of an append"}, "completion": "full_reentry", "kind": "seed_backup", "provenance": "operator act"}` | `{"recorded": true}` | `{"create_intents": [], "derivation_version": 1, "entries": [], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 0, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 0}` |
| 2 | `{"family": "machines", "kind": "allocate", "provenance": "model request"}` | `{"allocation": "admitted", "identity": {"derivation_version": 1, "family": "machines", "index": 0, "seed": 0}}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "reserved"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |
| 3 | `{"identity": {"derivation_version": 1, "family": "machines", "index": 0, "seed": 0}, "kind": "created", "provenance": "adapter observation"}` | `{}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |
| 4 | `{"kind": "export_sheet", "provenance": "operator act"}` | `{}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |
| 5 | `{"family": "machines", "kind": "allocate", "provenance": "model request"}` | `{"allocation": "admitted", "identity": {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0}}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}, {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0, "status": "reserved"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 2, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 2}` |
| 6 | `{"identity": {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0}, "kind": "created", "provenance": "adapter observation"}` | `{}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}, {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 2, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 2}` |
| 7 | `{"kind": "restore", "provenance": "import or restore"}` | `{}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": true, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |
| 8 | `{"family": "machines", "kind": "allocate", "provenance": "model request"}` | `{"allocation": "admitted", "identity": {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0}}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}, {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0, "status": "reserved"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 2, "passes": 0}, "restored_from_import": true, "seed": 0, "seed_backup": "full_reentry", "sequence": 2}` |

### replace allocates again

Evidence: generated witness projection — replace_allocates_again.
Applicability: Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed. View: replace_allocates_again. Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Allocation.replace_allocates_again", "order": "curated across traces; source order within each trace", "source": "docs/design/allocation-witnesses-v3.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"backupRecorded": true, "failureDurable": true, "restoredAllocatesNone": true, "senderFence": true, "unsentFailure": true}, "declarations": ["TauWeb.Allocation.replace_allocates_again"]}` |
| Starting projection (complete) | `{"create_intents": [], "derivation_version": 1, "entries": [], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 0, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "none", "sequence": 0}` |

Evidence: generated witness projection — replace_allocates_again steps.
Applicability: Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed. View: replace_allocates_again. Source steps. Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source journal after step (complete) |
|---|---|---|---|
| 1 | `{"append": {"durable": true, "provenance": "storage outcome of an append"}, "completion": "full_reentry", "kind": "seed_backup", "provenance": "operator act"}` | `{"recorded": true}` | `{"create_intents": [], "derivation_version": 1, "entries": [], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 0, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 0}` |
| 2 | `{"family": "machines", "kind": "allocate", "provenance": "model request"}` | `{"allocation": "admitted", "identity": {"derivation_version": 1, "family": "machines", "index": 0, "seed": 0}}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "reserved"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |
| 3 | `{"identity": {"derivation_version": 1, "family": "machines", "index": 0, "seed": 0}, "kind": "created", "provenance": "adapter observation"}` | `{}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |
| 4 | `{"kind": "export_sheet", "provenance": "operator act"}` | `{}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |
| 5 | `{"family": "machines", "kind": "allocate", "provenance": "model request"}` | `{"allocation": "admitted", "identity": {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0}}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}, {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0, "status": "reserved"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 2, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 2}` |
| 6 | `{"identity": {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0}, "kind": "created", "provenance": "adapter observation"}` | `{}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}, {"derivation_version": 1, "family": "machines", "index": 1, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 2, "passes": 0}, "restored_from_import": false, "seed": 0, "seed_backup": "full_reentry", "sequence": 2}` |
| 7 | `{"kind": "restore", "provenance": "import or restore"}` | `{}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": true, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |
| 8 | `{"family": "machines", "kind": "allocate", "provenance": "model request"}` | `{"allocation": "refused"}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": true, "seed": 0, "seed_backup": "full_reentry", "sequence": 1}` |
| 9 | `{"kind": "replace", "provenance": "operator act"}` | `{}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 0, "passes": 0}, "restored_from_import": false, "seed": 1, "seed_backup": "none", "sequence": 1}` |
| 10 | `{"append": {"durable": true, "provenance": "storage outcome of an append"}, "completion": "full_reentry", "kind": "seed_backup", "provenance": "operator act"}` | `{"recorded": true}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 0, "passes": 0}, "restored_from_import": false, "seed": 1, "seed_backup": "full_reentry", "sequence": 1}` |
| 11 | `{"family": "machines", "kind": "allocate", "provenance": "model request"}` | `{"allocation": "admitted", "identity": {"derivation_version": 1, "family": "machines", "index": 0, "seed": 1}}` | `{"create_intents": [], "derivation_version": 1, "entries": [{"derivation_version": 1, "family": "machines", "index": 0, "seed": 0, "status": "created"}, {"derivation_version": 1, "family": "machines", "index": 0, "seed": 1, "status": "reserved"}], "failures": [], "mappings": [], "next_unused": {"handoffs": 0, "machines": 1, "passes": 0}, "restored_from_import": false, "seed": 1, "seed_backup": "full_reentry", "sequence": 2}` |
<!-- /atlas-info -->

## Pins traces

Evidence: conceptual navigation to generated pin projections.
Applicability: LNVPS-path published installed keys and retained publication history;
the source is [Pins schema 5](design/pins-witnesses-v5.json), with
[Pins.lean](../tools/formal/TauWeb/Pins.lean)'s assumptions and omissions.
A reinstall event is already dispatched; these traces decide no Dispatch admission.

The old-pin and overlapping-publication pairs retain both sides' assumptions,
installation history and pending state. Each admitted partner is a withdrawn-guard
trap. `older_publication_still_refused_after_restart` preserves a still earlier
installation's overlap through restart. The separate
`pending_restart_then_fresh_admitted` continuation starts from its own intact source
history, admits a fresh disjoint publication and then a connection. It is useful
progress, never proof that a refused candidate became fresh or that an old history
was forgotten. [CHN-R7](../02-channel.md#the-routes-to-a-fingerprint) says “restart
and Restore do not” open another group and “the old installed pin authorizes no new
contact.” Comparison exceptions in other corpus pairs are not generalized into
this selection; all selected pair assumptions are shown whole. Bounds do not prove
TLS, honest scanning, contact timing or implementation migration.

<!-- atlas-info: pins-v5 -->
Evidence: generated witness projection; pins source header and complete bound context.
Applicability: LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.
External possibilities: not recorded here. Permitted next actions: consult the owning rules; no source outcome supplies extra authority.
Bound: finite source context only, neither completeness nor implementation evidence. Named traces are not claims about the enumeration.

| Source header and bound context (complete) |
|---|
| `{"bound": {"alphabet": [{"entry": 1, "keys": [21, 121, 221], "kind": "ready_to_reset", "provenance": "adapter observation", "source": "ready_to_reset"}, {"entry": 1, "keys": [51, 151, 251], "kind": "ready_to_reset", "provenance": "adapter observation", "source": "ready_to_reset"}, {"entry": 1, "keys": [31, 131, 231], "kind": "claim", "per": "machine", "provenance": "model request", "source": "model_text"}, {"append": {"durable": true, "provenance": "storage outcome of an append"}, "author": 1, "entry": 1, "keys": [21, 121, 221], "kind": "attest", "per": "machine", "provenance": "adapter observation", "source": "attest"}, {"append": {"durable": true, "provenance": "storage outcome of an append"}, "author": 2, "entry": 1, "keys": [31, 131, 231], "kind": "attest", "per": "machine", "provenance": "adapter observation", "source": "attest"}, {"kind": "restart", "provenance": "crash"}, {"entry": 1, "keys": [51, 151, 251], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}, {"boot": 0, "entry": 1, "keys": [51, 151, 251], "kind": "published", "per": "boot", "provenance": "adapter observation", "source": "published"}, {"entry": 1, "keys": [51, 151], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}, {"entry": 1, "keys": [51, 152, 252], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}, {"entry": 1, "keys": [52, 152, 252], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}, {"entry": 1, "kind": "reinstall", "provenance": "operator act"}, {"entry": 1, "into": "rescue", "kind": "reset", "provenance": "operator act"}, {"entry": 1, "keys": [10, 110, 210], "kind": "rescue_last", "provenance": "adapter observation", "source": "rescue_last"}, {"entry": 1, "keys": [11, 111, 211], "kind": "rescue_last", "provenance": "adapter observation", "source": "rescue_last"}, {"entry": 1, "kind": "connect", "presents": 11, "provenance": "adapter observation", "system": "rescue"}, {"entry": 1, "kind": "connect", "presents": 21, "provenance": "adapter observation", "system": "installed"}, {"entry": 1, "into": "installed", "kind": "reset", "provenance": "operator act"}, {"entry": 1, "kind": "connect", "presents": 21, "provenance": "adapter observation", "system": "rescue"}, {"entry": 1, "kind": "connect", "presents": 51, "provenance": "adapter observation", "system": "installed"}], "declaration": "TauWeb.Pins.bound", "events": 3, "start": {"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 0}], "halts": [], "pending_reinstall": [], "pins": [], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [], "sessions": [], "snapshot": [{"entry": 1, "keys": [10, 110, 210]}]}}, "module": "pins", "namespace": "TauWeb.Pins", "schema": 5, "source": "docs/design/pins-witnesses-v5.json"}` |

### old pin refused pending reinstall

Evidence: generated witness projection — old_pin_refused_pending_reinstall.
Applicability: LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof. View: old_pin_refused_pending_reinstall. LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.
Named trace; bound alphabet membership and exhaustive coverage are not implied.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Pins.old_pin_refused_pending_reinstall", "order": "curated across traces; source order within each trace", "source": "docs/design/pins-witnesses-v5.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"attestAuthorMatches": true, "attestDurable": true, "attestFirstContact": true, "attestSingleUse": true, "installedFirstContact": true, "journalAppend": "successful append atomically persists machine, pins and consumed state; restart retains them", "publication": "observed vendor status response; all recorded observations, including incomplete and refused publications, and pending reinstall records persist across restart; their failed append is outside this companion, as are TLS, scan honesty, timing and no-contact behavior", "publishedComplete": true, "publishedFresh": true, "publishedWithin": true, "readyAfterReinstallFresh": true, "reinstallRetiresPin": true, "sealAuthor": "observed author after unwrap; cryptography assumed", "senderAssociation": "planted sender ordinal equals machine entry; fixed across restart", "sourceAdmitsPin": true, "window": "attest observations delivered during the browser introduction window"}, "declarations": ["TauWeb.Pins.old_pin_refused_pending_reinstall"], "pair": {"side": "refused", "with": "TauWeb.Pins.old_pin_admitted_without_reinstall_guard"}}` |
| Starting projection (complete) | `{"awaiting": [], "boot": [], "confirmed": [], "consumed_introductions": [], "current_installations": [], "halts": [], "pending_reinstall": [], "pins": [], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [], "sessions": [], "snapshot": []}` |

Evidence: generated witness projection — old_pin_refused_pending_reinstall steps.
Applicability: LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof. View: old_pin_refused_pending_reinstall. Source steps. LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"entry": 1, "keys": [51, 151, 251], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}` | `{"pinned": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 0}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}], "sessions": [], "snapshot": []}` |
| 2 | `{"entry": 1, "kind": "reinstall", "provenance": "operator act"}` | `{"pending": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [], "pending_reinstall": [1], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": []}], "sessions": [], "snapshot": []}` |
| 3 | `{"entry": 1, "kind": "connect", "presents": 51, "provenance": "adapter observation", "system": "installed"}` | `{"check": "halted", "halt": "no_pin"}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [{"entry": 1, "presented": 51, "reason": "no_pin", "system": "installed"}], "pending_reinstall": [1], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": []}], "sessions": [], "snapshot": []}` |

### old pin admitted without reinstall guard

Evidence: generated witness projection — old_pin_admitted_without_reinstall_guard.
Applicability: LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof. Withdrawn-guard historical trap, never a production-success target. View: old_pin_admitted_without_reinstall_guard. LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.
Named trace; bound alphabet membership and exhaustive coverage are not implied.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Pins.old_pin_admitted_without_reinstall_guard", "order": "curated across traces; source order within each trace", "source": "docs/design/pins-witnesses-v5.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"attestAuthorMatches": true, "attestDurable": true, "attestFirstContact": true, "attestSingleUse": true, "installedFirstContact": true, "journalAppend": "successful append atomically persists machine, pins and consumed state; restart retains them", "publication": "observed vendor status response; all recorded observations, including incomplete and refused publications, and pending reinstall records persist across restart; their failed append is outside this companion, as are TLS, scan honesty, timing and no-contact behavior", "publishedComplete": true, "publishedFresh": true, "publishedWithin": true, "readyAfterReinstallFresh": true, "reinstallRetiresPin": false, "sealAuthor": "observed author after unwrap; cryptography assumed", "senderAssociation": "planted sender ordinal equals machine entry; fixed across restart", "sourceAdmitsPin": true, "window": "attest observations delivered during the browser introduction window"}, "declarations": ["TauWeb.Pins.old_pin_admitted_without_reinstall_guard"], "pair": {"side": "admitted", "with": "TauWeb.Pins.old_pin_refused_pending_reinstall"}}` |
| Starting projection (complete) | `{"awaiting": [], "boot": [], "confirmed": [], "consumed_introductions": [], "current_installations": [], "halts": [], "pending_reinstall": [], "pins": [], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [], "sessions": [], "snapshot": []}` |

Evidence: generated witness projection — old_pin_admitted_without_reinstall_guard steps.
Applicability: LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof. Withdrawn-guard historical trap, never a production-success target. View: old_pin_admitted_without_reinstall_guard. Source steps. LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"entry": 1, "keys": [51, 151, 251], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}` | `{"pinned": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 0}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}], "sessions": [], "snapshot": []}` |
| 2 | `{"entry": 1, "kind": "reinstall", "provenance": "operator act"}` | `{"pending": false}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 0}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}], "sessions": [], "snapshot": []}` |
| 3 | `{"entry": 1, "kind": "connect", "presents": 51, "provenance": "adapter observation", "system": "installed"}` | `{"check": "admitted"}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 0}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}], "sessions": [{"boot": 0, "entry": 1, "installation": 0, "pin": {"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}, "presented": 51, "system": "installed"}], "snapshot": []}` |

### overlapping publication refused

Evidence: generated witness projection — overlapping_publication_refused.
Applicability: LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof. View: overlapping_publication_refused. LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Pins.overlapping_publication_refused", "order": "curated across traces; source order within each trace", "source": "docs/design/pins-witnesses-v5.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"attestAuthorMatches": true, "attestDurable": true, "attestFirstContact": true, "attestSingleUse": true, "installedFirstContact": true, "journalAppend": "successful append atomically persists machine, pins and consumed state; restart retains them", "publication": "observed vendor status response; all recorded observations, including incomplete and refused publications, and pending reinstall records persist across restart; their failed append is outside this companion, as are TLS, scan honesty, timing and no-contact behavior", "publishedComplete": true, "publishedFresh": true, "publishedWithin": true, "readyAfterReinstallFresh": true, "reinstallRetiresPin": true, "sealAuthor": "observed author after unwrap; cryptography assumed", "senderAssociation": "planted sender ordinal equals machine entry; fixed across restart", "sourceAdmitsPin": true, "window": "attest observations delivered during the browser introduction window"}, "declarations": ["TauWeb.Pins.overlapping_publication_refused"], "pair": {"side": "refused", "with": "TauWeb.Pins.overlapping_publication_admitted_without_guard"}}` |
| Starting projection (complete) | `{"awaiting": [], "boot": [], "confirmed": [], "consumed_introductions": [], "current_installations": [], "halts": [], "pending_reinstall": [], "pins": [], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [], "sessions": [], "snapshot": []}` |

Evidence: generated witness projection — overlapping_publication_refused steps.
Applicability: LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof. View: overlapping_publication_refused. Source steps. LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"entry": 1, "keys": [51, 151, 251], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}` | `{"pinned": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 0}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}], "sessions": [], "snapshot": []}` |
| 2 | `{"entry": 1, "kind": "reinstall", "provenance": "operator act"}` | `{"pending": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [], "pending_reinstall": [1], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": []}], "sessions": [], "snapshot": []}` |
| 3 | `{"entry": 1, "keys": [53, 151, 253], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}` | `{"pinned": false}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [], "pending_reinstall": [1], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": [[53, 151, 253]]}], "sessions": [], "snapshot": []}` |
| 4 | `{"entry": 1, "kind": "connect", "presents": 53, "provenance": "adapter observation", "system": "installed"}` | `{"check": "halted", "halt": "no_pin"}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [{"entry": 1, "presented": 53, "reason": "no_pin", "system": "installed"}], "pending_reinstall": [1], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": [[53, 151, 253]]}], "sessions": [], "snapshot": []}` |

### overlapping publication admitted without guard

Evidence: generated witness projection — overlapping_publication_admitted_without_guard.
Applicability: LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof. Withdrawn-guard historical trap, never a production-success target. View: overlapping_publication_admitted_without_guard. LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Pins.overlapping_publication_admitted_without_guard", "order": "curated across traces; source order within each trace", "source": "docs/design/pins-witnesses-v5.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"attestAuthorMatches": true, "attestDurable": true, "attestFirstContact": true, "attestSingleUse": true, "installedFirstContact": true, "journalAppend": "successful append atomically persists machine, pins and consumed state; restart retains them", "publication": "observed vendor status response; all recorded observations, including incomplete and refused publications, and pending reinstall records persist across restart; their failed append is outside this companion, as are TLS, scan honesty, timing and no-contact behavior", "publishedComplete": true, "publishedFresh": false, "publishedWithin": true, "readyAfterReinstallFresh": true, "reinstallRetiresPin": true, "sealAuthor": "observed author after unwrap; cryptography assumed", "senderAssociation": "planted sender ordinal equals machine entry; fixed across restart", "sourceAdmitsPin": true, "window": "attest observations delivered during the browser introduction window"}, "declarations": ["TauWeb.Pins.overlapping_publication_admitted_without_guard"], "pair": {"side": "admitted", "with": "TauWeb.Pins.overlapping_publication_refused"}}` |
| Starting projection (complete) | `{"awaiting": [], "boot": [], "confirmed": [], "consumed_introductions": [], "current_installations": [], "halts": [], "pending_reinstall": [], "pins": [], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [], "sessions": [], "snapshot": []}` |

Evidence: generated witness projection — overlapping_publication_admitted_without_guard steps.
Applicability: LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof. Withdrawn-guard historical trap, never a production-success target. View: overlapping_publication_admitted_without_guard. Source steps. LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"entry": 1, "keys": [51, 151, 251], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}` | `{"pinned": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 0}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}], "sessions": [], "snapshot": []}` |
| 2 | `{"entry": 1, "kind": "reinstall", "provenance": "operator act"}` | `{"pending": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [], "pending_reinstall": [1], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": []}], "sessions": [], "snapshot": []}` |
| 3 | `{"entry": 1, "keys": [53, 151, 253], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}` | `{"pinned": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}, {"entry": 1, "installation": 1, "keys": [53, 151, 253], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": [[53, 151, 253]]}], "sessions": [], "snapshot": []}` |
| 4 | `{"entry": 1, "kind": "connect", "presents": 53, "provenance": "adapter observation", "system": "installed"}` | `{"check": "admitted"}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}, {"entry": 1, "installation": 1, "keys": [53, 151, 253], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": [[53, 151, 253]]}], "sessions": [{"boot": 0, "entry": 1, "installation": 1, "pin": {"entry": 1, "installation": 1, "keys": [53, 151, 253], "per": "machine", "source": "published"}, "presented": 53, "system": "installed"}], "snapshot": []}` |

### older publication still refused after restart

Evidence: generated witness projection — older_publication_still_refused_after_restart.
Applicability: LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof. View: older_publication_still_refused_after_restart. LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Pins.older_publication_still_refused_after_restart", "order": "curated across traces; source order within each trace", "source": "docs/design/pins-witnesses-v5.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"attestAuthorMatches": true, "attestDurable": true, "attestFirstContact": true, "attestSingleUse": true, "installedFirstContact": true, "journalAppend": "successful append atomically persists machine, pins and consumed state; restart retains them", "publication": "observed vendor status response; all recorded observations, including incomplete and refused publications, and pending reinstall records persist across restart; their failed append is outside this companion, as are TLS, scan honesty, timing and no-contact behavior", "publishedComplete": true, "publishedFresh": true, "publishedWithin": true, "readyAfterReinstallFresh": true, "reinstallRetiresPin": true, "sealAuthor": "observed author after unwrap; cryptography assumed", "senderAssociation": "planted sender ordinal equals machine entry; fixed across restart", "sourceAdmitsPin": true, "window": "attest observations delivered during the browser introduction window"}, "declarations": ["TauWeb.Pins.older_publication_still_refused_after_restart"]}` |
| Starting projection (complete) | `{"awaiting": [], "boot": [], "confirmed": [], "consumed_introductions": [], "current_installations": [], "halts": [], "pending_reinstall": [], "pins": [], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [], "sessions": [], "snapshot": []}` |

Evidence: generated witness projection — older_publication_still_refused_after_restart steps.
Applicability: LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof. View: older_publication_still_refused_after_restart. Source steps. LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"entry": 1, "keys": [51, 151, 251], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}` | `{"pinned": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 0}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}], "sessions": [], "snapshot": []}` |
| 2 | `{"entry": 1, "kind": "reinstall", "provenance": "operator act"}` | `{"pending": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [], "pending_reinstall": [1], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": []}], "sessions": [], "snapshot": []}` |
| 3 | `{"entry": 1, "keys": [52, 152, 252], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}` | `{"pinned": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}, {"entry": 1, "installation": 1, "keys": [52, 152, 252], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": [[52, 152, 252]]}], "sessions": [], "snapshot": []}` |
| 4 | `{"kind": "restart", "provenance": "crash"}` | `{"replayed": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}, {"entry": 1, "installation": 1, "keys": [52, 152, 252], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": [[52, 152, 252]]}], "sessions": [], "snapshot": []}` |
| 5 | `{"entry": 1, "kind": "reinstall", "provenance": "operator act"}` | `{"pending": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 2}], "halts": [], "pending_reinstall": [1], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}, {"entry": 1, "installation": 1, "keys": [52, 152, 252], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": [[52, 152, 252]]}, {"entry": 1, "installation": 2, "observations": []}], "sessions": [], "snapshot": []}` |
| 6 | `{"entry": 1, "keys": [54, 151, 254], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}` | `{"pinned": false}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 2}], "halts": [], "pending_reinstall": [1], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}, {"entry": 1, "installation": 1, "keys": [52, 152, 252], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": [[52, 152, 252]]}, {"entry": 1, "installation": 2, "observations": [[54, 151, 254]]}], "sessions": [], "snapshot": []}` |
| 7 | `{"entry": 1, "kind": "connect", "presents": 54, "provenance": "adapter observation", "system": "installed"}` | `{"check": "halted", "halt": "no_pin"}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 2}], "halts": [{"entry": 1, "presented": 54, "reason": "no_pin", "system": "installed"}], "pending_reinstall": [1], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}, {"entry": 1, "installation": 1, "keys": [52, 152, 252], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": [[52, 152, 252]]}, {"entry": 1, "installation": 2, "observations": [[54, 151, 254]]}], "sessions": [], "snapshot": []}` |

### pending restart then fresh admitted

Evidence: generated witness projection — pending_restart_then_fresh_admitted.
Applicability: LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof. View: pending_restart_then_fresh_admitted. LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.
Named trace outside event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Pins.pending_restart_then_fresh_admitted", "order": "curated across traces; source order within each trace", "source": "docs/design/pins-witnesses-v5.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"attestAuthorMatches": true, "attestDurable": true, "attestFirstContact": true, "attestSingleUse": true, "installedFirstContact": true, "journalAppend": "successful append atomically persists machine, pins and consumed state; restart retains them", "publication": "observed vendor status response; all recorded observations, including incomplete and refused publications, and pending reinstall records persist across restart; their failed append is outside this companion, as are TLS, scan honesty, timing and no-contact behavior", "publishedComplete": true, "publishedFresh": true, "publishedWithin": true, "readyAfterReinstallFresh": true, "reinstallRetiresPin": true, "sealAuthor": "observed author after unwrap; cryptography assumed", "senderAssociation": "planted sender ordinal equals machine entry; fixed across restart", "sourceAdmitsPin": true, "window": "attest observations delivered during the browser introduction window"}, "declarations": ["TauWeb.Pins.pending_restart_then_fresh_admitted"]}` |
| Starting projection (complete) | `{"awaiting": [], "boot": [], "confirmed": [], "consumed_introductions": [], "current_installations": [], "halts": [], "pending_reinstall": [], "pins": [], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [], "sessions": [], "snapshot": []}` |

Evidence: generated witness projection — pending_restart_then_fresh_admitted steps.
Applicability: LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof. View: pending_restart_then_fresh_admitted. Source steps. LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |
|---|---|---|---|
| 1 | `{"entry": 1, "keys": [51, 151, 251], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}` | `{"pinned": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 0}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}], "sessions": [], "snapshot": []}` |
| 2 | `{"entry": 1, "kind": "reinstall", "provenance": "operator act"}` | `{"pending": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [], "pending_reinstall": [1], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": []}], "sessions": [], "snapshot": []}` |
| 3 | `{"kind": "restart", "provenance": "crash"}` | `{"replayed": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [], "pending_reinstall": [1], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": []}], "sessions": [], "snapshot": []}` |
| 4 | `{"entry": 1, "keys": [52, 152, 252], "kind": "published", "per": "machine", "provenance": "adapter observation", "source": "published"}` | `{"pinned": true}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}, {"entry": 1, "installation": 1, "keys": [52, 152, 252], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": [[52, 152, 252]]}], "sessions": [], "snapshot": []}` |
| 5 | `{"entry": 1, "kind": "connect", "presents": 52, "provenance": "adapter observation", "system": "installed"}` | `{"check": "admitted"}` | `{"awaiting": [], "boot": [{"boot": 0, "entry": 1}], "confirmed": [], "consumed_introductions": [], "current_installations": [{"entry": 1, "installation": 1}], "halts": [], "pending_reinstall": [], "pins": [{"entry": 1, "installation": 0, "keys": [51, 151, 251], "per": "machine", "source": "published"}, {"entry": 1, "installation": 1, "keys": [52, 152, 252], "per": "machine", "source": "published"}], "planted_senders": [{"entry": 1, "sender": 1}], "publication_groups": [{"entry": 1, "installation": 0, "observations": [[51, 151, 251]]}, {"entry": 1, "installation": 1, "observations": [[52, 152, 252]]}], "sessions": [{"boot": 0, "entry": 1, "installation": 1, "pin": {"entry": 1, "installation": 1, "keys": [52, 152, 252], "per": "machine", "source": "published"}, "presented": 52, "system": "installed"}], "snapshot": []}` |
<!-- /atlas-info -->

## Declaration traces

Evidence: conceptual navigation to generated declaration projections.
Applicability: field presence and opaque-item set difference; the source is
[Declaration schema 1](design/declaration-witnesses-v1.json), with
[Declaration.lean](../tools/formal/TauWeb/Declaration.lean)'s assumptions and omissions.
The bound is a field/presence/observation/tenancy sweep, not an event-count bound.
The missing field in `absent_field_refused` is source data, not a renderer omission.

The listener finding, unspecified template and absent-field views remain separate
histories. The empty-inbound historical pair retains the withdrawn empty-list
meaning; `adhoc_delivered` is a separately complete field-check success, not a repair
or re-check of the earlier machine. The source's service items are ordinals: they
carry no service lifecycle, placement or secret semantics. Concrete field grammar
and presence meanings remain in
[delivery declaration v2](design/delivery-declaration-v1.md#presence-rule).

### Findings, placement and re-check — illustrative prose-only

Evidence: illustrative prose-only narrative, separate from Declaration field checks.
Applicability: LNVPS-path delivery and placing sessions; no checked composition with
Dispatch, Allocation or Pins. Owners:
[ARC-17/39](../01-architecture.md#what-a-session-delivers),
[ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) and
[SEC-5](../04-security-model.md#sec-5--the-credential-inventory).

Suppose a harness-composed lifecycle read produces a lifecycle finding. The reader
then follows the placement permission and fixed lockdown prerequisites in ARC-17,
with the separate protection and scan duties in ARC-43/SEC-5. `ARC-17` says “Every
other finding, a lockdown finding included, still refuses placement” and “placement
itself clears no finding.” After placement the reader follows the placing-session
demonstration and re-check, rather than interpreting a Declaration service ordinal
as evidence that a real service ran. `ARC-17` says “A finding is cleared by a re-check
and by nothing else”. No placement or re-check is inserted into a generated trace.

<!-- atlas-info: declaration-v1 -->
Evidence: generated witness projection; declaration source header and complete bound context.
Applicability: Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.
External possibilities: not recorded here. Permitted next actions: consult the owning rules; no source outcome supplies extra authority.
Bound: finite source context only, neither completeness nor implementation evidence. Named traces are not claims about the enumeration.

| Source header and bound context (complete) |
|---|
| `{"bound": {"base": {"declaration": {"default_credentials": "none", "drift_checks": [], "key_material.permitted": [], "key_material.spendable": false, "listeners.inbound": [22], "listeners.outbound": [], "required": [], "services": [], "version": 2}, "machine": {"multi_tenant": false, "observed": {"default_credentials": [], "drift_checks": [], "key_material.permitted": [], "key_material.spendable": [], "listeners.inbound": [22], "listeners.outbound": [], "required": [], "services": [], "version": []}}}, "declaration": "TauWeb.Declaration.bound", "observations": [[], [1]], "presences": {"default_credentials": ["missing", "unspecified", "none", [1]], "drift_checks": ["missing", "unspecified", [], [1]], "key_material.permitted": ["missing", "unspecified", [], [1]], "key_material.spendable": ["missing", "unspecified", false, true], "listeners.inbound": ["missing", "unspecified", [], [1]], "listeners.outbound": ["missing", "unspecified", [], [1]], "required": ["missing", "unspecified", [], [1]], "services": ["missing", "unspecified", [], [1]], "version": ["missing", "unspecified", 1, 2]}, "tenancies": [false, true]}, "module": "declaration", "namespace": "TauWeb.Declaration", "schema": 1, "source": "docs/design/declaration-witnesses-v1.json"}` |

### undeclared listener finding

Evidence: generated witness projection — undeclared_listener_finding.
Applicability: Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics. View: undeclared_listener_finding. Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.
Declaration field/presence/observation/tenancy sweep, not an event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Declaration.undeclared_listener_finding", "order": "curated across traces; source order within each trace", "source": "docs/design/declaration-witnesses-v1.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"emptyMeansPerField": true}, "declarations": ["TauWeb.Declaration.undeclared_listener_finding"]}` |
| Starting projection (complete) | `{"declaration": {"default_credentials": "none", "drift_checks": [], "key_material.permitted": [], "key_material.spendable": false, "listeners.inbound": [22], "listeners.outbound": [], "required": [], "services": [], "version": 2}, "machine": {"multi_tenant": false, "observed": {"default_credentials": [], "drift_checks": [], "key_material.permitted": [], "key_material.spendable": [], "listeners.inbound": [22, 80], "listeners.outbound": [], "required": [], "services": [], "version": []}}, "record": {"delivered": false, "verdicts": {}}}` |

Evidence: generated witness projection — undeclared_listener_finding steps.
Applicability: Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics. View: undeclared_listener_finding. Source steps. Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source record after step (complete) |
|---|---|---|---|
| 1 | `{"field": "version", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"version": "pass"}}` |
| 2 | `{"field": "listeners.inbound", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "finding"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "finding", "version": "pass"}}` |
| 3 | `{"field": "listeners.outbound", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "finding", "listeners.outbound": "pass", "version": "pass"}}` |
| 4 | `{"field": "services", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "finding", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 5 | `{"field": "key_material.spendable", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"key_material.spendable": "pass", "listeners.inbound": "finding", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 6 | `{"field": "key_material.permitted", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "finding", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 7 | `{"field": "drift_checks", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "finding", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 8 | `{"field": "required", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "finding", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |
| 9 | `{"field": "default_credentials", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"default_credentials": "pass", "drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "finding", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |
| 10 | `{"kind": "deliver", "provenance": "model request"}` | `{"delivered": false}` | `{"delivered": false, "verdicts": {"default_credentials": "pass", "drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "finding", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |

### template blocked

Evidence: generated witness projection — template_blocked.
Applicability: Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics. View: template_blocked. Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.
Declaration field/presence/observation/tenancy sweep, not an event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Declaration.template_blocked", "order": "curated across traces; source order within each trace", "source": "docs/design/declaration-witnesses-v1.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"emptyMeansPerField": true}, "declarations": ["TauWeb.Declaration.template_blocked"]}` |
| Starting projection (complete) | `{"declaration": {"default_credentials": "unspecified", "drift_checks": "unspecified", "key_material.permitted": "unspecified", "key_material.spendable": false, "listeners.inbound": "unspecified", "listeners.outbound": "unspecified", "required": "unspecified", "services": "unspecified", "version": 2}, "machine": {"multi_tenant": false, "observed": {"default_credentials": [], "drift_checks": [], "key_material.permitted": [], "key_material.spendable": [], "listeners.inbound": [22], "listeners.outbound": [], "required": [], "services": [1], "version": []}}, "record": {"delivered": false, "verdicts": {}}}` |

Evidence: generated witness projection — template_blocked steps.
Applicability: Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics. View: template_blocked. Source steps. Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source record after step (complete) |
|---|---|---|---|
| 1 | `{"field": "version", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"version": "pass"}}` |
| 2 | `{"field": "listeners.inbound", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "blocked"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "blocked", "version": "pass"}}` |
| 3 | `{"field": "listeners.outbound", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "blocked"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "blocked", "listeners.outbound": "blocked", "version": "pass"}}` |
| 4 | `{"field": "services", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "blocked"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "blocked", "listeners.outbound": "blocked", "services": "blocked", "version": "pass"}}` |
| 5 | `{"field": "key_material.spendable", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"key_material.spendable": "pass", "listeners.inbound": "blocked", "listeners.outbound": "blocked", "services": "blocked", "version": "pass"}}` |
| 6 | `{"field": "key_material.permitted", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "blocked"}` | `{"delivered": false, "verdicts": {"key_material.permitted": "blocked", "key_material.spendable": "pass", "listeners.inbound": "blocked", "listeners.outbound": "blocked", "services": "blocked", "version": "pass"}}` |
| 7 | `{"field": "drift_checks", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "blocked"}` | `{"delivered": false, "verdicts": {"drift_checks": "blocked", "key_material.permitted": "blocked", "key_material.spendable": "pass", "listeners.inbound": "blocked", "listeners.outbound": "blocked", "services": "blocked", "version": "pass"}}` |
| 8 | `{"field": "required", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "blocked"}` | `{"delivered": false, "verdicts": {"drift_checks": "blocked", "key_material.permitted": "blocked", "key_material.spendable": "pass", "listeners.inbound": "blocked", "listeners.outbound": "blocked", "required": "blocked", "services": "blocked", "version": "pass"}}` |
| 9 | `{"field": "default_credentials", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "blocked"}` | `{"delivered": false, "verdicts": {"default_credentials": "blocked", "drift_checks": "blocked", "key_material.permitted": "blocked", "key_material.spendable": "pass", "listeners.inbound": "blocked", "listeners.outbound": "blocked", "required": "blocked", "services": "blocked", "version": "pass"}}` |
| 10 | `{"kind": "deliver", "provenance": "model request"}` | `{"delivered": false}` | `{"delivered": false, "verdicts": {"default_credentials": "blocked", "drift_checks": "blocked", "key_material.permitted": "blocked", "key_material.spendable": "pass", "listeners.inbound": "blocked", "listeners.outbound": "blocked", "required": "blocked", "services": "blocked", "version": "pass"}}` |

### absent field refused

Evidence: generated witness projection — absent_field_refused.
Applicability: Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics. View: absent_field_refused. Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.
Declaration field/presence/observation/tenancy sweep, not an event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Declaration.absent_field_refused", "order": "curated across traces; source order within each trace", "source": "docs/design/declaration-witnesses-v1.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"emptyMeansPerField": true}, "declarations": ["TauWeb.Declaration.absent_field_refused"]}` |
| Starting projection (complete) | `{"declaration": {"default_credentials": "none", "key_material.permitted": [], "key_material.spendable": false, "listeners.inbound": [22], "listeners.outbound": [], "required": [], "services": [], "version": 2}, "machine": {"multi_tenant": false, "observed": {"default_credentials": [], "drift_checks": [], "key_material.permitted": [], "key_material.spendable": [], "listeners.inbound": [22], "listeners.outbound": [], "required": [], "services": [], "version": []}}, "record": {"delivered": false, "verdicts": {}}}` |

Evidence: generated witness projection — absent_field_refused steps.
Applicability: Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics. View: absent_field_refused. Source steps. Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source record after step (complete) |
|---|---|---|---|
| 1 | `{"field": "version", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"version": "pass"}}` |
| 2 | `{"field": "listeners.inbound", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "pass", "version": "pass"}}` |
| 3 | `{"field": "listeners.outbound", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "pass", "listeners.outbound": "pass", "version": "pass"}}` |
| 4 | `{"field": "services", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "pass", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 5 | `{"field": "key_material.spendable", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 6 | `{"field": "key_material.permitted", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 7 | `{"field": "drift_checks", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "refused"}` | `{"delivered": false, "verdicts": {"drift_checks": "refused", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 8 | `{"field": "required", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"drift_checks": "refused", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |
| 9 | `{"field": "default_credentials", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"default_credentials": "pass", "drift_checks": "refused", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |
| 10 | `{"kind": "deliver", "provenance": "model request"}` | `{"delivered": false}` | `{"delivered": false, "verdicts": {"default_credentials": "pass", "drift_checks": "refused", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |

### empty inbound refused

Evidence: generated witness projection — empty_inbound_refused.
Applicability: Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics. View: empty_inbound_refused. Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.
Declaration field/presence/observation/tenancy sweep, not an event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Declaration.empty_inbound_refused", "order": "curated across traces; source order within each trace", "source": "docs/design/declaration-witnesses-v1.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"emptyMeansPerField": true}, "declarations": ["TauWeb.Declaration.empty_inbound_refused"], "pair": {"side": "refused", "with": "TauWeb.Declaration.empty_inbound_admitted"}}` |
| Starting projection (complete) | `{"declaration": {"default_credentials": "none", "drift_checks": [], "key_material.permitted": [], "key_material.spendable": false, "listeners.inbound": [], "listeners.outbound": [], "required": [], "services": [], "version": 2}, "machine": {"multi_tenant": false, "observed": {"default_credentials": [], "drift_checks": [], "key_material.permitted": [], "key_material.spendable": [], "listeners.inbound": [22], "listeners.outbound": [], "required": [], "services": [], "version": []}}, "record": {"delivered": false, "verdicts": {}}}` |

Evidence: generated witness projection — empty_inbound_refused steps.
Applicability: Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics. View: empty_inbound_refused. Source steps. Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source record after step (complete) |
|---|---|---|---|
| 1 | `{"field": "version", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"version": "pass"}}` |
| 2 | `{"field": "listeners.inbound", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "finding"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "finding", "version": "pass"}}` |
| 3 | `{"field": "listeners.outbound", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "finding", "listeners.outbound": "pass", "version": "pass"}}` |
| 4 | `{"field": "services", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "finding", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 5 | `{"field": "key_material.spendable", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"key_material.spendable": "pass", "listeners.inbound": "finding", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 6 | `{"field": "key_material.permitted", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "finding", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 7 | `{"field": "drift_checks", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "finding", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 8 | `{"field": "required", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "finding", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |
| 9 | `{"field": "default_credentials", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"default_credentials": "pass", "drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "finding", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |
| 10 | `{"kind": "deliver", "provenance": "model request"}` | `{"delivered": false}` | `{"delivered": false, "verdicts": {"default_credentials": "pass", "drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "finding", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |

### empty inbound admitted

Evidence: generated witness projection — empty_inbound_admitted.
Applicability: Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics. Withdrawn-guard historical trap, never a production-success target. View: empty_inbound_admitted. Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.
Declaration field/presence/observation/tenancy sweep, not an event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Declaration.empty_inbound_admitted", "order": "curated across traces; source order within each trace", "source": "docs/design/declaration-witnesses-v1.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"emptyMeansPerField": false}, "declarations": ["TauWeb.Declaration.empty_inbound_admitted"], "pair": {"side": "admitted", "with": "TauWeb.Declaration.empty_inbound_refused"}}` |
| Starting projection (complete) | `{"declaration": {"default_credentials": "none", "drift_checks": [], "key_material.permitted": [], "key_material.spendable": false, "listeners.inbound": [], "listeners.outbound": [], "required": [], "services": [], "version": 2}, "machine": {"multi_tenant": false, "observed": {"default_credentials": [], "drift_checks": [], "key_material.permitted": [], "key_material.spendable": [], "listeners.inbound": [22], "listeners.outbound": [], "required": [], "services": [], "version": []}}, "record": {"delivered": false, "verdicts": {}}}` |

Evidence: generated witness projection — empty_inbound_admitted steps.
Applicability: Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics. Withdrawn-guard historical trap, never a production-success target. View: empty_inbound_admitted. Source steps. Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source record after step (complete) |
|---|---|---|---|
| 1 | `{"field": "version", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"version": "pass"}}` |
| 2 | `{"field": "listeners.inbound", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "pass", "version": "pass"}}` |
| 3 | `{"field": "listeners.outbound", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "pass", "listeners.outbound": "pass", "version": "pass"}}` |
| 4 | `{"field": "services", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "pass", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 5 | `{"field": "key_material.spendable", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 6 | `{"field": "key_material.permitted", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 7 | `{"field": "drift_checks", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 8 | `{"field": "required", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |
| 9 | `{"field": "default_credentials", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"default_credentials": "pass", "drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |
| 10 | `{"kind": "deliver", "provenance": "model request"}` | `{"delivered": true}` | `{"delivered": true, "verdicts": {"default_credentials": "pass", "drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |

### adhoc delivered

Evidence: generated witness projection — adhoc_delivered.
Applicability: Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics. View: adhoc_delivered. Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.
Declaration field/presence/observation/tenancy sweep, not an event-count bound.

| Source metadata | Value |
|---|---|
| Selection provenance | `{"case": null, "declaration": "TauWeb.Declaration.adhoc_delivered", "order": "curated across traces; source order within each trace", "source": "docs/design/declaration-witnesses-v1.json"}` |
| Declarations, assumptions, pair (when present) | `{"assumptions": {"emptyMeansPerField": true}, "declarations": ["TauWeb.Declaration.adhoc_delivered"]}` |
| Starting projection (complete) | `{"declaration": {"default_credentials": "none", "drift_checks": [], "key_material.permitted": [], "key_material.spendable": false, "listeners.inbound": [22], "listeners.outbound": [], "required": [], "services": [], "version": 2}, "machine": {"multi_tenant": false, "observed": {"default_credentials": [], "drift_checks": [], "key_material.permitted": [], "key_material.spendable": [], "listeners.inbound": [22], "listeners.outbound": [], "required": [], "services": [], "version": []}}, "record": {"delivered": false, "verdicts": {}}}` |

Evidence: generated witness projection — adhoc_delivered steps.
Applicability: Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics. View: adhoc_delivered. Source steps. Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.
External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.

| Step | Source event | Source outcome members (empty means none) | Source record after step (complete) |
|---|---|---|---|
| 1 | `{"field": "version", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"version": "pass"}}` |
| 2 | `{"field": "listeners.inbound", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "pass", "version": "pass"}}` |
| 3 | `{"field": "listeners.outbound", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "pass", "listeners.outbound": "pass", "version": "pass"}}` |
| 4 | `{"field": "services", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"listeners.inbound": "pass", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 5 | `{"field": "key_material.spendable", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 6 | `{"field": "key_material.permitted", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 7 | `{"field": "drift_checks", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "services": "pass", "version": "pass"}}` |
| 8 | `{"field": "required", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |
| 9 | `{"field": "default_credentials", "kind": "check", "provenance": "adapter observation"}` | `{"verdict": "pass"}` | `{"delivered": false, "verdicts": {"default_credentials": "pass", "drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |
| 10 | `{"kind": "deliver", "provenance": "model request"}` | `{"delivered": true}` | `{"delivered": true, "verdicts": {"default_credentials": "pass", "drift_checks": "pass", "key_material.permitted": "pass", "key_material.spendable": "pass", "listeners.inbound": "pass", "listeners.outbound": "pass", "required": "pass", "services": "pass", "version": "pass"}}` |
<!-- /atlas-info -->

## Historical Relay boundary

Evidence: conceptual navigation, historical companion only; no Relay trace is selected.
Applicability: [Relay schema 1](design/witness-file-v1.md#relay),
[its witnesses](design/relay-witnesses-v1.json) and
[Relay.lean](../tools/formal/TauWeb/Relay.lean)'s historical profile. Its symbolic
challenge, signature-verifier answer, resolver and address-table assumptions prove
no current `/v2/` connection binding, termination, discovery or migration result.
[TASKS.md open T30](../TASKS.md#open-t30-relay-port) owns the port. Neither the module's historical
illustration nor the independent pin/dispatch views form a checked current relay
composition. Current capability applicability remains the
[admission table](../07-conformance.md#capability-applicability-and-admission).
