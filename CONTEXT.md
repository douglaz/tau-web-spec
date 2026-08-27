# tau-web

A client-side AI harness that lets someone with only a phone provision and operate real
infrastructure, without trusting any party that could act on their behalf.

**This is the domain glossary. It defines terms and nothing else.** Where a term is governed
by a requirement, the requirement's identifier is given and the rule lives there, not here.
[`00-overview.md`](./00-overview.md) is the entry point.

## Language

### Execution planes

**Cloud plane** · `ARC-3`
Any action taken **off** the operator's machines with a credential they supplied. Carries two
approval modes: a **typed operation**, where an adapter exists and the action is expressed as
structured facts; and an **untyped call**, where none does and the operator approves a scope
instead.
_Avoid_: control plane, provisioning layer, API layer

**Box plane** · `ARC-3`
Shell execution on a machine the operator already owns. Command-at-a-time, free-form, never
pre-approved, always recorded.
_Avoid_: data plane, runtime layer, remote shell

**Scope** · `ARC-5`
A permission to act in a class, granted in advance. It names *where a credential goes*, not
what it can do.
_Avoid_: permission, grant, allowance

### Briefs

**Brief** · `ARC-9`
A document of instructions the AI reads and improvises from — prose plus example commands, in
the shape of an agent skill. Not executed verbatim, so what runs is not known before the AI
runs it.
_Avoid_: script, playbook, runbook, template

**Brief library**
The collection of briefs available to a session, shipped inside the signed bundle.

The format is **not** shared with lnrent. That project's *recipes* are executables its daemon
runs with high privilege; briefs are prose that must never be run as written. What is real is
a **layering**: a brief can tell the AI to invoke an lnrent hook as a deterministic tool.

### Roles

**Session** · `ARC-12`, `SEC-1`
One run of the harness under one set of model weights, responsible for exactly one machine.
See also *Flagged ambiguities*.

**Operator**
The human at the browser — the person who holds the credentials, approves the operations, and
owns the machines. Deliberately abstract over the tenants: under btc-policy a custody owner
funding a vault, under lnrent a seller renting capacity out. Both of those projects define
their **own** narrower `Operator` for their own domain.
_Avoid_: user, admin, owner, customer

**Coordinator** · `ARC-19`
AI-free deterministic code, running from the signed bundle on the operator's device, that
forms a federation by calling member APIs. The only party that reaches inside every member,
which is permitted precisely because it is not a model.

**btc-policy uses this word for a different component** — its operational relay, trusted until
the wrench attack and untrusted after. Different phase, opposite trust posture. Check the
register in the meta project before carrying the term across a repository boundary.

**Member**
A machine running the vault software as part of a federation. Generates its own key material
locally and never exports it.

**Lightweight pentest** · `ARC-17`
A session probing its own machine at delivery. A **competence** check, not an integrity check.
The periodic, outside check is a different object — see **Scanner**.

**Scanner** · `ARC-26`
A run of a specialist model, chosen by the operator, that probes machines' **public surfaces**
through the relay. Not a session: bound to no machine, holding no credential and no channel,
and composing no probe traffic.
_Avoid_: auditor, verifier (that word means the deterministic checklist), watchdog

**Verifier**
A deterministic program that reads a machine and reports its security-relevant state. Useful
for drift and honest mistakes within one member. Explicitly **not** a defence against a hostile
AI, because it reads what the machine chooses to tell it.

### Tenancy

**Tenant** · `ADR-0016`
A project built on the harness, supplying its own briefs, its own software, and its own
security requirements. The harness never sets a tenant's threshold; it isolates and counts.
_Avoid_: app, plugin, integration, use case

**Runtime obligation** · `ARC-35`
Something a tenant must do while the operator's browser is closed — answer a buyer, serve a
peer, meet a deadline. The harness cannot meet one, so a tenant's runtime obligations are its
**machines'**, discharged by its own software with no off-machine credential. A project with an
obligation it cannot move onto a machine is not a fit for this harness.
_Avoid_: background job, daemon work (both describe the mechanism rather than the duty)

**Multi-tenant machine** · `ARC-36`
A machine that serves parties the operator has never met — a rented slice, a hosted guest.
Hardening one is a different problem from hardening a single-purpose box, and its network
posture is the tenant's to state.
_Avoid_: shared host, multi-user (neither carries the untrusted-guest sense)

**Access model** · `ARC-27`
A tenant's decision about whether its machines remain enterable after delivery. **Maintained**
— the session can go back in. **Sealed** — the door is welded shut after setup by the tenant's
own design.
_Avoid_: maintenance mode, managed/unmanaged

**Threshold**
How many members must agree. A tenant fact, never the harness's.

**Effective threshold**
The threshold expressed in trust domains rather than in members, per layer. A 3-of-5
federation on five sets of weights behind one proxy is 3-of-5 against backdoored weights and
1-of-1 against a backdoored proxy.

**Honest-majority assumption**
**btc-policy's** security claim, not the harness's: a majority of the models used across a
federation are honest and competent. Byzantine in shape. It needs a threshold to mean anything.
_Avoid_: trustless, verified, provably secure

### The channel

**Attest** · `CHN-R5`
The cloud path's introduction route: the browser plants a one-time MAC secret in boot
configuration, and the machine's first boot posts its host-key fingerprints stamped under that
secret, through a relay drop-box, back to the browser.
_Avoid_: remote attestation, TPM attestation (the hardware senses; "attestation" for route 5
itself is fine)

**Drop-box** · `CHN-4`
A one-time buffer the browser opens at the relay before creating a machine, so a first-boot
machine has somewhere to post. The relay buffers; it cannot verify what it holds.

**Voucher** · `CHN-7`
The one-time MAC secret itself. A short-lived introduction **credential**, because possession
of it and the drop-box lets an actor stamp an arbitrary fingerprint the browser will trust.
_Avoid_: token, nonce (both understate what it authorizes)

**Artifact source** · `ARC-25`, `TRU-E8`
Wherever the installed system's bits come from: an image, a mirror, a channel. An untrusted
dependency pinned by content hash supplied from the browser.
_Avoid_: image host (too narrow), mirror (too narrow)

### State and recovery

**Exposure ledger** · `STA-10`
The per-machine history of every configured model that has ever touched it.
_Avoid_: audit log, history (unqualified)

**Recovery sheet** · `STA-16`
An exported record of host-key fingerprints, the exposure ledger, and the SSH client keys
wrapped under a passphrase. Sensitive in the same way a seed backup is.
_Avoid_: backup (unqualified), export file

**Replace / Restore** · `STA-17`
The two recovery flows, deliberately distinct. **Replace** issues new keys and revokes the old
— the default, for a phone that is lost. **Restore** reinstates the sheet's same keys and does
not revoke — for a phone that died in hand.

**Recovery ladder** · `ARC-16`
What happens when a model cannot finish its machine: retry, escalate behind the same proxy,
then destroy and restart under a different domain.

**Action transcript**
A browser-side record of what one session actually did, captured before transmission. It is
**not** evidence about a machine, because no second model may inspect it against that machine.
_Avoid_: audit trail, proof

**Provenance record**
The claim that a machine was provisioned by a specific cloud vendor and configured model, plus
the *set* of inference providers observed serving it. In the first version a local claim rather
than evidence.
_Avoid_: attestation, certificate, lineage

### Trust and diversity

**Trust tier** · `05-trust.md`
Which kind of trust a party represents. **Unavoidable** — true of any software. **Elective** —
the operator or publisher chose it and could change it. **Added** — the only tier the design
controls and the only one an invariant guards.
_Avoid_: trust score, threat level

**Trust domain** · `ARC-14`
An independent way for an AI to be compromised. Counted at two configured layers — **weights**
and **proxy** — plus one **observed**, the inference provider.

**Inference provider**
The party that actually serves the weights for a request, named at runtime by
`X-Provider-Name`. **Distinct from the proxy the session connects to.**
_Avoid_: AI provider, model provider, LLM vendor, serving provider

**Model**
The weights behind an inference provider. Two providers may serve the same model, so provider
diversity does not imply model diversity. This distinction is the whole security argument.

**Collision** · `OVR-6`
Two machines sharing a trust domain at any counted layer, the observed provider layer included.
Shown, not blocked.

**Procured inference** / **bring-your-own inference** · `ARC-31`
The default path, where the operator pays one fee and the publisher selects the models through
its one aggregator; and the advanced path, where the operator supplies their own tokens or runs
inference locally.

### Money

**Recurring cost**
The machines. Billed by the cloud vendor to the operator's own account. The app never mediates
it and cannot stop it.

**One-off cost**
Inference credits. The app retrieves an invoice; the operator's wallet pays it.

**Settled invoice**
Evidence that the operator has funded credits at a provider. It does **not** prove which member
used which proxy, because one top-up buys many queries.

## Flagged ambiguities

**"Instance"** is overloaded and must always be qualified.
- **Session** — one run of the harness under one set of weights, touching one machine. Prefer
  this over "AI instance".
- Never use bare "instance" for a virtual machine. Say **machine**.
- "Device" is not a unit of isolation here. Several sessions on one phone is the normal case.

**"Member"** means a machine that will become a federation member. In the first version nothing
has joined a federation, so a machine is not yet a member.

**"Approve"** means two different things and both are in play — an *operation* (structured
facts about one action) or a *scope* (a class of activity, in advance). `ARC-4`.

**"Verify"** is reserved. The product never presents a claim as verified (`SEC-2`). A host key
is *checked against a pin*; an artifact is *checked against a hash*; a scanner *reports*.

## Example dialogue

**Dev:** The AI needs to open port 8333 for the vault. Is that box plane or cloud plane?

**Domain expert:** Both, and they're different acts. Editing `nftables` on the machine is box
plane — free bash, transcript, no modal. Adding a firewall rule at the vendor is cloud plane,
so it's a typed operation and the operator sees a card.

**Dev:** Can't the AI just do it on the box and skip the card?

**Domain expert:** On the box, yes, and that's fine, it only affects a machine the operator
already owns. It cannot reach the vendor's firewall, because the box plane has no path to the
harness's cloud plane.

**Dev:** What if the brief says to resize the machine because it ran out of disk?

**Domain expert:** Then the AI stops and raises a cloud-plane operation, because that one spends
money. The brief can *suggest* it. Only a typed operation can *do* it.

**Dev:** Machine 1 looks misconfigured. Can I point the model from machine 2 at it to check?

**Domain expert:** No, and it isn't a policy question — machine 1 only has session 1's public
key, so session 2 literally cannot log in. That's deliberate. The only thing protecting the
operator is that no model reaches the threshold, and your audit would hand one model a second
foothold.

**Dev:** So nothing ever checks anyone's work?

**Domain expert:** Nothing goes inside to check. The scanner probes every machine's public
surface from outside — no credential, fixed probes, reports only. The claim is still not "we
verified it." The claim is "no single model provisioned enough members to matter." Those are
different sentences and only the second one is true, so only the second one gets said.

**Dev:** And the AI itself? Do we trust it?

**Domain expert:** Yes, by default — it's the operator's agent and it has root on its machine.
What we don't do is *pretend* otherwise. A tenant that needs the AI kept away from secrets
designs its procedure for that, like btc-policy sealing its nodes. Everywhere else we minimize
what the model can reach and count what's left.
