# One model, one machine, and an honest-majority assumption

Each model accesses exactly one machine. No model ever reads, audits, or touches a
machine it did not provision. Security rests on assuming that a majority of the models
used across a federation are honest and competent, in the same shape as a Byzantine
fault assumption.

We chose this because access is the thing that composes, not intent. A model that can
read a second machine has a foothold on two members, so permitting each model to touch
two machines halves the number of malicious models required to reach a k-of-n
threshold. Any verification scheme that involves one model inspecting another's work
therefore weakens the exact property it appears to strengthen.

## Considered options

**Cross-audit**: a second model, on a different inference provider, reads a finished
machine and reports anomalies. This is the option worth recording as rejected, because
it is intuitively appealing and will be proposed again. It sounds like defence in
depth. It is actually a second foothold. The auditor is not a neutral observer; it is
another model that now has access.

**Transcript comparison**: compare what two models did, rather than granting access to
a machine. Rejected on practicality before this constraint was even reached — two
models following the same prose brief run different commands in different orders, and
deriving comparable effects from arbitrary shell is the undecidable problem from
[ADR-0002](./0002-cloud-plane-and-box-plane.md).

**A deterministic verifier** that reads a machine and reports its state. Rejected
earlier and for a separate reason: it reads what the machine chooses to tell it, so it
cannot beat a hostile AI. It remains useful for drift detection and honest mistakes
inside a single member, run by that member's own model.

## Consequences

**There is no verification layer.** The security claim is one sentence and it is true:
no single model provisioned enough members to reach the threshold. Nothing in the
product may imply more than that. "No anomalies found" and "verified" are both claims
this design cannot make.

**Model diversity becomes the security parameter, not a preference.** If a user
configures three inference providers that all serve the same underlying weights, they
have one model, not three, and the honest-majority assumption is vacuous. Telling
providers apart from models is therefore a correctness requirement.

**A model that fails partway through cannot be replaced on its machine.** Handing a
stuck machine to a second trust domain would violate the invariant. Recovery is a
ladder: retry, then escalate to a stronger model *inside the same trust domain*, then
destroy the machine and restart under a different domain. The middle rung is free —
escalating within a domain grants no access that domain does not already have — so
only genuine failures cost a server.

**The unit is a trust domain, not a model.** A trust domain is the pair of an
inference provider and the weights it serves, and two accesses are independent only if
they differ in both. Two models at one provider share a domain; two providers serving
the same weights share a domain. Getting this pairing wrong in either direction breaks
the assumption silently.

**That last paragraph is amended by
[ADR-0007](./0007-trust-is-counted-in-two-layers-and-shown.md).** Treating a domain as
an indivisible pair is too strict for the default product: procured inference routes
every member through one proxy by design, so read literally the pairing rule collapses
every default configuration to a single domain and forbids the arrangement the rest of
this ADR assumes. Domains are now counted per layer — weights and proxy separately.

**Amended again once the per-layer counting was carried through.** The first amendment's
"one-domain-one-machine holds at each layer" repeats the same mistake one level down: at
the **proxy** layer the default product deliberately puts one domain on every machine, so
the rule cannot hold there and was never meant to. The rule that holds is about **access**:
a session touches exactly one machine, and no set of weights touches more than one. The
proxy layer is counted and displayed, not bound.

The recovery ladder above carries the same pre-split language and the same correction. "The
middle rung is free — escalating within a domain grants no access that domain does not
already have" was written when a domain meant the indivisible pair. Per layer, the rung is
free at the **proxy** layer only; the stronger model is *new weights on the machine*, and it
is safe exactly when those weights are not also running another member — otherwise one model
gains the two-machine foothold this whole record exists to prevent. Escalation is therefore
conditional, not free, and `spec.md` states the operative form.

**Honest mistakes ship silently.** On a first-time setup a misconfiguration is the
likely failure, not a hostile model, and this design has no mechanism that catches it
across members. The threshold protects funds; it does not protect against everyone
being sloppy in the same way.
