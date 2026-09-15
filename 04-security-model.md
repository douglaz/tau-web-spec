# 04 — The security model

## The posture, stated before the rules

**The AI is a trusted party by default.** It is the operator's agent. It holds a root shell
on the machine it is bound to, it can read what is on that machine, and that is ordinary —
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

### SEC-1 — one session, one machine, enforced by a lock

**A session MUST be bound to exactly one machine and MUST NOT read, audit, or touch any
machine it is not bound to.**

A session is bound by provisioning a machine; by re-entry, on a maintained machine only; or
by the recovery ladder's escalation, which re-binds a half-provisioning machine to the
successor session under `ARC-16`'s condition.

**Binding is an operator act in the browser, made before any channel access.** The operator
assigns the machine at session creation, and connecting is never what creates the binding —
otherwise a refused session and a re-entering one would be indistinguishable.

**Enforcement is cryptographic, not procedural.** Each session has **its own SSH client
keypair**, and only that session's public key reaches that machine's `authorized_keys`. A
session cannot authenticate to a machine it is not bound to, and the refusal comes from SSH
rather than from the harness declining to call its own transport. A single shared client key
would leave this invariant enforced only by routing code, which is bookkeeping rather than a
boundary.

**That the keypairs derive from one seed does not weaken this.** Derivation is how the browser
*obtains* machine 3's key; what reaches machine 3 is still machine 3's public key alone, and
session 2 is still refused by SSH. The seed is a root the *browser* holds — one thing to back
up instead of a sheet of keys — not a credential any session or machine ever sees (`STA-22`).

**Post-harness machinery holds no grant of this kind at all** (`ARC-19a`). It runs after every
machine of the setup is delivered, and where the profile seals, a sealed machine has no SSH to
authenticate to. It holds at most the credential the profile's handoff slot declares, which is
never a machine's own key. So this requirement has **no exception window**: there is no moment
in a machine's life when some party holds every machine's client key, and `CNF-8` tests that
absolutely rather than after a deadline.

*What this requirement used to say* was that the coordinator held a distinct grant covering
every machine's keypair for the setup window. That described a shape the ordering makes
impossible, and it quietly reintroduced the shared-key condition the paragraph above rejects —
enforcement by routing code rather than by SSH. It is recorded because a reader who assumes the
coordinator must reach inside every member will re-derive it.

Access is what composes, not intent: a model with a foothold on two machines halves the
number of malicious domains needed to reach k-of-n
([ADR-0004](./docs/adr/0004-one-model-one-machine.md)). No exception for debugging, for
auditing, or for any scheme in which one model inspects another's machine **from inside** —
the scanner's access-free surface probe is outside this subject, not an exception to it.

**Exposure is permanent for the life of the machine.** A model that has touched a machine
counts as touching it until that machine is destroyed, because ending a session does not
remove whatever the model may already have left behind. Tracking is `STA-10`. So the
recovery ladder's middle rung stays inside this rule only while the stronger configured
model is not assigned — and will never be assigned — to any other machine; past that rung the
machine is destroyed rather than handed on. **Re-entry stays inside this rule the same way.**

**What this invariant reaches, and what it does not.** It binds the harness's own channels —
the box-plane channel and typed operations. An approved untyped scope is outside its reach:
if the service behind the scope can itself administer machines, what bounds the session there
is the credential's authority, counted in the blast radius. A **scanner** run is outside this
invariant's subject because it is bound to no machine — and for exactly that reason it MUST
NOT hold any machine credential or channel: addresses in, observations out, nothing else.

It does not decide whether two sessions configured with different models are served the
*same weights* — nothing observable tells it (`OPN-4`). Identical weights behind two machines
is therefore a **collision, displayed under `OVR-6`** — not a violation, and not something an
implementation can be required to prevent.

### SEC-2 — nothing is presented as verified

**The product MUST NOT present any claim as verified.** There is no verification layer.
"Verified" and "no anomalies found" are claims this design cannot make.

### SEC-3 — the box plane has no path to the harness's cloud plane

**The box plane MUST NOT have a path to the harness's cloud plane.** A machine never holds a
vendor API token *belonging to the harness*, and work needing a cloud-plane action returns to
the browser, even mid-way through box-plane work.

**What this binds, stated because it was previously absolute and unenforceable:** the
harness's own placements and actions. A tenant's own credential, on the tenant's own machine, for the
tenant's own account, is a different thing — it is permitted, delivered under `SEC-5`, and
counted under `SEC-6`. What it is not is a way for the harness's vendor authority to reach a
machine.

### SEC-4 — how cloud-plane actions are approved

**A typed cloud-plane operation MUST be approved on structured facts, never on command text
— and an untyped call MUST NOT be presented as though its scope bounds what the credential
can do.**

**A scope MUST NOT name a vendor the harness knows.** A vendor control API reaches every
machine on the account — machines other sessions are bound to — and with no adapter the
harness cannot see which resource a call touches, so an untyped scope there is a path around
`SEC-1` that nothing records at the machine level. Vendor APIs are typed operations or
nothing.

**A typed operation that names an existing machine MUST be authorized against the calling
session's binding**, enforced by the adapter rather than left to the approval screen. A
session's vendor operations reach its own machine and account-level creation, nothing else.

The refusal has an honest boundary: only *known vendors* can be classified by hostname. A
third-party deployment or networking service may well administer machines, the harness cannot
know, and that unknown authority is precisely what the blast-radius statement counts an active
scope as.

### SEC-5 — the credential inventory

**Every credential the harness holds or places MUST appear in the table below, with the
lifetime and disposal it states. Anything not in the table is forbidden.**

This is an enumeration rather than a prohibition with exceptions, and the change is not
cosmetic: the previous form was a ban with a growing exception list, and every entry was
added *after* a review found the rule already being broken. A table cannot be silently
outgrown, because adding a credential means adding a row.

| # | Credential | Origin | Where it lives | Lifetime | What it authorizes | How it dies |
|---|---|---|---|---|---|---|
| 1 | Vendor API credential | Operator | Browser memory only | One session, or one deterministic recovery flow (`STA-18`) | Full account authority at that vendor | Session or flow ends |
| 2 | Inference **session** key | Minted from row 14 (procured); supplied by the operator (BYO) | Browser memory only | One session | Inference spend, **up to its own cap** | Revoked at session end (procured); session ends (BYO) |
| 3 | **SSH client private key, one per machine** | **Derived** from row 15 at that machine's index (`STA-22`) | Re-derived on demand; nothing to export | Machine lifetime | Login to **that one machine** | Removed from the machine on Replace (`STA-17`), which is a new seed |
| 4 | **Relay key**, one per pass | Derived from row 15 (`STA-22`); its public half is what the relay binds a bought pass to (`CHN-15`), and what the first stage hands the publisher out of band | Re-derived on demand; nothing to store | Until the pass expires or is revoked | Reaching the destinations recorded against its pass, on any port; recording destinations; revoking (`CHN-16`) | Pass expires; revoked by its own signature on Replace, and a new key bound to a new purchase |
| 5 | Host-key pins | Vendor API, rescue, or attest | Encrypted at rest; exported in the sheet | Installed system: machine lifetime. Rescue: one boot (`CHN-R1`) | Nothing — integrity reference | Machine destroyed; rescue pin discarded at the reset |
| 6 | Exposure ledger | Harness-derived | Encrypted at rest; exported in the sheet | Machine lifetime | Nothing — record | Machine destroyed |
| 7 | **Attest sender key**, one per machine | Derived from row 15 (`STA-22`) | Boot user-data; **never stored in the browser**, re-derived to check the seal | Until the browser accepts one introduction, or its window closes | **One** host-key introduction (`CHN-7`) | **The browser stops listening (`CHN-5`)** — that is the bound; scrubbed from disk as defence in depth (`CHN-6`); the metadata copy is permanent and worthless |
| 8 | ~~Drop-box collection token~~ | — | — | — | — | **Row retired.** The drop-box is gone (`CHN-4`); the attest post is a gift-wrapped event to an inbox any Nostr relay provides. |
| 9 | Rescue root password | Vendor-generated, in an API response | Never stored | Never used | Root login the harness declines to use | **Redacted before the response is recorded or reaches a model** |
| 10 | Recovery sheet passphrase | Operator-chosen | Never stored anywhere | Operator's memory | Unwraps the sheet | Not applicable |
| 11 | Untyped-scope credential | Operator | Browser memory only | Until the operator revokes or rotates it | **Unbounded at that origin** | Operator revokes at the service |
| 12 | **Tenant secret placed on a machine** | Operator | Browser memory, then the machine | Machine lifetime | Whatever the tenant's software uses it for | Machine destroyed, or operator rotates |
| 13 | ~~Injected SSH host private key~~ | — | — | — | — | **Row retired. `CHN-R3` is abandoned**: user-data stays readable from the vendor's metadata endpoint for the instance's life, so the key would be permanently re-fetchable by anything on the machine. No exception wording fixes that. |
| 14 | **Inference account credential** (procured only) | Operator, on funding an account-free balance | Encrypted at rest; **exported in the sheet** | Until the balance is spent | The remaining balance; minting and revoking row 2; attaching a funding source (`ARC-31a`) | Spent down or abandoned — **it is bearer and cannot be revoked** |
| 15 | **Operator seed** | Operator, at first use; backed up by the operator | Encrypted at rest; **in the operator's head or seed backup**, never in the sheet | Until replaced | Deriving rows 3, 4, 7, 16 and 17 — **every maintained machine, every relay pass, every future introduction, and every declared handoff** (`STA-22`) | Replaced by a new seed on Replace (`STA-17`); the old one is not revocable, only abandoned — and it is still needed *during* Replace |
| 16 | **Attest recipient key**, one per machine | Derived from row 15 (`STA-22`) | Re-derived on demand; public half in boot user-data | Until the introduction is accepted or the window closes | Decrypting **one** machine's introduction, and authenticating the inbox subscription that receives it (NIP-42, `CHN-18`) | The browser stops listening; the key is never used again |
| 17 | **Post-harness credential** (profiles declaring a handoff credential) | Derived from row 15 (`STA-22`); public half installed only on the machines the profile's handoff slot declares, during setup, before the handoff point (`ARC-19a`) | Re-derived on demand; nothing stored | As declared by the profile's handoff slot | Exactly the reach the profile's handoff slot declares, and no more — btc-policy's instance is the coordinator peer credential | As declared by the profile's handoff slot |
| 18 | Local unlock passphrase | Operator-chosen (`STA-23`) | Input UI briefly, then harness-worker memory; never persisted or sent | Unlock or passphrase-change operation | Derives row 19 to unwrap the local data key | Input and buffers cleared after use |
| 19 | Wrapping key (local store or sheet) | PBKDF2 from row 18 or row 10, with independent salts and purposes | Harness-worker memory only | Wrap/unwrap operation | Unwraps one row-20 key | Cleared after wrap/unwrap |
| 20 | Data-encryption key (local store or sheet) | Browser CSPRNG, independent per store/export | Harness-worker memory; only an authenticated wrapped copy persists | Local store unlocked; sheet import/export operation | Decrypts the named local store or sheet, never another purpose | Cleared on lock/end; replaced on re-encryption |

Rows 18–20 use the versioned envelope in `STA-23`. Row 15 derives row 17 as well as the
machine and relay credentials. Derivation indices, resource mappings and allocator counters
are encrypted recoverable metadata (`STA-22b`); a seed alone cannot discover them. A restored
seed is barred from new allocations until Replace. Losing an old seed or metadata prevents
direct Replace but does not remove Robot's vendor-authenticated rescue route (`STA-17`).

**Row 12 carries a caveat that MUST be stated wherever it is offered.** Delivery redaction
keeps the secret out of the transcript and out of model context *on the way in*. It does not
keep it from a model that later reads the machine's filesystem with the root shell `OVR-2`
grants. A tenant secret on a machine is therefore permanently inside that model's reach and
is counted under `SEC-6`. Anything else would be the overstatement this design refuses
everywhere else.

**Rows 1, 2 and 11 never reach storage.** They are re-supplied by the operator each session,
deliberately, which is why they appear in `STA-14`'s "dies with the phone" column. Row 2 is the
one that changed shape: on the procured path it is no longer something the operator retypes but
something the harness **mints, caps, and revokes**, which is why its lifetime is now enforced
rather than asserted.

**Row 14 is an unrevocable service credential, and it holds money.** It
is a bearer value: whoever has it can spend the balance and mint keys against it. That is why
row 2 exists at all — a session gets a capped, expiring derivative rather than the thing itself
— and why `STA-17`'s Replace flow cannot treat it like row 4. A relay pass is revoked by its
key's own signature and a new one bought; a stolen account credential can only be raced to the
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
Counting means: a tenant secret on a machine (`SEC-5` row 12) and an approved untyped scope
(row 11) both widen a model's reach beyond its machine, and both appear in the blast-radius
statement and the trust display for as long as they are live.

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
the harness asked the aggregator for, and the aggregator documents that it may override.

**A count MUST NOT be derived from something it does not measure.** The provider layer used to
be *observed* and had no source on the chosen aggregator; deriving it from the model name would
have produced a figure labelled *observed* that was read off the request. It is now *requested*,
which is a count of what was sent — and that label is the whole of its honesty. Should a
response ever carry the served provider, an *observed* count may sit beside the requested one;
until then there is one column, and it says what it is.

### SEC-10 — the trusted list does not grow silently

**The trusted-party list MUST NOT grow silently.** Any feature adding a party to it is a
change of the same weight as a schema migration. The certificate authorities a WASM TLS
client would bundle (`CHN-12`) are such a growth, which is one reason that capability is
unbuilt.

### SEC-11 — the host key is checked

**An SSH session MUST check the host key against the stored fingerprint, and a key that does
not match MUST halt the session.** Exactly one moment is exempt, and it is why `CHN-R4` is a
floor: under trust-on-first-use there is no stored fingerprint at first contact, so that
contact is trusted rather than verified and MUST be presented to the operator as such. No
other path may accept an unverified key.

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
layer.

The CORS sent-but-unreadable case is engineered away: an origin's route is chosen by a
dedicated harmless probe before any side-effecting call exists, every untyped call carries a
custom header so no simple request exists, and a real call's failure never selects a new
route. Should an unreadable response occur anyway, it is the same unknown outcome.

### SEC-13 — the app holds no funds

**The app MUST NOT hold, forward, or custody funds.** A Bitcoin wallet able to pay for
machines is an intended future capability and it collides with this, so the collision is
recorded rather than resolved (`OPN-17`).

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

**What the harness claims.** No session reaches a machine it is not bound to **through
anything the harness controls** — bound by provisioning it, by re-entry on a maintained
machine, or by the recovery ladder's escalation. A model's blast radius is:

- the machines its weights have touched, **plus**
- any credential authority standing approved for its session as an untyped scope, at that
  origin, which may itself reach machines the harness cannot see, **plus**
- any tenant secret placed on a machine it is bound to, which its root shell can read.

Those three are stated together because no one of them alone is the boundary. Every approved
scope and every placed tenant secret appears in the trust display until revoked or rotated —
closing an approval does not un-trust a service that still holds the key.

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
vacuous. Distinct weights are **configured** per machine, so distinctness is enforced by
construction; whether the proxy served the weights it was asked for is not observable, and that
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
