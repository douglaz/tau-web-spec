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

**The report** (comment 47000001, kept by the need review in comment 81000001). After revoking
one placement's key at its service, the operator may report that placement revoked. It is
journaled before it takes effect, and `STA-3` says "If the append fails, the transition does not
occur." It ends that placement's required reference and live listing, and moves it to history
labelled operator-reported, never "retired" or "rotated". It ends that placement only: another
placement keeps its own reference even with the same bytes, application name or path. It lifts no
`STA-20` or `STA-24` restriction and authorizes no retry. A missing file, a changed pin, a
reinstall, a new installation and the stop that stands in for a destroy never produce it.

**What was withheld stays withheld.** `SEC-5` says a report "never counts as a scan: bytes withheld
before it stay withheld". Output counts as produced after the report only when the job that
produced it was dispatched after the report was durably recorded. Re-collecting, replaying or
displaying an old range makes it no newer.

**The sheet** (comments 107000001 to 110000001). Payload version 7 gives every placement record a
`report` member and a `seed_id`, and adds `retired_allocations`. A reported record stays on every
later sheet, through its secret's rotation and its machine's destruction. A destroyed machine's
reported record has its application name checked by form only. After Replace, a destroyed
machine's reported record keeps the seed it was allocated under, and the new seed's sheet carries
that machine as a retired allocation whose recorded public key import accepts without deriving it.
Older versions convert with no report, so a sheet exported before the report restores the wait.

## Why a key revoked at its service changes ADR-0050's rejection

ADR-0050 rejected releasing the other machines' output without the disposed machine's references:
`SEC-5` says "Unscanned bytes MUST be withheld", and a secret copied onto another machine would go
unscanned. That rejection still stands for every byte it protected:

- **The backlog.** Output withheld before the report stays withheld. Releasing it was option I in
  comment 47000001, and every reading rejected it on the same ground as ADR-0050.
- **Other references.** The report ends one reference. Output still owes every other required
  reference and release prerequisite, so it does not release output that some other unarmed
  reference holds back.

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

- whether the report is offered while the placement's reference is armed;
- whether a report can be corrected or withdrawn;
- what keeps an ended unreported placement's withheld output withheld after a Restore from a later
  sheet;
- how other retired-seed facts are named after Replace.
