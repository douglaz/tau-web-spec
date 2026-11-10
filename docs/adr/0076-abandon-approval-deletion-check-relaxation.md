# Abandon approval deletion checks: an owner-directed relaxation

Decided 2026-11-08 (`tw-qe7.12`) on the owner's instruction, from review item R06, "Let
machine cancellation include follow-up deletion checks". This partially supersedes
[ADR-0053](./0053-the-setup-finishes-on-arrival-and-one-check-reads-a-stopped-machine.md)'s
blanket choice that every deletion check is started by the operator. Its other decisions,
alternatives and reasoning remain the historical record. This is a permission-only relaxation,
with no change to T44 or capability admission.

## Why

After abandoning a setup, an operator may return repeatedly while a stopped machine still
bills. Starting each deletion check again adds friction without changing the target or the
evidence needed. The owner accepts fewer repeated starts in exchange for continued, narrowly
authorized authenticated vendor contact while the app is available. Read-only authority does
not mean invisible contact: `SEC-4` says "these are authenticated reads the vendor receives and
may record".

## Decision and owners

The permission and initiation rule live in `SEC-4`; the single Abandon card and its durable
approval facts live in `ARC-21`. `ARC-21` says "For machines this abandonment flow stops, the
same card MUST also disclose: “Status will be checked while the app is available.”" and
"The Abandon approval carries the deletion-read permission through these journaled card facts".
This uses the recorded card facts, with no field, separate permission record, schema layer,
format version or migration.

For the permission's reach, `SEC-4` says "only for the abandoned setup's machines that the
abandonment flow itself stopped, as the approval's recorded resource dispositions (`ARC-21`)
identify them" and requires "the single Abandon card's durably recorded facts" to
"include the disclosure that status will be checked while the app is available".
For continuation, `SEC-4` says "On relevant app availability or reopening, the harness MAY
make bounded checks for those machines without a separate operator start for each check." Its
distinction is "Availability is an opportunity to use that recorded authority, never authority
by itself." No execution while the app is closed or eventual confirmation is promised.

## Narrowing of R06

The owner chose Abandon setup only. R06's retirement half is left out: the old machine of an
LNVPS Replace rebuild and a machine the in-setup replacement rung stopped retain manual
checks. `SEC-4` said, until 2026-11-10, "Otherwise each deletion check, which makes
`STG-21a`'s reads once, is started by the operator" and included
"Replace's old machine and every machine the in-setup replacement rung stopped, including
when its setup is later abandoned under a disclosed card". There is no Replace or retirement
approval created, named or extended, and no disclosure is put on a Replace card.

Approvals are distinguished by recorded facts, never by date or product version. `SEC-4`
includes "approvals whose recorded facts lack the disclosure" in that manual rule and says
"There is no action to extend an approval lacking the disclosure." R06's proposed extension
through a status action is dropped; no such action is defined. Nothing else is narrowed or
widened. Cancellation here means machine abandonment only: `SEC-4` says "Stop task, End
session, cancelling inference and browser closure convey no deletion-read authority."

## Preserved boundaries and evidence

For eligibility, `SEC-4` retains "It MUST act only on a machine stopped under `ARC-22`'s
unavailable-destroy treatment whose deletion is not yet confirmed" and "under that machine's
own recorded vendor key". For dispatch and custody, `SEC-4` says "Explicit app Lock,
unavailable credentials or an unavailable capability MUST prevent dispatch, including after
reopening." For the unavailable capability and its display, `SEC-4` says "Deletion verification
MUST remain unavailable until T44's vendor-key capability exists, and the interface MUST show
it as unavailable with the reason." T44 and `SEC-5` row 22 are unchanged.

The deletion check remains separate from abandonment's mutations; `SEC-4` says "it MUST NOT
replay stop, destroy, reinstall or renewal-off, or authorize a new target". Holder Ends,
paid-key revocation and reconciliation remain with `ARC-21`; session binding, durable intent,
unresolved outcomes, resource restrictions, independent delivery and secret custody remain
with their owners. No theorem, witness or assumption boundary changes: the non-session
authority stays with its prose owner under ADR-0032.

The predicate stays with `STG-21a`, the durable evidence record with `STA-24`, and the lifecycle
and display consequences with `SEC-5` and `ARC-22`. `STG-21a` says "This is accepted vendor
risk, not proof of host destruction in every source-permitted execution." Its completion
limit remains "No post-confirmation reappearance handling is specified: the resulting
billing-display gap remains, and completion does not claim permanent id absence or coverage
of that gap." Fewer operator starts change neither evidence nor trust.

For the positive permission and refusals, see `CNF-26`'s deletion-check case; the deletion
predicate's own fixtures stay with `CNF-112`. For Replace, `CNF-20` says "another check
requires another operator start". The applicability table keeps
the abandonment, Replace and in-setup replacement admissions separate, including later abandonment of a
rung-stopped machine's setup. These are capability-conditional demonstrations, not evidence
that T44 is usable. `STA-17`'s pointer remains correct: "The deletion check (`SEC-4`) collects
that evidence and adds no call to this flow." The glossary has no per-check initiation rule
to synchronize, and the credential format's missing-key refusal is unchanged.

*Amended 2026-11-10: partial supersession of the narrowing of R06, for Replace's old machine
only.* [ADR-0077](./0077-replace-old-machine-card-deletion-check-relaxation.md) records the
owner-directed widening (`tw-qe7.19`): a new Replace old-machine card, owned by `STA-17`, whose
recorded facts let `SEC-4`'s follow-up deletion reads run for the old machine of an LNVPS Replace
rebuild. A machine the in-setup replacement rung stopped keeps manual checks, as above. The
narrowing as decided on 2026-11-08 remains the historical record.
