# The installation label moves at reinstall dispatch

Decided 2026-10-16. `STG-20` owns the installation boundary, the shown id and the pin-freshness
backstop; `STA-20b` owns keeping an installation under a continuing choice and the reset offer;
`ARC-7` owns the per-machine value shown to the model. The install brief carries the disk
instructions. This record explains the choice without adding another duty.

## What was undecided

A model returning to rescue was told to inspect and resume an existing install. After a
destructive reinstall that advice preserved the predecessor the operator had chosen to erase.
Conversely, always wiping on return destroyed an interrupted successor. There was no recorded
disk list to distinguish them, and a continuing choice with an installed pin could regenerate
keys which could not replace that pin.

## The shape chosen

The journal-derived installation id `<machine>-<n>` labels the root when it is formatted.
Its generation moves at destructive reinstall dispatch, not at the choice: the dedicated
reset into rescue, or the vendor's reinstall call at LNVPS. This keeps a choice replaced before
its reset from re-labelling the kept root. Restart and Restore retain the id; the machine
component is distinct within the journal, the whole id fits ext4's label, and its encoding is
left unspecified. No journal field or disk record is added.

*Amended 2026-10-17:* The companion carries a reinstall, with or without a disposition, through
its existing journaled typed approval, bound to the reset call, entry, session and approved facts.
Its reset is now refused without a confirmed rescue activation dispatched since the approval.
Withdrawal in `STG-20`, rather than disposition, supplies the approval-only change of mind;
`STA-24` owns the replacement screen. This keeps the label tied to the actual destructive
boundary. Comparing the installation's first durable prerequisite read against earlier
installations' prerequisite reads and installed-system pins catches retained keys before
reboot, rather than at a halt afterwards. Earlier observations remain the backstop's
comparison, not the offer's. A predecessor's record cannot make the successor's offer.

*Amended 2026-10-17:* `STG-20` says "An approval **stands** from its record until its reset is
dispatched, a matching withdrawal is recorded, or the session it was rendered for ends".
Session end is not journaled; the journal alone therefore cannot say whether an approval
stands. An ended session's approval is shown as no longer usable, with no withdrawal offer,
and opens nothing. A successor approves again and needs a rescue activation dispatched since
that new approval and still confirmed. The companion assumes that ended sessions send no
request; its successor refusal and re-approval traces carry the rule through session binding,
without adding an event or changing the schema. It does not prove session termination or
carry the display duties.

*Amended 2026-10-17:* The encoding in `STG-20` replaces "its encoding is left unspecified":
the machine-family index is lowercase hexadecimal without leading zeros, and the installation
ordinal is decimal without leading zeros, initially zero. Distinctness is among machines
allocated under the current seed; an unmigrated machine keeps its retired-seed index and can
coincide with a migrated machine's new index. The largest index `7fffffff` leaves seven bytes
after the separator: the uniform ordinal bound is 9 999 999, and `7fffffff-9999999` fits exactly
in ext4's 16-byte label. A destructive reinstall that would exceed the bound is refused before
dispatch, saying why, on both dedicated and LNVPS paths. `STA-17` owns Replace's migration of
the component to the new index while carrying the ordinal, and refusal to migrate an install
unfinished in rescue through confirmation of the reset into the installed system, including
after pins are recorded. Its screen names the machine still awaiting migration and the reason;
Replace remains incomplete. The install brief treats an unresolved label probe as unreadable.

The label steers the model and nothing checks it. A matching root can be resumed or found
complete and kept; an unmarked or foreign root is the predecessor, including a hand-installed
one. Duplicate matching roots and unreadable labels stop the brief before erasure. Formatting
and writing the label are one command. The existing disk-selection safety blocks remain.

A continuing choice with an installed pin keeps that installation and its keys. The reset
offer compares its newest prerequisite read against that installation's active pin, so a
changed key is shown before reboot, rather than discovered by a halt after reboot. A
predecessor's prerequisite record cannot offer the successor's reset.

The pin companion adds a backstop against carrying earlier keys across reinstall: it compares
ready-to-reset keys against earlier installations' observations as well as pins. It enforces
that no pinned key survives reinstall; it cannot establish erasure as approved. A predecessor
that never supplied a pin, and has no matching observation, gives it nothing to compare.

## Alternatives considered

| Option | Disposition |
|---|---|
| A one-shot fresh flag | Rejected. The harness cannot derive an end point, or the next attempt wipes an interrupted successor again. |
| A disk list | Rejected. No structured record of approved disks exists. |
| Move the label at the choice | Rejected. Replacing the reinstall before its reset would re-label a kept root. |

## How it was reached

Successive independent readings of the disposition cases exposed the conflict between resume
and destructive reinstall, then the stale prerequisite record on a machine entry. The owner
settled both with the installation boundary and the label, keeping disk erasure outside what
pin checks can claim. The dispatch point follows the earlier decision that a disposition
alone does not move that boundary.

## Consequences

The requirement, the install brief and their conformance cases change together. Dispatch
computes installation boundaries and key comparisons from journal records; pins takes its
reinstall event at dispatch and adds the ready-to-reset freshness check. Both gain parameterized
refused-and-admitted witnesses and new witness-file schemas. No label check, disk record or
cross-module dependency is introduced.
