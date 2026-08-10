# Executive summary

tau-web is a client-side AI harness: an application that runs entirely in a phone
browser and provisions real infrastructure on its operator's behalf. There is no
server-side agent and no hosted orchestrator: nothing provisions a machine except the
operator's own device. It exists so that a non-technical person can stand up and
operate machines whose value depends on not handing any one party the ability to act
on all of them.

That is the goal, not an achieved property. Several parties remain trusted, the design
record still records the "no party the user must trust with the ability to act"
constraint as unsatisfied, and the section below names every party by hand rather than
claiming the list is empty.

There is no code in this repository. What exists is a domain language, fourteen
decisions recording what was chosen and — for most of them — which alternatives were
rejected and why, a design record with three rounds of adversarial review, and an
archived specification of the execution layer. A working
proof of concept lives in a separate repository and has established the one external
fact everything depends on: a browser can call a cloud vendor's API directly.

## The problem

Agentic AI is desktop-gated. Technical users run real harnesses against the best models
and get an AI that *acts*; everyone else gets a chat box, because installing and
configuring a harness takes technical knowledge and usually a desktop. The people who
would gain the most have only a phone.

The obvious fix is a hosted agent platform, and for one class of task it is unavailable
in principle. Anything whose value depends on *not* trusting a host — self-custody,
key management, sovereign infrastructure — cannot be delegated to a host. A single
party that provisions every member of a Bitcoin custody federation has defeated the
federation, whatever its intentions. For those tasks the gap can only be closed in the
browser.

Two intended tenants: **btc-policy**, self-hosted Bitcoin custody built on a federation
of policy co-signers, and **lnrent**, server rental paid over Bitcoin. The second turns
out to be load-bearing for the first, because a federation across five vendors means
five billing relationships, and renting for sats with no account is the only escape
from that.

## Who it is for

Sharper than "non-technical users." The threshold is 3-of-5 by default, which means
five machines, which at the reference price of €4.59/month is **€275 per year** before
inference. At a willingness to pay roughly 1% per year for custody, that implies
holdings near €27,500. There is no configuration that makes sense for someone holding
€1,000: the floor is three machines and three machines cost what they cost.

The target is therefore **a non-technical person with meaningful Bitcoin** — someone
with real reason to leave a custodian, for whom the fee is negligible against the
amount at stake. Stating this is better than letting someone discover it after
budgeting for a hobby.

## How it works

**The AI runs only in the browser.** A provisioned machine is a target, never an actor.
It never holds an inference key or a vendor API token and never initiates work. The
consequence is accepted rather than worked around: nothing runs while the app is
closed, so every step must be resumable across a locked phone.

**Actions split into two planes.** Cloud-plane actions — create, destroy, resize,
firewall, pay — are typed operations carrying structured metadata, and each one is
approved on its own facts rather than on the command text. (Setup is the batched case:
every machine creation is known in advance, so all five are approved together on one
screen, and only the unforeseen cloud-plane actions arrive individually later.)
Box-plane actions are free-form shell on a machine the operator already
owns: no individual command is pre-approved, because none is known in advance, but the
class of activity runs under a scope the operator approved, and everything is recorded.
Approving an operation and approving a scope are two different acts and the interface
must not blur them. The split exists because the two have
genuinely different shapes. Spending money is an enumerable API; configuring a machine
is not, and that is exactly where unanticipated problems live. Blast radii differ by
orders of magnitude — box-plane code can ruin one machine, cloud-plane code can spend a
credit card. The box plane has no path to the cloud plane.

**Recipes are instructions, not scripts.** Prose plus example commands, in the shape of
an agent skill. The AI reads a recipe and decides what to actually run. A script stops
dead at the first surprise, and the AI exists precisely for the surprises — a changed
image name, a package that will not install, a service that will not start. The cost is
paid honestly: what runs is not known before it runs, which is why approval needs
structured facts from the cloud plane rather than from command text.

**One trust domain, one machine.** Each model accesses exactly one machine and never
reads, audits, or touches a machine it did not provision. Access is what composes, not
intent: letting one model touch two machines halves the number of malicious models
needed to reach a k-of-n threshold. Five sessions run concurrently on the one device
the operator owns, each on different model weights, with all five machine creations
approved together in a single screen before any work begins.

**The AI's deliverable is a locked-down machine, demonstrated.** Hardening is a
property the session must show with a lightweight self-directed pentest, not a step it
reports having done. That pentest is a **competence check, not an integrity check** — a
model examining its own machine proves nothing against a malicious model, and does not
need to, because malice is what the threshold absorbs. What it catches is
honest-but-sloppy, which is the likely failure on a first-time setup. The job is
deliberately not uniform across vendors, because the
vendors are not uniform — Hetzner Cloud has no image upload API at all, while others
offer import paths that differ from each other. That heterogeneity is an argument *for*
the AI, not against it.

**The coordinator is AI-free.** Deterministic code from the signed bundle takes member
endpoints plus operator-supplied recovery descriptors and forms the federation by
calling member APIs. It is the only party that contacts all five members, which is
permitted precisely because it is not a model. The AI never touches key material:
member keys are generated on the machine and never exported.

**A vault is not finished when it is created.** Each member is periodically re-checked
by its own session: the pentest re-run, and upstream releases and security advisories
reviewed for the software that member runs. This is the work an AI is unusually well
suited to and that a non-technical operator will never do — reading CVE feeds for a
handful of components and deciding which matter to this configuration — and not doing
it is how a correctly-built vault becomes a vulnerable one over a year. It requires the
operator to open the app, since nothing runs while it is closed, and each re-check
costs inference on top of the machines.

## The security claim, stated exactly

**No single model provisioned enough members to reach the threshold.**

That is the whole claim, and it is conditional on the trust domains being genuinely
distinct. If several endpoints serve the same weights, the operator has one model
rather than five and the claim is vacuous — which is why the counting below is shown
to them, and why item 3 of the unresolved list matters: at the weights layer that
distinctness may not be enforceable at all, and until it is, this is a design goal
rather than a demonstrated property.

There is no verification layer, and nothing in the product may
imply one. Every scheme where a second model inspects a finished machine hands that
model a second foothold and weakens the threshold doing the real work. A deterministic
verifier reads whatever the machine chooses to tell it and cannot beat a hostile AI; it
survives only for drift detection and honest mistakes inside a single member, run by
that member's own model. "Verified" and "no anomalies found" are claims this design
cannot make.

Independence is counted at **two layers and never blended into one score**. Weights —
how many distinct sets of model weights are in use. Proxy — how many distinct
aggregators route the requests. Five members on five sets of weights behind one proxy
survive a backdoored model and do not survive a backdoored proxy. Both numbers are
true; one number would be a lie about whichever layer is thin, and the thin layer is
the one that gets exploited.

Two further footholds are closed explicitly. Members reach each other only on the vault
protocol port, mutually authenticated, everything else denied at the vendor firewall —
because network reachability is a foothold on the same terms as a credential, and a
model able to attack four other machines produces *correlated* faults, the one
assumption a threshold cannot survive losing. And recipes ship inside the signed
bundle, because a recipe is prose that steers every member at once: n honest, competent
models faithfully following poisoned instructions all build the wrong machine and agree
with each other perfectly while doing it.

One foothold is deliberately opened, and it is the newest surface in the design. The
periodic audit above reads advisory feeds and release notes, which are external content
that steers the model — so the feature meant to keep the vault safe is also a way in.
An advisory reading "critical: upgrade immediately to package X from repository Y" is a
supply-chain attack delivered through the audit. Three rules follow: fetched advisory
content is typed as untrusted and can never authorize an action by itself; advisory
review reports rather than acts, so any resulting change is a normal operation needing
normal approval however urgent the advisory claims to be; and the set of feeds ships
signed like the recipes, since a feed URL changeable at runtime steers every member at
once.

A second correction belongs here, on the same terms as the one below about the relay.
The decision record introducing the audit calls it "the first capability in the design
that lets arbitrary internet content reach the model," on the grounds that everything
before it was operator input, vendor APIs, or signed recipes. That is too strong: any
box-plane command already returns attacker-influenceable text — package manager output,
a downloaded README, a service log — and the specification types *all* tool output as
untrusted, not just fetched feeds. So the three rules above are not special to
advisories; the separation between instruction and content applies from the first shell
command on the first machine. What is genuinely new about advisory feeds is that
fetching remote text becomes a deliberate capability rather than a side effect, which
is what makes the feed list worth signing.

## What must still be trusted

Named plainly, because the product's pitch is the opposite of asking for trust:

- **The app bundle.** It is the one component not diversified across members, and it
  carries the recipes. A compromised host can serve one build that misbehaves on every
  member, and can serve a good bundle to anyone who looks like a checker. Reproducible
  builds make this detectable, not preventable, and the target operator will not verify
  a hash on a phone. The mitigation that works is third-party watchdogs, which requires
  reproducible builds to exist and someone to run the checks — neither is true today.
  This is the largest concentrated risk in the design.
- **The cloud vendor**, under every design considered. It owns the VM's memory and
  disk. Host-key pinning buys transport safety, not vendor independence; vendor
  independence is what multi-vendor membership buys.
- **The inference proxy — and on the default path there is only one of it.** Procured
  inference means the publisher routes every member's requests through the aggregators
  it has, so the normal configuration is five sets of weights behind a single proxy.
  That proxy can alter every prompt and response it carries, which makes it the thinnest
  layer in the default product even when the weights count looks healthy. Adding a
  second proxy, or supplying your own inference, is what moves it.
- **The operator's device.** It holds the credentials, runs the bundle, and carries all
  five concurrent sessions, so it is common-mode across every member. This is a
  deliberate trade: requiring five devices would defend against a compromised phone
  while guaranteeing that an operator who owns one phone never finishes setup.
- **The publisher**, on the default path, because it selects the models. Acceptable
  only because it is already trusted for the bundle and because bring-your-own
  inference exists as the escape hatch. If that escape hatch is ever dropped, the
  arrangement stops being defensible.
- **A majority of the models**, being both honest *and* competent. Honest-but-sloppy is
  the likely failure on a first-time setup, and no mechanism here catches a mistake
  everyone makes the same way.

Two more parties are trusted narrowly rather than fully, and both are worth naming so
the list cannot grow quietly later. The **coordinator** is trusted during setup: it is
the only party that contacts all five members, permitted because it is deterministic
code rather than a model. The **relay**, once it exists, cannot read or alter an SSH
session whose host key was pinned out of band, but it holds more authority than that
sentence suggests: it learns connection metadata — which operator, which destination,
when — and a relay that authenticates callers and constrains destinations decides *who
may connect where*.

  One correction belongs here rather than in a footnote. The design record settles the
  relay as "an availability dependency, not a trust one," where a hostile relay is a
  denial of service "and nothing worse." That holds for the routes that pin the host key
  out of band. It does not hold for the trust-on-first-use fallback the same record keeps
  as its always-works floor: at first contact there is nothing to check the key against,
  so a hostile relay can present its own and have it pinned, and reads the session from
  then on. Under TOFU the relay is trusted at first contact. Every route that retrieves
  or injects the fingerprint exists to avoid exactly that, which is why the floor is a
  floor and not a plan.

Origin diversity — a different mirror per member — was considered and rejected on user
safety, not security. Telling someone to open a second URL on a second device is
behaviourally identical to phishing, and the target operator is the person least
equipped to tell the difference.

## The two layers of documentation

They sit at different levels and were written in the opposite order to how they should
be read.

The **archived specification** is the execution layer: a Rust-first PWA compiled to
WebAssembly, a harness kernel derived from Tau's event and protocol concepts, an
end-to-end asynchronous Bash interpreter over `brush-parser`, WASI Preview 1 uutils
guests for real Unix commands, capability-scoped tools, and a dedicated worker owning
all mutable state. It carries 15 architectural decisions, 10 invariants — commit before
derived state, commit intent before side effect, no blind replay of uncertain side
effects, secrets never in model context — 14 MVP acceptance criteria, a 29-crate
workspace, and milestones M0 through M6. It remains the only detailed treatment of the
execution machinery, including the relay requirements and the untrusted-content rules
that later decisions rely on.

The **decision records** are the product and security architecture, and they are newer.
They were produced by grilling a design session that had already weighed three ways to
build this and rejected the one nearest the specification: harness kernel first as the
substrate, the cloud tooling folded in as its first tools, then the vault, then the
shell — which also means correcting the specification's own milestone order, since it
schedules the shell before the kernel. That path was costed end to end at four to six
months of unaided work and rejected for spending them before anyone sees anything, while
every scope question in the shell specification is still answered by guess. The chosen
path is cheaper, but the two figures do not compare: only its first stage
is estimated, at ten to twelve weeks, and the stage after that is explicitly unestimated,
because it is gated on the SSH spike that item 1 of the unresolved list below calls the
most likely to fail. (The specification stops short of the vault entirely — it specifies
the browser-side apparatus that provisions and drives machines, not anything that runs
on one.) The chosen first move is far smaller — two independently provisioned machines
with visibly different provenance, no federation, no vault — and the honest framing is
that this *displays* provenance rather than proving it, since a provenance record is a
local claim and forgery resistance is out of scope at this stage. It is not a claim that
anyone's bitcoin is safe.

Where the two disagree, the decisions win. The specification is kept because nothing
has replaced its execution-layer material and the decisions cite its section numbers.

## What is unresolved

Five items, in rough order of how much they gate:

1. **The browser-to-machine channel.** The mechanism is chosen — SSH, with host key
   verification as the pin, over a WebSocket-to-TCP relay. Once the right key is
   pinned, the transport underneath is irrelevant to confidentiality and integrity;
   before it is, the pin is the whole problem, which is what the routes below are
   about. The mechanism is not proven. It needs a WASM
   SSH client compiled to `wasm32-unknown-unknown` with its transport swapped for a
   WebSocket, which is a real spike and the thing most likely to fail. Four routes to
   the fingerprint are documented, from vendor API retrieval down to trust-on-first-use
   with continuity as the always-works floor, so the channel has a fallback even if
   retrieval fails everywhere.
2. **The relay itself.** Reinstating it reverses an earlier decision to have none. A
   WebSocket-to-arbitrary-TCP relay with no authentication is an open proxy and will be
   abused within days of being reachable. The specification already imposes the right
   requirements — authenticate the user, enforce destination policy, prevent generic
   open-proxy behaviour — and adopting those is the resolution. A relay that
   authenticates callers holds real authority over *who may connect where* even while
   holding none over *what is said*; both statements are true and the second does not
   cancel the first.
3. **Weights-level diversity may not be enforceable.** The available runtime signal
   names the serving provider, not the weights behind it. If it stays that way the
   honest position is to enforce provider diversity, say so plainly in the interface,
   and stop claiming more.
4. **The cloud-account floor.** Paying for inference is nearly solved — one of the
   aggregators takes Lightning with no registration, though whether a browser can reach
   it at all is still unprobed, and topping it up buys proxy diversity rather than
   weights diversity — but cloud vendors want an account, a card, and a recurring
   relationship, several times over. Invoice relay cannot fix this because vendors do
   not sell that way, which is what makes lnrent structural rather than a second tenant.
5. **A stalled setup bills.** Federation creation is all-or-nothing, approvals are
   batched up front, and nothing runs while the app is closed — so an interrupted setup
   is five machines billing with no progress. The product needs an opinion about when
   to prompt for resume or abandonment, and abandonment has to be a first-class action.

Four smaller items are each one call, one probe, or one boot away from closing: what a
vendor's
rescue API actually returns in its host-key field; whether the second inference proxy is
reachable from a browser at all; whether a second cloud vendor's API permits a browser
origin the way the first was shown to, which is roughly eighty lines of curl and is what
the vendor independence above depends on; and a code-read finding that the proof of
concept's cloud-init probably boots an unreachable machine — its user list has no
default entry, so injected keys reach no account. The fix is one line and nobody has
booted the file.

## Status and the next move

Nothing here has touched a real server. The proof of concept can talk to a vendor API
from a browser and has verified there is no CORS obstacle; it cannot yet create a
machine, and its approval screen and provisioning state machine are unbuilt.

The cheapest way to find out which of these decisions is wrong is not to write code.
It is to **write three recipes by hand — create a machine, harden it, install one vault
member — and run them against a disposable project.** That settles three things nothing
else can: which commands genuinely need to run in the browser versus on the machine,
whether the local/remote split is a seam a recipe author trips over, and, most
valuable, which steps could not be expressed as boot-time configuration at all. If the
answer to the last one is "none," provisioning needs no live channel and this plan gets
dramatically smaller — though the channel itself does not disappear, because the
coordinator still has to reach five member APIs on machines with no valid certificate,
and the periodic re-check has to reach a running member long after boot.
