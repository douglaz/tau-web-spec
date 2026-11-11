# Paid session key 24-hour default lifetime: an owner-directed amendment

Decided 2026-11-10 (`tw-qe7.15`, comment 245000001) on the owner's instruction, from review item
R08, "Simplify paid inference choices and validate the real contract", part B. The owner answered
"24 hours". This is an owner-directed amendment of the offered default, not a clarification. It
changes one value, the lifetime the Start surface offers before the operator edits it, and nothing
else.

## Why

R08 part B said to measure before changing the default: observe representative end-to-end setups,
including provider waits and app switching, and amend the default only if 15 minutes caused
avoidable restarts. The owner decided now, without that observation, so the evidence is no longer a
precondition for this default. R08's concern was that a session's lifetime runs through provider
waits, hidden time and suspension, and expiry ends the session, so a short default might end useful
work and force a new Start with its own confirmation. R08 called that a hypothesis to measure; the
owner gave no further reason and chose the value.

## Decision and owner

`ARC-31a` owns the value: `ARC-31a` says "The visible offered default is 1440 minutes (24 hours),
exactly 86400 seconds". That is the top of the existing range, which is unchanged: `ARC-31a` says
"Lifetime is entered as a whole number of minutes from 1 through 1440 inclusive". The Start surface
in `ARC-31a` shows "the visible offered defaults 0.10 and 1440 minutes".

## What is amended

- The offered lifetime default moves from 15 minutes (900 seconds) to 1440 minutes (86400 seconds),
  in `ARC-31a`'s lifetime paragraph and its Start surface. No other text named the old value: not
  `CNF-69`, the fixture profile (`bundle/inference-profile-fixture-v1.md`, which already supports
  1 through 1440 minutes), the formal companion, another ADR or the state-machine atlas.
- What the operator gives up by accepting the default unchanged: a session key confirmed at the
  default stays usable for up to 24 hours instead of 15 minutes. `ARC-31a`'s exposure bound does
  not rest on the lifetime and is unchanged: `ARC-31a` says "The exposure from a leaked session key
  is the lesser of the remaining balance and that key's cap." A key's read of the account's usage
  history lasts as long as the key does; `ARC-31a` says "One limit is stated rather than solved".
- The paid session the default starts also ends at that expiry (ADR-0052: "for a paid session, its
  key's expiry or cap exhaustion"), so by default its machines and standing approvals stay live for
  up to 24 hours, and a lost-key hold lasts up to 24 hours: `ARC-31a` says "hold the session until
  End or original expiry". The live paid key ADR-0028 accepted ("A live paid key now sits encrypted
  on the phone") sits there for up to 24 hours too.
- Any of this was already possible by selecting 1440 minutes.

## What stays

- The explicit confirmation: `ARC-31a` says "Before a procured session starts, the operator MUST
  explicitly confirm its displayed limit and lifetime." The default is shown, editable in place,
  and confirmed by the Start action like any other value.
- Nothing pauses the lifetime: `ARC-31a` says "Hidden, frozen and suspended time after the lifetime
  origin counts toward the lifetime exactly as visible time does; it is never excluded, paused or
  added back."
- A default the pinned profile cannot support is disclosed, not replaced: `ARC-31a` says "An
  unsupported default is disclosed as unavailable and is not replaced silently."
- One mint per session, no renewal and no top-up, under `ARC-31a` and `STA-23`. Automatic renewal,
  which the owner also adopted (`tw-qe7.15`, comment 252000001), is a separate owner-directed
  amendment drafted on its own and is not part of this decision.
- The 0.10 offered cap, the 0.01 to 100.00 amount envelope, production minting's refusal until a
  real profile is reviewed and pinned, and the wait on dated real-provider evidence (`tw-qe7.16`).
- No theorem, witness, gate, conformance case or assumption boundary moves.

## Alternatives considered

| Option | Disposition |
|---|---|
| Keep 15 minutes until representative setups are observed (R08 part B) | Not chosen: the owner decided the default now. |
| Offer a task-appropriate recommendation instead of one default | Not chosen: the owner named one value. |

## Amended 2026-11-11: one automatic renewal

The automatic renewal this record set aside is now drafted as
[ADR-0085](./0085-one-automatic-paid-key-renewal-at-expiry.md). The 1440-minute default applies
per key, so a session confirmed at the defaults can run up to about 48 hours and spend up to 0.20.
"One mint per session, no renewal and no top-up" above, and the bullet saying the session ends at
that expiry with its machines and standing approvals live for up to 24 hours, record what was
decided then; a lost-key hold still lasts until that key's own expiry, and the top-up ban is
unchanged.
