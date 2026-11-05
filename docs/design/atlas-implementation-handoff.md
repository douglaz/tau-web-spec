# Atlas implementation evidence handoff

This is an informational comparison packet for `tau-web-rust`, linked from the
[atlas](../state-machine-atlas.md). It adds no implementation duty or admission.
The owners are [07-conformance.md](../../07-conformance.md) and its
[admission table](../../07-conformance.md#capability-applicability-and-admission).
The [source-finding record](../review/2026-11-03-atlas-source-finding.md) records
the exercise and dispositions separately.

## Immutable source contract

The original fixture/source baseline is specification commit
**`674a7c6b8a4671fc2bc2e2e20855b084a69837ba`**. The original packet's paths and
selected cases were checked against that tree. The starting revision `4095db7` adds only the
tracker claim. This handoff's resulting documentation revision is supplied in the
completion report, not guessed here.

*Amended 2026-11-03:* that baseline holds `dispatch-witnesses-v8.json`,
`allocation-witnesses-v2.json` and `authority-witnesses-v2.json`. The
[fixture rows](#fixture-selection) for Dispatch schema 9, Allocation schema 3 and
Authority schema 3, and the
[unsent failure and deletion-contact coverage](#unsent-failure-and-deletion-contact-comparison-coverage),
were checked against the revision that adds this amendment; they do not exist at
`674a7c6`. A downstream result records both its actual
specification pin and implementation revision; agreement at an older pin is only
agreement at that pin.

[ADR-0032, How the implementation is compared](../adr/0032-the-formal-companion-follows-provisiond-spec.md#how-the-implementation-is-compared)
owns comparison discipline: “the core is written from the requirement text and
never from the Lean source or the file”. Build the independent implementation
from the owners; use exported outcomes and knowledge as test expectations.
Investigate a disagreement against those owners, retaining the failing history.
Copying Lean or renderer guards, or editing until a sample passes, defeats that
comparison. The files are test fixtures, not production decision inputs. No Lean
toolchain is required by the implementation.

Authority remains per clause under
[ADR-0032](../adr/0032-the-formal-companion-follows-provisiond-spec.md#what-is-adopted).
The [marked-region definition](../../CONTEXT.md#the-specifications-own-artifacts)
says “Inside one the declaration is authoritative and the Markdown is its rendering;
outside one the transitional rule holds and the Markdown is.” This applies to every
covered region, including STA-24's receipt mapping. Informational atlas rendering
does not extend those regions.

## Fixture selection

The wire contract is [Witness files](witness-file-v1.md#the-file), including its
[Authority schema 4 extension](witness-file-v1.md#authority-schema-4). Exact files:

| Path relative to the specification root | `module` / `schema` | Use and local boundary |
|---|---|---|
| [`docs/design/dispatch-witnesses-v10.json`](dispatch-witnesses-v10.json) | `dispatch` / 10 | Typed resource and command knowledge; lifecycle, pending-check, untyped and inference-clock behavior omitted |
| [`docs/design/allocation-witnesses-v3.json`](allocation-witnesses-v3.json) | `allocation` / 3 | Restore/Replace identities and ceremony; fresh entropy/import construction assumed |
| [`docs/design/pins-witnesses-v5.json`](pins-witnesses-v5.json) | `pins` / 5 | Symbolic publication/pin knowledge; atomic append/restart assumed, no transport evidence |
| [`docs/design/declaration-witnesses-v1.json`](declaration-witnesses-v1.json) | `declaration` / 1 | Field presence and opaque set differences; no lifecycle or secret-placement proof |
| [`docs/design/authority-witnesses-v4.json`](authority-witnesses-v4.json) | `authority` / 4 | Named processed-event histories using shared Dispatch; not an atlas renderer input |
| [`docs/design/relay-witnesses-v1.json`](relay-witnesses-v1.json) | `relay` / 1 | Historical `relay-protocol-v1.md` profile only; no current relay target selected |

For the atlas-displayed cases, the exact presentation selection remains
[`SELECTIONS`, `PAIR_NAMES` and `CASES`](../../tools/render_state_machine_atlas.py).
This packet selects the following smaller comparison sample, not a new declaration
inventory. In each row, qualify the displayed suffixes with the exact namespace
in the first column. Select by declaration membership, require a unique match,
and retain the entire trace and pair, not just its last step.

| Namespace | Selected declaration suffixes | Pair assumption change from baseline to historical counterfactual |
|---|---|---|
| `TauWeb.Dispatch` | `same_action_new_call_id_refused`, `same_action_new_call_id_admitted` | `resourceKey: entry → call` |
| `TauWeb.Dispatch` | `second_command_held`, `second_command_without_hold`; `hold_reads_and_other_machines` | `commandHold: true → false`; separate collection/progress history |
| `TauWeb.Dispatch` | `resolution_append_failed_refused`, `resolution_append_failed_admitted` | `durableBeforeApply: true → false`; Robot read confirmation |
| `TauWeb.Dispatch` | `excluded_order_refused`, `excluded_order_sent_without_guard` | `identityExclusion: true → false` |
| `TauWeb.Dispatch` | `lnvps_receipt_confirms`; `receipt_operation_limit` | Unpaired, operation-limited receipt histories; discriminator below |
| `TauWeb.Allocation` | `stale_sheet_refused`, `stale_sheet_admitted`; `replace_allocates_again` | `restoredAllocatesNone: true → false`; separate fresh-seed progress |
| `TauWeb.Pins` | `old_pin_refused_pending_reinstall`, `old_pin_admitted_without_reinstall_guard`; `pending_restart_then_fresh_admitted` | `reinstallRetiresPin: true → false`; separate fresh-publication progress |
| `TauWeb.Declaration` | `empty_inbound_refused`, `empty_inbound_admitted`; `adhoc_delivered` | `emptyMeansPerField: true → false`; separate complete-check progress |
| `TauWeb.Authority` | `successor_barrier_refused`, `successor_barrier_without_entry_key` | Nested `dispatch.resourceKey: entry → call` |
| `TauWeb.Authority` | `failed_confirmation_keeps_barrier`, `failed_confirmation_without_durability`; `durable_confirmation_opens_successor` | Nested `dispatch.durableBeforeApply: true → false`; shared Robot history and durable-confirmation progress |
| `TauWeb.Authority` | `hidden_progress`, `hide_ends_without_preservation`; `validated_progress_and_publication` | `hidePreserves: true → false`; separate validated continuation/publication |

The full names are obtained by joining namespace, dot and suffix, for example
`TauWeb.Authority.durable_confirmation_opens_successor`. Each name resolves
against the formal gate's current tagged index; that emitted index owns the
inventory. All selected declarations above have one fixture match except
`TauWeb.Dispatch.receipt_operation_limit`: require both an event with
`kind=request, operation=create` and an event with
`kind=associate, entry=1, target.vendor_machine_id=307`, matching `CASES` and the
source trace. The other receipt-operation histories share its declaration.
Do not select by array position, first match, outcome or a guessed provenance.
No repeated Authority declaration is selected by this packet.

These pair deltas are presentation aids, not replacements for each trace's full
`assumptions`. Preserve all other assumptions and the source `pair.side` and
`pair.with`. Historical admitted bad sides are negative controls: the independent
implementation should differ at the trap, not acquire its withdrawn guard.
For Authority, `side=refused` names the strong baseline and `side=admitted` the
counterfactual, **not** a send/publication result. In `hidden_progress`, the
baseline sends and the counterfactual wrongly refuses progress. Compare the
actual outcome fields rather than turning pair labels into expected refusals.

## Per-step comparison surfaces

Use the exact schema at the pin. Compare the initial `start` projection, then
every ordered `steps[].event`, including `kind`, provenance and all arguments,
the event's emitted outcome members, and its resulting projection. A lost reply
or crash is a driver instruction, not an observation the implementation magically
receives. The request carries unresolved naming inputs; compare the implementation's
mapping rather than supplying it a pre-resolved resource.

| Module | Initial / resulting surface | Emitted step outcomes, where present |
|---|---|---|
| Dispatch 9 | `start` / `knowledge` | `dispatch`, `refusal`, `settled`, `disposition`, `offer`, `withdrawal` |
| Allocation 3 | `start` journal / `journal` | `allocation`, `identity`, `recorded`, `terminalized`, `sent`, `pending` |
| Pins 5 | `start` knowledge / `knowledge` | `boot`, `check`, `consumed`, `halt`, `pending`, `pinned`, `replayed` |
| Declaration 1 | `start.declaration`, `start.machine`, `start.record` / `record` | `verdict`, `delivered` |
| Authority 4 | `start` / complete `knowledge`: `actors` (including `bound`), `ceremony`, `ceremony_owed`, `dispatch`, `ended_sessions`, `fenced`, `issued`, `locked`, `published` | `authority_eligible`, `sent`, `delegated_verdict`, `published`, `journal_changed` |

Absence of an optional outcome member is not false. Absence of delegation assigns
no universal cross-layer refusal precedence. Preserve ordered arrays, exact
argument identities, all knowledge members, guard parameters, external hypotheses,
`declarations`, `pair` and complete file `bound` metadata. Do not fabricate a clock,
timer, wire response, secret or external-state field.

Dispatch and Pins bounds are three events over their emitted alphabets;
Allocation's is four. Named witnesses can be longer than those enumeration bounds.
Declaration uses its emitted base/presence/observation/tenancy sweep, not an invented
event bound. Authority's `TauWeb.Authority.witnessBound` supplies the checked cap on
named histories: its `enumeration` is empty and claims no exhaustive alphabet.
Keep these distinctions in a downstream result with the exact fixture path,
bound, selected case/discriminator and implementation revision.

The [atlas's general-theorem reference](../state-machine-atlas.md#processed-authority-composition)
and [STA-23's Authority scope](../../03-state-and-recovery.md#what-survives-a-lost-phone) retain
the theorem/premise boundary. For example,
`TauWeb.Authority.ordinary_refinement` assumes
`dispatch.durableBeforeApply=true` and a newly dispatched intent; it establishes
symbolic eligibility and equality to the shared Dispatch transition, durable intent,
approval facts and applicable barrier/disposition checks. It does not measure a
real append or send. `TauWeb.Authority.fence_history` preserves an already fenced
identity over arbitrary symbolic histories; `TauWeb.Authority.ended_no_send` and
`TauWeb.Authority.ended_no_publication` additionally require `endFence=true`,
`workerIdentity=true` and membership in the fenced set. These are different claims
from the named finite samples. Single-writer custody, stopped predecessors,
connection/scan readiness, safe-unsent identification, origin correlation and the
conditional issuer/clock/limit evidence remain interface hypotheses.

## Runtime evidence still owed

No browser, device, adapter or live vendor evidence was obtained here. The table
routes missing evidence to existing owners; it is not another conformance suite.
Read each item's complete cases and the admission table before choosing a runtime
target. Green specification gates and faithful fixture rendering admit no route.

| Evidence seam still owed | Existing owner and applicability |
|---|---|
| Actual durable append before send, failed appends, lost replies, replay, same-entry fresh identifiers and successor sessions | [CNF-28/29/30/112](../../07-conformance.md#approval-and-recording--sec-4-sec-12): LNVPS-path enabled typed adapter, box-plane and inference cases; Robot/dedicated and untyped cases retain their own rows |
| Pre-send/post-await authority fencing, processed and delayed/suppressed lifecycle notifications, stale completion, writer concurrency, ceremony hide and second-instance refusal | [CNF-82](../../07-conformance.md#additional-contracts-from-the-september-9-review), with [CNF-29](../../07-conformance.md#approval-and-recording--sec-4-sec-12) and [CNF-40](../../07-conformance.md#state-and-recovery--sta-): the LNVPS path; physical Android Chrome under STG-14, iOS investigation only. Conditional procured limits stay with the procured items in the LNVPS-path row; no capability is enabled |
| Privileged tracked startup/collection, live-command waits, stopped waits, failed elevation, missing records and destructive dispositions across all requesters | [CNF-40/55/114](../../07-conformance.md#state-and-recovery--sta-), [CNF-110](../../07-conformance.md#approval-and-recording--sec-4-sec-12): the LNVPS path except the explicitly dedicated reboot/reset/relabel cases |
| Real transport, first-contact pin admission, reinstalls, retired pins, restored publication history and fresh privilege on re-entry | [CNF-21/23/109](../../07-conformance.md#the-channel--sec-11-chn-), [CNF-108](../../07-conformance.md#the-deliverable--arc-17-arc-39): the LNVPS path. [CNF-62–64](../../07-conformance.md#the-channel--sec-11-chn-) where a typed adapter uses the tunnel; attest/job-read cases retain their route rows |
| Vendor operation confirmation versus guest boot, service survival, pending-check hold, findings and final delivery verdict; model reports cannot supply a verdict | [CNF-50/53/107/108](../../07-conformance.md#the-deliverable--arc-17-arc-39), [CNF-112](../../07-conformance.md#approval-and-recording--sec-4-sec-12): LNVPS-path restart; `delivery_reboot` cases remain dedicated, scanner half follows scanner enablement |
| Restore/Replace, journal-only retained/omitted sends, pin history, stale backups, unknown findings, scan re-arm and empirical recovery | [CNF-19/20](../../07-conformance.md#credentials--sec-5), [CNF-84](../../07-conformance.md#additional-contracts-from-the-september-9-review) and [CNF-115](../../07-conformance.md#state-and-recovery--sta-) under the [recovery row](../../07-conformance.md#capability-applicability-and-admission); [CNF-95](../../07-conformance.md#credentials--sec-5) and [CNF-109](../../07-conformance.md#the-channel--sec-11-chn-) under the LNVPS-path required row, with its route qualifications. Robot rescue/relabel, job-read/attest admission and multi-machine scanning cases retain their separate rows |

The [atlas open-owner routes](../state-machine-atlas.md#open-owners-and-deliberate-boundaries)
retain semantic/evidence work separately from clarity completion. Tenants remain
with [OPN-27](../../08-open-questions.md). The conditional move of the historical
Relay module, witness file and controls remains with the **open**
[TASKS.md T30](../../TASKS.md#open-t30-relay-port), when paid-tcp-relay gains a formal
layer; its earlier completed namesake is the scaffold port.
Recovery/scanning gates remain empirical obligations. The symbolic Authority
extension is scoped targeted assurance, not physical lifecycle verification,
reliable cleanup, actual storage ordering, transport, vendor behavior or full
runtime composition.

## Unsent failure and deletion-contact comparison coverage

Informational coverage map. Rules and rationale stay in `STA-22b`, the
[allocation failure record](credential-format-v1.md#allocation-failure-record), `STA-20`,
`STA-24` and `CHN-2`. Select the named witness declarations from the exact files above and compare
every step, including refused/not-appended outcomes. Universal theorem references resolve
through the formal index rather than selecting a serialized trace. Bounded declarations
label enumeration members: compare their enumeration under its emitted bound rather than
requiring a unique named history. The new witnesses are not additional
atlas evaluator inputs. The table maps the discriminators to checking evidence and independent
implementation evidence; it records no completed browser or transport conformance.

| Discriminator | Declaration suffixes and emitted observable outcomes | Isolated control or implementation evidence |
|---|---|---|
| Local proven-unsent terminalization and consumed index | Allocation: `unsent_failure_durable`, `failed_create_keeps_index`; `terminalized` on the Failed step, proof identity/sequence, retained entries and counter | `formal: all local terminalization refused`; `CNF-72` |
| Pending sender and approved intent fenced after terminalization | Allocation pairs: `terminal_sender_refused` / `terminal_sender_admitted`, `terminal_intent_refused` / `terminal_intent_admitted`; `send_create.sent`, pending identity and create-intent history | `formal: pending sender ignores terminalization`; `CNF-72` |
| Approved possibly-sent intent plus error, loss, empty listing or disposition | Allocation pair: `possibly_sent_failure_refused` / `possibly_sent_failure_admitted`; `inconclusive_never_proves_unsent` selects each reason; Failed refuses despite no send marker | `formal: possibly-sent create treated as unsent`; `CNF-72` |
| Imported or stale-prefix absence proof | Allocation pairs: `imported_failure_refused` / `imported_failure_admitted`, `stale_sequence_refused` / `stale_sequence_admitted`; unchanged reservation versus admitted proof | `formal: imported prefix claims no later sends`, `formal: stale failure proof sequence accepted`; `CNF-72` |
| Failed append, replay and temporary hold | Allocation pair: `failure_append_refused` / `failure_append_admitted`; `failed_append_sender_progress`, `replay_sender_no_resend`, `held_reservation_stays`; reservation/counter, sent boolean and proof history | `formal: failed terminal append applied`, `formal: create readiness refuses every sender`; `CNF-72` |
| Entry/predecessor history and older actual machine | Allocation witness: `failure_retains_lineage`; universal theorem: `terminalization_keeps_metadata`; retained old mapping beside later Failed allocation | `formal: all local terminalization refused`; separate production contact/binding/target cases in `CNF-72`; mapping admission is assumed here |
| Index non-reuse, import and ceremony | Allocation universal theorems: `issued_nodup`, `issued_index_lt_limit`, `issued_below_next`; serialized `bounded_nodup`, stale-sheet and ceremony pairs and successful traces retained | Existing import/ceremony/exhaustion controls; `CNF-72`, `CNF-84` |
| Fresh command after admitted deletion | Dispatch pairs: `deleted_command_refused` / `deleted_command_admitted`, `deleted_reboot_refused` / `deleted_reboot_admitted`; `dispatch: refused`, `refusal.reason: deleted`, no new intent | `formal: deleted machine traffic allowed`, `formal: deleted harness reboot omitted from machine traffic`; `CNF-114` via `CNF-54` |
| Fresh collection after admitted deletion | Dispatch pair: `deleted_collection_refused` / `deleted_collection_admitted`; outgoing `read_route: machine` refuses | `formal: deleted machine traffic allowed`, `formal: collection confused with vendor evidence`; `CNF-114` via `CNF-54` |
| Deletion between reads on one connection | Dispatch pair: `reused_connection_refused` / `reused_connection_admitted`; first read dispatched, second refused, same connection ordinal | Same deletion/collection controls; `CNF-114` via `CNF-54` |
| Deletion during command or collection connection opening | Dispatch pairs: `opening_command_refused` / `opening_command_admitted`, `opening_collection_refused` / `opening_collection_admitted`; preparation sends nothing, readiness uses current deletion prefix | Same deletion/collection controls; `formal: connection readiness refuses every request`; `CNF-114` via `CNF-54` |
| Durable trigger, unsuccessful append and previously sent uncertainty | Dispatch: `failed_deletion_append_progress`, `deletion_keeps_uncertainty`, and `deletion_append_refused` / `deletion_append_admitted`; failed append/replay retains admission, local closure/replay retains unresolved command | `formal: unsuccessful deletion append treated as durable` plus independent production races in `CNF-114` via `CNF-54` |
| Independently authorized outgoing typed vendor evidence read, and authority refusal | Dispatch: `deleted_vendor_read_authority`; `read_route: vendor_evidence` sends with ordinary approval, otherwise same read refuses for approved facts | `formal: deletion blocks independently authorized vendor read`; existing approval checks; `CNF-114` via `CNF-54` |
| Legitimate connection progress | Dispatch: `connection_progress`; readiness sends, then another read sends on the same connection | `formal: connection readiness refuses every request`; `CNF-114` |
| Retained membership/history versus destruction's effective exposure | No new formal membership/exposure transition; independent implementation evidence in `CNF-54`, reached by `CNF-114` | `SEC-1` remains the owner; no membership removal inferred from the contact refusal |

The allocation-history and connection ordinals are serialized checking inputs. Complete local
history custody, sole-writer exclusion, destination classification, accepted deletion constituents,
actual append durability and transport ordering remain assumptions. In particular these traces
establish no I/O ordering, browser concurrency, remote cancellation, vendor behavior or capability
admission. Before enabling the corresponding implementation paths, the separate production
writer/append/handoff races in `CNF-72` and transport/writer/append races in `CNF-114` remain
required. The bound lengths are unchanged; alphabet members changed shape with their schemas. The added
cases are named histories.

Successor policy and live-session substitution, installation acceptance, held-output release,
journal-loss command overlap and recovery third-rung choices remain with their existing owners
and admission gates. Sheetless recovery adds no destructive authority under `STA-15`. No automatic successor or email-verification
recovery route follows from these comparisons.

Additional contact and lifecycle discriminators in Dispatch schema 9:

| Witness declarations | Observable comparison | Control / implementation evidence |
|---|---|---|
| `deleted_index_refused` / `deleted_index_admitted` | The index resolves to its exact deleted machine; it cannot bypass the contact check | `formal: deleted machine traffic allowed`; `CNF-114` |
| `missing_contact_refused` / `missing_contact_admitted` | Missing exact alias-to-machine resolution refuses as `unmapped`; shared entry equality supplies no destination | `formal: missing exact contact mapping accepted`; `CNF-114` |
| `same_entry_contact_preserved` | Already-admitted entry/index mappings to another actual machine remain usable while the deleted machine refuses; no successor admission | `formal: deletion compared by shared entry`; `CNF-72`, `CNF-114` |
| `replayed_connection_refused` / `replayed_connection_admitted` | Replay drops the queued predecessor request; stale readiness sends and appends nothing | `formal: pending connection survives replay or closure`; `CNF-114` |
| `closed_connection_refused` / `closed_connection_admitted`; `sibling_connection_progress` | Local closure drops that connection's queued request, preserves the sibling and settles no remote work | Same pending control; `formal: local closure drops sibling connection`; `CNF-114` |

The exact contact facts are existing admitted mapping fixtures, independent of resource identity;
their provenance and correctness are assumed here. The actual production mapping and session
membership checks remain separate implementation obligations. Collection progress under a held
command uses the explicit outgoing machine-read classification in `hold_reads_and_other_machines`.

The sender fence checks local reserved status and known create-intent history. Ordinary create,
retry, restored-identity and old-epoch authorization remain independent assumptions, as they are
for the allocator's explicit allocation inputs; the fence grants none. The non-imported,
current-epoch and current-prefix proof remains mandatory for the local Failed transition.

Allocation also emits `old_epoch_failure_refused` / `old_epoch_failure_admitted`: a stale import
loses a possibly-sent create, then Replace clears the import flag but cannot furnish a current
proof for the retained old epoch. `formal: old epoch supplies current unsent proof` removes only
the epoch comparison and must falsify its refusal alone. `nonreserved_failure_refused` /
`nonreserved_failure_admitted` checks that an already-created allocation acquires no Failed proof
record; `formal: non-reserved allocation gains failure proof` removes only reserved eligibility.
These discriminate the remaining clauses of the local proof, independently of index non-reuse.
Both retain the separate `CNF-72` production evidence obligation.
