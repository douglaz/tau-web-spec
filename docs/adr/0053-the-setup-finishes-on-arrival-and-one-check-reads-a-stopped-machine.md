# The setup finishes on arrival and one check reads a stopped machine

Decided 2026-11-03 and 2026-11-04. `ARC-22` owns the LNVPS in-setup replacement rung's form and
order, completion on arrival and the display of a stopped machine after its setup; `ARC-15`
owns the approved entry; `SEC-4` owns the deletion check's grant and the grant for Replace's
calls; `SEC-5` owns the credential lifetimes and the destruction duties; `STA-17` owns Replace,
its completion report and the retired seed's backup; `STG-21a` owns the deletion predicate;
`STA-24` owns the evidence record, dispositions and the sibling-entry permission.

## What was undecided

At LNVPS the harness cannot destroy a machine: where it would, it stops the machine, turns its
automatic renewal off and shows it as existing and billed until the vendor's deletion is
confirmed. That left four questions. When the in-setup replacement rung orders a new machine,
does the setup finish when the new machine arrives or only once the old one's deletion is
recorded? Who reads the old machine's deletion evidence, given that no session, listing or
flow the text named could? May Replace report complete while a rebuilt old machine's deletion
is unconfirmed? And which caller stops that old machine and turns its renewal off, since the
text required both and named nobody?

## The shape chosen

**The in-setup replacement rung at LNVPS.** The old machine is stopped, not destroyed, and the
replacement is a new approved entry of the same setup; no wait for confirmed deletion comes
before its order. For the rung's form and order, see `ARC-22`; for the entry, `ARC-15`; for its
allocation and the disposition rule, `STA-22b` and `STA-24`. The rung stays unavailable until
its admission row in `07-conformance.md` holds.

**The setup finishes on arrival.** The replacement's delivery is what the rung contributes to
its setup's completion; the old machine's deletion is not waited for. A stopped machine whose
deletion is unconfirmed stays shown as existing and billed after its setup, as a display rule
rather than an authority, with its duties open. For both, see `ARC-22`.

**One deletion check.** One operator-started check, outside any session and under the stopped
machine's own key, reads deletion for any machine stopped this way, whichever flow stopped it.
It supplies evidence and has no key until T44 lands. For its grant, see `SEC-4`; for the
predicate, `STG-21a`. ADR-0042 already keeps that key apart from the retired seed once the
carry-forward lands; this record changes nothing there.

**Replace stays incomplete.** An LNVPS Replace is reported incomplete until the rebuilt old
machine's deletion evidence is durably recorded, and no other Replace step waits on that
machine. For the rule and the retired seed's backup, see `STA-17`.

**Replace's two calls.** Replace's own model-free flow is the caller of the rebuilt old
machine's stop and renewal-off, under that machine's own key. For the grant, see `SEC-4`; for
the order, `STA-17`.

*Amended 2026-11-05:* the owner chose "Allow one read-back"; the panel split 3–1. After the
renewal-off, Replace's flow may read that one old machine, under its own key, to confirm
renewal is off, so the grant now names three kinds of call. Renewal is then shown confirmed off, and
Replace still reports complete only once the deletion is confirmed. The read confirms no stop
and no deletion, and T44 still gates the key. Whether the renewal-off itself is a fresh call
or a read-back of a state already off stays open, and so does whether the read may be repeated
after one that leaves the renewal-off unresolved. For the grant, see `SEC-4`.

## What it costs

- A working replacement no longer waits behind an unfinished setup, so the old machine's cost
  and exposure are carried by a display rule outside the setup rather than by the setup itself.
- A read-only authority outside any session now reaches machines outside any unfinished setup,
  including after Replace has ended and after an abandonment.
- If no read can ever confirm a deletion, Replace never reports complete for that machine, and
  a status that never clears can teach operators to ignore it.
- Replace's flow gains two vendor calls, the stop and the renewal-off, under the old machine's
  key [amended 2026-11-05: and the read that confirms that renewal-off; see the note above].
- Until T44 lands, none of this has a key: the check reads nothing, the calls cannot be made,
  and the machine stays shown with its duties open.

## Alternatives considered

| Option | Disposition |
|---|---|
| The setup stays unfinished until the old machine's deletion is recorded (completion B, 2026-11-03) | Superseded by the owner on 2026-11-04. Four of five readings chose completion on arrival. |
| A dedicated reader with one scope for an unfinished setup's machines and a second for Replace's old machine | Superseded: one check keyed on the machine's state replaces both scopes. |
| A separate check grant for each flow that stops a machine | Rejected by the owner. Three of five readings chose one grant, two chose a grant per flow; all five chose an operator-started check under the machine's own key. |
| Existing routes only, or no collector | Rejected by the owner: no route the text names can read the old machine's deletion. |
| Replace complete, with the old machine listed apart | Rejected by the owner. All three readings chose staying incomplete. |
| Replace complete only if the old machine's old public key was removed before the stop | Rejected by the owner. |
| Grant Replace's calls now and fix their order later | Rejected by the owner. All five readings chose the grant; three asked for the order in the same edit. |
| No read to confirm Replace's renewal-off, so the renewal-off has no confirmation route under `SEC-4`'s grant (2026-11-05) | Rejected by the owner. Three of four readings chose the read, one chose no read. |
| No grant for Replace's calls | Rejected by the owner: no route would stop the old machine or turn its renewal off. |
| Reinstall the same machine as the rung, a deletion wait before every new order, or a same-domain restart shown as a collision | Not chosen. |

## Consequences

`ARC-15`, `ARC-16`, `ARC-21`, `ARC-22`, `SEC-4`, `SEC-5`, `STA-17` and `STA-24` change
together with the conformance cases and the two LNVPS rows that cite these decisions. These
stay open: whether Replace's renewal-off for the old machine is a fresh call or a read-back of a
state already off; whether the read that confirms that renewal-off is part of the renewal-off
call, without which it has no confirmation route under `SEC-4`'s grant [decided 2026-11-05: a
read after the renewal-off is granted; see the note above]; whether that read may be repeated
after one that leaves the renewal-off unresolved; whether Replace's re-entry of each maintained machine reaches the old
machine; which caller stops the old machine in the in-setup rung, beyond its existing authorized
caller; the selectors `OPN-27` queues. Nothing here admits the in-setup replacement order, the
deletion check or Replace's calls. This record makes no capability, readiness or runtime claim.

Changed-file navigation for this amendment:

- `01-architecture.md`.
- `03-state-and-recovery.md`.
- `04-security-model.md`.
- `07-conformance.md`.
- `docs/adr/0053-the-setup-finishes-on-arrival-and-one-check-reads-a-stopped-machine.md`.

*Amended 2026-11-08: partial supersession of the blanket operator-started deletion-check choice.*
[ADR-0076](./0076-abandon-approval-deletion-check-relaxation.md) records the owner-directed
relaxation and narrowing of R06, owned by `SEC-4`, with the disclosed Abandon approval facts
owned by `ARC-21`. The blanket initiation choice above is history; the other decisions,
alternatives and reasoning remain the historical record.

*Amended 2026-11-10: a second partial supersession, for Replace's old machine only.*
[ADR-0077](./0077-replace-old-machine-card-deletion-check-relaxation.md) records the
owner-directed relaxation that lets a recorded Replace old-machine card (`STA-17`) carry
`SEC-4`'s follow-up deletion reads for the old machine of an LNVPS Replace rebuild. Which caller
stops the old machine in the in-setup rung stays open, as above.
