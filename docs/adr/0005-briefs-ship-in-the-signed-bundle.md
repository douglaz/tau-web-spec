# Briefs ship in the signed app bundle

Briefs are part of the released application. They are reviewed, versioned, and
integrity-checked with the rest of the code. Nothing fetches a brief at runtime, users
cannot supply their own, and a brief cannot change without shipping a release.

We chose this because a brief is prose that steers a model, which is prompt injection
by design, and every federation member reads the same brief. Whoever can change a
brief reaches every member at once. That defeats the honest-majority assumption in
[ADR-0004](./0004-one-model-one-machine.md) rather than being absorbed by it: n honest,
competent models faithfully following poisoned instructions all produce the wrong
machine, and they agree with each other perfectly while doing it. The brief is the one
component where diversity buys nothing, so it has to be locked instead.

This is affordable only because [ADR-0001](./0001-briefs-are-instructions-not-scripts.md)
put adaptability in the model rather than in the brief. Novel problems are handled by
the AI improvising during the session, not by shipping a new brief, so a small static
brief set does not imply a small set of handleable situations.

## Considered options

**A different brief per member, from a different author.** This is the correct
destination, because it makes the brief layer obey the same rule as the model layer
and removes the common mode entirely. Rejected for now because n independent brief
authors for one task is an ecosystem, and an ecosystem cannot be bootstrapped by one
project. Revisit when more than one party builds on this.

**Briefs signed by a party the user chooses to trust.** Rejected because "whose
briefs do you trust" is a question the target operator is by definition unequipped to
answer — the same person who cannot use ssh cannot evaluate a brief author either. In
practice they would trust whoever the app suggested, which is this ADR with extra
steps and a weaker guarantee.

**Fetched or user-supplied, unsigned.** Rejected outright. A text file that steers
every model on every member, changeable without shipping anything, is cheaper to
attack than an inference provider.

## Consequences

**Adding a cloud vendor, or fixing a brief, requires a release.** Iteration on briefs
is as slow as iteration on code, deliberately.

**The app bundle is now the only remaining single point of total compromise.** Models
are diversified, cloud vendors are diversified, machines are isolated. The bundle is
common-mode across every member and it carries the briefs too. The hosting-integrity
gap, already open and already lacking reproducible-build attestation, is now the
largest concentrated risk in the system.

## Amended: this makes the publisher a gatekeeper of tenancy

The consequences above were written about *iteration speed* — fixing a brief needs a release.
Under [ADR-0016](./0016-the-harness-isolates-and-counts-tenants-set-thresholds.md), which came
later and made tau-web a platform with tenants, the same rule means something larger: **a tenant
cannot exist without the publisher shipping its briefs.** Tenants supply their own software and
their own security requirements, and are otherwise independent — but the instructions that
install them live in someone else's signed bundle, so the publisher decides which tenants there
are and when any of their changes reach an operator.

That is authority, not merely friction, and it belongs named. `ARC-40` states it and `TRU-A1`
carries it in the added tier beside the compromise risk.

**It is a bootstrap seat, and this record already knew the destination.** The considered option
rejected above — a different brief per member, from a different author — was called "the correct
destination", rejected because "an ecosystem cannot be bootstrapped by one project." The same
answer applies one level up: the publisher writes and signs every brief because there is nobody
else yet. Briefs are shaped as agent skills, and skills went the same way — a curated
first-party set first, third-party authorship after.

**What must survive that opening is this record's actual security property**, which is not about
who signs: briefs are locked and never fetched at runtime, because prose that steers a model
reaches every member at once and diversity buys nothing against it. What changes when third-party
briefs arrive is *who the operator trusts for a brief's content*. Note that trusting the tenant's
own signer would add nobody new — `TRU-E7` already trusts whoever signs the software those briefs
install — so the eventual step is smaller than it looks. It still needs deciding when it arrives,
rather than guessing now.

**Nothing is shared with lnrent here.** An earlier version of this line said the format
was shared and only distribution was not. lnrent's *recipes* are executables its daemon
runs with high privilege; briefs are prose that must never be run as written, and no format
spans both. A brief can tell the AI to invoke an lnrent hook as a tool — that is a layering,
not a shared artifact.
