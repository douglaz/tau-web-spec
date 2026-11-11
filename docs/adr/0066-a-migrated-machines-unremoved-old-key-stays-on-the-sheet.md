# A migrated machine's unremoved old key stays on the sheet as a pending removal

Decided 2026-11-05 (`tw-p2q` comment 134000001). `STA-17` owns Replace, its migration, the old
key's removal and its screen; `STA-22b` owns the journal's retired-seed entries and the one import
exception; the credential format's payload version 7 owns the sheet; `CNF-20` and `CNF-84` own the
cases. This record adds no rule of its own.

## What was undecided

`STA-17` says of a dedicated machine's relabel "that is when the shown installation id (`STG-20`)
MUST move to the new index, never before the disk does, and only after that may the old key be
removed". So the migration act comes first and the removal after it. The credential format, as it
stood before this change (commit `d94429c`), said of that act "The same act ends the machine's
retired-seed entry and every superseded reservation naming it (below), so no journal state, and no
export, names one machine under two seeds", and "A migrated machine has no entry." Between the act
and a confirmed removal the old key was still installed, and nothing on the new seed's sheet
recorded it, its seed or its old index. After a Restore from that sheet the harness could neither
tell that a retired key was still on the machine nor finish its removal: the retired seed alone
derives nothing without the old index. The read-confirmed branch of a later Replace had the same
gap for the machine's original key, and every superseded reservation's key had it too.

## The shape chosen

**A pending removal keeps each unremoved key.** The migration act, and a later Replace's
read-confirmed act, end the machine's retired-seed entry and its superseded reservations as machine
entries, and keep each of their keys as a pending removal: an entry in `retired_allocations` under
the seed and index the key was allocated under, with family `machine`, the machine's stable
resource identity, the recorded key and `outstanding` with reason `"old_key_unremoved"` and a
`removal_of` naming the machine by its current name. That name is a machine in `allocations` or,
while a later Replace has not yet migrated the machine, an outstanding retired machine entry. Like
a superseded reservation it is not a second machine: no record names it, and it has no machine
state or artifact history. Several may name one machine. A later migration of the machine moves
each link to its new name in its one act.

**Removal is confirmed by a read.** `STA-17` owns the removal and its ending. The removal runs over
the connection authenticated by the machine's own current key once that key has passed its own
check: derived and compared for a machine of the payload's seed, and the deferred check, which
needs that machine's own seed, for one still under a retired seed. It takes out exactly the
recorded key. A durably appended read showing that key absent ends the pending removal. The act
that records the machine's deletion evidence ends it too, as the machine's destruction rather than
the key's removal; the pick names both endings.

**Replace stays incomplete.** While any pending removal stands, Replace and revocation are reported
incomplete, across restart, export and Restore.

**Restore.** Import accepts the pending removal's recorded key without deriving it, under the
existing one exception, and restores from it no allocation, record, contact identity or binding. A
Restore removes nothing by itself. After it, the removal is a step of Replace's flow, admitted once
`STA-20` and `STA-24` allow it, and it runs the same with or without the seed the key was allocated
under, since it derives nothing from it.

**Version.** This amends payload version 7, as ADR-0058 and ADR-0059 did, on ADR-0059's ground
that nothing in the repository writes a version-7 sheet.

## Why

The text forced none of the three options, but it excluded one. Removing the old key before the
migration act conflicts with `STA-17`'s "only after that may the old key be removed". Leaving the
key off the sheet and stating the limit on the screen would leave a Restore unable to identify the
key, so it would stay a working way in, which is what Replace exists to end: `STA-17` says
"changing what the browser uses is not removing a thief's access". The pending removal reuses the
superseded reservation's shape, whose recorded key already "serves only its removal from the
machine it names, which re-entry makes with the machine's own key". The recorded key is never
contact authority: every key the harness contacts a machine with is still derived and compared, or
waits for `STA-22b`'s deferred check, so that check is not weakened.

## What this narrows and widens

The owner accepted these by name under the 2026-11-05 panel rule. Each quote is the text as it
stood before this change (commit `d94429c`):

- the format's "A migrated machine has no entry" narrows to no entry that stands for the machine;
- the format's "The same act ends the machine's retired-seed entry and every superseded reservation
  naming it", `STA-22b`'s "Replace's migration ends a machine's retired-seed entry and its
  superseded reservations" and ADR-0059's "The act that migrates or destroys the machine ends its
  superseded reservations" narrow on the migrate side: the act ends them as entries that stand for
  the machine and keeps their keys. The destroy side holds, and the format's "The same act ends
  every superseded reservation naming it, as the act that migrates the machine does" now rests on
  the destroying act alone;
- the read-confirmed act, `STA-17`'s "showing that index's id confirms that migration in one
  journal act", the format's "confirms the migration to that index in one journal act, as above"
  and ADR-0059's "A read showing the reserved index's id confirms that migration", now also keeps
  the machine's original key, and each superseded reservation's key naming it, as a pending removal;
- `STA-17`'s "Re-entering a machine to remove the old key uses the old key" narrows to re-entry
  before migration; after it, removal runs over the machine's current key. So "needs its backup
  *during* Replace and abandons it after the last step below that needs it" no longer counts that
  removal among those steps;
- a pending removal has two endings, both in the pick: the read, and the act that records the
  deletion evidence of the machine it names;
- the format's `retired_allocations` "holds exactly the allocations the journal keeps under a seed
  other than the payload's" and `STA-22b`'s keep list widen to the pending removal;
- the format's "one of the two repeated mappings import accepts" widens to a third, and the format
  no longer writes the count;
- the format's `reservation_of` target "that is not itself a superseded reservation" narrows to
  exclude a pending removal too;
- the format's "nor does a reserved migration index (above)", on `machine_states`, widens to a
  superseded reservation and a pending removal;
- import gains refusals for a `removal_of` naming a reserved migration index or a machine whose own
  key equals the recorded key;
- `STA-17`'s completion refusal widens to name a pending removal, and its screen names it by its
  machine and its key's seed;
- `CNF-84`'s "the act that migrates or destroys the machine ends it" changes on the migrate side;
- ADR-0056's rescue rekey keeps its own rule, "removes the exact old public key that checked
  retained records identify", for that flow. This removal takes a recorded key without deriving
  it; if "checked" there means derived and compared, that narrows it for this removal (comment
  134000001). (Amended 2026-11-11 by
  [ADR-0083](./0083-old-key-removal-reads-cover-the-login-route-and-the-rescue-pass-takes-the-ceremony-destination-rules.md),
  an owner-directed amendment: that flow's removal is now kept as a pending removal of this
  record's kind, at the seed and index of the retired-seed entry naming the key, and ends as one
  does, and it is narrowed to a key a retired-seed entry names. The read that ends any pending
  removal must now cover every sshd authorization source for the accounts on the machine's login
  route.)

Held: "no journal state, and no export, names one machine under two seeds", since a pending removal
names a key and its link points one way, to the machine's current name; ADR-0058's "the recorded
key is never contact authority by itself"; ADR-0053's rejected row "Replace complete only if the old
machine's old public key was removed before the stop", which concerns the LNVPS rebuild's old
machine, which the rebuilding Replace never migrates. An earlier Replace may have migrated that
same machine and left its old key pending removal, linked to it, and `CNF-20` checks that the stop
is refused "while a re-entry of that machine, or a removal of its old public key, is still to complete".
(Editorial qualification, 2026-11-11: this sentence first said only that the old machine "never
migrates". It adds and removes no rule.)

## Alternatives considered

| Option | Disposition |
|---|---|
| Remove the old key before the migration act | Not selected. It conflicts with "only after that may the old key be removed", and an early removal followed by a failed append leaves the retired entry holding a key that no longer opens the machine. |
| No sheet record, and a screen statement of the limit | Not selected. A Restore could not identify the key, and nothing would keep Replace incomplete after it. |
| Derive and compare the recorded key from the retired seed before removing it | Not selected. Removal is not contact, and requiring the seed would keep its backup needed and leave a Restore without it unable to remove the key. |

## Consequences

`STA-17`, `STA-22b`, the credential format's payload version 7, `CNF-20` and `CNF-84` change
together. The formal companion is unchanged: its allocation module omits Replace's re-entry and the
sheet's import checks, and nothing here allocates an index. No theorem or gate changes.
