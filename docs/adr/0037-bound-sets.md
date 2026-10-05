# A session is bound to a set of machines, one by default

A session reaches only the machines the operator bound to it — its **bound set**. The default
is a set of one. A larger set is a weaker mode the operator accepts by its label, and it is
never offered where a profile declares an independence bound or for a multi-tenant machine.
Decided 2026-10-05.

This amends [ADR-0004](./0004-one-model-one-machine.md), which opens "A session accesses exactly
one machine", and [ADR-0016](./0016-the-harness-isolates-and-counts-tenants-set-thresholds.md),
which states the harness's guarantee as one session touching exactly one machine.

## Why

One machine per session was written for a vault, where a model with a foothold on two members
halves the number of malicious models a threshold must absorb. Applied to everybody, it
overstates. An operator who wants a web server and a database, with no quorum anywhere, gains
no independence by running two sessions under what the procured path makes the same model
anyway. And the sentence that justified the rule at the vendor's door — that a vendor
credential reaches every machine on the account — is not necessarily true, and not the hazard
it was taken for.

But the rule bought more than the threshold, and those things had to be named before it could
be loosened. With one machine per session the box plane's worst case was one machine; whatever
a machine printed could steer commands on that machine only; a confused model could not run a
command on the wrong machine, having one key; and a multi-tenant machine's guests were never
one context away from another machine's output. None of those is about a threshold.

## The decision

**The invariant is the set.** `SEC-1` says "A session MUST be bound to a set of machines the
operator fixed, and MUST NOT read, audit, or touch any machine outside it". Keys stay per
machine, a machine stays in at most one live session's set, and SSH still does the refusing.

**A set is one unit of harm and is shown as one.** `SEC-1` says "A bound set is one unit of
harm and one model context". That is why a larger set is an acceptable weaker mode
([ADR-0035](./0035-non-waivable-rules-and-acceptable-weaker-modes.md)) and not a preference:
its weaker modes, its placed secrets and its blast radius are stated for the set.

**Where `SEC-1` keeps one machine per session, no operator act changes that.** `SEC-1` says
"Wherever a profile declares any independence bound, each session is bound to exactly one
machine" and "A multi-tenant machine (`ARC-36`) is always bound alone". The first is the
harness's form of a rule the tenant states over configured models; btc-policy's is in its
profile's independence-bound slot.

**What a set costs is paid for in three mechanisms.**

- *Growth and no shrinking.* `SEC-1` says "A set grows by one operator act per machine, and
  never shrinks while its session lives".
- *Every command names its machine.* `ARC-7` says "Every command and every harness job names
  its machine", resolved by the harness against the set — the replacement for the
  wrong-target protection one key used to give.
- *The ledger records co-binding.* `STA-10` says "An entry is made at **binding**, for every
  machine of the session's bound set".

**The vendor's door.** A vendor API may reach machines outside a session's set, whoever holds
the credential. Where an adapter exists it closes that per operation, by refusing an operation
naming a machine outside the calling session's set, so a typed credential may serve several
sessions (`SEC-4`). Where none exists the conditions are
[ADR-0038](./0038-untyped-vendor-scopes.md)'s.

**The jump host is outside every set**
([ADR-0036](./0036-first-contact-is-never-trusted-through-the-relay.md)): the flow that uses
one is not a session.

## Considered options

**Keep exactly one machine per session for everyone.** Rejected as the universal rule and
kept three ways: as the default, as the rule under any declared independence bound, and as the
rule for a multi-tenant machine.

**Allow larger sets and say nothing more**, treating one machine per session as a best
practice an operator skipped. Rejected: a set of several machines does not meet the test a
weaker mode must meet per machine — its harm does not stay on one machine — so the test was
restated for the set and the set made a mode of its own: a bound set is one unit of harm, and
is shown as one. What "shows when it happens" means for harm that moves between the machines
of one set is not decided here (`TASKS.md`).

**A loose default that a tenant tightens.** Rejected: it inverts the direction every shipped
default in this design runs. The default is the strict value.

**Require one machine per session "where a tenant's independence bound needs it".** Rejected
for the key: nobody is placed to decide that a bound "needs" it. The rule is keyed on the slot
holding a relation at all, so a tenant is protected before its profile says anything more.

**State the tenant's rule over sessions.** Rejected: on the procured path several one-machine
sessions can be one configured model, and the tenant's claim is about models. The tenant's
rule is over a configured model's footprint — every machine it has touched and every machine
co-bound with those.

**Carry the rule in the profile's machine-set slot, or a new slot.** Rejected for the
independence-bound slot, which already says which machines must not share a fault.

**Let a machine leave a live set.** Rejected: what the model read from it is still in the
context commanding the rest, and jobs it started may outlive the release.

**One key per set, or one index reused across a set.** Rejected: per-machine keys are what
make the refusal SSH's.

**Hold the unresolved barrier per session or per set.** Rejected; it stays per approved machine
entry, for the reasons `STA-24` gives.

**Restate the permanence condition as "not assigned to any machine outside the current set".**
Rejected: sets change, and the condition would follow them and mean nothing. Under a declared
bound it is the footprint against that bound, for the life of the machines; elsewhere the
footprint is counted and shown.

**Compute the transitive closure of exposure in the ledger.** Rejected for recording the
co-bound set at binding and stopping there.

**Control the vendor's door with "one vendor credential per session".** This was the first
proposal. Rejected: under a typed adapter it is unnecessary, since each operation is authorized
on its own; with no adapter it is a comparison of strings, since two credentials can reach the
same machines; and it does not hold across time.

**Assume a scoped vendor token bounds reach, and say so.** Rejected: the harness cannot see
what a token is scoped to. The text says a vendor API *may* reach machines outside the set, and
no narrower bound is presented as checked.

**Enforce on what the adapter lists.** Rejected: a listing is the vendor's word at one moment.
It is displayed, and the authorization at each dispatch is the enforcement.

**Edit ADR-0004 and ADR-0016 in place.** Rejected for this record and a dated note on each:
what they said is the trap a reader will re-derive.

## Consequences

**ADR-0004's reasoning becomes the tenant's.** The halving argument is intact and is why a
declared bound means one machine per session. What no longer follows from it is a rule for
machines nobody counts as independent.

**"A different model on each machine" is not deliverable on the procured path today.** The
candidate order gives every session its highest-ranked candidate. Under a footprint rule that
is one model across every member. The gap predates this record and is recorded with the third
stage's open questions (`OPN-27`).

**The recovery ladder's middle rung under a larger set is not decided.** `SEC-1` still speaks
of re-binding one half-provisioned machine to a successor. Whether a successor takes the whole
set, a subset the operator picks, or nothing without an operator act is open (`TASKS.md`).

**Concurrency has a second axis.** Several sessions on one phone was the measured-nowhere
number; a session holding a channel to each machine of a larger set multiplies it differently,
and `CNF-45` now asks for the per-channel figure.

**The first stage is untouched.** Its set is one machine, and nothing here gates it.
