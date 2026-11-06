# A reported placement's older output stays withheld on its machine and its recorded peers

Decided 2026-11-06 (`tw-xef` comment 138000001; the ledger's wording, comment 139000001). `SEC-5` owns the scan boundary, row 23 and the
withholding after a report; `STA-10` owns the exposure ledger; `ARC-43` owns the report and the
re-arm after store loss; `CNF-95(k)` owns the case. This record closes a point the report's
withholding sentence left open and adds no rule of its own.

## What was undecided

`SEC-5` said at `dc43341` of a reported placement P: "After local-store loss nothing restores
P's ended reference: every job record from before the loss stays withheld for P, and a sheet's
`operator_reported_at` classifies no output." That sentence names no machine. The mark for an
ended placement without a report names its machines, "the `machine_states` entry of Q's machine
while that machine stays live and of every live machine the exposure ledger records in a bound set
with it", and says "After a
Restore, every job record from before the loss on a marked machine stays withheld, as it does for
a reported placement." Nothing said whether P's withholding reaches the same machines or every
machine.

## The shape chosen

**P's machine and its recorded peers.** After local-store loss, every job record from before the
loss stays withheld for P on P's machine and on every live machine the sheet's exposure ledger
records in a bound set with P's machine, whether P's machine is live or destroyed. A pre-loss
record on a machine that ledger never records with P's machine is not withheld for P; it owes
every other required reference and release prerequisite. The ledger read is the sheet's, which
`STA-16` fixes at its export ("**A restored sheet is knowledge as of export.**"), so a binding
made after the Restore withholds no older record for P.

**Unchanged.** The mark's setters, its machine scope and "nothing clears it" stand
([ADR-0060](./0060-a-machine-mark-keeps-an-ended-unreported-placements-older-output-withheld.md)).
A report stays final and is offered only while unarmed
([ADR-0062](./0062-the-lost-key-report-is-offered-only-while-unarmed-and-is-final.md)). A rotation
still never counts as a scan
([ADR-0061](./0061-a-rotation-keeps-the-old-placements-older-output-withheld.md)). `SEC-6`,
`STA-16`, `ARC-43` and the credential format are not touched.

## Why

Four independent readers answered; a fifth seat was unavailable. Two recommended this option and
two recommended every machine, and the owner chose this option. Three said the text forces no
answer and one said it does. Three said that before the loss P's reference governed output on a
bound set that included P's machine, and one said every machine's output.

`ARC-43` scopes the wait to the bound set: "Model `exec` across the bound set MUST wait while any
known required placement reference is unarmed." The chosen reach follows that scope after the
loss; this record does not decide which output an intact store's reference scans. A sheet carries
P's report only if it was exported after the report, and `STA-10` says "An entry is made at
**binding**", so that sheet's ledger holds the bindings its exporting store recorded. A binding
lost with an earlier store is missing from it, as it is from the mark's reach, since `STA-12` says
a restored ledger is "a **floor, not a census**". The every-machine option would withhold, after
every Restore from a sheet carrying P's report, on machines outside that recorded reach, which is
the cost ADR-0060 named when it did not select "Withhold every job record from before the loss on
every machine after any Restore". The P's-machine-only option would release A's record, although
`CNF-95(h)` specifies "machines A and M are in one bound set", "output on A is withheld", and
"every pre-loss job record stays withheld for P1".

**Narrowings and widenings.** This narrows the literal, unscoped reach of the earlier sentence
"every job record from before the loss stays withheld for P" to P's machine and its recorded
peers. No owner pick had fixed that reach: ADR-0057 decided "only later output for the reported
placement loses its scan" and said nothing of machines. It narrows and widens nothing in ADR-0060,
ADR-0061 or ADR-0062. `CNF-95(h)` specifies "machines A and M are in one bound set"; its
assertions are unchanged.

The minority's strongest argument: the restored ledger is "a **floor, not a census**" (`STA-12`),
so a missing ledger edge is no proof that a record lacks P's value, and a value carried from P's
machine to a peer and from that peer to a third machine is released for P. This record makes no
claim about whether that third machine's output was scanned for P before the loss.

## Alternatives considered

| Option | Disposition |
|---|---|
| Every machine | Not selected. It withholds on machines outside the sheet's recorded reach, after every later Restore, since a report is final. |
| P's machine only | Not selected. It releases a peer's record withheld for P while P was unarmed, and once P's machine is destroyed it withholds nothing for P. |

## Consequences

`SEC-5` and `CNF-95(k)` change together. The mark paragraph's "as it does for a reported
placement" stands. The formal companion has no placement or scan-reference state and is
unchanged.
