# The lost-key report is offered only while unarmed, and is final

Decided 2026-11-05 (`tw-5qs` comment 126000001, `tw-e42` comment 127000001). `ARC-43` owns the
report, its card and the wait it ends; `SEC-5` owns the scan boundary and row 23; `SEC-6` owns the
display; `CNF-42` and `CNF-95(h)` own the cases. This record closes two points ADR-0057 left open
and adds no rule of its own.

## What was undecided

`ARC-43` said at `e28bea5`: "Whether the report is offered while the placement's reference is
armed, and whether a report can be corrected or withdrawn, are not yet specified." The report was
chosen for the lost-key case, where the `exec` wait stands because a required reference is
unarmed. A reference armed by `digest_secret` or the local paste has no such wait, and nothing said
whether the card is offered for it. Nothing said either what an operator does after reporting the
wrong placement, or after learning that the service did not revoke the key.

## The shape chosen

**Offered only while unarmed.** The card offers the report only while that placement's required
reference is unarmed:
- The condition is "unarmed", not "lost-key": the harness tests whether the reference is armed.
- The state is read at the report's journal act. A re-arm journaled first refuses the report. A
  paste or digest record after the report arms nothing, as `ARC-43` already said.
- An armed reference keeps its scan until a rotation, destruction or local-store loss ends it.
  Once it is unarmed again, after a local-store loss for instance, the report is offered again.
- A placement whose key was revoked at its service while its reference is armed is ended by a
  rotation, once the placement gates admit that rotation, or by destruction. Model `exec` does not wait on an armed reference,
  so both routes can be reached.

**Final.** A recorded report cannot be corrected or withdrawn:
- A mistaken report stands, and the placement's reference stays ended. `SEC-5`'s "nothing
  re-creates them" and `ARC-43`'s "a paste or digest record arms nothing for it" hold as written.
  A Restore from a sheet that does not carry the report, one exported before it or a version 3
  to 6 sheet, still brings back the wait, as `ARC-43` and `CNF-95(h)` already said.
- The card says before the act that a report cannot be undone, and the trust display says so
  after it.
- After a mistake the operator may revoke the key at its service, rotate the placement through its
  placement gates, or destroy the machine. A rotation claims no revocation at the service, and none
  of these recalls output released after the report.
- Where the wrong placement was reported, the right one needs its own report, on the same terms,
  and the wrong one stays reported.

**Unchanged.** The report's effect, `SEC-5`'s scan boundary, `STA-16` and the credential format's
version-7 `report` member are not touched. The `reference_ended` mark, `CNF-84` and ADR-0061's "A
placement whose report already ended its reference loses nothing more at its rotation" stand.

## Why

Four independent readers answered; a fifth seat was unavailable. All four said the text forced
neither option on either question, and all four said the mark stays as written.

- **Offered only while unarmed** was accepted under the owner's 2026-11-05 panel rule, 3 of 4, with the reader that rule requires in the majority. It
  narrows `ARC-43`'s unconditioned "the operator may report that one placement revoked" to
  placements whose reference is unarmed. It narrows no owner pick: the report was decided for the
  lost-key case and the armed case was left open. It widens nothing. An armed reference still
  scans, so the report would trade a working scan for the operator's word where no wait needs
  ending.
- **Final** was accepted under the same rule, 4 of 4. It narrows and widens no owner pick. A
  withdrawal would widen "nothing re-creates them" and "arms nothing for it", and would change
  the version-7 sheet.

The minority's strongest argument on the first question: a revocation at the service is the same
fact whatever the local arming state, and a dead key stays listed live until the operator rotates
it or destroys the machine. Bead `tw-foh`, whether output after a rotation is still compared
against the old value, touches that point.

## Alternatives considered

| Option | Disposition |
|---|---|
| Offer the report while armed, as the same act | Not selected. It ends a working scan on the operator's word where no wait stands. |
| Offer it while armed with a different warning | Not selected, for the same reason. |
| Let a report be withdrawn while its placement is live, making its reference required again, unarmed | Not selected. It widens `SEC-5`'s "nothing re-creates them" and changes the version-7 sheet. |

## Consequences

`ARC-43`, `SEC-6`, `CNF-42` and `CNF-95(h)` change together, and ADR-0057 notes that both its
points are decided here. The formal companion has no placement or scan-reference state and is
unchanged.

*Partially superseded 2026-11-08:* [ADR-0075](./0075-report-correction-restores-future-protection.md)
replaces report finality with prospective correction; the unarmed-only offer remains.
