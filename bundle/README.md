# bundle/ — publisher-chosen inputs the build compiles in

Values the specification governs and the implementation repository compiles into the served
build at the pinned spec commit (ADR-0031). Nothing here is fetched at runtime (`SEC-7`,
`CNF-34`). Changing a value is a commit to this repository and a pin bump on the other side.

| File | Governs | Rule |
|---|---|---|
| `artifact-alpine.toml` | The Alpine bootstrap pin, repository branch and the accepted `apk` signing keys | `ARC-25`, `ARC-25a`, `CNF-66`, `CNF-67` |
| `inference.toml` | The procured aggregator, candidate entries `{ slug, maker, provider }`, allowlist entries `{ slug, provider }`, context floor, depth and retention tier | `ARC-31`, `ARC-31a`, `ARC-31b`, `TRU-A1a`, `CNF-71`, `CNF-78` |
| `timing.toml` | Every cadence and timeout the ceremony and the first-stage relay use, by name | `STG-20`, `CNF-80`, `CNF-87` |
| `cors-probe.sh` | The browser-route facts per origin, asserted on headers | `ARC-34`, `CNF-4` |

Tenant profiles stay in `docs/tenants/`, briefs in `docs/briefs/` and under each tenant; the
build compiles those in too.
