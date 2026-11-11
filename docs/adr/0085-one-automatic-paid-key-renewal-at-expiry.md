# One automatic paid-key renewal at expiry: an owner-directed amendment

Decided 2026-11-10 (`tw-qe7.15`, comments 245000001 and 252000001) on the owner's instruction,
from review item R08, "Simplify paid inference choices and validate the real contract". The owner
picked "Automatic renewal", whose option text was "Mint a new key silently at expiry. Removes
your per-key spending OK, so it changes a security rule." A review panel worked out the
mechanics. The owner's adoption question offered three options: adopt at 0.10 per key
(recommended), adopt at 0.05 per key, or drop it. The owner picked "Adopt, 0.10 per key
(Recommended)". This is an
owner-directed amendment that loosens a security rule, not a clarification. It reverses in part
[ADR-0028](./0028-procured-inference-is-the-operators-balance.md)'s "There is still one mint per
session" and the matching sentences of
[ADR-0052](./0052-no-local-event-ends-a-session.md). It also reverses the review's own advice
against silent inference renewal. Those records' other decisions remain the historical record.

## Why

R08 said a paid session's lifetime runs through provider waits, hidden time and suspension, and
expiry ends the session, so a useful session can end and force a new Start with its own
confirmation. The owner chose to let the session carry on once at expiry rather than to ask
again. The panel, five readers in round one and four counted in round two, settled the design
under the owner's 2026-11-05 panel rule:

- renewal only at expiry, never at the cap; a session total confirmed on the same Start screen
  with no new input; a successor minted only after the old key's expiry, with no overlap; a
  failed renewal that ends the session; the same terms on every key; every hold still applying
  (five of five);
- the 1 to 1440 minute range applies per key (four of five);
- exactly one renewal, so at most two keys, with a session total of twice the cap (three of
  four);
- nothing revoked at renewal, and End revoking every key (four of four);
- renewal offered only at a per-key cap of 50.00 or less (four of four).

Whether `ARC-31a`'s 100.00 bound limits one key or one confirmation did not settle (one to three,
"cannot tell from the text"). The 50.00 guard keeps one confirmation's keys within 100.00 under
either reading, so the question is moot for this design.

## Decision and owner

`ARC-31a` owns the renewal, in its paragraph "One automatic renewal at expiry": `ARC-31a` says
"The one automatic renewal is offered only at a confirmed cap of 50.00 account units or less, so
one confirmation's keys together stay within the 100.00 application ceiling." `ARC-31a` says
"The renewal follows only the established expiry of the session's first key, at that execution
opportunity." The Start surface in `ARC-31a` shows the per-key cap and lifetime and "the session
total of twice the cap". The offered per-key default stays 0.10, so by default a session spends at
most 0.20 and runs up to about 48 hours at the 24-hour default lifetime
([ADR-0078](./0078-paid-session-key-24-hour-default-lifetime.md)). `STA-23` now ends a paid
session "At cap exhaustion, or at an expiry at which `ARC-31a` leaves no renewal", and withholds
work at an expiry where the renewal can still follow.

## What is loosened

- `ARC-31a`: one mint attempt per session becomes one attempt per mint, the first key's and the
  renewal's; "No second mint is admitted" becomes "No other mint is admitted"; expiry ends the
  session only with no renewal left; the Start surface's "one mint and no renewal" becomes one
  renewal at most; the leaked-key exposure bound is restated per session as twice the cap.
- `CNF-69`: "admit no silent replacement mint" now admits the one confirmed renewal, and the item
  exercises it.
- `CNF-116`: "one mint" and "Paid expiry/cap ends" admit the renewal.
- `STA-23`: the expiry half of "MUST end at the next execution opportunity" ends only with no
  renewal left. Hiding, suspension, return and funding still never renew.
- `SEC-5` row 2: the "One session" lifetime and "up to its own cap" are restated so that a
  session holds at most two keys and spends up to twice the cap.
- Revocation timing: the superseded key's revocation attempt moves from its expiry, when the
  session used to end, to session End, up to one more lifetime later.
- In effect, one confirmation's paid time is no longer bounded by 1440 minutes, and one
  confirmation can spend up to twice the shown per-key cap. The text promises no hard 48-hour
  stop, because a late-scheduled renewal starts its own lifetime late.
- The operator's separate confirmation of each key's spend is removed for the second key: the one
  Start confirmation covers both.

**Narrowings against the option text** ("Mint a new key silently at expiry"): one renewal only;
expiry only, never the cap; renewal unavailable above a 50.00 cap; a failed renewal ends the
session; any binding change stops the renewal; only a sealed, validated predecessor with no
lost-key hold renews. Renewal at every expiry would be a later widening for the owner to choose.

## Formal companion

Four statements in `TauWeb.Authority` change, as the adoption directs:

- `TauWeb.Authority.assess`: expiry of the current key with renewal authority left withholds
  ordinary work and marks the renewal due instead of ending the session; no later assessment of
  that key lifts the withholding. Cap exhaustion still ends, and so does expiry with no renewal
  authority left.
- `TauWeb.Authority.keyEligible`: compares request evidence with the session's current key, the
  original until the renewal and then the successor, instead of only the single original key.
- `TauWeb.Authority.expired_session_ssh_refused` and `TauWeb.Authority.validation_terminal_ends`:
  each keeps its no-renewal conclusion unchanged and adds a rollover case, where expiry with
  renewal authority left refuses the work without ending the session, and cap exhaustion still
  ends it.

`TauWeb.Authority.repair_cannot_renew` and `TauWeb.Authority.cap_end_cannot_repair` prove
unchanged, with their statements and histories as before. New declarations model the renewal
itself (`TauWeb.Authority.renew`, `TauWeb.Authority.renewalLeft`) and its refused/admitted pairs,
including the two must-hold properties under renewal authority. A successor is installed only
with the same cap and its own key, origin and expiry. Existing structures gain renewal fields
that default to no renewal, the local step gains the renewal case, and existing candidates and
histories keep their values. Authority witness schema 6 adds
the renewal event and actor fields in a new file name; every schema-5 trace keeps its events and
steps. No gate script's policy changes; controls follow the new guards. The per-key cap limit
that makes renewal available, the session total and End's revocation of every key stay outside
the proofs, as the cap arithmetic always has.

## What stays

- The explicit Start confirmation in one action, the 1 to 1440 minute range, the 0.01 to 100.00
  amount envelope, the 0.10 and 1440-minute offered defaults, and an unsupported default
  disclosed rather than replaced.
- The top-up ban, the funding rules, `STA-20`'s and `STA-24`'s holds, the End and cancellation
  fences and End's irreversibility.
- Every mint's intent, terminal, seal, lost-key and issuer-validation rules, now applied to the
  renewed key too.
- Production minting's refusal until a real profile is reviewed and pinned. Use with the real
  provider still waits on dated issuer evidence (`tw-qe7.16`).

## Alternatives considered

| Option | Disposition |
|---|---|
| Drop it: one key per session, ending at expiry | Not chosen by the owner. |
| A typed session total allowing renewal at several expiries | The round-two dissent; not chosen (three of four for one renewal). |
| Renewal at cap exhaustion | Not chosen: renewal happens only at expiry (five of five). |
| Revoke the superseded key at renewal | Not chosen: nothing is revoked at renewal, and End revokes every key (four of four). |
| Offer 0.05 per key, keeping the default session total at 0.10 | Not chosen by the owner. |
