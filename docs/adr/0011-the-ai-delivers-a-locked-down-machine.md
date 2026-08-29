# The AI delivers a locked-down machine and demonstrates it, per vendor

An AI session's deliverable is a machine that is provisioned, hardened, running the
vault software, reachable, and **shown to be locked down** by a lightweight self-directed
pentest. The coordinator then takes the member endpoints plus operator-supplied recovery
descriptors and forms the federation by calling member APIs.

The AI's job is deliberately *not* uniform across vendors, because the vendors are not
uniform.

## Why the job cannot be reduced to booting a prebuilt image

A prebuilt custom image carrying the vault software would shrink the untrusted
component's role attractively. It cannot be relied on: Hetzner Cloud has no image
upload API at all and requires a rescue-and-write approach, while DigitalOcean and Vultr
offer import paths that differ from each other and from that. Custom images are an
optimisation available at some vendors, not a contract available at all of them, so the
AI must be able to install and harden from a stock image wherever they are not.

This heterogeneity is an argument *for* the AI rather than against it. Five vendors,
five rescue flows, five image mechanics, all changing without notice, is exactly the
unpredictable work that a deterministic provisioner cannot absorb.

## Lockdown is part of the deliverable, and the pentest is a competence check

Hardening is not a step the AI performs and reports; it is a property the AI must
demonstrate, with a lightweight pentest against its own machine — open ports, default
credentials, sshd posture, exposed services.

**This is a competence check, not an integrity check.** A model verifying its own work
proves nothing against a malicious model, and does not need to: malice is what the
threshold in [ADR-0004](./0004-one-model-one-machine.md) absorbs. The honest-majority
assumption requires the majority to be honest *and competent*, and the pentest is what
raises confidence in the second half. Honest-but-sloppy is the likely failure on a
first-time setup, and it is the one this catches.

The pentest runs from the machine itself or from the trusted coordinator. It never runs
from another member, because that would be the foothold
[ADR-0010](./0010-members-reach-each-other-on-one-authenticated-port.md) exists to
prevent. ("From the trusted coordinator" was imprecise, and
[ADR-0021](./0021-the-surface-pentest-is-outside-in.md) corrects it: what the coordinator
may run is the deterministic verifier, during setup — its only window; the delivery
pentest is the session's own, and the
periodic outside check belongs to the scanner.)

## Key isolation, finally specified

This closes what [ADR-0004](./0004-one-model-one-machine.md) left open. **The AI never
touches key material.** Recovery descriptors come from the operator. Member keys are
generated on the machine and never exported. The AI produces infrastructure and proves
it is closed; it does not produce, see, or carry secrets.

## Consequences

**The coordinator is trusted during setup and is AI-free.** It is the only party that
reaches inside all five members, which is permitted because it is deterministic code from the
signed bundle, already inside the trusted set. No model gains a second foothold.

**The coordinator's reach needs the same channel as everything else.** A freshly
provisioned machine has no WebPKI-valid certificate, so calling five member APIs from a
browser almost certainly rides the pinned SSH channel
([ADR-0015](./0015-the-browser-reaches-a-machine-over-pinned-ssh.md)) rather than direct
HTTPS.

**"Locked down" needs a definition, per vendor.** The pentest can only assert what it
checks, so the checklist is part of the brief set and therefore ships signed
([ADR-0005](./0005-briefs-ship-in-the-signed-bundle.md)).

## Amended: the surface is measured against a declaration, not against deny-all

"Open ports, exposed services" inherited its meaning from
[ADR-0010](./0010-members-reach-each-other-on-one-authenticated-port.md)'s
deny-everything-but-one-port posture, which is btc-policy's rule. That made the check
unusable for a tenant whose product is reachable ports: every slice a rental box sells looks
exactly like the finding the check was built to raise, so the pentest would report the
business model forever and the operator would learn to ignore it.

The operative form is `ARC-39`: the tenant supplies a **delivery declaration** — what must be
true of a finished machine — and both the delivery check and the periodic scanner measure
against it. **A difference from the declaration is the finding**, never a property the harness
assumed.

The listening surface is one part of that declaration and the reason it was written, but not
the whole of it. Service lifecycle is another, and it shows why the harness must not
generalise: a rental box needs its daemon enabled and surviving reboot, while a sealed vault
node is deliberately non-durable — reboot is death, by its tenant's own design. A harness rule
requiring durability would have contradicted a documented tenant fact.

The limit is real and is not to be smoothed over: this finds *undeclared* surface, never
hostile use of *declared* surface. A wide declaration buys a weak check. `SEC-2` already
forbids reporting either as verified.

## Amended: the deliverable is the tenant's software

"Running the vault software" above is btc-policy's case, written before
[ADR-0016](./0016-the-harness-isolates-and-counts-tenants-set-thresholds.md) separated the
harness from its tenants. The operative form — `ARC-17` — is
the software the machine's tenant calls for: the vault software under btc-policy,
`lnrentd` under lnrent. The lockdown demonstration and the pentest's competence framing
are unchanged — though the body's "malice is what the threshold absorbs" holds only where
a threshold exists; for a single-machine tenant nothing absorbs malice and `SEC-CLAIM`
states the accepted risk. The coordinator consequences are the federation half ADR-0016
marks for its seam.
