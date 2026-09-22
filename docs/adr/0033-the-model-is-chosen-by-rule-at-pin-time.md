# The model is chosen by rule at pin time, and the harness falls back only on availability

`bundle/inference.toml` carries an ordered **candidate order** of model slugs rather than one
slug, and a scheduled job in this repository recomputes what belongs in it and opens a pull
request when the answer changes. At session start the harness takes the highest-ranked
candidate the aggregator still lists; nothing else moves it down the order. Decided 2026-09-22.

## Why

A compiled-in slug is refreshed by the publisher's cadence and by nothing else, and what it
tracks does not hold still: on 2026-09-22 the aggregator listed 369 models, and which of them
exist next month is not knowable from here. Watching a list that long for departures is machine
work. Deciding which weights may provision a machine is not, because `ARC-14` counts weights as
one of three trust layers and [ADR-0004](./0004-one-model-one-machine.md) records model
diversity as the security parameter rather than a preference. This record splits those two jobs
and gives each to the party that can do it.

Two of the criteria are not preferences at all, and they do most of the work. `ARC-31a` says
"The retention tier MUST be requested explicitly on every call", because the aggregator's API
default is the weaker tier — so only models it serves under its zero-retention tier are
eligible. And a harness that drives machines by tool calls cannot use a model without tool
support. Of the 369 listed on 2026-09-22, 109 met both.

## How it works

- **The eligible set** is every model the aggregator lists that is served under its
  zero-retention tier, supports tool calls, and clears the context floor the job carries.
- **The candidate order** is the eligible models the aggregator flags as popular, in its order,
  then the rest of the eligible set newest first, to a fixed depth. The flag is the
  aggregator's editorial judgement and is used as exactly that: it orders the top of the list
  and claims nothing about quality, which no party here measures.
- **The job proposes; it never commits.** It opens a pull request when a candidate leaves the
  eligible set — retired, or its retention tier or tool support changed — and when a new
  entrant clears the floor. `ARC-40` names the publisher's authority over what ships, and a
  scheduled job that edited the bundle itself would hold that authority unnamed.
- **At runtime the order is read for availability and for nothing else.** "Still served" is
  read from the model list's own entries, never from a status code: the aggregator answers an
  unknown path with HTTP 200 and an error body, observed 2026-09-22.
- **The provider is not chosen by any of this.** The aggregator publishes no provider
  vocabulary and names no provider per model, so the requested provider stays a hand-taken
  value, and `CNF-78`'s measurement is owed before one is written.

## Considered options

**An external benchmark feed**, so that the order could rank on quality rather than on an
editorial flag. Rejected, and recorded because it is the obvious answer to "which model is
best": a list fetched at runtime that decides which weights provision every machine is the
shape `SEC-7` refuses when it says of briefs and advisory feed lists that they "MUST NOT be
fetched, configured, or substituted at runtime". Whoever served that feed would steer every
machine this product builds, and `05-trust.md` names no such party.

**Choosing in the browser at session start**, the bundle carrying the rule instead of the list.
It is the only option that fully answers "we do not know what tomorrow lists", and member
diversity falls out of it for free. Rejected for now on two costs: a reviewer of this
repository could no longer read `bundle/inference.toml` and know which model ships, and a
session would stop starting whenever the aggregator's model list did not answer.

**An escalation order rather than an availability order** — the recovery ladder's middle rung,
ordered weakest to strongest and climbing when a session is stuck. Rejected for the first
stage: `SEC-1` conditions that rung on the stronger weights not already running another member,
which needs cross-machine state a one-machine stage does not have.

**The flagged set alone, an empty one failing the build.** Rejected because on 2026-09-22
exactly one eligible model carried the flag, which leaves the availability fallback nowhere to
go on the day it is withdrawn.

## Consequences

**`bundle/inference.toml`'s schema changes** from one model slug to an ordered list, and the
implementation's build gate changes with it: an empty list fails the build where an empty slug
fails it today (ADR-0031).

**`STG-17` needs an amendment.** It says "the first stage offers rungs one and three only, and
says so", reasoning from one model slug. The candidate order does not change that — it is
ordered for availability and not for strength — and the sentence should say so, rather than
leave a reader to infer it from a list that now holds more than one entry.

**A conformance item is owed** for the session-start selection: which candidate was used, what
the exposure ledger (`STA-10`) and the provenance record carry when it was not the first, and
that the choice is read from the list rather than from a status code.

**Popularity is a third party's editorial judgement and the order inherits it.** Every operator
running one bundle converges on the same top candidate, which is the vacuous-diversity case
ADR-0004 names. Tolerable while the stage provisions one machine; worth revisiting at the
second.
