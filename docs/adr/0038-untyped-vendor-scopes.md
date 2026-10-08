# A vendor with no adapter is reached through an untyped vendor scope, on stated conditions

A cloud vendor the bundle has no adapter for is usable: the session reaches it through an
**untyped vendor scope**, as an acceptable weaker mode with conditions no operator act sets
aside. A typed adapter is the best practice, and an optimization, not a precondition. Decided
2026-10-05.

This amends [ADR-0017](./0017-off-machine-calls-and-scope-approval.md), which says "Vendor APIs
are typed operations or nothing; a vendor with no adapter is not yet usable, which is the cost
of keeping the isolation claim true".

## Why

ADR-0017 generalized the cloud plane to any service and then carved vendors back out, for a
real reason: a vendor's control API can remake a machine, and with no adapter the harness
cannot see which machine a call touches. The price was that the general case — any vendor an
operator names — waited on the publisher writing an adapter for each one. That is the same
release-between-the-operator-and-the-thing that ADR-0017 refused for third-party services.

The reason is still true. What changed is the answer to it: rather than refusing the vendor,
bound what an unseen call can reach by facts the harness does hold — its own journal — and
show the operator, as theirs to answer, the things it cannot know.

## The decision

**Typed wherever an adapter exists, and only there.** `SEC-4` says "A scope MUST NOT name an
origin a vendor adapter covers". An untyped scope at an API an adapter covers would walk around
the adapter's per-operation check, so the weaker mode is never a way past an available
stronger one.

**Untyped where none exists, on conditions `SEC-4` lists.** `SEC-4` says "Untyped, at a vendor
with no adapter — an acceptable weaker mode (`SEC-14`), under conditions no operator act sets
aside", and each condition is in its list.

The pause is `STA-24`'s to state: `STA-24` says "the harness worker MUST NOT dispatch a
box-plane command to any machine of the session's bound set at that vendor".

**What cannot be kept is shown.** With no adapter reading the response, a token the vendor
mints and a root password it generates are in model context. The conformance items that keep
such values from a model are restated for this mode, not waived and not quietly failed: what
is tested here is that the operator was told before approving.

**The questions the harness cannot answer are put to the operator, once, and labelled as the
operator's statement.** Whether the account holds other servers that matter, and whether it
can spend by itself. `SEC-4` carries the questions and the warnings word for word, and says
"The answers never block".

**The best practice** is a vendor identity derived per set, or a fresh project per set. The
first has no format yet (`OPN-26`).

## Considered options

**Typed operations or nothing**, the standing rule; or vendor control left to the operator,
who buys the machine by hand and binds what exists. Rejected as the rule and kept as the
preference: it is the only arrangement in which every vendor call is approved on facts, and it
makes the product as wide as the publisher's adapter list.

**Untyped only behind a scope the vendor itself enforces** — a token limited by the vendor to
one machine and one effect. Rejected as a condition: few vendors offer one, and the harness
could not check it if they did. Where an operator has such a token it narrows the exposure, and
the warnings follow from the operator's own answers.

**Untyped only with a vendor identity the harness derived for the session**, so that the
account holds nothing else by construction. Rejected as a condition and kept as the best
practice: it depends on a derivation that does not exist and on a vendor that separates
accounts by identity, which is known of no vendor yet.

**Key the exclusivity rule on the credential.** Rejected for the origin and the vendor
identity, read from the journal: two different tokens can reach the same account, and a rule
that compares strings is a label. The journal knows which machines were provisioned where.

**Make the operator's answers a gate** — refuse the scope if the account holds other servers,
or can spend by itself. Rejected: the harness cannot check either answer, an honest "not sure"
would block the operator the mode exists for, and a gate on a statement nobody can check
teaches people which answer to give. The answers set warnings, and the warnings are restated at every
later irreversible act.

**Confirm each destructive call under the scope.** Already rejected by ADR-0017 for untyped
calls in general: it shows a non-technical operator a raw request they cannot evaluate.

**Pause the box plane on every machine of the set** while a vendor call is unresolved.
Rejected for the narrower pause, to the set's machines at that vendor: a call to one vendor
cannot remake a machine at another.

**Use attest for a machine created under the scope.** Rejected: the model composes the create,
so the introduction key cannot ride in a boot configuration the harness did not write. The
first contact is a jump host's
([ADR-0036](./0036-first-contact-is-never-trusted-through-the-relay.md)).

**Assume the worst case in every sentence** — that a vendor credential reaches every machine
on the account. Rejected for "may reach". The absolute was not true of a scoped token, and a
rule built on it forbade an operator from using one vendor account in two sessions under a
typed adapter, for no gain.

## Consequences

**The typed path does not wait on this.** The first stage uses a typed adapter; this mode is
the second stage's, because it needs the jump host.

**Several edges are open and recorded** (`TASKS.md`): a token rotated at the same origin
starts with no unresolved barrier; abandonment has no typed destroy to run at such a vendor; a
vendor with no adapter that refuses a browser origin cannot be reached until an arbitrary
destination can be tunnelled; and the target's address arrives in a response the model reads,
where the jump-host route wants it read by harness code.

**The trust display gains a kind of entry.** A vendor reached this way is both the machine's
vendor and a service holding a key the harness cannot bound, for as long as that key lives.

**An adapter, when the publisher writes one, closes the mode for that vendor.** From that
bundle on, a scope naming the origin is refused.
