# Witness file v1

The schema of the files the formal companion emits, one per module, committed beside this
document as `<module>-witnesses-v1.json` (ADR-0032, "How the implementation is compared" —
what a witness file carries, what it never carries, and how the implementation reads it are
decided there and not restated here). `lake exe witnesses` writes them from `tools/formal/`;
`tools/check_witnesses.py` refuses a committed file that differs from the emission, and
`tools/check_fixtures.py` parses each as a document. So far,
[`allocation-witnesses-v1.json`](./allocation-witnesses-v1.json) from `TauWeb.Allocation`,
[`declaration-witnesses-v1.json`](./declaration-witnesses-v1.json) from `TauWeb.Declaration`, and
[`relay-witnesses-v1.json`](./relay-witnesses-v1.json) from `TauWeb.Relay`.

## The file

One JSON object. The header is pretty-printed and every trace is one line, so a diff names
the trace that moved.

| Member | What it holds |
|---|---|
| `schema` | `1`. A change to any shape below is a new version and a new file name. |
| `module` | The inventory name, lower-case: `allocation`, `declaration`, `relay`. |
| `namespace` | The Lean namespace the traces' declarations live in. |
| `bound` | `declaration`, the tagged `bound` the decided property and the emitter share, and its value rendered under the module's own members. Allocation (`TauWeb.Allocation.bound`): `events`, the number, and `alphabet`, the events the enumeration draws from. Declaration (`TauWeb.Declaration.bound`): `base`, the declaration and machine every case starts from; `presences`, per field, what the field is swept through, `missing` written as that word since a list has no absent member; `observations`, what the machine is made to show for it; `tenancies`. Relay (`TauWeb.Relay.bound`): `events`, the number; `alphabet`; and `start`, the opened connection every trace of the enumeration runs from. |
| `witnesses` | The named traces, one per decided witness, in the order the module states them. |
| `enumeration` | The traces the module's decided property closed over. Allocation: every trace of at most `bound.events` events over `bound.alphabet` from the initial journal, shortest first (`TauWeb.Allocation.bounded_nodup`). Declaration: one full check per case of the sweep, fields in the table's order, each field through each presence, observation and tenancy (`TauWeb.Declaration.bounded`). Relay: every trace of at most `bound.events` events over `bound.alphabet` from `bound.start`, shortest first (`TauWeb.Relay.bounded`). |

Both arrays hold traces of one shape:

| Member | What it holds |
|---|---|
| `declarations` | The `TauWeb.*` theorems the trace came from, resolvable against the `lake exe gate` index. Every name the file carries — here, in `bound.declaration`, in `pair.with` — is one the emitter checked against the tags (`Witnesses.lean`). |
| `assumptions` | Each guard parameter of the module by name, with the value the trace runs under, and each hypothesis the module takes rather than owns. Allocation has one guard, `restoredAllocatesNone`; declaration has one, `emptyMeansPerField`; relay has one, `dialRequiresAuthAccepted`, beside `special`, `ownAddress` and `resolve` — the value `CHN-16a`'s pinned tables and the relay's resolver take for the trace, since the module quantifies over them. |
| `pair` | Present on a refused-and-admitted pair: `side`, `refused` or `admitted`, and `with`, the other side's declaration. What the comparison expects of each side is ADR-0032's. |
| `start` | The state before the first event, in the projection below. Allocation: the `journal` — most traces start from the fresh seed; the exhaustion witness starts one below the index limit. Declaration: the `declaration` and the `machine` the check reads, and the empty `record`. Relay: the `challenge` as an ordinal, the `destination` the path parsed to, what the pipeline `classified` it as, the `pass` the operator's key holds, and the opened `connection`. |
| `steps` | One object per event, in order: `event`, the outcome members for that event kind, and the projection after the step — `journal` for allocation, `record` for declaration, `connection` for relay. |

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
| `check` | adapter observation | `field` | `verdict`: `refused`, `blocked`, `finding` or `pass` |
| `deliver` | model request | — | `delivered` |
| `auth` | operator act, or replay | `destination`, `key`, `event_kind`, `relay_tag`, `within_skew`, `signature_verifies`, `answers_challenge` | `auth`: `accepted`, `refused` or `ignored` |
| `dial` | adapter observation | `connected` | `dial`: `dialed` or `refused` |
| `app_frame` | operator act | — | `forwarded` |

An `auth` event's provenance is `replay` exactly when `answers_challenge` is `false`: a frame
that verifies and answers another connection's challenge is the replay. `ignored` is an AUTH the
connection did not take as step 2 — one arriving past it, or on a connection a path that does
not parse already closed. `dial` carries whether the TCP connection came up, which is the
adapter's answer and not the relay's decision; `refused` there is a dial the connection did not
make.

`allocate` carries the family and nothing a model would send beyond it: `STA-22b` decides the
index, not the request, so the request-to-entry mapping ADR-0032 has the comparison exercise
is module 4's, not this file's.

What is compared at a step is the projection after it. For allocation, an observation the journal cannot apply — `created`
for an identity never reserved, `destroyed` for one never created, `restore` with no sheet
exported — leaves it as it was, and the enumeration holds such traces because the alphabet is
closed under order. Whether the core refuses, ignores or flags the observation is its own
business; its journal after the step is what must match, so a refusal that changes nothing
is not a mismatch.

## The projection

### Allocation

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
| `record` | `verdicts`, per field checked so far; `delivered`, whether delivery was reached. `refused` is the declaration's own fault (a field absent, a wrong shape, a version other than 1, spendable declared on a multi-tenant machine); `blocked` is `unspecified`; `finding` is a difference from the declaration. |

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

