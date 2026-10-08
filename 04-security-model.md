# 04 — The security model

## The posture, stated before the rules

**The AI is a trusted party by default.** It is the operator's agent. It holds a root shell
on each machine of its bound set, it can read what is on those machines, and that is ordinary —
it is what any sysadmin has, and `OVR-2` exists because taking it away breaks the only
reason the AI is there.

Two rules used to be written as absolutes that a root shell already defeats: that the AI
never touches key material, and that a machine never holds a vendor API token. Neither was
enforceable, and stating them as invariants made the whole list weaker by putting
unenforceable entries beside enforceable ones.

The honest shape is a split:

- **A tenant may design its procedure so the AI never touches key material**, and btc-policy
  does: descriptors come from the operator, member keys are generated on the machine, and
  sealing removes the model before anything valuable exists. That is `SEC-T4`, and it is a
  tenant requirement, not a harness guarantee.
- **The harness minimizes and counts.** Deliver secrets redacted, keep them out of model
  context, prefer on-machine generation, prefer sealing — and count whatever remains
  reachable in the blast radius, exactly as an approved untyped scope is counted. That is
  `SEC-6`.

The security claim already said the honest version — "a compromised one owns the machine it
just configured" — so it was the absolutes that stood out of step, not the claim.

## The invariants

These may never be violated. They are product-level and distinct from the ten numbered
invariants in the archived execution-layer specification.

### SEC-1 — a session reaches only its bound set, enforced by a lock

**A session MUST be bound to a set of machines the operator fixed, and MUST NOT read, audit, or
touch any machine outside it. A machine MUST be in at most one live session's set at a time.**
The set is the session's **bound set**
([ADR-0037](./docs/adr/0037-bound-sets.md)).

**One machine is the default and the best practice.** A set of more than one is an acceptable
weaker mode (`SEC-14`), named machine by machine before contact. Two cases are never offered
it, and no operator act sets either aside:

- **Wherever a profile declares any independence bound, each session is bound to exactly one
  machine.** The rule is keyed on the profile's independence-bound slot holding a relation, not
  on a tenant asking for it. It is the harness's form of a rule the tenant states over
  configured models in its own profile, and the two are one rule at two strengths, as `SEC-T3`
  is for vendors.
- **A multi-tenant machine (`ARC-36`) is always bound alone.** Its guests are parties the
  operator has never met, and what another machine of a set returns must not steer root
  commands on their host.

A machine is bound to a session by provisioning it; by re-entry, on a maintained machine only;
or by the recovery ladder's escalation, which re-binds a half-provisioning machine to the
successor session under `ARC-16`'s condition.

**Binding is an operator act in the browser, made before any channel access to that machine.**
The operator names the set, machine by machine, at session creation, and connecting is never
what creates a binding — otherwise a refused session and a re-entering one would be
indistinguishable.

**A set grows by one operator act per machine, and never shrinks while its session lives.** An
addition goes through the mid-flight queue (`ARC-15`) on a card the harness composes: the set as
it will be, what the added machine costs, its first-contact route, and every acceptable weaker
mode standing on the set (`SEC-14`); a mode the added machine needs is accepted on that card. The added machine's entry and its allocation index are
journaled before any create is sent (`STA-22b`). No machine leaves a set while the session is
alive — what the model has read from it stays in the context that commands the rest.

**A bound set is one unit of harm and one model context.** Whatever the model reads on one
machine of a set can steer what it runs on every other, which typing that output as untrusted
(`SEC-8`) does not prevent, and a mistake aimed at one machine can land on another. So the
blast radius, the weaker modes and the placed secrets of a set are stated for the set and never
machine by machine. Machine naming and its resolution against the set are `ARC-7`'s.

**Enforcement is cryptographic, not procedural.** Each **machine** has its own SSH client
keypair, derived at that machine's index (`STA-22`, `SEC-5` row 3), and only that machine's
public key reaches its `authorized_keys`. A session is given exactly the keys of the machines
in its bound set and no other, so a session cannot authenticate to a machine outside its set,
and the refusal comes from SSH rather than from the harness declining to call its own
transport. Two harness flows hold a client key outside any session, and no model drives
either: the jump-host flow (`CHN-R6`), and Replace's key migration (`STA-17`), which holds one
machine's old and new keys while it swaps them and runs nothing else on it. A single shared client key would leave this invariant enforced only by routing code,
which is bookkeeping rather than a boundary.

**The key is the machine's, not the session's, and a binding is exclusive.** Until 2026-09-16
this paragraph said each *session* held its own keypair. That was true of the case it was
written for — a sealed machine is configured by one session and then loses SSH, so one session
is the machine's whole life — and false for a maintained machine, which a later session
re-enters with the same re-derived key (`ARC-27`). SSH cannot tell two sessions apart when they
present one private key, so what SSH enforces is separation between **machines**. Succession on
one machine is the harness worker's: a machine has at most one bound session at a time, and a
new binding — by re-entry, or by the recovery ladder's re-binding to a successor — requires the
predecessor session to have ended, its workers stopped and its channels closed, which is the act
`STA-23` already performs on lock. Two sessions on one machine at once is what this requirement
exists to prevent, and the ledger would only record it after the fact. Once a predecessor has
ended, a later session MAY re-enter any subset of its maintained machines; the machines it
leaves out stay unbound until some session is bound to them.

**That the keypairs derive from one seed does not weaken this.** Derivation is how the browser
*obtains* machine 3's key; what reaches machine 3 is still machine 3's public key alone, and
a session whose set does not hold machine 3 is still refused by SSH. The seed is a root the *browser* holds — one thing to back
up instead of a sheet of keys — not a credential any session or machine ever sees (`STA-22`).

**Post-harness machinery holds no grant of this kind at all** (`ARC-19a`). It runs after every
machine of the setup is delivered, and where the profile seals, a sealed machine has no SSH to
authenticate to. It holds at most the credential the profile's handoff slot declares, which is
never a machine's own key. So no party other than a machine's bound session — or, for a jump
host, which has none, the harness flow that makes the contact (`CHN-R6`), or, while Replace
migrates it, the harness's model-free Replace flow (`STA-17`) — ever holds that machine's
client key, at any moment in the machine's life, and `CNF-8` tests that of
post-harness machinery absolutely rather than after a deadline. A session whose bound set is the
whole setup does hold every key of it — which is why such a set is a weaker mode the operator
chose and sees, and never something a session is handed.

*What this requirement used to say* was that the coordinator held a distinct grant covering
every machine's keypair for the setup window. That described a shape the ordering makes
impossible, and it quietly reintroduced the shared-key condition the paragraph above rejects —
enforcement by routing code rather than by SSH. It is recorded because a reader who assumes the
coordinator must reach inside every member will re-derive it.

Access is what composes, not intent, and it composes two ways. Across a threshold, a model with
a foothold on two machines halves the number of malicious domains needed to reach k-of-n
([ADR-0004](./docs/adr/0004-one-model-one-machine.md)) — the tenant's argument, and the reason
a declared independence bound means one machine per session. Inside one session, a set is one
context, as above. No exception for debugging, for auditing, or for any scheme in which one
model inspects **from inside** a machine outside its set — the scanner's access-free surface
probe is outside this subject, not an exception to it.

**Exposure is permanent for the life of the machine.** A model that has touched a machine
counts as touching it until that machine is destroyed, because ending a session does not
remove whatever the model may already have left behind. A model bound to a set is entered
against every machine of it at binding, together with the set. Tracking is `STA-10`. Where a
profile declares an independence bound, the recovery ladder's middle rung and re-entry stay
inside this rule only while the configured model's **footprint** — every machine it has
touched, and every machine co-bound with those — stays within that bound for the life of those
machines; past that rung the machine is destroyed rather than handed on. Where no bound is
declared, the footprint is counted and shown (`OVR-6`), and neither the rung nor a re-entry is
refused for it.

**What this invariant reaches, and what it does not.** It binds the harness's own channels —
the box-plane channel and typed operations. An approved untyped scope is outside its reach:
if the service behind the scope can itself administer machines, what bounds the session there
is the credential's authority, counted in the blast radius — and where that service is a
vendor, `SEC-4` attaches its own conditions. A **scanner** run is outside this
invariant's subject because it is bound to no machine — and for exactly that reason it MUST
NOT hold any machine credential or channel: addresses in, observations out, nothing else. A
**jump host** (`CHN-R6`) is outside every bound set for a different reason: the flow that
creates and uses it is the harness's own and not a session, and no session is given its key or
its vendor identity.

It does not decide whether two sessions configured with different models are served the
*same weights* — nothing observable tells it (`OPN-4`). Identical weights behind two machines
is therefore a **collision, displayed under `OVR-6`** — not a violation, and not something an
implementation can be required to prevent.

### SEC-2 — nothing is presented as verified

**The product MUST NOT present any claim as verified.** There is no verification layer.
"Verified" and "no anomalies found" are claims this design cannot make. A model-written check
report MUST be labelled **"Checks the AI wrote — not part of Delivered"**, with no tick mark
and no "passed" or "verified" treatment, whatever its output (`ARC-39`).

### SEC-3 — the box plane has no path to the harness's cloud plane

**The box plane MUST NOT have a path to the harness's cloud plane.** A machine never holds a
vendor API token *belonging to the harness* — nor the key of an untyped vendor scope — and work
needing a cloud-plane action returns to the browser, even mid-way through box-plane work.

**What this binds, stated because it was previously absolute and unenforceable:** the
harness's own placements and actions. An **application secret** — a tenant's or an operator's
application's own credential, on its own machine, for its own account — is a different thing:
it is permitted, placed under `SEC-5` row 12, and counted under `SEC-6`. What it is not is a
way for the harness's vendor authority to reach a machine.

### SEC-4 — how cloud-plane actions are approved

**A typed cloud-plane operation MUST be approved on structured facts, never on command text
— and an untyped call MUST NOT be presented as though its scope bounds what the credential
can do.**

**A vendor's control API may reach machines outside the calling session's bound set** —
machines bound to other sessions, delivered machines no session holds, sealed machines nothing
re-enters, and machines of the operator's that the harness has never heard of: the whole
account, unless the operator minted a narrower credential, and the harness cannot see which.
Rescue, console, rebuild and credential minting make that API a door SSH keys do not guard, so
how a session goes through it is ruled here, in two modes
([ADR-0038](./docs/adr/0038-untyped-vendor-scopes.md)).

**Typed, wherever an adapter covers the origin.** A scope MUST NOT name an origin a vendor
adapter covers: an untyped scope at the same API would walk around the check below. There each
operation names its resource and is authorized as the next paragraph says, which closes the
hazard per operation whatever the credential can reach — so one vendor credential MAY serve
several sessions, and none reaches a machine outside its own set. What an adapter can list of
the account is displayed and never relied on: a listing is the vendor's word at one moment, and
the authorization at each dispatch is the enforcement.

**A typed operation that names an existing machine MUST be authorized against the calling
session's binding**, enforced by the adapter rather than left to the approval screen: one
naming a machine outside the calling session's bound set is refused. A session's vendor
operations reach the machines of its own set and account-level creation, nothing else.

**What is dispatched is the approved record.** The adapter executes the structured facts as
they were approved and journaled — the resource (`STA-24`), the arguments, the declared cost
bound, the bundle commit — never a request rebuilt at dispatch from session state or from
arguments the model supplies afterwards. `STA-24` says an approval is checked again at
dispatch; this says what is checked. "There was an approval" and "the approved thing is what
ran" are two different properties, and only the second is worth proving.

**Untyped, at a vendor with no adapter — an acceptable weaker mode (`SEC-14`), under
conditions no operator act sets aside.** A typed adapter is the best practice: used where the
bundle has one, shown as missing where it does not. Without one the session reaches the vendor
through an **untyped vendor scope**, a scope (`ARC-5`) naming that vendor's origin, and each of
these holds:

- **Known-machine exclusivity, checked against the journal.** The scope MUST be refused if any
  undestroyed machine provisioned through that origin, or through that vendor identity, lies
  outside the calling session's bound set; and while the scope stands, no such machine is bound
  to another session.
- **Never under an independence bound.** A session whose profile declares one is given no
  untyped vendor scope.
- **Invoices are read by harness code.** An invoice is decoded by harness code from the
  recorded response, tied to an approved machine entry, and paid by the operator (`ARC-30`).
- **The box plane pauses while a vendor call is open or unresolved** — to the set's machines
  at that vendor (`STA-24`).
- **First contact is through a jump host** (`CHN-R6`).

**What the mode cannot keep out of model context, it shows.** A token the vendor mints and a
root password the vendor generates arrive in a response no adapter reads, so the model reads
them. The scope's card and the trust display say so; `CNF-12` and `CNF-14` are restated for
this mode rather than quietly failed.

**The operator's statement, labelled as theirs.** When the key is supplied, the card the
harness writes asks two questions, once, with nothing preselected:

1. "Are there other servers in this account that you care about?"
2. "Can this account pay for things by itself? (a saved card, a prepaid balance, auto-renew)"

"Not sure" counts as yes. The answers never block. They set the warnings — "may reach every
server in this account", "can spend without asking" — and they are journaled and restated at
every later irreversible act on the set (`SEC-14`).

**The best practice** is a vendor identity derived per set, or a fresh project per set, so that
the credential reaches nothing else by construction. A derived vendor identity cannot be
derived today (`SEC-5` row 22).

Classification has an honest boundary: only an origin an adapter covers can be recognised by
hostname, and the conditions above attach where a session provisions machines through a scope.
A third-party deployment or networking service may well administer machines, the harness
cannot know, and that unknown authority is precisely what the blast-radius statement counts an
active scope as.

### SEC-5 — the credential inventory

**Every credential the harness holds or places MUST appear in the table below, with the
lifetime and disposal it states. Anything not in the table is forbidden.**

This is an enumeration rather than a prohibition with exceptions, and the change is not
cosmetic: the previous form was a ban with a growing exception list, and every entry was
added *after* a review found the rule already being broken. A table cannot be silently
outgrown, because adding a credential means adding a row.

| # | Credential | Origin | Where it lives | Lifetime | What it authorizes | How it dies |
|---|---|---|---|---|---|---|
| 1 | Vendor API credential, used through a typed adapter | Operator | Browser memory only | The sessions it is supplied to, or one deterministic harness flow (`STA-18`, `ARC-21`) | Whatever the vendor grants it, up to full account authority; the adapter authorizes each operation against the calling session's bound set (`SEC-4`), so one credential may serve several sessions | Session or flow ends |
| 2 | Inference **session** key | Minted from row 14 (procured); supplied by the operator (BYO) | Browser memory only | One session | Inference spend, **up to its own cap** | Revoked at session end (procured); session ends (BYO) |
| 3 | **SSH client private key, one per machine** | **Derived** from row 15 at that machine's index (`STA-22`) | Re-derived on demand; nothing to export. Given to the machine's bound session and no other; a jump host's, at the jump host's own index, is given to no session (`CHN-R6`); during Replace, the machine's old and new keys are held by the harness's model-free Replace flow and given to no session (`STA-17`) | Machine lifetime | Login to **that one machine** | Removed from the machine on Replace (`STA-17`), which is a new seed; a jump host's dies with the jump host |
| 4 | **Relay key**, one per pass | Derived from row 15 (`STA-22`); its public half is what the relay binds a bought pass to (`CHN-15`), and what the first stage hands the publisher out of band | Re-derived on demand; nothing to store | Until the pass expires or is revoked | Reaching the destinations recorded against its pass, on any port; recording destinations; revoking (`CHN-16`) | Pass expires or replacement is confirmed under `STA-17`, by signed revocation or stage 1's manual retirement |
| 5 | Host-key pins | Vendor API, rescue, attest, or a first contact from a jump host (`CHN-R6`), recorded with which | Encrypted at rest; exported in the sheet | Installed system: machine lifetime. Rescue: one boot (`CHN-R1`). A jump host's: one first contact | Nothing — integrity reference | Machine destroyed; rescue pin discarded at the reset; a jump host's pin discarded with the jump host, the route label (`CHN-R6`) being what the display keeps |
| 6 | Exposure ledger | Harness-derived | Encrypted at rest; exported in the sheet | Machine lifetime | Nothing — record | Machine destroyed |
| 7 | **Attest sender key**, one per machine — a jump host pinned by attest included, at its own index | Derived from row 15 (`STA-22`) | Boot user-data; **never stored in the browser**, re-derived to check the seal | Until the browser accepts one introduction, or its window closes | **One** host-key introduction (`CHN-7`) | **The browser stops listening (`CHN-5`)** — that is the bound; scrubbed from disk as defence in depth (`CHN-6`); the metadata copy is permanent and worthless |
| 8 | ~~Drop-box collection token~~ | — | — | — | — | **Row retired.** The drop-box is gone (`CHN-4`); the attest post is a gift-wrapped event to an inbox any Nostr relay provides. |
| 9 | Rescue root password, in a typed adapter's response | Vendor-generated, in an API response | Never stored | Never used | Root login the harness declines to use | **Redacted before the response is recorded or reaches a model.** Under an untyped vendor scope no adapter reads the response, so a vendor-generated password is outside this row and inside model context, and is shown as that (`SEC-4`) |
| 10 | Recovery sheet passphrase | Operator-chosen | Never stored anywhere | Operator's memory | Unwraps the sheet | Not applicable |
| 11 | Untyped-scope credential — a vendor's included, under `SEC-4`'s untyped vendor scope | Operator | Browser memory only | Until the operator revokes or rotates it | **Unbounded at that origin** | Operator revokes at the service |
| 12 | **Application secret placed on a machine** | Operator, on `place_secret`'s card (`ARC-43`) | Browser memory until the placing session ends, then the machine alone; briefly in the local paste re-arm card (`ARC-43`), cleared after reference construction and never persisted or sent | Machine lifetime | Whatever the application it was placed for uses it for | Machine destroyed, or operator rotates |
| 13 | ~~Injected SSH host private key~~ | — | — | — | — | **Row retired. `CHN-R3` is abandoned**: user-data stays readable from the vendor's metadata endpoint for the instance's life, so the key would be permanently re-fetchable by anything on the machine. No exception wording fixes that. |
| 14 | **Inference account credential** (procured only) | Operator, on funding an account-free balance | Encrypted at rest; **exported in the sheet** | Until the balance is spent | The remaining balance; minting and revoking row 2; attaching a funding source (`ARC-31a`) | Spent down or abandoned — **it is bearer and cannot be revoked** |
| 15 | **Operator seed** | Operator, at first use; backed up by the operator | Encrypted at rest; **in the operator's head or seed backup**, never in the sheet | Until replaced | Deriving rows 3, 4, 7, 16 and 17 — **every maintained machine, every relay pass, every future introduction, and every declared handoff** (`STA-22`) | Replaced by a new seed on Replace (`STA-17`); the old one is not revocable, only abandoned — and it is still needed *during* Replace |
| 16 | **Attest recipient key**, one per machine — a jump host pinned by attest included, at its own index | Derived from row 15 (`STA-22`) | Re-derived on demand; public half in boot user-data | Until the introduction is accepted or the window closes | Decrypting **one** machine's introduction, and authenticating the inbox subscription that receives it (NIP-42, `CHN-18`) | The browser stops listening; the key is never used again |
| 17 | **Post-harness credential** (profiles declaring a handoff credential) | Derived from row 15 (`STA-22`); public half installed only on the machines the profile's handoff slot declares, during setup, before the handoff point (`ARC-19a`) | Re-derived on demand; nothing stored | As declared by the profile's handoff slot | Exactly the reach the profile's handoff slot declares, and no more — btc-policy's instance is the coordinator peer credential | As declared by the profile's handoff slot |
| 18 | Local unlock passphrase | Operator-chosen (`STA-23`) | Input UI briefly, then harness-worker memory; never persisted or sent | Unlock or passphrase-change operation | Derives row 19 to unwrap the local data key | Input and buffers cleared after use |
| 19 | Wrapping key (local store or sheet) | PBKDF2 from row 18 or row 10, with independent salts and purposes | Harness-worker memory only | Wrap/unwrap operation | Unwraps one row-20 key | Cleared after wrap/unwrap |
| 20 | Data-encryption key (local store or sheet) | Browser CSPRNG, independent per store/export | Harness-worker memory; only an authenticated wrapped copy persists | Local store unlocked; sheet import/export operation | Decrypts the named local store or sheet, never another purpose | Cleared on lock/end; replaced on re-encryption |
| 21 | **Jump-vendor credential**: a vendor credential supplied separately from the target's (`CHN-R6`) | Operator | Browser memory only, held by the jump-host flow; never given to a session | One jump-host flow, from the create to the confirmed destroy | Creating one jump host, reading its address and destroying it, through the jump vendor's adapter | Flow ends |
| 22 | **Derived vendor identity** — not derivable today | — | — | — | — | No role exists for it. `STA-22` says "an implementation must not choose paths independently", and credential format v1 (`STA-22a`) defines no role, index family or known-answer vector for a vendor identity; until it does, none is derived or used (`OPN-26`) |
| 23 | **Placed-secret scan key and reference**, per secret | Fresh independent browser-CSPRNG key `K` on placement or re-arm; reference `HMAC-SHA-256(K, SHA-256(value))` plus byte length `L` | Encrypted local store under `STA-23`; working copy only in browser memory. Neither key nor reference goes to the machine, sheet, model, transcript or app origin | Until rotation, machine destruction or local-store loss; re-arm replaces it with a fresh key/reference | Local exact-value comparison only; no external authority | Cleared from working memory on lock, page hide, worker shutdown or session end; persistent copy removed on rotation/destruction, lost with the store |

Rows 18–20 use the versioned envelope in `STA-23`. Row 15 derives row 17 as well as the
machine and relay credentials. Derivation indices, resource mappings and allocator counters
are encrypted recoverable metadata (`STA-22b`); a seed alone cannot discover them. A restored
seed is barred from new allocations until Replace. Losing an old seed or metadata prevents
direct Replace but does not remove Robot's vendor-authenticated rescue route (`STA-17`).

**Row 12 carries a caveat that MUST be stated wherever it is offered.** `place_secret`
(`ARC-43`) keeps the secret out of the transcript and out of model context *on the way in*. It
does not keep it from a model that later reads the machine's filesystem with the root shell
`OVR-2` grants, nor from one that touched the machine earlier and left something behind. An
application secret on a machine is therefore permanently inside the reach of every model that
has touched or will touch that machine, and is counted under `SEC-6`. Anything else would be
the overstatement this design refuses everywhere else.

**Exact copies of a placed secret whose reference the browser holds are redacted from box-plane
output before that output reaches the model or the transcript, and the claim is no wider than
that.** During placement
the scan may compare the entered value in browser memory. Later it MUST compare
`HMAC-SHA-256(K, SHA-256(window))` against row 23's reference, over raw-byte windows of length
`L`, including windows crossing output chunks, before decoding or release to either sink.
Unscanned bytes MUST be withheld; matches become visible redaction markers naming the secret,
never silent omissions. The browser retains only the scan key, keyed reference and byte length
after the value is cleared; neither a bare hash nor the value persists there. A minimum byte length is
required at placement and every re-arm, with the numeric bound still open in T48; no arbitrary number
is implied by this construction. Placement and recovery arming are `ARC-43`'s procedures.

The scan sees exact values only: an encoded, partial or transformed copy passes. It covers
only placements whose reference the browser holds — none known only as "unknown since export"
(`STA-16`) — and a reference re-armed from a machine report covers the bytes the machine
reported, which may not be the value placed (`ARC-43`). It runs in
the browser — `STA-20a`'s output file lands on the machine before any browser scan runs — so
it is a statement about the harness's records and the model's context, never about what the
machine holds. The root-shell caveat on row 12 remains, including plaintext machine output.
[ADR-0041](./docs/adr/0041-secret-scan-rearms-from-machine-reports.md) records the choice and
its residual trust in the machine's current report.

**Rows 3, 7 and 16 cover a jump host's keys, and row 21 its vendor credential.** A jump host
(`CHN-R6`) is allocated its own index in the machine family, an index that is never an entry
of any session's bound set, and its keys are the ones those rows name at that index — rows 7
and 16 only where it is pinned by attest. Row 21
is what keeps the jump vendor's identity separate from the target's until row 22 can be
derived: a separately supplied credential, held by a harness flow no session holds.

**Rows 1, 2, 11 and 21 never reach storage.** Rows 1, 2 and 11 are re-supplied by the operator
each session, deliberately, which is why they appear in `STA-14`'s "dies with the phone" column;
row 21 is given to no session, and is supplied for each jump-host flow. Row 2 is the
one that changed shape: on the procured path it is no longer something the operator retypes but
something the harness **mints, caps, and revokes**, which is why its lifetime is now enforced
rather than asserted.

**Row 14 is an unrevocable service credential, and it holds money.** It
is a bearer value: whoever has it can spend the balance and mint keys against it. That is why
row 2 exists at all — a session gets a capped, expiring derivative rather than the thing itself
— and why `STA-17`'s Replace flow cannot treat it like row 4. Relay replacement follows
`STA-17`, including its manual stage-1 case; a stolen account credential can only be raced to the
bottom of its balance.
The bound is what the operator chose to fund.

A secret a service returns inside an untyped response is outside the harness's sight and
outside this table's reach; the moment such a secret is supplied *to* the harness as a
credential, it is covered. **One redaction is enforceable and mandatory**: every untyped
response is scanned for the harness's own held credentials before it reaches the model or the
record, because a service can echo the key it was sent. The scan sees exact values only.

### SEC-6 — minimize what the model can reach, and count the rest

**The harness MUST minimize what a model can reach and MUST count what remains in the blast
radius.** Minimizing means: deliver secrets redacted, keep them out of model context, prefer
generating on the machine over delivering, and prefer sealing where the tenant allows it.
Counting means: an application secret on a machine (`SEC-5` row 12) and an approved untyped
scope (row 11) both widen a model's reach beyond its bound set, and both appear in the
blast-radius statement and the trust display for as long as they are live. Every acceptable
weaker mode standing on a set (`SEC-14`) is counted and shown the same way, for the set.

This replaces an absolute the root shell already defeated. A tenant that needs the absolute
supplies it by procedure — `SEC-T4`.

### SEC-7 — briefs and feeds ship signed

**Briefs and advisory feed lists MUST ship in the signed bundle** and MUST NOT be fetched,
configured, or substituted at runtime. What *signed bundle* means today is defined once, in the
glossary: until `OPN-15` closes, compiled into the build the origin serves, with no signature
checked at runtime. Every use of the phrase in this corpus inherits that definition; `ARC-40`'s
"signs" is the same statement.

### SEC-8 — external content is untrusted

**All tool output and fetched external content MUST be typed as untrusted** and MUST NOT
authorize an action on its own, declare capabilities, or override policy.

### SEC-9 — counts are shown per layer

**Trust counts MUST be shown per layer and MUST NOT be blended into a single score** — and
the provider layer MUST be labelled **requested**, never *observed* or *verified*: it is what
the harness asked the aggregator for, and the aggregator documents that for some models it may
override.

**A count MUST NOT be derived from something it does not measure.** The provider layer used to
be *observed* and had no source on the chosen aggregator; deriving it from the model name would
have produced a figure labelled *observed* that was read off the request. It is now *requested*,
which is a count of what was sent — and that label is the whole of its honesty. Should a
response ever carry the served provider, an *observed* count may sit beside the requested one;
until then there is one column, and it says what it is.

**A response's own report of the provider is compared, never shown as a count.** The aggregator
answers a provider selection with a *reported provider*, its own word about itself
(`CONTEXT.md`). The harness MUST compare it with the requested provider and MUST record it in
the call's terminal record (`ARC-31a`). The two are spelled differently — the request carries a
slug, the report a display name, `z-ai` against `Z.AI` — so until the aggregator publishes the
mapping `OPN-23` asks for and the bundle carries it, equality is by both names folded to lower
case with punctuation removed. A match displays nothing and proves nothing. A mismatch MUST be
surfaced on that machine as *requested X; the proxy reported Y* — the report's provenance kept in
the words, because it is the proxy saying it did not honour the request, and nothing more. A
selection whose response carries no report, or a report that, folded the same way, matches
neither the requested provider nor any other provider the bundle names, MUST be surfaced as
*unrecognized*. No column is derived from any of it. If the report
merely echoes the request the detector never fires, which is why the *observed* column above
stays a *may* and `OPN-23`'s ask stands. A provider is requested per session (`ARC-14`), so
"that machine" in this requirement is each machine of the session's bound set.

**When the requested provider is the maker of the weights, the display MUST say so on that
machine.** The maker is a fact the bundle records beside the model, never parsed from the
model's name (`CNF-41`). The counts are unchanged — `ARC-14` lists the layers — but the
requested provider and the maker are then one party, and the operator is told rather than left
to recognise the name.

### SEC-10 — the trusted list does not grow silently

**The trusted-party list MUST NOT grow silently.** Any feature adding a party to it is a
change of the same weight as a schema migration. The certificate authorities a WASM TLS
client would bundle (`CHN-12`) are such a growth, which is one reason that capability is
unbuilt.

### SEC-11 — the host key is checked

**An SSH session MUST check the host key against the stored fingerprint, and a key that does
not match MUST halt the session.** Through the relay no moment is exempt: a first contact with
no stored fingerprint is refused there (`CHN-R4`). Exactly one first contact is made with
nothing to check the presented key against — the one from a jump host, inside a pinned outer
session (`CHN-R6`) — and that contact is trusted, not checked against a pin, and MUST be
presented to the operator as such. No other path may accept a key no pin was stored for.

On the dedicated path and attest (`CHN-R5`), where a fingerprint is stored before contact,
the check is `TauWeb.Pins.check` (ADR-0032). Attest admission includes author matching and
durable single use under the companion's stated assumptions (`ARC-43`, `CHN-5`). The jump-host
contact above remains outside it (T45); `check` has
no branch that admits a handshake with no pin. Its halts are three and not one: nothing stored to check against, the key that does not
match, and the halt `STA-20b`'s resume rule explains.
`TauWeb.Pins.mismatch_not_the_reset` is that the last two are never the same answer.

### SEC-12 — every off-machine call is recorded before it is sent

**Every off-machine call made with an operator credential MUST be recorded before it is
sent.** For a typed operation this is bookkeeping. For an untyped call it is the *only*
safeguard standing behind it, since the harness cannot bound what the credential authorizes.
For an inference request — the adapter's own call under the row-2 key — the record is an
intent with a local call id, then a terminal record of metadata, never the prompt body
(`ARC-31a`).

A call interrupted between the record and a confirmed response has an **unknown outcome**,
and for an untyped call no adapter exists to find out. So the record MUST carry that
unresolved state, the harness MUST NOT retry the call on its own or report it as failed, and
reconciliation belongs to the operator, at the service. `STA-8` is the same rule at the state
layer, and `STA-24` says what the unresolved state blocks: for an untyped call, every further
call under that scope until the operator disposes. Under an untyped vendor scope the record is
also what the money rule reads: `SEC-4` says "An invoice is decoded by harness code from the
recorded response".

The CORS sent-but-unreadable case is engineered away: an origin's route is chosen by a
dedicated harmless probe before any side-effecting call exists, every untyped call carries a
custom header so no simple request exists, and a real call's failure never selects a new
route. Should an unreadable response occur anyway, it is the same unknown outcome.

### SEC-13 — the app holds no funds

**The app MUST NOT hold, forward, or custody funds.** A Bitcoin wallet able to pay for
machines is an intended future capability and it collides with this, so the collision is
recorded rather than resolved (`OPN-17`). Handing a machine's invoice to the operator's own
wallet (`ARC-30`) is not that capability: the app relays and holds nothing.

### SEC-14 — a weaker mode is accepted by name, before contact, and never entered by failing

**A weaker mode MUST be one of the named ones, accepted by the operator by its label for one
bound set before the first contact it governs. It MUST NOT be entered because a
stronger check failed, and it MUST be restated at every later irreversible act on any machine
of the set**
([ADR-0035](./docs/adr/0035-non-waivable-rules-and-acceptable-weaker-modes.md)).

The **acceptable weaker modes** are these and no others, each beside the **best practice** it
stands in for — which is used when available and shown when missing:

| Acceptable weaker mode | Best practice it stands in for | Owner |
|---|---|---|
| An installation with no artifact pin | A pinned distribution | `ARC-25` |
| A first contact from a jump host | A host key pinned out of band by retrieve or attest | `CHN-R6` |
| Acting on a goal with no brief | A brief | `ARC-11a` |
| A bound set of more than one machine | A set of one | `SEC-1` |
| An untyped scope at a vendor with no adapter | A typed adapter | `SEC-4` |

Every mode but the untyped vendor scope is on the list because its harm stays inside that
bound set, shows when it
happens, and cannot be multiplied by a model retrying on its own. The untyped vendor scope
passes those tests only in part: it can reach whatever the vendor account reaches, and an
account that pays by itself can spend without asking. Its harm stays on the operator's own
account rather than inside the set. `SEC-4` says the untyped vendor scope stands "under conditions no operator act sets
aside", and the operator's two
answers, journaled and restated as warnings, disclose that reach rather than bound it
(ADR-0038).
Every item `07-conformance.md`'s tiering rule makes BLOCKING is a **non-waivable rule**, which
no label, no answer and no operator act sets aside.

- **By its label, for one bound set.** The set is named machine by machine before contact. A
  mode accepted for one set says nothing about another — a machine's own history aside, below —
  and a machine added to a set later is added on a card that restates the set's modes (`SEC-1`).
- **Across sessions, restatement follows the machine and acceptance follows the act.** A mode
  is accepted by the session that does what it governs, before doing it. An installation with no
  artifact pin and a first contact from a jump host are the machine's history: every later set
  that includes the machine is shown them at binding and restates them, and accepts them again
  only for a reinstall, which is a new installation and a new first contact (`CHN-R6`). Each
  session that acts on a goal with no brief, approves an untyped vendor scope or binds more than
  one machine accepts that mode itself, on a card it already shows: a larger set at binding,
  before any channel access, naming the history modes its machines bring into it (`SEC-1`); no
  brief with its goal, before the model acts on it (`ARC-11a`); an untyped vendor scope on its
  card, before the first call through it (`ARC-15`). A session that does none of these accepts
  none, and a session resumed after an interruption (`STG-12`) accepts nothing again. What an
  earlier session's mode left live — a vendor credential or minted token not yet revoked, a
  co-bound footprint — is restated with the history modes and never accepted again (`SEC-6`,
  `STA-10`).
- **Chosen before contact.** The operator chooses a mode from what the bundle or the vendor
  lacks — no pin for this distribution, no adapter for this vendor, no out-of-band route at
  this vendor, no brief for this software — or from what the set needs, more than one
  machine — before the first contact it governs: with any machine of the set for a mode
  accepted as the set is bound, with the added machine for one accepted as the set grows
  (`SEC-1`).
- **Never entered by failing.** A failed check halts. An artifact that does not match its pin,
  an introduction that never arrives, a host key that does not match: none of them continues
  in the weaker mode (`ARC-25`, `CHN-R5`, `SEC-11`).
- **Restated at every later irreversible act** on any machine of the set — placing an
  application secret (`ARC-43`), paying an invoice, a destroy or a reinstall, adding a machine
  among them — together with every other mode standing on the set, because acceptances do not
  compose silently.
- **Recorded and shown.** Each mode is journaled with the set and appears in the trust display
  for as long as it stands (`SEC-6`).

## Supplied by btc-policy, not by the harness

These bind wherever a tenant requires them and mean nothing otherwise, so under
[ADR-0016](./docs/adr/0016-the-harness-isolates-and-counts-tenants-set-thresholds.md) they
belong to that tenant and live with it.

**SEC-T1**, **SEC-T2**, **SEC-T3** and **SEC-T4** Moved to the btc-policy tenant profile,
[`docs/tenants/btc-policy/profile.md`](./docs/tenants/btc-policy/profile.md), slots
"Delivery declaration", "Machine set", "Independence bound" and "Secrets and parties"
(ADR-0030). The identifiers are kept so existing references resolve.

## SEC-CLAIM — the security claim, stated exactly

The harness and its tenants make **different** claims, and blurring them is how a single
machine ends up shipping under a vault's guarantee.

**What the harness claims.** No session reaches a machine outside its bound set **through
anything the harness controls** — each machine bound by provisioning it, by re-entry on a
maintained machine, or by the recovery ladder's escalation. A model's blast radius is:

- the machines its weights have touched — every machine of every set it was bound to — **plus**
- any credential authority standing approved for its session as an untyped scope, at that
  origin, which may itself reach machines the harness cannot see — a vendor's account under an
  untyped vendor scope included — **plus**
- any application secret placed on a machine it is bound to, which its root shell can read.

Those three are stated together because no one of them alone is the boundary. Every approved
scope and every placed application secret appears in the trust display until revoked or
rotated — closing an approval does not un-trust a service that still holds the key. Every
acceptable weaker mode standing on a set is stated with them (`SEC-14`); for a machine first
contacted from a jump host that statement is that its identity is as good as two paths
agreeing once (`CHN-R6`).

**The claim covers the harness's own AI and nothing else that thinks.** An operator's
application that acts on its own (`ARC-1a`) is outside it, and its machine's delivery card says
so.

The trusted set is named rather than small, and the tier this product adds is fixed. What the
harness *removes* is the party that would otherwise choose the operator's vendor, model and
configuration while holding their credentials.

**What the harness does not claim, and cannot: that the model is honest.** With one machine
there is no threshold, so nothing absorbs a malicious model — a compromised one owns the
machine it just configured, and no mechanism here notices. The pentest is a competence check
by its own definition and a deterministic verifier reads what the machine chooses to tell it,
so neither closes this. Ad hoc use ships under the smaller claim rather than borrowing a
larger one.

**What btc-policy stacks on top:**

> **No single model provisioned enough members to reach the threshold.**

That claim needs a vault. It is conditional on the trust domains being genuinely distinct: if
several endpoints serve the same weights the operator has one model rather than five and it is
vacuous. What is enforced is that a configured model's footprint stays within the profile's
independence bound (`SEC-1`, `SEC-T5`), and it is the **configured** weights that are counted;
whether the proxy served the weights it was asked for is not observable, and that
residue is `TRU-E2`'s trust rather than a property this claim can check (`OPN-4`). Until a
served-model signal exists, this is a design goal rather than a demonstrated property.

**There is no verification layer and nothing in the product may imply one.** Every scheme
where a second model inspects a finished machine **from inside** hands that model a second
foothold — the scanner never does; it reads only the public surface. A deterministic verifier
reads whatever the machine chooses to tell it and cannot beat a hostile AI; it survives only
for drift detection and honest mistakes inside a single machine, run by that machine's own
session — or by the harness's own AI-free code over that same session's channel during setup,
which is a different runner rather than a different reach (`ARC-26`: anything needing the
channel belongs to the machine's own session; it is not post-harness machinery, which holds no
channel at all under `ARC-19a`).

**Honest mistakes ship silently.** On a first-time setup a misconfiguration is the likely
failure, not a hostile model, and no mechanism here catches one made the same way by
everybody. The threshold protects funds; it does not protect against uniform sloppiness.

An **action transcript** is a browser-side record of what one session actually did, captured
before transmission. It is **not** evidence about a machine, because no second model may
inspect it against that machine. A **provenance record** — the claim that a machine was
provisioned by a specific vendor, configured model and **requested** provider — it once claimed
the *set* of providers *observed* serving it, which has no source on the chosen aggregator — is durable, and in the first version a local claim rather than evidence.
