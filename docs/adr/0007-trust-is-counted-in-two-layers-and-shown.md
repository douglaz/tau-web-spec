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
another member. `spec.md` states both in their operative form.

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

**PayPerQ's browser reachability is unverified.** OpenRouter's CORS behaviour was
established empirically; an OpenAI-compatible API does not imply an origin may call it.
This needs the same curl probe before the panel can offer it as a one-tap action.
