# One model, one machine, and an honest-majority assumption

A session accesses exactly one machine. Security rests on assuming that a majority of the
models used across a federation are honest and competent, in the same shape as a Byzantine
fault assumption.

We chose this because access is the thing that composes, not intent. A model that can read a
second machine has a foothold on two members, so permitting each model to touch two machines
halves the number of malicious models required to reach a k-of-n threshold. Any verification
scheme in which one model inspects another's machine **from inside** therefore weakens the
exact property it appears to strengthen. The outside-only scanner of
[ADR-0021](./0021-the-surface-pentest-is-outside-in.md) is the deliberate exception that
proves the rule, because it grants no access at all.

The operative statement is `SEC-1`, which defines binding, its three forms, and its
cryptographic enforcement. This record holds the reasoning and the rejected alternatives.

## Considered options

**Cross-audit**: a second model, on a different inference provider, reads a finished machine
and reports anomalies. This is the option worth recording as rejected, because it is
intuitively appealing and will be proposed again. It sounds like defence in depth. It is
actually a second foothold. The auditor is not a neutral observer; it is another model that
now has access.

**Transcript comparison**: compare what two models did, rather than granting access to a
machine. Rejected on practicality before this constraint was even reached — two models
following the same prose brief run different commands in different orders, and deriving
comparable effects from arbitrary shell is the undecidable problem from
[ADR-0002](./0002-cloud-plane-and-box-plane.md).

**A deterministic verifier** that reads a machine and reports its state. Rejected as a defence
against a hostile AI for a separate reason: it reads what the machine chooses to tell it. It
remains useful for drift detection and honest mistakes inside a single member, run by that
member's own session or by the coordinator during setup.

## Consequences

**There is no verification layer.** Nothing in the product may imply more than the claim.
"No anomalies found" and "verified" are both claims this design cannot make.

**Model diversity is the security parameter, not a preference.** If a user configures three
inference providers that all serve the same underlying weights, they have one model, not
three, and the honest-majority assumption is vacuous.

**Domains are counted per layer, not as an indivisible pair.** Treating a trust domain as the
pair of provider and weights is too strict for the default product: procured inference routes
every member through one proxy by design, so read literally that pairing collapses every
default configuration to a single domain and forbids the arrangement this record assumes.
Weights and proxy are counted separately, with the provider counted as observed
([ADR-0007](./0007-trust-is-counted-in-two-layers-and-shown.md)).

**The rule that survives the split is about access, not about domains.** A session is bound to
exactly one machine. The weights-level form — no set of weights on more than one machine — is
the **goal the binding serves**, not an enforceable rule of its own: the product enforces what
it assigns, and two sessions unobservably served the same weights are a displayed collision
rather than a violation. The proxy layer is counted and displayed, never bound.

**A model that fails partway through cannot be replaced on its machine.** Recovery is a ladder:
retry; escalate to a stronger model behind the same proxy; then destroy the machine and restart
under a different domain.

> **The middle rung looks free and is not.** Escalating behind the same proxy grants that party
> nothing it lacked, which is where the reasoning usually stops. But the stronger model is
> **new weights on that machine**, and that is harmless only while those weights are not also
> running another member. Otherwise one model gains the two-machine foothold this entire record
> exists to prevent. The rung is conditional, and `SEC-1` states the condition.

**Honest mistakes ship silently.** On a first-time setup a misconfiguration is the likely
failure, not a hostile model, and this design has no mechanism that catches one made the same
way by everybody. The threshold protects funds; it does not protect against uniform sloppiness.
