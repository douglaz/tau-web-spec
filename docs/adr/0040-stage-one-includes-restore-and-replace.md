# Stage 1 includes Restore and Replace, with manual relay retirement

Decided 2026-10-06. The first maintained cloud machine needs a recovery story at delivery,
not after the first phone is lost. The chosen option is **A′**: export, Restore and Replace's
machine half in stage 1, with its manually enrolled relay pass retired by the publisher.
The owning rules are `STA-15`–`STA-17`; the applicability table in `07-conformance.md` owns
which evidence completes each stage. This record amends
[ADR-0020](./0020-recovery-roots-in-the-vendor-account.md).

## Why Restore alone is not enough

A phone can lose its local store without being stolen; non-revoking Restore preserves the
machine's state in that case. Theft is different. The seed is encrypted on the phone, so
its backup is not evidence that the stolen device has no copy.

*Amended 2026-10-06 to correct the original quotation's attribution to `SEC-5`'s seed row.*
`STA-17` says "A stolen phone's encrypted store may eventually be unlocked" and "The old seed
is not revocable; changing what the browser uses is not removing a thief's access".
`STA-17` says "Recovery after a *lost* phone revokes;
restore after a *dead* one may not". Reusing the old key after theft leaves that key authorized.

Restore also reaches an allocation dead end without Replace. `STA-22b` says "a seed imported
after loss of the canonical journal may restore listed identities but MUST NOT allocate new
ones" and "To allocate again, use Replace with a freshly generated seed". An old sheet cannot
prove that later allocations never happened. Keeping Restore while omitting Replace would
preserve access but strand the restored operator when they next need a new identity.

The relay did not need to make that choice all-or-nothing. Stage 1 enrolls a pass by hand;
retiring that record and recording the new key uses the same publisher role. Signed
revocation remains paid/public-relay work. Robot rescue likewise belongs to the dedicated
path rather than to proof that cloud Restore works.

## Alternatives considered

| Option | Disposition |
|---|---|
| **A — export, Restore and full Replace in stage 1** | Keeps recovery and revocation together, but the unqualified acceptance set also pulls in signed relay revocation and Robot rescue. Those are different deployment milestones. Refined into A′. |
| **B — export and Restore; defer Replace under a label** | Rejected. A label does not revoke a stolen phone's access and is not an acceptable weaker mode: silent use of a copied key does not show its harm when it happens. It also leaves the allocation dead end. |
| **C — no recovery; destroy and recreate** | Rejected as the stage-1 policy. It discards recoverable machine state and the exported inference balance, and conflicts with `STA-15`: "The recovery sheet MUST be exported before a **maintained cloud** machine's setup completes". Destroy/recreate remains the no-sheet cloud remedy, not a substitute for export. |
| **A′ — export, Restore and machine Replace; relay retirement by hand** | Adopted. Keeps maintained-cloud recovery and theft response together without requiring the later relay purchase/revocation flow or the dedicated recovery path. |
| **B′ — publisher deferral of PRE-SCALE Replace applicability** | Rejected in favor of A′. This was a publisher stage-gating proposal, **not an operator waiver**: retain export and Restore, defer machine Replace and its partial-Replace evidence until before stage 2/public enrollment, and state destroy/recreate under a fresh seed plus application-secret rotation as the interim theft remedy. It reduces first-stage work but sacrifices state-preserving replacement. |

## Consequences and limits

The stage-1 recovery row covers `CNF-19`, `CNF-20` and `CNF-84`, with `CNF-10`'s export case.
Only the Robot rescue case of item 84 is assigned to the dedicated row; item 60's signed
revocation stays in the paid/public row. These applicability changes move no severity tier.
`STA-17` owns the remote key order, manual confirmation and partial-Replace reporting: "The
UI MUST NOT claim the old pass revoked before that confirmation".

Recovery knowledge is separate from recovered access. `STA-16` owns the "unknown since
export" state of placements, weaker modes and the declaration, and its reapproval boundary.
`STA-23` owns the persistent-storage request and visible refusal. Neither is a promise that
a phone retains its store. Placement metadata and scan recovery are addressed by
[ADR-0041](./0041-secret-scan-rearms-from-machine-reports.md).

Key replacement does not undo a secret already read or persistence already installed by a
thief. Those limits and the destroy/rebuild offer are `STA-17`'s; inference balance remains
bearer and unrevocable. Re-arming a scan changes no service credential. Cloud recovery with no
sheet still uses `STA-15`, with no revived unpinned rescue login.

The account-free vendor's recovery root remains open in T47. `OPN-24`'s probe list includes
inventory and destruction; a probe is evidence about an API, not a decision about that root.
`OPN-3` tracks the evidence at each milestone. No integrated recovery result is claimed here.
