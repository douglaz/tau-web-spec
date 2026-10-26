# bundle/ — publisher-chosen inputs the build compiles in

Values the specification governs and the implementation repository compiles into the served build
at the pinned spec commit (ADR-0031). These compiled inputs are not substituted at runtime
(`SEC-7`, `CNF-34`). CHN-19 uses its compiled key and starting set to verify runtime relay
announcements; those events are external content under SEC-8, not replacements for bundle inputs.
Changing a compiled value is a commit to this repository and a pin bump on the other side.

| File | Governs | Rule |
|---|---|---|
| `artifact-alpine.toml` | The Alpine bootstrap pin, repository branch and the accepted `apk` signing keys | `ARC-25`, `ARC-25a`, `CNF-66`, `CNF-67` |
| `inference.toml` | The procured aggregator, candidate entries `{ slug, maker, provider }`, allowlist entries `{ slug, provider }`, context floor, depth and retention tier | `ARC-31`, `ARC-31a`, `ARC-31b`, `TRU-A1a`, `CNF-71`, `CNF-78` |
| `timing.toml` | Every cadence and timeout the ceremony uses, by name; the relay's moved to [paid-tcp-relay][relay-source] on 2026-09-24 | `STG-20`, `CNF-80` |
| `lockdown.toml` | The fixed lockdown checks, the delivery reads, the machine-class question and the declaration rendering | `ARC-17`, `ARC-36a`, `ARC-39`, `ARC-43`, `OPN-14`, `CNF-49`–`CNF-53`, `CNF-99`, `CNF-100`, `CNF-103` |
| `cors-probe.sh` | The browser-route facts per origin, asserted on headers | `ARC-34`, `CNF-4` |

Tenant profiles stay in `docs/tenants/`, briefs in `docs/briefs/` and under each tenant; the
build compiles those in too.

CHN-19 also requires a publisher key and public discovery starting set from
`relay-discovery.toml`. The schema is documented in
[`docs/design/relay-discovery-inputs.md`](../docs/design/relay-discovery-inputs.md).
Deployment values have to be selected and validated before this file and its bundle-table row
are added together. The schema template is not a usable publisher key, endpoint or recovery
locator; a build without valid discovery inputs cannot enable the publisher default. Explicit
bring-your-own remains independent.

[relay-source]: https://github.com/douglaz/paid-tcp-relay/tree/ba316fc4f734deb93d76561d8703551377987654
