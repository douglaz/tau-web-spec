# A destructive disposition stops every box-plane job and offers the local paste at once

Decided 2026-10-19. `STA-24` owns the stop; `ARC-43` owns re-arm and the fallback card;
`STA-17` owns Replace's migration. This record adds no second rule.

## What was undecided

ADR-0044's destructive stop named the model's commands and jobs the model requested, leaving
harness-started work able to pre-empt the chosen reinstall. A digest left unresolved at store
loss could also leave the other machines waiting for references while the operator had the
values available locally. The fallback's timing under that disposition was unspecified.

## The shape chosen

`STA-24` says "the harness worker MUST refuse every box-plane job to that machine, whatever
the disposed call was and whoever starts it". Its permitted reads remain unchanged. The
requester cannot exempt a reboot, relabel, key migration, digest or delivery-check read from
the stop. Replace's treatment of the machine belongs to `STA-17`.

`ARC-43` says "the card is offered at once for every known required placement on it whose
reference is unarmed, the disposed digest's included". No required reference is waived; a
local paste can arm it while the destructive reinstall or abandonment still stands. The paste
sends nothing to the machine and changes no restriction of `STA-20` or `STA-24`. A late
record of the disposed digest arms nothing and cross-checks a paste without replacing it.

Under a destructive reinstall without a paste, `ARC-43` says "nothing is composed or re-issued
for that machine's unarmed placements until one operator act after the reinstall restarts the
re-read for all of them". That act issues a refused digest as a first issue and a disposed one
as the operator's re-issue, never automatically. The continuation's completion alone releases no
output whose reference remains unarmed.

## Alternatives considered

| Option | Disposition |
|---|---|
| Stop only model commands, letting harness-started jobs pass | Rejected. A reboot or relabel pre-empts the reinstall whoever starts it; Replace would keep migrating a machine chosen for a wipe. |
| Stop only writes, letting harness reads pass | Rejected. A read whose answer is lost bars reset or activation without a timeout and costs another disposition. |
| Offer the paste only after the wipe | Rejected. The file is then gone, so the later paste is checked no better; an early paste writes nothing to the machine and cannot pre-empt the reinstall. |
| Release the other machines' output without the disposed machine's references | Rejected. `SEC-5` says "Unscanned bytes MUST be withheld"; a secret copied onto another machine would go unscanned. |

## Consequences

The Markdown, conformance cases and companion change together. `TauWeb.Dispatch.stops` gains
`deliveryReboot` beside `exec`; the new pair is
`TauWeb.Dispatch.destructive_choice_stops_delivery_reboot` /
`TauWeb.Dispatch.delivery_reboot_dispatched_without_destructive_stop` under `destructiveStops`.
`TauWeb.Dispatch.command_bars_activation_and_reset` pins an unresolved command barring activation
and reset. Dispatch schema 6 is unchanged and regenerated. Re-arm remains prose and integrated
conformance evidence; the companion has no placement or scan-reference state.
