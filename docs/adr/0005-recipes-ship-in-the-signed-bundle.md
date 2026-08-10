# Recipes ship in the signed app bundle

Recipes are part of the released application. They are reviewed, versioned, and
integrity-checked with the rest of the code. Nothing fetches a recipe at runtime, users
cannot supply their own, and a recipe cannot change without shipping a release.

We chose this because a recipe is prose that steers a model, which is prompt injection
by design, and every federation member reads the same recipe. Whoever can change a
recipe reaches every member at once. That defeats the honest-majority assumption in
[ADR-0004](./0004-one-model-one-machine.md) rather than being absorbed by it: n honest,
competent models faithfully following poisoned instructions all produce the wrong
machine, and they agree with each other perfectly while doing it. The recipe is the one
component where diversity buys nothing, so it has to be locked instead.

This is affordable only because [ADR-0001](./0001-recipes-are-instructions-not-scripts.md)
put adaptability in the model rather than in the recipe. Novel problems are handled by
the AI improvising during the session, not by shipping a new recipe, so a small static
recipe set does not imply a small set of handleable situations.

## Considered options

**A different recipe per member, from a different author.** This is the correct
destination, because it makes the recipe layer obey the same rule as the model layer
and removes the common mode entirely. Rejected for now because n independent recipe
authors for one task is an ecosystem, and an ecosystem cannot be bootstrapped by one
project. Revisit when more than one party builds on this.

**Recipes signed by a party the user chooses to trust.** Rejected because "whose
recipes do you trust" is a question the target operator is by definition unequipped to
answer — the same person who cannot use ssh cannot evaluate a recipe author either. In
practice they would trust whoever the app suggested, which is this ADR with extra
steps and a weaker guarantee.

**Fetched or user-supplied, unsigned.** Rejected outright. A text file that steers
every model on every member, changeable without shipping anything, is cheaper to
attack than a model provider.

## Consequences

**Adding a cloud vendor, or fixing a recipe, requires a release.** Iteration on recipes
is as slow as iteration on code, deliberately.

**The app bundle is now the only remaining single point of total compromise.** Models
are diversified, cloud vendors are diversified, machines are isolated. The bundle is
common-mode across every member and it carries the recipes too. The hosting-integrity
gap, already open and already lacking reproducible-build attestation, is now the
largest concentrated risk in the system.

**Sharing recipes with lnrent means sharing the format, not the distribution.** Each
project ships its own set.
