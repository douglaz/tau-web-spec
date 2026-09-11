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
_Avoid_: permission, grant, allowance — and **"scope" in its ordinary sense**: what a rule
binds is "what it binds" or "its reach", the extent of a task is its "extent", and a tier that
applies to a stage "says which stage it gates". The word is reserved for the object above.

### Briefs

**Brief** · `ARC-9`
A document of instructions the AI reads and improvises from — prose plus example commands, in
the shape of an agent skill. Not executed verbatim, so what runs is not known before the AI
runs it. Owned by whichever party its content keys on: a brief keyed on a vendor product or a
distribution (install, vendor lockdown) is the harness's; a brief keyed on a tenant's software
(delivery) is the tenant's and lives with its profile (`ADR-0030`).
_Avoid_: script, playbook, runbook, template, "brief 2" (lockdown has two owners and is not
one document)

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

**Post-harness machinery** · `ARC-19`, `ARC-19a`
What a profile may declare, in its post-harness handoff slot, to run after the harness has
finished with the setup. AI-free deterministic code from the signed bundle, on the operator's
device, starting only once every machine of the setup is delivered. It holds no channel to any
machine at any point, and receives at most the credential that slot declares.
_Avoid_: post-setup agent, orchestrator (both suggest something that keeps running)

**Coordinator** · `docs/tenants/btc-policy/profile.md`
btc-policy's *Post-harness machinery*, defined in its profile.

**The btc-policy repository uses this word for a different component** — its operational
relay, trusted until the wrench attack and untrusted after. Different phase, opposite trust
posture. Check the register in the meta project before carrying the term across a repository
boundary.

**Member** · btc-policy vocabulary
A machine running the vault software as part of a federation. Generates its own key material
locally and never exports it. The harness's own word for the same thing is *machine*; the
general files say *member* only where btc-policy's federation is meant.

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
for drift and honest mistakes within one machine. Explicitly **not** a defence against a hostile
AI, because it reads what the machine chooses to tell it.

### Tenancy

**Tenant** · `ADR-0016`, `ARC-40`
A project built on the harness, supplying its own software, its own security requirements and
the content of its own briefs. The harness never sets a tenant's threshold; it isolates and
counts. **Independent in every respect but one**: briefs ship in the publisher's signed bundle,
so today the publisher decides which tenants exist and when their changes reach operators. A
bootstrap seat with a stated trajectory, not a property of the design.
_Avoid_: app, plugin, integration, use case

**Tenant profile** · `ADR-0030`
The one document in which a tenant tells the harness everything the harness needs to know
about it, in a fixed set of slots. Rules that only make sense inside a profile are the
tenant's; rules that hold for every profile are the harness's. A new project integrates by
writing a profile. The general specification refers to "the profile" and never names a tenant
in a normative sentence.
_Avoid_: tenant config, manifest (lnrent's recipes have manifests; not the same thing),
"the btc-policy section"

**Runtime obligation** · `ARC-35`
Something a tenant must do while the operator's browser is closed — answer a buyer, serve a
peer, meet a deadline. The harness cannot meet one, so a tenant's runtime obligations are its
**machines'**, discharged by its own software with no off-machine credential. A project with an
obligation it cannot move onto a machine is not a fit for this harness.
_Avoid_: background job, daemon work (both describe the mechanism rather than the duty)

**Watch-only** · `ARC-37`
Holding the public half of a key and nothing else: enough to derive addresses and observe that
payment arrived, never enough to spend. What a multi-tenant machine holds instead of a wallet.
_Avoid_: read-only (too general), cold (that describes where a key is, not whether one is present)

**Delegated obligation** · `ARC-38`
A runtime obligation met at a third party the operator chose, which notifies the machine, rather
than on the machine itself. The disposition that keeps a credential off a box hosting strangers,
at the price of an elective trusted party.
_Avoid_: outsourced, hosted (both suggest the harness arranged it; the operator did)

**Job record** · `STA-20`, `STA-21`
What the machine keeps about one box-plane command: the command **as received**, its output, its
exit code, and whether the process is still alive. Read on reconnect instead of guessing whether
a command finished. Machine-reported and advisory — the browser journal stays authoritative for
what was *sent*, and comparing the two catches honest mistakes, never a hostile machine.
_Avoid_: log, transcript (the transcript is the browser's, and authoritative)

**Delivery declaration** · `ARC-39`
A tenant's statement of what must be true of a finished machine — its listening surface, its
service lifecycle, whatever else it needs demonstrated. The harness measures against it rather
than assuming, because tenants disagree: one needs a service enabled and surviving reboot,
another needs a node that dies on reboot by design. A difference from the declaration is the
finding. It does not catch hostile use of declared surface, nor a declaration that is itself
wrong, and a vague one buys a weak check.
_Avoid_: allowlist, firewall rules (both name a mechanism; this is the tenant's statement of
intent, which a mechanism then enforces), spec (too broad)

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
The cloud path's introduction route: the browser plants a per-machine sender key in boot
configuration, and the machine's first boot seals its host-key fingerprints under that key and
gift-wraps them to a per-machine recipient key over Nostr. Both keys derive from the seed.
_Avoid_: remote attestation, TPM attestation (the hardware senses; "attestation" for route 5
itself is fine); "the secret" (there are two keys, and neither is stored)

**Notify channel** · `CHN-17`
The one way a machine speaks to the harness: an event, typed untrusted, that never gates and
never acts. Attest is its only use today.
_Avoid_: callback, webhook, command channel (all imply the machine can make something happen)

**Relay set** · `CHN-18`
The publisher's Nostr relay, which is mandatory, plus any public Nostr relays the operator adds.
_Avoid_: "the relay" — that is the TCP bridge, and a sentence that says it about an inbox is
wrong. A Nostr relay is always called that in full.

**Seed** · `STA-22`
The operator's BIP-39 mnemonic, from which every credential the browser derives comes: per
machine, the SSH client key and the two attest keys; per relay pass, the relay key; per
declared handoff, the post-harness credential. Never seen by a session or a machine; never in
the sheet. **This is the harness's seed.** A tenant may have a seed of its own (btc-policy's wallet
seed) which the harness never touches (`SEC-T4`); when both are in play, say *operator seed*
and *wallet seed*.
_Avoid_: master key, root key (both suggest something a session holds), "the user's nsec",
unqualified "seed" in any sentence that also mentions a vault
(a derived key is one of many, and none is the operator's social identity)

**Relay pass** · `CHN-15`, `CHN-16`
What is bought: the relay's record of which destinations a relay key may reach, until when, and
how fast. Paid for by invoice, bound to a key, never held as a value. There is no identity
behind it. Its key re-derives from the seed and exported pass index; losing the index can
lose the remaining quota.
_Avoid_: token, subscription, API key (all imply an account or a bearer string); "present the
pass" (one presents the key; the relay finds the pass)

**Relay key** · `CHN-15`, `SEC-5` row 4
The keypair the browser derives from the seed for one relay pass. Its public half is what the
relay binds a purchase to and what the first stage hands the publisher; its private half signs
the connection challenge, destination records, and revocation. Never stored, never bearer.
_Avoid_: relay credential (too vague), "the npub" (which of several)

**Drop-box** — retired. A one-time buffer the browser used to open at the relay before creating
a machine. Replaced by an inbox any Nostr relay provides (`CHN-4`). The name survives only in
the records that rejected relay-side single-use, which still applies to the inbox.

**Attest sender key** / **attest recipient key** · `CHN-7`, `SEC-5` rows 7 and 16
The per-machine pair attest runs on. The sender key's private half rides in boot configuration
and authorizes one introduction — an introduction **credential**, because possession of it lets
an actor seal an arbitrary fingerprint the browser will trust. The recipient key decrypts that
introduction. Both derive from the seed and neither is stored.
_Avoid_: voucher, token, nonce (all understate what the sender key authorizes); MAC secret (the
old mechanism)

**Rescue system** · `CHN-R1`, `STG-4`
The vendor's ephemeral boot environment on a dedicated server, used for installation. It
boots with **fresh host keys every time**, the vendor publishes their fingerprints only after
it has booted, and one activation is consumed by one boot. Never the installed system, and
never the harness's own recovery.
_Avoid_: recovery mode (recovery is the harness's ladder, `ARC-16`), live system, "rescue"
unqualified where the ceremony is meant

**Rescue ceremony** · `STG-4`, `STG-20`
The harness's typed sequence around a rescue system: register the machine's client key with
the vendor, activate rescue, reset, pin the rescue host key from the vendor, install, read
the installed host keys before the reboot, reset again. Deterministic, owned by the harness,
and no part of it belongs in a brief.
_Avoid_: rescue flow, install flow (the install is the brief's part, inside the ceremony)

**Pin** · `SEC-11`, `ARC-25`, `CHN-12a`
A fact about one endpoint, shipped or recorded in advance, that a presented thing is checked
against. Three exist: a **host-key pin** (a fingerprint), an **artifact pin** (a content hash
or a signing key plus revision), and an **issuer pin** (one issuing authority's certificate).
A pin delegates to nothing — a store holding exactly the pinned authority is a pin; a store
holding many authorities is a **trust store**, which is the unpriced object of `CHN-12b`.
_Avoid_: "the pin" unqualified where two kinds are in play; allowlist; whitelist; "root
store" for a store of one (it carries the general-trust sense)

**Artifact source** · `ARC-25`, `ARC-25a`, `TRU-E8`, `TRU-E8a`
Wherever the installed system's bits come from: an image, a mirror, a channel. An untrusted
dependency. Both distributions pin the bootstrap by hash and admit additional packages under
explicit signing keys. Alpine selects a repository branch; NixOS also pins its source revision.
The bootstrap hash is not a hash of the installed system.
_Avoid_: image host (too narrow), mirror (too narrow), **the pin** as a synonym for a content
hash (an artifact pin is one of two mechanisms — see **Pin**)

### State and recovery

**Exposure ledger** · `STA-10`
The per-machine history of every configured model that has ever touched it.
_Avoid_: audit log, history (unqualified)

**Recovery sheet** · `STA-16`
An exported record of derivation indices/resource mappings, host-key fingerprints, the
exposure ledger and the inference account credential, wrapped under a passphrase. It carries
no derived private keys; those re-derive from the seed plus the exported metadata.
_Avoid_: backup (unqualified), export file, "the keys" (they are not in it)

**Replace / Restore** · `STA-17`
The two recovery flows, deliberately distinct. **Replace** is a new seed, from which new keys
derive, with the old keys removed from every machine — the default, for a phone that is lost.
**Restore** re-derives the same keys from the same seed and does not revoke — for a phone that
died in hand. A restored seed may use recovered identities but cannot allocate new ones until
Replace, because an old export cannot prove the latest allocation counter (`STA-22b`).

**Recovery ladder** · `ARC-16`
What happens when a model cannot finish its machine: retry, escalate behind the same proxy,
then destroy and restart under a different domain.

**Action transcript**
A browser-side record of what one session actually did, captured before transmission. It is
**not** evidence about a machine, because no second model may inspect it against that machine.
_Avoid_: audit trail, proof

**Provenance record**
The claim that a machine was provisioned by a specific cloud vendor, configured model and
requested provider. It once claimed the *set* of providers *observed* serving it; the chosen
aggregator reports none. In the first version a local claim rather than evidence.
_Avoid_: attestation, certificate, lineage

### Trust and diversity

**Trust tier** · `05-trust.md`
Which kind of trust a party represents. **Unavoidable** — true of any software. **Elective** —
the operator or publisher chose it and could change it. **Added** — the only tier the design
controls and the only one an invariant guards.
_Avoid_: trust score, threat level

**Trust domain** · `ARC-14`
An independent way for an AI to be compromised. Counted at three configured layers — **weights**,
**proxy**, and the **provider** the harness requests per machine.

**Inference provider**
The party that actually serves the weights for a request. **Distinct from the proxy the session
connects to**, and distinct from the party that *made* the weights. **Requested** by the harness
in each call and shown under that label; not reported back by the chosen aggregator, which
documents that it may override the request. (`X-Provider-Name` is a different aggregator's
header and was recorded while that one was still the candidate.)
_Avoid_: AI provider, model provider, LLM vendor, serving provider; "observed provider" (there
is no observation today)

**Model**
The weights behind an inference provider. Two providers may serve the same model, so provider
diversity does not imply model diversity. This distinction is the whole security argument.

**Collision** · `OVR-6`
Two machines sharing a trust domain at any counted layer, the requested provider included.
Shown, not blocked.

**Procured inference** / **bring-your-own inference** · `ARC-31`, `ARC-31a`
The default path, where the operator funds an account-free balance at one aggregator and the
publisher selects the models — the publisher handling neither the money nor the credential; and
the advanced path, where the operator supplies their own tokens or runs inference locally.

**Inference account credential** vs **session inference key** · `ARC-31a`, `SEC-5` rows 14 and 2
The account credential is the procured path's upper tier: bearer, unrevocable, spendable, and
able to mint keys. A session key is minted from it with a cap and an expiry and revoked when the
session ends. A session holds only the second.
_Avoid_: "the inference key" for either one on its own; API key (says nothing about which tier)

### Money

**Recurring cost**
The machines. Billed by the cloud vendor to the operator's own account. The app never mediates
it and cannot stop it.

**One-off cost**
Inference credits. The app retrieves an invoice; the operator's wallet pays it.

**Settled invoice**
Evidence that the operator has funded credits at a provider. It does **not** prove which machine
used which proxy, because one top-up buys many queries.

## Flagged ambiguities

**"Instance"** is overloaded and must always be qualified.
- **Session** — one run of the harness under one set of weights, touching one machine. Prefer
  this over "AI instance".
- Never use bare "instance" for a virtual machine. Say **machine**.
- "Device" is not a unit of isolation here. Several sessions on one phone is the normal case.

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
