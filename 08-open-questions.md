# 08 — Open questions

This is the only list. Anything else that reads like an open question elsewhere in this
repository is history.

Each entry says **what would close it**, because a question without a closure criterion is a
worry rather than a work item, and because the gating set otherwise mixes a twenty-minute
probe with a multi-week spike as though they were the same size.

## Gating

**OPN-1 — The SSH client.** An SSH implementation compiled to `wasm32-unknown-unknown` with
its transport swapped for a WebSocket. It gates, because nothing works without one.

*Recalibrated twice, and the second time changed the answer.* This was called the item most
likely to sink the plan. It is not, and two earlier characterisations of it were wrong:

- **"The architecture is unproven" — false.** Browser-resident SSH over a WebSocket-to-TCP
  bridge ships in production in several independent implementations.
- **"Every implementation is Go, so Rust means pioneering" — also false.**
  [`Ar4l/sshmux`](https://github.com/Ar4l/sshmux) is a deployed Rust one, on
  `wasm32-unknown-unknown`, with Leptos CSR and a Trunk build and no npm — the stack the
  archived specification recommends, arrived at independently.
- **The blocker cited was the wrong blocker.** russh issue #224 concerns WASI under
  wasmtime/wasmer, a different target with different problems, and it was never about the
  browser.

The known-good configuration is published: `russh` with `default-features = false` and the
`ring` backend, `ring` with `wasm32_unknown_unknown_js`, `ws_stream_wasm` for the socket, and
`getrandom_backend="wasm_js"` in rustflags. The one genuine blocker is that russh's current
default crypto backend does not support this target, which a feature flag settles
([ADR-0024](./docs/adr/0024-the-ssh-client-is-rust-following-a-known-good-configuration.md)).

**Size is settled too, and it favours Rust.** The reference deployment is ~1.5 MB raw and
**~574 KB gzipped for the whole application** — terminal and UI included — against ~4.94 MB for
the Go equivalent.

*What actually remains:* carrying the configuration to russh's current release, and proving
**host-key pinning**, which is the one thing the references skip — most accept any key, and the
best of them offers a `Changed{old, new}` status that `SEC-11` and `CHN-R4` want. Estimated at
one to three engineer-weeks to an authenticated interactive shell.

*Closes when:* an SSH session reaches a real machine from a mobile browser through a relay,
**and refuses a mismatched host key** (`CNF-21`).

**OPN-2 — The relay's access system.** *Closed by design; open only as implementation.* There is
no identity model, because there is no identity: access is **bought** (`CHN-15`,
[ADR-0025](./docs/adr/0025-relay-access-is-bought-not-granted.md)). Issuance is a payment,
scoping and lifetime are the destination record `CHN-16` describes, and reacquisition is another
purchase rather than a recovery flow.

That satisfies the closure criterion this question was written with: a new operator obtains
access without the publisher hand-issuing anything, and the trusted-party list is unchanged,
since the publisher was already there as the relay's operator (`TRU-A2`) and being paid adds
nobody.

*Closes when:* an operator who has never contacted the publisher buys a pass and reaches a
machine with it.

**OPN-3 — The recovery machinery is designed and unproven.** The design is recorded across
`03-state-and-recovery.md` and `CHN-R5`. What stays open is empirical: the attest hook has to
fire reliably on a real first boot and post through the relay; the rescue ceremony has to be
rehearsed once end to end; and the sheet needs a format an operator can actually re-import.
Until those run, the channel's loss story is a design, not a property.

*Closes when:* `CNF-18`, `CNF-19` and `CNF-20` pass on real hardware.

**OPN-4 — Weights-level diversity may not be enforceable.** The available runtime signal names
the *inference provider*, not the weights behind it — and the provider is a layer nobody
configures, so there is nothing there to enforce either. The honest position is the one
`ARC-14` records: report what was observed, promise nothing forward. `SEC-CLAIM` stays
conditional on weights-level distinctness.

*Closes when:* a signal reaching the weights themselves exists, or the claim is permanently
restated as conditional. There is no current candidate for the former.

**OPN-5 — The cloud-account floor.** Cloud vendors want an account, a card, and a recurring
relationship, several times over, and invoice relay cannot fix it. This is what makes lnrent
structural rather than a second tenant, and what makes `OVR-5` hard.

*Closes when:* an operator can obtain machines at two distinct vendors without opening two
billing relationships.

**OPN-6 — What Robot's rescue `host_key` field actually returns** — full public keys,
fingerprints, which algorithms. Undocumented, and **first-stage-blocking**: `CHN-R1` is the
first stage's identity chain, which is why this sits among the gates despite being one
authenticated call from closing. The same call should re-check that Robot is still reachable
from a browser at all, since that result rests on a single recorded probe, and should read what
the automatic Linux install operation returns while it is there (`STG-3`).

*Closes when:* `CNF-48` is recorded. This is the cheapest item on the list and the one the most
rests on, which is why `STG-2` gates construction on it.

## One probe or one boot from closing

**OPN-7 — Whether the second inference proxy is reachable from a browser at all.** An
OpenAI-compatible API does not imply an origin may call it. *Closes when:* the same probe the
first proxy got is run against it.

**OPN-8 — Whether a second cloud vendor's API permits a browser origin.** Roughly eighty lines
of curl; the existing probe is a template, not a drop-in, since it hardcodes the first vendor's
base URLs, paths and assertions. `OVR-5` depends on the answer. *Closes when:* the forked probe
passes or fails against a named second vendor.

**OPN-9 — Whether the proof of concept's cloud-init boots an unreachable machine.** A code-read
finding, not an observed failure: its user list has no default entry and sets an empty
authorized-keys list, so the vendor's injected keys reach no account. The fix is one line and
nobody has booted the file. *Closes when:* the file is booted once.

## Design-level, still unanswered

**OPN-10 — The brief format schema.** Frontmatter fields, the local/remote block marker, how a
block returns structured data to the next one, versioning, signing. Designing a second consumer
for an undefined format is premature until this exists. *Closes when:* the three briefs written
during `STG-2` are generalized into a schema.

**OPN-11 — What executes brief commands locally in the browser.** Either a WASI host with
uutils guests, as the archived specification assumes, or a small set of purpose-built commands.
Deliberately not decided in advance: the scope is to be derived from real briefs rather than
guessed. *Closes when:* `STG-2`'s briefs show which commands genuinely need the browser rather
than the machine.

**OPN-12 — Convergence in practice.** *Substantially closed.* The design is `ARC-10`
(re-running a brief from the top is safe; the AI reads machine state before acting) and
`STA-6` (box-plane work never retries automatically). A declarative distribution (`ARC-24`)
makes it close to free. What remains is empirical and is tested rather than reasoned:
`CNF-37`.

**OPN-13 — Whether injecting the SSH host key is permitted, and on what terms.** `CHN-R3`
writes a *private* host key into boot-time user-data, which the vendor stores. There is one way
out: a **narrow exception naming that key and no other** in `SEC-5`, decided before the route is
used. Not a widening to "vendor and inference credentials" — that phrasing would quietly strip
the SSH *client* keys and the relay token of the same protection, a larger hole than the one
being patched. Scrubbing and rotating after first boot limits exposure but resolves nothing.

*The pressure has dropped:* attest (`CHN-R5`) now covers the cloud introduction this route was
the only hope for, so injection stays blocked without blocking anything else. *Closes when:* the
exception is decided, or the route is abandoned.

**OPN-14 — What "locked down" means, per vendor.** A pentest can only assert what it checks, so
the checklist is part of the signed brief set — and it does not exist yet for any vendor. Until
it does, `ARC-17`'s deliverable has no definition to be measured against.

Two parts are no longer open. Who may run which check was settled by `ARC-26`. And the *shape* is
settled by `ARC-39`: the tenant supplies a delivery declaration and the check measures against it,
so what is actually missing is the **declaration format** plus the items no declaration covers —
default credentials, sshd posture, and whatever a given vendor makes possible.

That also makes the question per-**tenant** as much as per-vendor, which the title understates.
*Closes when:* a declaration format exists and a checklist exists for the first stage's vendor.

**OPN-15 — Reproducible builds and the watchdogs that would make them mean something.** Neither
exists. Until they do, the bundle's integrity rests on trusting the host outright, and `TRU-A1`
is unmitigated. *Closes when:* builds are reproducible **and** at least one independent party
is checking.

**OPN-16 — Content-Security-Policy admission.** *Substantially closed.* The posture is
`ARC-33`: `connect-src` permissive, `script-src`/`object-src`/`base-uri` strict. What stays open
is empirical — runtime admission of the policy is unverified.

**OPN-17 — Where a wallet could live, if it is ever built.** Paying for machines and services
from inside the harness is an intended capability, and `SEC-13` collides with it. The three live
options are a separate origin — which `ARC-32` rejected for user safety, an objection that would
have to be answered rather than ignored — the same bundle, with `SEC-13` rewritten and the
undefended-bundle risk repriced from misconfiguring machines to spending funds, or a tenant of
its own. None is chosen. Whoever builds it settles this first.

**OPN-18 — A durable remote job record.** *Closed by design; open only as implementation.*
`STA-20` makes every box-plane command a job whose record holds the command as received, its
output, its exit code and its liveness, on persistent disk. `STA-21` states the limit: the record
is machine-reported and advisory, and comparing it against the browser journal catches honest
mistakes rather than a hostile machine.
[ADR-0022](./docs/adr/0022-durable-state-is-an-append-only-journal.md)'s amendment carries the
reasoning and the three rejected alternatives. *Closes when:* `CNF-40` passes.

**OPN-19 — Transcript retention.** A maintained machine accumulates command records for its
whole life in an encrypted store on a phone, and nothing states when they compact or expire.
*Closes when:* a retention and compaction policy exists in `03-state-and-recovery.md`.

**OPN-20 — The cost of a WebAssembly TLS client's trust store.** `CHN-12`'s tunneled fallback
needs a TLS client inside WebAssembly, which browsers do not supply and which must therefore
bundle its own certificate-authority set and own the revocation problem. That is a
trusted-party growth `SEC-10` guards, sitting in a credential path. Until it is priced, a
service refusing browser CORS is out of reach for untyped calls. *Closes when:* someone states
what the bundle would contain, how it is updated, and what revocation story it has — or the
capability is abandoned.

## Status and the next move

Nothing here has touched a real server. The proof of concept can call a cloud vendor's API
directly from a browser and has established there is no CORS obstacle — the one external fact
everything depends on. It cannot yet create a machine, and the provisioning state machine is
unbuilt.

The cheapest way to find out which of these decisions is wrong is still not to write code. It
is to **run the first stage by hand once**, which `STG-2` now requires rather than recommends.
