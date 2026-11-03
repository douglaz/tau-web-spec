# Atlas source-finding record — 2026-11-03

Informational exercise record, not a requirement registry. Entry point:
[state-machine atlas](../state-machine-atlas.md). Source baseline:
`674a7c6b8a4671fc2bc2e2e20855b084a69837ba`; the starting `4095db7` adds only the
tracker claim. [Implementation handoff](../design/atlas-implementation-handoff.md)
names the immutable fixture contract and runtime evidence still owed.

## Exercise result

Independent source-finding reads started from the atlas and answered every
question below before reconciliation. Quotations were then checked independently
against the owning clauses. Raw prompts, identities, responses and availability
logs remain outside version control. Agreement records a reading of these sources,
not conformance or resolution of an open semantic question.

The completed independent answers were reconciled question by question against
these owners. The pending-check question required a further source chain: ARC-43's
box-plane-work classification and CNF-53's explicit model-request case, recorded
in answer 3 below. The final reconciled answers and dispositions retain the specific uncertainty
below; successful reader exits alone supply no agreement evidence.

## 1. Fresh identifiers and unresolved operations

Atlas route: [Cloud and reconciliation](../state-machine-atlas.md#cloud-and-reconciliation),
[Cloud barrier](../state-machine-atlas.md#cloud-barrier),
[Allocation and recovery](../state-machine-atlas.md#allocation-and-recovery).

Verified answer: fresh naming or session admission supplies no escape from a
retained resource barrier. The owning [STA-24, resource paragraph](../../03-state-and-recovery.md#durable-state)
says “The unresolved barrier holds per resource, not per call.” It also says
“a second attempt at the same entry sits behind the same barrier even if it would
reserve another index”. Its opening paragraph says “including a session that
re-enters or succeeds the one that raised it”. [STA-8](../../03-state-and-recovery.md#durable-state)
says “It MUST NOT be retried automatically and no timer may clear it.”
A different approved entry meets its own approval and the identity-exclusion
checks in [protected evidence §3a](../design/protected-evidence-v1.md#identity-and-confirmation-boundary),
under STA-24's own independent-entry paragraph.

The inference request is the explicit exception: `STA-24`, *What stays permitted*,
says “The inference request (`ARC-31a`) keeps its unresolved intent” and
“does **not** bar the next request”. It retains unaccounted spend against the
session key's cap; conditional inference admission remains with
[ARC-31a](../../01-architecture.md#money). This exception supplies no fresh-call,
session or index escape from an unresolved cloud mutation.
Imported knowledge is different from allocation authority:
[STA-22b, import paragraph](../../03-state-and-recovery.md#what-survives-a-lost-phone)
says “every imported seed may restore listed identities but MUST NOT allocate
new ones”. [SEC-1, binding paragraph](../../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock)
says “Binding is an operator act in the browser, made before any channel access
to that machine.” [SEC-4, approved record](../../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved)
says “The adapter executes the structured facts as they were approved and journaled”.
Neither import nor a new session manufactures that authority.

Evidence boundary: authoritative prose except STA-24's separately rendered receipt
mapping. The [Dispatch fresh-call pair](../state-machine-atlas.md#same-action-new-call-id-refused)
is bounded, has no explicit crash/lost-response event, and changes `resourceKey`.
`TauWeb.Dispatch.replay_same_unresolved` is a general statement with
`durableBeforeApply=true` and initial memory equal to journal; it preserves the
unresolved view across replay, not remote outcomes. The general dispatch-admission
theorem `TauWeb.Dispatch.dispatched_only_if` assumes `durableBeforeApply=true`
and an intent newly dispatched by the request step, absent from the prior
dispatched list. It concludes journaled intent, matching approval/session/facts
and no blockers under its parameters; the standing-disposition conclusions are
conditional on `dispositionBindsContinuation=true`, with permission conditional
on reach. It is parametric in `resourceKey`; the per-entry choice is exposed by the
named guard pair and bounded check, not a new unconditional per-entry theorem.
The Allocation pair compares
an imported-seed restriction; `TauWeb.Allocation.issued_nodup` quantifies over
traces from `init` with `restoredAllocatesNone=true`. No runtime send/storage,
cryptographic binding or imported-sheet construction result is supplied.

## 2. Dead command without terminal outcome

Atlas route: [Commands](../state-machine-atlas.md#commands),
[Job-record collection](../state-machine-atlas.md#job-record-collection),
[Operator disposition](../state-machine-atlas.md#operator-disposition).

Verified answer: proof of death alone does not release the hold.
[STA-20, tracked job and unresolved-command paragraphs](../../03-state-and-recovery.md#durable-state)
says “A record with no exit code and a proven-ended command means it died;
the call stays unresolved” and “Only a terminal record releases the hold”. The
same paragraph identifies the finished-record, dedicated `delivery_reboot`
boot-change and disposition cases. [STA-24, What clears it](../../03-state-and-recovery.md#durable-state)
says “A disposition is a terminal record of its own kind” and “A disposition
keeps the outcome *unknown*”. Its continuation still matters; `STA-24` says
“A destructive continuation stops every box-plane job”.

Rescue persistence and planned reset route to
[STA-20b](../../03-state-and-recovery.md#durable-state), rather than being inferred
from installed-system persistence. Protected terminal representation routes to
[protected evidence §2](../design/protected-evidence-v1.md#2-job-schema-and-replay):
it distinguishes an authenticated present-but-withheld exit from genuine absence;
`ended` is not `finished`. Operation settlement and targeting retain
[§3a](../design/protected-evidence-v1.md#identity-and-confirmation-boundary).
Decision history: [ADR-0048](../adr/0048-an-unresolved-command-holds-its-machine.md),
[ADR-0050](../adr/0050-destructive-dispositions-stop-every-box-plane-job.md).

Evidence boundary: authoritative prose and representation; the
[command pair and collection history](../state-machine-atlas.md#second-command-held)
are bounded knowledge witnesses. No selected named witness demonstrates an ended
ordinary command with genuinely absent exit evidence. Dispatch's symbolic settlement
definition and the owner prose retain that distinction; these samples do not
supply a dedicated named test for it. Dispatch assumes single-writer serialization;
waits, stopped waits, privileged collection, runner liveness and flow resumption
remain prose/runtime obligations. No process or service liveness was observed.

## 3. Reads under overlapping restrictions

Atlas route: [Combined matrix](../state-machine-atlas.md#combined-matrix),
[Pending check, scanning and identity overlaps](../state-machine-atlas.md#pending-check-scanning-and-identity-overlaps),
[Admission ordering and replay](../state-machine-atlas.md#admission-ordering-and-replay).
The matrix remains pointer-only; this exercise follows its owners.

Verified distinctions:

- Adapter reconciliation and existing-record collection:
  [STA-24, What stays permitted](../../03-state-and-recovery.md#durable-state)
  says “Reads naming the resource — the adapter's status queries, the pinned
  SSH attempt that is `STG-4`'s third predicate, the collection of job records —
  are permitted”. This is permission through that restriction, not universal
  authority to contact, send or publish.
- Ordinary `exec` and harness jobs:
  [STA-20, unresolved-command hold](../../03-state-and-recovery.md#durable-state)
  says “a read through `exec` is a command, and a job the harness composes is held
  too”. Under the machine's destructive disposition, `STA-24` says
  “the harness worker MUST refuse every box-plane job to that machine”.
  The same *A destructive continuation stops every box-plane job* paragraph
  explicitly says “Reads stay permitted throughout, the pinned SSH attempt that
  is `STG-4`'s third predicate and the collection of job records among them”.
  This is permission through the destructive restriction; all independent
  authority, pin, custody and output restrictions still apply. Collection of
  existing records is distinct from issuing a new read job, which remains a
  box-plane job under the refusal above.
- Actual collection: `STA-20` says “Collection bypasses no host-pin or authority
  check, protected-evidence handling or other existing restriction”. It also says
  “arbitrary repair, payload execution or a model-supplied command MUST NOT be
  relabeled as collection”. A connection remains subject to
  [SEC-11](../../04-security-model.md#sec-11--the-host-key-is-checked):
  “An SSH session MUST check the host key against the stored fingerprint”.
- Pending delivery checking:
  [ARC-43, Evidence for enabled-survives-reboot](../../01-architecture.md#box-plane-execution-is-command-granular)
  says “holds the model's box-plane commands to that machine as `STA-20`'s hold
  does”. Its box-plane-work paragraph calls `fetch_artifact` and
  `ready_to_reset` “**box-plane work**” that runs “like any `exec`”.
  [CNF-53, survival-evidence cases](../../07-conformance.md#the-deliverable--arc-17-arc-39)
  says “a model box-plane request after the yes journaled with the reboot's intent
  and before the delivery check's verdict, including after the reboot settled,
  is held”. Together these sources cover a model-requested harness job, as well
  as ordinary model `exec`. They do not establish a universal hold on every
  harness-initiated job: the check's own necessary reads have their separate
  authorization and still meet other restrictions. For model-requested
  `place_secret`, [STA-20, tracked-input paragraph](../../03-state-and-recovery.md#durable-state)
  says it “is recorded by its command like any other”; CNF-53's model box-plane
  request case covers that job too. ARC-43 retains its distinct argument and
  per-placement approval rules. ARC-43 says “A stop settles
  no verdict and is shown as a stopped check, never as a pass.” Ending the cloud
  restart barrier does not end this separate check.
- Scan readiness/release: [ARC-43, re-arm paragraphs](../../01-architecture.md#box-plane-execution-is-command-granular)
  says “Model `exec` across the bound set MUST wait while any known required
  placement reference is unarmed” and “Only harness jobs whose output goes to
  **neither** model nor transcript are exempt”. It says those delivery reads
  “release their verdict and findings, never their raw output”.
  [SEC-5](../../04-security-model.md#sec-5--the-credential-inventory) says
  “Unscanned bytes MUST be withheld”. An exempt scan-read job still meets the
  independent command/destructive stops.
- Identity exclusions: `STA-24` says “reads, dispositions and operations through
  already admitted mappings are unaffected”. The exact-target subsection of
  [protected evidence §3a](../design/protected-evidence-v1.md#independent-recovery-and-exact-targeting)
  says “A withheld ID, quarantine, marker, receipt or association number, or
  independently generated handle resolves nothing.” No read exception invents
  a usable target.
- Untyped scope: `STA-24` says “nothing under a scope counts as a read, because
  nothing types it”. Its open/unresolved-call pause names “a box-plane command
  to any machine of the session's bound set at that vendor”; its destructive-hold
  paragraph names “the model's box-plane commands”. The harness-started-job
  seam remains visibly owned by [tw-pgp](../../.beads/issues.jsonl). The
  open/unresolved-call pause and the standing destructive hold are distinct
  paragraphs. Existing-record collection is not a newly issued command under
  STA-20: “Collecting a job record is not held”. That exception to the command
  hold does not type a scope call as a read or waive another restriction.
  The stage-2 harness-started-job boundary remains with tw-pgp; token-rotation
  and scope-succession questions route to [TASKS.md T47](../../TASKS.md#open),
  which lists “the hold across a re-approved scope or a rotated token”. Recorded
  decision comments do not amend the current normative paragraphs.
  STA-24's untyped pause is inside *What stays permitted*, whose opening sentence
  permits “Reads naming the resource” and explicitly includes “the collection of
  job records”, as quoted above. Whether that resource-naming permission reaches
  existing-record collection under the untyped pause remains a stage-2 question
  at STA-24/tw-pgp. STA-20's availability language and its “other existing
  restriction” qualification do not by themselves settle that overlap. Neither
  an all-job hold nor a read exception is extended by analogy.
- Publication: [STA-23](../../03-state-and-recovery.md#what-survives-a-lost-phone) says
  “A stale message or late result MUST NOT revive ended authority or publish an
  actionable result under stale authority.” A read's allowed send establishes
  neither a verdict nor permission to release protected output.

Evidence boundary: owner prose and selected symbolic Dispatch/Authority checks;
pending-check, untyped-scope and complete protected-output composition are not
proved by juxtaposing module traces. Clearing one restriction leaves the other
owners applicable. No universal first-refusal order is specified here. The
stage-2 destruction/output seam remains [tw-pkn](../../.beads/issues.jsonl).

## 4. Ordinary hide, suspension and actual end

Atlas route: [Sessions and approvals](../state-machine-atlas.md#sessions-and-approvals),
[Processed suspension and validated continuation](../state-machine-atlas.md#processed-suspension-and-validated-continuation),
[Processed-authority composition](../state-machine-atlas.md#processed-authority-composition).

Verified answer: ordinary hide preserves authority; processed interruption needs
current per-work validation; actual end cannot be undone by return.
[STA-23, local lifecycle paragraphs](../../03-state-and-recovery.md#what-survives-a-lost-phone)
says “An ordinary visibility-only hide MUST NOT end or pause an unlocked session,
clear its runtime authority, or invalidate its approvals.” It says “Before further
ordinary sends or actionable result publication after a processed suspension or
interruption, the surviving worker MUST validate its current authority, bindings,
holds, connection state and scan readiness.” Its safe-continuation paragraph says
“The worker MUST admit only an identifiable safe unsent continuation”. Validation
is not a successful reconciliation or new dispatch approval.

`STA-23` says “Explicit app Lock, pagehide including entry to the back-forward
cache, reload, or worker shutdown MUST stop dispatch, end session workers and
close channels” and “During the seed-backup ceremony an ordinary hide MUST take
this full Lock path too”. Its ceremony paragraphs leave interrupted completion
owed and never re-display words automatically. Its writer paragraph says
“missing heartbeat or a timeout is not confirmed predecessor termination.”
The distinction from a physical freeze is explicit: `STA-23` says “no
instantaneous fence at the physical app switch or physical resumption is claimed”.

The [SEC-1 binding owner](../../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock)
and [SEC-4 approval owner](../../04-security-model.md#sec-4--how-cloud-plane-actions-are-approved)
and conditional [ARC-31a](../../01-architecture.md#money) remain applicable.
`STA-23` says “No procured-key expiry is imputed to bring-your-own or local paths.”
Durable history cannot revive ended approvals or runtime credentials.

Evidence boundary: no rendering region covers these lifecycle clauses. General
`TauWeb.Authority.hide_identity` needs `hidePreserves=true`,
`preserveKnowledge=true`, ceremony false and a processed hide.
`TauWeb.Authority.lifecycle_knowledge` needs `preserveKnowledge=true` and leaves
Dispatch knowledge unchanged. The fence and refinement theorem premises are
[spelled out in the handoff](../design/atlas-implementation-handoff.md#per-step-comparison-surfaces).
Named Authority histories have a finite length cap, not exhaustive event coverage.
They assume stopped predecessors, writer/store custody and current readiness;
they establish no reliable cleanup, physical erasure, actual scheduling or
pre-send/post-await implementation fence. Browser and physical Android evidence
remains owed under [CNF-82](../../07-conformance.md#additional-contracts-from-the-september-9-review),
with [CNF-29](../../07-conformance.md#approval-and-recording--sec-4-sec-12) and
[CNF-40](../../07-conformance.md#state-and-recovery--sta-) and the applicable
[dedicated approval cases](../../07-conformance.md#stage-applicability-and-admission).

## 5. Restart, boot, reports and Delivered

Atlas route: [Vendor receipts and status reads](../state-machine-atlas.md#vendor-receipts-and-status-reads),
[Boot and service observations](../state-machine-atlas.md#boot-and-service-observations),
[Delivery publication, placement and re-check](../state-machine-atlas.md#delivery-publication-placement-and-re-check).

Verified answer: none of receipt, boot change or model-written success alone
establishes Delivered. [STG-21a, Restart](../../06-first-stage.md#the-stages)
says “It does not establish a completed guest boot or service survival.”
[ARC-43, reboot evidence](../../01-architecture.md#box-plane-execution-is-command-granular)
says “New boot identity plus active unit is the init-agnostic survival evidence.”
Its pending-check paragraph ends at a durably journaled verdict or journaled stop,
not a vendor receipt. [ARC-17, Delivered paragraph](../../01-architecture.md#what-a-session-delivers)
says “A finding is cleared by a re-check and by nothing else”.
[ARC-39, proposed declaration paragraph](../../01-architecture.md#what-a-session-delivers)
says “Neither success nor failure counts toward Delivered, creates or clears a
finding, or blocks delivery or secret placement.” That sentence concerns
model-composed checks, not the harness-composed check. `ARC-17` says “placement
itself clears no finding”. [SEC-5](../../04-security-model.md#sec-5--the-credential-inventory)
continues to govern secret handling.

Demonstrated reboot is not a universal prerequisite for Delivered. ARC-43 says
“No reboot is offered when no such service is declared or a `running-at-delivery`
service is also declared”. For the otherwise-passing undemonstrated case, it says
the label “enabled, restart not demonstrated” “leaves the machine Delivered when
its checks otherwise pass”. The label and offer conditions retain their owner;
a boot change still clears no standing lifecycle finding by itself.

Evidence boundary: the restart receipt is an operation-limited bounded Dispatch
history. The Declaration witnesses check fields and opaque set differences,
not actual service survival or pending-check composition. The atlas restart
story is explicitly illustrative prose. Existing runtime owners are
[CNF-50/53/107/108](../../07-conformance.md#the-deliverable--arc-17-arc-39) and
[CNF-112](../../07-conformance.md#approval-and-recording--sec-4-sec-12), under their
stage rows: LNVPS typed restart is stage 1; `delivery_reboot` remains dedicated;
the scanner half remains conditional on scanner enablement. No new delivery suite
or stage promotion follows from this exercise.

## 6. Restore: knowledge versus authority

Atlas route: [Allocation and recovery](../state-machine-atlas.md#allocation-and-recovery),
[Allocation traces](../state-machine-atlas.md#allocation-traces),
[Open owners](../state-machine-atlas.md#open-owners-and-deliberate-boundaries).

Verified answer: identity/history survive to the extent present in the imported
artifact; live authority and fresh allocation do not arise from that history.
[STA-16, restored sheet paragraphs](../../03-state-and-recovery.md#recovery-by-access-model-and-vendor)
says “A restored sheet is knowledge as of export” and “after store loss each
maintained machine is shown as **unchecked**, its findings unknown, until a
re-check runs”. Its installation paragraph says “An active pin remains usable
under its recorded route; a retired pin admits no new contact.” Restored
`lnvps_retrieve` admission still needs its direct current-set comparison;
application/provider facts and approved machine state retain their distinct labels
and reapproval treatment there. The versioned payload/association owner is
[credential format, Recovery sheet](../design/credential-format-v1.md#recovery-sheet).
`STA-22b` says “every imported seed may restore listed identities but MUST NOT
allocate new ones”. [STA-17, Restore bullet](../../03-state-and-recovery.md#recovery-by-access-model-and-vendor)
says “explicitly presented as non-revoking”. Restore does not revoke a lost phone.

Complete journal loss and stale local-store backup are different:
[STA-24, Lost journal and stale backup](../../03-state-and-recovery.md#durable-state)
says “recovery alone settles no retained unresolved intent, clears no retained
resource barrier or command hold, erases no standing disposition and authorizes
no automatic retry”. [STA-20, journal-only paragraph](../../03-state-and-recovery.md#durable-state)
says “may therefore overlap that earlier command while it still runs” about
sends omitted from restored journal knowledge, without a new recovery enumeration
or wait. This accepted limitation supplies no remote concurrency safety.

For new authority, [SEC-1](../../04-security-model.md#sec-1--a-session-reaches-only-its-bound-set-enforced-by-a-lock)
says “connecting is never what creates a binding”. [STA-23](../../03-state-and-recovery.md#what-survives-a-lost-phone)
says “Individual session end destroys that session's runtime authority and pending
approvals; it does not revive on return.” Fresh binding, live approval and current
admission checks are separate from historical approved machine state. Scan re-arm
is separate again: [ARC-43](../../01-architecture.md#box-plane-execution-is-command-granular)
says “Re-arming neither reapproves the restored declaration nor any weaker mode”.

Evidence boundary: the Allocation traces establish only symbolic allocation
knowledge, not sheet import, credential safety, remote command completeness or
recovery success. Current journal-only rules and LNVPS privileged collection have
landed; they are not old unresolved questions. The
[recovery row](../../07-conformance.md#stage-applicability-and-admission) owns
[CNF-19/20](../../07-conformance.md#credentials--sec-5),
[CNF-84](../../07-conformance.md#additional-contracts-from-the-september-9-review) and
[CNF-115](../../07-conformance.md#state-and-recovery--sta-).
[CNF-95](../../07-conformance.md#credentials--sec-5) and
[CNF-109](../../07-conformance.md#the-channel--sec-11-chn-) are in the stage-1
required row, with their stated qualifications: CNF-95 cases (e)/(f)'s A/B output-release assertions and case (e)'s copied-key
assertions remain stage 2, while CNF-109's new job-read and attest admission cases keep their
separate route rows. These existing items retain runtime
ownership. [STA-14, LNVPS qualification](../../03-state-and-recovery.md#what-survives-a-lost-phone)
says “not an available LNVPS Restore”. T44 still owes the coordinated credential
format/recovery implementation before stage-1 completion; a decided direction
is not an operative vendor-identity role. Sheetless cloud destructive authorization remains with
[tw-yhd](../../.beads/issues.jsonl): “Cloud destroys and recreates” in STA-22b's
no-sheet paragraph must be read beside SEC-4's “displayed and never relied on”
listing and binding rules. A listing of a sheetless machine supplies no approved
entry; this record preserves the conflict without authorizing destruction.
Robot rescue relabel and installation questions retain
[tw-lq8/tw-l1l](../../.beads/issues.jsonl).

## 7. Historical relay boundary

Atlas route: [Historical Relay boundary](../state-machine-atlas.md#historical-relay-boundary).

Verified answer: the profile is historical `relay-protocol-v1.md` / `/v1/`, with
[Relay schema 1](../design/witness-file-v1.md#relay) and
[its witness file](../design/relay-witnesses-v1.json).
[CHN-15](../../02-channel.md#the-relay)
says “Those declarations and `relay-witnesses-v1.json` do not certify the `/v2/`
additions.” It also says “The selected wire profile is `/v2/`; `/v1/` and the
historical companion remain explicitly scoped to v1.”
[Relay.lean's opening scope](../../tools/formal/TauWeb/Relay.lean)
excludes `/v2/` connection binding, termination and discovery; the atlas also
marks current migration outside its claim. The current shared wire source and
consumer adoption stay with CHN-15/19, not the historical examples.
The **open** [TASKS.md T30](../../TASKS.md#open-t30-relay-port) owns the port:
“The module, its witness file” and “the controls that read them move when that set
grows a formal layer”. This is a conditional move to paid-tcp-relay, not a claim
that current `/v2/` formalization already exists or a new definition of that task.
The completed T30 lower in that file is the earlier scaffold and cannot close
this work. Relay.lean also excludes purchase/revocation messages, retries and
refreshed DNS results, and abstracts bytes, signatures and timing. These omissions
remain locally visible alongside the current CHN-15/19 consumer contract.

Evidence boundary: the historical theorem signatures quantify over symbolic
traces with resolver/address-table assumptions. Ordinal challenges, verifier
answers and abstract text shapes are not wire bytes, signatures, timers or real
transport. No Relay trace is generated into the atlas and no current relay
composition follows from independent Pins/Dispatch views. Current route
admission still follows [the stage table](../../07-conformance.md#stage-applicability-and-admission).

## Findings and dispositions

| Finding | Disposition and retained owner |
|---|---|
| STA-23 destinations landed at Durable state; the migration pointer for STA-17 landed in the lost-phone section | Corrected only the exercise atlas and handoff/record routes to their actual owning sections. Mixed binding/approval and conformance links split where their owners differ. No corpus-wide anchor redesign. |
| T30 named both an open relay port and a completed scaffold task | Added a task-local anchor to the open entry and linked exercise routes to it. The port's conditional move remains as written. |
| Pending-check model-requested harness-job coverage was questioned | Reconciled against ARC-43's work classification, survival-evidence paragraph and CNF-53's explicit model box-plane request case in answer 3. No exemption or universal harness-job hold added. |
| Untyped pause, collection and standing hold risked conflation | Preserved STA-20's collection/new-command distinction and STA-24's scope-call/pause/hold paragraphs. Collection under the untyped pause is not explicitly settled; stage-2 unresolved overlaps remain at STA-24/tw-pgp. Pending decisions are not amendments. |
| Historical Relay source link differs from CHN-15's current shared revision | Kept the historical module/profile boundary explicit; made no inference of current coverage from either revision. Open T30 retains the module/witness/control move. |
| Coarse run-in subclauses, tracker-file links and Authority-scope search | Exact clause/paragraph names are recorded above, with existing section anchors and record IDs. The tracked declaration index and schema remain the inventories; no new normative registry or anchor framework. |
| Ended-command named sample and unconditional per-entry general theorem are absent from this selected evidence | Kept the actual symbolic premises and finite sample boundaries in answers 1–2. No theorem or fixture added. |
| Delivery offer conditions, marked-region authority and recovery-row membership needed more precise presentation | Added the no-universal-reboot qualification, pointed to the current marked-region definition, and separated the recovery row's items from stage-1 required items and their later-route cases. Owners and applicability are unchanged. |
| Recovery, scanning and later-route semantic/evidence work remains open | Existing atlas owners tw-yhd, tw-ae7, tw-lq8, tw-l1l, tw-pgp, tw-pkn and tw-z99 retain their recorded limits; T44, T47, OPN-27 and the conformance stage rows retain their work. No older journal-only or privilege question reopened. |
| Physical lifecycle, real storage/send order, transport and vendor evidence was not obtained in this exercise | Routed to the handoff's existing conformance owners. This exercise obtains no implementation evidence. |

The clarity evidence is navigation, checked quotations, deterministic bounded
projections and scoped general theorems. Targeted Authority assurance retains its
shared Dispatch seam, useful successful continuations and discriminating controls,
with the explicit hypotheses above. No runtime readiness, physical lifecycle,
transport, vendor behavior, cleanup or full-composition conclusion follows.
