# Ad-hoc admission defaults to the conservative machine class

Decided 2026-11-08, on the owner's instruction. This is a **relaxation** of mandatory
up-front classification questions for an ad-hoc machine when the conservative multi-tenant
class supports the whole task. It partially supersedes
[ADR-0034](./0034-general-case-first-tenants-are-optional-skills.md)'s decision that
"Machine class is asked" for every machine with no tenant. The rest of that decision and
its rejection of "Have the model propose the machine class and the operator approve it"
remain in force.

## Why

A one-machine goal needing no wallet can reach setup approval within the conservative
restrictions. An obligatory classification screen adds an answer without changing what
that task may do. Recording the source of the class preserves the distinction between a
conservative harness choice and a fact the operator explicitly asserted. The default belongs
to the harness, never to a model's suggestion or a preselected answer.

Multi-tenant describes the parties served, not shared physical hardware: `ARC-36` says
"A machine that serves parties the operator has never met is **multi-tenant**."

## Decision and retained boundaries

The owning rule is `ARC-36a`. `ARC-36a` says "A default is not an operator answer."
Its initial-admission rule, provenance, conditional signed questions and model prohibition
apply through the ad-hoc profile; the profile points there rather than carrying a second
classification rule. `ARC-44` remains the owner of profile use and per-machine journaling
before installation, and `ARC-39` of declaration approval. Tenant presets and maintained
access retain their treatment.

The question path resolves class only during initial admission. `ARC-36a` says "While an
ad-hoc machine's initial admission remains open, through setup approval and before binding,
if no explicit operator answer has yet been journaled for that machine, the harness MUST
explain the concrete conflict before asking the classification questions for requested
behavior that requires a less restrictive class." `ARC-36a` says "The explicit answer and
its resolved class MUST be journaled before admitting that behavior, and before binding and
installation." This first-answer path requires no prior default record. `ARC-36a` says
"A further relaxing request MUST NOT use the question path to relax an operator-answered
restrictive class or admit behavior incompatible with that class; its operator-answer
provenance MUST be retained."
The signed question text, answers, class mapping and note in `bundle/lockdown.toml` are
unchanged. No policy-inference subsystem is introduced.

The restrictions retain their owners. `ARC-37` says "A multi-tenant machine MUST NOT hold
**spendable** key material." `SEC-1` says "A multi-tenant machine (`ARC-36`) is always bound
alone." `ARC-43` says "the operator confirms the value is not spendable before it is sent;
without that confirmation nothing is placed". These apply equally under the default;
declaration approval is no waiver. Application credentials and tenant key material retain
their separate treatment in the delivery-declaration companion.

For the already-bound defaulted case, `ARC-36a` says "Once an ad-hoc machine has been bound
under the harness default, the harness MUST refuse a request requiring a less restrictive
class for the rest of that session, explaining the concrete conflict without presenting the
classification questions." This resolves that case in the relaxing direction only.
`ARC-36a` says "Its class does not relax in that session; those requests MUST leave the
journaled class and harness-default provenance unchanged." No later-session re-entry policy
is chosen here. Tightening after binding remains open in `TASKS.md`; `ARC-36a` says "The
model MAY propose a tightening, single-purpose to multi-tenant, and nothing else".
The rejection of model-proposed classification in ADR-0034 stands, including when a
suggestion was displayed before interruption or UI state was restored.

## Consequences

An operator who did not request the less restrictive capability before binding cannot obtain
it on that machine in that session. The relaxation trades mandatory up-front questioning
for this cost; a request after binding receives an explanation and a refusal, without a
question whose answer could be mistaken for permission to proceed.

The after-binding refusal was chosen rather than instructed, and it **narrows** the owner's
instruction. That instruction asked that, when a later request conflicts with the
conservative restrictions, the concrete conflict be explained before the relevant question is
asked. Here the question path stays open only during initial admission; after binding the
conflict is explained and no question is asked. A review panel picked the refusal, three of
four readers with a fifth seat unavailable, accepted under the owner's 2026-11-05 panel rule.
The dissent was to ask after binding and then admit the behavior through every check.

Conformance for class admission and same-session refusal is in `CNF-100`; dependent
restriction cases are in `CNF-92`, `CNF-52`, `CNF-94` and `CNF-99`. Maintained access and
pre-installation journaling are covered by `CNF-101`.

The recovery format retains a recorded class value without treating a harness default as
unapproved or turning that value into an operator answer. No format version or field changes.
The declaration companion consumes the class as a Boolean; its spendable-material refusal
and its theorem are unchanged. Admission provenance and the same-session refusal under
`ARC-36a` change neither that declaration refusal nor any capability's conformance admission.
