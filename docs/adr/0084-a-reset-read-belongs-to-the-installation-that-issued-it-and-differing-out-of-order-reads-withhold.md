# A reset read belongs to the installation that issued it, and differing out-of-order reads withhold the reset: an owner-directed amendment

Decided 2026-11-10 on the owner's instruction ("Adopt it", row by row), after a review panel in
two rounds. The counts and the owner's picks are `tw-74f` comment 262000001 (rows 28 and 29).
This is an owner-directed amendment. It amends one earlier recorded boundary by name and decides
one recorded open point (below). `STA-20b` owns the reset into the installed system and its
prerequisites; `ARC-43` owns `ready_to_reset`'s read and its refusals.

## What was undecided

Each quote is the text as it stood before this change (commit `d454852`).

- **Row 28, which installation a late result belongs to.** `STA-20b` said "The offer MUST use
  the current installation's durable prerequisites to make the offer; earlier installations'
  records are read only to withhold it". No sentence said which installation a `ready_to_reset`
  result belongs to when it is collected or appended after a reinstall boundary. The reset that
  dispatches a standing disposition's reinstall "does not wait for a command that disposition
  names", so such a command's result can still arrive later. Counted under the installation
  current when it is processed, as the formal companion does (it "derives the installation at
  processing; this is no faithful translation of late results"), an earlier installation's result
  could become the current installation's first durable prerequisite read. Four of five readers
  found that this could make a false offer, not only withhold one; the fifth could not tell
  whether such a history can be built.
- **Row 29, which out-of-order good read counts as newest.** `STA-20b` said: "Outside that
  lifting, where an older-issued `ready_to_reset` command's otherwise admitted prerequisite result
  is first durably appended after a later-issued command's result, which of the two is the newest
  read is not decided." The offer turns on that read: it "MUST NOT be offered when the newest
  `ready_to_reset` read differs from the active installed pin". With different key sets, each
  ordering can offer where the other withholds.

## The shape chosen

- **Row 28, the issuing installation.** A `ready_to_reset` result belongs to the installation
  that was current when its command's intent was journaled, in the browser journal's issue order,
  whenever the result is collected or appended. A result of a command issued before the current
  installation began is an earlier installation's record, read only to withhold: it never becomes
  the current installation's first durable prerequisite read, active pin or any other current
  prerequisite. The command ID its record already carries ties it to that intent, so no field is
  added. The rule can withhold an offer but never make one. Five of five in round one.
- **Row 29, withhold on a difference.** Among results that belong to the current installation,
  where an older-issued command's result is first durably appended after a later-issued
  command's result and the two key sets differ, the offer and dispatch of the reset into the
  installed system are withheld. Only a command issued after both, in issue order, may lift that,
  with its durably appended result and under every prerequisite, the first-read anchor and the
  active pin included. Equal key sets change nothing. It offers only where both orderings would.
  Five of five in round one; no conformance case, four of five with the required reader in the
  majority.

Row 28 applies first, so row 29 compares only the current installation's results. Both use the
issue order the refusal-lifting rule already uses. Whether either history can be built under the
admission rules stays unsettled: `tw-4mz` comment 228000001 "establishes no constructible runtime
history". If neither can be built, the rules cost nothing.

## What this amends

- **Amended, by name (row 28):** the attribution boundary in `tw-4mz` comment 221000001 (O7A),
  whose acceptance created "no new issue-time attribution rule, processing-time permission,
  anchor-poisoning policy, storage field or cross-boundary conformance case". The issue-time
  attribution rule is added. No storage field is added. The cross-boundary conformance case stays
  out: on row 28's case, which split two to two in round two, the owner picked "No extra test".
- **Decided (row 29):** the open point that `tw-4mz` comment 228000001 recorded at `STA-20b`'s
  newest-read boundary ("Which of those is the newest read remains not decided"). The rule is a
  withholding only, not a general issue-order rule for choosing the newest read.
- The adoption names no narrowing or widening. Each rule can only withhold the offer or dispatch
  (five of five on each row).

## What stays

- The formal companion. No theorem, gate, witness or assumption boundary moves (five of five on
  each row). `TauWeb.Dispatch.installationOf` still derives the installation when an event is
  processed. `STA-20b`'s disclosure of that limit stays and now names both rules as Markdown-only.
- No conformance case is added: for row 28 by the owner's "No extra test", for row 29 four of
  five. `CNF-86`'s existing cases stand, including "After reinstall, predecessor prerequisites
  cannot offer a reset".
- The refusal-lifting rule, the fixed first-read anchor, the active pin, missing-result
  withholding, the earlier-installation overlap refusal and every authority condition.
- Repeated collection and duplicate append stay outside row 29's rule, as 228000001 left them.

## Alternatives considered

| Option | Disposition |
|---|---|
| Leave each point open | The earlier recorded boundaries, now amended by the owner's "Adopt it". |
| Row 28: the installation at append, as the companion derives it, stated as the rule | Not selected (five of five for the issuing installation). An earlier installation's result could set the current first read. |
| Row 28: change the companion (`installationOf`, the coupled collection event) | Not selected (five of five for keeping the disclosed limit). The Markdown rule is stricter and contradicts no theorem. |
| Row 28: one `CNF-86` history of a late result after the boundary | Not selected. Split two to two in round two; the owner picked "No extra test". |
| Row 28: align the witness file's `reset_offer` note | Not adopted (two of five). The `STA-20b` disclosure carries the limit. |
| Row 29: the later-issued result is the newest read | Not selected (five of five for withholding). It offers on that read while an older command's late result disagrees. |
| Row 29: the later-appended result is the newest read | Not selected. It offers on a late older result while the later-issued read shows changed keys. |
| Row 29: one conformance case | Not selected (four of five, with the required reader in the majority). |
