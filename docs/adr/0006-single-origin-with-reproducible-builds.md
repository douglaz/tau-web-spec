# One origin, with reproducible builds

The application is served from a single origin. Builds are reproducible and their
hashes published, so a third party can verify that the served bundle matches the
published source. We do not diversify the origin across federation members.

This is a deliberate exception to the pattern used everywhere else. Models, inference
providers, cloud vendors, and machines are all diversified per member so that no single
party reaches a threshold. The bundle is not, and it therefore remains the one
common-mode component in the system, carrying the briefs as well
([ADR-0005](./0005-briefs-ship-in-the-signed-bundle.md)).

## Considered options

**Origin diversity — a different origin or mirror per member**, all publishing the same
reproducible hash, so a compromised origin reaches only one member and the threshold
absorbs it. This is the option worth recording as rejected, because it is the
consistent extension of every other decision here and it will be proposed again.

It was rejected on user-safety grounds rather than security grounds. Instructing
someone to "open this other URL on your second device" is behaviourally identical to a
phishing attack, and the target operator is precisely the person least equipped to tell
the difference. Teaching Bitcoin users that the same app legitimately lives at several
addresses trains the reflex that gets them robbed. The attack it prevents is rarer than
the attack it teaches. Several origins also means several hosting parties and several
certificates, each secured worse than one would be.

## Consequences

**The bundle is the remaining single point of total compromise.** A coerced or
compromised host can serve one build that misbehaves on every member at once, and it
can serve a good bundle to anyone who looks like a checker while serving a bad one to a
target. Reproducible builds make this detectable, not preventable, and the target
operator will not verify a hash on a phone.

**That sentence is one party short**, and so is the same claim in
[ADR-0005](./0005-briefs-ship-in-the-signed-bundle.md). Every member installs the same
vault software release, so whoever signs it is common-mode across the federation in the
same shape as the bundle. The bundle remains the largest such component and the argument
below is unaffected; "the remaining" is the word that overstates.

The mitigation that matters is therefore **third-party watchdogs**, not user
verification: if independent parties routinely fetch and compare the served bundle
against the published hash, an attacker cannot know who is checking. That only works if
reproducible builds actually exist and someone runs the checks, neither of which is
true today.

This is the honest limit of the design, and it must be stated as plainly in the product
as it already is in the `ai-vps-harness` README's "What you still have to trust."

## Amended: the opening overstates provider diversification

"Models, inference providers, cloud vendors, and machines are all diversified per member"
predates [ADR-0007](./0007-trust-is-counted-in-two-layers-and-shown.md)'s layer split and
conflates the provider with the weights. On the default path the aggregator picks the
inference provider per request and the product does not configure it per member; it is
now counted as the third layer
([ADR-0007](./0007-trust-is-counted-in-two-layers-and-shown.md)'s amendments) — first as
observed per response, and since as *requested* per member, never as a promise of separation. The **vendor** half of the
sentence stands, and the
specification's vendor-diversity invariant rests on it; the provider half is the stale
part. The contrast the paragraph draws — everything else diversified, the bundle not —
survives with the corrected list.
