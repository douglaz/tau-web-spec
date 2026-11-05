# A retired-seed handoff stays under its seed, and a pending migration index is read, then superseded

Decided 2026-11-05 (`tw-rds` comment 115000001). `STA-17` owns Replace, its migration, its screen
and the retired seed's backup; `STA-22b` owns the journal's retired-seed entries and the one import
exception; `SEC-5` rows 15 and 17 own the seed's and the post-harness credential's lifetimes; the
credential format's payload version 7 owns the sheet; `CNF-84` owns the cases. This record closes
the two points ADR-0058 left open and adds no rule of its own.

## What was undecided

The credential format said: "What the new seed's sheet holds for a handoff allocated under a
retired seed is not yet specified, and neither is what a later Replace does with a
`migration_index` whose reserved allocation is under the seed that Replace retires." `STA-17` said
"what a later Replace does with a migration index under the seed it retires is not yet specified
(credential format)". Two cases had no sheet form:

- a handoff allocated under the seed Replace retires, whose post-harness credential's public half
  is installed "during setup, before the handoff point" (`ARC-19a`) and whose lifetime is "As
  declared by the profile's handoff slot" (`SEC-5` row 17);
- a machine whose new index a first Replace reserved and whose migration stayed unconfirmed, as
  after a failed relabel read, when a second Replace retires the seed that index is under. Version
  7's `migration_index` must name an allocation in `allocations`, which then belongs to the new
  seed, so that export had no form.

## The shape chosen

**A retired-seed handoff stays under its seed.** The new seed's sheet carries each handoff the
journal keeps under a retired seed in `retired_allocations`, family `handoff`, with its seed, index,
tenant and handoff ID, its credential's role-4 public half as its recorded key and `outstanding`
with reason `"lifetime_running"`, for as long as its profile's declared lifetime runs. The
post-harness machinery is given the credential only after the harness derives it from the retired
seed the operator supplies and compares it with the recorded key. Using it is a step that needs the
retired seed, so Replace's screen says the retired seed stays needed for it. The entry ends in one
journal act when the journal records the declared end. Replace does not re-issue a handoff.

**A pending migration index is read first, then superseded.** A later Replace that finds a machine
whose migration index is under the seed it retires first takes, on a dedicated machine, the label
read `STA-17` already requires. A read showing the reserved index's id confirms that migration in
one journal act, and the machine then migrates like any machine of that seed. Otherwise one journal
act supersedes the reservation: the machine keeps its own retired-seed entry and may get a fresh
migration index under the new seed, and the old reservation becomes its own retired machine entry
with reason `"superseded_reservation"` and a `reservation_of` link to the machine's entry. Like a
migration index it is not a second machine: no record names it, and it has no machine state or
artifact history. Its recorded key is one more retired public key re-entry removes from the
machine. The act that migrates or destroys the machine ends its superseded reservations, and a
further Replace copies them unchanged. Every such migration index is settled before that Replace's
export, which holds none.

*Amended 2026-11-05*
([ADR-0066](./0066-a-migrated-machines-unremoved-old-key-stays-on-the-sheet.md)): the act that
migrates the machine ends its superseded reservations as machine entries and keeps each of their
keys as a pending removal until a read confirms it removed. The act that destroys the machine
still ends them.

**Version.** This amends payload version 7, as ADR-0058 did. Its text marked both points not yet
specified, and nothing in the repository writes a version-7 sheet.

## Why

The text forces neither part, but it excludes two options. Re-issuing a handoff under the new seed
conflicts with "during setup, before the handoff point" and "over the bound session's own channel"
(`ARC-19a`): Replace runs with "no session is bound" (`STA-17`), and a sealed machine cannot be told
a new key. Dropping the reservation conflicts with `STA-22b`'s "Failed requires local proof that
this allocation's create was never sent", since the reserved key may be installed on the machine.
Once a read shows the reserved id, `STA-17`'s "A later read showing the new id confirms the relabel
without another write" decides that branch. A label alone does not tell which seed an index
belongs to, so the superseded reservation keeps the recorded link to its machine rather than a
second machine name. Deferring the handoff's key check keeps `STA-22b`'s derive-and-compare for
every credential the harness gives out: the recorded key is never authority by itself.

## What this widens

The owner accepted these by name under the 2026-11-05 panel rule. Each quote is the text as it
stood before this change (commit `a5f1853`):

- comment 113000001's `retired_allocations` "carrying every allocation the journal keeps under an
  earlier seed" covers handoffs too, and its recorded-key acceptance, deferred to before use,
  covers a retired handoff;
- `STA-17`'s "needs its backup *during* Replace and abandons it after", now after the last step
  that needs it, and `SEC-5` row 15's "until
  the last step that needs it is done": a retired-seed handoff's use while its lifetime runs is
  such a step;
- comment 113000001's reserved index "linked, not a second machine" gains a second linked kind,
  the superseded reservation, and the format's "the one repeated mapping import accepts" widens to
  it;
- `CNF-84` accepts family `handoff`, the new reasons and the link member, and refuses their
  malformed forms.

## Alternatives considered

| Option | Disposition |
|---|---|
| Re-issue the handoff under the new seed where a channel remains | Not selected. Its public half is installed only during setup, before the handoff point, over the bound session's channel. |
| End the handoff at Replace | Not selected. It cuts a credential short of the lifetime its profile declares. |
| Re-enter the machine without the read | Not selected. A landed relabel would be overwritten and its confirmed migration lost. |
| Drop the reservation | Not selected. The reserved key may be installed, and nothing proves its create never sent. |

## Consequences

`STA-17`, `STA-22b`, `SEC-5` row 15, the credential format's payload version 7 and `CNF-84` change
together. The formal companion is unchanged: its allocation module omits the sheet's import checks
and Replace's re-entry, and nothing here allocates an index.
