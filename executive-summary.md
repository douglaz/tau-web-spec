# Executive summary

A short read of the specification, which begins at [`00-overview.md`](./00-overview.md).
Everything here is stated there in more detail, and where the two differ, the specification
wins. **This document carries no counts and no normative rules** — those live in the numbered
topic files under their own identifiers, so that changing one changes it in one place.

## What it is

tau-web is a client-side AI harness: an application that runs entirely in a phone browser and
provisions real infrastructure on its operator's behalf. Nothing provisions a machine except
the operator's own device — no server-side agent, no hosted orchestrator. It exists so that a
non-technical person can stand up machines whose value depends on not handing any one party the
ability to act on all of them.

That is the goal, not an achieved property. Several parties remain trusted, and
[`05-trust.md`](./05-trust.md) names each of them by hand rather than claiming the list is
empty.

There is no code in this repository. What exists is the specification, a domain language, a set
of decision records with the alternatives they rejected, a conformance checklist, a design
record carrying three rounds of adversarial review, an engineering review, and an archived
specification of the execution layer. A proof of concept in a separate repository has
established the one external fact everything depends on: a browser can call a cloud vendor's
API directly.

## The problem

Agentic AI is desktop-gated. Technical users run real harnesses against the best models and get
an AI that *acts*; everyone else gets a chat box. The people who would gain most have only a
phone.

**And the gap is widening.** Most people are mobile-only and will stay that way, while both
mobile platforms keep tightening what may be installed outside their stores. The browser is not
a compromise accepted for convenience — it is the last route by which a non-technical person
reaches real compute without someone else configuring it for them.

The obvious fix is a hosted agent platform, and for one class of task it is unavailable in
principle. Anything whose value depends on *not* trusting a host cannot be delegated to one,
because the host becomes the party you were trying not to need. A vault whose members were all
provisioned by a single party has been defeated by that party, whatever its intentions.

So: a harness in the browser that provisions and operates machines the operator rents and
controls. **Tenants build on it** — Bitcoin custody, server rental over Bitcoin, and ad hoc use
that needs neither. The second turns out to be load-bearing for the first, because a federation
across several vendors means several billing relationships, and renting for sats with no account
is the only escape from that.

## How it works

**The AI runs only in the browser, and it is a trusted party.** A machine is a target, never an
actor: it holds no inference key and no vendor token belonging to the harness, and it never
initiates work. Its one outbound message, the attest introduction, acts on nothing on its
behalf.

But the model has a root shell on the machine it is bound to, and the design says so plainly
rather than pretending a rule could take that away. It is the operator's agent, which is the
whole point. What the harness does is **minimize** what the model can reach and **count** what
remains — and where a tenant genuinely needs the model kept away from secrets, that tenant
designs its procedure for it, as Bitcoin custody does by sealing its nodes after setup.

The consequence is accepted rather than worked around: nothing runs while the app is closed, so
every step must survive a locked phone. Durable state is an append-only journal, and an
interrupted brief is re-run from the top and converges rather than resuming a step it cannot
identify.

**Actions split into two planes, off-machine and on.** The **cloud plane** is anything done off
the operator's machines with a credential they supplied. Where an adapter types the action it is
approved on structured facts; where none does, the operator approves a *scope* naming the
credential and the origin, every call is recorded before it is sent, and the harness **claims
nothing about what that credential can do** — for most services it cannot know. The **box plane**
is command-at-a-time shell on a machine the operator already owns: nothing is pre-approved,
because nothing is known in advance, and everything is recorded before transmission.

Each side carries its own bound. Box-plane work can be free-form because the worst case is
ruining a machine already paid for. Cloud-plane work has no such bound, so an untyped call means
approving a key's full authority at an origin, and the interface has to say that rather than
imply a limit.

**Briefs are instructions, not scripts.** The AI reads prose plus example commands and decides
what to run. A script stops dead at the first surprise, and the AI exists precisely for the
surprises. Briefs ship inside the signed bundle, because a brief steers every member at once and
diversity buys nothing against it.

**One session, one machine, and the lock is real.** Each session is bound to exactly one machine
by an operator act before anything connects, and **each holds its own SSH keypair**, so only that
session's public key reaches that machine. A session cannot authenticate to a machine it is not
bound to, and the refusal comes from SSH rather than from the harness declining to call itself.
Access composes, not intent. Sessions run concurrently on the one device the operator owns, each
configured with a different model, with all machine creations approved together before any work
begins.

**The deliverable is a locked-down machine, demonstrated** by a lightweight self-directed pentest
— a **competence check, not an integrity check**. A model examining its own machine proves nothing
against a malicious model. What it catches is honest-but-sloppy, the likely failure on a
first-time setup.

**The coordinator is AI-free, and holds no channel to any machine at any point.** Deterministic
code from the signed bundle forms the federation by calling member APIs. It is the tenant's
machinery, not the harness's, and it runs only once every machine is sealed — at which point
there is no SSH left to hold. What it carries is peer-equivalent to what one member may do to
another, which the vault protocol already assumes may be done by a hostile party.
Federation creation is all-or-nothing, so abandonment has to be a first-class action — and an
unfinished, still-billing setup owns the app's opening screen.

**Members reach each other only on the vault protocol port**, mutually authenticated, everything
else denied at the vendor firewall — because reachability is a foothold on the same terms as a
credential, and a model able to attack four other machines produces *correlated* faults, the one
assumption a threshold cannot survive losing.

**The browser reaches a machine over SSH**, verifying the host key against a fingerprint obtained
by other means, through a relay that carries ciphertext. On dedicated hardware the vendor API
hands over the key; on the cloud path, where retrieval is dead, a designed and not yet booted
route — *attest*, the machine introducing its own key over Nostr under a per-machine key
planted at creation — closes the gap without trusting first contact. **Every per-machine key the
browser needs derives from a seed the operator holds**, so a lost phone re-derives them from
twelve words plus exported derivation indices; what the seed cannot re-derive — allocation
metadata, pins, the ledger, the inference balance — is what
the recovery sheet is for, and the vendor account is what says which machines exist.

**The system is written from inside a rescue environment**, for two reasons: rescue is what
publishes the host key, and the chosen distributions are not on the vendor's installer menu. That
makes the **artifact source** — wherever the bits come from — a party that decides what every
machine runs. The browser supplies the bootstrap hash and accepted package/cache signing keys
from the signed bundle. Both Alpine and NixOS still trust those package signers; a bootstrap
hash does not cover the entire installed system.

**A machine is not finished when it is delivered.** Each is periodically re-checked — inside by
its own session where the tenant allows re-entry, outside by a **scanner**: a specialist model of
the operator's choosing that probes public surfaces through the relay with no credential and no
access, whose findings are reports rather than gates. The advisory watch deliberately opens a
foothold, so fetched content is untrusted, review reports rather than acts, and the feed list
ships signed.

## The security claim, stated exactly

The harness and its tenants claim **different** things, and blurring them is how a single machine
ends up shipping under a vault's guarantee.

**The harness claims** that no session reaches a machine it is not bound to *through anything the
harness controls*, and that a model's blast radius is the machines its weights have touched, plus
any approved untyped scope, plus any tenant secret placed on those machines — all three stated
together, because no one of them alone is the boundary. What it *removes* is the party that would
otherwise pick the operator's vendor, model and configuration while holding their credentials.

**It does not claim the model is honest, and cannot.** With one machine there is no threshold, so
nothing absorbs a malicious model — a compromised one owns the machine it just configured. Ad hoc
use ships under that smaller claim rather than borrowing a larger one.

**Bitcoin custody stacks its own on top:** *no single model provisioned enough members to reach
the threshold.* That needs a vault, and it is conditional on the trust domains being genuinely
distinct — if several endpoints serve the same weights, the operator has one model rather than
five and it is vacuous.

There is no verification layer and nothing may imply one. Any scheme where a second model inspects
a finished machine from inside hands that model a second foothold. "Verified" and "no anomalies
found" are claims this design cannot make.

Independence is counted at **three configured layers — weights, proxy, and the provider the
harness requests per member — never blended into one score**. Members on several sets of weights
behind one proxy survive a backdoored model and do not survive a backdoored proxy. One number
would be a lie about whichever layer is thin, and the thin layer is the one that gets exploited.

The provider layer is labelled **requested**, and that word is doing real work: the chosen
aggregator does not report which provider served a request and documents that it may override
the one asked for. What is shown is what was sent, not what happened, and the display says so
rather than deriving a number from the model name and calling it observed.

## What must still be trusted

There is no zero. Everything runs on silicon, an operating system, a browser, a model, a vendor.
So the list is not short, and the useful question is not how many parties but **who chose them**.

**Unavoidable**, true of any software at all: the operator's device, and the stack underneath the
machines.

**Elective** — real trust, chosen and changeable. The cloud vendor, which owns its machine's
memory and disk. The inference proxy, of which the default path has exactly one. The provider
behind it. A majority of the models, honest *and* competent. The scanner's model. Any service an
approved untyped call hands a credential to. Whoever signs the software the machines run. And the
artifact source, which decides what every machine boots. **This is precisely the set a hosted
service picks for you, silently and unlisted.**

**Added by this product** — the only tier the design controls, and the only one an invariant
guards. The app bundle and its publisher, which is not diversified and carries the briefs, making
it the largest concentrated risk. The relay, publisher-operated by default, which cannot read a
session pinned out of band but does learn the member topology — a bootstrap seat, direct-first,
until a relay on a machine of the operator's own takes over ordinary traffic. An external
relay still manages and scans that relay-host machine. That is the whole tier — the
coordinator was once listed here and is not a party this product adds (`TRU-A3`).

What the product removes is the party that would otherwise choose every entry in the middle tier
and hold the credentials too: the service operator. That is the whole claim, and it is smaller
than "trustless" — but it survives the regress.

## What is not settled

The maintained list is [`08-open-questions.md`](./08-open-questions.md), and each entry says what
would close it. The ones that gate the work are the SSH client compiled to WebAssembly; the
the recovery machinery, designed but unproven until it runs once;
whether weights-level diversity is enforceable at all, which the security claim is conditional
on; the cloud-account floor that makes rental structural; and what the dedicated vendor's rescue
endpoint actually returns — one authenticated call that the first stage's whole identity chain
rests on.

## Status

Nothing here has touched a real server. The proof of concept can talk to a vendor API from a
browser; it cannot yet create a machine.

The first stage is **one rental box on a dedicated server, over the full channel** — the hardest
machinery on purpose. Construction gates on running that stage **by hand, once**, against a
disposable server: it settles in an afternoon what the corpus otherwise discovers over weeks, and
it produces the first briefs the product needs as a by-product.

The vault, with its concurrent sessions, trust panel and federation, is the second stage and
reuses the channel the first one proves.
