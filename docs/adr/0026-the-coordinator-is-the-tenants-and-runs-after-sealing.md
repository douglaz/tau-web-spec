# The coordinator is the tenant's, and runs after sealing

Federation formation belongs to the vault, not to the harness, and it begins only once every
machine is provisioned, locked down, delivered and **sealed**. The coordinator therefore holds
no channel to any machine at any point in its life. Its credential is peer-equivalent: the
vault protocol port of [ADR-0010](./0010-members-reach-each-other-on-one-authenticated-port.md),
reached over the relay like any other TCP.

## The problem this addresses

Two requirements described two different coordinators. `ARC-19` said it *"forms the federation
by calling member APIs."* `SEC-1` and `TRU-A3` said it *"holds every machine's client keypair"*
for the setup window. Those are not the same grant, and the second is far larger than the first
describes needing.

The larger reading also contradicted the requirement that carried it. `SEC-1` rejects a single
shared client key because it *"would leave this invariant enforced only by routing code, which
is bookkeeping rather than a boundary."* A party holding every machine's key recreates exactly
that condition — and because this record's sibling, ADR-0012, makes creation all-or-nothing, the
window necessarily spanned every member at once.

It left `CNF-8` untestable too. That item verified the grant was *"unusable after setup
completes… by attempting a coordinator channel access and observing refusal."* If the
coordinator holds the members' own session keys, nothing can revoke them — they must stay in
`authorized_keys` for the sessions themselves — so the refusal could only come from the harness
declining to call its own transport. That is the failure mode `SEC-1` names by hand.

## The decision, and why the ordering settles it

**The coordinator is tenant machinery.** Federation formation belongs to the vault the way the
threshold does ([ADR-0016](./0016-the-harness-isolates-and-counts-tenants-set-thresholds.md))
and the delivery declaration does (`ARC-39`). The harness does not know what a federation is,
and has no business holding the credentials that make one.

**It runs after sealing**, which is already the order ADR-0012 requires: no federation until
every member is provisioned, locked down and reachable. Sealing is
[ADR-0013](./0013-ongoing-operation-periodic-pentest-and-advisory-watch.md)'s — SSH
uninstalled, no administrative path.

That ordering does the work. **On a sealed member there is no channel to hold.** The question of
how a coordinator's channel grant is scoped, revoked or tested does not need a good answer,
because the grant cannot exist. `SEC-1` gains no exception window, and `CNF-8` becomes an
inspection of what the coordinator is given rather than a refusal test — the same shape `CNF-9`
already uses for the scanner, and for the same reason: absence of a credential is not
observable by attempting to use one.

**What it does hold is peer-equivalent.** It can do to a member what another member can do,
and no more. `ARC-23` already states that the vault protocol must be safe against actively
hostile peers — confirmed as btc-policy's own premise rather than a requirement invented here —
so this grant adds nothing to the vault's threat model. That is the difference between a party
whose misbehaviour the protocol was designed for and one whose misbehaviour it was not.

## Considered options

**A distinct per-member coordinator key, removed at setup's end.** Revocation would be
cryptographic rather than procedural, and per member. Rejected because the removal is a step
that can fail, and a member whose removal fails is left carrying a live all-member key with
nothing watching. It also keeps a moment when one party can reach inside every machine, which is
the property in question.

**Shell access under an SSH certificate expiring with the setup window.** Better than removal:
`sshd` enforces the expiry, and no step can fail to run. Rejected because it time-boxes
`SEC-1`'s objection rather than answering it, requires `TrustedUserCAKeys` on every member, and
rests on certificate support in the chosen client that is not verified.

**Keep it as written and price it honestly** — declare `SEC-1` procedural for the setup window
and cap the window's length. Rejected as the weakest option that is not wrong: it concedes the
property the security claim rests on, in exchange for machinery the ordering shows is not
needed.

## Consequences

**`TRU-A3` retires.** The coordinator was listed as a party this product adds because its reach
was believed broader than anything else the application does. Its reach is now narrower — the
application holds every session; the coordinator holds none. Whatever trust it needs is
`TRU-A1`'s, the bundle it ships in. The row is kept as a retirement, not deleted, because "the
coordinator reaches inside every member" is the intuitive reading of what a coordinator is.

**A formation failure is a rebuild, not a repair.** Recorded in ADR-0012. If a sealed member's
API refuses to form, nobody can go back inside. Only the ladder's last rung applies: destroy
and rebuild that member. The alternative is an administrative path into a machine holding the
vault, kept open for the length of a step that either works or does not.

**The vault protocol port answers the world, and that is unchanged.** The coordinator reaches it
over the relay, and `ARC-41` forbids privileging relay sources — so what the relay can reach,
the world can. ADR-0010 already made mutual authentication the boundary rather than the
firewall; this record relies on that rather than weakening it.

**ADR-0021's third owner is renamed.** No check is the coordinator's. The deterministic
checklist verifier is the harness's, run over each bound session's own channel during setup,
holding no grant of its own.

**The peer-equivalent credential has a stated origin, added after
[ADR-0029](./0029-the-machine-speaks-nostr-and-keys-derive-from-a-seed.md).** This record left
open where the credential comes from, and the obvious source is closed: ADR-0011 generates a
member's own keys on the machine and never exports them, so the coordinator cannot be handed
one. It is instead a keypair the browser **derives from the operator seed**, whose public half
the bound session installs into each member's peer set during setup — before sealing, the one
window a member can still be configured — and whose private half re-derives rather than being
stored. It is `SEC-5` row 17, a credential the harness places rather than an unlisted grant,
which is what `CNF-13`'s completeness rule requires. The reach it confers was always understood:
a hostile peer's worth, which `ARC-23` designs for.
