# tau-web

A client-side AI harness that lets someone with only a phone provision and operate
real infrastructure, without trusting any party that could act on their behalf. Its
first tenants are Bitcoin custody (btc-policy) and server rental over Bitcoin (lnrent).

This is the domain glossary. [`spec.md`](./spec.md) is the specification itself.

## Language

### Execution planes

**Cloud plane**:
Any action taken **off** the operator's machines with a credential they supplied — creating
or paying for infrastructure, and equally a call to any other third-party service. Carries
two approval modes. **Typed operation**: an adapter exists, the action is expressed as
structured facts, and each one is approved individually. **Untyped call**: no adapter, so the
operator approves a scope instead, and the harness claims nothing about what the credential
can do.
_Avoid_: control plane, provisioning layer, API layer

**Box plane**:
Free-form shell execution on a machine the operator already owns. Not enumerable, not
pre-approved, always recorded. This is where unanticipated problems get solved.
_Avoid_: data plane, runtime layer, remote shell

The split is **off-machine versus on-machine**, and each side carries its own reasoning
rather than sharing one. Box-plane work can be free-form because the worst case is ruining a
machine already paid for. Cloud-plane work has no such bound — it can spend or publish — so
where the harness can type an action it shows the facts, and where it cannot it records the
call and states plainly that the credential's authority is unknown to it.

### Briefs

**Brief**:
A document of instructions the AI reads and improvises from — prose plus example
commands, in the shape of an agent skill. It is *not* executed verbatim, so what runs
is not known before the AI runs it.
_Avoid_: script, playbook, runbook, template

**Brief library**:
The collection of briefs available to a session, shipped inside the signed bundle.

The format is **not** a shared primitive with lnrent, though an earlier version of this
entry called it a candidate one. lnrent's *recipes* are executables its daemon runs with high
privilege; these are prose that must never be run as written. They are not two spellings of
one artifact and cannot be merged. What is real is a **layering**: one of these documents
can tell the AI to invoke an lnrent hook as a deterministic tool.

### Roles

**Session** (see also Flagged ambiguities):
One run of the harness under one set of model weights, responsible for exactly one
machine. Its deliverable is a provisioned, hardened, reachable machine that it has
demonstrated is locked down. It never touches key material.

**Operator**:
The human at the browser — the person who holds the credentials, approves the operations,
and owns the machines. Deliberately abstract over the tenants: under btc-policy this is a
custody owner funding a vault, under lnrent a seller renting capacity out, and both of
those projects define **their own** narrower `Operator` for their own domain. Not a
customer, not an end user of anything the operator later runs.
_Avoid_: user, admin, owner, customer

**Coordinator**:
AI-free deterministic code, trusted during setup, running from the signed bundle on the
operator's device. It takes member endpoints plus operator-supplied recovery descriptors
and forms the federation by calling member APIs. It is the only party that contacts
every member, which is permitted precisely because it is not a model.

**btc-policy uses this word for a different component** — its operational relay, trusted
until the wrench attack and untrusted after, with an enumerated list of what a compromised
one can do. Different phase, opposite trust posture. Check the register in the meta project
before carrying the term across a repository boundary.

**Member**:
A machine running the vault software as part of a federation. Generates its own key
material locally and never exports it.

**Lightweight pentest**:
A session probing its own machine for open ports, default credentials, and exposed
services. A **competence** check, not an integrity check: it proves nothing against a
malicious model — where the tenant has a threshold, malice is what the threshold absorbs;
a single-machine tenant accepts that risk uncovered.
Never run from another member.

### Trust and verification

**Tenant**:
A project built on the harness, supplying its own briefs, its own software, and its own
security requirements. btc-policy and lnrent are the first two; ad hoc use is a tenant of
one machine and no requirements. **The harness never sets a tenant's threshold** — it
isolates and counts, and the tenant says what the counts must be.
_Avoid_: app, plugin, integration, use case

**Access model**:
A tenant's decision about whether its machines remain enterable after delivery — decided by
the tenant like the threshold, adapted to by the harness. **Maintained** — the session can
go back in, so ongoing operation means repair, patching, and the full re-check (lnrent, ad
hoc use). **Sealed** — the door is welded shut after setup by the tenant's own design, so
ongoing operation degrades to an external surface probe and an advisory watch whose only
remedy is replacement (btc-policy, where sealing is what makes duress protection real).
_Avoid_: maintenance mode, managed/unmanaged

**Honest-majority assumption**:
**btc-policy's** security claim, not the harness's: a majority of the models used across a
federation are honest and competent. Byzantine in shape. It needs a threshold to mean
anything, so it says nothing about a single machine — where nothing absorbs a malicious
model and the honest claim is smaller. There is no verification layer, and nothing may
imply one.
_Avoid_: trustless, verified, provably secure

**Trust tier**:
Which kind of trust a party represents, since the regress has no bottom and a flat list
reads as a scorecard. **Unavoidable** — the device, its OS, the browser, the stack
underneath; true of any software. **Elective** — the cloud vendor, the proxy, the inference
provider, the models, any service an approved untyped call hands a credential to, and the
signer of the software the machines run; real trust that the
operator or publisher chose and could change, and
exactly the set a hosted service picks for you silently. **Added** — the bundle and its
publisher, the relay, the coordinator; the only tier the design controls and the only one an
invariant guards.
_Avoid_: trust score, threat level

**Trust domain**:
An independent way for an AI to be compromised. There are two layers and they are
counted separately rather than collapsed:
- **Weights domain** — the model itself. Two members using different weights survive
  one set of weights being backdoored, even through a shared proxy.
- **Proxy domain** — the aggregator routing the request (OpenRouter, PayPerQ). A
  compromised proxy can alter every prompt and response it carries, whatever weights
  are behind it.

Independence at one layer is real protection at that layer and none at the other.
Saying "five models" when all five ride one proxy is true about weights and false
about proxies, so both counts are shown, never a single blended number.

**Procured inference**:
The default path. The operator pays one fee and the publisher selects the models, reaching
them through the one aggregator it has — so **every member rides a single proxy by design**,
which is exactly why a collision is shown rather than blocked. Adds no new trusted party,
because the publisher is already trusted for the bundle, but it does mean the publisher
chooses the weights.

**Bring-your-own inference**:
The advanced path. The operator supplies their own provider tokens or runs inference
locally, removing the publisher from model selection and, with local inference, the
proxy layer entirely.

**One session, one machine**:
The invariant that protects the assumption, stated at the layer where it can hold. A
session accesses exactly one machine and never reads, audits, or touches a machine another
session provisioned — except by re-binding: a later session re-enters a **maintained**
machine, or takes over a stuck one at the recovery ladder's middle rung, each bound to
that machine as its own. That binding is what the product can enforce.
Whether two machines end up served the *same weights* it cannot observe, so that case is a
displayed collision under the two-layer count, not a violation — the weights-level form,
no set of weights on more than one machine, is the goal the binding serves. Exposure lasts
for the machine's life, since ending a session removes nothing a model may have left
behind. Access composes; a model with a foothold on two machines halves the number of
malicious domains needed to reach a k-of-n threshold. The **proxy** layer is deliberately
outside this rule: on the default path one proxy serves every member, counted and
displayed rather than forbidden.
_Avoid_: one trust domain one machine (the pre-split form, which forbids the default
product at the proxy layer)

**Recovery ladder**:
What happens when a model cannot finish its machine. Retry; then escalate to a stronger
model **behind the same proxy** — cheap because the proxy gains no access it lacked, but
conditional, because the stronger model is new weights on the machine and must not be
assigned to another member; then destroy the machine and restart under a different
domain, which costs a server. Escalation re-binds the stuck machine to the successor
session — the third binding form — and past that rung the machine moves nowhere: it is
destroyed, never handed to any other session.

**Action transcript**:
A browser-side record of what one session actually did, captured before
transmission. Useful for the operator to read and for a member's own drift detection.
It is **not** evidence about a machine, because no second model may inspect it against
that machine.
_Avoid_: audit trail, proof

**Provenance record**:
The claim that a given machine was provisioned by a specific cloud vendor, inference
provider, and model. Durable, and in the first version a local claim rather than
evidence.
_Avoid_: attestation, certificate, lineage

**Verifier**:
A deterministic program that reads a machine and reports its security-relevant state,
run by that machine's own model. Useful for drift and honest mistakes within one
member. Explicitly **not** a defence against a hostile AI, because it reads what the
machine chooses to tell it.

### Diversity

**Inference provider**:
The party that actually serves the weights for a request, named at runtime by
`X-Provider-Name`. **Distinct from the proxy the session connects to**: on the default path
a session talks to an aggregator, which routes to one of these. Two machines whose requests
land at the same inference provider share a party that neither displayed count covers,
because the two counted layers are weights and proxy and this is neither.
_Avoid_: AI provider, model provider, LLM vendor, serving provider

**Model**:
The weights behind an inference provider. Two providers may serve the same model, so
provider diversity does not imply model diversity. This distinction is the whole
security argument, not a pedantic one.

**Collision**:
Two machines sharing a trust domain at either layer. A collision reduces the effective
threshold below the nominal one. It is **shown, not blocked** — blocking would make the
default configuration impossible, since procured inference shares a proxy by design.

**Threshold**:
How many members must agree. A tenant fact — this default is **btc-policy's**: 3-of-5,
with 2-of-3 for testing and small values, chosen for the operator rather than by them.
The harness never sets one; it isolates and counts.

**Effective threshold**:
The threshold expressed in trust domains rather than in members, per layer. A 3-of-5
federation on five sets of weights behind one proxy is 3-of-5 against backdoored
weights and 1-of-1 against a backdoored proxy. Both numbers are true and both are
shown.

### Money

**Recurring cost**:
The machines. Billed by the cloud vendor to the operator's own account, on their own
payment method. The app never mediates it and cannot stop it.

**One-off cost**:
Inference credits. The app retrieves an invoice from the provider; the operator's wallet
pays it. The app relays, never custodies.

**Settled invoice**:
Evidence that the operator has funded credits at a provider. It bounds which proxies are
available. It does **not** prove which member used which proxy, because one top-up buys
many queries — that evidence is `X-Provider-Name` on each response.

## Flagged ambiguities

**"Instance"** is overloaded and must always be qualified.
- **Session** — one run of the harness configured with one set of model weights,
  touching one machine. A federation is provisioned by several concurrent sessions on
  a single device. Prefer this over "AI instance".
- Never use bare "instance" for a virtual machine. Say **machine**.
- "Device" is not a unit of isolation here. Five sessions on one phone is the normal
  case; the separation that matters is between model weights.

**"Member"** means a machine that will become a federation member. In the first
version nothing has joined a federation, so a machine is not yet a member.

**"Approve"** means two different things and both are in play.
- **Approve an operation** — the operator sees structured facts about one cloud-plane
  action and permits it. Only possible on the cloud plane.
- **Approve a scope** — the operator permits a class of activity in advance. This is what
  box-plane work runs under, because its contents are not known in advance, and what an
  untyped cloud-plane call runs under, because no adapter exists to type it. **A scope names
  where a credential goes, not what it can do.** For box-plane work the machine bounds the
  damage; for an untyped call nothing does, and the interface may not imply otherwise.

## Example dialogue

**Dev:** The AI needs to open port 8333 for the vault. Is that box plane or cloud
plane?

**Domain expert:** Both, and they're different acts. Editing `nftables` on the machine
is box plane — free bash, transcript, no modal. Adding a firewall rule at the vendor
is cloud plane, so it's a typed operation and the operator sees a card.

**Dev:** Can't the AI just do it on the box and skip the card?

**Domain expert:** On the box, yes, and that's fine, it only affects a machine the
operator already owns. It cannot reach the vendor's firewall, because the box plane has no
path to the cloud plane.

**Dev:** What if the brief says to resize the machine because it ran out of disk?

**Domain expert:** Then the AI stops and raises a cloud-plane operation, because that
one spends money. The brief can *suggest* it. Only a typed operation can *do* it.

**Dev:** Machine 1 looks misconfigured. Can I point the model from machine 2 at it to
check?

**Domain expert:** No. That model would then have access to two machines, and the only
thing protecting the operator is that no model reaches the threshold. Your audit hands
one model a second foothold. If machine 1 is wrong, its own model fixes it, or you
destroy it and start again.

**Dev:** So nothing ever checks anyone's work?

**Domain expert:** Nothing does. The claim is not "we verified it." The claim is "no
single model provisioned enough members to matter." Those are different sentences and
only the second one is true, so only the second one gets said.
