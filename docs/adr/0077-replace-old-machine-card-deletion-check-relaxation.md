# Replace old-machine card deletion checks: an owner-directed relaxation

Decided 2026-11-10 (`tw-qe7.19`) on the owner's instruction, from the "Retire old machine" half of
review item R06, "Let machine cancellation include follow-up deletion checks", which
[ADR-0076](./0076-abandon-approval-deletion-check-relaxation.md) left out. The owner picked "Adopt
it" over the recommended "Drop it". This is an owner-directed relaxation, not a clarification. It
partially supersedes ADR-0076's narrowing of R06 and, a second time,
[ADR-0053](./0053-the-setup-finishes-on-arrival-and-one-check-reads-a-stopped-machine.md)'s
blanket choice that every deletion check is started by the operator, both for Replace's old
machine only. Their other decisions, alternatives and reasoning remain the historical record. It
is permission only, with no change to T44 or capability admission.

## Why

R06 assumed an existing "Retire old machine" approval could carry the follow-up deletion checks.
A review panel, two rounds with four readers counted in each and one seat missing, found that
premise does not hold: no existing approval carries that reach for Replace's old machine, because
Replace's stop rests on its flow grant and journals call facts, not card prose (three of four,
one could not tell from the text). The narrowest form is a new card for Replace's old machine
only (four of four). Every point was accepted under the owner's 2026-11-05 panel rule. The owner
accepts one more card on each LNVPS Replace rebuild in exchange for no per-check starts on that
machine later, and continued, narrowly authorized authenticated vendor contact while the app is
available. That contact is visible to the vendor: `SEC-4` says "these are authenticated reads
the vendor receives and may record".

## Decision and owners

The card and its recorded facts live in `STA-17`: "An LNVPS Replace rebuild MUST show one Replace
old-machine card for its old machine." `STA-17` says "Approving it durably records the card's
facts, its disclosure included, as `ARC-21` records the Abandon approval's". The disclosure is
recorded card facts, as ADR-0076's is, with no field, separate permission record, schema layer,
format version or migration (four of four).

The permission lives in `SEC-4`, on the Abandon permission's bounds: `SEC-4` says "only for the
one machine it names, the old machine of an LNVPS Replace rebuild" and "under the same limits as
the Abandon permission above". The card supplies deletion reads only; `SEC-4` says "it MUST NOT
replay stop, destroy, reinstall or renewal-off, or authorize a new target, and it gives Replace's
own flow no further call".

## What is loosened, reversed and widened

- `SEC-4`'s manual rule: Replace's old machine leaves it once its card is recorded. The rule
  keeps it otherwise; `SEC-4` says "Replace's old machine when no Replace old-machine card for it
  is recorded, including after a Restore from the recovery sheet alone, which brings back no such
  card".
- `CNF-20`'s former "No Replace-card disclosure or approval extends this permission" and the
  Replace applicability row's former "without a Replace-card disclosure or extended approval" are
  reversed.
- The owner's 2026-11-08 "Abandon-setup only" pick (`tw-qe7.12`) is widened to Replace's old
  machine.
- Each LNVPS Replace rebuild gains one approval card where it had none.

## What stays

- Manual: every machine the in-setup replacement rung stopped, including one whose setup is later
  abandoned; a Replace rebuild whose card was declined or never recorded; and any machine after a
  Restore from the recovery sheet alone. `CNF-20` carries that fallback case.
- Replace's three-call grant and its order. `SEC-4` says "The deletion check gives this flow no
  further call." `STA-17` says "The deletion check (`SEC-4`) collects that evidence and adds no
  call to this flow." Replace stays reported incomplete until the old machine's deletion evidence
  is durably recorded.
- T44: `SEC-4` says "Deletion verification MUST remain unavailable until T44's vendor-key
  capability exists, and the interface MUST show it as unavailable with the reason." The use for
  this machine is offered only once item 20's deletion-check case passes, and each read still
  needs that machine's own recorded vendor key and, where that key can come only from the
  retired seed, that seed: `STA-17` says "a read under that key is such a step".
- ADR-0053's open question of which caller stops the old machine in the in-setup rung.
- No theorem, witness, gate or assumption boundary moves, and the credential format gains
  nothing (four of four). The non-session authority stays with its prose owner under ADR-0032.

## Alternatives considered

| Option | Disposition |
|---|---|
| Drop it: Replace's old machine keeps one operator start per check | Recommended, not chosen by the owner. |
| Carry the reach on an existing Replace approval | Not available: no existing approval carries it (three of four). |
| Also cover a machine the in-setup rung stopped | Not chosen: the owner adopted the form for Replace's old machine only; that machine stays manual (four of four). |
