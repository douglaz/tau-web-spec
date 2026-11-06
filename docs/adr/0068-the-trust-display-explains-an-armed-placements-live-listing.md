# The trust display explains an armed placement's live listing

Decided 2026-11-06 (`tw-3o0` comment 140000001). `SEC-6` owns the display statement;
`ARC-43` keeps the placement and report rules; `CNF-42` and `CNF-95(h)` own the cases.
This record adds no rule of its own.

## What was undecided

`ARC-43` says "The card is not offered for an armed reference, which keeps its scan until a
rotation, destruction or local-store loss ends it". An operator who revoked a key at its service
could still see its placement listed live, without a report card or an explanation beside it.
Whether the trust display should explain that window was undecided.

## The shape chosen

**A fixed statement, no operator act.** The statement belongs beside each armed live placement
in `SEC-6`, with the existing placement rule quoted from `ARC-43`. It records no operator
assertion and adds no state. The report, its finality, the scan, the reference, the live listing,
row 23's lifetime, the `exec` wait, re-arm, the sheet and its format retain their existing rules.

The statement promises no scan past the armed state: it says revocation at the service alone
ends neither the listing nor the scan, and names rotation and destruction as the ends only
"while its reference stays armed". Local-store loss is not a rotation or destruction:
`ARC-43` says "once that reference is unarmed again,
after a local-store loss for instance, the report is offered again". The statement cannot
promise a scan through that loss.

## Why

The fixed-statement option was accepted under the owner's 2026-11-05 panel rule, 4 of 4;
a fifth seat was unavailable. The armed-state qualification also had agreement from 4 of 4.
The pick adds a display duty and narrows or widens none of ADR-0057, ADR-0061, ADR-0062 or
ADR-0064. The qualification makes the option's scan wording conditional on the reference
remaining armed; it changes no earlier decision.

The operator reads the explanation where the live placement appears. A fixed statement uses
only the arming state the harness already holds; it needs neither evidence of service revocation
nor another operator assertion and its persistence rules.

## Alternatives considered

| Option | Disposition |
|---|---|
| Silent on purpose: no display change and no new act, with the reason recorded here | Not selected. The operator would still see a live placement without the explanation. |
| A non-final operator note beside one armed placement | Not selected. It adds an act and leaves journaling, export, Restore, withdrawal and the later unarmed transition to decide; a sheet-borne note also needs a change to the version-7 format. |

## Consequences

`SEC-6`, the listing pointer under `SEC-CLAIM`, `CNF-42` and `CNF-95(h)` change together.
`ARC-43`, `SEC-5`, row 23, `STA-16` and the credential format are unchanged. The formal
companion has no placement or scan-reference state and is unchanged.
The later qualification of which rotation ends a disposed placement is recorded in
[ADR-0070](./0070-a-rotation-keeps-a-possibly-unfinished-predecessors-reference.md).
