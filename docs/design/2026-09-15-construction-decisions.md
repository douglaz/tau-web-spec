# September 15 construction decisions

A build-readiness review of the corpus at `054baf3` by two independent readers returned
BUILD-WITH-DECISIONS: nothing stopped construction, but eleven interfaces were undefined and
an implementer would have guessed. Eleven decisions were drafted, reviewed by three
independent readers (18, 5 and 19 findings), amended where they converged, and adopted on
2026-09-15 with one further decision the review surfaced. This record is history; the
operative text is in the rules each row names.

| # | Decision | Where it lives | What review changed |
|---|---|---|---|
| D1 | The publisher builds the first-stage relay on a three-message protocol | `docs/design/relay-protocol-v1.md`, `CHN-15`, `CNF-87`, T27 | Destination checked against the recorded set, one destination grammar, no dial before OK, ordering asserted |
| D2 | Every model-issued exec is one stateless job; brief blocks are self-contained examples | `ARC-7`, brief 1, `OPN-10` | Reframed as an authoring rule (`ARC-9`); each value's source named; machine-derived values recomputed |
| D3 | The harness reads the artifact hash and host keys from jobs it composes; the model requests them | `ARC-43`, `STG-4`, `STG-6`, `CNF-22`, `CNF-24`, brief 1 | Two requestable harness jobs with a trigger each; `ready_to_reset` reads keys before unmounting. Edit review: the jobs are box-plane work, requested by a fourth tool, never approved on facts |
| D4 | Inference is the adapter's own call, recorded as intent then metadata | `ARC-31a`, `SEC-12`, `CNF-28` | Not an untyped scope; no `TRU-E6` entry; pre-send intent with a local id |
| D5 | One bundle entry names the inference target | `bundle/inference.toml`, `ARC-31`, `TRU-A1`, ADR-0028, `STG-17` | "In the briefs" corrected corpus-wide; ladder rung two absent at one slug |
| D6 | The harness defines the declaration schema before re-asking lnrent | `docs/design/delivery-declaration-v1.md`, `ARC-39`, `OPN-14`, T28 | Explicit presence: value, `[]`, or `unspecified`; absent is an error |
| D7 | Robot mutations reconcile by observable state, clock-free | `STG-4`, `STA-5`, `CNF-38` | Reset confirmed by a changed host-key set, activation by the echoed key, no `boot_time` ordering |
| D8 | The accepted Alpine keys are declared and build-verified against the pinned minirootfs | `bundle/artifact-alpine.toml`, `ARC-25a`, `CNF-67` | Declared list plus build diff, so the check is not a tautology |
| D9 | "Signed bundle" means compiled into the served build until `OPN-15` closes | glossary, `SEC-7`, `ARC-40`, `CNF-44` | One definition, inherited everywhere, rather than eight edits |
| D10 | Cadences and limits are named values; readiness probes are pinned SSH attempts | `bundle/timing.toml`, `STG-20`, `CNF-80`, `CNF-87` | Bare port probes dropped: they trip OpenSSH's penalty (`ARC-41`) |
| D11 | The CORS probe lives here and asserts on headers | `bundle/cors-probe.sh`, `CNF-4` | Unauthenticated, header assertions, build gate in the implementation repository |
| D12 | Spec and implementation are separate repositories, pinned by commit; inputs live here | ADR-0031, `bundle/`, T29 | Raised by the review of D11; two follow-on questions settled the pin and the inputs' home |

Held against reviewer pressure: `CNF-65`'s flat-out rate test stays with the paid relay
(`CNF-87` already tests that configured limits apply); D9 stays one definition rather than a
per-file rewrite.
