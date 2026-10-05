# The general case comes first: a tenant is an optional skill, and a goal is enough to act on

The harness works for an operator who has a goal and nothing else: "launch a VPS paid in
Bitcoin and install Hermes on Omarchy", with no tenant and no brief keyed on any of it. A
tenant is skill-shaped content compiled into the signed bundle — briefs that make installing
its software faster and more reliable, and presets for the facts its machines carry — and it
improves that path without being a precondition for it. Decided 2026-10-04 and 2026-10-05.

This amends [ADR-0016](./0016-the-harness-isolates-and-counts-tenants-set-thresholds.md) and
[ADR-0030](./0030-tenant-specific-rules-live-in-a-tenant-profile.md), and supersedes
[ADR-0018](./0018-first-stage-is-one-lnrent-box-on-dedicated.md).

## Why

The corpus had come to read as though a machine could exist only inside a tenant. A delivery
declaration had to be supplied by one. Machine class and access model were values a tenant's
profile preset. The first stage was one tenant's box. And the one case with no tenant, ad hoc
use, was a profile with every slot filled in advance for a machine that serves nothing. The
person the product is for — someone with a phone who wants a machine that is theirs — arrives
with a sentence, not with a tenant.

What the harness acts on never needed a tenant. It needs facts about a machine: its
class, its access model and its delivery declaration. A tenant is one source of them. The
operator, answering the harness's own questions and approving a proposal in plain language, is
the other.

## The decision

**Every machine runs under a profile, and a tenant is optional.** `ARC-44` says "Every machine
runs under a profile, and a tenant is optional". ADR-0030's schema stands and so does its
rejection of a machine with no profile at all: a machine with no tenant runs under the
publisher's built-in ad-hoc profile, whose per-machine slots the operator fills. `CNF-49` is
untouched in what it refuses — `CNF-49` says "A machine with no declaration does not pass,
because there is nothing to measure against" — and both of ADR-0030's guards survive: a
declaration never widens what the harness gates, and the journal holds the declaration in
force.

**Those facts, without a tenant.**

- *Machine class* is asked. `ARC-36a` says "The model MAY propose a tightening, single-purpose
  to multi-tenant, and nothing else". The questions are the harness's, nothing is preselected,
  and an operator who is not sure has a multi-tenant machine.
- *Access model* is maintained. `ARC-27` says "sealing cannot be undone, so it needs a tenant
  whose own design calls for it".
- *The delivery declaration* is per machine. `ARC-39` says "Every machine MUST have a
  **delivery declaration**"; with no tenant the model proposes it from the goal, starting from
  the ad-hoc profile's signed minimum, and the operator approves it.

**A goal is not a brief.** `ARC-11` still locks briefs into the bundle, for the reason it
always gave: one document steering every machine is the one place diversity buys nothing. A
goal escapes that reason only while it stays one operator's instruction to one session.
`ARC-11a` says "A goal steers one session's bound set and nothing else", "A goal is never
imported, shared or reused", and "A goal MUST be refused for a machine under a profile that
declares an independence bound".

**The roadmap follows.** `STG-21` says "Stage 1 is the owner's scenario: one goal, one machine,
no tenant". The probes come before it, a vendor with no adapter after it — where the browser can reach
its API, as `STG-22` words it — and tenants last
(`06-first-stage.md`). The dedicated path ADR-0018 made the first stage is the construction
test bed: its rehearsal evidence and its install brief stand, and it gates offering a
dedicated server to an operator rather than gating the first stage.

## Considered options

**Keep a tenant mandatory**, and treat the operator's own scenario as a third tenant somebody
has to write. Rejected: it puts a release between an operator and any software nobody has
written a brief for, which is most software, and it makes the publisher the author of every
use the product will ever have.

**Reverse ADR-0030 and let a machine run with no profile.** ADR-0030 had already rejected
"Optional profile, with ad hoc use running without one", because it opens a second integration
path and puts a hole in "no declaration, no delivery". That objection still holds, so the
record is amended instead of reversed: the profile stays, and what changes is who fills its
per-machine slots.

**Let the operator supply briefs.** Rejected where ADR-0005 rejected it — "Fetched or
user-supplied, unsigned. Rejected outright" — and the same objection is why a goal may not be
imported, shared, stored as a template, or applied to a second session. A goal pasted from
somewhere else into many sessions is a socially distributed brief with no signature.

**Have the model propose the machine class and the operator approve it.** Rejected: the model
would be framing the question that switches a harness gate on or off, and an operator approving
a sentence cannot tell a wrong class from a right one. The harness asks in its own words, the
unsure answer is the strict one, and the model may only tighten.

**A third class, "unknown", for an operator who cannot answer.** Rejected for the default that
costs nothing: multi-tenant removes spendable key material, and a machine that needs no wallet
never notices.

**Seal a machine on the operator's say, or the model's.** Rejected. Sealing is irreversible,
and a machine is safe to seal only when its software was designed never to need a hand again.
That is a tenant's design, not an approval.

**Count a check the model wrote as a check.** Rejected: `ARC-43` exists because a value the
harness relies on cannot come from model text, and a model-written command that reports its
own success is that. Such a check is run and shown as a report.

**Treat a fetched README as instructions.** Rejected: it is fetched external content, typed
untrusted, and it informs work the goal already authorized.

**Keep the lnrent box on a dedicated server as the first stage.** Rejected as the *first*
stage and kept as a test bed. Its argument was that dedicated is the only place the identity
chain closes; that is still true of retrieve, and it stopped being a reason to go there first
once a first contact with no pin became refused rather than a last resort
([ADR-0036](./0036-first-contact-is-never-trusted-through-the-relay.md)) — attest has to run
before anything ships on a cloud vendor either way.

**Untyped vendors before typed ones**, since the general case is any vendor. Rejected on
order, not on merit: an untyped vendor scope needs the jump host, and the jump host needs a
vendor whose creation the harness composes, plus attest.

## Consequences

**The first stage has no tenant in it.** lnrent's declaration, the tenant daemon's brief and
the Robot lockdown checklist stop gating it and gate the third stage. What the first stage
needs instead is listed in `STG-21`, and the probes that stand in front of it are stage 0's: the first vendor,
attest on a real first boot, and the distribution on a server (`OPN-24`, `OPN-3`, `OPN-25`).

**The publisher's seat narrows by one power.** `ARC-40` still records that the publisher
decides which tenants exist. It no longer decides whether an operator can act at all.

**No brief is a weaker mode, and is shown as one** (`SEC-14`,
[ADR-0035](./0035-non-waivable-rules-and-acceptable-weaker-modes.md)). A brief remains the best
practice: with one, an install converges by an author's design; with none, by the model's care.

**Whether a multi-machine tenant fits the skill shape is open** (`OPN-27`). Atomic creation
across vendors, sealing and the coordinator are harness rules and profile slots today, and this
record does not move them. Whether lnrent is a tenant or a vendor the operator buys from is
open in the same entry.

**If the first vendor fails its probe**, the first stage — and no later one — runs on Hetzner
Cloud with attest and a card account. That shows the harness and not the account-free purchase,
and is recorded as the alternative for that reason.
