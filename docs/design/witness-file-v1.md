# Witness files

The schemas of the files the formal companion emits, one per module, committed beside this
document as `<module>-witnesses-v<schema>.json` (ADR-0032, "How the implementation is compared" —
what a witness file carries, what it never carries, and how the implementation reads it are
decided there and not restated here). `lake exe witnesses` writes them from `tools/formal/`;
`tools/check_witnesses.py` checks emission equality and marked pair structure across the
emitted corpus under this schema and ADR-0032, and
`tools/check_fixtures.py` parses each as a document. Allocation uses schema 3 in
[`allocation-witnesses-v3.json`](./allocation-witnesses-v3.json) from `TauWeb.Allocation`:
the local unsent terminal proof, durable append and sender fence extend the ceremony schema 2.
Declaration and relay keep schema 1:
[`declaration-witnesses-v1.json`](./declaration-witnesses-v1.json) from `TauWeb.Declaration`,
[`relay-witnesses-v1.json`](./relay-witnesses-v1.json) from `TauWeb.Relay`. The dispatch
module uses schema 10 in [`dispatch-witnesses-v10.json`](./dispatch-witnesses-v10.json) from
`TauWeb.Dispatch`. Schema 10 adds `end_session` with `session` and `appended`, and the
`session_ends` knowledge list. Dispatch retains the assumption that an ended session sends no
request; its End record neither enforces request admission nor proves browser termination.
Schema 9 adds per-request deletion contact; see its section below. Schema 8 added canonical received-ID withholding, quarantined evidence,
retained-evidence conflict checks and the pre-send identity-exclusion guard/refusal
(see the schema-8 section below). Schema 7 added receipt bindings, received results and retained receipts
(see the schema-7 section below). Amended 2026-10-18: schema 6 adds `commandHold` and `rebootBootChange`,
the `delivery_reboot` operation, `collect_reboot` and the `reboot_results` projection.
Amended 2026-10-17: schema 5 adds the approval-bound activation,
earlier-installation offer comparison and reinstall-withdrawal guards, `withdraw_reinstall`,
its outcome and projection, and the `approval_activation` and `withdrawn_approval` refusals.
Schema 4 added the approved dedicated reinstall boundary and failed-prerequisite withholding
guards, `approve_reinstall`, and the journaled approval, prerequisite-command/result and
current-installation projections. The
installation boundary is computed from journaled dispatches, never supplied by an event.
Schema 3 added the session-destroy and per-installation reset-offer guards, and the key-set
ordinal on `reset_prereqs`. Schema 2 added refused
dispositions, the four continuations, the reinstall operation, assumptions, disposition and
standing projections, and the witness starting from a journal already written. The pins
module uses schema 7 in [`pins-witnesses-v7.json`](./pins-witnesses-v7.json) from `TauWeb.Pins`.
Schema 7 replaces schema 6: failed required verification append leaves knowledge unchanged,
without a separate failed-append stop field. The pending revalidation hold stands and the next
authorized read can still succeed. Schema 6 added Restore revalidation events, unresolved contact
holds and verification append outcomes, under `STA-16`. Schema 5 replaced schema 4: the
post-reinstall `ready_to_reset` freshness guard changes assumptions.
Schema 4 added installation groups, pin installation ordinals and compact observations.
Schema 3 added LNVPS publication and reinstall events, per-fingerprint sets and presented keys.
Schema 2 replaced schema 1 when attest and restart were added.
A consumer reads the witness schema at its exact specification pin. Moving that pin to a
new schema requires updating its reader and comparison together; this specification change
claims no downstream migration or implementation comparison.

## The file

One JSON object. The header is pretty-printed and every trace is one line, so a diff names
the trace that moved.

| Member | What it holds |
|---|---|
| `schema` | `3` for allocation and `5` for authority; `1` for declaration and relay; `10` for dispatch and `7` for pins. A change to any shape below is a new version and a new file name for that module. |
| `module` | The inventory name, lower-case: `allocation`, `declaration`, `relay`, `dispatch`, `pins` for the host-pin lifecycle, and `authority` for the separate processed-authority file ([Authority schema 5](#authority-schema-5)). |
| `namespace` | The Lean namespace the traces' declarations live in. |
| `bound` | `declaration`, the tagged `bound` the decided property and the emitter share, and its value rendered under the module's own members. Allocation (`TauWeb.Allocation.bound`): `events`, the number, and `alphabet`, the events the enumeration draws from, including the ceremony. Declaration (`TauWeb.Declaration.bound`): `base`, the declaration and machine every case starts from; `presences`, per field, what the field is swept through, `missing` written as that word since a list has no absent member; `observations`, what the machine is made to show for it; `tenancies`. Relay (`TauWeb.Relay.bound`): `events`, the number; `alphabet`; and `start`, the opened connection every trace of the enumeration runs from. Dispatch (`TauWeb.Dispatch.bound`): `events`, the number; `alphabet`; and `start`, the journal every trace runs from, which carries the harness's associations and nothing dispatched. Pins (`TauWeb.Pins.bound`): the same shape; `start` carries one earlier `/rescue/last` snapshot, plus the fixed `planted_senders` list defined below from that starting knowledge and the alphabet. |
| `witnesses` | The named traces, one per decided witness, in the order the module states them. |
| `enumeration` | The traces the module's decided property closed over. Allocation: every trace of at most `bound.events` events over `bound.alphabet` from the initial journal, shortest first (`TauWeb.Allocation.bounded_nodup`). Its reach includes three consecutive allocations after a ceremony, reallocation after `created`, `failed` or `export_sheet`, and allocation under epoch 0, 1 or 2 separately. A `destroyed` event between allocations is a no-op without a preceding `created`; reallocation after an actual destruction needs five events and remains in `TauWeb.Allocation.successful_trace`. Allocating under two epochs also needs five events (`seed_backup, allocate, replace, seed_backup, allocate`), outside this bound. The event list and trace count come from `bound.alphabet` and this emitted enumeration. The alphabet includes a durable full-reentry ceremony; skip and failed append are named witnesses. Declaration: one full check per case of the sweep, fields in the table's order, each field through each presence, observation and tenancy (`TauWeb.Declaration.bounded`). Relay: every trace of at most `bound.events` events over `bound.alphabet` from `bound.start`, shortest first (`TauWeb.Relay.bounded`). Dispatch: every trace of at most the bound over the alphabet from `bound.start`, shortest first, **filtered to distinct request call ids** (`TauWeb.Dispatch.bounded`). Pins: the same shape, from `bound.start` (`TauWeb.Pins.bounded`). |

Both arrays hold traces of one shape:

| Member | What it holds |
|---|---|
| `declarations` | The `TauWeb.*` theorems the trace came from, resolvable against the `lake exe gate` index. Every name the file carries — here, in `bound.declaration`, in `pair.with` — is one the emitter checked against the tags (`Witnesses.lean`). |
| `assumptions` | Each guard parameter of the module by name, with the value the trace runs under, and each hypothesis the module takes rather than owns. Allocation carries `restoredAllocatesNone`, `backupRecorded`, `unsentFailure`, `failureDurable` and `senderFence`; declaration has one, `emptyMeansPerField`; relay has one, `dialRequiresAuthAccepted`, beside `special`, `ownAddress` and `resolve` — the value `CHN-16a`'s pinned tables and the relay's resolver take for the trace, since the module quantifies over them. Dispatch carries `resourceKey`, `durableBeforeApply`, `endedBelowSucceeded`, `dispositionBindsContinuation`, `reach` (`disposed`, or one of the retained traps `resource`, `every_dispatch` and `still_unresolved`), `destructiveStops`, `lapse` (`continuation`, or `any_intent` or `first_operation`), `resetIntoRescueOnly`, `newestActivationRead`, `dispositionOwnResource`, `sessionDestroyRefused`, `resetOfferCurrentInstallation`, `approvedReinstallBoundary`, `failedPrerequisiteWithdraws`, `approvalResetRequiresRescue`, `resetOfferFreshKeys`, `reinstallWithdrawalEffective`, `commandHold`, `rebootBootChange`, `orderAssociation`, `identityExclusion`, `deletionContact` and `pendingCleared`. What the far side actually did is external state, which a witness never carries. Pins carries `sourceAdmitsPin`, `attestAuthorMatches`, `attestSingleUse`, `attestDurable`, `attestFirstContact`, `publishedComplete`, `publishedFresh`, `publishedWithin`, `reinstallRetiresPin`, `installedFirstContact`, `readyAfterReinstallFresh`, `restoreBeforeContact`, `restoreReadAuthorized`, `restoreSavedPin` and `restoreEvidenceDurable`, with symbolic sender associations, seal-author observations, atomic durable appends, open introduction windows and vendor-status observations as stated assumptions. |
| `pair` | Present on a refused-and-admitted pair: `side`, `refused` or `admitted`, and `with`, the other side's declaration. What the comparison expects of each side is ADR-0032's. |
| `start` | Each trace's complete starting projection. Allocation carries its journal; fresh-seed, exhaustion and retained-lineage starts are selected by the emitted trace. Declaration carries the `declaration`, `machine` and empty `record`. Relay carries `challenge`, parsed `destination`, its `classified` result, `pass` and opened `connection`. Dispatch carries `knowledge`: ordinary association starts, replayed-invalid-disposition starts and exact-contact mapping fixtures are distinguished by the trace itself. Pins carries `knowledge`, with each trace's named `planted_senders`, and `bound.start` supplies its enumeration start. |
| `steps` | One object per event, in order: `event`, the outcome members for that event kind, and the projection after the step — `journal` for allocation, `record` for declaration, `connection` for relay, `knowledge` for dispatch and for pins. |

<a id="authority-schema-2"></a>

## Authority schema 5

[`authority-witnesses-v5.json`](./authority-witnesses-v5.json) is the separate processed-authority
checking interpretation. Authority schema 5 embeds Dispatch schema 10, including the classified request and deletion/waiting projections. Schema 4 split irreversible session Ends from incarnation fences, added pause/resume and sealed-terminal withholding, and made ceremony entry a pause. The authority
file has the common header/trace envelope, an empty `enumeration`, and a `bound` naming
`TauWeb.Authority.witnessBound`: a checked length cap for named finite histories, not an
exhaustive alphabet. All identities and original key/origin/cap/expiry fields are symbolic
ordinals, never credentials or actual clock values.

Schema 4 makes ceremony completion explicit:
`finish_ceremony` carries `completion` (`full_reentry` or `skipped`), `same_seed`
(a validation hypothesis for full re-entry, null for skip), and `appended` (the admitted
durable-completion outcome). Invalid, inactive or failed-append completion supplies no
ordinary authority. This is no cryptographic or real storage-ordering proof.
Execution freshness checks incarnation names against current and retired executions; exact
worker/session lookup remains independently required. Freshness is checked rather than
assumed. Binding lifetime is
session-level and independent of execution fences. The additional pairs cover these checks,
resume authorization/unlock/validation, sticky lost-key state, owed ceremony completion,
ceremony entry while locked and binding growth while paused or locked. A successful `unlock`
stands for the local passphrase entry; ceremony entry from an already unlocked store has no
further passphrase event in this interpretation.
Arbitrary-state boundary traces carry their complete `start` projection: an already fenced
dormant actor still owns its binding, and an archived actor or a fresh execution identity
cannot erase a retained session End. These inputs do not claim to be histories reachable
from the strong initial state; the separate retirement regression and repeated-resume
progress traces exercise that transition history directly.

Schema 5 adds one guard, `sealUnlocked`: a `sealed_terminal` event processed while `locked`
records no terminal, so a resume after the next unlock still withholds the paid key unless a
seal is processed after that unlock and before resume. Event, knowledge and pair shapes are
unchanged from schema 4, and every schema-4 trace keeps its events and steps, with
`sealUnlocked` true. `locked_seal_refused` and `locked_seal_without_check` are the
refused/admitted pair, and `unlocked_seal_progress` processes the same seal after `unlock` and
before `resume` and keeps the key. A seal stands for a durably committed, validated terminal,
sealed under the data key, and a locked store does not hold that key: `STA-23` says "only a
passphrase-wrapped data key persists", and processed Lock MUST "clear working keys and
credential buffers, returning locked". As an input
convention, this interpretation presents a terminal append begun before Lock after the next
unlock and before resume, however the append finishes; opening's staging recovery in
[protected evidence](./protected-evidence-v1.md) is one such route, and it completes only a
complete authentic staged record. It makes no storage-ordering claim.

The emitted vocabulary inventory below is regenerated by `tools/check_witnesses.py --write`
from the companion's emission and checked by the same gate. It enumerates shape only; the
owning requirements and the prose below retain their authority. No key material is emitted.

<!-- witness-vocabulary: authority -->
| Emitted inventory | Value |
|---|---|
| schema | `5` |
| events | `actionable_publication, assess_key, end_session, enter_ceremony, finish_ceremony, fresh_admission, grow_binding, hide, invalidate, ordinary_request, pause, received_record, replace_end, replay, resume, sealed_terminal, suspend, unlock, validate_continuation, visible` |
| knowledge | `actors, ceremony, ceremony_owed, dispatch, ended_sessions, fenced, issued, locked, published` |
| guards | `bindingSessionLifetime, ceremonyActive, ceremonyAppend, ceremonyCompletion, ceremonyHideLocks, ceremonyPending, ceremonyRelease, ceremonyUnlocked, endFence, exclusiveBinding, executionFresh, growthAvailable, growthExclusive, hidePreserves, individualOnly, lostKeySticky, machineMembership, pauseRequired, preserveKnowledge, procuredEligibility, publicationDispatch, publicationOrigin, requestOriginal, requestSession, resumeAuthorized, resumeTerminal, resumeUnlocked, resumeValidation, scopedExpiry, sealUnlocked, sealedTerminalRequired, unsentContinuation, validationMatches, validationRequired, validationTerminal, workerIdentity` |
<!-- /witness-vocabulary -->

Schema 2 adds the explicit `requestSession`, `machineMembership`, `growthExclusive` and
`requestOriginal` guard assumptions for isolated counterfactuals of existing checks. The event,
knowledge and pair shapes are unchanged from schema 1. Fresh-admission `exclusiveBinding`
also governs growth; `growthExclusive` bypasses only the growth-side check. `requestOriginal`
bypasses only the current evidence comparison in `keyEligible`, leaving assessment unchanged.

Each trace's assumptions carry the authority guards, nested Dispatch parameters and
explicit external hypotheses. A `work` names a worker/session/incarnation, request and approval;
it contains no resolved resource. A recorded issued origin additionally carries the resolved
resource returned by Dispatch. An actionable-publication event keeps this original call separate
from its proposed continuation and evidence. Only that continuation's evidence says `safe_unsent`.
The continuation call cannot already occur in the issued/dispatch history. Absence there supplies
no safe-unsent evidence by itself. The positive late-result histories use distinct continuation
calls; the marked issued-call counterfactual retains the unsafe reuse.
These booleans stand for current evidence under STA-23 and ARC-31a, not measured browser or
issuer behavior; both anchor and adjacent-pair discrepancy checks are present separately. False
means a fact has not been established, not proof of its negation. Established upper-bound equality
or passage beyond the original expiry is `expired`; established cap exhaustion is `exhausted`.
Those terminal assessments apply at validation as well as request/publication boundaries.

This schema explicitly extends ADR-0032's witness provenance vocabulary with
`processed lifecycle notification`, for already processed hide, visible, suspension and
non-operator global-end events, and `harness publication`, for the harness's actionable
publication attempt. These labels are symbolic inputs, not evidence that a browser notification
arrived or an adapter supplied a publication. Other events retain `operator act`, `model request`, `adapter observation`,
`disposition` or `replay`; current readiness/issuer facts remain abstract hypotheses even where
their provenance is `adapter observation`. This extension was introduced in authority schema 2 and is retained in schema 5.

Events distinguish processed `hide`, `visible`, `suspend`, invalidation, operation-specific
validation, individual/global End, pause (pagehide/bfcache, reload, shutdown and discard), resume,
sealed-terminal evidence, ceremony entry/completion, authorized unlock/fresh admission/binding growth, key assessment, ordinary request,
actionable publication, separately authorized received record, and replay. A received record
uses Dispatch's existing observation/receipt/reboot/disposition shape and carries authorization,
writer ownership and store access; it is not a new query send or a universal harness exemption.
The ordinary-request event alone carries its actual intent-append outcome.

Every step is evaluated by `TauWeb.Authority.step`. Its `knowledge` contains the existing
Dispatch knowledge projection plus actors/bindings, interruption revisions, particular validation,
key withholding, paused/committed-terminal/lost-key facts, irreversible incarnation fences
and ended-session identities, store/ceremony flags, issued origins and publications.
A request reports `authority_eligible`, actual new `sent` and, when delegated, the actual
`delegated_verdict`; absence of delegation assigns no cross-layer runtime refusal precedence.
A publication reports whether the publication list grew; recording reports whether the durable
journal changed. The file retains each strong/counterfactual pair whole, including positive
progress properties where the counterfactual wrongly refuses work. In authority pairs, `side:
"refused"` identifies the strong baseline that rejects the retained trap and `side: "admitted"`
identifies the counterfactual that admits the trap. These labels are not event outcomes:
`sent`, `published` and `delegated_verdict` carry those, including a strong baseline's required
progress and a counterfactual's unjustified refusal. It is not an implementation
comparison or evidence of scheduling, physical fencing, durability or issuer enforcement.

## Events

For the existing module schemas in the table below, each `event` has a `kind` and a
`provenance` from ADR-0032's closed vocabulary; the members beside them are the event's
arguments. Authority schema 5's explicit extension and event shapes are described above.
Additional allocation events and outcomes are defined in [Allocation schema 3](#allocation-schema-3);
additional deletion, opening and closure events are defined in [Dispatch schema 9](#dispatch-schema-9).

| `kind` | `provenance` | Arguments | Outcome members on the step |
|---|---|---|---|
| `allocate` | model request | `family` | `allocation`: `admitted` with `identity`, or `refused` |
| `created` | adapter observation | `identity` | — |
| `failed` | local writer decision | `identity`, `checked_sequence`, nested durable `append` | `terminalized` |
| `destroyed` | adapter observation | `identity` | — |
| `export_sheet` | operator act | — | — |
| `restore` | import or restore | — | — |
| `replace` | operator act | — | — |
| `seed_backup` | operator act | `completion`: `full_reentry` or `skipped`; `append` with provenance `storage outcome of an append` and `durable` | `recorded`: whether the append took effect |
| `check` | adapter observation | `field` | `verdict`: `refused`, `blocked`, `finding` or `pass` |
| `deliver` | model request | — | `delivered` |
| `auth` | operator act, or replay | `destination`, `key`, `event_kind`, `relay_tag`, `within_skew`, `signature_verifies`, `answers_challenge` | `auth`: `accepted`, `refused` or `ignored` |
| `dial` | adapter observation | `connected` | `dial`: `dialed` or `refused` |
| `app_frame` | operator act | — | `forwarded` |
| `request` | model request; operator act for `delivery_reboot` | `call`, `target`, `operation` (`create`, `reset`, `reinstall`, `destroy`, `activate`, `register_key`, `exec`, `delivery_reboot`, `read` or `inference`), `session`, `facts`, `read_route`, `connection`, `approved`, `appended` | `dispatch`: `dispatched` or `refused`, with `refusal` on the second |
| `read` | adapter observation | `source`, `resource`, `operation`, `reports`, `appended` | `settled`: the call ids the read took out of the barrier |
| `collect_reboot` | adapter observation | `call`, `resource`, `record_boot` (ordinal, or `null` for no recorded boot), `observed_boot` (ordinal), `appended` | `settled`: the call ids removed from the barrier |
| `dispose` | disposition | `resource`, `calls`, `continuation` (`destructive_reinstall`, `abandonment`, `as_if_done` or `as_if_not_done`), `appended` | `disposition`: `recorded`; `refused`, where it names no call, or names a call that is neither unresolved on the disposition's own resource nor one the standing disposition disposed; or `not_appended` |
| `associate` | operator act | `target`, `entry` | — |
| `approve_reinstall` | operator act | `entry`, `call`, `approved` session and facts, `appended` | — |
| `withdraw_reinstall` | operator act | `entry`, `call`, `approved` session and facts, `appended` | `withdrawal`: `recorded`, `refused` after that approval's reset was dispatched, or `not_appended` |
| `reset_prereqs` | adapter observation | `entry`, `keys` (opaque key-set ordinal), `appended` | `offer`: whether the planned reset into the installed system may be offered |
| `replay` | replay | — | — |
| `reset` | operator act | `entry`, `into` | `boot`: the rescue boot the harness counts for that entry after it |
| `rescue_last` | adapter observation | `source`, `entry`, `keys` (`null` while the field is empty) | `pinned`: whether the read journaled a pin |
| `ready_to_reset` | adapter observation | `source`, `entry`, `keys` | `pinned` |
| `attest` | adapter observation | `source`, `entry`, `per` (and `boot` for rescue), `keys`, observed `author`; nested `append` with provenance `storage outcome of an append` and `durable` | `pinned`; `consumed`: whether this entry's introduction is consumed after the step |
| `restore` | import or restore | `entry` | `verification_pending`, `retry_available` |
| `verify` | adapter observation | `entry`, `keys` (`null` for transport failure, `[]` for an empty publication), `authorized`, `append` (storage outcome of an append: `durable`) | `verification_pending`, `retry_available` |
| `published` | adapter observation | `source`, `entry`, `per` (and `boot` for a refused rescue-scope trap), `keys` | `pinned` |
| `reinstall` | operator act | `entry`; a destructive reinstall dispatched at the vendor reinstall call or the dedicated reset into rescue | `pending`: whether a new installed pin from any source is awaited |
| `restart` | crash | — | `replayed`: durable knowledge retained, session/handshake records dropped |
| `claim` | model request | `source`, `entry`, `per` (and `boot` with it), `keys` | `pinned` |
| `connect` | adapter observation | `entry`, `system`, `presents` | `check`: `admitted` or `halted`, with `halt` on the second |

An `auth` event's provenance is `replay` exactly when `answers_challenge` is `false`: a frame
that verifies and answers another connection's challenge is the replay. `ignored` is an AUTH the
connection did not take as step 2 — one arriving past it, or on a connection a path that does
not parse already closed. `dial` carries whether the TCP connection came up, which is the
adapter's answer and not the relay's decision; `refused` there is a dial the connection did not
make.

`allocate` carries the family and nothing a model would send beyond it: `STA-22b` decides the
index, not the request, so the request-to-entry mapping ADR-0032 has the comparison exercise
is dispatch's, not allocation's.

A `request` carries what a model sends and no resource: the harness resolves the `target` against
its own `associations`, and that resolution is what the comparison exercises. `appended` on an
event is the storage outcome of that event's own append — a driver instruction, like a lost
response, which the harness sees only as absence. A lost response has no event at all: nothing
settles the call, and it stays in the barrier. Whether a `read` clears anything is its `source`
and its `reports` together, and the step's `settled` is the answer; a read settles the calls that
were outstanding when it was taken, never one dispatched afterwards.

A `request` is labelled a model request and is a session's, except `delivery_reboot`, which
is labelled an operator act and represents the harness flow. The dispatch witnesses do not
model the delivery check's verdict or its pending-check hold: a model `exec` after a settled
`delivery_reboot` in a trace stands for one after the verdict, and an implementation compares
those steps on that reading. Under a standing abandonment
a session's destroy is refused; the paired trace without `sessionDestroyRefused` retains the
former admission as a trap, not a permission a comparison can infer. `ARC-21` runs abandonment
"never through a session"; the flow's destroy intent is read outside request admission by
`TauWeb.Dispatch.abandonment_ends_at_its_destroy_alone`.
Replay alone ends no session (`STA-23`); Dispatch assumes an ended session sends no request.
The durable End in the ended-approval trace records history under that assumption.
No named witness makes an ended-session request after a replay
it preceded. The bounded enumeration retains a superset of realizable traces, so its universal
property is stronger.
The file holds no trace in which a `register_key` is requested under a standing disposition: the journal holds nothing that says a
key registration is owed, and `TauWeb.Dispatch.reinstall_does_not_refuse_key_registration` is
decided over a trace that requests none. `destroy` stands for the destroy or the
stop that stands in for it, and `reinstall` for the vendor's own reinstall call (`ARC-22`). A
refused `dispose` changes nothing: the projection after it is the projection before it.

`approve_reinstall` carries the existing typed approval for one destructive reinstall's
reset into rescue, bound to that reset call, approved entry, session and facts. It neither
supplies nor moves the installation ordinal. The activation used at dispatch must have been
dispatched since that approval and its newest admissible durable read must still confirm it;
otherwise the approval-bound reset is refused at dispatch. A matching withdrawal since the
newest approval refuses that reset naming the withdrawal, even under a reinstall disposition,
when no unresolved call bars it (`STA-24`).
A disposition does not withdraw approval. A re-approval starts the activation check again.
An approval is usable only while its rendering session runs (`STG-20`); the companion assumes
ended sessions send no request and uses session binding for the successor refusal. Session
termination and the no-longer-usable display with no withdrawal offer remain Markdown-only.
An approval for a reset never dispatched cannot make another reset open an installation; a
second rescue reset needs its own approved reinstall to open another. `withdraw_reinstall`
records the named withdrawal except after that approval's reset was dispatched; that refusal
changes no projection. No matching approval or a repeated withdrawal withdraws nothing further.

`reset_prereqs` abstracts a `ready_to_reset` collection whose per-command record is already
durable before collection starts (`ARC-8`, `STA-4`). It appends that command record first and
then attempts the result append; `appended` here is the storage outcome of the **result**.
A failed result contributes no result record. The prior durable command record withholds
the offer across replay, for that entry and current installation, even when the failed read
would have repeated the pin. A later durable prerequisite read can restore it. This event
does not model command transmission or failure of the prior command-record append.

The `source` on the events that offer a pin is the admission source `ARC-43` decides by,
and it is why `claim` exists at all: a set named in model text has to be writable as an event to
be refused as one. A `reset` is one already dispatched — whether it may be is dispatch's, above —
and `connect` carries what the far sshd presented and never what the machine is running.

What is compared at a step is the projection after it. For allocation, an event the journal
cannot apply — `created` for an identity never reserved, `destroyed` for one never created,
or `restore` with no sheet exported (the bare-seed refusal) — leaves it as it was. The
enumeration holds these cases because the alphabet is closed under order. A ceremony whose
append fails also leaves the journal unchanged, but appears only in the named witnesses.
Whether the core refuses, ignores or flags the event is its own
business; its journal after the step is what must match, so a refusal that changes nothing
is not a mismatch.

## The projection

### Allocation

`journal`, `start` and every `identity` are harness knowledge in `STA-22b`'s vocabulary and
never the complete companion state layout. The exported sheet, fresh entropy counter and
ever-issued list stay internal. Pending sender identities and the per-step send boolean expose
only the local boundary outcomes described in Allocation schema 3 below.

| Member | Meaning |
|---|---|
| `seed` | The ordinal of the seed in the trace: `0` the initial seed, each Replace the next. Never a seed identifier and never key material. |
| `derivation_version` | The credential format's derivation version, `1`. |
| `family` | `machines`, `passes` or `handoffs`. |
| `index` | The family's index. |
| `next_unused` | The next unused index per family, the three families as members. |
| `entries` | The allocated entries oldest first, each an identity with `status`: `reserved`, `created`, `failed` or `destroyed`; the last two are `STA-22b`'s tombstones. |
| `seed_backup` | `"none"`, `"full_reentry"` or `"skipped"`, the ceremony record for the journal's current seed ordinal. Export copies it, Restore restores it, Replace clears it; neither completion is a verified backup. |
| `restored_from_import` | Whether the seed was imported from any sheet or store backup and no Replace has happened since — the state the restored-seed guard reads. |
| Schema-3 additions | See [Allocation schema 3](#allocation-schema-3) for the local proof/history and retained mapping members. |

### Declaration

`declaration`, `machine` and `record` are the delivery check's inputs and its knowledge in
`delivery-declaration-v1.md`'s vocabulary. Items are opaque: a declared listener, service, key,
drift check, required check or default credential is an integer, and what the machine shows for
a field is a list of the same integers, so the comparison exercises presence and the set
difference each row names and nothing about ports, lifecycles or commands. An implementation
maps each integer to one concrete record of the field's shape and one observed fact.

| Member | Meaning |
|---|---|
| `declaration` | Keyed by the table's field names, dotted. A value is the field's value, `"unspecified"`, or the member absent — `missing`, rendered as the document defines it, so that a reader meets it as absent and not as `unspecified`. `"none"` for `default_credentials` is written as the table does and means the empty list of what must have been changed. |
| `machine` | `multi_tenant` (`ARC-36`), and `observed`: per field, what the machine shows — the sockets answering, the restrictions in place, the services demonstrated, the spendable material found, the tenant material found, the required checks that hold, the credentials changed. `drift_checks` is the maintained re-check's (`ARC-26`) and delivery reads only its presence. |
| `record` | `verdicts`, per field checked so far; `delivered`, whether delivery was reached. `refused` is the declaration's own fault (a field absent, a wrong shape, a version other than 2, spendable declared on a multi-tenant machine); `blocked` is `unspecified`; `finding` is a difference from the declaration. |

### Relay

`connection` is the WebSocket as `relay-protocol-v1.md` names it, and never the companion's
state. What it omits is what a witness may not carry: the challenge's bytes, the signature, the
key's material and `relay.auth_skew` — a challenge is an ordinal, a key is an ordinal, and
whether a frame is signed, fresh and answering this connection's challenge is the verifier's
answer rather than a value. An address is a `family` and an opaque `value`; an implementation
maps each to one concrete address of that family, and a DNS name likewise.

| Member | Meaning |
|---|---|
| `destination` | The `host` — an `address` or a `name` — and the `port`, after the parse and the normalization. Absent as `null` for a path that does not parse, which closes the connection before any check. |
| `classified` | The address the destination pipeline admitted, or `null` where `CHN-16a` refused it or a name answered with a forbidden address. It is the only address the dialer is handed, and it is decided once, when the connection opens. |
| `pass` | What the operator's key holds: `live` (unexpired and not revoked), and `recorded`, one entry per recorded host with `paced`, whether the window cap admits a dial to it now. `null` for a key with no pass. |
| `phase` | `opened`, `auth_accepted`, `ok_sent` or `closed`. `auth_accepted` and `ok_sent` are two phases with the dial between them. |
| `auth_accepted`, `ok_sent` | Whether this connection's AUTH was accepted and whether OK went out, kept past the close: the two orderings are about the trace and not about the phase a dial or a frame finds. |
| `dialed` | The addresses the dialer was handed, oldest first. |
| `forwarded` | Application bytes forwarded. A binary frame before OK closes the connection instead. |
| `refused` | The reason sent before closing — `auth`, `pass`, `destination`, `address`, `pace` — or `dial` for a dial that failed after the checks passed, or `null`. |

### Dispatch

`knowledge` is harness knowledge in `STA-24`'s vocabulary and never the companion's state layout,
and it is the running worker's — which `STA-3` makes what was durably appended. External state is
not in the file at all: no member says what a vendor or machine did, and a `read`'s `reports` is
the adapter's answer rather than the far side itself. Resources and targets are opaque: an approved machine entry, an
allocation index and a vendor machine id are integers, and `facts` is one integer
standing for the structured facts an approval was rendered on, so the comparison exercises the
resolution, the barrier and the approval checks and nothing about arguments or cost bounds.

| Member | Meaning |
|---|---|
| `durable` | Whether in-memory state is also what was appended. `STA-3` makes it always true; the traces without that rule are where it is false. |
| `associations` | The harness's own mapping of what a model may name — an allocation index, a vendor machine id — to the approved machine entry, oldest first. Never taken from a request. |
| `calls` | One entry per intent the journal holds, oldest first, with its state read from later records at that intent's position, never looked up by call id: the `call`, the `target` the model named, the `resource` the harness assigned, the `operation`, the `session`, the `approved` session and facts, and `state` — `unresolved`, `terminal` (an admissible confirming read, a matching reboot collection, or a valid disposition), or `no_effect` for a read. |
| `unresolved` | Per resource the journal names, the call ids the barrier stands on. |
| `dispositions` | Every disposition record the journal holds, oldest first: its `resource`, `calls` and `continuation`, and `valid` — whether `STA-24`'s test accepts it against the journal before it. One that is not valid is read as if it had never been recorded, and is here because the operator is shown the record. A valid one may have been replaced or have ended since. |
| `standing` | Per resource, the disposition standing over it: the `calls` it disposed and the `continuation` in force. Absent where none stands — none recorded, or the continuation dispatched — and in the trace that runs without `dispositionBindsContinuation`, where a disposition restricts nothing. |
| `reset_offer` | The approved entries whose planned reset into the installed system may be offered (`STA-20b`): prerequisites belong to the current installation, the newest collection has a durable result, and its keys match the first durable prerequisite keys there. That first set must also differ from every earlier installation's prerequisite set for the entry. One ordinal per key set carries identical sets only; partial overlap, installed-pin comparison and the rescue-pin comparison are Markdown-only. |
| `current_installations` | Each named `entry` and its derived zero-based `installation`. Only a vendor reinstall dispatch or the rescue reset dispatching an approved destructive reinstall advances it. |
| `reinstall_approvals` | Existing journaled typed approvals, oldest first: `entry`, `call` and `approved` session/facts. These name the specific reset dispatch, never a generation. |
| `reboot_results` | Collected reboot records, oldest first: `call`, `resource`, `record_boot` (or `null`), `observed_boot`. Ordinals stand for boot identities, never wire bytes. Only a durable matching new-boot collection settles the approved delivery reboot. |
| `reinstall_withdrawals` | Journaled withdrawal acts, oldest first: `entry`, `call` and `approved` session/facts, matching the approval they withdraw. |
| `prerequisite_records` | Oldest first, the durable `ready_to_reset` per-command records (`kind: command`) and results (`kind: result`), each with `entry` and derived `installation`; a result also has its symbolic `keys`. A command without a later durable result withholds the offer until a later durable prerequisite read. |
| `dispatched` | The calls whose effect went out, oldest first. |
| Schema-9 additions | See [Dispatch schema 9](#dispatch-schema-9) for exact contact mappings, admitted deletion and pending-connection members. |

A refusal is `reason` — `unmapped`, `binding`, `facts`, `append`, `barrier`, `continuation`,
`approval_activation`, `withdrawn_approval`, `identity_exclusion` or `deleted` — with `calls` on the barrier, `records` on the identity exclusion and, on the continuation, `in_force`: the continuation of the
standing disposition that refused the request, whether by its reach or by the stop a destructive
one puts on `exec` and `delivery_reboot`. `approval_activation` names an approval-bound reset
without a confirming activation dispatched since approval. `withdrawn_approval` names its matching withdrawal with
`resource`, `call` and `approved` session/facts. For `deleted`, see [Dispatch schema 9](#dispatch-schema-9).


### Pins

In schema 7, `knowledge` is harness knowledge in `SEC-11`'s, `CHN-R1`'s, `CHN-R7`'s and `ARC-43`'s
vocabulary and never
the companion's state layout. External state is not in the file: `snapshot` is what the
vendor's field showed when it was read, a session's `presented` is what the far sshd presented, and
no member says which system the machine is actually running. An `entry` is the approved machine
entry as an integer. A host-key set is an ordered array of symbolic fingerprint ordinals,
in Ed25519, RSA and ECDSA order when complete. A handshake presents one symbolic ordinal.
No ordinal is a real fingerprint, public key or key material. Arrays expose partial overlap
between publications and membership of a presented key in a pinned set.

| Member | Meaning |
|---|---|
| `pins` | The pins journaled, oldest first: the `entry`, what the pin is held `per` — `boot`, with the `boot` beside it, or `machine` — the `keys`, `source`, and installation ordinal; attest pins also carry the observed `author`. A pin from an earlier installation remains in history but is inactive. |
| `publication_groups` | Installation groups in creation order, each with its `entry`, zero-based `installation`, and compact `observations` in recording order. An empty reading is recorded when it opens a group. Any group may have no observations, including the initial one opened by a job read or attest; reinstall also opens a group with no observations, so its first empty reading adds none. Empty groups retain installation boundaries. |
| `current_installations` | Each named machine's current installation ordinal, whether or not it has a publication or active pin. |
| `pending_verification` | Restored, already admitted published pins whose contact remains withheld pending revalidation; retained across restart. Pin preservation is independent of contact permission. |
| `pending_reinstall` | Machine entries whose latest operator-chosen destructive reinstall, through the vendor API or from rescue, has no new installed pin from any source. This is explanatory state, not the gate on an active pin. |
| `consumed_introductions` | Machine entries whose introductions have been accepted, in journal order; retained across restart. Pins and consumption are appended together before any connection can use them. |
| `planted_senders` | A fixed list of machine entries and their independently configured sender ordinals, identical in `start` and every step. For a named witness, take entries from its starting knowledge, then event entries in trace order, keeping the first occurrence of each. For the enumeration, use entries from `bound.start`'s knowledge and then `bound.alphabet` in the same way; `bound.start` and every enumerated trace, including the empty trace, share that list. An event's entry is included even when the event is refused and journals nothing. The symbolic association is fixed by the assumptions, not supplied by the observed author; no private keys or key bytes are serialized. |
| `snapshot` | Per entry, what `/rescue/last` showed when the harness read it, `null` for the empty field — the one journaled before a reset, which the confirmation is read against, and which a reading taken while that reset is outstanding does not move. Absent for an entry whose field was never read. |
| `boot` | Per entry, the rescue boot the harness counts: `0` before the first reset into rescue, and the next one for each dispatched. Never the vendor's `boot_id`. |
| `awaiting`, `confirmed` | The resets dispatched whose confirmation is outstanding, and those confirmed, each as the `entry` and the system it resets `into`. An outstanding one also carries what it `expects`: the pin the intent named as its expected next pin (`STA-20b`), `null` for a reset into rescue, whose next set nothing knows yet. |
| `sessions` | The connections admitted, oldest first: the `entry`, the `system`, the `boot` and installation ordinal it was made in, the single fingerprint ordinal `presented`, and the `pin` it was checked against. Historical sessions remain intelligible after reinstall. |
| `halts` | The handshakes halted, oldest first: the `entry`, the `system`, what was `presented`, and the `reason` — `no_pin` (no eligible pin: a restored pin can be stored but ineligible while revalidation is unresolved; see `STA-16`), `mismatch` (the error `SEC-11` halts on), or `confirms_reset` (the halt the reset explains). |

The pin sources are the vocabulary of `TauWeb.Pins.Source`: `rescue_last`, `ready_to_reset`,
`attest`, `published` and `model_text`. The event's observed author is compared with that machine's planted
sender; the file never supplies a prevalidated introduction. A failed append records neither
pins nor consumption under production parameters, so the next valid introduction can still
succeed. The assumption of an atomic durable pin append and replay is a boundary of the proof,
not evidence about real storage or cryptography. Installation groups, recorded observations and
reinstall records are assumed durable too; ordinary publication and reinstall append failures
remain outside the companion. A `verify` event separately carries an atomic required-evidence
and revalidation append outcome: a failed required append records nothing and leaves
knowledge unchanged, including for a contradictory read. The pending revalidation hold stands
across restart, and the next authorized qualifying read can still succeed. Empty and contained
repeats that neither add evidence nor admit contact require no append. `restore` starts from
admitted, import-validated pins and history; import byte validation is outside these symbolic
events. The `authorized` input represents existing vendor-status read
authority; retry grants none. `retry_available` is false once a durably recorded observation
in the current installation holds a fingerprint outside the saved pin (`STA-16`); a `verify`
event that still arrives is processed and retained. That check is the `publishedWithin`
assumption, so a trace whose assumptions turn it off still shows retry available.
Restart preserves those journaled facts,
including refusal of a second introduction and publication history; window and status-poll timing
are outside this file. A halted handshake after an attempted connection does not demonstrate
`CNF-23`'s "no contact with the machine before an eligible pin is active" on the integrated harness.
`CHN-5` says
"the browser MUST stop listening for that installation's introduction and MUST refuse an
introduction that arrives later, without journaling a pin or consuming an introduction".
Its first-contact trap projects unchanged pins and consumption after the late introduction;
the connection presenting that introduction's set is checked against the pin already held.

The bounded alphabet and event limit are emitted from the companion's declarations. Longer
named traces additionally exercise rescue refusal, wrong-author then valid admission, repeated
introduction across restart, failed-append then valid admission, independent machines and an
introduction after a job pin, and LNVPS source, completeness, incomplete history, freshness,
pending reinstall across restart and machine-isolation cases. Restore witnesses additionally
exercise failed-read retry, empty/partial completion, durably appended contradictions retained
before Restore or during revalidation with retry withdrawn, unauthorized verification, failed evidence append with
retry still available, later qualifying completion after failed append (including a conflicting
read), and retired-pin refusal. These named
traces do not extend the bounded alphabet or its decided coverage. The named traces also include
the second dedicated ceremony and earlier job-read or attest pin overlap. Each
new guard's refused/admitted pair changes only that guard, as the assumptions record, except
the publication-to-publication replacement pair: its admitted side also disables the
within-installation comparison so a complete but changed set can reach the replacement guard.
The Restore saved-pin equality pair disables within-installation comparison on both sides
so the equality guard alone refuses its different complete publication. The single-use pair
runs with first contact only off, so that the consumed introduction is what
its refused side shows.

### Dispatch schema 7: operation receipts

The guard `orderAssociation` requires the order's returned id and its durable association.
An approval carries `receipt_binding`, either null or an LNVPS binding with operation
`order`, `stop` or `restart`, `account` and `signed_request` ordinals. The same binding appears
in the journaled call. A `receive` event has provenance `adapter observation`, `appended`, and
`receipt`: `source`, `call`, `resource`, `target`, `binding`, `validated`, `returned_vendor`.
The last field is the returned vendor id for an order, or null when absent. Source is
`browser_vendor_tls`, `arbitrary_response`, `job_output`, `notify_event` or `proposed_text`.
The outcome's `settled` lists calls removed from the barrier. Knowledge retains `receipts`,
oldest first, with those same fields. An order settles only once that id's durable association
names the approved entry; receiving its receipt alone leaves the order unresolved. Validation
and browser-vendor TLS are input assumptions;
these ordinals are neither key bytes nor evidence about network execution. Read events retain
their distinct provenance and shape. No receipt carries deletion confirmation; its constituent
record and secret-duty consequences remain outside this companion.

### Dispatch schema 8: unavailable vendor identity

Receipt objects additionally carry `returned_withheld`, a boolean distinguishing canonical
received-present withholding from absent `returned_vendor`. These witness ordinals abstract
canonical evidence; raw/protected decoding, genuine pre-omission comparisons, setup validation,
projection custody and listing candidate selection remain in the Markdown companion.
An ordinary display omission never changes the canonical witness receipt.

`associate_evidence` has provenance `adapter observation`, genuine `vendor` and `entry`
ordinals, conversion `withheld` and append outcome `appended`. Its admission is derived from
the earlier journal, never supplied by the event. A duplicate appends nothing; a retained
known cross-entry conflict refuses. Unknown cross-entry aliasing produces quarantine, which
supplies no mapping, target or receipt settlement. A failed append applies nothing.
`associate` uses the same admission rule with retained input and successful append.
Approved-entry and allocation-reservation checks are assumed at these abstraction inputs.

Knowledge additionally carries `quarantined` entries as `{vendor,entry}`, with vendor null
for canonical withholding, and `identity_exclusions` as `{entry,records}` with ascending
zero-based record ordinals in the abstract journal. No raw bytes, receipt hashes or new target
handles are carried. The `identity_exclusion` refusal names `records`. The guard
`identityExclusion` has its refused/admitted pair for an order to another entry after canonical
withholding. Other named witnesses retain same-entry adoption, withheld association, failed
append, quarantine conflict, unresolved withheld receipt, uncorrelated evidence and permanence
through disposition/replay. An existing mapping retains its own targeting authority. No
session-limit, concrete encoder or external cleanup property is proved by these witnesses.

## Allocation schema 3

The Failed event is a `local writer decision`, an explicit extension of ADR-0032's closed
provenance vocabulary. The same extension labels a local create-intent append and local
transport closure; it conveys a local decision, never an external observation or operator act.
The `failed` event contains `identity`, `checked_sequence` and a nested `append` with
`storage outcome of an append` provenance and `durable`. Its step's `terminalized` boolean
reports whether the admitted proof record was added. The former adapter-observed failure event
is removed. `created` and `destroyed` retain their observation provenance.

`journal.sequence` is an allocation-history prefix ordinal, advanced by reservation, approved
create intent and admitted terminalization. `create_intents` retains possibly-sent identities;
`failures` retains identity/checked-sequence pairs. `mappings` retains opaque admitted identity,
entry, predecessor identity (or null) and machine ordinal (or null), independently of status.
Mapping admission is assumed, never supplied by Failed. The lineage witness starts with these
already-admitted mappings and does not admit a successor. No recovery-payload or derivation
version changes with this witness schema.

`begin_create` has model-request provenance and an identity; it registers a pending sender.
`create_intent` has local-writer-decision provenance, identity and `appended`, representing an
approved possibly-sent create even when no later send marker exists. `send_create` has
model-request provenance, identity and `appended`; it fuses approval and handoff in one
serialized step. A preceding `create_intent` for that identity is already possibly sent and
therefore refuses a later `send_create`. The step reports a `sent` boolean and `pending`
identities after the writer's final fence. `begin_create` and `replay` also report `pending`;
all starts have no pending or sent creates. `replay` has replay provenance and drops the
pending sender without resending. `inconclusive` carries ordinal `reason`: error, loss, empty
listing or disposition (0 through 3); only the last has disposition provenance, the rest adapter
observation. It changes no allocation knowledge and supplies no local unsent proof.

The complete prefix, absence of earlier possibly-sent create and non-imported journal are
checked by the sole writer. The serialized trace assumes sole-writer serialization, genuine
local prefix custody, independent ordinary create/retry authorization and actual append-before-handoff
ordering. The sender fence checks reserved status and known intent history; it does not decide
imported or old-epoch create authority. The stronger non-imported/current-epoch conditions apply
to the new local terminal proof only. It proves no writer lock,
storage implementation, browser concurrency, transport race or vendor behavior. The independent
implementation evidence remains `CNF-72`.

## Dispatch schema 9

Requests add `read_route` (`machine` or `vendor_evidence` for reads, null otherwise) and nullable symbolic `connection`.
The route is the harness adapter's classification of the real destination, not a model-chosen
exemption. `machine` reads are outgoing job-record requests; it is the conservative construction default.
Vendor evidence reads explicitly select `vendor_evidence`. The outgoing pinned SSH probe is
outside this classification and remains subject to its existing owners. A `vendor_evidence` request retains
ordinary typed approval checks; wrong approved facts refuse. Received `read` observations remain
separate and are not transmissions. `deletionContact` checks machine traffic in the shared final
send decision, including `exec`, `delivery_reboot` and each `machine` read. Refusal `deleted`
adds no terminal record for previously sent work.

`deletion` has adapter-observation provenance, `vendor` and `appended`. Its input is assumed to
be already admitted under the existing deletion-evidence contract; it does not validate those
constituents, infer destruction from a stop receipt, or settle unrelated calls. Durable
`deleted_machines` is a list of exact machine ordinals, not allocation failure or entry status.
An explicit vendor target is checked by that identity. Entry/index targets use the exact
already-admitted alias-to-machine facts in `contact_mappings` (`target`, `vendor`); a shared
resource entry never substitutes for machine identity. Missing exact contact mapping refuses
as `unmapped`. Mapping admission and immutable-ID correspondence remain assumptions; the new
checking events admit no map. Initial fixtures carry the corresponding existing mappings.

`await_connection` has model-request provenance and nested complete `request` arguments
(call, target, operation, session, facts, read route, connection and approval), without any
append outcome at preparation: no intent or transmission occurs there.
`waiting_connections` projects its call and connection. `connection_ready` has adapter-observation
provenance, `call` and `appended`, resumes that pending request and reports the fresh `dispatch`
and possible `refusal` after checking current knowledge. A missing pending call does nothing.
`close_connection` has local-writer-decision provenance and a connection ordinal; it changes no
call outcome. Under `pendingCleared`, replay discards every pending request and local closure
discards only that connection’s pending requests, without settling previously sent work. Each
refusal has a guard-removal pair, and a sibling connection retains valid progress. Reuse is explicit in successive request events sharing a connection ordinal;
each is checked independently. Connection-ready notifications assume that opening completed;
no actual socket, await scheduling or cancellation is established.

The exact covered boundary is one final serialized check per outgoing request, after preparation
and between reads, against the current admitted deletion prefix and ordinary typed approval.
Real transport/writer/append races, destination classification, browser scheduling and I/O
ordering remain independent implementation evidence under `CNF-114` and `CNF-54`. No capability
is admitted by these witnesses. Authority schema 3 embeds these fields but its received records
remain received records; it adds no outgoing collection proof of its own.
