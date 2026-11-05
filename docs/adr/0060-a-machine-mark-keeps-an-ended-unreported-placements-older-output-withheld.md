# A machine mark keeps an ended unreported placement's older output withheld after a Restore

Decided 2026-11-05 (`tw-huu` comment 118000001). `SEC-5` owns the scan boundary and row 23;
`ARC-43` owns the re-arm after store loss; `STA-10` owns the exposure ledger; `STA-16` owns what a
restored sheet shows; the credential format's payload version 7 owns the mark's wire form;
`CNF-84` and `CNF-95(i)` own the cases. This record closes a point ADR-0057 left open and adds no
rule of its own.

## What was undecided

The credential format said of a placement without an operator report: "Rotation replaces its
record with the rotation's new placement, and its machine's destruction removes it from every later
export. What keeps output withheld for such an ended placement after a Restore from a later sheet
is not yet specified." After local-store loss the sheet is the only thing that names a placement.
`ARC-43` re-arms "every placement the sheet records" and says the unknown inventory "does not
itself block work once all known required references are armed". A job record from before the
loss that held the ended placement's value, on its machine or a peer in its bound set, had nothing
left to keep it withheld once the other references were armed. `SEC-5` says of destruction "bytes
withheld before it stay withheld" and of a reported placement "every job record from before the
loss stays withheld for P"; neither reached an ended record that left the sheet.

## The shape chosen

**A mark on each machine the ended reference scanned.** Each version-7 `machine_states` entry
carries a required boolean, `reference_ended`. The journal act that records the rotation of a
placement without a report, or the admitted deletion evidence of a machine holding one, sets it on
that placement's machine while the machine stays live and on every live machine the exposure ledger
records in a bound set with it. Nothing clears it, and the exporter copies it.

**What it does after a Restore.** On a marked machine every job record from before the loss stays
withheld, as for a reported placement. Only output whose box-plane job the restored journal records
as dispatched after the loss is new.

**What it is not.** It names no placement and carries no value-derived reference, so the display
can say only that a reference that scanned the machine ended before export. Import checks its form
only. Versions 3 to 6 convert with the mark unset, so an older sheet restores its own as-of-export
state. Like the rest of the sheet it is as of export: an end the journal records after a sheet's
export sets no mark on that sheet.

**Version.** This amends payload version 7, as ADR-0058 and ADR-0059 did. Nothing in the
repository writes a version-7 sheet.

## Why

Four independent readers split two, one and one, and all said the text forces no option and that
no option touches a theorem. With no majority the owner chose the mark. It keeps `SEC-5`'s
"Unscanned bytes MUST be withheld" across a Restore without keeping an ended unreported record on
the sheet, so a rotation still replaces that record and an unreported record on a destroyed
allocation is still refused. It withholds only on the machines whose output the ended reference
scanned, read from the ledger's recorded bound sets rather than reconstructed.

## What this changes in earlier picks

Nothing is narrowed or widened. A rotation still replaces an unreported record, its machine's
destruction still removes it from later exports, the refusal of an unreported record on a
destroyed allocation stands, and a reported record keeps its own rules.

## Alternatives considered

| Option | Disposition |
|---|---|
| Keep the ended unreported record on later sheets as history | Not selected. It amends the refusal of an unreported record on a destroyed allocation, and like the mark it cannot name a placement made after the export. |
| Withhold every job record from before the loss on every machine after any Restore | Not selected. It withholds on machines no ended reference scanned and narrows `ARC-43`'s release once every known reference is armed. It alone would cover a placement made after the export and ended before the loss. |

## Consequences

`SEC-5`, `ARC-43`, `STA-16`, the credential format's payload version 7, `CNF-84` and `CNF-95(i)`
change together. The formal companion has no placement or scan-reference state and is unchanged.
How rotation treats output produced before it within a session stays open; the mark covers only
what a Restore loses.
