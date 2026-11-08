# Report correction restores future protection

Decided 2026-11-08 (`tw-qe7.11`), on the owner's instruction. This partially supersedes
[ADR-0062](./0062-the-lost-key-report-is-offered-only-while-unarmed-and-is-final.md)'s report
finality. Its unarmed-only offer and the finality of independent rotation and confirmed
destruction remain. This record adds no second rule.

## Decision and reason

A mistaken report can remove scanning for a credential that is still valid. Keeping that
mistake final leaves later output exposed even when the operator notices it. The chosen
prospective correction restores protection for future release while retaining the report as
history. `ARC-43` owns the action: "The operator MAY correct an uncorrected revocation report
for a placement not independently ended by rotation or confirmed destruction." Its durable
boundary is also there: "If the append fails, the previous report state, listing and release
behavior remain in force and the failure MUST be shown."

The benefit has limits. `ARC-43` says "It MUST restore a future required reference, initially
unarmed, before affected output can be released." `SEC-5` owns the scan boundary: "Any output
withheld before correction stays withheld, even after a successful fresh re-arm; output already
released is never recalled, recovered or erased." The interval without an active scan
requirement remains history, including any disclosure in that interval. A correction neither
proves service state nor reverses an external revocation.

Re-arm uses the digest and local-paste procedures in `ARC-43`, with fresh material and their
custody, minimum, fallback, cross-check and disposition limits. `ARC-43` says "A machine-derived
reference MUST be labelled **"re-armed from the machine's report"**, never "protected" or proof
that the original value was recovered." Machine-selected current bytes can differ from the
original secret. Local paste writes no machine file and repairs no inventory. Forgotten or
omitted placements and ledger edges remain missing.

## Widenings and partial reversal

The first change is the owner's instruction; the second was picked under the owner's panel rule:

- **SEC-5/ARC-43 re-arm widening and ADR-0062 finality reversal (owner-directed).** ADR-0062 retained SEC-5's
  then-wording "nothing re-creates them" and ARC-43's "a paste or digest record arms nothing
  for it", rejecting withdrawal because it widened those rules. Correction makes fresh digest
  and local-paste re-arm available for a corrected placement. It restores a protective
  requirement prospectively, without resurrecting retired scan material or independently ended
  placements. The report and its timestamp remain; its uncorrected finality is what is reversed.
- **TRU-E12: one-clause widening of R04's owners list.** The grant includes only its qualified
  report predicate, separately from the re-arm widening. `TRU-E12` owns listing "for as long as
  a live placement without an uncorrected operator report names that application on that machine".
  This restores visibility: the provider returns beside a sole corrected live placement even
  though its original report remains in history. Other application/provider policy is unchanged.
  ARC-43's matching predicate and the quotations in STA-16, CNF-84 and CNF-103 agree with it.
  A review panel picked this reading and its reach, three of four readers each with a fifth
  seat unavailable, accepted under the owner's 2026-11-05 panel rule. On the reading, the
  fourth reader found that the sources could not settle it; on reach, the fourth called the
  edit dependent in kind while agreeing that it needs this explicit grant.

The offer condition is retained: `ARC-43` says "The card is not offered for an armed reference".
Ordinary rotation keeps its placement gates, recording boundary, fixed end set and
possibly-unfinished-predecessor exception. Correction supplies no contact or runtime authority,
operation outcome, approval, retry, disposition change or barrier release.

## Recovery representation

The credential format's payload version 8 owns the narrow encoding. It retains `report`
unchanged, appends correction and subsequent report facts in `report_events`, and carries
`independent_end` so an independently ended reported placement cannot return live at Restore.
This supports repeated report/correction actions without a generic undo protocol. Retained
reports already carry their pre-loss withholding, so correction needs no additional machine
mark. `STA-16` owns preservation: "Export, Restore and replay MUST preserve the original report
and timestamp, each subsequent correction or report, and any independent end."

Version 7 has no correction encoding and does not establish whether a retained reported record
on a live machine was independently rotated. Its explicit conversion preserves that uncertainty
rather than granting correction eligibility. Versions before it retain their original validation
and conversions. Payload version 8, local correction evidence version 1, session journal format
2, derivation v1, sheet envelope v1 and local envelopes are separate versions. No value-derived
scan material enters the sheet, and no unrelated partial-history encoding is specified here.

## Alternatives

| Option | Disposition |
|---|---|
| Keep a mistaken report final | Rejected by the owner: it prevents restoration of future protection. |
| Clear or rewrite the report field | Rejected: it erases the original fact and reinterprets older sheets. |
| Reuse retired material or treat current machine bytes as the original secret | Rejected: it exceeds the reference's lifetime and provenance. |
| Release the withheld backlog or claim already released output recovered | Rejected: correction supplies no retrospective protection. |
| Keep the sole corrected placement's provider hidden because a literal report remains | Rejected: it understates live exposure; the predicate belongs to TRU-E12. |

## Consequences

ARC-43, SEC-5, SEC-6 and STA-16 carry the action, scan boundary, display and recovery duties;
TRU-E12 changes only its report predicate. The credential format and CNF-42, CNF-84, CNF-95 and
CNF-103 carry the dependent shape and demonstrations. These textual obligations claim no
integrated execution. The inspected formal declarations under ARC-43 cover pin sources and
reboot settlement; those under STA-16 cover restored-pin verification. None represents placement
or scan-reference state, so no Lean declaration, theorem, assumption, witness or marked region
changes for this amendment.
