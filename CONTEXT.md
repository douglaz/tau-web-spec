# tau-web

A client-side AI harness that lets someone with only a phone provision and operate
real infrastructure, without trusting any party that could act on their behalf. Its
first tenants are Bitcoin custody (btc-policy) and server rental over Bitcoin (lnrent).

## Language

### Execution planes

**Cloud plane**:
The set of actions expressed as typed operations against a vendor's API — creating,
destroying, resizing, or paying for infrastructure. Enumerable, and therefore
approvable with structured metadata.
_Avoid_: control plane, provisioning layer, API layer

**Box plane**:
Free-form shell execution on a machine the operator already owns. Not enumerable, not
pre-approved, always recorded. This is where unanticipated problems get solved.
_Avoid_: data plane, runtime layer, remote shell

The split exists because the two have different shapes. Spending money is an
enumerable API; configuring a machine is not. The blast radius of box-plane code is
one machine already paid for; the blast radius of cloud-plane code is a credit card.

### Recipes

**Recipe**:
A document of instructions the AI reads and improvises from — prose plus example
commands, in the shape of an agent skill. It is *not* executed verbatim, so what runs
is not known before the AI runs it.
_Avoid_: script, playbook, runbook, template

**Recipe library**:
The collection of recipes available to an AI instance. Shared with lnrent, which
already provisions from its own deterministic scripts.

### Roles

**Session** (see also Flagged ambiguities):
One run of the harness under one set of model weights, responsible for exactly one
machine. Its deliverable is a provisioned, hardened, reachable machine that it has
demonstrated is locked down. It never touches key material.

**Coordinator**:
AI-free deterministic code, trusted during setup, running from the signed bundle on the
operator's device. It takes member endpoints plus operator-supplied recovery descriptors
and forms the federation by calling member APIs. It is the only party that contacts
every member, which is permitted precisely because it is not a model.

**Member**:
A machine running the vault software as part of a federation. Generates its own key
material locally and never exports it.

**Lightweight pentest**:
A session probing its own machine for open ports, default credentials, and exposed
services. A **competence** check, not an integrity check: it proves nothing against a
malicious model and does not need to, because malice is what the threshold absorbs.
Never run from another member.

### Trust and verification

**Honest-majority assumption**:
The security claim of the whole system: a majority of the models used across a
federation are honest and competent. Byzantine in shape. There is no verification
layer, and nothing may imply one.
_Avoid_: trustless, verified, provably secure

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
The default path. The operator pays one fee and the publisher selects models across
available proxies. Adds no new trusted party, because the publisher is already trusted
for the bundle, but it does mean the publisher chooses the weights.

**Bring-your-own inference**:
The advanced path. The operator supplies their own provider tokens or runs inference
locally, removing the publisher from model selection and, with local inference, the
proxy layer entirely.

**One trust domain, one machine**:
The invariant that protects the assumption. A trust domain accesses exactly one
machine and never reads, audits, or touches a machine it did not provision. Access
composes; letting one domain touch two machines halves the number of malicious domains
needed to reach a k-of-n threshold.

**Recovery ladder**:
What happens when a model cannot finish its machine. Retry, then escalate to a
stronger model **inside the same trust domain** (free, because that domain already has
access), then destroy the machine and restart under a different domain (costs a
server). Moving inside a domain is free; moving between domains costs money.

**Action transcript**:
A browser-side record of what one AI instance actually did, captured before
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
The service endpoint an AI instance talks to. Distinguishable at runtime via
`X-Provider-Name`.
_Avoid_: AI provider, model provider, LLM vendor

**Model**:
The weights behind an inference provider. Two providers may serve the same model, so
provider diversity does not imply model diversity. This distinction is the whole
security argument, not a pedantic one.

**Collision**:
Two machines sharing a trust domain at either layer. A collision reduces the effective
threshold below the nominal one. It is **shown, not blocked** — blocking would make the
default configuration impossible, since procured inference shares a proxy by design.

**Threshold**:
How many members must agree. **3-of-5 by default**; 2-of-3 for testing and small
values. Chosen for the operator rather than by them.

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
- **Approve an operation** — the user sees structured facts about one cloud-plane
  action and permits it. Only possible on the cloud plane.
- **Approve a scope** — the user permits a class of activity in advance. This is what
  box-plane work runs under, because its contents are not known in advance.

## Example dialogue

**Dev:** The AI needs to open port 8333 for the vault. Is that box plane or cloud
plane?

**Domain expert:** Both, and they're different acts. Editing `nftables` on the machine
is box plane — free bash, transcript, no modal. Adding a firewall rule at the vendor
is cloud plane, so it's a typed operation and the user sees a card.

**Dev:** Can't the AI just do it on the box and skip the card?

**Domain expert:** On the box, yes, and that's fine, it only affects a machine the
user already owns. It cannot reach the vendor's firewall, because the box plane has no
path to the cloud plane.

**Dev:** What if the recipe says to resize the machine because it ran out of disk?

**Domain expert:** Then the AI stops and raises a cloud-plane operation, because that
one spends money. The recipe can *suggest* it. Only a typed operation can *do* it.

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
