# The implementation order, as the specification once kept it

*Archived 2026-11-04. Non-normative: nothing here gates anything.*

The owner's direction, 2026-11-04: "Remove/archive the stages. We should focus on describing
the system. The implementation order will be decided later elsewhere."

The specification now describes paths and capabilities. Each one is admitted by its own rows
in [`07-conformance.md`](../../07-conformance.md), and the tenants, the dedicated path
offered to an operator and a post-harness handoff profile form one admission group
(`STG-23`). What follows is the order the specification used to carry, kept as it read on
2026-11-04 so that dated records that cite stages stay readable. Where a stage below named a
gate, that gate now lives in the row or the admission group that the specification names; no
gate was dropped with the order.

## The stage list (06-first-stage.md, "The stages")

The work was staged as the list below set out, re-drawn on 2026-10-05 around the general
case: an operator with a goal and no tenant
([ADR-0034](../adr/0034-general-case-first-tenants-are-optional-skills.md)).

- **Stage 0 — the probes**, run alongside construction. The LNVPS probe followed `OPN-24`;
  its paid phase B ran on 2026-10-11 and LNVPS passed; `CHN-R7` admits its route. The Omarchy
  question closed by restating stage 1 on plain Arch (`OPN-25`). The separate attest
  first-boot experiment (`OPN-3`) informs vendors that accept boot configuration, but did not
  gate stage 1.
- **Stage 1 — the owner's scenario, with no tenant** (`STG-21`), now the LNVPS path.
- **Stage 2 — a vendor with no adapter** (`STG-22`), now the untyped-scope, jump-host and
  sets-above-one capabilities.
- **Stage 3 — tenants, as skills** (`STG-23`), now the admission group.

Typed came before untyped for a reason of order, not of preference: an untyped vendor scope
needs the jump host for its machines' first contact (`SEC-4`), and the jump host needs a jump
vendor whose creation the harness composes through a typed adapter and whose host key it can
pin by a route `CHN-R6` admits. That dependency is still stated in `STG-22`; only the order is
archived.

## After the first stage (06-first-stage.md)

`STG-22` and `STG-23` said what stages 2 and 3 bring. Both reuse the channel, the journal and
the delivery check that stage 1 proves; neither is a subset of it.

## The roadmap (ADR-0034, "The roadmap follows")

The probes came before stage 1, a vendor with no adapter after it — where the browser can
reach its API — and tenants last. The dedicated path ADR-0018 made the first stage is the
construction test bed: its rehearsal evidence and its install brief stand, and it gates
offering a dedicated server to an operator rather than gating the first stage.

## Status and the next move (08-open-questions.md)

The installation and identity-chain rehearsal ran on a disposable dedicated server on
2026-09-08 (`docs/findings/2026-09-08-first-stage-rehearsal.md`). Both pinned SSH hops closed;
`OPN-6` is closed. The Rust/WASM SSH and pinned-TLS spikes also ran, including physical
Android evidence. Robot's browser route is the pinned TLS tunnel, not direct CORS fetch.

Construct the integrated harness from those results and the v1 credential/storage contracts,
using the dedicated path as the test bed. Both LNVPS probe phases are recorded, and LNVPS
passed its stage-1 target criteria on 2026-10-11 (`OPN-24`); `CHN-R7` admits the route, and
its integrated conformance remains open. No further probe is needed for admission. The attest
first-boot finding stands for applicable routes (`OPN-3`), and the Omarchy question closed on
plain Arch (`OPN-25`). Write the generic lockdown checklist (`OPN-14`). The live rehearsal has
not demonstrated the harness, a goal-driven install, local unlock, or interrupted-install
convergence. Complete the stage-1 conformance subset before claiming delivery; do not repeat
the already-closed identity-chain probe as a construction gate.
