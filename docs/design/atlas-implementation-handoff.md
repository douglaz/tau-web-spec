# Atlas implementation evidence handoff

This is an informational comparison packet for `tau-web-rust`, linked from the
[atlas](../state-machine-atlas.md). It adds no implementation duty or admission.
The owners are [07-conformance.md](../../07-conformance.md) and its
[stage table](../../07-conformance.md#stage-applicability-and-admission).
The [source-finding record](../review/2026-11-03-atlas-source-finding.md) records
the exercise and dispositions separately.

## Immutable source contract

The fixture/source baseline is specification commit
**`674a7c6b8a4671fc2bc2e2e20855b084a69837ba`**. All paths and selected cases below
were checked against that tree. The starting revision `4095db7` adds only the
tracker claim. This handoff's resulting documentation revision is supplied in the
completion report, not guessed here. A downstream result records both its actual
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
[Authority schema 2 extension](witness-file-v1.md#authority-schema-2). Exact files:

| Path relative to the specification root | `module` / `schema` | Use and local boundary |
|---|---|---|
| [`docs/design/dispatch-witnesses-v8.json`](dispatch-witnesses-v8.json) | `dispatch` / 8 | Typed resource and command knowledge; lifecycle, pending-check, untyped and inference-clock behavior omitted |
| [`docs/design/allocation-witnesses-v2.json`](allocation-witnesses-v2.json) | `allocation` / 2 | Restore/Replace identities and ceremony; fresh entropy/import construction assumed |
| [`docs/design/pins-witnesses-v5.json`](pins-witnesses-v5.json) | `pins` / 5 | Symbolic publication/pin knowledge; atomic append/restart assumed, no transport evidence |
| [`docs/design/declaration-witnesses-v1.json`](declaration-witnesses-v1.json) | `declaration` / 1 | Field presence and opaque set differences; no lifecycle or secret-placement proof |
| [`docs/design/authority-witnesses-v2.json`](authority-witnesses-v2.json) | `authority` / 2 | Named processed-event histories using shared Dispatch; not an atlas renderer input |
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
| Dispatch 8 | `start` / `knowledge` | `dispatch`, `refusal`, `settled`, `disposition`, `offer`, `withdrawal` |
| Allocation 2 | `start` journal / `journal` | `allocation`, `identity`, `recorded` |
| Pins 5 | `start` knowledge / `knowledge` | `boot`, `check`, `consumed`, `halt`, `pending`, `pinned`, `replayed` |
| Declaration 1 | `start.declaration`, `start.machine`, `start.record` / `record` | `verdict`, `delivered` |
| Authority 2 | `start` / complete `knowledge`: `actors` (including `bound`), `ceremony`, `ceremony_owed`, `dispatch`, `fenced`, `issued`, `locked`, `published` | `authority_eligible`, `sent`, `delegated_verdict`, `published`, `journal_changed` |

Absence of an optional outcome member is not false. Absence of delegation assigns
no universal cross-layer refusal precedence. Preserve ordered arrays, exact
argument identities, all knowledge members, guard parameters, external hypotheses,
`declarations`, `pair` and complete file `bound` metadata. Do not fabricate a clock,
timer, wire response, secret or external-state field.

Dispatch and Pins bounds are three events over their emitted alphabets;
Allocation's is four. Named witnesses can be longer than those enumeration bounds.
Declaration uses its emitted base/presence/observation/tenancy sweep, not an invented
event bound. Authority's `TauWeb.Authority.witnessBound` is a twenty-event cap on
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
Read each item's complete cases and the stage table before choosing a runtime
target. Green specification gates and faithful fixture rendering admit no route.

| Evidence seam still owed | Existing owner and applicability |
|---|---|
| Actual durable append before send, failed appends, lost replies, replay, same-entry fresh identifiers and successor sessions | [CNF-28/29/30/112](../../07-conformance.md#approval-and-recording--sec-4-sec-12): stage-1 enabled typed adapter, box-plane and inference cases; Robot/dedicated and untyped cases retain their own rows |
| Pre-send/post-await authority fencing, processed and delayed/suppressed lifecycle notifications, stale completion, writer concurrency, ceremony hide and second-instance refusal | [CNF-82](../../07-conformance.md#additional-contracts-from-the-september-9-review), with [CNF-29](../../07-conformance.md#approval-and-recording--sec-4-sec-12) and [CNF-40](../../07-conformance.md#state-and-recovery--sta-): stage 1; physical Android Chrome under STG-14, iOS investigation only. Conditional procured limits stay with the procured items in the stage-1 row; no capability is enabled |
| Privileged tracked startup/collection, live-command waits, stopped waits, failed elevation, missing records and destructive dispositions across all requesters | [CNF-40/55/114](../../07-conformance.md#state-and-recovery--sta-), [CNF-110](../../07-conformance.md#approval-and-recording--sec-4-sec-12): stage 1 except the explicitly dedicated reboot/reset/relabel cases |
| Real transport, first-contact pin admission, reinstalls, retired pins, restored publication history and fresh privilege on re-entry | [CNF-21/23/109](../../07-conformance.md#the-channel--sec-11-chn-), [CNF-108](../../07-conformance.md#the-deliverable--arc-17-arc-39): LNVPS stage 1. [CNF-62–64](../../07-conformance.md#the-channel--sec-11-chn-) where a typed adapter uses the tunnel; attest/job-read cases retain their route rows |
| Vendor operation confirmation versus guest boot, service survival, pending-check hold, findings and final delivery verdict; model reports cannot supply a verdict | [CNF-50/53/107/108](../../07-conformance.md#the-deliverable--arc-17-arc-39), [CNF-112](../../07-conformance.md#approval-and-recording--sec-4-sec-12): stage-1 LNVPS restart; `delivery_reboot` cases remain dedicated, scanner half follows scanner enablement |
| Restore/Replace, journal-only retained/omitted sends, pin history, stale backups, unknown findings, scan re-arm and empirical recovery | [CNF-19/20](../../07-conformance.md#credentials--sec-5), [CNF-84](../../07-conformance.md#additional-contracts-from-the-september-9-review) and [CNF-115](../../07-conformance.md#state-and-recovery--sta-) under the [recovery row](../../07-conformance.md#stage-applicability-and-admission); [CNF-95](../../07-conformance.md#credentials--sec-5) and [CNF-109](../../07-conformance.md#the-channel--sec-11-chn-) under the stage-1 required row, with its route qualifications. Robot rescue/relabel, job-read/attest admission and multi-machine scanning cases retain their separate rows |

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
