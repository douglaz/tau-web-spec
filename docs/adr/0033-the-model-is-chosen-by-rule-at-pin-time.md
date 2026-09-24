# The model is chosen by rule at pin time, and the harness falls back only on availability

`bundle/inference.toml` carries an ordered **candidate order** of model slugs rather than one
slug, and a scheduled job in this repository recomputes what belongs in it and opens a pull
request when the answer changes. At session start the harness takes the highest-ranked
candidate the aggregator still lists; nothing else moves it down the order, and a list that does
not answer moves it nowhere. Decided 2026-09-22. Corrected 2026-09-23, after the measurement
that took the two values and an independent-reader review of this record; and 2026-09-24, when
the decisions that measurement left open were taken (TASKS T38).

## Why

A compiled-in slug is refreshed by the publisher's cadence and by nothing else, and what it
tracks does not hold still: the aggregator's list grew by nine models between the two days it
was read (`docs/findings/2026-09-22-provider-routing/`). Watching a list that long for
departures is machine work. Deciding which weights may provision a machine is not: `ARC-14`
says a trust domain is "counted at three configured layers, never as one blended number", the
weights are one of them, and [ADR-0004](./0004-one-model-one-machine.md) says "Model diversity
is the security parameter, not a preference." This record splits those two jobs and gives each
to the party that can do it.

## What the rule is made of

**The eligible set** is every model the aggregator lists that meets three conditions, each with
an owner or with one owed:

- *Zero retention.* Two things, related and distinct. `ARC-31a` says "The retention tier MUST
  be requested explicitly on every call": that is a request parameter, and on this aggregator
  it is `provider.zdr: true`, documented on its `api-docs` page, which also says a model with no
  zero-retention endpoint "will fail to route" — loud, not silent, except one documented
  model-plus-web-search case. The eligibility filter is the other thing: which models the rule
  may pick at all. It is the aggregator's zero-retention **badge** — its `privacyLevel`
  attribute, which by its own documentation marks open-weights models that have a zero-retention
  endpoint and is stricter than "can be routed zero-retention", excluding every Claude and
  almost every GPT — **plus a publisher-kept allowlist** of proprietary models that route
  zero-retention, each named by the publisher and probed by the job. The badge is computable
  from a committed snapshot; the allowlist is the publisher's judgement and says so. Both take an
  owner clause beside `ARC-31a`'s request rule (T37). Until then they are this record's rule.
- *Able to call the harness's tools.* `ARC-43` says "The model's tool set in the first stage is
  exactly four", and a candidate that cannot call them cannot do the work. `ARC-43` owns the
  interface; T37 adds the sentence that a candidate must be able to drive it.
- *Above a context floor.* Neither the value nor an owner exists yet; T37 carries both.

**The candidate order** is the eligible models the aggregator flags as popular, in its order,
then the rest of the eligible set newest first, to a fixed depth. The flag is the aggregator's
editorial judgement and is used as exactly that: it orders the top of the list and claims
nothing about quality, which no party here measures, and nothing about availability, which the
order is otherwise for.

**The counts come from a committed snapshot, never from prose.** `eligible-set.py` in the
finding's directory applies this rule to `models-<date>.json`; what it prints is the count.

**The job proposes; it never commits.** It opens a pull request when a candidate leaves the
eligible set — retired, or its badge or tool support changed, or an allowlisted model stops
routing zero-retention — and when a new entrant clears the floor. `TRU-A1` says "Model
selection ships in the signed bundle", and that is the publisher's; a job that edited the bundle
itself would hold that authority unnamed.

**At runtime the order is read for availability and for nothing else.** The harness reads the
aggregator's model list once, at session start, and takes the highest-ranked candidate it
finds there. "Still listed" is read from the list's own entries, never from a status code: the
aggregator answers an unknown path with HTTP 200 and an error body. If the list does not answer,
the harness calls the first candidate anyway: the list is an optimization and never a gate, an
unreachable catalogue must not become a way to stop every session from starting, and the call
itself fails loudly if the model is gone.

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
refused with `404`; a satisfiable one is served with a `provider` field that follows the pin,
which `SEC-9` names the *reported provider* and uses only to detect a mismatch; the label stays
*requested*. The aggregator documents the routing object on its `api-docs` page and no provider
vocabulary anywhere; a refusal discloses, per model, the providers that serve it. Selecting a
provider also routes the request through the proxy's upstream, which `TRU-E2` now names.

**A fallback is new weights on a machine.** `SEC-1` conditions the ladder's escalation on the
stronger model being one that "is not assigned — and will never be assigned — to any other
machine", and says "Re-entry stays inside this rule the same way". An availability fallback on
a re-entered or successor session is a new configured model on that machine and stays inside
`SEC-1` like any other; the candidate order is never `ARC-16`'s escalation rung, and T37 gives
`STG-17` the sentence that says so.

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
Rejected by the publisher on 2026-09-24: it excludes every Claude and almost every GPT although
they route zero-retention per call; the allowlist admits named ones under the publisher's own
name, and the job probes those and only those.

**Zero-retention capability instead of the badge**, admitting any model for which `provider.zdr`
routes. Rejected: it is not discoverable from the list, only by a paid probe per candidate per
run, so the set would no longer reproduce from a snapshot.

## Consequences

**`bundle/inference.toml`'s schema changes** from one model slug to an ordered list, and the
implementation's build gate changes with it: an empty list fails the build where an empty slug
fails it today (TASKS T29). Until T37 lands the file carries one slug, the rule's top candidate.

**`STG-17` needs an amendment.** It says "the first stage offers rungs one and three only, and
says so", reasoning from one model slug. A list does not change that — it is ordered for
availability and not for strength — and `STG-17` should say so as a rule, not leave a reader
to infer it from a list that now holds more than one entry.

**A conformance item is owed** for the session-start selection — which candidate was used, what
the exposure ledger and the provenance record carry when it was not the first, that "still
listed" is read from the list and never from a status code, and what an unanswered list
produces — after a requirement owns the selection, since a conformance item tests a rule.

**Popularity is a third party's editorial judgement and the order inherits it.** The risk
ADR-0004 names is inside one setup: "If a user configures three inference providers that all
serve the same underlying weights, they have one model, not three, and the honest-majority
assumption is vacuous." An order every machine reads the same way gives every machine of one
setup the same top candidate. Tolerable while the stage provisions one machine; it is the first
thing to revisit at the second.

**The allowlist can change the top of the order the day it is populated.** Most of the models
the aggregator flagged as popular on 2026-09-23 are proprietary and unbadged
(`models-2026-09-23.json`). Today the allowlist is empty and the top candidate is the one
badged model that carries the flag; the day a proprietary model is allowlisted, the aggregator's
popularity order decides whether it takes the top from the open-weights model. That is the
publisher's judgement exercised twice — once in the allowlist, once by accepting the flag's
order — and both are named as such.

**The same party can hold two layers.** Today's provider is the maker of the weights it serves.
The layers stay counted and displayed separately, per `ARC-14`, and `SEC-9` now says the
display marks that machine as the same party at both, counts unchanged. `CNF-41`'s rule that the
provider is "never derived from the model name" cannot be told apart, on screen, from a
requested value that happens to match; only `CNF-78`'s request inspection can, and does.
