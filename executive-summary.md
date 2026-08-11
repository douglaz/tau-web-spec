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
domain language, fifteen decisions recording what was chosen and — for most of them — which
alternatives were rejected, a design record with three rounds of adversarial review, and an
archived specification of the execution layer. A working proof of concept in a separate
repository has established the one external fact everything depends on: a browser can call a
cloud vendor's API directly.

## The problem

Agentic AI is desktop-gated. Technical users run real harnesses against the best models
and get an AI that *acts*; everyone else gets a chat box. The people who would gain most
have only a phone.

The obvious fix is a hosted agent platform, and for one class of task it is unavailable in
principle. Anything whose value depends on *not* trusting a host — self-custody, key
management, sovereign infrastructure — cannot be delegated to a host. A single party that
provisions every member of a Bitcoin custody federation has defeated the federation,
whatever its intentions.

Two intended tenants: **btc-policy**, self-hosted Bitcoin custody built on a federation of
policy co-signers, and **lnrent**, server rental paid over Bitcoin. The second turns out to
be load-bearing for the first, because a federation across five vendors means five billing
relationships, and renting for sats with no account is the only escape from that.

## Who it is for

Sharper than "non-technical users." The default threshold is 3-of-5, so five machines, so
**€275 per year** at the reference price before inference. At a willingness to pay roughly
1% per year for custody, that implies holdings near €27,500. Nothing here makes sense for
someone holding €1,000: the floor is three machines and three machines cost what they cost.

The target is **a non-technical person with meaningful Bitcoin** — real reason to leave a
custodian, and a fee that is negligible against the amount at stake.

## How it works

**The AI runs only in the browser.** A machine is a target, never an actor: it holds no
inference key, no vendor token, and never initiates work. The consequence is accepted
rather than worked around — nothing runs while the app is closed, so every step must be
resumable across a locked phone.

**Actions split into two planes.** Cloud-plane actions — create, destroy, resize, firewall,
pay — are typed operations approved on structured facts rather than on command text.
Box-plane actions are free-form shell on a machine the operator already owns: nothing is
pre-approved, because nothing is known in advance, but the class of activity runs under an
approved scope and everything is recorded. Spending money is an enumerable API; configuring
a machine is not, and that is exactly where unanticipated problems live. The box plane has
no path to the cloud plane.

**Recipes are instructions, not scripts.** The AI reads prose plus example commands and
decides what to run. A script stops dead at the first surprise, and the AI exists precisely
for the surprises. Recipes ship inside the signed bundle, because a recipe is prose that
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

**A vault is not finished when it is created.** Each member is periodically re-checked by
its own session, including a review of advisories for the software it runs. That
deliberately opens a foothold — an advisory reading "critical: upgrade immediately" is a
supply-chain attack delivered through the audit — so fetched content is untrusted, review
reports rather than acts, and the feed list ships signed.

## The security claim, stated exactly

**No single model provisioned enough members to reach the threshold.**

That is the whole claim, and it is conditional on the trust domains being genuinely
distinct. If several endpoints serve the same weights, the operator has one model rather
than five and the claim is vacuous — and at the weights layer that distinctness may not be
enforceable at all, which makes this a design goal rather than a demonstrated property
until it is.

There is no verification layer and nothing may imply one. Any scheme where a second model
inspects a finished machine hands that model a second foothold. "Verified" and "no
anomalies found" are claims this design cannot make.

Independence is counted at **two layers and never blended into one score** — how many
distinct sets of weights, and how many distinct proxies route the requests. Five members on
five sets of weights behind one proxy survive a backdoored model and do not survive a
backdoored proxy. One number would be a lie about whichever layer is thin, and the thin
layer is the one that gets exploited.

## What must still be trusted

- **The app bundle** — the largest component not diversified, and it carries the recipes.
  Reproducible builds would make compromise detectable, not preventable, and neither they
  nor the watchdogs that would give them meaning exist yet. The largest concentrated risk.
- **The cloud vendor**, under every design considered. It owns the machine's memory and
  disk. Pinning buys transport safety, not vendor independence.
- **The inference proxy**, and on the default path there is only one of it — the thinnest
  layer in the default product even when the weights count looks healthy.
- **The inference provider behind that proxy**, which actually runs the weights and can
  rewrite everything routed to it. Neither displayed count covers it.
- **Whoever signs the vault software**, since every member installs the same release —
  common-mode in the same shape as the bundle.
- **The operator's device**, which holds the credentials and carries all five sessions.
- **The publisher**, on the default path, because it selects the models.
- **A majority of the models**, being both honest *and* competent.

The **coordinator** and the **relay** are trusted narrowly rather than fully, and both are
named so the list cannot grow quietly.

## What is not settled

The specification carries twenty open questions in one maintained list. Six gate the
work: the SSH client compiled to WebAssembly, which is the single item most likely to fail;
who *operates* the relay, since what it must do is already settled; how the browser
authenticates *itself* to a
machine, which host-key pinning does nothing for, and what happens to browser-held key
material when a phone is replaced; whether weights-level diversity is enforceable at all,
which the security claim is conditional on; the cloud-account floor that makes lnrent
structural; and what the product should do about a stalled setup that keeps billing.

Two of the twenty are decisions worth re-opening rather than gaps. The recovery ladder was
written before trust domains were counted per layer, and escalating a stuck machine to a
stronger model puts new weights on it — safe only if those weights are not running another
member, which no decision record says. And the option of letting
each machine serve its own bridge, removing the relay entirely, was rejected because it
needed a domain name the target operator does not have — and certificates for bare IP
addresses have since made that premise false.

## Status

Nothing here has touched a real server. The proof of concept can talk to a vendor API from
a browser; it cannot yet create a machine.

The cheapest way to find out which of these decisions is wrong is not to write code. It is
to **write three recipes by hand — create a machine, harden it, install one vault member —
and run them against a disposable project.**
