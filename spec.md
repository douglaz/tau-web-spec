# tau-web

tau-web is a client-side AI harness: an application that runs entirely in a phone
browser and provisions real infrastructure on its operator's behalf. Nothing provisions
a machine except the operator's own device — there is no server-side agent and no hosted
orchestrator. It exists so that a non-technical person can stand up and operate machines
whose value depends on not handing any one party the ability to act on all of them.

That is the goal, not an achieved property. Several parties remain trusted, and
[What must still be trusted](#what-must-still-be-trusted) names every one of them by
hand rather than claiming the list is empty.

There is no code in this repository. `tau-web` is a working name.

## How to read this

This document is the entry point. It states what the system is, what it does, what it
may never do, and what is still unknown. Four other places carry material this document
refers to rather than repeats:

| Where | What it holds |
|---|---|
| [`CONTEXT.md`](./CONTEXT.md) | The domain glossary — the canonical term for each concept, the aliases to avoid, and the ambiguities that must always be qualified. |
| [`docs/adr/`](./docs/adr/) | The fifteen decisions, and for most of them the alternatives that were rejected and the grounds for rejecting them — some in a `Considered options` section, some inline, and a few not at all. This document states *what* was decided; an ADR is where *why* lives. |
| [`docs/design/`](./docs/design/) | A record of the design session held on 2026-08-07, kept as history. It is the only account of why this approach was chosen over the two others weighed against it. |
| [`docs/archive/`](./docs/archive/) | The original Rust/WASM PWA specification — the execution layer, in far more detail than anything here. Superseded as a plan, retained because it is the only treatment of the machinery and because the decisions cite its section numbers. |

[`executive-summary.md`](./executive-summary.md) is a shorter read of this document for
someone who wants the shape without the detail.

One document referred to here lives outside this repository: **`ai-vps-harness`**, the
proof of concept, which established that a browser can call a cloud vendor's API directly.
Its own `§` numbers are cited a few times below and in the decision records; they are not
this document's and not the archived specification's.

The two specifications sit at different levels and were written in the opposite order to
how they should be read. The archived one is the execution layer: a Rust-first PWA
compiled to WebAssembly, a harness kernel derived from Tau's event and protocol concepts,
an end-to-end asynchronous Bash interpreter over `brush-parser`, WASI Preview 1 uutils
guests for real Unix commands, capability-scoped tools, and a dedicated worker owning all
mutable state. It carries 15 architectural decisions of its own, 10 numbered invariants,
14 MVP acceptance criteria, a 29-crate workspace, and milestones M0 through M6 — none of
which are the decisions or invariants recorded here. This document is the
product and security architecture, and it is newer. **Where the two disagree, this one
wins.**

## The problem

Agentic AI is desktop-gated. Technical users run real harnesses against the best models
and get an AI that *acts*; everyone else gets a chat box, because installing and
configuring a harness takes technical knowledge and usually a desktop. The people who
would gain the most have only a phone.

The obvious fix is a hosted agent platform, and for one class of task it is unavailable
in principle. Anything whose value depends on *not* trusting a host — self-custody, key
management, sovereign infrastructure — cannot be delegated to a host. A single party
that provisions every member of a Bitcoin custody federation has defeated the
federation, whatever its intentions. For those tasks the gap can only be closed in the
browser.

Two intended tenants:

- **[btc-policy](https://github.com/douglaz/btc-policy)** — self-hosted Bitcoin custody:
  multisig plus Miniscript descriptors, a federation of policy co-signers that inspect
  exact PSBTs, delayed sovereign recovery. Standing the federation up means provisioning
  and hardening several machines at several vendors.
- **[lnrent](https://github.com/douglaz/lnrent)** — server rental over Bitcoin. Operators
  run a daemon, publish over Nostr, buyers pay Lightning or Fedimint. An operator who
  cannot stand up the daemon cannot participate, and the project keeps AI out of its
  serving path by design, so any AI help has to live on the user's side.

The second turns out to be load-bearing for the first rather than merely a second
tenant, for the reason given under [Money](#money).

## Who it is for

Sharper than "non-technical users." The threshold is 3-of-5 by default
([ADR-0008](./docs/adr/0008-three-of-five-default-and-its-economic-floor.md)), which
means five machines, which at the `cx22` reference price of €4.59/month is **€275 per
year** before inference. A 2-of-3 federation is €165. At a willingness to pay roughly 1%
per year for custody, those imply holdings near €27,500 and €16,500 respectively. There
is no configuration that makes sense for someone holding €1,000: the floor is three
machines and three machines cost what they cost.

The target is therefore **a non-technical person with meaningful Bitcoin** — someone with
real reason to leave a custodian, for whom the fee is negligible against the amount at
stake. Stating this is better than letting someone discover it after budgeting for a
hobby.

## Constraints

Six constraints bound every decision here. The fourth is not satisfied today, and the
sixth is counted and displayed rather than enforced.

1. **The mobile browser is the runtime.** No install, no extension, no native package,
   no desktop, no terminal. A normal HTTPS URL on Android Chrome and iOS Safari.
2. **The AI must be free to act.** Future adversity on a machine is not enumerable in
   advance. Restricting the AI's authority to keep it safe breaks the only reason it is
   there.
3. **Credentials stay in browser memory.** No credential is written to storage, sent to
   the application's own origin, included in a model request, or persisted in a log.
4. **No party the operator must trust with the ability to act.** A transport that can
   only stall or drop is acceptable; one that can read or inject is not. **This is
   unsatisfied today**, which is why the first stage has no remote channel at all.
   Host-key verification is the intended mechanism — chosen, not proven — but passing the
   SSH spike is *not* sufficient to satisfy this constraint. It is satisfied only on a
   route that pins the fingerprint **out of band**, and today none of those is available
   on the cloud path: route 1 is dedicated-servers-only and a separate integration, route
   2 is unverified, route 3 is blocked behind open question 15. That leaves route 4, the
   trust-on-first-use floor, under which a hostile relay can have its own key pinned at
   first contact and read the session from then on
   ([ADR-0015](./docs/adr/0015-the-browser-reaches-a-machine-over-pinned-ssh.md)). The
   spike is necessary and the routes are what make it sufficient.
5. **Members must not share a cloud vendor.** The vendor owns its machine's memory and
   disk and is trusted under every design considered, so two members at one vendor is one
   party able to act on both — the correlated fault a threshold cannot absorb
   ([ADR-0006](./docs/adr/0006-single-origin-with-reproducible-builds.md) diversifies
   cloud vendors per member for exactly this reason). Nothing in the design forces vendor
   sharing, so unlike the proxy layer below this one stays a requirement. What makes it
   hard is the account floor under [Money](#money) — a reason it is expensive, not a
   reason it is optional.
6. **Independence between members is counted per layer and shown, not enforced.**
   Weights and proxy are counted separately, and a collision at either layer is
   displayed rather than blocked
   ([ADR-0007](./docs/adr/0007-trust-is-counted-in-two-layers-and-shown.md)). Blocking
   would make the default configuration impossible, because procured inference routes
   every member through one proxy by design — so at the proxy layer the default product
   *does* share a domain, deliberately and visibly. Independence is the security
   parameter; it is not a precondition this product can enforce.

## Architecture

### The AI runs only in the browser

The AI lives in the operator's browser. A provisioned machine is a target, never an
actor: it never holds an inference key or a vendor API token and never initiates work
([ADR-0003](./docs/adr/0003-the-ai-runs-only-in-the-browser.md)). An inference key on a
machine is a credential living outside browser memory and a machine that can call a model
unprompted is a machine that can act unprompted — which is the thing this project exists
to avoid.

The consequence is accepted rather than worked around: **nothing runs while the app is
closed.** Every step must be resumable across a locked phone, and progress must survive
the harness worker being killed.

### Two planes

Actions split into two planes with different rules
([ADR-0002](./docs/adr/0002-cloud-plane-and-box-plane.md)).

**Cloud plane** covers anything that spends money or changes infrastructure at a vendor:
create, destroy, resize, firewall, register key. These are typed operations carrying
structured metadata, and each is approved on its own facts rather than on command text.

**Box plane** covers shell execution on a machine the operator already owns. It is
free-form, never pre-approved, always recorded.

The split exists because the two have genuinely different shapes. Spending money is an
enumerable API; configuring a machine is not, and that is exactly where unanticipated
problems live. The blast radii differ by orders of magnitude — box-plane code can ruin
one machine the operator already bought, cloud-plane code can spend a credit card.

**Approval means two different things and the interface must not blur them.** Approving
an *operation* means seeing structured facts about one cloud-plane action and permitting
it. Approving a *scope* means permitting a class of activity in advance, which is what
box-plane work runs under, because its contents are not known beforehand.

### Recipes

A recipe is a document of prose plus example commands, in the shape of an agent skill.
The AI reads it and decides what to actually run; it is not executed verbatim
([ADR-0001](./docs/adr/0001-recipes-are-instructions-not-scripts.md)). A script stops
dead at the first surprise — a changed image name, a package that will not install, a
service that will not start — and the AI exists precisely for the surprises. A setup
nobody can finish sends the operator back to a custodian, which is worse than the risks
this design accepts.

The cost is paid honestly: what runs is not known before it runs, which is what forces
approval to draw on structured facts from the cloud plane rather than on command text.
Adaptations also do not accumulate — the same problem may be solved differently on two
runs, and the library does not improve on its own.

**Recipes ship inside the signed application bundle**
([ADR-0005](./docs/adr/0005-recipes-ship-in-the-signed-bundle.md)). Nothing fetches a
recipe at runtime and operators cannot supply their own. A recipe is prose that steers a
model, which is prompt injection by design, and every member reads the same recipe — so
whoever can change one reaches every member at once. That defeats the honest-majority
assumption rather than being absorbed by it: n honest, competent models faithfully
following poisoned instructions all produce the wrong machine, and agree with each other
perfectly while doing it. The recipe is the one component where diversity buys nothing,
so it is locked instead.

The recipe *format* is a candidate shared primitive with lnrent. The *library* is not
shared: each project ships its own set inside its own bundle.

### Sessions, trust domains, and diversity

A **session** is one run of the harness under one set of model weights, responsible for
exactly one machine. A federation is provisioned by several concurrent sessions on a
single device ([ADR-0009](./docs/adr/0009-one-device-concurrent-sessions-batched-approval.md)).

**One session, one machine.** Each session accesses exactly one machine and never reads,
audits, or touches a machine it did not provision
([ADR-0004](./docs/adr/0004-one-model-one-machine.md)). Access is what composes, not
intent: letting one model touch two machines halves the number of malicious models
needed to reach a k-of-n threshold. Any verification scheme in which one model inspects
another's work therefore weakens the exact property it appears to strengthen.

This rule about access is absolute. The separate question of *how many distinct trust
domains are in play* is not a rule at all but a count, and it comes out differently at
each layer.

**A trust domain is counted at two layers, never as one blended number**
([ADR-0007](./docs/adr/0007-trust-is-counted-in-two-layers-and-shown.md)):

- **Weights** — the model itself. Two members on different weights survive one set of
  weights being backdoored, even through a shared proxy.
- **Proxy** — the aggregator routing the request. A compromised proxy can alter every
  prompt and response it carries, whatever weights sit behind it.

A 3-of-5 federation on five sets of weights behind one proxy is 3-of-5 against
backdoored weights and 1-of-1 against a backdoored proxy. Both numbers are true; one
number would be a lie about whichever layer is thin, and the thin layer is the one that
gets exploited.
A **collision** — two machines sharing a domain at either layer — is therefore *shown,
not blocked*, because procured inference shares a proxy by design and blocking would
make the default configuration impossible.

**Why one device.** The separation that matters is between models, not between pieces of
hardware. The device is already a trusted party, so putting five sessions on it adds no
party that was not already trusted. Requiring five devices would defend against a
compromised phone while guaranteeing that an operator who owns one phone never finishes
setup.

**Why concurrent.** Nothing runs while the app is closed, so sequential provisioning
would multiply the time the operator must hold a phone awake by the member count. A
twenty-minute install becomes a hundred-minute one. Concurrency costs nothing in
security, since the invariant is one domain per machine and simultaneity does not change
which domain touches which machine. It is bounded by mobile memory and proxy rate limits,
which are reasons to cap concurrency rather than to serialize it.

**Why approvals batch.** Every machine creation is known before anything starts, so all
of them fit in one screen showing the whole federation and its true recurring cost.
Everything unpredictable is box-plane, which needs no approval by construction.
Mid-flight cloud-plane actions are rare by definition, so a queue for them is cheap and
never competes with itself for attention. Five concurrent workers producing interleaved
popups on a phone is modal fatigue in its purest form, and the operator cannot tell which
member is asking.

**Recovery is a ladder.** Retry; then escalate to a stronger model behind the same proxy;
then destroy the machine and restart under a different domain, which costs a server. A
stuck machine is never handed to a session that did not provision it — past the middle
rung it is destroyed instead.

The middle rung is cheap because the proxy already had access, so escalating behind it
grants that party nothing new. But the stronger model is *new weights on that machine*,
and that is harmless only while those weights are not also running another member —
otherwise one model has a foothold on two machines, the composition the threshold cannot
survive. [ADR-0004](./docs/adr/0004-one-model-one-machine.md) predates the per-layer
counting that makes this visible and still calls the rung unconditionally free; question
20 records that it needs amending. Partial failure is the normal case and must be a
coherent state the operator can act on, not an error.

### What a session delivers

A session's deliverable is a machine that is provisioned, hardened, running the vault
software, reachable, and **shown to be locked down** by a lightweight self-directed
pentest — open ports, default credentials, sshd posture, exposed services
([ADR-0011](./docs/adr/0011-the-ai-delivers-a-locked-down-machine.md)). Hardening is a
property the session demonstrates, not a step it reports having performed.

**The pentest is a competence check, not an integrity check.** A model examining its own
machine proves nothing against a malicious model, and does not need to, because malice is
what the threshold absorbs. What it raises confidence in is the *competent* half of the
honest-majority assumption. Honest-but-sloppy is the likely failure on a first-time
setup, and it is the one this catches. It never runs from another member.

The job is deliberately not uniform across vendors, because the vendors are not uniform.
Hetzner Cloud has no image upload API at all and requires a rescue-and-write approach,
while others offer import paths that differ from each other and from that. A prebuilt
image is an optimisation available at some vendors, not a contract available at all of
them. That heterogeneity is an argument *for* the AI, not against it.

### The coordinator and federation creation

The **coordinator** is AI-free deterministic code running from the signed bundle on the
operator's device. It takes member endpoints plus operator-supplied recovery descriptors
and forms the federation by calling member APIs. It is the only party that contacts every
member, which is permitted precisely because it is not a model.

**Federation creation is all-or-nothing**
([ADR-0012](./docs/adr/0012-a-federation-is-created-only-when-every-member-works.md)). A
partially-formed federation has no honest description: a 3-of-5 vault with four working
members is not "80% set up" — its real threshold, failure modes, and security claim are
all different from the thing the operator approved, and none of those differences are
visible from a progress bar. "Four up, one stuck" is not a state, it is an unfinished
setup.

Because approvals batch up front, all five machines exist and bill from the moment they
are created, while one member is retried or replaced. **Abandonment must therefore be a
first-class action** — a cloud-plane operation with the same approval treatment as
creation — or an operator who gives up pays indefinitely for a vault that never existed.

### Member networking

Members open connections to each other only on the vault protocol port, mutually
authenticated. No SSH between members, no arbitrary traffic, everything else denied at
the vendor firewall
([ADR-0010](./docs/adr/0010-members-reach-each-other-on-one-authenticated-port.md)).

**Network reachability is a foothold on the same terms as a credential.** If the five
machines can reach each other, a model controlling machine 1 can attack machines 2
through 5 directly, and the one-domain-one-machine invariant is broken by the network
rather than by any grant. This matters more than it first appears: a k-of-n threshold
assumes faults are **independent**, and one model able to attack four other machines
produces *correlated* faults — the one assumption a Byzantine threshold cannot survive
losing.

The vault protocol must therefore be safe against actively hostile peers, not merely
faulty ones. This is confirmed to be btc-policy's own premise rather than a new
requirement: a policy co-signer inspects exact PSBTs precisely because it does not trust
its peers.

Because firewall rules are cloud-plane, the deny-by-default posture is visible to the
operator, and a recipe cannot quietly widen it.

### The browser-to-machine channel

The browser reaches a machine over SSH, verifying the host key against a fingerprint
obtained by other means, through a WebSocket-to-TCP relay
([ADR-0015](./docs/adr/0015-the-browser-reaches-a-machine-over-pinned-ssh.md)). A browser
cannot open a TCP socket to port 22 at all, so a bridge is forced regardless of who runs
it. The check that matters happens inside the SSH protocol at the application layer, so
once the right key is pinned the transport underneath is irrelevant to confidentiality
and integrity.

Four routes to the fingerprint exist, from vendor API retrieval down to trust-on-first-use
with continuity as the floor. That floor is *not* currently a working fallback: a pin lives
in browser storage, and question 3 records what happens when that storage is cleared or the
phone is replaced. **Under the routes that pin out of band a
hostile relay is a denial of service and nothing worse. Under trust-on-first-use it is
not**: at first contact there is nothing to check the key against, so a hostile relay can
present its own, have it pinned, and read the session from then on. Every retrieval and
injection route exists to avoid exactly that, which is why the floor is a floor.

A relay that authenticates callers and constrains destinations **holds real authority over
who may connect where, while holding none over what is said.** Both are true and the
second does not cancel the first. It must not be a generic open proxy; the archived
specification's §21 requirements are the resolution.

The mechanism is chosen, not proven. It needs an SSH client compiled to
`wasm32-unknown-unknown` with its transport swapped for a WebSocket, which is the single
item most likely to fail.

### Ongoing operation

A vault is not finished when it is created. Each member is periodically re-checked by
**its own** session: the pentest is re-run, and upstream releases and security advisories
for the software that member runs are reviewed
([ADR-0013](./docs/adr/0013-ongoing-operation-periodic-pentest-and-advisory-watch.md)).
This is the work an AI is unusually well suited to and a non-technical operator will never
do, and not doing it is how a correctly-built vault becomes a vulnerable one over a year.

It requires the operator to open the app, since nothing runs while it is closed, so the
product needs a way to make a lapsed check loudly visible without being able to do
anything about it unattended. Each re-check costs inference on top of the machines.

**This opens a foothold deliberately, and it is the newest surface in the design.**
Advisory feeds and release notes are external content that steers the model. An advisory
reading "critical: upgrade immediately to package X from repository Y" is a supply-chain
attack delivered through the feature meant to make the vault safer. Three rules follow:
fetched content is typed as untrusted and can never authorize an action by itself;
advisory review **reports, it does not act**, so any resulting change is a normal
operation needing normal approval however urgent the advisory claims to be; and the set
of feeds ships signed like the recipes, since a feed URL changeable at runtime steers
every member at once.

The first of those three is a general rule, not a rule about advisories. Any box-plane
command already returns attacker-influenceable text — package-manager output, a
downloaded file, a service log — and the archived specification types *all* tool output
as untrusted (§20.5) for that reason. What is genuinely new here is that fetching remote
text becomes a deliberate capability rather than a side effect, which is what makes the
feed list worth signing.

### Money

Two kinds of cost, handled differently, and they must not be merged
([ADR-0014](./docs/adr/0014-the-app-relays-invoices-and-never-holds-funds.md)).

**Recurring costs** — the machines — are billed by the cloud vendor to the operator's own
account on their own payment method. The app never mediates this and cannot stop it; only
the operator can. The app holds a vendor API token that spends against an account the
operator already controls.

**One-off costs** — inference credits — are assisted. The app retrieves an invoice from
the provider and hands it to the operator's wallet to pay. It relays an invoice; it never
holds, forwards, or custodies funds. A payment intermediary would be the one place in the
design where the operator is asked to trust *more* rather than less.

Payment evidence is weaker than it looks and the trust panel must not overstate it. A
**settled invoice** proves the operator funded credits at a provider and bounds which
proxies are available; it does not prove which member used which proxy, because one top-up
buys many queries. Per-member routing evidence is separate and comes from response
metadata.

**Inference has two paths.** *Procured* is the default: the operator pays one fee and the
publisher selects the models. It adds no new trusted party, because the publisher is
already trusted for the bundle — but it does mean the publisher chooses the weights, and on
the default path it reaches them all through one aggregator, so every member is routed
through a single proxy. *Bring-your-own* is
the advanced path: the operator supplies provider tokens or runs inference locally,
removing the publisher from model selection and, locally, the proxy layer entirely.

**This is where lnrent becomes structural.** Paying for inference is *nearly* solved — an
aggregator that takes Lightning with no registration would make funding several providers a
few invoices, subject to the browser reachability that question 9 records as still unprobed.
Cloud vendors are not: they want an account, a card, and a recurring billing
relationship, and a 3-of-5 federation across distinct vendors means several of those.
Invoice relay cannot fix it, because vendors do not sell that way. Without something like
lnrent, the multi-vendor requirement collides with the operator's willingness to open
billing relationships, and vendor diversity quietly collapses to whatever account they
already had.

### Distribution

The application is served from a **single origin**, as a static HTTPS host serving
HTML/JS/WASM/CSS/manifest/service-worker. No app store, no package manager, no install
step — that is the product. Builds are reproducible and their hashes published, so a third
party can verify that the served bundle matches the published source
([ADR-0006](./docs/adr/0006-single-origin-with-reproducible-builds.md)).

Origin diversity — a different mirror per member — was considered and **rejected on user
safety, not security.** Instructing someone to open a second URL on a second device is
behaviourally identical to phishing, and the target operator is precisely the person least
equipped to tell the difference. Teaching Bitcoin users that the same app legitimately
lives at several addresses trains the reflex that gets them robbed.

So the bundle remains a common-mode component — the largest, and the one that carries the
recipes, though not the only one: see the vault-software signer below.
Reproducible builds make a compromised bundle detectable, not preventable, and the target
operator will not verify a hash on a phone. The mitigation that matters is **third-party
watchdogs** — independent parties routinely fetching and comparing the served bundle, so
an attacker cannot know who is checking. That requires reproducible builds to exist and
someone to run the checks, and neither is true today.

Continuous integration must run the CORS probe on every push, because browser
reachability is an external dependency that can regress silently: a vendor could tighten
its headers any day and the probe is the only thing that would say so.

## Invariants

These may never be violated. They are product-level and distinct from the ten numbered
invariants in the archived execution-layer specification.

1. **A session MUST NOT be given access to more than one machine, and MUST NOT read,
   audit, or touch a machine another session provisioned.** Access is what composes, not
   intent: a model with a foothold on two members halves the number of malicious domains
   needed to reach k-of-n ([ADR-0004](./docs/adr/0004-one-model-one-machine.md)). No
   exception for debugging, for auditing, or for any scheme in which one model inspects
   another's machine. **Exposure is permanent for the life of the machine**: a model that
   has touched a machine counts as touching it until that machine is destroyed, because
   ending a session does not remove whatever the model may already have left behind. So the
   recovery ladder's middle rung stays inside this rule only while the stronger model has
   not run — and will not later run — any other member; past that rung the machine is
   destroyed rather than handed on.

   **What this invariant reaches, and what it does not.** The product decides which machine
   a session may touch, so that part is enforceable and absolute. It does not decide
   whether two sessions configured with different models are served the *same weights* —
   nothing observable tells it (question 4). Identical weights behind two members is
   therefore a **collision, displayed under constraint 6** — not a violation of this
   invariant, and not something an implementation can be required to prevent. The security
   claim is conditional on that distinctness for exactly this reason, and saying so here is
   what keeps this list enforceable rather than aspirational.
2. **The product MUST NOT present any claim as verified.** There is no verification
   layer. "Verified" and "no anomalies found" are claims this design cannot make.
3. **The box plane MUST NOT have a path to the cloud plane.** A machine never holds a
   vendor API token. Work needing a cloud-plane action returns to the browser, even
   mid-way through box-plane work.
4. **Cloud-plane actions MUST be approved on structured facts, never on command text.**
5. **Credentials MUST NOT leave browser memory** — not to storage, not to the app's own
   origin, not into a model request, not into a log. The injection route for SSH host
   keys is a known conflict with this, and open question 15 is where it is tracked.
6. **The AI MUST NOT touch key material.** Recovery descriptors come from the operator.
   Member keys are generated on the machine and never exported.
7. **Recipes and advisory feed lists MUST ship in the signed bundle** and MUST NOT be
   fetched, configured, or substituted at runtime.
8. **All tool output and fetched external content MUST be typed as untrusted** and MUST
   NOT authorize an action on its own, declare capabilities, or override policy.
9. **Trust counts MUST be shown per layer and MUST NOT be blended into a single score.**
10. **The trusted-party list MUST NOT grow silently.** Any feature adding a party to it is
    a change of the same weight as a schema migration.
11. **Members MUST NOT be reachable from each other except on the vault protocol port,
    mutually authenticated**, with everything else denied at the vendor firewall.
12. **A federation MUST NOT be formed until every member is provisioned, hardened, and
    reachable.**
13. **An SSH session MUST check the host key against the stored fingerprint, and a key
    that does not match MUST halt the session.** Exactly one moment is exempt and it is
    the reason route 4 is a floor: under trust-on-first-use there is no stored
    fingerprint at first contact, so that contact is trusted rather than verified and
    MUST be presented to the operator as such. No other path may accept an unverified
    key.
14. **The app MUST NOT hold, forward, or custody funds.**
15. **Two machines of one federation MUST NOT be created at the same cloud vendor.**
    Stated in machines rather than members deliberately: nothing has joined a federation
    when this rule has to bind, so a rule about "members" would not reach the first stage
    at all. The vendor owns its machines' memory and disk, so two of them at one vendor is
    a single party able to act on both — the correlated fault invariant 11 exists to prevent at the network layer,
    arriving instead through the billing relationship. Unlike every other entry here this
    one has no decision record of its own: it rests on
    [ADR-0006](./docs/adr/0006-single-origin-with-reproducible-builds.md)'s statement that
    cloud vendors are diversified per member, which is background to a decision about
    *origin* diversity, plus the correlated-fault argument in
    [ADR-0010](./docs/adr/0010-members-reach-each-other-on-one-authenticated-port.md). It
    is the one rule in the first stage that blocks rather than displays, so it should have
    a record of its own.

## The security claim, stated exactly

**No single model provisioned enough members to reach the threshold.**

That is the whole claim, and it is conditional on the trust domains being genuinely
distinct. If several endpoints serve the same weights, the operator has one model rather
than five and the claim is vacuous — which is why the counting is shown to them, and why
the weights-diversity item in the open questions matters: at that layer distinctness may
not be enforceable at all, and until it is, this is a design goal rather than a
demonstrated property.

There is no verification layer and nothing in the product may imply one. Every scheme
where a second model inspects a finished machine hands that model a second foothold and
weakens the threshold doing the real work. A deterministic verifier reads whatever the
machine chooses to tell it and cannot beat a hostile AI; it survives only for drift
detection and honest mistakes inside a single member, run by that member's own session.

**Honest mistakes ship silently.** On a first-time setup a misconfiguration is the likely
failure, not a hostile model, and no mechanism here catches one made the same way by
everybody. The threshold protects funds; it does not protect against uniform sloppiness.

An **action transcript** is a browser-side record of what one session actually did,
captured before transmission. It is useful for the operator to read and for a member's own
drift detection. It is **not** evidence about a machine, because no second model may
inspect it against that machine. A **provenance record** — the claim that a machine was
provisioned by a specific vendor, inference provider, and model — is durable, and in the
first version a local claim rather than evidence.

## What must still be trusted

Named plainly, because the product's pitch is the opposite of asking for trust.

- **The app bundle.** The one component not diversified across members, and it carries the
  recipes. A compromised host can serve one build that misbehaves on every member, and can
  serve a good bundle to anyone who looks like a checker. This is the largest concentrated
  risk in the design.
- **The cloud vendor**, under every design considered. It owns the machine's memory and
  disk. Host-key pinning buys transport safety, not vendor independence; vendor
  independence is what multi-vendor membership buys.
- **The inference proxy — and on the default path there is only one of it.** Procured
  inference means the publisher picks the models, and it has one aggregator that reaches
  them all, so the normal configuration is five sets of weights behind a single proxy.
  (Adding a second is a supported move, not a redesign — that is the point of counting the
  layer separately.) That proxy can
  alter every prompt and response it carries, which makes it the thinnest layer in the
  default product even when the weights count looks healthy.
- **The inference provider behind the proxy.** The aggregator does not run the weights; it
  routes to whoever does, and that party — the one `X-Provider-Name` names, per
  [`CONTEXT.md`](./CONTEXT.md) — sees and can rewrite every prompt and response sent to it,
  exactly as the proxy can, for whichever share of members land there. Two machines served
  by the same one share a party that neither count displays, because the counted layers are
  weights and proxy and this is neither (question 4). It is named here because the list is
  meant to be exhaustive even where the counting is not yet settled.
- **The operator's device.** It holds the credentials, runs the bundle, and carries all
  five concurrent sessions, so it is common-mode across every member. A deliberate trade:
  requiring five devices would defend against a compromised phone while guaranteeing that
  an operator who owns one phone never finishes setup.
- **The publisher**, on the default path, because it selects the models. Acceptable only
  because it is already trusted for the bundle and because bring-your-own inference exists
  as the escape hatch. If that escape hatch is ever dropped, the arrangement stops being
  defensible.
- **A majority of the models**, being both honest *and* competent.

- **Whoever signs the vault software the members run.** Recipes install the same release on
  every member, so its signer is common-mode across the federation in the same shape as the
  bundle — which means
  [ADR-0005](./docs/adr/0005-recipes-ship-in-the-signed-bundle.md)'s claim that the bundle
  is "the only remaining single point of total compromise" is one party short — as is
  [ADR-0006](./docs/adr/0006-single-origin-with-reproducible-builds.md)'s "the bundle is
  the remaining single point of total compromise," which says the same thing in a record
  this document does not otherwise amend. Artifact pinning would bound this; nothing here
  specifies it yet.

This list covers the parties **this design asks the operator to trust that an ordinary
setup would not**. It deliberately stops short of the stack everything runs on — the
operating system, its package repositories, the certificate authorities, the hardware —
which are trusted here no more and no less than anywhere else, and which would make the
list unbounded without making it more honest.

Two parties are trusted narrowly rather than fully, and both are named so the list cannot
grow quietly. The **coordinator** is trusted during setup, as the only party contacting
every member, permitted because it is deterministic code rather than a model. The
**relay**, once it exists, cannot read or alter a session whose host key was pinned out of
band — but it learns connection metadata, and one that authenticates callers and
constrains destinations decides who may connect where. Under trust-on-first-use it is
trusted outright at first contact.

## What the first stage must demonstrate

The first stage provisions **two independent machines and joins them into no federation.**
It is not a vault and it is not a claim that anyone's bitcoin is safe. What it supports is
"these two machines have visibly different provenance" — and even that *displays*
provenance rather than proving it, since a provenance record is a local claim and forgery
resistance is out of scope at this stage.

Recipes are local-only here. Both machines are configured entirely through boot-time
user-data, which needs no relay, no WASM SSH client, and no answer to the channel
question. Acceptance is these predicates:

1. Two sessions, each configured with a **different model**, each create exactly one
   machine at a different cloud vendor. Stated in what a session is actually *configured
   with* — a proxy endpoint and a model — because the **inference provider** is whoever
   that proxy routes to and is known only from the response
   ([`CONTEXT.md`](./CONTEXT.md)). Whether two different models rest on different weights
   is not checkable at all (question 4), so a criterion written in weights would pass or
   fail on something nothing can measure.
2. For each machine the app persists a provenance record naming the cloud vendor, the
   inference provider, and the model identifier, surviving a page reload and a browser
   restart.
3. A trust-domain collision is **displayed** — at each layer separately, never blended —
   at the moment the operator can still act on it. A **shared cloud vendor blocks the
   create** and says why: ADR-0007 reversed blocking for the proxy layer specifically,
   because procured inference shares a proxy by design, and that reasoning does not reach
   vendors, which nothing forces anyone to share.
4. A local-only recipe with at least two blocks runs end to end, and the user-data
   submitted to the vendor API is byte-identical to what the approval screen displayed.
5. None of the four credentials — two vendor tokens, two inference keys — appears in a
   request to the app origin, in any model request body, in IndexedDB, in local storage,
   in service-worker caches, or in any log.
6. A create interrupted between intent and confirmation, then resumed, results in exactly
   one machine.
7. All of the above pass on Android Chrome and iOS Safari, through a normal HTTPS URL,
   with no install.

The second stage adds remote blocks over the channel **and everything that turns machines
into a federation** — the coordinator, federation formation, all-or-nothing creation. Both
halves wait on the same thing: the coordinator has to reach five member APIs on machines
with no valid certificate, so it needs the channel as much as recipes do. Neither can be
estimated until the SSH spike resolves.

## The decisions

Each is a consequence of the ones above it. Where a decision had a real alternative, the
record carries it and the grounds for rejecting it.

| ADR | Decision |
|---|---|
| [0001](./docs/adr/0001-recipes-are-instructions-not-scripts.md) | Recipes are instructions the AI reads, not scripts it executes |
| [0002](./docs/adr/0002-cloud-plane-and-box-plane.md) | Cloud-plane actions are typed operations; box-plane actions are free shell |
| [0003](./docs/adr/0003-the-ai-runs-only-in-the-browser.md) | The AI runs only in the browser; a machine is a target, never an actor |
| [0004](./docs/adr/0004-one-model-one-machine.md) | One model, one machine, and an honest-majority assumption |
| [0005](./docs/adr/0005-recipes-ship-in-the-signed-bundle.md) | Recipes ship in the signed app bundle |
| [0006](./docs/adr/0006-single-origin-with-reproducible-builds.md) | One origin, with reproducible builds |
| [0007](./docs/adr/0007-trust-is-counted-in-two-layers-and-shown.md) | Trust is counted in two layers, and shown rather than scored |
| [0008](./docs/adr/0008-three-of-five-default-and-its-economic-floor.md) | 3-of-5 by default, and the economic floor it implies |
| [0009](./docs/adr/0009-one-device-concurrent-sessions-batched-approval.md) | One device, concurrent sessions, approvals batched up front |
| [0010](./docs/adr/0010-members-reach-each-other-on-one-authenticated-port.md) | Members reach each other on one authenticated port, everything else denied |
| [0011](./docs/adr/0011-the-ai-delivers-a-locked-down-machine.md) | The AI delivers a locked-down machine and demonstrates it, per vendor |
| [0012](./docs/adr/0012-a-federation-is-created-only-when-every-member-works.md) | A federation is created only when every member works |
| [0013](./docs/adr/0013-ongoing-operation-periodic-pentest-and-advisory-watch.md) | Ongoing operation: periodic pentest and advisory watch |
| [0014](./docs/adr/0014-the-app-relays-invoices-and-never-holds-funds.md) | The app relays invoices and never holds funds |
| [0015](./docs/adr/0015-the-browser-reaches-a-machine-over-pinned-ssh.md) | The browser reaches a machine over SSH, pinned at the application layer |

## Open questions

This is the only list. Anything else that reads like an open question elsewhere in this
repository is history.

### Gating

1. **The SSH client spike.** An SSH implementation compiled to `wasm32-unknown-unknown`
   with its transport swapped for a WebSocket. `russh` is the realistic Rust candidate but
   is async and tokio-shaped. This is unproven work of the same character as the archived
   specification's M0 gates, and it is the item most likely to fail. Treat a failure as
   the thing that pushes remote blocks out of the second stage entirely.
2. **Who operates the relay, and how a browser gets a credential for it.** What the relay
   must *do* is settled — authenticate the user, enforce destination policy, prevent
   generic open-proxy behaviour, per the archived specification's §21 — so one open half is
   who runs a component that learns which operator connects where and when, and how an
   operator would know. The other is that "authenticate the user" implies a scoped
   short-lived token whose issuer, identity model, first issuance, and reacquisition after
   browser storage is lost are all unspecified; done carelessly that adds an identity party
   to the trusted list. Reinstating a relay at all reverses the proof of concept's own §4,
   which listed one as explicitly absent. It is also a candidate lnrent tenant.
3. **How the browser authenticates itself to a machine.** Host-key verification proves the
   *machine* to the browser and nothing in the other direction; sshd still wants a client
   credential. Where the browser gets a client private key, how the matching public key
   reaches the machine, and what happens to that key across sessions are all unspecified —
   and a client key held in browser memory only, per invariant 5, has no obvious recovery
   story. It is the first new credential class beyond the four the first stage counts —
   the route-3 host private key at question 15 would be the second — and it gates the
   second stage as surely as the spike does.

   **The same problem runs the other way, for host fingerprints.** A pin lives in browser
   storage, and browser storage is cleared, evicted, or left behind when the operator
   replaces a phone. The machine is still there and still has its key, but nothing local
   attests to it. Treating that as a first contact hands a hostile relay the pin that
   routes 1 to 3 exist to prevent; refusing to connect strands the operator from their own
   vault. Neither is acceptable, so durable export or an authenticated re-verification path
   has to exist before the channel is real.
4. **Weights-level diversity may not be enforceable, and the inference provider is counted
   nowhere.** The available runtime signal names the *inference provider*, not the weights
   behind it, so if that does not change, the honest position is to enforce provider
   diversity, say so plainly in the interface, and stop claiming more — the security claim
   is conditional on this. The second half is that the inference provider is a distinct party
   from both the aggregator and the weights, and a compromised one can rewrite every prompt
   and response routed to it, exactly as a proxy can, for whichever share of members land
   there. [ADR-0007](./docs/adr/0007-trust-is-counted-in-two-layers-and-shown.md) counts
   two layers and does not count this one. Whether it deserves a third layer, or folds into
   the proxy count, is undecided — and until it is, a healthy-looking pair of numbers may
   still hide a shared party.
5. **The cloud-account floor.** Cloud vendors want an account, a card, and a recurring
   relationship, several times over, and invoice relay cannot fix it. This is what makes
   lnrent structural rather than a second tenant, and it is what makes constraint 5 hard.
6. **A stalled setup bills.** Federation creation is all-or-nothing, approvals are batched
   up front, and nothing runs while the app is closed — so an interrupted setup is five
   machines billing with no progress. The product needs an opinion about when to prompt for
   resume or abandonment.

### One call, one probe, or one boot from closing

7. **What Hetzner Robot's rescue `host_key` field actually returns** — full public keys,
   fingerprints, which algorithms. Undocumented. One authenticated call answers it, and the
   same call should re-check that Robot is still reachable from a browser at all: that
   result rests on a single recorded probe, and vendor CORS headers are exactly the kind of
   external dependency the continuous probe elsewhere in this document exists to catch
   regressing.
8. **Whether Hetzner Cloud's rescue action returns host keys the way Robot's does.**
   Unverified, and it matters first, because the cloud product is where this starts.
9. **Whether the second inference proxy is reachable from a browser at all.** An
   OpenAI-compatible API does not imply an origin may call it. This needs the same probe
   the first proxy got before the trust panel can offer it as a one-tap action.
10. **Whether a second cloud vendor's API permits a browser origin.** Roughly eighty lines
    of curl — the existing probe is a template, not a drop-in, since it hardcodes the first
    vendor's base URLs, paths, and assertions. Constraint 5 depends on the answer.
    Candidates include Vultr, DigitalOcean, Linode, and lnrent itself, which is interesting
    because it needs no cloud account at all.
11. **Whether the proof of concept's cloud-init boots an unreachable machine.** A code-read
    finding, not an observed failure: its user list has no default entry and sets an empty
    authorized-keys list, so the vendor's injected keys reach no account. The fix is one
    line and nobody has booted the file. Do this before anything depends on being able to
    log in.

### Design-level, still unanswered

12. **The recipe format schema.** Frontmatter fields, the local/remote block marker, how a
    block returns structured data to the next one, versioning, signing. Designing a second
    consumer for an undefined format is premature until this exists.
13. **What executes recipe commands locally in the browser.** Either a WASI host with
    uutils guests, as the archived specification assumes, or a small set of purpose-built
    commands. This is deliberately not decided in advance: the scope is to be derived from
    real recipes rather than guessed, and the archived specification's answers here are
    currently guesses.
14. **Mid-recipe recovery at step granularity.** Duplicate-create protection is designed
    but the provisioning state machine it needs is not built, and a multi-step recipe needs
    the same idea per step on top of it.
15. **Whether injecting the SSH host key is permitted, and on what terms.** Route 3 writes
    a *private* host key into boot-time user-data, which the vendor stores — squarely
    against invariant 5. [ADR-0015](./docs/adr/0015-the-browser-reaches-a-machine-over-pinned-ssh.md)
    says the contradiction may not be left standing, and there is only one way out: carve a
    **narrow exception for the injected server host key specifically**, before the route is
    used. Not a rewrite of invariant 5 down to "vendor and inference credentials" — that
    phrasing would quietly strip the SSH *client* private key (question 3) and the relay
    token (question 2) of the same protection, which is a larger hole than the one being
    patched. Scrubbing and rotating the key after first boot limits exposure but resolves
    nothing; the key has already been exported. That decision has not been taken, and route
    3 cannot be used until it is.
16. **What "locked down" means, per vendor — and who may run the check.** A pentest can
    only assert what it checks, so the checklist is part of the signed recipe set
    ([ADR-0011](./docs/adr/0011-the-ai-delivers-a-locked-down-machine.md)) — and it does
    not exist yet for any vendor. Until it does, the deliverable in
    [What a session delivers](#what-a-session-delivers) has no definition to be measured
    against.

    The second half is a live divergence between current records. This document and
    `CONTEXT.md` describe the pentest as **self-directed** — the machine's own session,
    never another member. ADR-0011 and
    [ADR-0010](./docs/adr/0010-members-reach-each-other-on-one-authenticated-port.md) also
    permit it to run "from the trusted coordinator." Those are different objects: a
    coordinator-run scan is deterministic code reading a machine, which `CONTEXT.md` calls
    a **verifier** and which is explicitly not a defence against a hostile model — so it
    cannot substitute for the competence check, whatever else it is worth. Nothing yet says
    which the deliverable requires.
17. **Reproducible builds and the watchdogs that would make them mean something.** Neither
    exists. Until they do, the bundle's integrity rests on trusting the host outright.
18. **Content-Security-Policy gaps.** There is no WebSocket entry today; when one is added
    it must name the relay's exact `wss://` origin rather than the bare `wss:` scheme,
    which would permit a WebSocket to every secure origin there is. Runtime admission of
    the policy is also unverified, and adopting the Robot route adds one more static entry.
19. **Whether the relay is still necessary, now that certificates for bare IP addresses
    exist.** [ADR-0015](./docs/adr/0015-the-browser-reaches-a-machine-over-pinned-ssh.md)
    rejected having the machine obtain its own certificate and serve its own bridge —
    removing the third party altogether — because it needed a DNS name the target operator
    does not have. Public CAs now issue short-lived WebPKI certificates for IP addresses,
    and a machine has a public IP, so that premise no longer holds. This does not reverse
    the decision, and nothing here has re-weighed it: issuance against an address the
    operator does not own long-term, renewal on a days-long cadence for a machine that must
    stay reachable, address changes, and whether a machine terminating its own TLS beats a
    relay that carries ciphertext it cannot read are all unexamined. It is on this list
    because a rejection resting on a false premise should not be left standing quietly.
20. **Two places where the decision records still say more than this document does.** Both
    concern one-domain-one-machine after
    [ADR-0007](./docs/adr/0007-trust-is-counted-in-two-layers-and-shown.md) split a domain
    into two layers, and neither has been reconciled.
    - **The recovery ladder.**
      [ADR-0004](./docs/adr/0004-one-model-one-machine.md) calls the middle rung free
      because "escalating within a domain grants no access that domain does not already
      have," written while a domain meant an indivisible provider-and-weights pair.
      Escalation is cheap at the proxy layer and puts new weights on the machine, so it is
      safe only if those weights are not running another member — a condition none of the
      three records states. `CONTEXT.md` is furthest off: "escalate to a stronger model
      inside the same trust domain (free, because that domain already has access)" cannot
      describe escalating to a stronger model at all once a domain is counted per layer,
      since same-domain then means same weights.
    - **The rule itself.** ADR-0004 says "one-domain-one-machine holds at each" layer and
      ADR-0007 says "the one-machine-per-domain rule still holds"; `CONTEXT.md` states it
      with no layer qualification at all. Read literally, all three forbid procured
      inference, which those same records require to remain the default. This document
      states the coherent version — the rule binds *access*, collisions are displayed —
      and that divergence is recorded here rather than left for a reader to discover by
      following a link for the *why* and finding the opposite.

## Status and the next move

Nothing here has touched a real server. The proof of concept can call a cloud vendor's API
directly from a browser and has established there is no CORS obstacle — the one external
fact everything depends on. It cannot yet create a machine, and the provisioning state
machine is unbuilt.

The cheapest way to find out which of these decisions is wrong is not to write code. It is
to **write three recipes by hand — create a machine, harden it, install one vault member —
and run them against a disposable project.** That settles three things nothing else can:
which commands genuinely need to run in the browser versus on the machine, whether the
local/remote split is a seam a recipe author trips over, and, most valuable, which steps
could not be expressed as boot-time configuration at all.

If the answer to the last one is "none," provisioning needs no live channel and this plan
gets dramatically smaller — though the channel itself does not disappear, because the
coordinator still has to reach five member APIs on machines with no valid certificate, and
the periodic re-check has to reach a running member long after boot.
