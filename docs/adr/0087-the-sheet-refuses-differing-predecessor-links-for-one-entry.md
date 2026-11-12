# The recovery sheet refuses differing predecessor links for one entry: an owner-directed amendment of payload version 8

Decided 2026-11-11 on the owner's instruction ("Adopt the refusal"), after a review panel in one
round. The counts and the owner's pick are `tw-5hl` comment 280000001. This is an owner-directed
amendment of the credential format's payload version 8 in place. It narrows what version-8 import
accepts, by name, against ADR-0080 (below). The credential format's recovery sheet owns the
members and their refusals; `STA-22b` owns the replacement act and its link; `CNF-84` owns the
case.

## What was undecided

The quotes are the text as it stood before this change (commit `32d1f75`).

`predecessor` is defined per approved entry. The format said it is "the exact string `"none"` when
the journal holds no predecessor for the entry", or, "on each allocation of a replacement entry, an
object with exactly the members `seed_id`, `machine_index` and `entry_id`", and that "The exporter
copies both members unchanged from the journal". ADR-0080 recorded that "Every allocation of the
replacement entry carries the same link". So a conforming exporter writes one `predecessor` value
per known `entry` id (four of four).

Import accepted a sheet that gave one known `entry` id two different values. Each refusal checked
one record or one link's target, and none compared two records of one entry: ADR-0080 records that
the draft "adds no refusal of differing links among one entry's allocations". Which link the
restored journal then held was not stated, while `STA-22b` says "Replay, export and import preserve
the predecessor link and these restrictions without redispatch", and `CNF-72` requires the link to
name its target "and no other" (four of four). The per-record cycle check did not see a cycle
between entries whose records disagree: entry A with one record carrying `"none"` and another
linking to B's Failed record, which links back to A's Failed record, passed every listed check.

## The shape chosen

- **Refuse differing links.** Import refuses, before binding, two machine entries, in either list
  or one in each, whose `entry` carries the same id and whose `predecessor` values differ: two
  different strings, a string and a link, or two links that differ in any of `seed_id`,
  `machine_index` and `entry_id` (four of four).
- **`"unknown"` is left out.** An `entry` of `"unknown"` carries no id; that string is the same on
  every converted entry, so the comparison leaves those entries out (four of four).
- **No winner.** No precedence rule picks one of two differing links; the sheet is refused.
- **Several links to one Failed allocation stay accepted.** The format's "Several links may name one
  Failed allocation" and the owner's earlier "Don't add a check" (ADR-0080) are unchanged.
- **The export side.** The format now states what it already forced: every machine entry of one
  approved entry carries the same `predecessor`, so the exporter writes one value per known `entry`
  id. No sheet a conforming exporter writes is newly refused.
- **One `CNF-84` case**, in two runs: `"none"` against a link, and two links naming different Failed
  allocations, across `allocations` and `retired_allocations` (four of four). The same case
  accepts a replacement entry with two allocations carrying the same link, so an import that
  refuses every repeated `entry` id fails it; this adds no rule.

The panel split two to two on whether today's undefined restore could drop `STA-22b`'s dispatch
wait. The rule does not depend on that point, so it took no second round.

## Version: amended in place

This follows ADR-0080 and ADR-0081, which amended payload version 8 in place on the ground that
nothing writes a version-8 sheet (four of four).

Re-checked at landing, 2026-11-12: nothing writes a version-8 sheet. This repository holds no
sheet writer in its tools, workflows or prototypes. The implementation repository (`tau-web-rust`)
`main` is still at `c01f980`, where ADR-0080's check found its recovery-sheet export ticket open and
no `retired_allocations` in its source.

## What this narrows

- **Narrowed, by name:** what version-8 import accepts, against ADR-0080's "adds no refusal of
  differing links among one entry's allocations". A sheet giving one known `entry` id differing
  `predecessor` values was accepted and is now refused before binding.
- It also closes the cross-entry cycle above, since A's two records now differ and the sheet is refused.

## What stays

- Every earlier version-8 refusal, the conversion of versions 3 to 7 with both members
  `"unknown"`, and `STA-22b`'s duty.
- `CNF-72`'s link "names exactly the retired entry's approved-entry identity and its Failed
  allocation, and no other".
- The formal companion: no theorem, gate, witness or assumption boundary moves (four of four). The
  companion has no replacement act and omits the sheet's import checks. The credential vectors,
  derivation version 1, the sheet envelope and its AAD are unchanged.

## Alternatives considered

| Option | Disposition |
|---|---|
| Leave import accepting differing links | Not chosen by the owner. The restored link would be undefined. |
| Pick one link by a precedence rule | Not chosen. No rule in the text ranks two links of one entry. |
| Bump to payload version 9 | Not chosen. Version 8 is amended in place, as ADR-0080 and ADR-0081 did, since nothing writes a version-8 sheet. |
