# Procured inference is the operator's balance, not the publisher's account

On the default inference path the **operator** funds an account-free balance at one aggregator
and holds the credential for it. The harness mints a **capped, expiring session key** from that
credential for each session and revokes it when the session ends. The publisher selects the
models, in the briefs, and touches neither the money nor the credential.

`ARC-31a` states the mechanism and `SEC-5` rows 2 and 14 state the two tiers. This record holds
the reasoning, the verified facts it rests on, and what it costs.

## The problem this addresses

`SEC-5` row 2 used to read *"Operator (BYO) or publisher (procured)"*, and nothing anywhere said
how a publisher-originated credential reached browser memory. Every unstated answer was bad.
Baking a key into the bundle publishes it to everyone who loads a public download. Fetching one
per session requires something to decide, per request, that *this* operator is entitled to it —
which is an account system with a different name, and
[ADR-0025](./0025-relay-access-is-bought-not-granted.md) rejected exactly that, for exactly this
audience.

## What was verified, 2026-09-05

Against the aggregator's own pages and its live API, not its marketing.

**Credential issuance needs no account.** One unauthenticated `POST` with an empty body returns
a working credential and a key. No email, no password, no signup. The operator's copy is a bearer
value the aggregator itself compares to cash.

**Bitcoin is a first-class funding rail.** Lightning from ten cents, on-chain, Liquid and Monero,
all prepaid and non-withdrawable — plus gift cards bought elsewhere, which means the aggregator
never sees a payment at all. No identity check is documented at any spend level.

**The two-tier split is the aggregator's own design, not a convention layered on top.** Key
management is authenticated by the account credential and **rejects the session key**, verified
by observation. So a session key cannot mint siblings, raise its own cap, or attach a funding
source. Session keys take a spend limit down to one cent, a reset period, and an expiry, and
revocation is immediate and irreversible.

**Exposure is hard-capped.** An exhausted balance returns `402`. There is no credit line, no
overage and no postpaid mode, so a leaked session key costs at most the lesser of the remaining
balance and that key's cap.

**It answers a browser directly.** `Access-Control-Allow-Origin: *` on the preflight, on the
model list, and on the 401, with `Authorization` permitted. This closes what
[ADR-0007](./0007-trust-is-counted-in-two-layers-and-shown.md) recorded as unverified and means
procured inference needs no relay, so `CHN-13` gains no new exposure.

**Its terms permit the arrangement.** No key-sharing, resale, or on-behalf-of prohibition
exists, and the operator markets white-label integration to wallets and exchanges with a named
live partner.

## Considered options

**The publisher holds the account and issues keys to operators.** This is what `ARC-31`'s *"the
operator pays one fee"* implied if the fee went to the publisher, and it is the option a reader
will re-propose, because it sounds like the publisher absorbing complexity on the operator's
behalf. Rejected: something must then decide per session who gets a key, and that decision needs
a durable notion of who is asking. It reintroduces the identity party that ADR-0025 removed from
the relay, in a product whose argument is that no party accumulates a picture of the operator.
It also makes the publisher hold operator funds, which nothing else in this design does.

**The operator brings a provider key and there is no procured path.** Simplest of all, and it is
already the bring-your-own path. Rejected as the *default* because it requires an account at a
model provider — a card, an email, a billing relationship — which is the barrier the product
exists to remove for someone holding only a phone and some bitcoin.

**Hand the session the account credential directly.** Fewer moving parts, no minting, no
revocation to get right. Rejected because that credential is bearer, unrevocable, spends the
whole balance and can attach an auto-refilling wallet. The tiering exists precisely so a session
holds something bounded.

## Consequences

**The Added tier gets smaller than `TRU-A1` described.** The publisher was tolerated in model
selection *because* bring-your-own existed as an escape hatch. It now also handles no money and
issues no credential, so its procured-path role is narrower than the record assumed.

**`SEC-5` gains the only unrevocable row in the table.** Row 14 holds spendable balance with no
issuer to revoke against. Every other credential in the design can be killed; this one can only
be spent down or abandoned. That asymmetry is why row 2 exists at all.

**The recovery sheet now carries money.** `STA-16` exports the account credential, because the
alternative is that a lost phone burns whatever the operator funded, with no path back — the
aggregator's own words are that if you lose it, it is gone. The sheet already holds the keys to
every maintained machine, so this changes the size of a loss rather than its kind. What it must
not do is arrive unannounced: a sheet holding balance is a different object from one holding
references, and the export screen says so.

**Replace cannot cover it, and `STA-17` says so.** The flow can revoke every session key minted
from the credential and mint no more, which stops the harness and not a thief. The only real
remedy is to move or spend the balance.

**A session key can read the account's usage history.** Timestamps, model names and costs across
every key, with no prompt content. So a session observes that its siblings ran and what they
cost. `SEC-1` binds what a session reaches on machines and is silent about what it learns of
other sessions. There is no remedy at the aggregator and the information carries no address, no
content and no credential, so it is stated in `ARC-31a` rather than solved.

**The retention default is a trap and is handled as one.** The aggregator's web app defaults to
its zero-retention tier and **its API does not**, so a harness that omits the flag gets prompt
retention upstream and is not told. `ARC-31a` requires it on every call and `CNF-71` checks an
outgoing request rather than trusting the default.

**The party is thinly documented, and that is priced rather than smoothed.** No legal entity, no
jurisdiction, no governing law, no forum for the arbitration its terms require; its own About and
Contact pages are linked and return 404; its terms bind the user to a usage policy and a sharing
policy that **do not exist yet** and take effect on posting. There is no status page and no
reliability record. Against that it is visibly a real operation, shipping continuously for
eighteen months, running its own Lightning node. `TRU-E2` states both halves. The reason this is
acceptable is the prepaid bound: the operator's exposure is what the operator chose to fund.

**One thing this record does not fix.** The aggregator does not report which provider served a
request, so `ARC-14`'s observed layer has no source. That is `OPN-23`, and it is a separate
decision from this one.
