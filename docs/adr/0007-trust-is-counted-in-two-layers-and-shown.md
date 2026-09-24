# Trust is counted in two layers, and shown rather than scored

Independence is counted separately at two layers. **Weights** — how many distinct model
weights are in use. **Proxy** — how many distinct aggregators route the requests. Both
counts are displayed to the operator, alongside a plain-language list of who must stay
honest. They are never combined into a single score.

This amends the invariant in [ADR-0004](./0004-one-model-one-machine.md), which defined
a trust domain as the pair of provider and weights and treated independence as
requiring both to differ. That definition is too strict for the default product: the
publisher procures inference on the operator's behalf, so a shared proxy is the normal
case, and under the old definition every default configuration would have collapsed to
a single domain. What changed is that a domain is counted per layer instead of as an
indivisible pair.

An earlier version of this paragraph added "the one-machine-per-domain rule still holds,"
which is wrong at exactly the layer this record legalises: on the default path the proxy
domain touches every machine, by design. The rule that survives the split is about
**access** — each session bound to exactly one machine, with the weights-level form the
goal the assignment
serves, since unobservable weight reuse is a displayed collision rather than a violation —
while the
proxy layer is counted and displayed rather than bound. The same correction applies to
ADR-0004's recovery ladder: escalating to a stronger model is free at the proxy layer and
conditional at the weights layer, since the new weights must not already be running
another member. `SEC-1` and `ARC-16` state both in their operative form.

The layers protect against different things and neither substitutes for the other.
Five members on five sets of weights behind one proxy survive a backdoored model and do
not survive a backdoored proxy. Saying "five models" is true about weights and false
about proxies, which is why one number cannot be honest.

## Considered options

**A single blended security score.** Rejected because it hides which layer is thin, and
the thin layer is the one that gets exploited.

**Two named tiers, "Standard" and "Independent", with trust sets stated at setup.**
Rejected because a tier is read once, at the moment the operator cares least, and
because proxy count is a dial rather than a tier — PayPerQ can be added for ten cents
in sats with no registration, so the interesting states are the middle ones.

## Consequences

The panel must be operable, not decorative. Adding a second proxy has to be reachable
from the panel itself, so the operator learns what proxy diversity means by moving the
number rather than by reading about it.

**The trusted-party list must never grow silently.** Any feature that adds a party to
it is a change of the same weight as a schema migration.

The publisher stays in the trusted set on the default path, because it selects the
models. That is acceptable only because the publisher is already trusted for the bundle
([ADR-0006](./0006-single-origin-with-reproducible-builds.md)), and because
bring-your-own inference exists as the escape hatch. If that escape hatch is ever
dropped, this ADR stops being defensible.

**PayPerQ's browser reachability is verified, 2026-09-05.** It was recorded here as unverified,
correctly — an OpenAI-compatible API does not imply an origin may call it. The probe has now been
run and it passes comfortably: `Access-Control-Allow-Origin: *` on the preflight, on the model
list, and on the 401, with `Authorization` permitted and the requested header list echoed rather
than whitelisted. The panel can offer it as a one-tap action. `OPN-7` still stands, because it
asks about a **second** proxy and this settles the first.

## Amended: a third count, observed rather than configured

The two layers above are what the operator or the publisher *configured*. The runtime
signal showed a third party neither covers: the **inference provider** behind the
aggregator — chosen per request by the proxy, able to rewrite everything it carries, and
shareable between members without either configured count moving. It is now counted too,
and differently: a per-response, historical count built from `X-Provider-Name` — "across
the responses seen, N distinct providers served these members" — labeled **observed**,
because it can change on the next request and covers only witnessed traffic. Provider
collisions are shown, never blocked, and never restated as forward distinctness: absence
of observed sharing is not evidence of separation. The never-blend rule is unchanged —
three numbers, three labels, no score — and the display cost is nothing new, since the
header is already recorded for provenance.

## Amended again: the third count has no source, because the header was the other aggregator's

The paragraph above is right about *why* the layer matters and wrong about the one fact it
rests on. **`X-Provider-Name` is OpenRouter's header.** It was recorded here while OpenRouter
was the live candidate and PayPerQ was the one whose reachability this record flags as
unverified. The choice then went the other way, and the header did not travel with it: checked
against PayPerQ's own docs and live API on 2026-09-05, **no response field or header names the
provider that served a request**, and page script could not read one if it did — `/chat/completions`
exposes only a request id to a cross-origin caller.

"The display cost is nothing new, since the header is already recorded for provenance" is the
sentence that made this invisible. It was true of the aggregator being measured at the time and
became false without anyone touching it.

**The layer is kept and the count is emptied.** The reasoning for counting the provider
separately is untouched — it is still a party neither configured layer covers, still chosen per
request, still able to rewrite everything it carries. What is gone is the evidence. A count
derived from the model name would name whoever *made* the weights, presented under a label that
says *observed*, which is precisely the overstatement `SEC-2` forbids elsewhere. So the number is
shown as absent until a source exists.

There is circumstantial evidence that PayPerQ resells OpenRouter for much of its catalogue — a
legacy `openrouter:` type still accepted, OpenRouter's exact routing-preference conventions, and
OpenRouter-specific community model slugs. **Inference, not verification.** If it holds, the
provider name exists upstream and is being dropped in the middle. It is not a basis for claiming
anything today.

## Amended a third time: the layer is requested, and all three are configured

The empty count did not stay empty. The same routing conventions that made the resale inference
plausible are what answered it: PayPerQ accepts a `provider` object in the request — `order`,
`only`, `ignore` — so the harness **asks** for a provider per member exactly as it asks for a
model, and the display shows what was asked under the label *requested*. The third layer joins
the first two as **configured**, which is where `OPN-4` had already landed for weights: what the
harness sends is known by construction, and what the proxy does with it is the proxy's trust.

**The override is documented and is not a new party.** PayPerQ's own text says provider fields
the caller supplies "may be overridden." That is exactly the capability the proxy row already
names — it can alter anything it carries — so the label *requested* points at `TRU-E2`, not at a
fresh row. `CNF-78` measures the one observable thing about it: whether an unsatisfiable pin
fails the call or silently succeeds.

**What was rejected.** Switching to an aggregator that reports the served provider would restore
the observed count at the cost of the accountless Lightning funding and open CORS that won
PayPerQ the slot — the product's premise traded for a display. Retiring the layer would discard
reasoning that is still right. Asking PayPerQ to expose the served provider costs nothing and is
recorded in `OPN-23`'s closure as a standing ask; if it lands, an *observed* column sits beside
the requested one and override becomes visible per response.

## Amended a fourth time: the aggregator reports a provider, and the report is a detector

Measured 2026-09-22 and 2026-09-23 (`docs/findings/2026-09-22-provider-routing.md`): a request
carrying a provider selection — `provider.only` — is served with a `provider` field in the
response, and the field follows the pin: `Z.AI` for `z-ai`, `DeepInfra` for `deepinfra`.
Requests with no routing preference, with a model-name suffix, or with `zdr` alone carry no such
field. An unsatisfiable pin is refused with `404` at a named routing step, never silently
rerouted. So the second amendment's "no response field or header names the provider that served
a request" was true of what was checked on 2026-09-05 and is not true now, and the third
amendment's "one observable thing" — refusal or silent success — has a second beside it: a
report that follows the pin.

**What the field is, decided 2026-09-24.** It is the proxy's report of itself (`TRU-E2`), in a
body whose CORS headers a browser could read, and nothing in a response can make it more than
that. So it is named — the *reported provider*, `CONTEXT.md` — and given one use: comparison.
`SEC-9` says "A match displays nothing and proves nothing" and "A mismatch MUST be surfaced on
that machine", the report's provenance kept in the words; the mismatch is believable because it
is against interest. The count stays *requested*; the *observed* column stays a *may*, untaken.

**What the envelope showed.** Responses on that path arrive in OpenRouter's response schema, and
the switch is triggered by the selection (`only`), not by `zdr`. `TRU-E2` now carries that
name by inference, dated, as a second name on the same row; whether it earns a row of its own
waits on confirmation.

**The documentation, read properly.** The third amendment's phrase "may be overridden" is from
the aggregator's `api-docs` page, which documents the whole routing object — `zdr`,
`data_collection`, `order`/`only`/`ignore`, `sort`, price and latency preferences, fallback
controls — and scopes the override to "a few models (some Anthropic and Gemini variants)" with
routing rules it enforces, the `zdr` request preserved. Its `llms.txt`, read on 2026-09-22 and
-23, omits all of it, which is what the text of this amendment merged on 2026-09-23 mistook for
"undocumented".

The title of this record is now wrong twice over — it is three layers, not two, and none of
them is observed — and it is kept, because the reasoning it names is the reasoning that survived.
