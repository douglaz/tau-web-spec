# Sheetless cloud recovery adds no destructive authority

Decided 2026-11-02. `STA-15` owns recovery of a maintained cloud machine whose pin is lost
with no sheet; `SEC-4` owns every destructive authorization, including the abandonment flow's;
`STA-17` owns Replace's missing-seed and missing-index limits; `ARC-22` owns the LNVPS forms of
destroy and recreate; `STG-21a` owns LNVPS deletion confirmation.

## What was undecided

`STA-15` said that such a machine "is destroyed and recreated", and `STA-22b` said "Cloud
destroys and recreates". That destroy names a machine the journal maps to no entry, so neither a
session's binding nor the abandonment flow's authorization covers it, and nothing else
authorized it. The LNVPS case in `CNF-84` asked for a stop with renewal off, but with the old
seed or index missing `STA-17` says "the harness can neither reinstall nor stop it".

## The shape chosen

The operator acts at the vendor. Sheetless recovery adds no destructive authority: for a
machine that existing authorization cannot admit, the harness gains no permission to stop,
reinstall or destroy it from a listing, a recovery-sheet mapping, a selection, a new adoption
card or a new recovery-evidence rule. Existing authority is unchanged: the harness recreates
only where its existing credentials, authority, allocation and approval rules permit, and a
fresh acquisition is a new order under its own approvals.
The screen names the remedies that are unavailable. It does not promise that every vendor offers
a manual destroy, or that a missing credential can be recovered. At LNVPS a missing old seed or
index loses the vendor key, so stop, reinstall and deletion confirmation are all unavailable,
and the machine stays shown as existing and billed. An operator's report of a manual action
establishes no deletion, billing cessation or cleared obligation.

`SEC-4` is unchanged, including its abandonment authorization for this setup's own create
response or key-tied evidence. Retained barriers, identity exclusions, host-pin rules, uncertain
outcomes and the exposure and billing displays stay in force.

## Readings not selected

- **A listing or sheetless discovery as destructive authority.** `SEC-4` already refuses it.
  `SEC-4` says "What an adapter can list of the account is displayed and never relied on" and
  "A mapping imported from a recovery sheet is never enough by itself."
- **A new adoption card or recovery-evidence rule** admitting a listed machine into destructive
  authority. It would create general listed-object adoption and a second authorization home.
- **Keeping `CNF-84`'s LNVPS stop without the key.** It contradicts `STA-17`'s refusal, which
  stands.
- **Treating abandonment or a separately started setup as an in-setup third rung or an extra
  order** under this decision. The LNVPS setup flow governs those until its in-setup replacement
  order is admitted.

## Consequences

`STA-15` holds the rule, and `STA-22b` and `STA-17` point to it. `CNF-84` and the LNVPS
recovery admission row check the distinguishing cases. Nothing here enables pending
bare-seed import, per-machine discovery, the coordinated format and recovery amendment, the
dedicated rescue rekey, or any installation acceptance or reset gate.
[ADR-0036](./0036-first-contact-is-never-trusted-through-the-relay.md)'s sentence that such a
machine "is destroyed and recreated" is qualified by this record.

*Renumbered 2026-11-05:* this record merged as ADR-0053 on the same day as the setup record
that holds that number, which merged first. The tracker's closure of tw-yhd cites it as
ADR-0053; that citation means this record.
