# An unresolved command holds its machine

Decided 2026-10-18. `STA-20` owns the command hold and its collection; `ARC-43` owns the
delivery reboot's result and pending-check hold; `STA-17` owns Replace's migration.
This record adds no second rule.

## What was undecided

Reconnecting waited on the dropped command, but a fresh call could ask for work beside it.
A command proven ended without an exit also led straight to convergence, leaving no operator
choice before new work. A delivery reboot could terminate its own record before completion,
so treating its exit as its result either resumed too early or asked for a second decision
after the reboot the operator had already approved.

## The shape chosen

The hold belongs to the machine and covers commands through every tool, reads through `exec`
included, and harness-composed jobs. Record collection stays available. The worker serializes
the dispatch check with intent append, so a held request records no intent. Collection waits
without holding the writer; stopping the wait settles nothing. Another machine is independent.
Only a terminal record releases the hold; uncertain outcomes go to the operator first.

For the harness's delivery reboot the operator's yes is already in the intent. Its own job
record naming the machine and old boot, collected on a different boot, is its result even if
shutdown prevented a completion mark. A missing record names no boot and cannot supply that
result. The settlement records a boot change, never an exit status or its cause, and is durable
before dispatch resumes. The delivery check still holds model commands until its verdict or
the operator's journaled stop of the pending check. A held reboot asks for yes again at its first issue after release.

A held harness job is composed afresh by its visible flow after release, rather than queued;
a stopped wait leaves no work armed through replay. Replace leaves the held machine not
migrated, with its old key, and migrates the others.

In the companion, `changesRunning .deliveryReboot` is false because that predicate carries
`STA-24`'s cloud-plane exception: it says "a cloud-plane operation that **changes what the
machine is running**". The delivery reboot is box-plane work, held by `STA-20`; it can be
issued beside an unresolved activation. Its unresolved intent still bars cloud-plane work.
The independent command hold therefore sits beside the cloud-plane barrier.

## Alternatives considered

| Option | Disposition |
|---|---|
| Wait only on the dropped call; dispatch fresh requests and leave convergence to the brief | Rejected. A new identity still runs beside the old command. |
| Release after a fresh read finds no live command | Rejected. Liveness is not a final outcome; the operator sees uncertainty first. |
| Let `Ended` release, holding only missing and incomplete records | Rejected. Proven end without an exit still leaves an uncertain outcome. |
| Ask for a second operator tap after the delivery reboot | Rejected. The approved reboot's new-boot record is its result. |
| Hold an incomplete reboot record that names the old boot | Rejected. A shutdown can interrupt that record after writing the evidence needed. |
| Queue a held harness job | Rejected. Its flow must compose a first issue after release; a stopped wait must leave nothing armed. |

## How it was reached

The owner chose to hold all new commands while an earlier command is running or unresolved,
including reads, while allowing collection and keeping other machines independent. The owner
then settled the delivery reboot's own result and the half-written record naming its old boot.

## Consequences

The requirements, conformance cases and dispatch companion change together. The hold and
boot-change settlement each gain a parameter and refused/admitted pair; the alphabet gains a
second command. Witnesses that formerly needed two unresolved commands now use a continuing
disposition followed by replacement. Dispatch schema 6 carries the new operation and collection.

This supersedes ADR-0044's "Both now state what may be unresolved together": `STA-24` now names
at most one unresolved box-plane command, while an older activation may still stand beside it.
