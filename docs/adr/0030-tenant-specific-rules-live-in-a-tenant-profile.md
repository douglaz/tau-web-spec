# Tenant-specific rules live in a tenant profile with a fixed schema

The general specification had absorbed rules that belong to one tenant: btc-policy's
federation, coordinator and member material (`ARC-19`–`ARC-23`, `SEC-T1`–`SEC-T4`) and
lnrent's multi-tenant, no-spendable-keys and delegated-receiving material (`ARC-36`–`ARC-38`).
[ADR-0016](./0016-the-harness-isolates-and-counts-tenants-set-thresholds.md) stated the test
for telling them apart and a disposition of "retire and point", but nothing carried it out,
and what a new project must hand the harness in order to be a tenant was scattered across five
requirements with no document naming the whole.

**Decision.** Every tenant has a **profile**: one document with a fixed set of slots. Rules
that only make sense inside a profile are the tenant's; rules that hold for every profile are
the harness's. The general specification refers to "the profile" and never names a tenant in a
normative sentence; examples may. A new project integrates by writing a profile, so the
schema is the integration contract. Ad hoc use is a built-in profile owned by the publisher.

## The schema

Header: tenant identity, where its own records live, the briefs it supplies, and a profile
revision.

| Slot | Form |
|---|---|
| Access model | `maintained` or `sealed` (`ARC-27`) |
| Machine class | `single-purpose` or `multi-tenant`. A switch on a harness rule (`ARC-36`), not content |
| Vendor products targeted | dedicated, cloud, or both. Recovery and the lockdown checklist key on it |
| Machine set | count, and whether creation is atomic (`ARC-20`, `SEC-T2`) |
| Independence bound | the tenant's own quorum-relative relation, or none (`SEC-T3`'s binding form) |
| Delivery declaration | network policy in and out, per-service lifecycle, permitted key material, drift checks, required software and checks (`ARC-39`) |
| Secrets and parties | tenant secrets placed on machines (`SEC-5` row 12), elective parties introduced (`TRU-E9`), phase constraints such as sealed-before-anything-valuable-exists (`SEC-T4`) |
| Runtime obligations | what must hold while the browser is closed and how it is discharged (`ARC-35`, `ARC-38`) |
| Post-harness handoff | machinery, inputs, credential provisioning and acceptance at the tenant's peer API, failure outcome, or none (`ARC-19`, ADR-0026) |

Slots the harness branches on or displays take structured values; the reasoning behind them
stays the tenant's prose.

## Two guards, which are harness rules and live outside every profile

- **A delivery declaration narrows what the harness gates; it never widens it.** `ARC-37`
  remains a harness rule keyed on the machine-class value and `CNF-52` stays BLOCKING, so a
  profile cannot switch a gate off with prose. The same holds for `CNF-50` against a wide
  listener range. The one slot that may relax a shipped default is the independence bound,
  which moves the one-vendor-per-machine default toward the tenant's own quorum-relative
  bound and never past it (`OVR-5`, `SEC-T3`).
- **The run records its contract.** The journal holds the profile identity, revision and the
  resolved declaration for each machine; resume and scans use that record, so a revised
  profile cannot silently redefine "delivered".

## Considered options

**Marked sections per topic file**, extending `04-security-model.md`'s "supplied by btc-policy"
pattern with `-T` identifiers everywhere. Rejected: it keeps one tenant's rules spread across
eight files and still leaves the integration contract implicit.

**Move tenant rules to the tenant repositories and keep pointers**, ADR-0016's original plan.
Kept as the eventual destination for btc-policy's own invariants, rejected as the mechanism:
lnrent's repository has no concept of the harness, and pointers alone never state what a
tenant must supply.

**Optional profile, with ad hoc use running without one.** Rejected: it opens a second
integration path and puts a hole in `CNF-49`, "no declaration, no delivery".

## Consequences

The general files lose their federation material to the btc-policy profile; the identifiers
that move keep their numbers under the profile that owns them. lnrent's material turned out
to be harness rules with lnrent as their first instance: `ARC-36` defines the class every
profile selects from, `ARC-37` is the gate the first guard protects, and `ARC-38` is a
permission any tenant may use. They stay in `01-architecture.md`, and lnrent's profile
carries only its values. T25 still lifts the Lightning mechanism sentence out of `ARC-37`. The
leaks that remain after the move are a migration list, not a redesign: derivation role 4 and
the "federations" allocation family in `STA-22a`/`STA-22b`, `SEC-5` row 17, `SEC-T3`'s
stricter default, the coordinator paragraphs in `SEC-1` and `ARC-12`, the federation
applicability row in `07-conformance.md`, and the glossary's Member, Coordinator and
Threshold entries. The ad hoc profile's minimal declaration is signed content; operator-added
listeners are per-machine journal input, and an unspecified declaration field blocks delivery
where an explicit empty set does not.

**A tenant is a directory, and briefs split by owner.** `docs/tenants/<name>/profile.md`
holds the slots and `docs/tenants/<name>/briefs/` the briefs keyed on that tenant's software,
delivery first. `docs/briefs/` keeps what is keyed on a vendor product or a distribution:
the install brief and the vendor lockdown checklist. The tenant half of lockdown is not a
brief; it is the delivery check reading the declaration (`ARC-17`). The bundle ships the same
tree, so a new tenant is a new directory.

Reviewed independently by two readers before adoption on 2026-09-09; both raised the first
guard, one raised the second, and their corrections to the draft schema are folded in.
