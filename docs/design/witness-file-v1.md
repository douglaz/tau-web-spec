# Witness file v1

The schema of the files the formal companion emits, one per module, committed beside this
document as `<module>-witnesses-v1.json` (ADR-0032, "How the implementation is compared" —
what a witness file carries, what it never carries, and how the implementation reads it are
decided there and not restated here). `lake exe witnesses` writes them from `tools/formal/`;
`tools/check_witnesses.py` refuses a committed file that differs from the emission, and
`tools/check_fixtures.py` parses each as a document. The first is
[`allocation-witnesses-v1.json`](./allocation-witnesses-v1.json), from `TauWeb.Allocation`.

## The file

One JSON object. The header is pretty-printed and every trace is one line, so a diff names
the trace that moved.

| Member | What it holds |
|---|---|
| `schema` | `1`. A change to any shape below is a new version and a new file name. |
| `module` | The inventory name, lower-case: `allocation`. |
| `namespace` | The Lean namespace the traces' declarations live in. |
| `bound` | `declaration`, the tagged `bound` the decided property and the emitter share (`TauWeb.Allocation.bound`); `events`, its value, rendered; `alphabet`, the events the enumeration draws from. |
| `witnesses` | The named traces, one per decided witness, in the order the module states them. |
| `enumeration` | Every trace of at most `bound.events` events over `bound.alphabet` from the initial journal, shortest first — the traces `TauWeb.Allocation.bounded_nodup` decided over. |

Both arrays hold traces of one shape:

| Member | What it holds |
|---|---|
| `declarations` | The `TauWeb.*` theorems the trace came from, resolvable against the `lake exe gate` index. Every name the file carries — here, in `bound.declaration`, in `pair.with` — is one the emitter checked against the tags (`Witnesses.lean`). |
| `assumptions` | Each guard parameter of the module by name, with the value the trace runs under. Allocation has one, `restoredAllocatesNone`. |
| `pair` | Present on a refused-and-admitted pair: `side`, `refused` or `admitted`, and `with`, the other side's declaration. What the comparison expects of each side is ADR-0032's. |
| `start` | The journal before the first event, in the projection below. Most traces start from the fresh seed; the exhaustion witness starts one below the index limit. |
| `steps` | One object per event, in order: `event`, the outcome members for that event kind, and `journal`, the projection after the step. |

## Events

Each `event` has a `kind` and a `provenance` from ADR-0032's closed vocabulary; the members
beside them are the event's arguments.

| `kind` | `provenance` | Arguments | Outcome members on the step |
|---|---|---|---|
| `allocate` | model request | `family` | `allocation`: `admitted` with `identity`, or `refused` |
| `created` | adapter observation | `identity` | — |
| `failed` | adapter observation | `identity` | — |
| `destroyed` | adapter observation | `identity` | — |
| `export_sheet` | operator act | — | — |
| `restore` | import or restore | — | — |
| `replace` | operator act | — | — |

`allocate` carries the family and nothing a model would send beyond it: `STA-22b` decides the
index, not the request, so the request-to-entry mapping ADR-0032 has the comparison exercise
is module 4's, not this file's.

What is compared at a step is `journal`. An observation the journal cannot apply — `created`
for an identity never reserved, `destroyed` for one never created, `restore` with no sheet
exported — leaves it as it was, and the enumeration holds such traces because the alphabet is
closed under order. Whether the core refuses, ignores or flags the observation is its own
business; its journal after the step is what must match, so a refusal that changes nothing
is not a mismatch.

## The projection

`journal`, `start` and every `identity` are harness knowledge in `STA-22b`'s vocabulary and
never the companion's state layout: what it holds beyond the journal — the exported sheet,
the seeds generated, every identity ever issued — is the theorems' business and not in the
file.

| Member | Meaning |
|---|---|
| `seed` | The ordinal of the seed in the trace: `0` the initial seed, each Replace the next. Never a seed identifier and never key material. |
| `derivation_version` | The credential format's derivation version, `1`. |
| `family` | `machines`, `passes` or `handoffs`. |
| `index` | The family's index. |
| `next_unused` | The next unused index per family, the three families as members. |
| `entries` | The allocated entries oldest first, each an identity with `status`: `reserved`, `created`, `failed` or `destroyed`; the last two are `STA-22b`'s tombstones. |
| `restored_from_import` | Whether the journal was imported after loss of the canonical one and no Replace has happened since — the state the restored-seed guard reads. |
