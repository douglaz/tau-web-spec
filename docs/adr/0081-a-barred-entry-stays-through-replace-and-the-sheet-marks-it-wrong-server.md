# A barred entry stays through Replace and the sheet marks it `wrong_server`: an owner-directed amendment

Decided 2026-11-10 on the owner's instruction ("Adopt it"), after a review panel in two rounds.
The counts and the owner's pick are `tw-74f` comment 262000001 (row 21). This is an
owner-directed amendment. It amends the owner's 2026-11-05 pick to leave the point undecided
(`tw-4mz` comment 167000001), widens two rules by name (below) and amends the credential format's
payload version 8 in place. `STA-17` owns the wrong-server record, Replace and its screen;
`STA-22b` owns the journal's retired-seed entries; `STA-16` owns what the sheet carries; the
credential format owns the reason; `CNF-20`, `CNF-84` and `CNF-117` own the cases.

## What was undecided

The rescue rekey lets the operator record that an entry its card created names the wrong server.
The record bars the entry for good and "survives export and Restore with it". Before this change
(commit `397f88f`), the text said that "How a Replace and the sheet's list of machine states treat
an entry so barred is not decided, including whether the journal and the new seed's sheet keep the
entry through a Replace". The credential format added: "Which member of the entry's allocation
metadata carries it, under which payload version, is not decided." So a Replace could drop the
entry, and with it the bar and the protected-evidence admission refusal that stops a new card for
the same server. Nothing said whether Replace could report complete while the screen still showed
a key possibly written to that server.

On 2026-11-05 the owner chose to leave this undecided, after an earlier panel found no majority
(comment 167000001). That pick predates the panel sort that put the point back on the list
(`tw-74f` row 21). The owner then picked "Pursue it, panel first" and, after the design panel,
"Adopt it".

## The shape chosen

- **Kept through every Replace.** The journal keeps the barred entry under the seed it was
  allocated under, with its bar, index, mapping, history, intents, unresolved calls and scoped
  host-key read. No Replace migrates it, and Replace's screen shows it barred and not migrated
  (five of five in round one). Keeping it in the journal only was rejected: the protected-evidence
  refusal and the bar would be lost after a Restore.
- **Incomplete while a not-undone item stands.** While the screen shows any item the harness may
  not have undone on that server, Replace and revocation stay reported incomplete, across restart
  and export (five of five in round one).
- **The sheet carries the bar as a reason.** The new seed's sheet carries the entry in
  `retired_allocations` with the closed reason `"wrong_server"`. There is no intent or summary
  member (four of four in round two). After a Restore, every entry the sheet carries with that
  reason holds Replace and revocation incomplete, since the sheet carries no intent (four of four).
- **What clears an item.** No item ends on the operator's word, an acknowledgement of the screen
  or an export. Only admitted, durably recorded evidence of that item's end could end it, and the
  text names none for any of the four items (core four of four in round two; the token vote was
  three to one, and the lone reader's sentence has the same effect, so it was recorded as
  compatible wording). A read the bar allows resolves a call and ends no item. So for a barred
  entry with any item, Replace and revocation stay incomplete until a later rule names evidence
  that ends it.
- **Authority.** The reason restores no authority. A passing deferred check admits none of what
  the bar refuses, and the entry is never migrated.

## Version: payload version 8 amended in place

This follows ADR-0080, which amended version 8 in place on the owner's "Fix version 8" pick
(`tw-lgf`) on the ground that nothing writes a version-8 sheet. Re-checked at drafting, 2026-11-11:
that ground still holds. This repository's tools, workflows and prototypes write no sheet. The
implementation repository (`tau-web-rust`, `main` at `c01f980`) still has its recovery-sheet
export ticket, "Exporting and importing the recovery sheet", open, and its source names no
`retired_allocations`. The text does not force a new number. No version-8 sheet could carry a
barred retired entry as specified, since the text left the carrier undecided, so a version-8-to-9
conversion would supply nothing. Versions 3 to 7 have no such reason: import refuses it there as
an unknown reason, and conversion gives it to no entry.

## What this widens and amends

Each quote is the text as it stood before this change (commit `397f88f`).

- **Amended, by name:** the owner's 2026-11-05 pick to leave the treatment undecided (comment
  167000001). `STA-17`'s "is not decided" sentence is replaced by the rule above.
- **Widened, by name:** after a Restore, the incomplete hold covers a bar with no intent. Live,
  the screen shows an item "only when the journal holds the intent of the call or job behind it",
  so a bar recorded before any intent shows none and holds nothing. After a Restore from a sheet
  that carries it, the same entry holds Replace and revocation incomplete. This can over-withhold;
  it cannot report complete for a marked entry (four of four in round two).
- **Widened, by name:** import now accepts the machine reason `"wrong_server"` on a version-8
  retired entry, which it refused before as "an unknown reason". Version 8's scope note says so.
- `STA-22b`'s keep list, `STA-16`'s sheet contents, `STA-17`'s list of what the new sheet
  carries and the format's `retired_allocations` list each gain the barred entry.
- The format's open sentence narrows: after a Replace the record is the reason. Which member of a
  current-seed allocation's metadata carries it, and under which payload version, is still not
  decided (four of four in round two left the carrier open).
- `CNF-20` gains the Replace runs, with and without an item, before and after a Restore. `CNF-84`
  gains the round trip and the version-3-to-7 refusal. `CNF-117` (m) points to them, and (n)'s
  card refusal holds after a Replace and a Restore.

## Resolved in drafting

- **Live completion with no item.** The round-two design names the widening as the no-intent case
  after a Restore. The draft therefore states that, live, the bar alone does not hold Replace
  incomplete when the screen shows no item. This follows from the settled text; it is not a new
  choice.
- **The scoped read.** It stays journal-only (`SEC-5` row 5), so a Restore still loses it as an
  input that withholds. That limit is unchanged.

## What stays

- The bar itself, its refusals, and the known limit of a sheet exported before the bar, which
  restores the entry without it.
- `STA-24`'s barrier over the entry's unresolved calls, and the reads that resolve them.
- The formal companion carries no such record. No theorem, gate or assumption boundary moves (five
  of five in round one).
- The credential vectors, derivation version 1, the sheet envelope and its AAD.

## Editorial fix in ADR-0066

The same batch qualifies ADR-0066's "the LNVPS rebuild's old machine, which never migrates" to the
rebuilding Replace: an earlier Replace may have migrated that machine and left its old key pending
removal, which `CNF-20` checks. A review panel recorded it as editorial, four of four (`tw-74f`
row 31). It adds and removes no rule.

## Alternatives considered

| Option | Disposition |
|---|---|
| Leave it undecided | The owner's 2026-11-05 pick, now amended by the owner's "Adopt it". |
| Keep the entry in the journal only | Rejected (five of five in round one). A Restore would lose the bar and the admission refusal. |
| A summary member listing the items not undone, with a new payload version | Not selected (four of four for the reason only in round two). It is safe only if an absent, older or malformed summary never reads as "no effects", and an encoding fault there yields a false complete. |
| Let the reads the bar allows clear items | Rejected (four of four in round two). The bar allows only "the reads that resolve its calls still unresolved", and resolving a call leaves its intent. |
| Bump to payload version 9 | Not taken. The owner's "Fix version 8" ground still holds, and the text does not force a bump. |
