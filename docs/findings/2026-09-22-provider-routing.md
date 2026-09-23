# Findings — requested-provider routing at the aggregator (`CNF-78`)

Dates: 2026-09-22 — five calls, response bodies only, `2026-09-22-provider-routing/run-2026-09-22/`
— and 2026-09-23 — six calls, each with its request body, HTTP status, response headers and
response body, `run-2026-09-23/`. All against `https://api.ppq.ai/v1/chat/completions`, model
`glm-5.3`, `max_tokens` 5, from a key minted with a spending cap and an expiry. **No call sent a
retention tier**: `ARC-31a` names "the flag" without its wire form, and the aggregator's
published API (`ppq.ai/llms.txt`, read on both days) documents none.

`CNF-78` says "a pin naming a provider that cannot serve the requested model either fails the
call or silently succeeds, and which one is recorded".

## Verdict

**On both days an unsatisfiable `provider.only` was refused, and a satisfiable one was served
with a `provider` field in the response that followed the pin.** Refusal is `CNF-78`'s first
outcome. The field is the aggregator's own report, on one response path; it is not evidence,
independent of the proxy, of which party served the request — `TRU-E2` names the proxy as
able to alter everything it carries. The display label stays *requested*.

| Case | Request | 09-22 | 09-23 | Response |
|---|---|---|---|---|
| A | no routing preference | `200` | `200` | `chatcmpl-…` envelope, no provider field |
| B | `provider.only: ["z-ai"]` | `200` | `200` | `gen-…` envelope, `"provider":"Z.AI"` |
| C | `provider.only: ["definitely-not-a-provider-xyz"]` | `404` | `404` | refused at `Filter by Allowed Providers` |
| D | model suffix `:floor` | `200` | `200` | `chatcmpl-…` envelope, no provider field |
| E | `provider.only: ["openai"]` — a real provider that does not serve this model | `404` | `404` | refused at `Filter by Allowed Providers` |
| F | `provider.only: ["deepinfra"]` | — | `200` | `gen-…` envelope, `"provider":"DeepInfra"` |

The refusal names the step and the alternatives. C's message:

> No allowed providers are available for the selected model. Providers serving
> `z-ai/glm-5.3-20260816`: baidu, reka, sail-research, novita, io-net, phala, morph,
> inference-net, deepinfra, digitalocean, inceptron, gmicloud, makora, siliconflow, alibaba,
> decart, friendli, akashml, baseten, mistral, crusoe, wafer, venice, together, parasail,
> modal, fireworks, cloudflare, atlas-cloud, z-ai, but your request's `provider.only`
> preference permits only: definitely-not-a-provider-xyz.

C and E share that template and differ in `metadata.requested_providers`; both carry
`metadata.failed_routing_step` = `Filter by Allowed Providers` and a thirty-entry
`metadata.available_providers`.

## What the evidence supports, and what it does not

**The pin is applied as a filter.** Two unsatisfiable pins were refused on two days, at a named
routing step, with the model's serving providers disclosed in the error. That is disclosure
through a refusal, not documentation: nothing here makes the list a stable catalogue.

**The reported provider follows the pin.** B returned `Z.AI` and F returned `DeepInfra`; A and D
returned no field. The values are display names, not the requested slugs `z-ai` and
`deepinfra`, and no mapping between the two is published. Following the pin rules out a fixed
or model-derived value. It does not rule out an echo of the constraint, and nothing a response
carries can: independent evidence would have to come from the serving party.

**The envelopes differ.** Responses to a `provider.only` request carry a `gen-…` id,
`native_finish_reason`, `usage.cost` and `usage.is_byok`; the others carry a `chatcmpl-…` id and
none of those. That suggests distinct processing paths. It does not establish which component
produced the field, nor whether the `provider.only` path puts another party in series with the
proxy — `SEC-10`'s concern, carried by T38.

**The documentation does not match the behaviour, in both directions.** `ppq.ai/llms.txt`
documents routing only as model-name suffixes (`:nitro`, `:floor`, `:exacto`, `:online`,
`:thinking`, `:extended`) and does not document a `provider` object. ADR-0007 and `OPN-23` record
that the aggregator's text said a supplied provider field "may be overridden"; `llms.txt` as read
on both days does not contain that phrase, and which document carried it is not recorded. The
response bodies cannot settle a documentary question; this finding only dates the mismatch.

**Cost.** Only the `provider.only` responses carry `usage.cost` (B: $0.0000458 on 09-22). The
account balance moved by $0.000126 across the first five calls — an account-side figure, not in
the bodies.

## What this changed in the corpus

Each of these said, without qualification, that the aggregator reports nothing about the
provider. Each is qualified in the same change as this finding, dated and path-specific, and
none of them changes the display label:

- `ARC-31` said "the chosen aggregator returns no routing metadata".
- `ARC-14` said "The chosen aggregator exposes no equivalent" and "Whether the request was
  honoured is not observable from a response today".
- `TRU-E3` said "no response field or header names the provider that served a request".
- `OVR-6` said "the aggregator reports nothing back and may override".
- `OPN-4` said "there is no provider signal at all"; `OPN-23`'s closure said "The aggregator
  actually chosen exposes no equivalent (verified 2026-09-05)".
- `CONTEXT.md`'s *Inference provider* said "not reported back by the chosen aggregator", and
  *Provenance record* said "the chosen aggregator reports none".
- ADR-0007's second amendment, ADR-0028, ADR-0033 and `executive-summary.md` carried the same
  claim; ADR-0007 gains a fourth amendment, and the others a dated sentence.

`SEC-9` anticipated exactly this: "Should a response ever carry the served provider, an
*observed* count may sit beside the requested one". A field has appeared on one path. Whether it
is *the served provider* is what T38 asks, and the requirement says *may*.

## What the account path showed

Creating an account is one unauthenticated `POST /accounts/create`: no email, no identity step.
It returns a `credit_id` and a key. The `credit_id` is `ARC-31a`'s account credential — `ARC-31a`
says "It mints and revokes session keys" — and it is the header key management authenticates
by; no bearer key can mint or revoke. `ARC-31a` says "A session inference key is minted per
session with a spend cap and an expiry", and `POST /keys` mints exactly that; the calls above
were made with one. The key an account is *issued* with carries no cap, no reset period and no
expiry — an uncapped working key, not the account credential, and unsuitable as the session key
until capped.

## The eligible set, from a committed snapshot

`models-2026-09-23.json` is the aggregator's model list as returned on 2026-09-23, and
`eligible-set.py` applies ADR-0033's rule to it. Its output that day:

```
listed: 378
eligible (zero-retention tier + tool calls): 111
of those flagged popular: 1
  glm-5.3  context=1310720  owned_by=Z.ai
```

The same rule on 2026-09-22, against a list not committed, gave 369, 109 and the same one model.
The list moved by nine entries overnight, which is the premise ADR-0033 rests on.
