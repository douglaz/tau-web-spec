# A rotation keeps the old placement's older output withheld

Decided 2026-11-05 (`tw-8cl` comment 121000001). `SEC-5` owns the scan boundary and row 23;
`SEC-6` owns the display; `ARC-43` owns rotation and the wait it ends; `CNF-95(j)` owns the case.
This record closes a point ADR-0060 left open and adds no rule of its own.

## What was undecided

`SEC-5` row 23 ends a placed secret's scan key and reference "Until rotation", and removes its
persistent copy on rotation. `SEC-5` also says "Unscanned bytes MUST be withheld". Destruction
and the operator report each say they never count as a scan. Rotation had no such sentence:
`SEC-5` said at `05601d3` "How rotation treats output produced before it within the session is not yet
specified." A job on a peer in the machine's bound set could print the old value and finish
before the rotation was recorded, yet be collected after it. A job could also run across the
rotation. Either way, once the old reference had ended, nothing compared that job's output with
the old value. ADR-0060's mark covers only what a Restore loses.

## The shape chosen

**The destruction and report rule, with the rotation in their place.** A rotation never counts as
a scan:
- Bytes withheld before it stay withheld, whichever reference withheld them. A range withheld
  while the old reference was unarmed is included.
- Output is after the rotation only when its box-plane job was dispatched after the journal act
  that records the rotation was durably recorded. A job dispatched before that act stays
  pre-rotation, whether it finished or runs across the act. Its bytes not scanned against the old
  reference before the act stay withheld.
- Output after the rotation is not compared against the old reference, as row 23 already said.
  While the journal records the rotation, the trust display states that limit.

The rule holds in every session while the local store is intact, a rotation recorded after a
Restore included. After a store loss that follows the rotation, ADR-0060's mark governs.

**Unchanged.** Row 23 and the credential format are not touched. The mark's rotation setter
stands: this rule releases no pre-rotation output for the old reference. A placement whose
report already ended its reference loses nothing more at its rotation.

## Why

All four independent readers recommended this option, and all said the text forced neither
option. It was accepted under the owner's 2026-11-05 panel rule, 4 of 4. All four also said:
- it narrows or widens no earlier owner pick;
- it touches no theorem;
- it leaves the mark unchanged;
- keeping the old reference would widen row 23's lifetime and disposal.

Destruction, the report and rotation now follow one rule. No ended scan material is kept.

## Alternatives considered

| Option | Disposition |
|---|---|
| Keep the old reference in the local store to scan ranges whose job was dispatched before the rotation | Not selected. It widens row 23's lifetime and its removal of the persistent copy on rotation, and needs a rule for when the reference is finally dropped. |

## Open

These stay open:
- which act of the rotation's `place_secret` records the rotation, since decided in
  [ADR-0063](./0063-a-rotation-is-recorded-by-its-zero-exit-job-record.md);
- what a rotation whose job fails or stays unresolved does to the old reference, since decided in
  [ADR-0063](./0063-a-rotation-is-recorded-by-its-zero-exit-job-record.md);
- whether output after a rotation should still be compared against the old value, since a
  rotation is not a revocation, and whether the trust display should say so, since decided in
  [ADR-0064](./0064-a-rotation-is-not-a-revocation-and-the-display-says-so.md).

## Consequences

`SEC-5`, `SEC-6`, `ARC-43` and `CNF-95(j)` change together, and ADR-0060 notes that its open
point is decided here. The formal companion has no placement
or scan-reference state and is unchanged.
