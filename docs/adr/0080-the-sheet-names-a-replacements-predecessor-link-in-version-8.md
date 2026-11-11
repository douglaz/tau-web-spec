# The recovery sheet names a replacement's predecessor link: an owner-directed amendment of payload version 8

Decided 2026-11-10 on the owner's instruction, after a review panel of five readers in two rounds.
Round one's counts are `tw-lgf` comment 270000001; round two's counts and the owner's picks are
comment 260000001. This is an owner-directed amendment of the credential format's payload
version 8 in place. It adds format rules and loosens no requirement; it widens what import accepts
in one place and narrows which entries carry the old "entry/predecessor metadata", both named
below. `STA-22b` owns the replacement act and its link; the credential
format's recovery sheet owns the members; `CNF-72` and `CNF-84` own the cases.

## What was undecided

The text promised the link but gave it no wire shape. `STA-22b` says "Replay, export and import
preserve the predecessor link and these restrictions without redispatch." The credential format,
as it stood before this change (commit `409ee91`), said that a replacement entry names "the
retired entry's approved-entry identity and its Failed allocation", that "The link is carried in
the existing entry/predecessor metadata", and that each retired Failed allocation is exported
"with its consumed index and entry/predecessor metadata, so a replacement entry's predecessor link
(`STA-22b`) still resolves". No member of `allocations` or of a retired entry carried that
metadata, and import refused "an extra member" on a retired entry. A sheet holding a replacement
could not be written as specified, and an importer had nothing that tied a replacement to its
Failed predecessor or named either approved entry (five of five in round one).

## The shape chosen

- **Where.** Every machine entry that stands for an approved entry, in either list, carries two
  members, `entry` and `predecessor`, as the link, `"none"` or `"unknown"`; passes and handoffs
  carry none (four of five in round two). Which other records carry none is resolved in drafting
  (below): the draft names each machine allocation in `allocations` other than a reserved
  migration index, and each machine entry in `retired_allocations` other than a superseded
  reservation or a pending removal.
- **`entry`.** The approved-entry identity as an opaque id, `{"id":"<A>"}`, carried at both ends of
  a link, the Failed target included, or `"unknown"` for a converted entry. Import requires the
  link's id to equal its target's (owner's pick, "Matching ID on both"). It is neither the
  protected-evidence `approved_entry` form nor rebuilt from the allocation index (five of five in
  round two).
- **`predecessor`.** `"none"`, `"unknown"` after conversion, or the backward link on the
  replacement's own allocation: the Failed allocation's `seed_id` and `machine_index` (five of five
  in round one), plus the retired entry's id (four of five in round one). There is no successor
  pointer (five of five in round one), and a replacement later replaced keeps its own link.
- **Failed mark.** A current-seed machine allocation the journal records as Failed carries
  `failed: true`, as `destroyed: true` is stated (five of five in round two). The format had
  defined it only on retired entries and assumed it elsewhere; the "target is Failed" check needs
  it.
- **Migration.** Replace's migration gives the machine's new allocation under the fresh seed its
  members unchanged, so the link still names its target by the retired seed and index (five of
  five in round two).
- **Refusals before binding.** A link to no entry in either list, a target that is not Failed, a
  self-link, wrong types, and a missing, extra or duplicate member inside the link (five of five in
  round one); either member on a record that does not carry it, and a cycle (four of five in round
  one). The id match is the owner's pick above. The draft defines the cycle over machine entries,
  following each link to the Failed allocation it names, and adds no refusal of differing links
  among one entry's allocations.
- **Older data.** Versions 3 to 7 convert with both members `"unknown"`, never `"none"` (four of
  five in round one), and later exports keep them.
- **Two replacements of one Failed entry.** No refusal (owner's pick, "Don't add a check"). The
  format says that several links may name one Failed allocation, as it says of its other links.
- **Authority.** The members grant none (five of five in round one).

## Version: amended in place

The owner picked "Fix version 8", over a version-9 bump, after the panel split three to two. This
follows the in-place amendments of payload version 7. ADR-0058 gave as its ground that version 7
was added the same day, that "its text marked these members not yet specified", and that "no
fixture, tool or prototype in the repository writes a recovery sheet". ADR-0059 gave the last two,
and ADR-0060 and ADR-0066 only that nothing in the repository writes a version-7 sheet. Here the
text-marking ground differs:
version 8's text did not mark the link unspecified, it promised the link without encoding it. The
consequence is the same, since no version-8 sheet holding a replacement could be written as
specified, and a version-8-to-9 conversion would have supplied nothing.

Re-checked at landing, 2026-11-11: nothing writes a version-8 sheet. This repository holds no
sheet writer in its tools, workflows or prototypes. The implementation repository (`tau-web-rust`, `main` at
`c01f980`) has its recovery-sheet export ticket, "Exporting and importing the recovery sheet",
still open, and its source names no `retired_allocations`.

## What this adds and widens

Each quote is the text as it stood before this change (commit `409ee91`).

- **Widened, by name:** the retired-entry import refusal "an `outstanding` object with a missing,
  extra or duplicate member, and an extra member" now admits, in version 8, `entry` and
  `predecessor` on a machine entry that version 8 requires to carry them, and `CNF-84`'s "a
  malformed, duplicate or extra-member entry" reads the same way. Import now accepts a retired
  entry it refused before this change. On a pass, a handoff, a superseded reservation or a pending
  removal, and on any entry of a version-3-to-7 payload, either member is still refused.
- **Narrowed, by name:** the format's "its entry/predecessor metadata" stood on every retired
  entry, passes and handoffs included. It is now the two named members, and only on a machine
  entry other than a superseded reservation or a pending removal; a pass, a handoff, a superseded
  reservation and a pending removal now carry no such metadata. The format's "appear only on a
  machine" list gains the two members.
- `allocations` gains the two members on a machine allocation other than a reserved migration
  index, and states `failed: true` on a Failed machine allocation.
- Import gains the refusals listed above, and conversion from versions 3 to 7 gains the two
  `"unknown"` values.
- Replace's migration states that the members move to the machine's new allocation.
- `STA-22b` gains a pointer to the member. `CNF-72` gains the export of the link after the
  replacement act, and `CNF-84` the round trips, the conversion and the refusals.

## Resolved in drafting

Round two left two points open for the draft, unvoted, the second in two parts. The draft resolves
them as follows. The first resolution is consistent with the settled text but not forced by it;
the other two follow from it.

- **Records that are not machine entries.** A reserved migration index, a superseded reservation
  and a pending removal carry neither member, and import refuses either on them. The format already
  says each is "not a second machine", that a migration index's allocation has no record naming it,
  and that a pending removal "names a key and not the machine"; round one refused the member on a
  record it does not apply to (four of five). The machine's own entry carries its members, and the
  migration act gives the reserved index the members when the machine moves to it.
- **Several links naming one Failed allocation.** Stated as accepted, since the owner picked no
  refusal and the format states multiplicity for `reservation_of` and `removal_of`.
- **A replacement entry with more than one allocation.** Every allocation of the replacement entry
  carries the same link. The link is entry metadata: the format says a replacement entry "names, as
  its predecessor, the retired entry's approved-entry identity and its Failed allocation", and
  `STA-22b` admits "the approved replacement entry with its own reserved index, linked to the old
  entry as its predecessor". A later attempt at the replacement entry adds no predecessor:
  `CNF-72` says "A later Failed attempt at an entry neither grants a successor nor blocks contact to
  its older actual machine".

## What stays

- `STA-22b`'s duty is unchanged; its text gains a pointer to the member.
- The wrong-server record's member stays undecided: the format still said "Which member of the
  entry's allocation metadata carries it, under which payload version, is not decided" (kept apart,
  five of five in round one). ADR-0081 later settled it for a retired-seed entry.
- The formal companion, the credential vectors and their checker, derivation version 1, the sheet
  envelope and its AAD are unchanged (five of five in round one). No theorem, gate or assumption boundary moves.
- `CNF-72`'s link "names exactly the retired entry's approved-entry identity and its Failed
  allocation, and no other" is unchanged; the id match lets import check it.

## Alternatives considered

| Option | Disposition |
|---|---|
| Bump to payload version 9 | Not chosen by the owner. Earlier payload extensions each took a new version number; here the conversion from version 8 would supply nothing, since no conforming version-8 sheet holding a replacement exists. |
| Leave the identity's encoding undecided | Not chosen by the owner. A sheet holding a replacement would stay unwritable. |
| The protected-evidence `approved_entry {setup,index}` form | Rejected (five of five in round two): its `setup` is an approval journal number the sheet does not carry, so import could check it by form only. |
| Refuse two replacements naming one Failed entry | Not chosen by the owner (four to one against). `STA-22b` says "An allocation already Failed in this journal needs only the retirement and the admission", and a second attempt at one entry may reserve another index. |
| The member only on a replacement | Not selected (four of five in round two for every machine entry). Absence could not record "unknown" for converted data on a later export. |
| Retract the promise, or call the link already carried | Rejected (five of five in round one). |
