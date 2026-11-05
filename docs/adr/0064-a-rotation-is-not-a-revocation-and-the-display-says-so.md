# A rotation is not a revocation, and the display says so

Decided 2026-11-05 (`tw-foh` comment 132000001). `SEC-5` owns the claim and the scan boundary;
`SEC-6` owns the display; `ARC-43` owns the rotation's card; `CNF-95(j)` owns the case. This
record closes the last point ADR-0061 left open and adds no rule of its own.

## What was undecided

ADR-0061 left open "whether output after a rotation should still be compared against the old
value, since a rotation is not a revocation, and whether the trust display should say so".
`SEC-5` says "The rotation claims neither revocation of the old value at its service nor erasure of
its copies". Nothing shows the old value stopped working at its service. A later command can print
it back, from a config cache or from a withheld job's own record under `/var/lib/tau-web/jobs`,
and after the recorded rotation that output is not compared against the old value. `SEC-6` stated
that limit beside the new placement but said nothing about revocation.

## The shape chosen

**The comparison ends at the rotation, as before.** The act that records the rotation
([ADR-0063](./0063-a-rotation-is-recorded-by-its-zero-exit-job-record.md)) ends the old placement
P's scan key and reference and its live listing. Output after it is not compared against the old
value. Row 23's lifetime column stays "Until rotation". The `exec` wait, re-arm, the sheet, the
credential format and its version, and the `reference_ended` mark are unchanged. No new operator
act is added, and the lost-key report stays offered only while unarmed
([ADR-0062](./0062-the-lost-key-report-is-offered-only-while-unarmed-and-is-final.md)).

**The display and the card say a rotation is not a revocation.** Beside the new placement, the
trust display states that the rotation is not a revocation, and that revoking the old value at its
service is the operator's act, which the harness does not verify. The rotation's `place_secret`
card says the same before the operator approves it. The owning paragraphs cite `SEC-5`'s claim
for both statements. Like the limit beside it, the display's statement lasts while the journal
records the rotation; after a Restore from a later sheet only the `reference_ended` statement is
shown, as before. The clause "which the harness does not verify" is text work: it states the
`SEC-5` claim's limit at the service and adds no rule.

## Why

Four independent readers answered; a fifth seat was unavailable. All four said the text forces
neither answer.

- **The comparison** was accepted under the owner's 2026-11-05 panel rule, 4 of 4. The scan was
  never the control for a live credential: `SEC-5` limits the redaction claim to exact copies
  "whose reference the browser holds", and "the claim is no wider than that". Revocation at the
  service ends the old value's authority there; copies and earlier disclosures remain, and the
  harness cannot verify the revocation. Destruction is the parallel case: it "claims neither
  physical erasure nor revocation of the credential at its service", yet its references end, and
  ADR-0050 already declined to extend them on its peers. Keeping the old reference is the
  alternative ADR-0061 did not select, extended to all later output, and it still needs a rule for
  when the reference is dropped. Ending it by the operator's report would offer the report
  while armed, which ADR-0062 did not select.
- **The statement** was accepted under the same rule, 4 of 4. An operator reading "rotated" could
  take it for a revocation, and only the operator can revoke the old value.

The pick narrows or widens no earlier owner pick (ADR-0050, ADR-0057, ADR-0060, ADR-0061,
ADR-0062, ADR-0063). The bead's "Either answer widens row 23's lifetime" holds only for keeping
the old reference.

## Alternatives considered

| Option | Disposition |
|---|---|
| Keep P's reference and require it until the operator reports the old value revoked, or P's machine is destroyed | Not selected. It widens row 23's lifetime, needs a second unreported record at one path on the sheet, which the importer rejects, and a report offered while armed. |
| Keep P's reference and compare against it while the local store lasts, without requiring it | Not selected. It widens row 23's lifetime, adds a held but unrequired reference the text has no state for, and loses its protection silently at a store loss. |

## Consequences

`SEC-6`, `ARC-43` and `CNF-95(j)` change together, and ADR-0061 notes that its last open point is
decided here. `SEC-5`, row 23, `CNF-42` and the credential format are unchanged. The formal
companion has no placement or scan-reference state and is unchanged.
