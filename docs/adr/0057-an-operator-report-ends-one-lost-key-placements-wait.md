# An operator report ends one lost-key placement's wait

Decided 2026-11-03 and 2026-11-05 (`tw-i55` comments 47000001, 81000001, 107000001, 108000001,
109000001 and 110000001). `ARC-43` owns the report and the wait it ends; `SEC-5` owns the scan
boundary and rows 12 and 23; `SEC-6` and `TRU-E12` own the display; `STA-16` and the credential
format own the sheet; `STA-22b` owns the one import exception. This record revisits ADR-0050's
rejected "Release the other machines' output without the disposed machine's references" and adds
no rule of its own.

## What was undecided

After local-store loss with no copy of an application key, `ARC-43` says "Model `exec` across
the bound set MUST wait while any known required placement reference is unarmed." A re-arm, an
admitted rotation or the machine's destruction ends that wait, and its card says "that neither a
reinstall nor the stop that stands in for a destroy (`ARC-22`) ends that wait". Where a reinstall
leaves no file for `digest_secret` to read, the operator cannot paste the value, and the commands
the machine needs before rotation's placement gates admit it are themselves model commands, the
only exit left is destruction. Nothing let an operator who had revoked the key at its service say
so.

## The shape chosen

**The report** (comment 47000001, kept by the need review in comment 81000001). `ARC-43` owns it:
"After revoking a placement's key at its service, the operator may report that one placement
revoked." What it ends, what it leaves standing and what never produces it are `ARC-43`'s. The
decision recorded here is that a report names one placement and trusts the operator's word, for
the reasons below.

**What was withheld stays withheld.** `SEC-5` owns the scan boundary, and says a report "never
counts as a scan: bytes withheld before it stay withheld". The decision recorded here is that only
later output for the reported placement loses its scan.

**The sheet** (comments 107000001 to 110000001). The credential format's payload version 7 owns
the shape, and `STA-22b` owns its one import exception. The decisions recorded here are a report
member on each placement record rather than a separate list, a reported record kept through its
secret's rotation and its machine's destruction, and, after Replace, a destroyed machine's
reported record tagged with the seed it was allocated under.

## Why a key revoked at its service changes ADR-0050's rejection

ADR-0050 rejected releasing the other machines' output without the disposed machine's references:
`SEC-5` says "Unscanned bytes MUST be withheld", and a secret copied onto another machine would go
unscanned. That rejection still stands for every byte it protected:

- **The backlog.** `SEC-5` says "A report never counts as a scan". Releasing the backlog was
  option I in comment 47000001, and every reading rejected it on the same ground as ADR-0050.
- **Other references.** `ARC-43` says later output "owes every other reference and release
  prerequisite".

What changes is later output for the reported placement alone. A revoked key is a credential its
service no longer honours. A copy of it in later output exposes bytes, not authority. The owner
accepted, by name, trusting the operator's statement in place of service evidence. The owner also
accepted the cost: "a mistaken report could expose a still-live key in later output and understate
live exposure". The display says so. `SEC-6` lists the placement as operator-reported history,
"unverified at the service", and states that later output is not checked for its value.

## Alternatives considered

| Option | Disposition |
|---|---|
| Keep the re-arm, paste, admitted-rotation and destruction routes only | Not selected. It leaves the conditional deadlock, whose only exit is destruction. |
| Record the report without ending the wait or the live listing | Not selected. It leaves the deadlock and adds a record that changes nothing. |
| Resume commands but keep output withheld | Not selected. It lets the machine's repair run, but no output from it can be released. |
| Require service verification | Not selected. The harness has no revocation oracle for an operator's service. |
| Clear every placement holding the same value | Not selected. A report names one placement; another holding the same bytes may still be live. |
| Release the old withheld backlog | Rejected, as in ADR-0050: `SEC-5` says "Unscanned bytes MUST be withheld". |

## Consequences

The Markdown, the credential format and the conformance cases change together: `CNF-42` for the
display, `CNF-84` for the version-7 sheet and `CNF-95(h)` for the scan. The formal companion has
no placement or scan-reference state and is unchanged. Still to be decided:

- whether the report is offered while the placement's reference is armed, since decided in
  [ADR-0062](./0062-the-lost-key-report-is-offered-only-while-unarmed-and-is-final.md);
- whether a report can be corrected or withdrawn, since decided in
  [ADR-0062](./0062-the-lost-key-report-is-offered-only-while-unarmed-and-is-final.md);
- what keeps an ended unreported placement's withheld output withheld after a Restore from a later
  sheet, since decided in
  [ADR-0060](./0060-a-machine-mark-keeps-an-ended-unreported-placements-older-output-withheld.md);
- how other retired-seed facts are named after Replace, since decided in
  [ADR-0058](./0058-the-new-seeds-sheet-keeps-retired-seed-machines-under-their-own-seed.md).
