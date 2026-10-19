# Running-at-delivery binds until the boot changes

Decided 2026-10-18. `ARC-43` owns the re-entry read, boot anchor and evidence note; `ARC-17`
owns findings and the placing session's demonstration. This record adds no second rule.

## What was undecided

A declaration could ask for a service running at delivery and deliberately lost at restart.
Re-entry did not say whether to read that service, or whether stopping later failed its
lifecycle. Treating every stopped service alike would turn an approved restart death into a
finding; ignoring every later stop would hide a crash on the delivery boot.

## The shape chosen

Every declared service's unit is read at re-entry; enablement is read only for
`enabled-survives-reboot`. For `running-at-delivery`, the boot identity journaled with the
last check finding it running anchors the lifecycle. Never found running still binds.
Stopped on the anchor boot is a finding. Stopped only after a restart carries the note
"stopped since a restart, as approved" wherever Delivered appears, without a new finding.

A restart cannot clear a standing crash finding. With the declaration unchanged, a check
finding the service running clears it; the existing declaration-amendment route remains.
A session placing a secret needs the service running after its last placement: the note does
not count, and a stopped service there is a lifecycle finding, preserving the delivered or
handed-over-with-findings verdict.

## Alternatives considered

| Option | Disposition |
|---|---|
| Never bind after delivery | Rejected. A crash while the machine stays up would leave it showing delivered. |
| Bind at every check | Rejected. A deliberately restart-lost service would become a finding after its approved restart. |
| Allow running-at-delivery only on sealed machines | Rejected. `ARC-27` says "neither the operator's goal nor the model's proposal can seal a machine"; the stage-1 maintained path needs this lifecycle too. |
| Clear a standing finding at the first check after restart | Rejected. Restart must not erase an already observed crash. |

## How it was reached

The owner chose a finding for a stop before restart and a note for a stop after restart,
keeping an existing finding across restart until the service is seen running again. The same
decision required the placing session to demonstrate running and named the re-entry read.

## Consequences

The open questions in `OPN-14` are decided; its owed reads and integrated evidence remain open.
T42 points at the decided mechanics. Lifecycle cases stay together in `CNF-53`; `CNF-108`
continues to exercise the broader re-entry check. The declaration companion gains only a
docstring: evidence notes are passes there, while lifecycle timing remains prose.
