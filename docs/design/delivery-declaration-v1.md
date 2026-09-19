# Delivery declaration v1

Normative companion to `ARC-39` and ADR-0030's "Delivery declaration" slot. The structured form
the delivery check (`CNF-49`–`CNF-53`) reads. A tenant's profile carries the prose; a v1
document carries the values the harness measures against — today the examples below, and a
file beside each profile once T28 lands.

## Presence rule

**Every field below is present, always.** Its value is one of:

- a concrete value or non-empty list — checked as declared;
- an explicit empty list `[]` — the tenant has said *none*, and **what *none* means is the
  field's own**, stated in its row below. For a field that declares what must exist (inbound
  listeners, permitted key material) an empty list means *nothing may*, and anything found is a
  finding; for a field that declares a restriction or an obligation (outbound restrictions,
  services, drift checks, required software) it means *none is declared* and there is nothing to
  check. Until 2026-09-16 this bullet read "nothing to check, delivery may pass" for every field,
  which for `listeners.inbound` was the opposite of its row: an implementation reading the rule
  and not the rows would have passed a machine with any listener at all;
- the string `"unspecified"` — the tenant has not said; **delivery is blocked** (ADR-0030).

An absent field is a schema error, not `unspecified`. This is what keeps "absent means empty"
from passing delivery silently. The harness invents no default for any field. Presence is one
rule for every field; meaning is one rule per field, and an implementation carries the two
separately — a field is *missing*, *unspecified*, or *specified with a value*, and only the third
is evaluated, under that field's semantics.

## Shape

JSON object, `version: 1`. Field names are fixed; values are as described.

| Field | Value | What the check does |
|---|---|---|
| `version` | `1` | Refuse any other |
| `listeners.inbound` | list of `{proto: "tcp"\|"udp", port: n, from: "any"\|"peers"\|"none"}` | Every answering socket must match an entry; an undeclared one is the finding (`CNF-50`, `CNF-51`) |
| `listeners.outbound` | list of `{proto, host, port}` restrictions, or `[]` for none; `host` is a DNS name, a CIDR block, or `"any"` | `[]` means no outbound restriction is declared, explicitly |
| `services` | list of `{name, lifecycle: "running-at-delivery"\|"enabled-survives-reboot"}` | Demonstrated exactly as declared; nothing beyond it is asserted (`CNF-53`) |
| `key_material.spendable` | `false` on a multi-tenant machine (`ARC-37`, harness rule; a profile cannot set `true` there) | Searched for after install (`CNF-52`) |
| `key_material.permitted` | list of `{kind, where}` describing the **tenant's** key material expected on disk, or `[]` for none. On a multi-tenant machine only public or watch-only kinds are admissible (`ARC-37`); a single-purpose machine may list private, non-spendable material, as btc-policy's member vault keys are | Tenant material outside the list is a finding. What the harness itself places — the machine's SSH host keys and the machine's own client public key (`SEC-1`, `CHN-R1`) — is always expected and is never listed |
| `drift_checks` | list of `{name, command, expect}` the maintained re-check runs, or `[]` | Run by the machine's own session on re-entry (`ARC-26`) |
| `required` | list of `{name, check: command, expect}` — software and checks that must hold at delivery, or `[]` | Run at delivery |
| `default_credentials` | `"none"` or a list of what must have been changed | Checked at delivery (`ARC-17`) |

The field and what-an-empty-list-means columns of this table are carried as
`TauWeb.Declaration.row` (ADR-0032), one row per field of `TauWeb.Declaration.Field`, so a field
added without its row does not build; `TauWeb.Declaration.empty_inbound_finding` and
`TauWeb.Declaration.empty_outbound_passes` prove the two readings of `[]` above, and
`TauWeb.Declaration.spendable_multi_tenant_refused` that `true` for `key_material.spendable` on a
multi-tenant machine is refused. The value shapes and the commands stay here.

`command`/`check` strings are box-plane commands the harness composes into typed reads; their
output never enters model context as authority (`SEC-8`).

## ad-hoc, v1 (complete)

```json
{
  "version": 1,
  "listeners": { "inbound": [ { "proto": "tcp", "port": 22, "from": "any" } ], "outbound": [] },
  "services": [],
  "key_material": { "spendable": false, "permitted": [] },
  "drift_checks": [],
  "required": [],
  "default_credentials": "none"
}
```

Listeners the operator adds during a session are per-machine journal input, not profile
content (ad-hoc profile).

## lnrent, v1 (template, every field unspecified)

To be sent to the tenant (T28) as the answer format for
[douglaz/lnrent#87](https://github.com/douglaz/lnrent/issues/87). The two values the corpus
already states are filled; everything else waits for the tenant.

```json
{
  "version": 1,
  "listeners": { "inbound": "unspecified", "outbound": "unspecified" },
  "services": [ { "name": "lnrentd", "lifecycle": "enabled-survives-reboot" } ],
  "key_material": { "spendable": false, "permitted": "unspecified" },
  "drift_checks": "unspecified",
  "required": "unspecified",
  "default_credentials": "unspecified"
}
```

## btc-policy, v1

Restated from its profile when the tenant supplies its drift checks and required software
(both "not yet stated"); until then the same template shape with those two fields
`"unspecified"`, one inbound listener on the vault protocol port from `peers`, one service
`running-at-delivery`, and `key_material.permitted` naming the member vault keys. TASKS T28.
