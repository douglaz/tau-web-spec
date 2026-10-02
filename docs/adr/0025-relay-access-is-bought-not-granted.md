# Relay access is bought, not granted

**Moved 2026-09-24.** The rule this record adopted, with both amendments below, is
paid-tcp-relay's (its ADRs 0001 and 0003, `PAS-1`–`PAS-8`, `DST-2`, `DST-3`;
github.com/douglaz/paid-tcp-relay). This record stays as the history of why tau-web adopted it
and is no longer the rule's home; `CHN-15` and `CHN-16` are tau-web's adoption.

An operator obtains relay access by **paying for a pass**, not by holding an account. The
relay returns `402` with an invoice over ordinary HTTPS; the operator's own wallet pays it;
the relay observes its own invoice settle and issues an **opaque random pass**, against which
it keeps a record of the destinations that pass may reach and when it expires. The pass is
presented when the WebSocket opens.

No email, no password, no reset flow, no identity. Losing the pass is not a recovery problem:
you buy another one.

We chose this because the alternative is an account system, and an account system is a party
that knows every operator by name and can switch them off. `SEC-10` prices adding a party to
the trusted tier as a change of the same weight as a schema migration, and this product exists
to remove exactly that kind of relationship rather than acquire one. The corpus already leans
on the same escape twice: `OPN-5` records that renting for sats with no account is the only way
out of the cloud vendor billing floor, and `ARC-31` says an aggregator taking Lightning with no
registration nearly solves inference. This is the third instance of one pattern.

It also costs less to build than it looks. `ARC-30` already specifies an invoice-relaying flow
for inference credits, and `SEC-13` already forbids the app from holding funds, so the
interface and the constraint both exist.

## Amended: the port restriction was wrong, and pacing replaces it

This record was written without checking it against
[ADR-0021](./0021-the-surface-pentest-is-outside-in.md), and the two contradicted each other
outright. The pass was restricted to the SSH port; the scanner ADR-0021 specifies probes **which
ports answer**, through this same relay. Every probe the scanner exists to send was a probe the
restriction refused.

The subtler half is worse than the contradiction. Run the scan anyway and the relay forwards
port 22 and nothing else, so the scan observes exactly one open port on every machine — always,
whatever that machine's firewall is doing. It would confirm `ARC-39`'s declaration by
construction and show the operator a manufactured observation of their own vault. A check that
cannot fail is worse than no check, because no check is visibly absent.

It also broke `ARC-41` from the side ARC-41 did not guard. That requirement forbids the firewall
*privileging* relay sources, so the relay-side surface is never **larger** than the world's —
which is the whole no-access argument. The port restriction made it **smaller**. The argument
needs equality, and only one side of it was written down.

**A recorded destination is therefore reachable on any port, and pacing carries the weight the
port restriction used to.** Per-run and per-target limits already exist in ADR-0021's tool
contract; they stop being politeness and become the anti-abuse control. The narrowing that keeps
`CHN-8` true is now: recorded destinations only, capped in number, paced per destination, billed,
revocable.

**What this gives up, stated plainly.** The relay cannot verify that a recorded destination
belongs to the operator, so every scan target being a harness-provisioned machine is an
assumption rather than an enforcement — weaker than the rule it replaces. The residual is
bounded by the relay being a *worse* scanner than the alternative: a pass buys a capped, paced,
revocable, billed view of a handful of addresses, and the same money rents a machine with none
of those limits. A tool strictly worse than what an attacker already has does not attract them.
That is an economic argument, not a cryptographic one, and it is priced here so nobody later
mistakes it for the latter.

## Amended: the pass is bound to a derived key, and nothing bearer remains

The opaque random string is gone. What the relay binds a purchase to is the **public half of a
relay key** the browser derives from the operator's seed
([ADR-0029](./0029-the-machine-speaks-nostr-and-keys-derive-from-a-seed.md), `STA-22`), one
per purchase; on connect the relay issues a challenge and the browser signs it, in the shape
NIP-42 defines and the browser already implements for the Nostr relay. Recording a destination
and revoking are messages signed by the same key. **The pass is what the relay remembers; the
key is what the browser proves.**

**What forced it.** `STA-17` promised the pass would be revoked after a lost phone, and this
record's own design made that impossible: the string was on the lost phone, and with no account
the relay had no way to recognise whoever asked. Once a seed existed, a derived key answered it
in one move — and answered a second thing nobody had asked, which is that a bearer string let
anyone holding it widen the destination list, and a signature does not.

**What it gives up.** Nothing this record valued. Purchases are still unlinkable by credential,
because each pass derives its own key. There is still no account, no email, nothing the
operator supplies. What changes is that a lost phone no longer loses the pass — the key
re-derives — so "re-bought rather than recovered" was true of the string and is not true of
the key.

**Revocation is re-priced.** Under `ARC-41` the relay's view equals the world's, so a pass in the
wrong hands reaches nothing the public internet does not. It spends the operator's paid quota
and gets their pass blamed for the traffic. Revocation protects money and attribution, not
machines, and `CHN-16` now says so.

**The L402 objections below, re-read against this.** The first — the browser cannot run a
`402` challenge on a WebSocket upgrade — does not apply to a challenge that runs *inside* the
socket after it opens, which is what NIP-42 does and why it was borrowed. The second — no
preimage — is moot, because the relay observes its own invoice settle and needs nothing from
the wallet. The third — a stable identifier by design — is the one this amendment had to
answer, and per-purchase derivation is the answer. The fourth stands: the relay is stateful
regardless. What is kept from L402 is still the shape.

## Considered options

### L402, the designed standard for this exact problem

The Lightning HTTP 402 protocol is precisely this idea, specified: the server answers `402`
with `WWW-Authenticate: L402 macaroon="…", invoice="…"`, the client pays, and retries with
`Authorization: L402 <macaroon>:<preimage>`. The server verifies an HMAC chain and that
`sha256(preimage)` matches the payment hash baked into the credential. It is maintained by
Lightning Labs, its reference proxy shipped a release in March 2026 and was still being worked
on in August 2026, and Lightning Loop uses it in production.

Its scoping language is genuinely good and does what this relay needs. Macaroon caveats are
`condition=value` predicates in an extensible vocabulary, and the reference proxy's real
grammar includes `services=lightning_loop:0` and per-service `…_valid_until` timeouts, with
stacked caveats required to be strictly more restrictive. `services=ssh_host_17:0` is a
two-line satisfier away, not a hope. A holder can also attenuate further offline — narrowing a
broad pass to one machine for ten minutes without contacting the issuer.

**Rejected on four grounds, of which the third is decisive.**

*The browser cannot run the challenge.* The `WebSocket` constructor accepts a URL and
subprotocols and nothing else — there is no headers argument — and a failed upgrade reaches
application code as an error event with no access to the response, so the `402` and its
challenge header are unreadable. A working path exists and is used in the lnd ecosystem, which
smuggles the credential through `Sec-Websocket-Protocol` and runs the challenge over a prior
`fetch()`. But that is a convention rather than the specification, which contains no mention of
WebSockets at all.

*It wants a preimage this design does not have.* Verification is stateless precisely because
the client proves payment by producing the preimage. Here the operator's **own wallet** pays
(`ARC-30`, `SEC-13`), and a wallet paying a scanned invoice returns nothing to the browser.
Recovering the preimage would mean requiring a programmatic wallet connection, and the
extension-based ones need an install that `OVR-1` forbids.

*It carries a stable user identifier, by design.* The macaroon identifier is
`version || payment_hash || token_id`, and the specification describes that 32-byte `token_id`
as **a stable user identifier across macaroon rotations**. Every use of a pass is linkable to
every other use and to the payment that bought it. Adopting a credential built around a durable
identifier, in a product whose whole argument is that no party accumulates a picture of the
operator, is adopting the thing being avoided.

*Its main advantage is moot here.* Stateless verification is what macaroons buy, and `STA-17`
requires the relay pass to be **revocable** — the Replace flow re-issues it and revokes the
old one. Revocation is inherently stateful. The relay also needs state anyway for settlement
polling, abuse control, live connection tracking and expiry, and the reference proxy itself now
stores tokens server-side to support revocation. The delegation machinery would be carried
without being used, since this relay is both issuer and verifier with nobody to delegate to.

The interoperability argument does not rescue it: the proposed bLIP has sat unmerged since June
2023, one service directory lists sixteen L402 endpoints against over a thousand for a
competing scheme, and the largest third-party adopter has publicly concluded that
re-architecting around it was not worth the client-adoption problem — one cited reason being
that applications use WebSockets rather than HTTP.

**What is kept from it: the shape.** A `402` carrying an invoice, a scoped and time-limited
credential issued on payment, and no account anywhere. That was always the valuable part.

### Ecash tokens

Cashu defines an ecash token presented against a `402`, and it beats every other option on
payer privacy: each spend is unlinkable, there is no persistent identifier in the credential at
all, and the token is a plain string that passes trivially where a header cannot go.

Rejected because the privacy it buys is largely undone downstream. `CHN-13` records that the
relay learns the member topology regardless — which operator connects to which destinations,
when. Paying unlinkably for a tunnel that then observes where you go is a narrow gain, and it
costs a mint: the operator must either run one or trust one, which is a new party in the tier
`SEC-10` guards. Worth revisiting if the relay's metadata exposure is ever closed, because then
the payment becomes the remaining link.

### An account system

What every ordinary service does, and it genuinely makes support, abuse response and revocation
easier. Rejected because it adds the identity party this record exists to avoid, and because the
audience is defined as people who already hold Bitcoin and are trying to leave exactly this kind
of arrangement behind.

### Keep issuing tokens by hand

What the first stage does, and correctly: one operator who is also the publisher needs no
issuance system ([ADR-0019](./0019-the-publisher-operates-the-default-relay.md)). Rejected as
the answer for a real user base, because deferring twice is how a stopgap hardens into the
default by inertia.

## Consequences

**The relay needs to receive Lightning, and that is its operator's problem.** For the default
relay that operator is the publisher. For a **self-hosted** relay under `CHN-11`'s trajectory
the operator runs it for themselves and charges nobody, so no payment machinery arises at all.
If someone ever rents relay capacity to others from a machine that also hosts guests, `ARC-37`
binds and receiving must be watch-only or delegated — the pieces compose without a special
case.

**Payment does not by itself stop abuse; it raises its price and enables response.** A pass
buyer can declare destinations, and a relay that forwards wherever it is told is a paid proxy
rather than an open one. What narrows it to something defensible is the combination `CHN-8`
already requires: only to destinations recorded against that pass, capped in number, paced per
destination, and revocable the moment abuse is observed (see the amendment above for why the
port is not part of that list). The
destination record is the same row as the authorization, which is why keeping them together
matters.

**Destinations are declared as machines come into existence, not at purchase.** A machine
being provisioned does not exist when the pass is bought — it is created through the cloud
plane, direct from the browser, and only then does it have an address. So a pass is bought
first and its destination list grows as the operator adds machines. That is also the moment
the relay learns topology, which `CHN-13` already prices.

**The first stage is unaffected.** It runs on a pasted token by ADR-0019, which remains right
for a single operator who is also the publisher. `STG-18` continues to record that enrolment is
untested, and this record is what that gap now points at. *(Superseded by the amendment above:
nothing is pasted. The first stage hands the publisher the relay key's **public** half out of
band, and the relay authenticates a challenge against it — `STG-18`, `CNF-87`.)*

**`SEC-5` gains no new credential class.** The relay pass replaces the relay token in row 4,
with the same lifecycle: held encrypted at rest, revoked and re-issued by the Replace flow. What
changes is where it comes from — bought rather than handed over — and that losing it needs no
recovery path. *(Superseded by the amendment above: row 4 is now the derived relay key,
re-derived on demand and never stored; the pass is what the relay remembers, and Replace
revokes it by the old key's signature.)*

## Recovery and destination limits, September 9 correction

The derived key is recoverable only with its pass index and relay URL (`STA-22b`), now included
in the sheet. Missing metadata can lose remaining quota; seed-only purchase discovery is not
promised. `CHN-16a` also constrains every destination at dial time to public unicast addresses,
excluding the relay itself. A signed destination record does not authorize loopback, private
network or metadata access, even in the first stage's manually enrolled configuration.
