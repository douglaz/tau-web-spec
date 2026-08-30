# Relay access is bought, not granted

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
already requires: forward only to the SSH port, only to destinations recorded against that
pass, capped in number, rate limited, and revocable the moment abuse is observed. The
destination record is the same row as the authorization, which is why keeping them together
matters.

**Destinations are declared as machines come into existence, not at purchase.** A machine
being provisioned does not exist when the pass is bought — it is created through the cloud
plane, direct from the browser, and only then does it have an address. So a pass is bought
first and its destination list grows as the operator adds machines. That is also the moment
the relay learns topology, which `CHN-13` already prices.

**The first stage is unaffected.** It runs on a pasted token by ADR-0019, which remains right
for a single operator who is also the publisher. `STG-18` continues to record that enrolment is
untested, and this record is what that gap now points at.

**`SEC-5` gains no new credential class.** The relay pass replaces the relay token in row 4,
with the same lifecycle: held encrypted at rest, revoked and re-issued by the Replace flow. What
changes is where it comes from — bought rather than handed over — and that losing it needs no
recovery path.
