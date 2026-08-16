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
| [`docs/adr/`](./docs/adr/) | The twenty-one decisions, and for most of them the alternatives that were rejected and the grounds for rejecting them — some in a `Considered options` section, some inline, and a few not at all. This document states *what* was decided; an ADR is where *why* lives. |
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

**That gap is widening, not closing.** Most people are mobile-only and will stay that way,
and both mobile platforms keep tightening what may be installed outside their stores. The
browser is therefore not a compromise accepted for convenience — it is the last route by
which a non-technical person reaches real compute, and real AI, without a third party
configuring it for them. That is why constraint 1 is a constraint and not a preference.

The obvious fix is a hosted agent platform, and for one class of task it is unavailable in
principle. Anything whose value depends on *not* trusting a host cannot be delegated to a
host, because the host becomes the party you were trying not to need. Self-custody, key
management, sovereign infrastructure: a vault whose members were all provisioned by one
party has been defeated by that party whatever its intentions, and the same shape recurs
anywhere the point is that nobody else can act for you.

So: a harness that runs in the browser, provisions and operates machines the operator rents
and controls, and makes authenticated calls on their behalf. **Tenants build on it** —
supplying their own briefs, their own software, and their own security requirements
([ADR-0016](./docs/adr/0016-the-harness-isolates-and-counts-tenants-set-thresholds.md)).
Two are intended, and ad hoc use is a third that needs neither of them:

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

Someone who is mobile-only and wants a machine — or a service, or an authenticated call —
that is theirs rather than a hosted product's. That is deliberately wider than any single
tenant, and the harness has no narrower answer to give.

**Each tenant's economics differ sharply, and they are tenant facts rather than product
facts** ([ADR-0016](./docs/adr/0016-the-harness-isolates-and-counts-tenants-set-thresholds.md)).

- **btc-policy.** 3-of-5 by default
  ([ADR-0008](./docs/adr/0008-three-of-five-default-and-its-economic-floor.md)) means five
  machines, which at the `cx22` reference price of €4.59/month is **€275 per year** before
  inference; a 2-of-3 federation is €165. At a willingness to pay roughly 1% per year for
  custody, those imply holdings near €27,500 and €16,500. No vault configuration makes sense
  for someone holding €1,000 — the floor is three machines and three machines cost what they
  cost. *That tenant's* target is a non-technical person with meaningful Bitcoin, worth
  stating plainly rather than letting someone discover it after budgeting for a hobby.
- **lnrent.** The arithmetic inverts. An operator is one machine, not five, and dedicated
  hardware is the best value per unit of capacity for rental — so the cost that makes a vault
  expensive makes a rental server sensible.
- **Ad hoc use.** One machine, no threshold, no federation, and none of the above.

## Constraints

Six constraints bound every decision here. The fourth is satisfied only where a host key
can be pinned out of band — the first stage's dedicated path, not yet the cloud path —
and the sixth is counted and displayed rather than enforced.

1. **The mobile browser is the runtime.** No install, no extension, no native package,
   no desktop, no terminal. A normal HTTPS URL on Android Chrome and iOS Safari.
2. **The AI must be free to act.** Future adversity on a machine is not enumerable in
   advance. Restricting the AI's authority to keep it safe breaks the only reason it is
   there.
3. **Credentials stay in browser memory, or in the named stores invariant 5 carves.** No
   credential is written to storage in cleartext, sent to
   the application's own origin, included in a model request, or persisted in a log.
4. **Beyond the application itself, this product adds one component in every session's
   path — the relay, publisher-run by default and so a capability of an already-trusted
   party rather than a new one
   ([ADR-0019](./docs/adr/0019-the-publisher-operates-the-default-relay.md)) — and it
   must not be able to read or inject.** A transport that can only stall or drop is
   acceptable. This constrains what the *product introduces*, not trust the operator
   already carries: their phone, their cloud vendor, the model they chose. That
   distinction is the whole of
   [What must still be trusted](#what-must-still-be-trusted), and stating the constraint
   any other way makes it unsatisfiable rather than unsatisfied — everything runs on
   something. On the default inference path the publisher additionally selects the models —
   a wider role for a party already trusted for the bundle, not a second added party —
   and bring-your-own inference removes that role.

   **Satisfied under any route that pins the host key out of band; violated under
   trust-on-first-use**, where the relay is trusted at first contact and can have its own
   key pinned
   ([ADR-0015](./docs/adr/0015-the-browser-reaches-a-machine-over-pinned-ssh.md)). No
   out-of-band route exists on the cloud path today: route 1 is dedicated-only and a
   separate integration, **route 2 does not exist** — Hetzner Cloud's rescue action returns
   an action and a root password and no host key — and route 3 is blocked behind question
   13. That is why the first stage runs on dedicated hardware, where route 1 pins out of
   band ([ADR-0018](./docs/adr/0018-first-stage-is-one-lnrent-box-on-dedicated.md)). For
   the cloud path, **route 5 — attest** — is designed to close exactly this gap: a
   one-time secret in user-data lets the machine introduce its own host key through the
   relay with no trust-on-first-use
   ([ADR-0020](./docs/adr/0020-recovery-roots-in-the-vendor-account.md)); it has not yet
   run, and question 3 tracks the probe. Passing the SSH spike is
   necessary and does not by itself satisfy this; the routes are what make it sufficient.
5. **Members must not share a cloud vendor.** The vendor owns its machine's memory and
   disk and is trusted under every design considered, so two members at one vendor is one
   party able to act on both — the correlated fault a threshold cannot absorb
   ([ADR-0006](./docs/adr/0006-single-origin-with-reproducible-builds.md) diversifies
   cloud vendors per member for exactly this reason). Nothing in the design forces vendor
   sharing, so unlike the proxy layer below this one is enforced — at the shipped default
   of one vendor per machine, relaxable by the tenant toward its own quorum-relative bound
   and never past it (invariant 16 states how the two strengths relate). What makes it
   hard is the account floor under [Money](#money) — a reason it is expensive, not a
   reason it is optional.
6. **Independence between members is counted per layer and shown, not enforced.**
   Weights and proxy are counted separately, the provider is counted as observed, and a
   collision at any counted layer is
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
([ADR-0003](./docs/adr/0003-the-ai-runs-only-in-the-browser.md)). The one
machine-originated message *to the harness* is the attest introduction, which acts on
nothing on the machine's behalf — its only authority is the one-time introduction,
handled as the short-lived credential
[ADR-0020](./docs/adr/0020-recovery-roots-in-the-vendor-account.md) classifies. An inference key on a
machine is a credential living outside browser memory and a machine that can call a model
unprompted is a machine that can act unprompted — which is the thing this project exists
to avoid.

The consequence is accepted rather than worked around: **nothing runs while the app is
closed.** Every step must be resumable across a locked phone, and progress must survive
the harness worker being killed.

### Two planes

Actions split into two planes with different rules
([ADR-0002](./docs/adr/0002-cloud-plane-and-box-plane.md)).

**Cloud plane** covers any action taken **off** the operator's machines with a credential
they supplied — creating, destroying, resizing, firewalling or paying at a vendor, and
equally a call to any other third-party service
([ADR-0017](./docs/adr/0017-off-machine-calls-and-scope-approval.md)). It has two approval
modes:

- **Typed operations**, where an adapter exists: the action carries structured metadata and
  each one is approved on its own facts rather than on command text.
- **Untyped calls**, where none does: the operator approves a *scope* — this credential,
  this origin — every call is recorded before it is sent, and the harness **claims nothing
  about what the credential can do.** It usually cannot know: most services publish no
  machine-readable statement of what a key authorizes, and a bound stated on a guess is
  worse than none.

**Box plane** covers shell execution on a machine the operator already owns. It is
free-form, never pre-approved, always recorded.

The split is **off-machine versus on-machine**, and each side carries its own reasoning
rather than sharing one. Box-plane work can be free-form because the worst case is ruining
one machine the operator already bought — that bound is what makes it tolerable. Cloud-plane
work has no such bound: it can spend a credit card, publish irreversibly, or read an entire
account. Where the harness can type the action it shows the facts; where it cannot, the
operator is authorizing **a credential's authority rather than a set of actions**, and the
interface has to say so in those terms.

**Approval means two different things and the interface must not blur them.** Approving an
*operation* means seeing structured facts about one action and permitting it — available
only where an adapter types the action. Approving a *scope* means permitting a class of
activity in advance, which is what box-plane work runs under, because its contents are not
known beforehand, and what an untyped call runs under, because nothing types it.

**A scope names where a credential goes, not what it can do**, and the two cases differ in
what stops the damage. Box-plane work is bounded by the machine. An untyped call is bounded
only by the credential — so approving one is approving that key's full authority at that
host, for as long as it is valid, whatever the brief intended at the time. Where a service
offers a scoped or read-only key, using one is the only thing that actually narrows this,
and it is the operator's move rather than the harness's.

**"Where it goes" is an exact origin, and a redirect that leaves it ends the call.**
Browsers follow redirects automatically, and a credential riding in a custom header rides
along to the new origin — a body does too, under 307/308 — so an approved host with an
open redirect would otherwise launder the credential to an origin nobody approved, in a
request never recorded. (A query-string credential is not replayed by the browser; only a
server that echoes it into the redirect target forwards it.) The header case alone is
enough, and the mechanics force the strict form: under browser fetch, following is
automatic unless disabled — the redirected request would be sent before any check could
run — so **every scoped call is sent with redirect following disabled**, and a redirect
response simply ends the call. The browser returns a blocked redirect opaque, destination
hidden, so nothing can be auto-surfaced for approval: reaching wherever the service moved
starts from what the service documents, as a new scope.

### Briefs

A brief is a document of prose plus example commands, in the shape of an agent skill.
The AI reads it and decides what to actually run; it is not executed verbatim
([ADR-0001](./docs/adr/0001-briefs-are-instructions-not-scripts.md)). A script stops
dead at the first surprise — a changed image name, a package that will not install, a
service that will not start — and the AI exists precisely for the surprises. A setup
nobody can finish sends the operator back to a custodian, which is worse than the risks
this design accepts.

The cost is paid honestly: what runs is not known before it runs, which is what forces
approval to draw on structured facts from the cloud plane rather than on command text.
Adaptations also do not accumulate — the same problem may be solved differently on two
runs, and the library does not improve on its own.

**Briefs ship inside the signed application bundle**
([ADR-0005](./docs/adr/0005-briefs-ship-in-the-signed-bundle.md)). Nothing fetches a
brief at runtime and operators cannot supply their own. A brief is prose that steers a
model, which is prompt injection by design, and every member reads the same brief — so
whoever can change one reaches every member at once. That defeats the honest-majority
assumption rather than being absorbed by it: n honest, competent models faithfully
following poisoned instructions all produce the wrong machine, and agree with each other
perfectly while doing it. The brief is the one component where diversity buys nothing,
so it is locked instead.

The format is **not** shared with lnrent, though this document previously called it a
candidate shared primitive. lnrent's *recipes* are executables its daemon runs with high
privilege; these are prose that must never be run as written, and no format spans both. The
real relationship is a **layering** — one of these documents can tell the AI to invoke an
lnrent hook as a deterministic tool. The library is not shared either: each project ships
its own set inside its own bundle.

### Sessions, trust domains, and diversity

A **session** is one run of the harness under one set of model weights, responsible for
exactly one machine. A federation is provisioned by several concurrent sessions on a
single device ([ADR-0009](./docs/adr/0009-one-device-concurrent-sessions-batched-approval.md)).

**One session, one machine.** Each session is bound to exactly one machine — the one it
provisions, the maintained one it re-enters, or the stuck one it takes over on the
recovery ladder — and never reads, audits, or
touches any other
([ADR-0004](./docs/adr/0004-one-model-one-machine.md)). Access is what composes, not
intent: letting one model touch two machines halves the number of malicious models
needed to reach a k-of-n threshold. Any verification scheme in which one model inspects
another's machine from inside therefore weakens the exact property it appears to
strengthen — the scanner's outside probe is the deliberate exception that proves the
rule, since it grants no access at all.

This rule about access is absolute. The separate question of *how many distinct trust
domains are in play* is not a rule at all but a count, and it comes out differently at
each layer.

**A trust domain is counted at two configured layers plus one observed, never as one
blended number**
([ADR-0007](./docs/adr/0007-trust-is-counted-in-two-layers-and-shown.md)):

- **Weights** — the model itself. Two members on different weights survive one set of
  weights being backdoored, even through a shared proxy.
- **Proxy** — the aggregator routing the request. A compromised proxy can alter every
  prompt and response it carries, whatever weights sit behind it.
- **Provider, observed** — the party that actually served each response, read from
  `X-Provider-Name`. Chosen per request by the proxy, not configured by anyone, so this
  count is historical: it says how many distinct providers the witnessed traffic landed
  at, and it never promises the next request lands the same way.

A 3-of-5 federation on five sets of weights behind one proxy is 3-of-5 against
backdoored weights and 1-of-1 against a backdoored proxy. Both numbers are true; one
number would be a lie about whichever layer is thin, and the thin layer is the one that
gets exploited.
A **collision** — two machines sharing a domain at any counted layer — is therefore *shown,
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
security, since the invariant binds each session to exactly one machine — with
weights-level separation
the goal the assignment serves — and simultaneity does not change which session touches
which machine. It is bounded by mobile memory and proxy rate limits,
which are reasons to cap concurrency rather than to serialize it.

**Why approvals batch.** Every machine creation is known before anything starts, so all
of them fit in one screen showing the whole federation and its true recurring cost.
"Everything unpredictable is box-plane" was true when it was written and gained one
exception when off-machine calls generalized: the unpredictable cloud case is now the
untyped call, and its **scope approval rides the same rules** — approved with the
up-front batch when the brief names the service, and joining the mid-flight queue when
one is discovered later. No untyped call runs before its scope is approved.
Mid-flight cloud-plane interactions stay rare by definition, so the queue is cheap and
never competes with itself for attention. Five concurrent workers producing interleaved
popups on a phone is modal fatigue in its purest form, and the operator cannot tell which
member is asking.

**Recovery is a ladder.** Retry; then escalate to a stronger model behind the same proxy;
then destroy the machine and restart under a different domain, which costs a server. A
stuck machine moves only up its own ladder: re-bound to the successor session at the
middle rung (invariant 1's third binding form), destroyed past it — never handed to any
other session.

The middle rung is cheap because the proxy already had access, so escalating behind it
grants that party nothing new. But the stronger model is *new weights on that machine*,
and that is harmless only while those weights are not also running another member —
otherwise one model has a foothold on two machines, the composition the threshold cannot
survive. [ADR-0004](./docs/adr/0004-one-model-one-machine.md) predates the per-layer
counting that makes this visible and originally called the rung unconditionally free; it
now carries an amendment stating the condition. Partial failure is the normal case and must be a
coherent state the operator can act on, not an error.

### What a session delivers

A session's deliverable is a machine that is provisioned, hardened, running the software
its tenant calls for — the vault software under btc-policy, `lnrentd` under lnrent —
reachable, and **shown to be locked down** by a lightweight self-directed
pentest — open ports, default credentials, sshd posture, exposed services
([ADR-0011](./docs/adr/0011-the-ai-delivers-a-locked-down-machine.md)). Hardening is a
property the session demonstrates, not a step it reports having performed.

**The pentest is a competence check, not an integrity check.** A model examining its own
machine proves nothing against a malicious model. Where the tenant has a threshold it does
not need to — malice is what the threshold absorbs, and the check raises confidence in the
*competent* half of the honest-majority assumption. On a single-machine tenant nothing
absorbs malice and the pentest does not pretend to: that risk is accepted, as the security
claim states plainly. Either way, honest-but-sloppy is the likely failure on a first-time
setup, and it is the one this catches. It never runs from another member.

The job is deliberately not uniform across vendors, because the vendors are not uniform.
Hetzner Cloud has no image upload API at all and requires a rescue-and-write approach,
while others offer import paths that differ from each other and from that. A prebuilt
image is an optimisation available at some vendors, not a contract available at all of
them. That heterogeneity is an argument *for* the AI, not against it.

### The coordinator and federation creation

The **coordinator** is AI-free deterministic code running from the signed bundle on the
operator's device. It takes member endpoints plus operator-supplied recovery descriptors
and forms the federation by calling member APIs. It is the only party that reaches
**inside** every
member, which is permitted precisely because it is not a model — the scanner, which is
one, touches only the public surfaces the whole internet already sees
([ADR-0021](./docs/adr/0021-the-surface-pentest-is-outside-in.md)).

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

**An unfinished setup owns the first screen.** Nothing runs while the app is closed and
no push channel exists — building one would add a server and a party against the grain of
the whole design — so the moment the app opens is the only moment the product can speak,
and it spends that moment on the thing that is costing money. If an unfinished setup
exists, resume-or-abandon *is* the opening screen, not a badge: it shows the running cost
in the same terms the approval screen used — roughly what has been billed so far, and
what it bills per month until finished or abandoned. After roughly a week without
progress the emphasis flips and abandonment leads, because a product that presents a
neutral fork forever has no opinion where the operator most needs one. Abandonment
destroys every machine of the setup through typed operations, and the screen states
plainly what stops billing — the machines — and what does not: the vendor accounts
themselves.

### Member networking

Members open connections to each other only on the vault protocol port, mutually
authenticated. No SSH between members, no arbitrary traffic, everything else denied at
the vendor firewall
([ADR-0010](./docs/adr/0010-members-reach-each-other-on-one-authenticated-port.md)).

**Network reachability is a foothold on the same terms as a credential.** If the five
machines can reach each other, a model controlling machine 1 can attack machines 2
through 5 directly, and the access invariant — one session, one machine — is broken by
the network rather than by any grant. This matters more than it first appears: a k-of-n threshold
assumes faults are **independent**, and one model able to attack four other machines
produces *correlated* faults — the one assumption a Byzantine threshold cannot survive
losing.

The vault protocol must therefore be safe against actively hostile peers, not merely
faulty ones. This is confirmed to be btc-policy's own premise rather than a new
requirement: a policy co-signer inspects exact PSBTs precisely because it does not trust
its peers.

Because firewall rules are cloud-plane, the deny-by-default posture is visible to the
operator, and a brief cannot quietly widen it.

### The browser-to-machine channel

The browser reaches a machine over SSH, verifying the host key against a fingerprint
obtained by other means, through a WebSocket-to-TCP relay
([ADR-0015](./docs/adr/0015-the-browser-reaches-a-machine-over-pinned-ssh.md)). A browser
cannot open a TCP socket to port 22 at all, so a bridge is forced regardless of who runs
it. The check that matters happens inside the SSH protocol at the application layer, so
once the right key is pinned the transport underneath is irrelevant to confidentiality
and integrity.

Five routes to the fingerprint are identified — vendor API retrieval down to
trust-on-first-use with continuity as the floor, plus **attest**, a one-time secret in
user-data under which the machine stamps and introduces its own host key, designed for
the cloud path where retrieval is dead and injection is blocked
([ADR-0020](./docs/adr/0020-recovery-roots-in-the-vendor-account.md)). One route,
Cloud-side retrieval, is
verified dead. A pin lost with a phone is no longer fatal: recovery roots in the vendor
account — the rescue ceremony on dedicated, the recovery sheet mandatory on maintained
cloud machines —
and question 3 keeps what remains empirical. **Under the routes that pin out of band a
hostile relay is a denial of service and nothing worse. Under trust-on-first-use it is
not**: at first contact there is nothing to check the key against, so a hostile relay can
present its own, have it pinned, and read the session from then on. Every route that pins
before first contact — retrieval, injection, attestation — exists to avoid exactly that,
which is why the floor is a floor.

A relay that authenticates callers and constrains destinations **holds real authority over
who may connect where, while holding none over what is said.** Both are true and the
second does not cancel the first. It must not be a generic open proxy; the archived
specification's §21 requirements are the resolution, plus one duty §21 never imagined:
holding attest drop-boxes — buffering a machine's one-time introduction until the browser
collects it ([ADR-0020](./docs/adr/0020-recovery-roots-in-the-vendor-account.md)'s
amendment).

The mechanism is chosen, not proven. It needs an SSH client compiled to
`wasm32-unknown-unknown` with its transport swapped for a WebSocket, which is the single
item most likely to fail.

### Ongoing operation

A machine is not finished when it is delivered. Things break, software rots, and
configurations drift — and the operator has no sysadmin, which is the gap this product
exists to close. So each machine is periodically re-checked, and
upstream releases and security advisories for the software it runs are reviewed
([ADR-0013](./docs/adr/0013-ongoing-operation-periodic-pentest-and-advisory-watch.md)).
This is the work an AI is unusually well suited to and a non-technical operator will never
do, and not doing it is how a correctly-built machine becomes a vulnerable one over a year.

The re-check has an inside and an outside, with different owners
([ADR-0021](./docs/adr/0021-the-surface-pentest-is-outside-in.md)). **Inside** — anything
needing the channel — belongs to the machine's own session and nobody else, because access
composes. **Outside** — the public surface through the relay: which ports answer, whether
deny-everything-but-one-port holds — is the **scanner's**: a specialist model of the
operator's choosing, run after first-online and periodically, holding member addresses and
no credential, no channel, no binding — and composing no traffic: the probes are a
deterministic allowlisted toolset, the model picks targets and reads observations, so
even a malicious specialist cannot attack through the probe. What it costs is topology — the scanner's full
inference path sees the
member set, model, proxy, and provider alike, a named row in the trust display — and what
it produces is reports:
observations that never gate, never act, and are never called verified, since a lying
specialist is a supply-chain attack shaped exactly like a poisoned advisory.

**How much of that is possible is the tenant's decision, not the harness's** — it follows
from the tenant's *access model*, exactly as the threshold does
([ADR-0016](./docs/adr/0016-the-harness-isolates-and-counts-tenants-set-thresholds.md)).
On **maintained** machines — lnrent boxes, ad hoc use — the machine is re-entered: a later
session, bound to it as its one machine under invariant 1, does repair, patching, the full
re-check, with the scanner probing the outside. On **sealed** machines nothing re-enters,
by the tenant's own design:
btc-policy uninstalls SSH after setup and forbids upgrade-in-place, precisely so nobody can
be forced back into a vault node. There the inside half simply does not exist and the
re-check *is* the scanner's
surface probe — deny-everything-but-one-port is observable from outside, through the relay,
though the result is only as trustworthy as the relay that carries it and is shown as what
the relay reported, never as verified — plus an advisory watch whose only remedy is rotating
to a successor vault. Runtime
monitoring stays the tenant's own: every vault node is already its own watchtower.

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
of feeds ships signed like the briefs, since a feed URL changeable at runtime steers
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
few invoices, subject to the browser reachability that question 7 records as still unprobed.
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
briefs, though not the only one: see the software signer below.
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

1. **A session MUST be bound to exactly one machine and MUST NOT read, audit, or touch
   any machine it is not bound to.** A session is bound by provisioning a machine; by
   re-entry, on a maintained machine only; or by the recovery ladder's escalation, which
   re-binds a half-provisioned machine to the successor session under the rung's
   condition — a machine mid-provisioning is neither provisioned nor maintained, and
   without this third form the ladder's middle rung would be unreachable. **Binding is an
   operator act in the browser,
   made before any channel access**: the operator assigns the machine at session creation,
   for provisioning, re-entry, or escalation, and connecting is never what creates the
   binding —
   otherwise a refused session and a re-entering one would be indistinguishable at the
   relay. Access is what composes, not
   intent: a model with a foothold on two members halves the number of malicious domains
   needed to reach k-of-n ([ADR-0004](./docs/adr/0004-one-model-one-machine.md)). No
   exception for debugging, for auditing, or for any scheme in which one model inspects
   another's machine from inside — the scanner's access-free surface probe
   ([ADR-0021](./docs/adr/0021-the-surface-pentest-is-outside-in.md)) is outside this
   subject, not an exception to it. The permanence below is tracked in the **exposure
   ledger** — persisted state and recovery-sheet content
   ([ADR-0020](./docs/adr/0020-recovery-roots-in-the-vendor-account.md)); a machine
   recovered without it, or from a stale sheet, carries **unknown past exposure**,
   displayed as such, and re-entry then binds only a configured model not currently
   assigned to any other machine. **Exposure is permanent for the life of the machine**: a model that
   has touched a machine counts as touching it until that machine is destroyed, because
   ending a session does not remove whatever the model may already have left behind. So the
   recovery ladder's middle rung stays inside this rule only while the stronger
   configured model is not assigned — and will never be assigned — to any other member;
   past that rung the machine is
   destroyed rather than handed on. **Re-entry stays inside this rule the same way**: the
   machine outlives its sessions, so a later session may be bound to it — but to it alone,
   and the configured model that session runs counts as having touched it permanently,
   under the same condition as the rung: the product never assigns it to another machine.
   Assignment is what the product controls and these conditions bind at that layer;
   whether two configured models are secretly the same weights is the unobservable case
   below, a displayed collision.

   **What this invariant reaches, and what it does not.** It binds the harness's own
   channels — the box-plane channel and typed operations — where the product decides which
   machine a session may touch, so there it is enforceable and absolute. An approved
   untyped scope is outside its reach: if the service behind the scope can itself
   administer machines, what bounds the session there is the credential's authority,
   counted in the blast radius and shown until the credential is revoked or rotated —
   which is why invariant 4
   refuses scopes at known vendors, and why the security claim states machines *plus
   scopes* rather than resting on this invariant alone. A **scanner** run
   ([ADR-0021](./docs/adr/0021-the-surface-pentest-is-outside-in.md)) is outside this
   invariant's subject because it is bound to no machine — and for exactly that reason it
   MUST NOT hold any machine credential or channel: addresses in, observations out,
   nothing else. It does not decide
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
4. **A typed cloud-plane operation MUST be approved on structured facts, never on command
   text — and an untyped call MUST NOT be presented as though its scope bounds what the
   credential can do.** A scope names where a key goes. For box-plane work the machine
   bounds the damage; for an untyped call nothing does, and an approval screen that reads
   like a limit is the overstatement this design refuses everywhere else
   ([ADR-0017](./docs/adr/0017-off-machine-calls-and-scope-approval.md)). **A scope MUST
   NOT name a vendor the harness knows**: a vendor control API
   reaches every machine on the account — machines other sessions are bound to — and with
   no adapter the harness cannot see which resource a call touches, so an untyped scope
   there is a path around invariant 1 that nothing records at the machine level. Vendor
   APIs are typed operations or nothing — and **a typed operation that names an existing
   machine MUST be authorized against the calling session's binding**: a session's vendor
   operations reach its own machine and account-level creation, nothing else, enforced by
   the adapter rather than left to the approval screen. Beyond the vendors it knows, the
   harness cannot classify what a third-party credential administers — that reach is
   exactly what the blast-radius statement counts an active scope as, and the approval
   screen says so rather than implying the service was vetted.
5. **Credentials the harness holds MUST NOT leave browser memory, except under the named
   exceptions below** — never to the app's own origin, never into a model request, never
   into a log, and to storage only as named. **Persistence at rest**: the SSH client key,
   the relay token, and the host-key pins persist locally, encrypted at rest and unlocked
   by the operator at app open — ongoing operation cannot survive a restart without them,
   and a rule that pretends otherwise would be broken daily in silence. **The recovery
   sheet**: an operator-initiated export, passphrase-wrapped, that deliberately leaves
   the device ([ADR-0020](./docs/adr/0020-recovery-roots-in-the-vendor-account.md)). **The
   attest voucher**: a short-lived introduction credential, harness-generated and placed
   in user-data once — it authorizes exactly one introduction, expires, becomes single-use
   because the browser verifies the first valid stamp and discards the secret (the
   drop-box only buffers; it cannot judge validity), is scrubbed from the machine's
   cloud-init artifacts at first boot, and is redacted from records and model input. Nothing else is excepted, each exception is named before
   use per the standard question 13 sets, and the injection route for SSH host keys
   remains a conflict tracked at question 13. The
   invariant covers what the operator supplies and what the harness generates; a secret a
   service returns inside an untyped response is outside the harness's sight and outside
   this rule's reach —
   [ADR-0017](./docs/adr/0017-off-machine-calls-and-scope-approval.md) records that limit,
   and the moment such a secret is supplied *to* the harness as a credential, it is
   covered.
6. **The AI MUST NOT touch key material.** Recovery descriptors come from the operator.
   Member keys are generated on the machine and never exported.
7. **Briefs and advisory feed lists MUST ship in the signed bundle** and MUST NOT be
   fetched, configured, or substituted at runtime.
8. **All tool output and fetched external content MUST be typed as untrusted** and MUST
   NOT authorize an action on its own, declare capabilities, or override policy.
9. **Trust counts MUST be shown per layer and MUST NOT be blended into a single score** —
   and the observed provider count MUST be labeled as historical observation, never
   presented as forward-looking distinctness.
10. **The trusted-party list MUST NOT grow silently.** Any feature adding a party to it is
    a change of the same weight as a schema migration.
11. **An SSH session MUST check the host key against the stored fingerprint, and a key
    that does not match MUST halt the session.** Exactly one moment is exempt and it is
    the reason route 4 is a floor: under trust-on-first-use there is no stored
    fingerprint at first contact, so that contact is trusted rather than verified and
    MUST be presented to the operator as such. No other path may accept an unverified
    key.
12. **Every off-machine call made with an operator credential MUST be recorded before it is
    sent.** For a typed operation this is bookkeeping. For an untyped call it is the *only*
    safeguard standing behind it, since the harness cannot bound what the credential
    authorizes — which is what makes it an invariant rather than a described behaviour.
    A call interrupted between the record and a confirmed response has an **unknown
    outcome**, and for an untyped call no adapter
    exists to find out. (The CORS sent-but-unreadable case is engineered away: an
    origin's route is chosen by a dedicated harmless probe before any side-effecting
    call exists, every untyped call carries a custom header so no simple request exists,
    and a real call's failure never selects a new route. Should an unreadable
    response occur anyway, it is the same unknown outcome.) So the record MUST
    carry that unresolved state, the harness MUST NOT retry the call on its own or report
    it as failed, and
    reconciliation belongs to the operator, at the service.
13. **The app MUST NOT hold, forward, or custody funds.** A Bitcoin wallet able to pay for
    machines is an intended future capability and it collides with this, so the collision is
    recorded rather than resolved (question 17). Self-custody would not breach
    [ADR-0014](./docs/adr/0014-the-app-relays-invoices-and-never-holds-funds.md)'s
    *reasoning* — nobody is asked to trust an intermediary — but it changes what a bundle
    compromise costs, from misconfiguring machines to spending the money, behind the one
    risk this document already calls unmitigated. Whoever builds it settles this first.

### Supplied by btc-policy, not by the harness

The three below are federation rules. They bind wherever a tenant requires a threshold and
mean nothing for a single machine, so under
[ADR-0016](./docs/adr/0016-the-harness-isolates-and-counts-tenants-set-thresholds.md) they
belong to that tenant and move with it. They are listed here, unchanged, until pointers
into btc-policy's own records replace them — the meta project exists but holds only the
coordination layer, the ecosystem map and the term register — and an implementer building
for a tenant without a threshold is not bound by them.

14. **Members MUST NOT be reachable from each other except on the vault protocol port,
    mutually authenticated**, with everything else denied at the vendor firewall.
15. **A federation MUST NOT be formed until every member is provisioned, hardened, and
    reachable.**
16. **No cloud vendor's machines may reach a federation's quorum — the tenant's rule,
    which binds. The harness ships a stricter default: one vendor, one machine.**
    Stated in machines rather than members deliberately: nothing has joined a federation
    when this rule has to bind, so a rule about "members" would not reach provisioning at
    all. The vendor owns its machines' memory and disk, so two of them at one vendor is
    a single party able to act on both — the correlated fault invariant 14 exists to prevent
    at the network layer, arriving instead through the billing relationship. The two
    statements are one rule at two strengths: btc-policy ADR-0009's quorum-relative form is
    the bound an implementation MUST enforce, and the flat one-vendor-per-machine form is
    the default the harness applies — relaxable by the tenant toward its own bound, never
    past it, and never by the harness on its own. An implementation that blocks at the
    default and lets the tenant open it to the bound satisfies both. Unlike every
    other entry here this one has no decision record of its own: it rests on
    [ADR-0006](./docs/adr/0006-single-origin-with-reproducible-builds.md)'s statement that
    cloud vendors are diversified per member, which is background to a decision about
    *origin* diversity, plus the correlated-fault argument in
    [ADR-0010](./docs/adr/0010-members-reach-each-other-on-one-authenticated-port.md). It
    is the rule whose collision **blocks** where the weights and proxy layers only display
    (constraint 6) — first binding in the second
    stage, with the vault — so it should have a record of its own.

## The security claim, stated exactly

The harness and its tenants make **different** claims, and blurring them is how a single
machine ends up shipping under a vault's guarantee
([ADR-0016](./docs/adr/0016-the-harness-isolates-and-counts-tenants-set-thresholds.md)).

**What the harness claims.** No session reaches a machine it is not bound to **through
anything the harness controls** — bound by
provisioning it, by re-entry on a maintained machine, or by the recovery ladder's
escalation of a stuck one. A model's blast radius is the
machines its weights have touched — plus, once an untyped scope is approved for its
session, that credential's authority at that origin, which may itself reach machines the
harness cannot see; the two are stated together because neither alone is the boundary.
Every approved scope appears in the trust display **until its credential is revoked or
rotated** — closing the approval does not un-trust a service that still holds the key.
Nothing beyond those two. The trusted set is named rather
than small — sorted below into what any software requires, what the operator chose, and
what this product adds — and the tier this product adds is fixed: only it is the harness's
to control, and it holds three entries. What the harness *removes* is the party that would otherwise choose the operator's
vendor, model and configuration while holding their credentials.

**What the harness does not claim, and cannot: that the model is honest.** With one machine
there is no threshold, so nothing absorbs a malicious model — a compromised one owns the
machine it just configured, and no mechanism here notices. The pentest is a competence check
by its own definition and the verifier reads what the machine chooses to tell it, so neither
closes this. Ad hoc use ships under the smaller claim rather than borrowing a larger one.

**What btc-policy stacks on top:**

> **No single model provisioned enough members to reach the threshold.**

That claim needs a vault. It is conditional on the trust domains being genuinely distinct:
if several endpoints serve the same weights the operator has one model rather than five and
it is vacuous — which is why the counting is shown to them, and why the weights-diversity
item in the open questions matters. At that layer distinctness may not be enforceable at
all, and until it is, this is a design goal rather than a demonstrated property.

There is no verification layer and nothing in the product may imply one. Every scheme
where a second model inspects a finished machine **from inside** hands that model a second
foothold — the scanner never does; it reads only the public surface
([ADR-0021](./docs/adr/0021-the-surface-pentest-is-outside-in.md)) — and
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
provisioned by a specific vendor and configured model, plus the set of inference
providers observed serving it — is durable, and in the
first version a local claim rather than evidence.

## What must still be trusted

Everything runs on something. The phone's silicon, its operating system, the browser, the
model, whoever serves it, the cloud vendor, the server's firmware — any of them could carry
a backdoor, and following that regress to the end leaves you hand-fabricating chips in a
Faraday cage. **There is no zero.** So this section does not try to be short. It tries to be
accurate, and it sorts the parties by the one distinction that changes what anybody can do
about them: who chose them.

### Unavoidable

True of any software anyone runs, and not improved by this design.

- **The operator's device** — its silicon, its operating system, its browser. It holds the
  credentials, runs the bundle, and carries all five concurrent sessions, so it is
  common-mode across every member. A deliberate trade: requiring five devices would defend
  against a compromised phone while guaranteeing that an operator who owns one phone never
  finishes setup.
- **The stack underneath everything** — the operating systems on the machines, their
  package repositories, the certificate authorities. Trusted here no more and no less than
  anywhere else. Naming each one would make this list unbounded without making it more
  honest.

### Elective

Real trust, and **the operator or the publisher chose it and could choose otherwise.** This
is exactly the set a hosted service picks on your behalf, silently and unlisted.

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
  by the same one share a party the third, **observed** count now reports — historically,
  per response, never as a forward promise
  ([ADR-0007](./docs/adr/0007-trust-is-counted-in-two-layers-and-shown.md)'s amendment).
  It stays named here because observation is not separation.
- **A majority of the models**, being both honest *and* competent.
- **The scanner's model, when the operator engages one** — trusted to see the member
  topology and to report honestly, never with access
  ([ADR-0021](./docs/adr/0021-the-surface-pentest-is-outside-in.md)). A lying scanner
  cannot touch a machine; what it can do is steer the operator, which is why its findings
  are reports and never triggers.
- **Any service an approved untyped call reaches.** The operator hands it a credential
  whose authority the harness cannot bound, so for the life of that key the service is
  trusted with everything the key can do. This class cannot be enumerated in advance —
  which is why it is named here as a class, and why each approved scope must appear in the
  trust display until its credential is revoked or rotated — not merely while the approval
  stands, since closing it does not un-trust a service that still holds the key — rather
  than in this list by name
  ([ADR-0017](./docs/adr/0017-off-machine-calls-and-scope-approval.md)).
- **Whoever signs the software the machines run** — the vault software under btc-policy,
  `lnrentd` under lnrent, whatever a brief installs for ad hoc use. For a single machine
  the signer is trusted for that machine, the same shape as any installed software. For a
  federation it is sharper: briefs install the same release on
  every member, so the signer is common-mode across the federation in the same shape as the
  bundle — which means
  [ADR-0005](./docs/adr/0005-briefs-ship-in-the-signed-bundle.md)'s claim that the bundle
  is "the only remaining single point of total compromise" is one party short — as is
  [ADR-0006](./docs/adr/0006-single-origin-with-reproducible-builds.md)'s "the bundle is
  the remaining single point of total compromise," which says the same thing in a record
  this document does not otherwise amend. Artifact pinning would bound this; nothing here
  specifies it yet.

### Added by this product

The only set the design controls, and therefore the only one worth an invariant. **Invariant
10 guards this tier** — a feature that adds an entry here is a change of the same weight as
a schema migration. The other two tiers grow when the world does; this one grows only when
someone decides it should.

- **The app bundle, and the publisher who serves it.** This is the application itself
  rather than a third party, but it is not diversified across members and it carries the
  briefs, so a compromised host can serve one build that misbehaves on every member — and
  can serve a good bundle to anyone who looks like a checker. **The largest concentrated
  risk in the design.** On the default path the publisher also selects the models, which is
  acceptable only because it is already trusted for the bundle and because bring-your-own
  inference exists as the escape hatch. If that hatch is ever dropped, the arrangement stops
  being defensible.
- **The relay**, once it exists — trusted narrowly. It cannot read or alter a session
  whose host key was pinned out of band, but it learns
  connection metadata, and one that authenticates callers and constrains destinations
  decides who may connect where. Under trust-on-first-use it is trusted outright at first
  contact. On the default path its operator is **the publisher**
  ([ADR-0019](./docs/adr/0019-the-publisher-operates-the-default-relay.md)), so the entry
  is less a new party than the publisher's second capability — bundle plus connection
  metadata — and the trust display names the operator; under bring-your-own it is whoever
  the operator points at. The publisher's seat is a **bootstrap**: the relay is
  direct-first and minimum-usage by design, and the product moves the operator to a relay
  on a maintained machine of their own once one exists (ADR-0019's amendment; a sealed
  vault node hosts nothing) — so the default's metadata
  visibility is transitional, not a resting state.
- **The coordinator**, narrowly and during setup only, as the only party that reaches inside every
  member. It is deterministic code running from the signed bundle on the operator's own
  device, so it is the application rather than a separate party — but it is listed because
  its reach is broader than anything else the application does.

**What this product actually removes** is the party that would otherwise pick every entry in
the elective tier and hold the credentials besides: the service operator. That is the whole
of the claim. It is a smaller claim than "trustless" and it is one that survives contact
with the regress above.

## What the first stage must demonstrate

The first stage provisions **one lnrent box on a dedicated server, over the full channel**
([ADR-0018](./docs/adr/0018-first-stage-is-one-lnrent-box-on-dedicated.md)). One session,
one machine, one real tenant, and deliberately the hardest machinery: Robot offers no
pre-boot configuration at all, so nothing can be done to the machine except through the
channel — which forces the WASM SSH spike, the relay, and the rescue flow to succeed or
fail in week one. It replaces the two-cloud-machine diversity demo the design session
chose: that staged a vault argument the platform no longer leads with, proved the easy
machinery, and deferred both hard problems.

Acceptance is these predicates:

1. The session registers its SSH client public key with Robot as a **typed operation** —
   Robot's `authorized_key` field takes fingerprints of keys already registered there, not
   raw keys — then activates rescue the same way, passing that fingerprint, triggers the
   reboot into
   it the same way — activation only configures the next boot; Robot's reset call is
   its own typed operation, since nothing else can restart a machine the harness cannot
   yet reach — retrieves the rescue host
   key from the API response, and connects with **no trust-on-first-use at either hop**:
   the rescue key is pinned from the API, and the installed system's host keys are
   generated inside the rescue session, per machine, and read before reboot. The response
   also carries a generated **root password**; it is never used — the client key is the
   credential — and it is **redacted before the response is recorded or reaches a model**.
2. The system is installed and hardened entirely through box-plane work over the pinned
   channel, and every byte sent to the machine is **recorded before transmission**; the
   transcript matches what was sent.
3. The machine ends **locked down and demonstrated**: the deliverable of
   [What a session delivers](#what-a-session-delivers), with `lnrentd` running and
   reachable.
4. The machine is **maintained**, and the story is exercised: at least one later session
   re-enters over the same pinned channel and re-runs the check.
5. No credential — the Robot credential, the rescue root password Robot returns, the
   inference key, the SSH client private key,
   or the relay token (pasted out of band for the first stage,
   [ADR-0019](./docs/adr/0019-the-publisher-operates-the-default-relay.md)) — appears in a
   request to the app origin, in any model request body, or in any log — and none appears
   in IndexedDB, local storage, or service-worker caches outside the encrypted-at-rest
   store invariant 5 names: cleartext nowhere. The client key is a **new
   credential class** (question 3) and its handling is stated, not silently extended.
6. A rescue activation or its reset, interrupted between intent and confirmation, then
   resumed, results in exactly one rescue session and one install.
7. All of the above pass on Android Chrome and iOS Safari, through a normal HTTPS URL,
   with no install.
8. A channel access that does not present the bound session's authorization — however
   well-formed the attempt — is **refused**. With one machine, nothing exercises the
   harness's central access rule by accident: this predicate shows the refusal is enforced
   by mechanism rather than satisfied by scarcity, and it is distinguishable from
   predicate 4's re-entry precisely because binding is the operator's act, not the
   connection's.

Provenance is still recorded — vendor, inference provider, model, surviving reload and
restart — and the per-layer counts are still shown, per invariant 9: the configured
counts read one — one set of weights, one proxy on the procured path, no proxy entry at
all under local inference, which removes that layer rather than counting it — and the
observed provider count reports whatever the traffic shows, which even for one machine
can exceed one, since the proxy picks the provider per request. The smaller claim, stated
as numbers. What waits is
comparison: with one machine there is no collision to display, so the collision display
and the operable panel arrive with the tenant that needs them.

The second stage brings the vault: Cloud machines, multiple concurrent sessions, the trust
panel, the coordinator, federation formation, all-or-nothing creation — and Cloud's
identity problem — route 2 dead, injection blocked behind question 13, attest designed
for exactly this and unproven (question 3). It reuses the channel the first stage proved. If the spike fails instead, the fallback
is the old cloud-first stage with the channel question reopened.

## The decisions

Each is a consequence of the ones above it. Where a decision had a real alternative, the
record carries it and the grounds for rejecting it.

| ADR | Decision |
|---|---|
| [0001](./docs/adr/0001-briefs-are-instructions-not-scripts.md) | Briefs are instructions the AI reads, not scripts it executes |
| [0002](./docs/adr/0002-cloud-plane-and-box-plane.md) | Cloud-plane actions are typed operations, box-plane actions are free shell — untyped calls arrive with 0017 |
| [0003](./docs/adr/0003-the-ai-runs-only-in-the-browser.md) | The AI runs only in the browser; a machine is a target, never an actor |
| [0004](./docs/adr/0004-one-model-one-machine.md) | One model, one machine, and an honest-majority assumption |
| [0005](./docs/adr/0005-briefs-ship-in-the-signed-bundle.md) | Briefs ship in the signed app bundle |
| [0006](./docs/adr/0006-single-origin-with-reproducible-builds.md) | One origin, with reproducible builds |
| [0007](./docs/adr/0007-trust-is-counted-in-two-layers-and-shown.md) | Trust is counted in two layers, and shown rather than scored |
| [0008](./docs/adr/0008-three-of-five-default-and-its-economic-floor.md) | 3-of-5 as btc-policy's default, and the economic floor it implies |
| [0009](./docs/adr/0009-one-device-concurrent-sessions-batched-approval.md) | One device, concurrent sessions, approvals batched up front |
| [0010](./docs/adr/0010-members-reach-each-other-on-one-authenticated-port.md) | Members reach each other on one authenticated port, everything else denied |
| [0011](./docs/adr/0011-the-ai-delivers-a-locked-down-machine.md) | The AI delivers a locked-down machine and demonstrates it, per vendor |
| [0012](./docs/adr/0012-a-federation-is-created-only-when-every-member-works.md) | A federation is created only when every member works |
| [0013](./docs/adr/0013-ongoing-operation-periodic-pentest-and-advisory-watch.md) | Ongoing operation: periodic pentest and advisory watch |
| [0014](./docs/adr/0014-the-app-relays-invoices-and-never-holds-funds.md) | The app relays invoices and never holds funds |
| [0015](./docs/adr/0015-the-browser-reaches-a-machine-over-pinned-ssh.md) | The browser reaches a machine over SSH, pinned at the application layer |
| [0016](./docs/adr/0016-the-harness-isolates-and-counts-tenants-set-thresholds.md) | The harness isolates and counts; tenants set thresholds |
| [0017](./docs/adr/0017-off-machine-calls-and-scope-approval.md) | Off-machine calls generalize the cloud plane; untyped ones are approved by scope |
| [0018](./docs/adr/0018-first-stage-is-one-lnrent-box-on-dedicated.md) | The first stage is one lnrent box on a dedicated server, over the full channel |
| [0019](./docs/adr/0019-the-publisher-operates-the-default-relay.md) | The publisher operates the default relay; bring-your-own is the escape hatch |
| [0020](./docs/adr/0020-recovery-roots-in-the-vendor-account.md) | Recovery roots in the vendor account; the cloud pin is introduced by attestation |
| [0021](./docs/adr/0021-the-surface-pentest-is-outside-in.md) | The surface pentest is outside-in, and may use a specialist model |

## Open questions

This is the only list. Anything else that reads like an open question elsewhere in this
repository is history.

### Gating

1. **The SSH client spike.** An SSH implementation compiled to `wasm32-unknown-unknown`
   with its transport swapped for a WebSocket. `russh` is the realistic Rust candidate but
   is async and tokio-shaped. This is unproven work of the same character as the archived
   specification's M0 gates, and it is the item most likely to fail. A failure sinks this
   stage's whole approach: the recorded fallback is the old cloud-first stage, with the
   channel question reopened
   ([ADR-0018](./docs/adr/0018-first-stage-is-one-lnrent-box-on-dedicated.md)).
2. **The relay's identity system.** What the relay must *do* is settled — authenticate
   the user, enforce destination policy, prevent generic open-proxy behaviour, per the
   archived specification's §21 — and who runs it is now decided too: the publisher by
   default, bring-your-own as the escape hatch, with the first stage on a token issued
   out of band and pasted once
   ([ADR-0019](./docs/adr/0019-the-publisher-operates-the-default-relay.md)). What stays
   open, and gates the second stage: the real token system — issuer, identity model,
   first issuance, scoping and lifetime, and reacquisition after browser storage is
   lost. Done carelessly that adds an identity party to the trusted list, which is why it
   was deliberately not decided in passing. Reinstating a relay at all reverses the proof
   of concept's own §4, which listed one as explicitly absent.
3. **The recovery machinery is designed and unproven.** The design is now recorded:
   recovery roots in the vendor account, the rescue ceremony re-verifies on dedicated,
   the recovery sheet is mandatory on maintained cloud machines, and **attest** — route 5 —
introduces the
   cloud pin at creation with no trust-on-first-use
   ([ADR-0020](./docs/adr/0020-recovery-roots-in-the-vendor-account.md)). The client key
   itself is a new credential class the first stage counts — acceptance predicate 5 names
   it beside the Robot credential and the inference key; the route-3 host private key at
   question 13 would be the next. What stays open is empirical, and it still gates: the
   attest hook has to fire reliably on a real first boot and post through the relay; the
   rescue ceremony has to be rehearsed once end to end; and the sheet needs a format an
   operator can actually re-import. Until those run, the channel's loss story is a design,
   not a property.
4. **Weights-level diversity may not be enforceable.** The available runtime signal names
   the *inference provider*, not the weights
   behind it — and the provider is a layer nobody configures, so there is nothing there to
   enforce either: the honest position is the one the counting amendment records — report
   what was observed, promise nothing forward, and stop claiming more. The security claim
   stays conditional on weights-level distinctness. The provider itself is no longer uncounted: it is the third,
   **observed** count under
   [ADR-0007](./docs/adr/0007-trust-is-counted-in-two-layers-and-shown.md)'s amendment —
   built from `X-Provider-Name` per response, historical, never implying forward
   distinctness. What stays open is whether any signal can ever reach the weights
   themselves; until one can, the weights count rests on configured model identity, which
   is exactly the conditionality the security claim already carries.
5. **The cloud-account floor.** Cloud vendors want an account, a card, and a recurring
   relationship, several times over, and invoice relay cannot fix it. This is what makes
   lnrent structural rather than a second tenant, and it is what makes constraint 5 hard.
6. **What Hetzner Robot's rescue `host_key` field actually returns** — full public keys,
   fingerprints, which algorithms. Undocumented, and **first-stage-blocking**: route 1
   is the first stage's identity chain
   ([ADR-0018](./docs/adr/0018-first-stage-is-one-lnrent-box-on-dedicated.md)), which is
   why this sits among the gates despite being one authenticated call from closing. The
   same call should re-check that Robot is still reachable from a browser at all: that
   result rests on a single recorded probe, and vendor CORS headers are exactly the kind of
   external dependency the continuous probe elsewhere in this document exists to catch
   regressing.

### One probe or one boot from closing
7. **Whether the second inference proxy is reachable from a browser at all.** An
   OpenAI-compatible API does not imply an origin may call it. This needs the same probe
   the first proxy got before the trust panel can offer it as a one-tap action.
8. **Whether a second cloud vendor's API permits a browser origin.** Roughly eighty lines
    of curl — the existing probe is a template, not a drop-in, since it hardcodes the first
    vendor's base URLs, paths, and assertions. Constraint 5 depends on the answer.
    Candidates include Vultr, DigitalOcean, Linode, and lnrent itself, which is interesting
    because it needs no cloud account at all.
9. **Whether the proof of concept's cloud-init boots an unreachable machine.** A code-read
    finding, not an observed failure: its user list has no default entry and sets an empty
    authorized-keys list, so the vendor's injected keys reach no account. The fix is one
    line and nobody has booted the file. Do this before anything depends on being able to
    log in.

### Design-level, still unanswered

10. **The brief format schema.** Frontmatter fields, the local/remote block marker, how a
    block returns structured data to the next one, versioning, signing. Designing a second
    consumer for an undefined format is premature until this exists.
11. **What executes brief commands locally in the browser.** Either a WASI host with
    uutils guests, as the archived specification assumes, or a small set of purpose-built
    commands. This is deliberately not decided in advance: the scope is to be derived from
    real briefs rather than guessed, and the archived specification's answers here are
    currently guesses.
12. **Mid-brief recovery at step granularity.** Duplicate-create protection is designed
    but the provisioning state machine it needs is not built, and a multi-step brief needs
    the same idea per step on top of it.
13. **Whether injecting the SSH host key is permitted, and on what terms.** Route 3 writes
    a *private* host key into boot-time user-data, which the vendor stores — squarely
    against invariant 5. [ADR-0015](./docs/adr/0015-the-browser-reaches-a-machine-over-pinned-ssh.md)
    says the contradiction may not be left standing, and there is only one way out: carve a
    **narrow exception for the injected server host key specifically**, before the route is
    used. Not a rewrite of invariant 5 down to "vendor and inference credentials" — that
    phrasing would quietly strip the SSH *client* private key (question 3) and the relay
    token (question 2) of the same protection, which is a larger hole than the one being
    patched. Scrubbing and rotating the key after first boot limits exposure but resolves
    nothing; the key has already been exported. That decision has not been taken, and route
    3 cannot be used until it is. The pressure to take it has dropped: attest (route 5)
    now covers the cloud introduction this route was the only hope for
    ([ADR-0020](./docs/adr/0020-recovery-roots-in-the-vendor-account.md)), so injection
    stays blocked without blocking anything else.
14. **What "locked down" means, per vendor.** A pentest can
    only assert what it checks, so the checklist is part of the signed brief set
    ([ADR-0011](./docs/adr/0011-the-ai-delivers-a-locked-down-machine.md)) — and it does
    not exist yet for any vendor. Until it does, the deliverable in
    [What a session delivers](#what-a-session-delivers) has no definition to be measured
    against. Who may run which check is no longer open:
    [ADR-0021](./docs/adr/0021-the-surface-pentest-is-outside-in.md) settled the former
    divergence — the delivery check is the session's own, the periodic surface pentest is
    the scanner's, the coordinator may run the deterministic verifier during setup (its
    only window), and the verifier's ongoing runner stays the machine's own session.
15. **Reproducible builds and the watchdogs that would make them mean something.** Neither
    exists. Until they do, the bundle's integrity rests on trusting the host outright.
16. **Content-Security-Policy admission.** The collision this question used to carry is
    resolved by deciding which side gives: **the policy is not the security boundary for
    off-machine calls — approval and recording are** (invariants 4 and 12). The design
    does not restrict what the harness can reach; it restricts what runs without the
    operator's say. So `connect-src` is permissive for `https:` and `wss:` alike, stated
    plainly rather than pretending the list contains anything — exactness for the relay
    was only free while its origin was a constant, and the bring-your-own and self-hosted
    trajectories make it configuration. Calls are **direct-first**: the browser
    reaches a service itself wherever CORS permits, and the relay carries only what
    cannot go direct — SSH always, CORS-refused untyped calls as a tunneled fallback
    under TLS that terminates in the browser, and the machine-originated attest post via
    its drop-box
    ([ADR-0019](./docs/adr/0019-the-publisher-operates-the-default-relay.md)'s amendment).
    What stays open here is empirical: runtime admission of the policy is unverified, and
    the tunneled fallback needs the same WASM TLS machinery character as the SSH spike.
17. **Where a wallet could live, if it is ever built.** Paying for machines and services
    from inside the harness is an intended capability, and invariant 13 collides with it.
    [ADR-0014](./docs/adr/0014-the-app-relays-invoices-and-never-holds-funds.md) holds the
    three live options — a separate origin, which
    [ADR-0006](./docs/adr/0006-single-origin-with-reproducible-builds.md) rejected for
    user safety and whose objection would have to be answered rather than ignored; the
    same bundle, with invariant 13 rewritten and the undefended-bundle risk repriced from
    misconfiguring machines to spending funds; or a tenant of its own. None is chosen.
    Whoever builds it settles this first.

## Status and the next move

Nothing here has touched a real server. The proof of concept can call a cloud vendor's API
directly from a browser and has established there is no CORS obstacle — the one external
fact everything depends on. It cannot yet create a machine, and the provisioning state
machine is unbuilt.

The cheapest way to find out which of these decisions is wrong is still not to write code.
It is to **run the first stage by hand once**: activate Robot rescue on a disposable
dedicated server, read what `host_key` actually returns (question 6), install and harden
from inside the rescue session, stand up `lnrentd` — and write the briefs for those steps
as you go, since they are the first three briefs the product needs. That settles what
nothing else can: whether the no-TOFU chain works end to end, which commands genuinely
need the browser versus the machine, and whether the brief format survives contact with a
real install.

The old assignment's sharpest question — which steps could not be expressed as boot-time
configuration at all — is answered by fiat on this path: on Robot, none can be, so the
channel gates everything. It returns as a real question in the second stage on Cloud,
where user-data exists and could shrink the channel's role in provisioning — though never
to zero, because the coordinator still has to reach member APIs on machines with no valid
certificate. The periodic re-check is not a second reason there: vault nodes are sealed,
so their re-check is an external probe through the relay, never a session inside.
