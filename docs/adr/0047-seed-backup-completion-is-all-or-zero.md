# Seed-backup completion is all or zero

Accepted 2026-10-16. `STA-23` owns the ceremony, its two completions and durable record;
`STA-22b` owns the allocation gate in every family. The recovery sheet copies that record
under `STA-16` and the version-3 credential payload contract, without changing its version.

## Why all or zero

"All or zero, for confident people": show all twelve words outside a session, then hide
them while the operator either re-enters all of them or explicitly skips the check. A full
import yielding the same seed id catches transcription errors; an explicit skip records what
the operator chose. Neither completion makes a verified-backup claim. A durable record is
state, so interruption before it leaves the ceremony owed at the next unlock. Replace's
fresh seed owes its own record before its allocations; generating the seed itself is free
of that gate. Imported seeds restore and never allocate, and typing them in is their proof.

## Alternatives rejected

- An "I wrote it down" checkbox catches nothing.
- A three-word spot check lets one miscopied word pass three times in four.
- A ceremony offered but never required leaves an unbacked seed able to lose every machine
  and, at LNVPS, the account that can stop it.

The gate requires a recorded choice, not a claim that the operator has made a verified
backup. On-demand re-display uses the same ceremony after passphrase entry again.
