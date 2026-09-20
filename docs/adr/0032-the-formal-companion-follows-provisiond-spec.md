# The formal companion follows provisiond-spec's formal layer, by reference

Selected clauses of this specification are carried as Lean definitions and theorems under
`tools/formal/`, on the decision provisiond-spec recorded as its ADR-0025 (accepted 2026-09-13)
and btc-policy-spec is adopting. Decided 2026-09-16, from `lean-01.md`'s review of the corpus at
`9c58b44`; not yet built (TASKS T30). This record names what is adopted, the two places this
corpus must deviate, and nothing else — the reasoning is provisiond-spec's and is cited rather
than restated, because a second explanation of one decision is how a second normative copy gets
written.

## What is adopted

- **Placement.** `tools/formal/`, inside this repository, under a `tools/` carve-out this
  repository did not previously have: specification only, plus the gates that check it. This
  amends ADR-0031's "never the harness code" by one clause — an executable statement of the
  specification is specification. A separate repository was rejected there for a reason that
  holds here: a check that guards a set has to live with it.
- **Authority is per clause.** A formalized clause's home is its Lean declaration tagged
  `@[req "STA-22b"]`. The Markdown requirement keeps its identifier, its MUST, its rationale and
  its retained traps, and renders the clause; until a rendering gate covers a clause the Markdown
  stays authoritative and the Lean is a checking interpretation.
- **The tags are the record.** `lake exe gate` emits the index of tagged declarations; the
  citations gate resolves backticked `TauWeb.*` names against it. No hand-kept map, no
  identifier family for theorems: a third copy was rejected there and is not opened here.
- **A theorem is never conformance.** No `CNF` identifier appears under `tools/formal/`, and
  the coverage gate counts nothing from it. `07-conformance.md`'s applicability table is
  unchanged.
- **Trust policy, enforced by the gate.** A tagged declaration may depend on `propext`,
  `Classical.choice` and `Quot.sound` and nothing else; `sorryAx` is refused transitively; the
  project declares no `axiom`; `native_decide` is refused outside an `Explore` namespace that may
  hold nothing tagged. No Mathlib until a commit names the theorem that cannot close without it.
- **Every guard a dated amendment added is a parameter**, with two theorems: the bad trace
  refused with the guard, admitted without it. This corpus's "*what this requirement used to
  say*" paragraphs are the inventory.
- **What is not Lean's to carry enters as a hypothesis, never an axiom.** A vendor's behaviour,
  the browser's storage semantics, the aggregator honouring a request.
- **The gate runs with the others, on every push**, under one Nix shell, with a negative control
  per check in CI. The textual gates are ported with it — identifiers, fixtures, obligations,
  coverage, citations — because the formal gate's index has no reader without them, and because
  this corpus has already paid twice for the drift those gates refuse (`00-overview.md`, "two
  renumberings").

## The two deviations

- **No *model*.** Bare *model* is the weights in this corpus and the whole security argument
  rides on it, so the artifact is the **formal companion** and its lifecycle definitions carry
  no *model* in their names. provisiond-spec's *witness*, *assumption*, *property*, *theorem*,
  *decided* and *specification gate* are taken verbatim (`CONTEXT.md`).
- **No marked regions yet.** provisiond-spec's rendering gate keeps a table or worked example in
  a requirement equal to what its declaration emits. This corpus has no formalized table to
  render on the day of this decision; the gate is ported when the first one exists, and until
  then every formalized clause is under the transitional rule above. **The gate
  (`tools/check_regions.py`) landed 2026-09-20 with the tables that triggered it**:
  `ARC-39`'s field table in `delivery-declaration-v1.md` and `STA-22a`'s role table in
  `credential-format-v1.md`, each a `match` region, since both carry prose and the first carries
  conformance citations the companion may never emit. Inside a marked region the declaration is
  authoritative and the Markdown renders it; every other formalized clause stays under the
  transitional rule. **One adaptation**: provisiond refuses a region outside the requirement its
  declaration is tagged with, and here the normative companion carries the table while the
  requirement points at it, so a region may also sit in a document that requirement's body
  links. The test is directional and read from the Markdown, so it opens no second map.

## The inventory, in order

Decided 2026-09-16 with the rest. Built in the order that lets each module be true when it
lands, and the first modules carry the review's own findings as witnesses, as provisiond-spec's
first milestone did.

| # | Module | Clauses | The trap each retains as a negative witness |
|---|---|---|---|
| 1 | Allocation | `STA-22`, `STA-22a`, `STA-22b`, the index rules of `credential-format-v1.md` | One index on two machines (`STA-22`'s own trap); a seed restored from a stale sheet allocating anyway (the guard `STA-22b` gained 2026-09-09, as a parameter with the refused-and-admitted pair); a failed create freeing its index |
| 2 | Declaration presence and meaning | `ARC-39`, `delivery-declaration-v1.md` | An empty inbound list read as "nothing to check" (fixed 2026-09-16). The field table as a total function, totality decided; the first candidate for a marked region |
| 3 | Relay admission | `CHN-15`, `CHN-16`, `CHN-16a`, `relay-protocol-v1.md` | "No dial before OK" as one invariant instead of two (fixed 2026-09-16); a hostname re-entering the dialer after validation |
| 4 | Dispatch and the unresolved barrier | `STA-3`, `STA-4`, `STA-7`, `STA-8`, `STA-24`, `SEC-12`, `STA-20b`, `STG-4`'s confirmation predicates | A lost response to a destructive Robot call followed by the same action under a new call id (the resource key as the parameter: approved entry refuses, call id admits); a second allocation index for the same approved entry; a planned reset offered after a failed journal append; a `boot_id` change read as success; a resolution observed but its append failed, with dispatch resuming; a disposition read as unrestricted dispatch |
| 5 | Host-pin lifecycle | `SEC-11`, `CHN-R1`, `ARC-43` | A rescue pin reused across boots; an installed pin taken from model text; a connection before `/rescue/last` fills |
| later | Attest single-use across restart; exposure reach per domain; handoff reach | `CHN-5`, `STA-10`–`STA-13`, `ARC-19a` | Cloud-route and btc-policy work; nothing in the first stage exercises them |

Module 4 waited on the barrier's level, written as `STA-24` on 2026-09-16 after a two-reader
panel (`docs/review/2026-09-16-barrier-panel.md`); building the fence before that decision
would have proved a false requirement. Nothing in the inventory gates first-stage
construction or completion: the companion is a specification gate, and `07-conformance.md`'s
applicability table does not change.

## How the implementation is compared

Decided 2026-09-16 after a second two-reader panel
(`docs/review/2026-09-16-companion-comparison-panel.md`). The companion's lifecycle definitions
compute the outcomes the specification permits for a sequence of events and faults, so that
tau-web-rust can be compared against them in a test. The comparison is a test and nothing
stronger; the companion proves nothing about a running implementation.

- **The companion emits a witness file per module; the implementation compares against it.**
  `lake exe witnesses` writes each module's tagged witnesses and the bounded enumeration its
  decided properties close over, as JSON, committed under `docs/design/` beside
  `credential-vectors-v1.json` — the pattern this corpus already has. A specification gate
  refuses a committed file that differs from the emission, on provisiond's render-and-regions
  pattern. The implementation reads the files from its pinned `spec/` tree the way it runs
  `spec-checks/`; **no Lean enters its toolchain**, and the files are checks, never inputs the
  build compiles in (ADR-0031).
- **What a witness file carries.** A schema version; the module; the **bound**, rendered from
  the one declaration the decided theorem and the emitter share; and per trace: the `TauWeb.*`
  declarations it came from, resolvable against the `lake exe gate` index; the guard parameters
  as assumptions, name and value; events in, from a closed vocabulary with provenance — operator
  act, model request, adapter observation, storage outcome of an append, lost response, crash,
  replay, import or restore, session succession, disposition — where a lost response and a
  crash are driver instructions and the harness sees only absence; and the expected outcome
  **at each step**, not only at the end: dispatch accepted or refused, the `STA-7`
  classification after a replay, and a projection of harness knowledge in the requirements'
  own vocabulary, never the companion's state layout. Requests carry what a model would send;
  the file never supplies an already-correct resource key, so the request-to-entry mapping is
  what gets compared. Each refused-and-admitted pair appears whole, marked: the comparison
  expects the production core to match the refused trace and to **differ** from the admitted
  one, which is the negative control.
- **What it never carries.** A `CNF` identifier (the rule above, path-independent: the emitter
  lives under `tools/formal/` and its output is still the companion's); a claim about external
  state; a timer value; wire bytes or key material; a mapping to implementation modules.
- **Evidence.** A conformance item may cite a witness file as an input to its test, as `CNF-83`
  cites the credential vectors; a witness file never cites a conformance item. A pass is
  evidence about harness knowledge only — never about external state, never about whether an
  effect ran before its append returned, never about concurrency — and the test record names
  the file, its bound and the implementation revision. The files are an **additional** evidence
  source a conformance item may cite, never the only one it accepts: otherwise module 1 would
  gate the first live rehearsal through `07-conformance.md`'s fixture paragraph, which the
  inventory section above says it does not.
- **Independence** is two implementations of one Markdown that share no code: the companion
  in Lean, the core in Rust. It holds only while the core is written from the requirement text
  and never from the Lean source or the file; a core edited until the file passes has
  collapsed the comparison into self-agreement. The theorem is what makes agreement on the
  sample more than two programs agreeing on a misreading; it does not protect a wrong
  statement, which is what the panels are for.
- **Drift, stated.** A stale pin stays green and means "conformant to spec commit X", a release
  fact rather than a warning. A Markdown change with an unchanged companion stays green until
  the rendering gate covers that clause, under the transitional rule above.

**Considered and not taken.** The implementation's CI running Lean on generated sequences:
exact and live, but nothing above the ceiling that the comparison is a test, at the price of
Lean and Lake in every implementation build and a toolchain crossing a boundary no record asks
for. A scheduled live differential run beside the files: added when someone will read it, since
a green job nobody reads is the check `CNF-3` exists to catch. A random generator with a pinned
seed: a second generator beside the one the decided properties already use, which is the second
copy provisiond deleted. **Proving selected Rust against the companion** through Aeneas
(`lean-01.md` §5, level 3): not adopted and not tracked, a later option once pure Rust modules
exist and stabilise; an open question needs a closure criterion and "when it seems worth it" is
not one.

## Consequences

`CONTEXT.md` gains the vocabulary, and **witness file**, **bound** and **companion comparison**.
TASKS T30 ports `tools/`, `flake.nix`, `AGENTS.md` and `ci.yml` from provisiond-spec and writes
this repository's withdrawn-identifier table for what the identifier gate finds; T31 lands
module 1 with its witness file and the emission gate. ADR-0031's "How the boundary works" gains
the witness files and the two settlements above.
