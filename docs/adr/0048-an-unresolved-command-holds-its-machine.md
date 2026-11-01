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

## Dated amendment — journal-only recovery protection, 2026-11-01

The owner chose journal-only protection. The command-hold boundary belongs to
[`STA-20`](../../03-state-and-recovery.md#durable-state): "The command hold is journal-only."
The complete-loss/stale-backup distinction and retained-record effects belong to
[`STA-24`](../../03-state-and-recovery.md#durable-state): "Every retained record MUST keep its
interpretation under the replay rules above". Replace's migration remains at
[`STA-17`](../../03-state-and-recovery.md#recovery-by-access-model-and-vendor).

The choice accepts the journal's knowledge limit during recovery, including key replacement.
Access recovered from a seed and sheet cannot recover an outstanding-call record: `STA-14`
says "Transcripts and provenance are gone and stated as gone." A stale backup raises a
different question from complete loss, because it has records to interpret. `STA-24` says
"Settlement of one retained call under its own contract supplies no completeness or completion
evidence about omitted sends". For the effects on retained holds and standing dispositions,
see that same owner; for the overlap boundary and its non-exception to other admission
requirements, see `STA-20`.

| Alternative | Disposition |
|---|---|
| Bounded recovery enumeration and hold | Rejected by the owner. It would add a prerequisite based on machine-reported records. For the limits of that evidence, see `STA-21`: "Enumerating machine records cannot reconstruct lost journal intents or approvals, establish completeness against a hostile machine, discover a command that left no record, or promise that an old phone cannot issue further work." |
| Operator-cancellable advisory wait | Rejected by the owner. It would add a recovery wait before new work or key replacement; the chosen command-hold boundary remains `STA-20`'s. |
| Treat a backup import as clearing its retained restrictions | Rejected. `STA-24` says "recovery alone settles no retained unresolved intent, clears no retained resource barrier or command hold, erases no standing disposition and authorizes no automatic retry." |

This clarifies the knowledge limit already present in the companion, without changing a
dispatch parameter. `TauWeb.Dispatch.openIntents` reads the surviving journal through
`TauWeb.Dispatch.inEffect`; `TauWeb.Dispatch.barring` filters that set with
`TauWeb.Dispatch.bars` and `TauWeb.Dispatch.commandHold`. Compare
`TauWeb.Dispatch.second_command_held` / `TauWeb.Dispatch.second_command_without_hold`,
`TauWeb.Dispatch.hold_reads_and_other_machines`, `TauWeb.Dispatch.command_holds_delivery_reboot`
and `TauWeb.Dispatch.replay_same_unresolved`. The without-hold witness is the existing
negative control, not a recovery permission. The single-writer and ended-session conventions
remain assumptions; collection/wait procedures and the pending-delivery-check hold remain
prose boundaries in the module's opening notes.

For implementation obligations, see `CNF-115` and the existing cases it references in
[`07-conformance.md`](../../07-conformance.md#state-and-recovery). Consistent specification
gates supply no integrated recovery, fresh-image, remote-completeness or production-safety
evidence. T42's live-image work and T44's credential/recovery amendment remain outstanding.
