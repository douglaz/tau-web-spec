# The setup finishes on arrival and one check reads a stopped machine

Decided 2026-11-03 and 2026-11-04. `ARC-22` owns the LNVPS in-setup replacement rung's form and
order, completion on arrival and the display of a stopped machine after its setup; `ARC-15`
owns the approved entry; `SEC-4` owns the deletion check's grant and the grant for Replace's two
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

**The in-setup replacement rung at LNVPS.** The old machine is stopped and its renewal turned
off, its terminal reconciliation finishes, and only then is the replacement ordered. No wait for
confirmed deletion comes before the order. The replacement is a new approved entry of the same
setup, with its own approval, original structured facts, allocation, per-machine identity, and
verification, invoice and first-contact admissions; it is never a re-order of the old entry or a
new label for the old machine, and it gives nobody authority over the old machine. A
disposition stays an unknown outcome and never stands in for a confirmation. The rung's stop
takes the same unavailable-destroy treatment as an abandonment's machine and a Replace
rebuild's old machine. The rung stays unavailable until its admission row in
`07-conformance.md` holds.

**The setup finishes on arrival.** In that rung the setup finishes when the replacement is
delivered. The old machine then leaves the machines the abandonment flow reaches. The opening
screen still shows it, and every other machine of a finished setup that was stopped this way
and is not yet confirmed deleted, as existing and billed, with its cost and the vendor's stated
deletion date, until the deletion evidence is durably recorded. That is a display rule, not an
authority, and it does not make a finished setup own the first screen. Its exposure and
placed-secret duties stay open.

**One deletion check.** The operator starts it from the screen that shows the machine; nothing
starts it on its own. It runs outside any session, drives no model and holds no SSH client key.
It covers any machine stopped under the unavailable-destroy treatment whose deletion is
unconfirmed, whichever flow stopped it and whatever state its setup is in, finished or abandoned
included. It makes only the deletion reads of `STG-21a`, under that machine's own recorded
vendor key, and no mutating call, and it never uses another machine's key. It supplies evidence
and ends no duty by itself. Read-only describes the harness's authority, not the vendor's side:
the vendor receives each authenticated read, and such a read can create an empty account row.
The key is the machine's derived vendor identity, which cannot be derived today, so until T44
lands the check has no key and makes no read. ADR-0042 already keeps that key apart from the
retired seed once the carry-forward lands; this record changes nothing there.

**Replace stays incomplete.** An LNVPS Replace is reported incomplete until the rebuilt old
machine's deletion evidence is durably recorded, including across a restart, after the stated
deletion date passes and after a failed append of the evidence. No other Replace step waits on
that machine. The operator may drop the retired seed's backup once the last step that needs it
is done; the wait for deletion does not by itself keep the backup needed, but a read under a key
that only the retired seed can give is such a step.

**Replace's two calls.** Replace's own model-free flow is the caller of exactly two vendor calls
for the rebuilt old machine: its stop, after any re-entry of that machine and any removal of its
old public key, and then its renewal-off, after the stop is confirmed. Both use that machine's
own recorded key. The deletion check gives the flow no further call, and T44 gates the key.

## What it costs

- A working replacement no longer waits behind an unfinished setup, so the old machine's cost
  and exposure are carried by a display rule outside the setup rather than by the setup itself.
- A read-only authority outside any session now reaches machines outside any unfinished setup,
  including after Replace has ended and after an abandonment.
- If no read can ever confirm a deletion, Replace never reports complete for that machine, and
  a status that never clears can teach operators to ignore it.
- Replace's flow gains two mutating vendor calls under the old machine's key.
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
| No grant for Replace's calls | Rejected by the owner: no route would stop the old machine or turn its renewal off. |
| Reinstall the same machine as the rung, a deletion wait before every new order, or a same-domain restart shown as a collision | Not chosen. |

## Consequences

`ARC-15`, `ARC-16`, `ARC-21`, `ARC-22`, `SEC-4`, `SEC-5`, `STA-17` and `STA-24` change
together with the conformance cases and the two LNVPS rows that cite these decisions. These
stay open: whether Replace's renewal-off for the old machine is a fresh call or a read-back of a
state already off; whether Replace's re-entry of each maintained machine reaches the old
machine; which caller stops the old machine in the in-setup rung, beyond its existing authorized
caller; the selectors `OPN-27` queues. Nothing here admits the in-setup replacement order, the
deletion check or Replace's calls. This record makes no capability, readiness or runtime claim.

Changed-file navigation for this amendment:

- `01-architecture.md`.
- `03-state-and-recovery.md`.
- `04-security-model.md`.
- `07-conformance.md`.
- `docs/adr/0053-the-setup-finishes-on-arrival-and-one-check-reads-a-stopped-machine.md`.
