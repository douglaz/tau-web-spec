# bundle/ — publisher-chosen inputs the build compiles in

Values the specification governs and the implementation repository compiles into the served build
at the pinned spec commit (ADR-0031). Changing a compiled value is a commit to this repository
and a pin bump on the other side.

`SEC-7` says "Briefs and advisory feed lists MUST ship in the signed bundle and MUST NOT be fetched,
configured, or substituted at runtime." See also `CNF-34`. For publisher-default discovery and
the external-content boundary, see `CHN-19` and `SEC-8`.

| File | Governs | Rule |
|---|---|---|
| `artifact-alpine.toml` | The Alpine bootstrap pin, repository branch and the accepted `apk` signing keys | `ARC-25`, `ARC-25a`, `CNF-66`, `CNF-67` |
| `inference.toml` | The procured aggregator, candidate entries `{ slug, maker, provider }`, allowlist entries `{ slug, provider }`, context floor, depth and retention tier | `ARC-31`, `ARC-31a`, `ARC-31b`, `TRU-A1a`, `CNF-71`, `CNF-78` |
| `timing.toml` | Every cadence and timeout the ceremony uses, by name; the relay's moved to [paid-tcp-relay][relay-source] on 2026-09-24 | `STG-20`, `CNF-80` |
| `lockdown.toml` | The fixed lockdown checks, the delivery reads, the machine-class question and the declaration rendering | `ARC-17`, `ARC-36a`, `ARC-39`, `ARC-43`, `OPN-14`, `CNF-49`–`CNF-53`, `CNF-99`, `CNF-100`, `CNF-103` |
| `cors-probe.sh` | The browser-route facts per route, asserted on headers | `ARC-34`, `CNF-4` |

Tenant profiles stay in `docs/tenants/`, briefs in `docs/briefs/` and under each tenant; the
build compiles those in too.

`CHN-19` says "The build MUST compile the publisher discovery public key P and a nonempty public
Nostr discovery starting set B from `bundle/relay-discovery.toml` at its pinned specification
commit." The schema is documented in
[`docs/design/relay-discovery-inputs.md`](../docs/design/relay-discovery-inputs.md).
Deployment values have to be selected and validated before this file and its bundle-table row
are added together. The schema template is not a usable publisher key, endpoint or recovery
locator. For publisher-default admission, see `CHN-19`; for bring-your-own, see `CHN-11`.

[relay-source]: https://github.com/douglaz/paid-tcp-relay/tree/ba316fc4f734deb93d76561d8703551377987654

The CORS probe table includes LNVPS `/api/v1/vm` with requested POST and
`/api/v1/account` with requested PATCH, alongside the existing inference and Robot routes.
`probe HOST PATH EXPECT [REQUESTED_METHOD]` defaults the preflight method to POST. Only
unauthenticated OPTIONS and GET are sent; the requested mutation is never sent. OPTIONS
success, origin, method and header checks are independent of GET's origin-header check;
a readable GET authentication refusal can pass. This checks declared CORS shape, not
signed-mutation acceptance or end-to-end browser functionality (`CNF-4`, `CNF-32`).
