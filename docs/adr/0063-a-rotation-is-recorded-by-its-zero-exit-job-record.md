# A rotation is recorded by its zero-exit job record

Decided 2026-11-05 (`tw-38p` comment 130000001). `SEC-5` owns the act that records a rotation and
the scan boundary; `ARC-43` owns the new placement's listing and the wait; the credential format
owns the exported sheet; `CNF-95(j)` owns the case. This record closes two points ADR-0061 left
open and adds no rule of its own.

## What was undecided

ADR-0061 put the rotation's scan boundary at "the journal act that records the rotation", but
`SEC-5` said at `d30dfba`: "Which act of the rotation's `place_secret` records the rotation, and
what a rotation whose job fails or stays unresolved (`STA-8`) does to P's reference, are not yet
specified." A rotation's `place_secret` has several journal acts: the record made before its bytes
leave (`ARC-8`), the admission of its job record, and possibly a disposition (`STA-24`). Its job can
exit nonzero or stay unresolved. Nothing said which act ends the old placement P's scan key and
reference, sets the `reference_ended` mark and moves the boundary, or what P keeps when no act
does.

## The shape chosen

**The zero-exit job record records the rotation.** The act that records the rotation is the one
that admits the rotation job's completed root-only job record with a zero exit (`STA-20`). Until
then:
- P's scan key and reference stay as they were, armed or unarmed. A P without a report stays live,
  listed and required; a reported P stays in operator-reported history with no required reference.
- The new placement is listed, and its reference required, from the record made before its bytes
  leave, whatever its job then does, since from that record on its bytes may have left: `STA-4`
  says an intent with no terminal record means the call "may have been sent, never that it was
  not". Output owes both references.
- No `reference_ended` mark is set.

**What records no rotation.** The record made before the bytes leave, a nonzero exit, a job that
stays unresolved and a disposition record no rotation, and leave P as above. A job record of a
rotation call that a disposition disposed records no rotation, whenever collected; it is journaled
and shown. `STA-24` says "Evidence about the calls the disposition names that arrives after it is
journaled and shown: it neither reopens the call nor removes the disposition", and a disposition
"keeps the outcome *unknown*". `ARC-43`'s rule for a digest record of a call a destructive
disposition named has the same shape.

**The exported sheet.** The credential format rejects "two records without a report at one machine,
application name, secret name and path". Writing both an unreported P and its new placement while
the rotation is unrecorded would produce a sheet the importer rejects, and so would writing the new
placements of a failed attempt and its retry, whether or not P has a report. The export therefore
writes a rotation's new placement only once `SEC-5` records the rotation, for every P: a sheet
exported before then holds P as it was and no record for the new placement, and a rotation never
recorded leaves its new placement on no sheet. The recorded rotation then replaces an unreported
P's record with the new placement's, and writes a reported P's new placement beside it, as the
format already said. This is the smallest change the text forces: no sheet field, version or
importer rule changes.

It narrows one thing, by the sheet's export time rather than the time of the store loss. A sheet
exported after the record made before a rotation's bytes leave and before `SEC-5` records the
rotation holds no record for the new placement, so a Restore from it lists the new placement
nowhere and requires no reference for it, whenever the store is later lost. A failed attempt's new
placement is never exported, so any Restore ends its listing and required reference. After such a
Restore an unreported P is restored as placed and owes its re-arm, which reads whatever its path
then holds: if the new bytes are there, the re-armed reference holds the new value, no mark is set,
and pre-loss records holding the old value are withheld only until the re-armed references check
them clean. This sits within `ARC-43`'s existing limit, "After store loss there is no old reference
with which to detect every rewrite", the same limit a sheet exported before any rotation began
already has, and `STA-16` shows the restored inventory as "unknown since export".

**Unchanged.** ADR-0061's boundary and its rule, row 23, the mark's rotation setter, `STA-4`,
`STA-20` and `STA-24` are not touched; this record names which act ADR-0061's boundary is.

## Why

Four independent readers answered; a fifth seat was unavailable.

- **The recording act.** Two readers recommended this option and two recommended the rotation be
  recorded only by a matching cross-check digest after the job. None recommended the record made
  before the bytes leave. All four said the text forces no option. The tie went to the owner, who
  picked this option on 2026-11-05.
- **A failed, unresolved or disposed job** records no rotation, P keeps its reference and listing,
  the new placement is listed and required from the record made before its bytes leave, and no
  mark is set: 4 of 4, under either recommended option. All four said this narrows or widens no
  earlier owner pick (ADR-0060, ADR-0061, ADR-0062), touches no theorem and leaves row 23's
  lifetime column unedited.
- **The sheet and the late record** were left by the panel to the text work. The sheet follows from
  the importer's duplicate rule, as above. On the late record, two readers said it records none,
  one said the text cannot tell and one did not address it. The review pass of this text, four
  independent readers, agreed 4 of 4 that it records none.

Recording the rotation at the record made before the bytes leave would end P's scan while its new
value might never have arrived. The admitted zero-exit record is the first act that shows the job
ran to completion.

## Alternatives considered

| Option | Disposition |
|---|---|
| The record made before the rotation's bytes leave records it | Not selected. It ends P's reference and sets the mark while the new value may never have been placed. |
| A matching cross-check digest after the job records it | Not selected. The owner picked the zero-exit job record after a 2–2 tie. |
| Export both P and the new placement while the rotation is unrecorded | Not selected. For an unreported P, or for two attempts, the importer rejects two records without a report at one machine, application name, secret name and path. |

## Open

These stay open:
- what ends a failed attempt's new placement, its listing and its required reference, while the
  local store stays intact (a Restore does, above);
- what a failed first placement does to its listing, its reference and the export, on which the
  text is silent.

## Consequences

`SEC-5`, `ARC-43`, the credential format and `CNF-95(j)` change together, and ADR-0061 notes that
both its points are decided here. The formal companion has no placement or scan-reference state
and is unchanged.
