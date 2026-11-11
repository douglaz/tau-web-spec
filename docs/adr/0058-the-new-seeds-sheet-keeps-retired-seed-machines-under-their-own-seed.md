# The new seed's sheet keeps retired-seed machines under their own seed

Decided 2026-11-05 (`tw-1wq` comment 113000001). `STA-17` owns Replace, its migration and its
screen; `STA-22b` owns the journal's retired-seed entries and the one import exception; `STA-16`
and the credential format's payload version 7 own the sheet; `CNF-84` owns the cases. This record
extends ADR-0057's sheet decision and adds no rule of its own.

## What was undecided

Comment 110000001 carried, after Replace, a destroyed machine that a reported placement record
names, under the seed it was allocated under. The credential format then said: "How artifact
history, host pins, installation groups and exposure-ledger entries name a machine allocated under
a retired seed is not yet specified, and neither is what the new seed's sheet holds for a live
machine that Replace leaves unmigrated." Until that was written a Replace export could fail its own
import, and `CNF-84` says "no export can write a sheet its own import refuses". Three cases had no
sheet form:

- a destroyed retired-seed machine whose records other than a reported placement name it by a bare
  index, which `STG-20` says "can coincide with a migrated machine's new index";
- a live machine Replace leaves unmigrated, which `STG-20` keeps "under the retired seed" until
  Replace migrates it;
- an LNVPS rebuild's old machine awaiting its deletion evidence, which the rebuilding Replace
  never migrates. (Editorial qualification, 2026-11-11: this item first said only that the old
  machine "never migrates". An earlier Replace may have migrated that same machine, as `CNF-20`
  checks. It adds and removes no rule.)

## The shape chosen

**Naming.** Every record that names a machine names it by `seed_id` plus `machine_index`, with no
default seed: placements, artifact history, machine states, host pins, installation groups and
exposure-ledger references, a recorded bound set's included. A missing seed is refused, never read
as the payload's.

**Retention.** Every destroyed retired-seed machine the journal keeps stays on every later sheet
with all its kept records, whether or not a reported placement names it.

**A live retired machine.** A machine Replace has not migrated, a jump host and an LNVPS old machine
included, stays on the new seed's sheet as a live allocation under its retired seed, with its
machine state, its other records and the reason the screen names it not yet migrated. Import
accepts its recorded key without deriving it, but before any contact, vendor read or call under its
identity, or binding, the harness derives the key from the retired seed the operator supplies and
compares it. The check is deferred, not waived. A passing check reconnects under the existing pin.
The machine is marked destroyed in one journal act when its deletion evidence is durably recorded.

**Cases the readers raised**, written in with the picks:

- a retired relay pass stays on the sheet while `STA-17`'s screen names it unrevoked or awaiting
  its manual retirement's confirmation;
- a retired Failed allocation stays as a tombstone, so a replacement's predecessor link resolves;
- a machine whose new index is reserved but whose migration is unconfirmed, as after a failed
  relabel read, keeps its retired-seed name, and the reserved index is linked to it as its
  migration index, not a second machine;
- migration is one journal act that moves the entry and every record naming it;
- after a Restore, a machine migrates only to a migration index its sheet records, since an
  imported seed allocates nothing; otherwise it waits for another Replace, which keeps every
  earlier retired seed's entries;
- the sheet holds no key, so a Restore from the sheet without the retired seed runs no deletion
  check for an LNVPS old machine (`SEC-4`).

**Version.** This amends payload version 7 rather than adding version 8. Version 7 was added the
same day, its text marked these members not yet specified, and no fixture, tool or prototype in
the repository writes a recovery sheet.

## Why

A bare index is ambiguous once a retired-seed index can equal a migrated machine's new index, and
a default seed would read a missing member as a value, which the format refuses for a machine
state. Keeping every destroyed machine's records, not only those a report names, keeps `STA-16`'s
"MUST survive export and Restore" whole for each destroyed machine. A live unmigrated machine
already has a home in the journal, so the sheet carrying it is what keeps Replace's own export
restorable; dropping it would lose the machine's state and pins at a Restore. Deferring the key
check keeps `STA-22b`'s "derives each listed public key and compares it" for every allocation that
is ever contacted: the recorded key is never contact authority by itself.

## What this widens

The owner accepted these by name under the 2026-11-05 panel rule. Each quote is the text as it
stood before this change (commit `7998147`):

- comment 110000001's "for that allocation only" widens to live retired machines and to destroyed
  retired machines no reported record names;
- `STA-22b`'s one exception covers every retired allocation the sheet carries, and for a live one
  the check is deferred to before contact;
- `CNF-84`'s refusals of "`destroyed` absent or other than `true`", of an entry "no placement
  names" and of "a record without a report naming one" give way to the accepted cases;
- the format's "Only a placement record names a retired allocation" and its retired allocation
  with no `machine_states` entry give way to seed-qualified records and a live retired machine's
  state;
- `STA-22b`'s journal keep "while a reported placement record names it" widens to every
  retired-seed entry the journal keeps.

## Alternatives considered

| Option | Disposition |
|---|---|
| Keep a destroyed machine only while a reported record names it | Not selected. It drops kept records a destroyed machine's history needs. |
| A separate encoding whose absent seed means the payload's | Not selected. A missing member would be read as a default. |
| Move the machine to a reserved new-seed index before the disk moves | Not selected. `STA-17` moves the shown identity "never before the disk does", the rebuilding Replace never migrates the LNVPS old machine, and the record would carry a key the machine never held. (Editorial qualification, 2026-11-11, as in the list above: this first said only that the old machine "never migrates".) |
| Keep the machine only on the retired seed's last sheet | Not selected. Comment 110000001 rejected that for the same reason: no later sheet extends it. |
| Leave the machine off the new sheet until its migration finishes | Not selected. Replace's export is one of its finished steps, and a Restore from it would lose the machine. |

## Consequences

`STA-16`, `STA-17`, `STA-22b`, the credential format's payload version 7 and `CNF-84` change
together. The formal companion is unchanged: its allocation module omits the sheet's import checks and
Replace's re-entry, and nothing here allocates an index. Still to be decided, since decided in
[ADR-0059](./0059-a-retired-seed-handoff-stays-and-a-pending-migration-index-is-superseded.md):

- what the new seed's sheet holds for a handoff allocated under a retired seed;
- what a later Replace does with a migration index whose reserved allocation is under the seed
  that Replace retires.
