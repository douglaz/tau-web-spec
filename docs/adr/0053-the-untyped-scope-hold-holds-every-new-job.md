# The untyped-scope hold refuses every new job and carries by exact origin

Decided 2026-11-02 and 2026-11-03 (`tw-pgp` comments 35000001 and 46000001). `STA-24` owns the
hold, its coverage, its release and both inheritance rules; `SEC-4` owns the scope's local
permission and its exclusivity; `STA-23` owns what ends a session; `SEC-14` owns acceptance;
`STA-20` owns collection; `ARC-43` owns the local paste. This record amends ADR-0038, ADR-0044
and ADR-0050 by note and adds no rule of its own.

## What was undecided

`STA-24`'s destructive hold under an untyped vendor scope kept "the model's box-plane commands"
stopped, so a job the harness starts itself was unsettled. The typed stop, "A destructive
continuation stops every box-plane job", is a separate rule and did not settle it. `STA-24`'s
inheritance covered only "A scope re-approved for the same origin and credential", and ADR-0038
recorded that "a token rotated at the same origin starts with no unresolved barrier". No text
said when the scope's local permission closes, whether a later scope's calls inherit a standing
destructive hold, or whether the hold reaches a successor session's jobs.

## The shape chosen

Each of the five decisions below is an owner's choice, recorded as an amendment, not as what
the former wording already meant.

**Every new job is held** (2026-11-02). While a destructive disposition stands on the scope,
every new box-plane job to a machine the hold covers is refused, whoever starts it: the model's
commands, a digest, a reboot, a delivery-check read, a relabel, a key migration. A freshly issued
read job is a new job. Collecting an existing record and the local paste stay available under
their own guards; the paste clears nothing and authorizes no job. The operator's replacement of
the disposition is still the only release. The hold overrides no deletion, pin, binding,
command-hold or custody requirement, and adds no recovery sweep or protection for work the
journal omits.

**A standing destructive hold carries to later scopes at the same exact origin** (2026-11-03,
reading B). After a token rotation or a reapproval, calls through the later scope are refused,
whatever their credential, approval id or overlap with the held machines, and a fresh session
does not get past it by approving one. The inheritance is by exact origin, not by vendor identity
across origins, and supplies no approval or binding. The original disposition and its calls keep
their identities and resource; nothing in the journal is rewritten.

**An unresolved call is inherited by every later scope at the same exact origin** (2026-11-03,
reading A). No credential is compared, so the same result follows after the credential has been
erased. The cost accepted is that a different account at the same origin is blocked until the
original call has a valid terminal record. Same-origin, same-credential inheritance stays
mandatory. Session end, credential erasure, reapproval and work done at the vendor by hand are
not terminal reconciliation. A valid terminal record ends the barrier; a destructive disposition
then engages the inheritance above, and a continuing one creates no hold.

**The scope's local permission closes at the session's end** (2026-11-03, reading A). Its
exclusivity closes with it. A successor approves afresh, on the card where it accepts the mode,
and one card act may do both. Resupplying a credential or accepting the mode alone carries no
permission over. Closing is not revocation at the service, erases no history and ends no display
of a still-exposed credential. "Session end" is what ends a session under `STA-23` as ADR-0052
left it: a Lock, a reload or a hide ends none.

**A successor's new jobs stay held on the machines the hold covers** (2026-11-03, reading A),
the original set's lawful later growth up to its final recorded reach included, until the
replacement. The successor's unrelated machines are not held, and the hold applies whether or not
the successor approves a vendor scope. Closing the predecessor's permission is not the
replacement.

**What stays as it was.** No token fingerprint, durable credential-derived reference, account
proof or runtime framework is added. Known-machine exclusivity is checked on its own, and a new
token does not evade it. No untyped call becomes a typed read by its name. Machines outside the
bound set, or at another vendor, are not held. None of these is the replacement: manual vendor
work or its report, late observations, a key replacement, a new token or approval, local buffer
clearing, a Lock, actual session end, or a true revocation at the service, which ends that
credential's external authority but proves no deletion or operation success.

**Classification.** The readings disagreed on two of these decisions, and the disagreement is
retained. For the permission lifetime, two readings called it an amendment and one a
source-forced clarification. For successor jobs, two called it a clarification and one an
amendment.

## Alternatives considered

| Decision | Option not selected |
|---|---|
| Calls under an inherited destructive hold | A: the same origin, and overlap with the originally held machines. |
| Calls under an inherited destructive hold | C: genuinely new scopes treated separately. |
| Calls under an inherited destructive hold | D: carry only under the same credential. |
| Calls under an inherited destructive hold | E: an explicit operator link to the predecessor scope. |
| Calls under an inherited destructive hold | F: lineage by a verified account proof. |
| Calls under an inherited destructive hold | G: refuse the new scope's approval itself. |
| Calls under an inherited destructive hold | H: carry by vendor identity across origins. |
| Unresolved calls after a credential change | B: keep the same-credential boundary. |
| Unresolved calls after a credential change | C: allow the call and show the outstanding one on its card. |
| Unresolved calls after a credential change | D: explicit operator linkage between scopes. |
| Unresolved calls after a credential change | E: refuse the new scope's approval while the call is unresolved. |
| Unresolved calls after a credential change | F: inherit only where the new scope overlaps the original reach. |
| Local permission lifetime | B: reuse after the successor's fresh acceptance, automatic transfer included. |
| Local permission lifetime | C: keep until an explicit local close, then approve anew. |
| Local permission lifetime | D: explicit adoption of the earlier permission by the successor. |
| Local permission lifetime | E: permission left attached to the ended session. |
| Local permission lifetime | F: expiry on a timer. |
| Local permission lifetime | G: expiry on an ordinary hide. |
| Successor jobs | B: job applicability ends with the old session. |
| Successor jobs | C: coverage frozen when the disposition is recorded. |
| Successor jobs | D: the successor's whole set at that vendor. |
| Successor jobs | E: held only if the successor also approves another vendor scope. |
| Successor jobs | F: refuse successor binding until the replacement. |

The all-new-jobs decision was chosen without a recorded competing reading. How a reinstall or an
abandonment is carried out by hand at such a vendor and what records it, and scopes that are not
a vendor's, stay open (`TASKS.md` T47). No credential-recognition mechanism is chosen, and no
claim is made that the former same-credential text already forced refusal after erasure.

## Consequences

`STA-24` and `SEC-4` change, with pointers from `ARC-15`, `SEC-14` and `STA-23`, `CNF-105`'s
cases, the T47 record and the state-machine atlas's pointers. ADR-0038, ADR-0044 and ADR-0050
gain notes. The hold, its inheritance and the permission lifetime remain prose only: the formal
companion carries no untyped pause or hold, and no existing theorem is evidence for them. This
record makes no capability, readiness or runtime claim; untyped scopes stay behind their
admission row.
