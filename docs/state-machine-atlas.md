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
for append eligibility and counted restart. Durable journal/snapshot knowledge is
replayed; unresolved calls are derived. Passphrase access does not establish writer
ownership. Authority invalidation routes to STA-23's Lock/shutdown and confirmed
predecessor-termination boundary, not a heartbeat or successful decrypt.

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
  revive on return.” Use STA-23's pre-send/post-await fences on every path.
  ARC-31a's admission, cap and absolute-expiry contract applies on the procured
  inference path only. Durable approval history is not live authority.
  SEC-1's jump-host and Replace key-holding exceptions and SEC-4's abandonment
  authorization have their own owners, not a generic session bypass.

The identity is the rendering session and its bound machine entries; a typed
approval also names its approved facts. ARC-12 is the session owner, SEC-1 the
binding owner, SEC-4 the approval owner, and STA-23 the live-authority owner.
Journaled approval history survives as history; pending approvals and runtime
credentials do not survive session end. Dedicated-path standing reinstall approvals
route also to [STG-20](../06-first-stage.md#what-the-first-stage-does-not-test), which says “An approval **stands** from
its record until its reset is dispatched, a matching withdrawal is recorded, or
the session it was rendered for ends”. Its route limit is “This approval exists
only on the dedicated path; at LNVPS the reinstall call is itself the dispatch, so
no approval waits.” Eligibility is derived from those owners,
not from merely finding an old approval in the store. Procured-key limits are the
conditional ARC-31a dimension, never seed or SSH-key expiry.

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
Confirmation/disposition retires the named open call under STA-24; it does not
retire independent identity exclusions, pins, delivery duties or session fences.
`STA-24` says “it
neither reopens the call nor removes the disposition” (see *When the restriction
ends*).

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

The command key is machine plus tracked call/job, with the record's boot identity;
it is not the service the command launched. Browser intent and durably collected
advisory evidence differ from the transient collector and remotely reported process
state. STA-20/20b and [protected job replay](design/protected-evidence-v1.md#2-job-schema-and-replay)
own these representations. Liveness and hold are derived, not a universal completion
state. Terminal acceptance retires only that command's hold; ended-without-exit,
missing records and stopped collection retain uncertainty. Replay leaves no queued
harness job armed: `STA-20` says “after a stopped wait only the operator resumes that
flow, and nothing left armed survives replay.”

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
and the [pin re-entry reference](#pin-retirement-and-admission) below; restored
active status alone does not admit that contact.

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
  the matrix does not waive any of them.

The keys are the machine's declaration in force, each declared service/boot, and
placement identity (machine, application, secret name and path). ARC-39 and the
[declaration format](design/delivery-declaration-v1.md#shape) own the declaration;
ARC-17/43 own findings, placement gates, evidence labels and the pending check;
SEC-5 and [protected evidence §§1–5](design/protected-evidence-v1.md#1-decoder-boundary-and-facts)
own references, custody and release. Scan material is encrypted local state,
excluded from the sheet, and live arming is not inferred from an orphan scan blob.
Delivery, placement permission and scan readiness are separate derived predicates.
Finding retirement is a re-check. Placement inventory and its reference duty route
to ARC-43 and protected evidence §5's rotation/destruction boundary; stop, absent
file and re-arm do not end that inventory. Each scan key/reference has its separate
[SEC-5 row 23](../04-security-model.md#sec-5--the-credential-inventory) lifetime:
local-store loss loses it, and `SEC-5` says “re-arm replaces it with a fresh
key/reference”. `ARC-43` says “Re-arming neither reapproves the restored declaration
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
Replace's fresh seed does not by itself remove the old remote keys. Restore's
knowledge labels and findings remain STA-16's, scan re-arm remains ARC-43's, and
unknown pre-loss commands remain [tw-ub7](../.beads/issues.jsonl). For restored
LNVPS pin contact use [STA-16](../03-state-and-recovery.md#recovery-by-access-model-and-vendor),
which says “Only a complete set equal to the pin keeps it active”; the required
current-publication re-read is indexed [below](#pin-retirement-and-admission).

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
STA-23 and [the applicable matrix owners](#combined-matrix). A newly composed read
is box-plane work; adapter reconciliation and record collection have their own
permission. `STA-4` says “The record is appended immediately before the bytes
leave”. `STA-3` says “If the append fails, the transition does not occur.” This
boundary changes recorded intent/derived holds, not knowledge of remote execution.

Lost reply/interruption/re-entry route to STA-7/8 and STA-24's dispatch recheck;
`STA-5` says “No unresolved mutation is automatically replayed”. Neither a new call,
index nor successor bypasses the entry barrier. A held command records no intent
(STA-20); a duplicate request identity is not a new retry permission. Evidence:
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
and operation and be durably appended before taking effect.” It also says “Failed
append, timeout and operator disposition establish no success.” Only accepted
durable evidence changes settlement or an admitted mapping; independent pending
checks, scan readiness, session authority and pin admission retain their owners.

Failed append/lost reply retain uncertainty unless authenticated replay establishes
a landed record. §3a specifies “Landed-then-error latches the old writer; fresh
authenticated replay applies the landed evidence once without resend.” Duplicate,
withheld, quarantined,
stale and replayed evidence route to §3a's historical admission and idempotence,
not reconstructed operands or rewritten receipts. After disposition, late evidence
is visible without reopening the call or undoing the standing choice; after session
end, STA-23 forbids stale actionable publication. Coverage:
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
“Only a terminal record releases the hold”. Missing/incomplete, running and proven
ended without exit are different; only the permitted terminal form durably accepted
can change that hold. `STA-21` says “The job record is machine-reported and advisory.”
Its command outcome supplies neither service survival nor cloud confirmation.

Failed/malformed read is not Missing; failed append supplies no durable terminal
result. Duplicate/late/already-settled records retain ordinary admission and
truthful visibility under the protected companion §2. `STA-20` says “stopping
settles nothing, and a machine that cannot be reached is answered at once”.
Re-entry collects rather than automatically repeating the job;
ordinary commands and rescue have different persistence. Coverage:
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
terminal record of its own kind”. Its durable append settles the named open calls
as unknown and establishes/replaces the continuation; unnamed calls and independent
identity exclusions remain. A failed append changes neither. A request racing
terminal evidence is re-evaluated against the journal before it, not accepted as
an unconditional duplicate disposition.

Effects route to *What a disposition reaches*, *A destructive continuation stops
every box-plane job* and *When the restriction ends*, with
[ADR-0044's amendments](adr/0044-a-disposition-limits-what-its-calls-barred.md),
[ADR-0048](adr/0048-an-unresolved-command-holds-its-machine.md) and
[ADR-0050](adr/0050-destructive-dispositions-stop-every-box-plane-job.md).
`STA-24` says “The restriction ends when the continuation it names is dispatched,
its intent durably appended”. Preparation and permitted reads do not end it;
interrupted continuation dispatch leaves its own barrier. Late evidence does not
remove it. Coverage: `TauWeb.Dispatch.replayed_invalid_disposition_means_nothing`,
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
implement continuation.” Ending is a live-authority boundary, not an append that
settles remote work; no unload callback is assumed for journaling. Begun appends
and possibly sent effects retain STA-3/8's durability/uncertainty boundaries.
`STA-23` says “Already accepted remote work may continue even after local Lock or
loss.” Ending one session does not itself lock the store or end another eligible
session. Procured-key expiry/cap/clock fences apply only on that inference path.

Lost reply, stale result or repeated lifecycle notification cannot restore ended
authority; killed/discarded workers restart locked with replay and fresh session
admission. Durable approval history is no substitute. Coverage: prose-only end
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
rather than be cancelled partway.” It retains bindings/writer ownership; possibly
sent work stays uncertain. Continuation validates “current authority, bindings,
holds, connection state and scan readiness” before sends or actionable publication.
That validation changes permission to continue safely; it supplies no remote
terminal evidence, pin or renewed procured-key limit.

`STA-23` says “if it cannot identify one it MUST show reconciliation or required
operator action and wait.” Failed append remains STA-3's, lost replies remain
STA-8's, and duplicate/stale messages remain ordered at the pre-send/post-await
fences. No physical freeze callback, precise physical switch fence or memory
survival is assumed. Coverage: prose-only lifecycle validation; Dispatch's session
convention and the separate tw-237.4 assurance seam are the limits, not a checked
suspension/dispatch composition.

### Pin retirement and admission

Applicability: stage-1 LNVPS reinstall/Restore; the reset-into-rescue and other pin-source routes remain route-specific.

Event/key: dispatch of the operator-chosen destructive reinstall opens the
machine's next installation; vendor publication or an eligible route supplies a
candidate pin. Preconditions, evidence and authority route to
[STG-20](../06-first-stage.md#what-the-first-stage-does-not-test),
[CHN-R7 and the other routes](../02-channel.md#the-routes-to-a-fingerprint),
[SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked),
[ADR-0045](adr/0045-the-installation-label-moves-at-reinstall-dispatch.md) and
STA-3. `STG-20` says the reinstall “opens a new installation when it is
**dispatched**”. The intent's durable boundary changes installation identity and
retires old contact authority, not when approval is rendered or a later key appears.
`CHN-R7` says “restart and Restore do not” open a new group. Its comparison-before-
retention and complete/fresh/contained candidate rules govern admission separately
from reinstall confirmation. Pin admission permits a checked handshake, no job.

Failed append cannot apply the transition; lost reinstall reply leaves its barrier.
Duplicate/refused publications retain history without rewriting the active pin;
re-entry retains active/retired groups and cannot reuse the old pin during the wait.
`CHN-R7` says “A refused or repeated observation cannot rewrite the active pin or
its provenance.” Route-specific waits and unavailable-wire identity retain their
own refusals. Restored active LNVPS pins have an additional
[STA-16 re-read boundary](../03-state-and-recovery.md#recovery-by-access-model-and-vendor):
“before an active `lnvps_retrieve` pin restored from it admits a contact, the harness
MUST read the machine's current published set by `CHN-R7`'s direct fetch.”
`STA-16` says “Only a complete set equal to the pin keeps it active.” Empty, partial,
different or failed reads admit no contact; the first contact stays unresolved.
The reading alone opens no installation and retires no pin; the operator's
reinstall/abandonment routes remain at STA-16/ARC-22. This restored-sheet contact
check is prose-only, not added to the Pins properties below.

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
check, never as a pass.” Failed verdict append therefore supplies no release by
verdict. Lost/interrupted read, refused/held read or no record supplies no pass;
duplicate/stale observations gain no current publication authority from history
(STA-23), and re-entry uses ARC-43's service reads and STA-16's restored labels.

Findings, lifecycle labels, scan arming and permission to place remain independent.
`ARC-17` says “Every other finding, a lockdown finding included, still refuses
placement” and “placement itself clears no finding.” The lifecycle-only case may
permit placement after fixed lockdown checks; its finding still needs re-check,
and the placing session owes its post-placement demonstration. Labels route to
the [observation reference](#boot-and-service-observations) below, not a universal
failure/Delivered conversion. A model-written report is not a verdict.
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
| Typed mutation on the approved entry, including create/order | Refused without applicable authority; otherwise allowed subject to other guards: [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock), [SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved), [STA-23](../03-state-and-recovery.md#durable-state) | Refused: [STA-24](../03-state-and-recovery.md#durable-state) | Refused: [STA-24](../03-state-and-recovery.md#durable-state) | Refused: [STA-24](../03-state-and-recovery.md#durable-state), [STA-20](../03-state-and-recovery.md#durable-state) | Refused except the authorized continuation/preparation, allowed subject to other guards: [STA-24](../03-state-and-recovery.md#durable-state) |
| Adapter reconciliation read | Allowed subject to other guards, under the read/flow authority: [SEC-4](../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved), [STA-23](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [STA-24](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [STA-24](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [STA-20](../03-state-and-recovery.md#durable-state), [STA-24](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [STA-24](../03-state-and-recovery.md#durable-state) |
| Ordinary `exec`, including a read through `exec` | Refused without live binding authority; otherwise allowed subject to other guards: [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock), [STA-23](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [STA-24](../03-state-and-recovery.md#durable-state) | Refused: [STA-24](../03-state-and-recovery.md#durable-state) | Held: [STA-20](../03-state-and-recovery.md#durable-state) | Refused: [STA-24](../03-state-and-recovery.md#durable-state) |
| Harness-owned box-plane job, including a harness-composed read | Applicable session or named flow authority required; allowed subject to other guards: [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [STA-23](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [STA-24](../03-state-and-recovery.md#durable-state) | Refused: [STA-24](../03-state-and-recovery.md#durable-state) | Held: [STA-20](../03-state-and-recovery.md#durable-state) | Refused: [STA-24](../03-state-and-recovery.md#durable-state) |
| Job-record collection (not a new job) | Allowed subject to other guards and current read/flow authority: [STA-20](../03-state-and-recovery.md#durable-state), [STA-23](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [STA-24](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [STA-24](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [STA-20](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [STA-24](../03-state-and-recovery.md#durable-state) |
| Pin-checked connection (not permission to execute) | Refused on binding/pin failure; otherwise allowed subject to other guards: [SEC-1](../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked), [STA-23](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards; no new command permission: [STA-24](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) | Not specified as a general connection permission; named reconciliation contact only: [STA-24](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) | Allowed subject to other guards for collection, no new command: [STA-20](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) | Not specified as a general connection permission; named reconciliation contact only: [STA-24](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) |
| Inference request | Refused without eligible session authority; otherwise allowed subject to other guards (procured limits conditional): [ARC-31a](../01-architecture.md#money), [STA-23](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [STA-24](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [STA-24](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [ARC-31a](../01-architecture.md#money), [STA-20](../03-state-and-recovery.md#durable-state) | Allowed subject to other guards: [STA-24](../03-state-and-recovery.md#durable-state), [ARC-31a](../01-architecture.md#money) |
| Actionable publication | Refused under stale authority; output held until protected release; otherwise allowed subject to other guards: [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) | Not specified by this restriction; publication owners: [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | Not specified by this restriction; publication owners: [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | Not specified by this restriction; publication owners: [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | Not specified for destruction/output interaction; existing publication guards still apply: [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [tw-pkn](../.beads/issues.jsonl) |

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
matrix, with the local qualifications in the extension below.

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

### Pending check, scanning and identity overlaps

Evidence: conceptual navigation, prose-only except §3a's symbolic identity guards
carried by Dispatch. Applicability: typed stage-1 installed machine in the first
three columns; the last column is deferred untyped-vendor material. A cell's
outcome applies only to the named restriction, never as an overall admission.

| Action class | Pending post-restart delivery check | Required scan reference unarmed / protected release | Vendor identity unavailable, quarantined or excluded | Untyped vendor pause / destructive hold |
|---|---|---|---|---|
| Typed mutation | Not specified by this hold; [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [STA-24](../03-state-and-recovery.md#durable-state) still govern | Not specified as a blanket mutation hold; actual custody/pre-send guards at [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) and [§§1–5](design/protected-evidence-v1.md#1-decoder-boundary-and-facts) apply | Refused when wire literal is unavailable; excluded new orders refused; already admitted mappings retain their treatment at [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting) | Not a typed route. Further calls under the affected scope are refused by [STA-24](../03-state-and-recovery.md#durable-state); nothing there is typed as a read |
| Adapter reconciliation read | Allowed subject to other guards at [STA-24](../03-state-and-recovery.md#durable-state); clears no pending check | Allowed subject to other guards, protected evidence/release at [§§1–5](design/protected-evidence-v1.md#1-decoder-boundary-and-facts) | Refused if its wire path needs unavailable literal; other reads unaffected by order exclusion at [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting) | Refused for calls under the affected scope; no typed read exemption, [STA-24](../03-state-and-recovery.md#durable-state) |
| Ordinary `exec` | Held for the model's box-plane commands, [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | Held across bound set while any known required reference is unarmed; output withheld by [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) | Not specified as an independent box-plane hold; quarantine supplies no mapping, [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting) | Held on the affected bound set/vendor, [STA-24](../03-state-and-recovery.md#durable-state) |
| Harness-owned job | Reach beyond the named model commands is not specified as a blanket hold; delivery reads have their own flow, [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | Allowed subject to other guards only for neither-sink jobs; output to either sink has no exemption, [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | Not specified as a separate job hold; quarantine grants no target, [§3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary) | Held during the open-call pause; destructive hold's harness-started reach is not specified, [tw-pgp](../.beads/issues.jsonl), [STA-24](../03-state-and-recovery.md#durable-state) |
| Job-record collection | Allowed subject to other guards at [STA-20/24](../03-state-and-recovery.md#durable-state); no verdict from collection alone | Collection can proceed subject to other guards; output release held until known references armed, [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | Allowed subject to other guards; unavailable literal grants no targeting, [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting) | Allowed subject to other guards; collection is distinct from a call under the scope or a new command, [STA-20/24](../03-state-and-recovery.md#durable-state) |
| Pin-checked connection | Allowed subject to other guards; no command permission, [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) | Not specified as a connection hold; output still protected by [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) | Not specified as an independent connection hold; quarantine admits no mapping or pin, [§3a](design/protected-evidence-v1.md#independent-recovery-and-exact-targeting), [CHN-R7](../02-channel.md#the-routes-to-a-fingerprint) | Not specified as a connection hold; no command permission, [STA-24](../03-state-and-recovery.md#durable-state), [SEC-11](../04-security-model.md#sec-11--the-host-key-is-checked) |
| Inference request | Not held by the named box-plane hold; allowed subject to other guards, [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular), [ARC-31a](../01-architecture.md#money) | Allowed subject to other guards, including actual request/framing custody and release, [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [§3](design/protected-evidence-v1.md#3-protected-inference-terminals) | Allowed subject to other guards; mapping grants no inference authority, [ARC-31a](../01-architecture.md#money) retains its guards | Allowed subject to other guards; inference's separate exception remains [STA-24](../03-state-and-recovery.md#durable-state), [ARC-31a](../01-architecture.md#money), not a vendor-scope read |
| Actionable publication | Not specified by this hold; stopped check supplies no verdict or pass ([ARC-43 quotation above](#pins-output-and-pending-check)). Publication authority and protected release still follow [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) | Held for unscanned bytes; checked verdict/findings only for neither-sink delivery reads, [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular) | Refused as confirmation or usable target from quarantine; protected reporting allowed subject to other guards, [§3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary) | Not specified as a universal publication decision; [STA-23](../03-state-and-recovery.md#durable-state), [SEC-5](../04-security-model.md#sec-5--the-credential-inventory), [tw-pkn](../.beads/issues.jsonl) retain their boundaries |

The decisive owner passages, rather than the matrix pointers, are:

- [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular): “holds the model's
  box-plane commands to that machine”. Its pending-check hold and lifecycle reads
  are **prose-only**. STA-20's broader command hold is not silently substituted.
- `ARC-43` says “Model `exec` across the bound set MUST wait while any known required
  placement reference is unarmed” and “Only harness jobs whose output goes to
  **neither** model nor transcript are exempt”. Its delivery reads “release their
  verdict and findings, never their raw output”. That exemption removes only the
  unarmed-reference barrier; STA-20/24 can still hold/refuse a newly composed read.
  [SEC-5](../04-security-model.md#sec-5--the-credential-inventory) says “Unscanned bytes
  MUST be withheld”; protective encoding supplies no extra settlement authority.
- [STA-24](../03-state-and-recovery.md#durable-state) says “reads, dispositions and
  operations through already admitted mappings are unaffected” by the unavailable-
  identity order exclusion. [Protected evidence §3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary)
  states “No current predicate discharges it.” Its exact-target boundary states
  “A withheld ID, quarantine, marker, receipt or association number, or independently
  generated handle resolves nothing.” Same-entry independent recovery is not
  erasure of different-entry risk. Known retained identity conflict is refusal;
  unknown alias is quarantine, not permission.
- `STA-24` says “nothing under a scope counts as a read, because nothing types it”
  and, for destructive untyped hold, “keeps the model's box-plane commands to the
  machines of the session's bound set at that vendor stopped until the operator
  replaces it”. The typed every-requester stop does not settle
  [tw-pgp](../.beads/issues.jsonl). These untyped restrictions are prose-only and
  retain the later-route applicability in the admission list.

For overlaps, read each applicable restriction separately. A terminal command can
release its command hold while an older LNVPS renewal-off remains unresolved; an accepted
restart can clear its cloud barrier while the pending check remains. A stopped
check has no verdict. A paste can arm a reference without lifting a destructive
stop. These are conceptual owner routes, not a universal first-error order or
additional checked traces. The renewal-off case follows
[STG-21's post-order operation](../06-first-stage.md#the-stages) and
[STA-24's box-plane carve-out](../03-state-and-recovery.md#durable-state):
“Box-plane dispatch to the machine is governed by `STA-20` and `STA-20b`, not by this
rule”, subject to its running-system exception; renewal-off is not a reset,
reinstall, destroy or stand-in stop. Dedicated activation/key-registration overlap
retains its own route. The existing failure/successor allocation questions
[tw-sfu/tw-hwl/tw-nj8](../.beads/issues.jsonl), installation/recovery questions
[tw-l1l/tw-lq8/tw-yhd](../.beads/issues.jsonl), and restored-command boundary
[tw-ub7](../.beads/issues.jsonl) still qualify the affected action.

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

| Observation | Admissible predicate / owner | Boundary it cannot establish |
|---|---|---|
| Exact-call vendor receipt | [STA-24, *What clears it*](../03-state-and-recovery.md#durable-state) and [STG-21a's operation predicates](../06-first-stage.md#the-stages): order, stop, restart have different interpretations | No generic 2xx confirmation, reconstructed withheld identity, host pin or delivery verdict |
| Authenticated status/listing | [STG-21/21a](../06-first-stage.md#the-stages): verified account, qualifying order adoption, registration, renewal-off, reinstall or combined deletion, each under its own predicate | No status-only restart confirmation or fresh stop confirmation from a cached state; deletion requires its combined contract |
| Protected receipt/association | [§3a](design/protected-evidence-v1.md#identity-and-confirmation-boundary): historical eligibility and admitted exact-literal mapping only | Quarantine grants no operational target or order settlement; disposition grants no identity/uniqueness; protection grants no vendor truth |

`STA-24` says “A generic 2xx, an unrelated response or an unvalidated/malformed body
is insufficient.” `STG-21a` says order confirmation “establishes no host creation,
IP allocation, invoice production, payment, boot or contact readiness.” Its
restart clause says “Only a recorded successful response correlated to this exact
restart request confirms the vendor’s report of successful hard-reset task
completion” and “It does not establish a completed guest boot or service survival.”
The subsequent guest-boot read is a separate box-plane job and cannot confirm the
restart. `ARC-43` says “Operation-confirmation evidence admitted by STA-24 supplies
authority only for that operation’s result, not for delivery checks or host-key
pins.” For stop, `STG-21a` says “no currently identified status-read-only predicate
qualifies”. Dedicated Robot's observable-state predicates remain
[STG-4's](../06-first-stage.md#acceptance), not replacement LNVPS evidence.

Coverage boundary: Dispatch carries abstract source/correlation and symbolic
identity guards. Its opening assumptions leave the detailed STG-21a predicates,
protected encodings and listing selection in prose. The generated receipt trace
below establishes no live vendor or device evidence.

### Job records and model-written reports

[STA-20/21](../03-state-and-recovery.md#durable-state) own command/boot classification,
and [protected evidence §2](design/protected-evidence-v1.md#2-job-schema-and-replay)
owns retained/withheld facts and truthful advisory comparison. `STA-20` says “A
record with no exit code and a proven-ended command means it died; the call stays
unresolved”. A terminal record can settle its own command subject to those owners;
its output can supply an ARC-43 checked value only from the appropriate harness-
composed job. `STA-24` says a job record “cannot clear a cloud-plane barrier”.
Service liveness is the declaration's question; command exit is not its answer.

Model-written checks remain reports. [ARC-39](../01-architecture.md#what-a-session-delivers)
says “Neither success nor failure counts toward Delivered, creates or clears a
finding, or blocks delivery or secret placement.” `ARC-43` says checked values
come “never from model text”. The [declaration format](design/delivery-declaration-v1.md#shape)
separates proposed typed values from the signed-bundle measuring procedures.
Coverage: Dispatch carries selected command classification/settlement; actual
job truth, output protection, delivery authority and report-only treatment remain
prose/implementation obligations, not proven by the command witnesses.

### Host-key publications

[CHN-R7](../02-channel.md#the-routes-to-a-fingerprint) owns complete/fresh/contained
publication history and installed-pin admission. Its source is the recorded vendor
status direct fetch over browser-terminated TLS; `CHN-R7` says “This is a
vendor-published observation, not an attestation.” [STG-21a's reinstall predicate](../06-first-stage.md#the-stages)
needs its prior complete baseline plus post-dispatch publication/status contract.
An empty prior installation group can admit a pin without confirming reinstall;
the independent cloud barrier still applies. A publication supplies no general
operation confirmation, session authority or service evidence. Rescue publication
and attest retain [CHN-R1/R5's](../02-channel.md#the-routes-to-a-fingerprint)
separate producers, boot/sender identity and acceptance boundaries. Pins carries
symbolic admission/history; vendor/address-scan truth and integrated absence of
contact remain outside that property.

### Boot and service observations

`STA-20` says “a PID from another boot cannot establish liveness”. Ordinary
changed-boot evidence establishes old-command end, not successful effects.
The separate non-LNVPS `delivery_reboot` has ARC-43's own-job/own-machine/new-boot
terminal exception; `ARC-43` says it “claims the observed boot change, never an
exit status or a cause.” The same reboot bytes through `exec` remain an ordinary
command. This exception grants no LNVPS restart confirmation.

For delivery, use [ARC-43's evidence clauses](../01-architecture.md#box-plane-execution-is-command-granular)
and [ARC-17's placing-session demonstration](../01-architecture.md#what-a-session-delivers):

| Observation or local condition | Owner's evidence treatment | Independent boundary |
|---|---|---|
| Enablement read without demonstrated reboot | ARC-43's **“enabled, restart not demonstrated”**, beside Delivered if other checks pass; no lifecycle finding from that label | No claim of survival; re-entry/re-check follows its evidence clause |
| New guest boot plus active unit after the approved reboot | ARC-43's survival evidence, followed by the delivery check | Not the cloud restart's confirmation or the durable final verdict |
| `running-at-delivery` found running | ARC-43 journals that boot with the result, anchoring the promise there | Stopped on that boot is a lifecycle finding; boot change does not clear a standing finding |
| Stopped after a changed boot, previously running there | ARC-43's **“stopped since a restart, as approved”** under its stated conditions | The note is not a placing session's post-placement demonstration |
| Failed/held/refused/no-record check | ARC-43's finding for an actual read with unexpected status/missing binary, versus no settlement for held/refused/no record | No fabricated pass; stopped pending check supplies no verdict |
| Lifecycle finding versus another finding | ARC-17's lifecycle placement exception, fixed lockdown prerequisites and re-check | Placement permission is not placement, placement clears no finding, and delivery needs the demonstration |

`ARC-43` says “That labelled state is no difference from the declaration, raises
no lifecycle finding, and leaves the machine Delivered when its checks otherwise
pass.” For `running-at-delivery` it says “A boot change never clears a standing
lifecycle finding”. `ARC-17` says “A finding is cleared by a re-check and by
nothing else” and “placement itself clears no finding.” Re-arm is a local scan
reference boundary; [ARC-43](../01-architecture.md#box-plane-execution-is-command-granular)
labels a machine-derived reference **“re-armed from the machine's report”** and
says “It covers no forgotten placement.” It is no restored-state reapproval,
original-value proof or rotation. Coverage: these lifecycle/placement/re-arm
boundaries are prose-only, distinct from Declaration's coarse field predicates
and Dispatch's dedicated-reboot terminal property.

### Notifications

Applicability: notify/attest routes; stage-1 LNVPS uses no notify channel.
[CHN-17](../02-channel.md#the-attest-sequence) says “a machine may send the harness
an event, and an event is an observation.” Its ordinary events “never gates a
step, never triggers an action”, with the single attest introduction exception
owned by [CHN-R5](../02-channel.md#the-routes-to-a-fingerprint) /
[CHN-5](../02-channel.md#the-attest-sequence). That exception gates
the awaited first contact for the planted sender and single-use browser acceptance,
not command completion or delivery. Candidate notification uses in CHN-17 are
not adopted sources. The relay companion's historical profile is not a proof of
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
