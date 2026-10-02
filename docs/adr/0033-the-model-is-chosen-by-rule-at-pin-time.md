# The model is chosen by rule at pin time, and the harness falls back only on availability

`bundle/inference.toml` carries an ordered **candidate order** of model slugs rather than one
slug, and a scheduled job in this repository recomputes what belongs in it and opens a pull
request when the answer changes. At session start the harness takes the highest-ranked
candidate the aggregator still lists; nothing else moves it down the order, and a list that does
not answer moves it nowhere. Decided 2026-09-22. Corrected 2026-09-23, after the measurement
that took the two values and an independent-reader review of this record; and 2026-09-24, when
the decisions that measurement left open were taken (TASKS T38) and a second review read them.

## Why

A compiled-in slug is refreshed by the publisher's cadence and by nothing else, and what it
tracks does not hold still: the aggregator's list read on 2026-09-23 differed from the one read
the day before, whose snapshot was not kept (`docs/findings/2026-09-22-provider-routing/`).
Watching a list that long for departures is machine work. Deciding which weights may provision a
machine is not: `ARC-14` says a trust domain is "counted at three configured layers, never as one
blended number", the weights are one of them, and [ADR-0004](./0004-one-model-one-machine.md)
says "Model diversity is the security parameter, not a preference." This record splits those two
jobs and gives each to the party that can do it.

## What the rule is made of

**The eligible set** has its requirement home in `ARC-31b`; the clauses landed on
2026-09-24. The following records why those conditions were chosen.

- *Zero retention.* Two things, related and distinct. `ARC-31a` says "The retention tier MUST
  be requested explicitly on every call": that is a request parameter, and on this aggregator
  it is `provider.zdr: true`, documented on its `api-docs` page, which also says a model with no
  zero-retention endpoint "will fail to route" — loud, not silent, except at least one documented
  model-plus-web-search case. The eligibility filter is the other thing: which models the rule
  may pick at all. It is the aggregator's zero-retention **badge** — its `privacyLevel`
  attribute, which by its own documentation marks "open-source models that also have a ZDR
  endpoint" and is stricter than "can be routed zero-retention"; `eligible-set.py` prints how it
  falls by owner — **plus a publisher-kept allowlist** of proprietary models that route
  zero-retention, each named by the publisher and probed by the job. The badge is computable
  from a committed snapshot (`ARC-31a`); the allowlist is the publisher's judgement (`TRU-A1a`). The list also carries an `e2e` tier; `ARC-31a` says
  "the strongest tier the browser can request, which is `zdr`".
- *Able to call the harness's tools.* `ARC-43` says "The model's tool set in the first stage is
  exactly four", and a candidate that cannot call them cannot do the work. `ARC-43` owns the
  interface and says a candidate "MUST be able to call this tool set".
- *Above a context floor.* The publisher value is `session.context_floor` in the bundle;
  `ARC-31b` says "A candidate whose listed `context_length` is below the floor is not eligible."

**The candidate order** is the eligible models the aggregator flags as popular, in its order,
then the rest of the eligible set newest first, to a fixed depth. The flag is the aggregator's
editorial judgement and is used as exactly that: it orders the top of the list and claims
nothing about quality, which no party here measures, and nothing about availability, which the
order is otherwise for.

**The counts come from a committed snapshot, never from prose.** `eligible-set.py` in the
finding's directory applies the bundle inputs and selection rule to `models-<date>.json`;
what it prints is the count.

**The job proposes; the publisher lands the change.** `ARC-31b` says "opens a pull
request only when the candidate order changes". The
publisher's authority is `TRU-A1`'s, and a job that edited the bundle itself would hold it
unnamed. `ARC-31b` says "Its credential is the **publisher's own** aggregator account and its
spend the publisher's, never an operator's balance or session key". The workflow commits only on
a proposal branch; the publisher alone decides whether the bundle change lands.

**At runtime the order is read for availability and for nothing else.** The harness reads the
aggregator's model list once, at session start, and takes the highest-ranked candidate it
finds there. "Still listed" is read from the list's own entries, never from a status code: the
aggregator answers an unknown path with HTTP 200 and an error body. If the list does not answer,
the harness calls the first candidate anyway: the list is an optimization and never a gate, an
unreachable catalogue must not become a way to stop every session from starting, and the call
itself fails loudly if the model is gone. The no-match case was settled on 2026-09-24:
`ARC-31b` says "A well-formed list containing none of the signed candidates is also treated as
unanswered."

That read is fetched external content, and `SEC-8` says "All tool output and fetched external
content MUST be typed as untrusted and MUST NOT authorize an action on its own, declare
capabilities, or override policy". It complies by construction: the list authorizes nothing —
the signed candidate order is the authorization — and reading it can only remove candidates
from consideration, never add one. `SEC-7` says of briefs and advisory feed lists that they
"MUST NOT be fetched, configured, or substituted at runtime"; the model list is neither, and its
source is `TRU-E2`, the party every inference call already goes to. That is also what separates
this read from the benchmark feed rejected below: the feed would decide *which* weights, this
decides only *whether* a signed candidate is still there.

**The provider is not chosen by any of this.** It is a hand-taken value. Measured before it was
written (`docs/findings/2026-09-22-provider-routing.md`): an unsatisfiable `provider.only` is
refused with `404`; a satisfiable one is served with a `provider` field that follows the pin.
`SEC-9` says "A response's own report of the provider is compared, never shown as a count", and
the label stays *requested*. The aggregator documents the routing object on its `api-docs` page,
and neither page read on 2026-09-23 publishes a provider catalogue or a mapping from the names
it reports to the slugs it accepts; a refusal discloses, per model, the providers that serve it.
Selecting a provider also routes the request through what `TRU-E2` now names, by inference, as
the proxy's upstream.

**A fallback is new weights on a machine.** `SEC-1` conditions the ladder's escalation on the
stronger model being one that "is not assigned — and will never be assigned — to any other
machine", and says "Re-entry stays inside this rule the same way". An availability fallback on
a re-entered or successor session is a new configured model on that machine and stays inside
`SEC-1` like any other; `STG-17` says "the harness **MUST NOT** use the
candidate order as that rung".

## Considered options

**An external benchmark feed**, so that the order could rank on quality rather than on an
editorial flag. Rejected, and recorded because it is the obvious answer to "which model is
best": a list fetched at runtime that decides which weights provision every machine is the
shape `SEC-7` refuses for briefs and feed lists, and `05-trust.md` names no such party.

**Choosing in the browser at session start**, the bundle carrying the rule instead of the list.
It is the only option that fully answers "we do not know what tomorrow lists", and member
diversity falls out of it for free. Rejected for now on two costs: a reviewer of this
repository could no longer read `bundle/inference.toml` and know which model ships, and a
session would depend on the aggregator's model list to start at all.

**An escalation order rather than an availability order** — the recovery ladder's middle rung,
ordered weakest to strongest and climbing when a session is stuck. Rejected for the first
stage: `SEC-1`'s condition needs cross-machine state a one-machine stage does not have.

**Filters only; the publisher orders the shortlist; the job only watches the set.** The
reviewer's recommendation, and the option that keeps the ordering judgement entirely with the
publisher. Rejected by the publisher: a hand-ordered list ages at the rate it is tended, and the
point of the rule is a criterion that does not wait on the publisher's attention.

**The flagged set alone, an empty one failing the build.** Rejected because on both days
exactly one eligible model carried the flag, which leaves the availability fallback nowhere to
go on the day it is withdrawn.

**The badge alone, as the retention filter.** The reviewer's recommendation: it is the only
zero-retention fact the list carries, so the set stays reproducible from a snapshot, and badged
models are open weights served by many providers, which gives `ARC-14`'s provider layer room.
Rejected by the publisher on 2026-09-24: it excludes models that route zero-retention per call
(`eligible-set.py` prints which owners' models carry the badge), and the allowlist admits named
ones under the publisher's own name. This reintroduces a hand-kept list, which the option above
was rejected for; the difference is that this list admits candidates and does not order them.

**Zero-retention capability instead of the badge**, admitting any model for which `provider.zdr`
routes. Rejected: it is not discoverable from the list, only by a paid probe per candidate per
run, so the set would no longer reproduce from a snapshot.

## Consequences

**2026-09-24 — per-entry requested providers.** The model became a list on 2026-09-22,
while the provider remained bundle-wide. On 2026-09-24 the publisher reported that requesting
`z-ai` with `xiaomi/mimo-v2.6-flash` or `deepseek/deepseek-v4.1-flash`, using the method of
cases C and E in `docs/findings/2026-09-22-provider-routing.md`, returned 404,
"No allowed providers are available for the selected model". This is the publisher's reported
measurement, not a new experiment here. The publisher then chose per-entry pins; the committed
values live in `bundle/inference.toml`, and the amendment's owners are `ARC-31b` and `TRU-A1a`.

**`bundle/inference.toml` carries the candidate schema.** T37 landed the ordered entries
with separate slug, maker and provider, the allowlist with its own pins, context floor and
depth, and the daily proposing workflow. The implementation repository's `build.rs` migration remains owed at its spec pin
bump: consume the new schema and reject missing or empty candidate or allowlist providers, alongside
the existing empty candidate-list and context-floor gates, and enforce selection at runtime.
No implementation build gate changed in this repository (ADR-0031).

**The first-stage and conformance amendments landed with the rules.** `STG-17` says "the first
stage offers rungs one and three only, and says so". Fixtures: `CNF-88` (selection),
`CNF-89` (comparison), `CNF-90` (same-party mark). These are conformance obligations, not evidence of a
running harness. The same-party fixture requests a provider that is not the maker; with the
current top candidate and provider, deriving the provider from the model name would pass
`CNF-78`'s request inspection identically.

**Popularity is a third party's editorial judgement and the order inherits it.** The risk
ADR-0004 names is inside one setup: "If a user configures three inference providers that all
serve the same underlying weights, they have one model, not three, and the honest-majority
assumption is vacuous." An order every machine reads the same way gives every machine of one
setup the same top candidate. Tolerable while the stage provisions one machine; it is the first
thing to revisit at the second.

**The allowlist can change the top of the order the day it is populated.** `eligible-set.py`
prints how many of the models the aggregator flags as popular are unbadged; most are, and the
snapshot names them. Today the allowlist is empty and the top candidate is the one badged model
that carries the flag; the day an allowlisted model carries the flag, the aggregator's popularity
order decides whether it takes the top from the open-weights model. Two more things follow.
Some of the models an allowlist would admit — the aggregator's documentation names "some
Anthropic and Gemini variants" — are the ones it says `only` may be overridden for, so the
*requested* label is weakest exactly there. And proprietary models are usually served by their
maker, which is `SEC-9`'s same-party case by default. All of it is the publisher's judgement
exercised twice — once in the allowlist, once by accepting the flag's order — and both are named
as such.

**The same party can hold two layers.** The committed entries request their weights' makers.
The layers stay counted and displayed separately, per `ARC-14`; `SEC-9` says "When the requested
provider is the maker of the weights, the display MUST say so on that machine", reading the
maker from the bundle, never from the slug (`CNF-41`).
