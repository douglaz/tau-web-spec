# Executive summary

A short read of [`spec.md`](./spec.md), which is the full statement of the system.
Everything here is stated there in more detail, and where the two differ, the
specification wins. It is also the only place the open questions are maintained.

## What it is

tau-web is a client-side AI harness: an application that runs entirely in a phone browser
and provisions real infrastructure on its operator's behalf. Nothing provisions a machine
except the operator's own device — no server-side agent, no hosted orchestrator. It exists
so that a non-technical person can stand up machines whose value depends on not handing
any one party the ability to act on all of them.

That is the goal, not an achieved property. Several parties remain trusted, and the
specification names each of them by hand rather than claiming the list is empty.

There is no code in this repository. What exists is the specification this summarises, a
domain language, eighteen decisions recording what was chosen and — for most of them — which
alternatives were rejected, a design record with three rounds of adversarial review, and an
archived specification of the execution layer. A working proof of concept in a separate
repository has established the one external fact everything depends on: a browser can call a
cloud vendor's API directly.

## The problem

Agentic AI is desktop-gated. Technical users run real harnesses against the best models
and get an AI that *acts*; everyone else gets a chat box. The people who would gain most
have only a phone.

**And the gap is widening.** Most people are mobile-only and will stay that way, while both
mobile platforms keep tightening what may be installed outside their stores. The browser is
not a compromise accepted for convenience — it is the last route by which a non-technical
person reaches real compute, and real AI, without someone else configuring it for them.

The obvious fix is a hosted agent platform, and for one class of task it is unavailable in
principle. Anything whose value depends on *not* trusting a host cannot be delegated to one,
because the host becomes the party you were trying not to need. A vault whose members were
all provisioned by a single party has been defeated by that party, whatever its intentions.

So: a harness in the browser that provisions and operates machines the operator rents and
controls. **Tenants build on it.** Two are intended — **btc-policy**, self-hosted Bitcoin
custody on a federation of policy co-signers, and **lnrent**, server rental paid over
Bitcoin — and ad hoc use is a third that needs neither. The second turns out to be
load-bearing for the first, because a federation across five vendors means five billing
relationships, and renting for sats with no account is the only escape from that.

## Who it is for

Someone mobile-only who wants a machine — or a service, or an authenticated call — that is
theirs rather than a hosted product's. Deliberately wider than any one tenant, and the
harness has no narrower answer.

Each tenant's economics then differ sharply, and they are tenant facts rather than product
facts. **btc-policy** defaults to 3-of-5, so five machines, so **€275 per year** at the
reference price before inference — implying holdings near €27,500 at roughly 1% per year for
custody, and making no sense at all for someone holding €1,000. That tenant's target is a
non-technical person with meaningful Bitcoin. **lnrent** inverts the arithmetic: an operator
is one machine, and dedicated hardware is the best value for rental. **Ad hoc use** carries
neither.

## How it works

**The AI runs only in the browser.** A machine is a target, never an actor: it holds no
inference key, no vendor token, and never initiates work. The consequence is accepted
rather than worked around — nothing runs while the app is closed, so every step must be
resumable across a locked phone.

**Actions split into two planes, off-machine and on.** The **cloud plane** is anything done
off the operator's machines with a credential they supplied — creating or paying at a vendor,
and equally a call to any other service. Where an adapter types the action it is approved on
structured facts rather than command text; where none does, the operator approves a scope
naming the credential and the host, every call is recorded before it is sent, and the harness
**claims nothing about what that credential can do** — for most services it cannot know. The
**box plane** is free-form shell on a machine the operator already owns: nothing is
pre-approved, because nothing is known in advance, but it runs under an approved scope and
everything is recorded.

Each side carries its own bound rather than sharing one. Box-plane work can be free-form
because the worst case is ruining a machine already paid for. Cloud-plane work has no such
bound — so an untyped call means approving a key's full authority at a host, and the
interface has to say that rather than imply a limit. The box plane has no path to the cloud
plane.

**Briefs are instructions, not scripts.** The AI reads prose plus example commands and
decides what to run. A script stops dead at the first surprise, and the AI exists precisely
for the surprises. Briefs ship inside the signed bundle, because a brief is prose that
steers every member at once and diversity buys nothing against it.

**One session, one machine.** Each model accesses exactly one machine and never touches
one it did not provision. Access composes, not intent. Five sessions run concurrently on
the one device the operator owns, each configured with a different model — what a session
is actually configured with, since the inference provider that ends up serving it is known
only from the response, and whether two models rest on different *weights* is not checkable
at all — with all five machine creations approved together before any work begins. That access rule is absolute; how many
*distinct* trust domains are in play is a separate count, and at the proxy layer the
default product deliberately shares one — which is displayed rather than forbidden.

**The deliverable is a locked-down machine, demonstrated** by a lightweight self-directed
pentest — a **competence check, not an integrity check**. A model examining its own machine
proves nothing against a malicious model and does not need to, because malice is what the
threshold absorbs. What it catches is honest-but-sloppy, the likely failure on a first-time
setup.

**The coordinator is AI-free.** Deterministic code from the signed bundle forms the
federation by calling member APIs. It is the only party contacting all five members,
permitted precisely because it is not a model. Federation creation is all-or-nothing, so
abandonment has to be a first-class action.

**Members reach each other only on the vault protocol port**, mutually authenticated,
everything else denied at the vendor firewall — because reachability is a foothold on the
same terms as a credential, and a model able to attack four other machines produces
*correlated* faults, the one assumption a threshold cannot survive losing.

**The browser reaches a machine over SSH**, verifying the host key against a fingerprint
obtained by other means, through a relay that carries ciphertext. Once the right key is
pinned the transport is irrelevant to confidentiality and integrity. Under the fallback that
pins on first contact it is not — and that fallback is currently the only route reachable on
the cloud path, while being itself unusable until a pin can survive a replaced phone. The
channel is chosen, not built, and this is the sharpest reason why.

**A machine is not finished when it is delivered.** Each is periodically re-checked by its
own session, and advisories for the software it runs are reviewed. How far the re-check can
go is the tenant's call — its *access model*: maintained machines (lnrent, ad hoc) get
repair, patching and the full re-check; sealed ones (btc-policy welds the door shut after
setup, deliberately) get an outside-only surface probe and advisories whose sole remedy is
replacement. The advisory watch deliberately opens a foothold — an advisory reading
"critical: upgrade immediately" is a supply-chain attack delivered through the audit — so
fetched content is untrusted, review reports rather than acts, and the feed list ships
signed.

## The security claim, stated exactly

The harness and its tenants claim **different** things, and blurring them is how a single
machine ends up shipping under a vault's guarantee.

**The harness claims** that no session reaches a machine it did not provision, that a
model's blast radius is the machines it provisioned, and that the trusted set is fixed and
small. What it *removes* is the party that would otherwise pick the operator's vendor, model
and configuration while holding their credentials.

**It does not claim the model is honest, and cannot.** With one machine there is no
threshold, so nothing absorbs a malicious model — a compromised one owns the machine it just
configured. Ad hoc use ships under that smaller claim rather than borrowing a larger one.

**btc-policy stacks its own on top:** *no single model provisioned enough members to reach
the threshold.* That needs a vault, and it is conditional on the trust domains being
genuinely distinct — if several endpoints serve the same weights, the operator has one model
rather than five and it is vacuous. At the weights layer that distinctness may not be
enforceable at all, which makes it a design goal rather than a demonstrated property until
it is.

There is no verification layer and nothing may imply one. Any scheme where a second model
inspects a finished machine hands that model a second foothold. "Verified" and "no
anomalies found" are claims this design cannot make.

Independence is counted at **two layers and never blended into one score** — how many
distinct sets of weights, and how many distinct proxies route the requests. Five members on
five sets of weights behind one proxy survive a backdoored model and do not survive a
backdoored proxy. One number would be a lie about whichever layer is thin, and the thin
layer is the one that gets exploited.

## What must still be trusted

There is no zero. Everything runs on silicon, an operating system, a browser, a model, a
vendor — chase that regress far enough and you are fabricating chips by hand. So the list is
not short, and the useful question is not how many parties but **who chose them**.

**Unavoidable**, true of any software at all: the operator's device — its silicon, its
operating system, its browser — and the stack underneath the machines, their package
repositories and the certificate authorities.

**Elective** — real trust, chosen by the operator or the publisher and changeable. The cloud
vendor, which owns its machine's memory and disk. The inference proxy, of which the default
path has exactly one, making it the thinnest layer even when the weights count looks healthy.
The inference provider behind it, which actually runs the weights and is covered by neither
displayed count. A majority of the models, being both honest *and* competent. Whoever signs
the vault software, since every member installs the same release. **This is precisely the
set a hosted service picks for you, silently and unlisted.**

**Added by this product** — the only tier the design controls, and the only one an invariant
guards. The app bundle and its publisher, which is the application rather than a third party
but is not diversified and carries the briefs, making it the largest concentrated risk. The
relay, the one genuinely new third party, which cannot read a session pinned out of band but
does learn who connects where. The coordinator, narrowly and during setup, as the only party
that contacts every member.

What the product removes is the party that would otherwise choose every entry in the middle
tier and hold the credentials too: the service operator. That is the whole claim, and it is
smaller than "trustless" — but it survives the regress.

## What is not settled

The specification carries eighteen open questions in one maintained list. Six gate the
work: the SSH client compiled to WebAssembly, which is the single item most likely to fail;
who *operates* the relay, since what it must do is already settled; how the browser
authenticates *itself* to a machine, which host-key pinning does nothing for, and what
happens to browser-held key material when a phone is replaced; whether weights-level
diversity is enforceable at all, which the security claim is conditional on; the
cloud-account floor that makes lnrent structural; and what the product should do about a
stalled setup that keeps billing. Under the first-stage decision, the channel questions
gate week one rather than a later phase.

## Status

Nothing here has touched a real server. The proof of concept can talk to a vendor API from
a browser; it cannot yet create a machine.

The first stage is **one lnrent box on a dedicated server, over the full channel** — the
hardest machinery on purpose, so the item most likely to fail (an SSH client compiled to
WebAssembly) fails in week one or clears the way. The vault, with its concurrent sessions,
trust panel and federation, is the second stage and reuses the channel the first one
proves.

The cheapest way to find out which of these decisions is wrong is still not to write code:
run the first stage by hand once against a disposable dedicated server, and write the
briefs for its steps as you go — they are the first three the product needs.
