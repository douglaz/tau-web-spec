# The app relays invoices and never holds funds

Money is handled in two distinct ways and they must not be merged.

**Recurring costs** — the machines — are paid by the operator directly to the cloud
vendor, on their own account and their own payment method. The app never mediates this.
It holds a vendor API token that can spend against an account the operator already
controls, which is the arrangement `ai-vps-harness` already assumes.

**One-off costs** — inference credits — are assisted: the app retrieves an invoice from
the provider and hands it to the operator's wallet to pay. It relays an invoice. It
never holds, forwards, or custodies funds.

We chose this because a payment intermediary would be the one place in the design where
the operator is asked to trust *more* rather than less, on a product whose entire pitch
is the opposite. It also keeps a company from holding a Bitcoin user's funds, which is a
regulatory question before it is a trust question, and it is precisely the relationship
the operator came here to escape.

## What the payment evidence does and does not prove

Payment receipts are weaker evidence than they first appear, and the trust panel must not
overstate them.

- **A settled invoice proves the operator has funded credits at that provider.** It
  bounds which proxies are available and funded. It does not prove which member used
  which proxy, because one top-up buys many queries.
- **Per-member routing evidence is separate**, and would come from response metadata —
  `X-Provider-Name`. **That header is OpenRouter's**, and the aggregator since chosen exposes
  no equivalent (verified 2026-09-05, [ADR-0028](./0028-procured-inference-is-the-operators-balance.md)).
  So there is no per-member routing *evidence* from a response; routing is instead
  **requested** per member in the call (`ARC-14`), and the second of these two is a record of
  what was sent rather than what was served.

Two evidences, two strengths. The panel in
[ADR-0007](./0007-trust-is-counted-in-two-layers-and-shown.md) should cite the right one
for the right claim rather than blending them into one confidence.

## Consequences

**The vendor-account friction is now the real onboarding problem.** Paying for inference
is **solved**, and verified rather than assumed (2026-09-05,
[ADR-0028](./0028-procured-inference-is-the-operators-balance.md)): PayPerQ issues a working
credential from one unauthenticated call with no email, takes Lightning from ten cents, and
answers a browser origin directly — which closes the reachability
[ADR-0007](./0007-trust-is-counted-in-two-layers-and-shown.md) recorded as unverified. It is
also **one** aggregator reaching many models, so this is a single invoice rather than the
"several providers, a few invoices" this line originally imagined.
Cloud vendors are not: they want an account, a card, and a recurring billing
relationship, and a 3-of-5 federation across distinct vendors means several of those.
App-relayed invoices cannot fix this, because vendors do not sell that way.

**lnrent is therefore load-bearing for this product, not merely a second tenant.**
Renting machines for sats with no account is the same escape hatch for cloud vendors
that PayPerQ is for inference. Without something like it, the multi-vendor requirement
collides with the target operator's willingness to open several billing relationships, and
vendor diversity quietly collapses to whatever they already had an account with. That
requirement is *not* stated in [ADR-0004](./0004-one-model-one-machine.md), which an
earlier version of this line cited: ADR-0004 is about model access and says nothing about
cloud vendors. It rests on
[ADR-0006](./0006-single-origin-with-reproducible-builds.md)'s per-member vendor
diversification plus the correlated-fault argument in
[ADR-0010](./0010-members-reach-each-other-on-one-authenticated-port.md), and `SEC-T3`
records that it deserves a decision record of its own.

**Abandoning a setup has a direct cost the app cannot cancel.** Since the vendor
relationship is the operator's, only the operator can stop the billing — the app can
destroy machines ([ADR-0012](./0012-a-federation-is-created-only-when-every-member-works.md))
but cannot close accounts.

**A wallet is intended, and this decision does not yet cover it.** Paying for machines and
services from inside the harness is a wanted capability. Self-custody would not contradict
the reasoning above, since no intermediary appears and nobody is asked to trust more — but
it does not follow that it is free. Key material would share an origin, a process and a
storage layer with the model, which
[ADR-0011](./0011-the-ai-delivers-a-locked-down-machine.md) keeps apart; and a compromised
bundle would move from misconfiguring machines to spending funds, against a bundle that
[ADR-0006](./0006-single-origin-with-reproducible-builds.md) already records as
undefended — reproducible builds do not exist and nobody runs the watchdogs. The live
options are a separate origin (which
[ADR-0006](./0006-single-origin-with-reproducible-builds.md) rejected for user safety, an
objection that would have to be answered rather than ignored), the same bundle with this
consequence rewritten, or a tenant of its own. **This is deferred, not decided**, and it is
recorded here because a wallet is the kind of feature that arrives looking harmless and
lands on the invariant most easily violated by accident.
