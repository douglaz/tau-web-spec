# First placements are recorded before send and completed attempts rotate together

Partly decided 2026-11-06 (`tw-x7k` comment 142000001). `ARC-43` owns the ceremony, listing
and wait; `SEC-5` owns which placements a rotation ends, their scan boundary and the mark;
`SEC-6` owns the display; the credential format owns the sheet; `CNF-95(l)` and `(m)` own
the new cases. This record adds no rule of its own. The disposed-attempt question below
remains open.

## What was undecided

ADR-0063 left open what ends an unsuccessful rotation attempt's new placement while the
store stays intact, and what a failed first placement does to its listing, reference and
export. `ARC-43` says "A rotation's new placement is listed from the record made before its
bytes leave, whatever its job then does". A nonzero exit can therefore leave both the old
placement P and the attempted new placement N1 locally required, while a later attempt
adds N2. The paragraph's former "the new placement's reference is required alone" did not
identify a rule ending N1. The credential format separately says "a rotation that is never
recorded leaves its new placement on no sheet"; losing that knowledge on Restore does not
establish an end while the store stays intact.

The same format says "A placement without a report is live: the export writes it until its
secret is rotated or its machine is destroyed", but had no first-placement start. ADR-0063
left that start open. A first attempt has no older record competing for its sheet position.

## The accepted cores

**A first placement starts before its bytes leave.** `ARC-43` now says "A first placement is
listed, and its reference required, from the approved record made before its bytes leave,
whatever its job then does." The credential format starts its export at that record too.
A failed first job can have left bytes at its destination; excluding the only known
placement would lose that path on every later sheet. A later attempt at the recorded
machine, application name, secret name and path is a rotation there even if the earlier
job never succeeded, and uses the rotation's existing export delay. A completed first
attempt's unreported record is replaced only by a recorded rotation, keeping the existing
importer's refusal of two records without a report at that tuple.

**A recorded rotation ends additional completed attempts at that destination.** `SEC-5`
now says "The same journal act also records the rotation of every earlier still-live
placement without a report" and qualifies the set by the exact machine, application name,
secret name and path, and by a completed root-only job record admitted before the later
rotation's pre-send record. Journal order identifies earlier attempts; neither placement
times nor matching values identify this set. A completed nonzero attempt followed by an
admitted zero-exit rotation is the ordinary case. The act records each additional
placement's rotation, so the existing boundary and mark apply to each. `SEC-5` says "A
rotation never counts as a scan: bytes withheld before it stay withheld".

The card names each placement it would end. The card and display warnings cover every
additionally ended value: `SEC-5` says "The no-revocation and no-erasure limit applies to
every value whose reference the act ends." No failure or disposition alone ends a
placement, and a later digest never replaces an intact reference.

## Why and decision limits

Four independent readers answered; a fifth seat was unavailable. Each accepted core was
recommended by all four, and is accepted under the owner's 2026-11-05 panel rule:

- first-placement listing and required reference from the approved pre-send record;
- first-placement export from that record, independently of the listing choice;
- a later attempt at that same recorded destination is a rotation there;
- ending the earlier completed attempts with the later recorded rotation, under the
  qualification above, and applying the rotation boundary to each end.

The first-placement rules fill the gap ADR-0063 left open. The additional ends widen what
one rotation records under ADR-0063 and shorten those references' lifetime at that act;
ADR-0061's withholding boundary and ADR-0064's disclosure now cover every ended attempt.
ADR-0060's mark reaches each additional unreported end, including an earlier unreported
attempt when P already has a report. No schema or mark field changes. ADR-0062's report
eligibility and finality, ADR-0067's reported-history reach and ADR-0068's armed-reference
explanation keep their decisions. ADR-0063's recording act and its exclusion of an
unrecorded rotation attempt from export keep theirs.

## Open: a disposed attempt that may still be running

Whether a later rotation also ends a disposed attempt when no completed root-only job
record was admitted before that later rotation's pre-send record remains undecided.
Three readers recommended ending it too, and one recommended retaining it: a disposition
does not prove the old job stopped, so it could write after the replacement. The minority
is the reader the panel rule requires for non-unanimous acceptance; this question goes
to the owner. Their shared option heading did not settle this semantic difference.

The sheet consequence is part of that question. If the disposed attempt was a first
placement, its record is on the sheet. The retaining recommendation also delays exporting
the successor until the retained first placement ends; the other recommendation replaces
that record at the later recorded rotation. Neither consequence is chosen here.

The following also have no decision here: a proposed exception exporting a reported failed
rotation attempt despite ADR-0063's no-sheet rule; an additional failed-job display label;
and a separate concern about older conformance wording. They are outside the accepted
cores, rather than amendments hidden in them.

## Consequences

`ARC-43`, `SEC-5`, `SEC-6`, the credential format and `CNF-95` change together. The cases
cover nonzero first attempts, unresolved and disposed first attempts without a successor,
completed-attempt consolidation, failed appends, tuple isolation, output boundaries and
Restore. The disposed-attempt successor history awaits the owner. This is a partial
amendment; `tw-x7k` stays open. The formal companion has no placement/reference state,
and this change supplies no formal or runtime evidence.
