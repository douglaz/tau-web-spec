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

The relaxation removes the separate classification question only while the task fits the
conservative class. `ARC-36a` says "For an ad-hoc machine, before admitting requested behavior
that requires a less restrictive class, the harness MUST obtain an explicit operator answer
to the classification questions for that machine." The signed question text, answer mapping and note in
`bundle/lockdown.toml` are unchanged. No policy-inference subsystem is introduced.

The restrictions retain their owners. `ARC-37` says "A multi-tenant machine MUST NOT hold
**spendable** key material." `SEC-1` says "A multi-tenant machine (`ARC-36`) is always bound
alone." `ARC-43` says "the operator confirms the value is not spendable before it is sent;
without that confirmation nothing is placed". These apply equally under the default;
declaration approval is no waiver. Application credentials and tenant key material retain
their separate treatment in the delivery-declaration companion.

The question path supplies a prerequisite for relaxing behavior, not authority for an
already-bound class transition. `ARC-36a` says "it supplies no reclassification route or
exception to `SEC-1`'s binding, re-entry, growth or exposure checks." No transition,
grandfathering rule, history reset or admission route is chosen here. The rejection of
model-proposed classification in ADR-0034 therefore stands, including when a suggestion was
displayed before interruption or UI state was restored.

## Consequences

`CNF-100` exercises admission and provenance, the signed-question prerequisite and attempts
to manufacture an answer. The directly dependent multi-tenant cases are `CNF-92`, `CNF-52`
and `CNF-94`; declaration refusal remains covered by `CNF-99`. `CNF-101` continues to cover
maintained access and journaling before installation.

The recovery format retains a recorded class value without treating a harness default as
unapproved or turning that value into an operator answer. No format version or field changes.
The declaration companion consumes the class as a Boolean; its spendable-material refusal
and its theorem are unchanged. This decision changes admission provenance, not that refusal
or any capability's conformance admission.
