# lnrent — tenant profile

Owned by [lnrent](https://github.com/douglaz/lnrent). Records:
https://github.com/douglaz/lnrent. Briefs supplied: none yet.
Profile revision: 1 (2026-09-10).

Schema: ADR-0030. Rules that only make sense here are the tenant's; everything else is the
harness's. Identifiers below keep their original numbers.

## Access model

Maintained (`ARC-27`). The box is re-entered by a later session bound to it.

## Machine class

Multi-tenant: it serves buyers the operator has never met. The class is the harness's
definition (`ARC-36`, in `01-architecture.md`); this profile only selects it, and by doing so
switches on the harness's spendable-key rule (`ARC-37`, `CNF-52`).

## Vendor products targeted

Dedicated. The first stage builds one lnrent box on a dedicated server
([ADR-0018](../../adr/0018-first-stage-is-one-lnrent-box-on-dedicated.md)).

## Machine set

One machine, so nothing is created as a set.

## Independence bound

None. lnrent has no quorum, so no independence relation binds.

## Delivery declaration

Pending: lnrent has not supplied one yet (https://github.com/douglaz/lnrent/issues/87). The
sub-slots below hold what the corpus already states; the rest is unspecified, and unspecified
blocks delivery. The answer format is the v1 template in
[`docs/design/delivery-declaration-v1.md`](../../design/delivery-declaration-v1.md), every
unstated field marked `unspecified`.

### Network policy

Not yet stated by the tenant. See https://github.com/douglaz/lnrent/issues/87.

### Service lifecycle

The daemon, `lnrentd`, must be enabled and survive every reboot, because it has to answer
while the operator sleeps (`ARC-39`).

### Permitted key material

Watch-only or delegated; no spendable key material. The prohibition itself is the harness's
(`ARC-37`, gated by `CNF-52`) and this profile cannot widen it. What is lnrent's is the
mechanism: on-chain receiving holds an extended public key and derives a fresh address per
order; Lightning receiving is delegated to a receiving service the operator chose, because it
cannot be watch-only.

### Drift checks

Not yet stated by the tenant. See https://github.com/douglaz/lnrent/issues/87.

### Required software and checks

Not yet stated by the tenant. See https://github.com/douglaz/lnrent/issues/87.

## Secrets and parties

The tenant's own credential for the receiving service is placed on its own machine (`SEC-5`
row 12), and that service is an elective party (`TRU-E9`).

## Runtime obligations

The machine is the capacity lnrent sells, so the obligation is met there by the tenant's own
software with no harness credential (`ARC-35`). Lightning receipt is delegated to a
receiving service under the harness's general permission for that (`ARC-38`); lnrent is
its first user, and the service is the elective party named above.

## Post-harness handoff

None. lnrent has no machinery that runs after the harness finishes.
