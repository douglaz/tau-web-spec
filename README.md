# tau-web

Design work for a client-side AI harness that lets someone with only a phone provision and
operate real infrastructure, without trusting any party that could act on their behalf.

**That is the goal, not an achieved property.** Several parties are still trusted, and the
specification names each of them. The harness's own claim is about isolation: a model's blast
radius is the machines its weights have touched, plus any approved credential scope, plus any
tenant secret placed on those machines — and no session reaches a machine it is not bound to
through anything the harness controls. The vault claim — *no single model provisioned enough
members to reach the threshold* — belongs to btc-policy, the tenant that stacks it on top.
"Verified" is not a claim this design can make.

No harness code here, by decision (ADR-0031): the implementation is
[`douglaz/tau-web-rust`](https://github.com/douglaz/tau-web-rust), which pins this repository
by commit as its `spec/` submodule. This repository holds the specification, the domain language,
the decisions taken so far, and the reasoning that produced them. `bundle/` holds the
publisher-chosen values the implementation compiles in, `prototypes/` holds throwaway spikes
that answer open questions by running, `docs/findings/` holds what they found,
`docs/briefs/` holds draft briefs written from those runs, not yet in any bundle, and
`tools/` holds the gates that check the specification and, under `tools/formal/`, the formal
companion (ADR-0032): `nix develop --command bash tools/check-all.sh` runs them all, the
formal gate first.

`tau-web` is a working name.

## Start here

**[`00-overview.md`](./00-overview.md)** — the problem, the audience, the constraints, and the
map to everything else.

The specification is split by topic, and every requirement carries a stable identifier so that
`SEC-1` means the same rule wherever it moves:

| | |
|---|---|
| [`01-architecture.md`](./01-architecture.md) | How the system is put together |
| [`02-channel.md`](./02-channel.md) | Reaching a machine, and the five routes to a pinned host key |
| [`03-state-and-recovery.md`](./03-state-and-recovery.md) | Surviving a killed worker, and a lost phone |
| [`04-security-model.md`](./04-security-model.md) | The invariants, the credential inventory, the claim |
| [`05-trust.md`](./05-trust.md) | Who must still be trusted, and who chose them |
| [`06-first-stage.md`](./06-first-stage.md) | What gets built first, and what it must show |
| [`07-conformance.md`](./07-conformance.md) | What an implementation must demonstrate |
| [`08-open-questions.md`](./08-open-questions.md) | Everything still unknown, and what would close it |

[`docs/tenants/`](./docs/tenants/) holds one profile per tenant (`ADR-0030`).

[`executive-summary.md`](./executive-summary.md) is a shorter read for the shape without the
detail. [`CONTEXT.md`](./CONTEXT.md) is the glossary. [`TASKS.md`](./TASKS.md) is the open
work.

## The two intended tenants

- [btc-policy](https://github.com/douglaz/btc-policy) — self-hosted Bitcoin custody. Standing
  up a federation of policy co-signers means provisioning and hardening several machines at
  several vendors, which a non-technical operator can neither do nor delegate, because a
  single party that provisions every member has defeated the federation.
- [lnrent](https://github.com/douglaz/lnrent) — server rental over Bitcoin. An operator who
  cannot stand up the daemon cannot participate, and the project keeps AI out of its serving
  path by design, so any AI help has to live on the user's side. **tau-web replaces that
  project's current provisioning path**, which holds a cloud vendor token on the machine — the
  arrangement `SEC-3` exists to forbid.

The installation rehearsal ran on a disposable dedicated server on September 8, 2026; both
pinned SSH hops closed. Harness construction can start. The integrated harness, interrupted
resume, lockdown and tenant delivery remain unproven. The next work is construction plus the
lnrent declaration/checklist and briefs 2–3; `07-conformance.md` defines first-stage completion.

## Requirement conventions

Requirements use RFC 2119 keywords: **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**,
**MAY**. Each is tagged with a stable identifier so it can be cited in code review, tests and
issue trackers. `tools/check_ids.py` reads every shape below and refuses a duplicate, a
citation nothing defines, a gap in a sequence not listed as withdrawn, an identifier far above
its neighbours, a reference to an ADR that does not exist, and a conformance item with no tier.
`tools/check_citations.py` refuses a quoted attribution — `` `X` says "…" `` — whose target's
body does not contain the quote, and ratchets unquoted ones against `tools/citation-baseline.json`;
`tools/check_coverage.py` counts the requirements no conformance item cites and ratchets that
count against `tools/coverage-baseline.json`. Each baseline records a date and a reason, and is
rewritten with `--write-baseline DATE REASON`, deliberately.

A formalized clause's home is its Lean declaration in `tools/formal/`, tagged `@[req]` with
the identifier it formalizes (ADR-0032). `tools/check_formal.sh` runs first: it refuses a
`CNF` identifier anywhere in the tree and a module under `TauWeb/` the umbrella never
imports, builds, and runs `lake exe gate`, which refuses a tagged declaration depending on
any axiom beyond `propext`, `Classical.choice` and `Quot.sound` — so a `sorry` that
`lake build` accepts is red — a `native_decide` outside `TauWeb.Explore`, and an empty index.
The index it writes, one line per tagged declaration, is the list of what is carried;
`tools/check_citations.py` refuses a backticked `TauWeb.*` name the index does not resolve.
The same run emits the witness files (`docs/design/witness-file-v1.md`), and
`tools/check_witnesses.py` refuses a committed one under `docs/design/` that differs from
the emission.

It also emits the **marked regions**, and `tools/check_regions.py` refuses a table between
`<!-- formal: TauWeb.Render.… -->` and `<!-- /formal -->` that is not what its declaration
emits. `ARC-39`'s field table and `STA-22a`'s role table are marked, each in the normative
companion its requirement links, and the gate prints what it rendered. Each is compared on the tokens the declaration determines —
a field's shape, a role's family, credential and secret — so a row's prose and its conformance
citations stay the document's. The gate also refuses a region naming a declaration the index
does not carry, one sitting where its requirement neither defines nor links, a declaration
rendered twice, a malformed marker, and an emitted region no document renders.

| Prefix | Domain |
|---|---|
| `OVR-n` | Overview and scope |
| `ARC-n` | Architecture |
| `CHN-n` | The channel; `CHN-Rn` is one of the routes to a pinned host key |
| `STA-n` | State and recovery |
| `SEC-n` | Security model; `SEC-Tn` is a tenant rule now in btc-policy's profile; `SEC-CLAIM` is the claim itself |
| `TRU-Un`, `TRU-En`, `TRU-An` | Trust: unavoidable, elective, and added by this product |
| `STG-n` | The first stage |
| `CNF-n` | Conformance items |
| `OPN-n` | Open questions |

A letter suffix (`STA-22a`, `TRU-E8a`) is an amendment that stands beside its parent and is
cited on its own. A conformance item carries a tier — **BLOCKING**, **PRE-SCALE** or
**DEFERRED**, as `07-conformance.md`'s tiering section defines them — except under "Build and
gate", which precedes the tiering rule, and "Measurements", which are recorded rather than
passed. Tiers describe severity; `07-conformance.md`'s applicability table says what gates a
stage.

### Identifiers are append-only. Text is not.

An identifier is never reused and never renumbered. It costs nothing, and it is what makes a
citation durable across the topic files, the decision records, the tenant profiles and the
implementation's tests; `00-overview.md` records the two renumberings that already cost review
rounds spent re-verifying what pointed where. Any occurrence of an identifier in a document is
a citation, backticked or not: a Mermaid note cannot backtick, and the gate reads it too.

**Deleting the text is not reusing the number.** The gap in the sequence *is* the tombstone. A
deleted identifier goes in the table below so an old citation still resolves, and
`tools/check_ids.py` reads that table — an identifier may be absent from the documents only if
it is listed there, and an identifier listed there may not be defined again.

**A moved requirement leaves a pointer, not a copy.** When a rule moves to a tenant profile
(ADR-0030), its old home keeps one line — `**ARC-23** Moved to the btc-policy tenant profile,
… slot "Delivery declaration"` — so the identifier still resolves. The pointer is not a
definition and not a withdrawal; the gate requires it to point at a definition that exists.
`ARC-20`, `ARC-23` and `SEC-T1`–`SEC-T4` are of this kind.

### Withdrawn identifiers

Deleted from the documents. Never reused. Listed so an older citation still resolves.

| Identifier | Was | Why it went |
|---|---|---|
| `STG-8` | A first-stage criterion requiring a real tenant outcome — a published listing and a delivered order — or a written statement of why not | Both halves were wrong: the first tested lnrent rather than tau-web, the boundary ADR-0016 draws, and the second was an opt-out an essay could satisfy. `STG-7` against `ARC-17` carries what the harness owes; `CNF-49` carries that a declaration exists. `06-first-stage.md` keeps the retirement note |

Two rows of `SEC-5`'s credential table are retired in place, struck through, keeping their row
numbers because prose cites them by number: row 8, the drop-box collection token, went with the
drop-box (`CHN-4`); row 13, the injected SSH host private key, went when `CHN-R3` was abandoned.
They are rows, not identifiers, and the gate does not read them.
