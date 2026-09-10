# ad-hoc — tenant profile

Owned by the publisher and shipped in the bundle. Records: this file. Briefs supplied: none yet.
Profile revision: 1 (2026-09-10).

Schema: ADR-0030. Rules that only make sense here are the tenant's; everything else is the
harness's. Identifiers below keep their original numbers.

## Access model

Maintained (`ARC-27`). The machine is re-entered by a later session bound to it.

## Machine class

Single-purpose.

## Vendor products targeted

Dedicated and cloud.

## Machine set

One machine, so nothing is created as a set.

## Independence bound

None. Ad hoc use has no quorum, so no independence relation binds.

## Delivery declaration

Minimal, and it is signed content shipped in the bundle. An unspecified field blocks delivery;
an explicit empty set does not. Listeners the operator adds during a session are per-machine
journal input, not profile content.

### Network policy

sshd on port 22 with key-only authentication, and no other listener. Outbound: an explicit
empty set of restrictions, not an unspecified field.

### Service lifecycle

None: ad hoc use ships no software of its own, so the declared set is empty rather than
unspecified.

### Permitted key material

None beyond the harness session's SSH client public key in `authorized_keys` (`SEC-1`).

### Drift checks

None: the declaration names no state to re-check, and the empty set is explicit rather than
unspecified.

### Required software and checks

No default credentials.

## Secrets and parties

None. Ad hoc use places no tenant secret on the machine and introduces no elective party.

## Runtime obligations

None.

## Post-harness handoff

None.
