# The harness isolates and counts; tenants set thresholds

tau-web is a platform, and the projects built on it are tenants. The harness guarantees
that one session touches exactly one machine, counts trust domains per layer, displays
collisions, and states what it adds to and removes from the operator's trusted set. It
**never says how many independent domains are enough.** That is a tenant's decision:
btc-policy requires 3-of-5 across independent domains and an honest majority, lnrent
requires one machine and no threshold at all, and ad hoc use requires neither.

We chose this because the two things were welded together and are not the same kind of
claim. "One session touches one machine" is a property of the harness, testable against the
harness, and true whatever is being built. "Three of five must be honest" is a property of
a vault. Fusing them made the architecture read as though it exists only to build vaults,
and left the security section unable to describe a single machine — which is what lnrent
and ad hoc use actually are.

It also gives the platform a claim that survives without a federation. The harness adds one
third party (the relay), removes the party that would otherwise choose the operator's
vendor, model and configuration while holding their credentials, and bounds a model's blast
radius to the machines it provisioned. That is true for one machine and for five.

## What this moves

Tenant-specific material leaves this repository for a meta project where the projects
coordinate. Whole: 3-of-5 and its economics, member-to-member reachability, all-or-nothing
federation creation. Split down a real seam: the honest-majority half of
[ADR-0004](./0004-one-model-one-machine.md) from its one-session-one-machine half, the
effective-threshold framing of
[ADR-0007](./0007-trust-is-counted-in-two-layers-and-shown.md) from its two-layer counting,
and the coordinator half of
[ADR-0011](./0011-the-ai-delivers-a-locked-down-machine.md) from its pentest half.

`spec.md` loses its audience section, its federation acceptance criteria, and the parts of
its security section that assume a threshold exists.

## Considered options

**The harness owns all security**, with tenants supplying only recipes and software. This
keeps the documents nearly intact and is the smaller change. Rejected because lnrent and ad
hoc use would inherit federation machinery that does not apply to them, and because the
harness would go on making a claim only one tenant can support — the specific defect that
prompted this.

**The harness is mechanism only** and makes no security claims at all. Rejected because the
trust accounting *is* the differentiator: a harness that describes planes, a channel and a
bundle without saying what it adds and removes is plumbing, and the ecosystem would have
nothing to build a pitch on.

**Keep the vault as the wedge** and treat everything else as later expansion. Rejected on
the same grounds as the first option, with the added cost that ad hoc usage would ship under
a security claim that does not apply to it — the failure mode
[ADR-0004](./0004-one-model-one-machine.md) exists to prevent, arriving from the other
direction.

## Consequences

**The harness cannot state a threshold-based security claim.** What it can state is
narrower and holds everywhere: no session reaches a machine it did not provision, the
counts are shown per layer and never blended, and the added-trust tier is fixed and small.
A tenant stacks its own claim on top.

**A single machine has nothing absorbing a malicious model, and the harness must say so.**
The threshold is what absorbs malice; without one, a compromised model owns the machine it
just configured. The pentest is a competence check by its own definition and the verifier
reads what the machine chooses to tell it, so neither closes this. Ad hoc use is therefore
honest about a smaller claim rather than borrowing the vault's.

**Trust is stated in three tiers** — unavoidable, elective, added by this product — because
the regress has no bottom and a flat list reads as a scorecard the design is losing. Only
the third tier is the harness's to control, and only it is guarded by an invariant.

**The recipe format becomes an ecosystem concern.** It was already a candidate shared
primitive with lnrent; with a meta project it has somewhere to live that is neither
project's.

**Two projects now have to agree on where a decision belongs**, and the failure mode is a
decision recorded in neither. The meta project owns anything that spans tenants; this
repository owns anything true of the harness with no tenant present.
