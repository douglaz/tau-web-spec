# tau-web

Design work for a client-side AI harness that lets someone with only a phone provision
and operate real infrastructure, without trusting any party that could act on their
behalf.

No code yet. This repository holds the domain language, the decisions taken so far, and
the reasoning that produced them.

`tau-web` is a working name.

## Why it is client-side

The gap this addresses is that agentic AI is effectively desktop-gated. Technical users
run real harnesses against the best models and get an AI that acts; everyone else gets a
chat box, because installing and configuring a harness needs technical knowledge and
usually a desktop.

The obvious fix — a hosted agent platform — is unavailable for an entire class of tasks:
anything whose value depends on *not* trusting a host. Self custody, key management,
sovereign infrastructure. For those, the gap can only be closed client-side.

First two intended tenants:

- [btc-policy](https://github.com/douglaz/btc-policy) — self-hosted Bitcoin custody.
  Standing up a federation of policy co-signers means provisioning and hardening several
  machines at several vendors, which a non-technical operator can neither do nor
  delegate, because a single party that provisions every member has defeated the
  federation.
- [lnrent](https://github.com/douglaz/lnrent) — server rental over Bitcoin. An operator
  who cannot stand up the daemon cannot participate, and the project keeps AI out of its
  serving path by design, so any AI help has to live on the user's side.

## Contents

| Path | What it is |
|---|---|
| [`executive-summary.md`](./executive-summary.md) | The whole design in one read: the problem, who it is for, how it works, the security claim stated exactly, what must still be trusted, and what is unresolved. Start here. |
| [`CONTEXT.md`](./CONTEXT.md) | Domain glossary. The canonical term for each concept, aliases to avoid, and flagged ambiguities. |
| [`docs/adr/`](./docs/adr/) | Architecture decision records. What was decided, why, and which alternatives were rejected and on what grounds. |
| [`docs/design/`](./docs/design/) | The design session the ADRs came out of: problem framing, the three approaches weighed, open questions with the evidence behind each, and what three rounds of adversarial review found. Partly superseded by the ADRs, and the only record of why this approach was chosen over the others. |
| [`docs/archive/`](./docs/archive/) | Superseded documents, kept because later work cites them. Currently the original Rust/WASM PWA specification. |

## The decisions, in the order they forced each other

Each one is a consequence of the one above it.

| ADR | Decision |
|---|---|
| [0001](./docs/adr/0001-recipes-are-instructions-not-scripts.md) | Recipes are instructions the AI reads, not scripts it executes |
| [0002](./docs/adr/0002-cloud-plane-and-box-plane.md) | Cloud-plane actions are typed operations; box-plane actions are free shell |
| [0003](./docs/adr/0003-the-ai-runs-only-in-the-browser.md) | The AI runs only in the browser; a machine is a target, never an actor |
| [0004](./docs/adr/0004-one-model-one-machine.md) | One model, one machine, and an honest-majority assumption |
| [0005](./docs/adr/0005-recipes-ship-in-the-signed-bundle.md) | Recipes ship in the signed app bundle |
| [0006](./docs/adr/0006-single-origin-with-reproducible-builds.md) | One origin, with reproducible builds |
| [0007](./docs/adr/0007-trust-is-counted-in-two-layers-and-shown.md) | Trust is counted in two layers, and shown rather than scored |
| [0008](./docs/adr/0008-three-of-five-default-and-its-economic-floor.md) | 3-of-5 by default, and the economic floor it implies |
| [0009](./docs/adr/0009-one-device-concurrent-sessions-batched-approval.md) | One device, concurrent sessions, approvals batched up front |
| [0010](./docs/adr/0010-members-reach-each-other-on-one-authenticated-port.md) | Members reach each other on one authenticated port, everything else denied |
| [0011](./docs/adr/0011-the-ai-delivers-a-locked-down-machine.md) | The AI delivers a locked-down machine and demonstrates it, per vendor |
| [0012](./docs/adr/0012-a-federation-is-created-only-when-every-member-works.md) | A federation is created only when every member works |
| [0013](./docs/adr/0013-ongoing-operation-periodic-pentest-and-advisory-watch.md) | Ongoing operation: periodic pentest and advisory watch |
| [0014](./docs/adr/0014-the-app-relays-invoices-and-never-holds-funds.md) | The app relays invoices and never holds funds |

## What is deliberately not claimed

There is no verification layer, and nothing here may imply one. Any scheme where one
model inspects another's machine hands that model a second foothold, which weakens the
threshold that is doing the real work (0004). A deterministic verifier reads whatever the
machine chooses to tell it and cannot beat a hostile AI.

The security claim is one sentence: **no single model provisioned enough members to
reach the threshold.** "Verified" and "no anomalies found" are both claims this design
cannot make.

The app bundle remains the one common-mode component and the largest concentrated risk
(0006).

## Open

- Contents of Hetzner Robot's rescue `host_key` field — one authenticated call answers it
- PayPerQ browser reachability — a CORS probe
- A second cloud vendor's CORS behaviour — the same probe Hetzner got, ~80 lines of curl
- An SSH client compiled to `wasm32-unknown-unknown` over a WebSocket — the one real spike
- When to prompt an operator to resume or abandon a stalled setup, since machines bill while it waits

Nothing here has touched a real server. The cheapest way to find out which of these
decisions is wrong is to write three recipes by hand and run them against a disposable
project.
