# Findings — requested-provider routing at the aggregator (`CNF-78`)

Date: 2026-09-22. Evidence: `2026-09-22-provider-routing/case-{A,B,C,D,E}.json`, the response
bodies as returned. Five calls against `https://api.ppq.ai/v1/chat/completions` from a funded
account, model `glm-5.3`, `max_tokens` 5. Total cost $0.000126.

`CNF-78` requires the one observable fact about override to be measured: whether a pin naming a
provider that cannot serve the requested model **fails the call** or **silently succeeds**.

## Verdict

**It fails the call, and the aggregator names the provider that served a satisfiable one.**
*Requested* therefore means "honoured or refused", not merely "sent".

| Case | Request | Result |
|---|---|---|
| A | no routing preference | `200`, `chatcmpl-…` envelope, no provider named |
| B | `provider.only: ["z-ai"]` | `200`, `gen-…` envelope, body carries `"provider":"Z.AI"` |
| C | `provider.only: ["definitely-not-a-provider-xyz"]` | `404`, refused |
| D | model suffix `:floor` | `200`, `chatcmpl-…` envelope, no provider named |
| E | `provider.only: ["openai"]`, a real provider that does not serve this model | `404`, refused |

C and E return the same refusal, which enumerates the providers that do serve the model:

> No allowed providers are available for the selected model. Providers serving
> `z-ai/glm-5.3-20260816`: baidu, reka, sail-research, novita, io-net, phala, morph,
> inference-net, deepinfra, digitalocean, inceptron, gmicloud, makora, siliconflow, alibaba,
> decart, friendli, akashml, baseten, mistral, crusoe, wafer, venice, together, parasail,
> modal, fireworks, cloudflare, atlas-cloud, z-ai, but your request's `provider.only`
> preference permits only: definitely-not-a-provider-xyz.

## What this overturns

**The provider is reported back.** `ARC-31` says "the chosen aggregator returns no routing
metadata, so what the display shows is what was asked for", and `CONTEXT.md`'s *inference
provider* says it is "not reported back by the chosen aggregator". Case B carries
`"provider":"Z.AI"` in the response body. The observed layer `OPN-23` closed for want of a
source has one on this path.

**The provider vocabulary is published** — by the refusal, per model, as the list above.
ADR-0033 records that the aggregator "publishes no provider vocabulary and names no provider
per model", which was true of its documentation and false of its behaviour.

**Requesting a provider is what makes the answer observable.** A call with no routing
preference (A) and a call with a suffix (D) are both served without naming a provider; only the
`provider.only` form (B) comes back with one, and in a different response envelope. The two
paths are not the same code at the aggregator, so what is true of one is not evidence about the
other.

**The published API documents neither form.** `ppq.ai/llms.txt` documents routing only as a
model-name suffix (`:nitro`, `:floor`, `:exacto`, `:thinking`, `:extended`, `:online`). The
`provider` object `bundle/inference.toml` names — from ADR-0007's order/only/ignore — is
undocumented and works. An undocumented request shape is a fact about today, not a commitment,
and this finding is what dates it.

## What the account path showed

Creating an account takes one unauthenticated `POST /accounts/create`: no email, no identity
step. It returns the two tiers `ARC-31a` describes — an account credential that governs, and a
bearer key — and a Lightning topup funds it from the documented minimum upward.

`ARC-31a`'s lower tier is real and not a convention: `POST /keys` mints a key with a spending
cap and an expiry, and the calls above were made with one. Two facts about the upper tier are
worth the corpus's attention. The key an account is *issued* with carries no cap, no reset
period and no expiry — caps exist only on keys minted afterwards, so "the key you were given"
is an account-tier credential whatever it is called. And key management is authenticated by the
account credential rather than by any key, which is what makes revocation meaningful.
