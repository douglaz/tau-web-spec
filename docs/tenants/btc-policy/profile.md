# btc-policy — tenant profile

Owned by [btc-policy](https://github.com/douglaz/btc-policy). Records:
https://github.com/douglaz/btc-policy. Briefs supplied: none yet.
Profile revision: 1 (2026-09-10).

Schema: ADR-0030. Rules that only make sense here are the tenant's; everything else is the
harness's. Identifiers below keep their original numbers.

## Access model

Sealed (`ARC-27`). SSH is uninstalled after setup and upgrade-in-place is forbidden, so no
later session re-enters a member.

## Machine class

Single-purpose: a vault node and nothing else.

## Vendor products targeted

Dedicated and cloud. Both are in scope for members.

## Machine set

Five machines by default (3-of-5); three (2-of-3) for testing and small values
([ADR-0008](../../adr/0008-three-of-five-default-and-its-economic-floor.md)). The members of
one federation are created as a set, all-or-nothing.

**ARC-20** Federation creation MUST be all-or-nothing
([ADR-0012](../../adr/0012-a-federation-is-created-only-when-every-member-works.md)). A
partially-formed federation has no honest description: a 3-of-5 vault with four working
members is not "80% set up" — its real threshold, failure modes, and security claim are all
different from the thing the operator approved, and none of those differences are visible
from a progress bar.

**SEC-T2** A federation MUST NOT be formed until every member is provisioned, hardened, and
reachable.

## Independence bound

The tenant's own quorum-relative relation, which binds as written.

**SEC-T3** No cloud vendor's machines may reach a federation's quorum — the tenant's rule,
which binds. The harness ships a stricter default: one vendor, one machine. The two are one
rule at two strengths: btc-policy's quorum-relative form is the bound an implementation MUST
enforce, and the flat form is the default the harness applies — relaxable by the tenant
toward its own bound, never past it, and never by the harness on its own.

## Delivery declaration

One vault protocol port, a node running at delivery that dies on the first reboot by design,
and member keys generated on the machine and never exported.

### Network policy

**SEC-T1** Members MUST NOT be reachable from each other except on the vault protocol port,
mutually authenticated, with everything else denied at the vendor firewall.

**ARC-23** Members MUST open connections to each other only on the vault protocol port,
mutually authenticated. No SSH between members, no arbitrary traffic, everything else
denied at the vendor firewall
([ADR-0010](../../adr/0010-members-reach-each-other-on-one-authenticated-port.md)).

**Network reachability is a foothold on the same terms as a credential.** If the machines
can reach each other, a model controlling machine 1 can attack machines 2 through 5
directly, and `SEC-1` is broken by the network rather than by any grant. A k-of-n threshold
assumes faults are **independent**, and one model able to attack four other machines
produces *correlated* faults — the one assumption a Byzantine threshold cannot survive
losing.

The vault protocol must therefore be safe against actively hostile peers, not merely faulty
ones. This is confirmed to be btc-policy's own premise rather than a new requirement.
Because firewall rules are cloud-plane, the deny-by-default posture is visible to the
operator, and a brief cannot quietly widen it.

### Service lifecycle

The node must be running at delivery and is not required to survive a reboot: sealing is what
makes its duress protection real (`ARC-39`).

### Permitted key material

Member vault keys, generated on the machine and never exported. Recovery descriptors come from
the operator (`SEC-T4`, under Secrets and parties).

### Drift checks

Not yet stated by the tenant.

### Required software and checks

Not yet stated by the tenant.

## Secrets and parties

Sealing removes the model before anything valuable exists, which is the phase constraint the
rest of this slot depends on.

**SEC-T4** The AI MUST NOT touch key material. Recovery descriptors come from the operator;
member keys are generated on the machine and never exported. **This is achievable because
btc-policy designs the whole procedure for it** — the model is gone, by sealing, before
anything valuable exists. A maintained tenant cannot have this, because the model keeps
coming back, and for those the harness offers `SEC-6` instead.

## Runtime obligations

After sealing a member serves authenticated peers on its vault protocol port, with no harness
credential (`ARC-35`).

## Post-harness handoff

The coordinator: this tenant's machinery, running only after every member is provisioned,
locked down, delivered and sealed (`ARC-19`, `ARC-19a`,
[ADR-0026](../../adr/0026-the-coordinator-is-the-tenants-and-runs-after-sealing.md)). Its input
is member endpoints plus operator-supplied recovery descriptors, and it holds one
browser-derived peer credential per federation, installed into each member's peer set before
sealing.
