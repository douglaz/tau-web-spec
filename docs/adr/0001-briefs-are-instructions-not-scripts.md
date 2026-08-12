# Briefs are instructions the AI reads, not scripts it executes

A brief is a document of prose plus example commands, in the shape of an agent skill.
The AI reads it and decides what to actually run. It is not executed verbatim.

We chose this because the AI exists precisely to handle problems we cannot enumerate
in advance — a vendor changing an image name, a package that fails to install, a
service that will not start for a reason nobody has seen. A script stops dead at the
first surprise, and a setup nobody can finish sends the user back to a custodian,
which is a worse outcome than the risks this design accepts.

## Considered options

**Scripts executed verbatim**, with the AI selecting and parameterizing them, and
authoring a new brief when none fits. Rejected despite two real advantages: it makes
pre-approval trivial, and every solved problem becomes a reusable artifact, so the
library compounds. It was rejected because it inverts the failure mode we care most
about — it is most brittle exactly when the AI is most needed.

**Scripts with declared decision points** where the AI may substitute. Rejected
because it requires predicting where flexibility will be needed, which is the same
problem we are saying cannot be solved. Novel adversity arrives in the places nobody
marked.

## Consequences

What runs is not known until the AI runs it, so **an operation cannot be approved in
advance by showing the user what will happen.** This is the constraint that forces
[ADR-0002](./0002-cloud-plane-and-box-plane.md).

Adaptations do not accumulate. The same problem may be solved differently on two runs
and the library does not improve on its own. If compounding is wanted later, it has to
come from the AI writing back into briefs as a deliberate feature, not as a side
effect of running them.
