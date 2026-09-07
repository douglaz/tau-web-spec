# 08 — Open questions

This is the only list. Anything else that reads like an open question elsewhere in this
repository is history.

Each entry says **what would close it**, because a question without a closure criterion is a
worry rather than a work item, and because the gating set otherwise mixes a twenty-minute
probe with a multi-week spike as though they were the same size.

## Gating

Five, and every one is empirical or currently unanswerable. Nothing here waits on a
decision.

**OPN-1 — The SSH client.** An SSH implementation compiled to `wasm32-unknown-unknown` with
its transport swapped for a WebSocket. It gates, because nothing works without one.

*Recalibrated twice, and the second time changed the answer.* This was called the item most
likely to sink the plan. It is not, and two earlier characterisations of it were wrong:

- **"The architecture is unproven" — false.** Browser-resident SSH over a WebSocket-to-TCP
  bridge ships in production in several independent implementations.
- **"Every implementation is Go, so Rust means pioneering" — also false.**
  [`Ar4l/sshmux`](https://github.com/Ar4l/sshmux) is a Rust one, on `wasm32-unknown-unknown`,
  with Leptos CSR and a Trunk build and no npm — the stack the archived specification
  recommends, arrived at independently. **An existence proof, not a production deployment**:
  one author, no stars, July 2026. It settles reachability, not maturity.
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

**OPN-3 — The recovery machinery is designed and unproven.** The design is recorded across
`03-state-and-recovery.md` and `CHN-R5`. What stays open is empirical: the attest hook has to
fire reliably on a real first boot and reach the relay set; the rescue ceremony has to be
rehearsed once end to end; and the sheet needs a format an operator can actually re-import.
Until those run, the channel's loss story is a design, not a property.

*Narrowed 2026-09-06.* The attest pipeline itself has now run — gift-wrap from a no-TTY script,
publish to three public relays, unwrap on the other side — so what is unproven is no longer the
mechanism but its behaviour **on a real first boot**: cloud-init timing, the static binary on
Alpine, and the browser's window against a measured slowest boot (`CHN-6`). The seed also adds
one item: the derivation must be shown deterministic across a reinstall of the app, or
"re-derive from twelve words" is a claim rather than a property.

*Closes when:* `CNF-18`, `CNF-19`, `CNF-20` and `CNF-72` pass on real hardware.

**OPN-4 — Weights-level diversity may not be enforceable.** The runtime signal named the
*inference provider*, not the weights behind it — and the provider is a layer nobody
configures, so there was nothing there to enforce either. The honest position is the one
`ARC-14` records: report what was observed, promise nothing forward. `SEC-CLAIM` stays
conditional on weights-level distinctness.

*The signal situation changed, and not only for the worse.* On the chosen aggregator there is
no provider signal at all (`OPN-23`), so the sentence above describes a signal that is gone. But
the **weights are configured, not observed**: the harness picks the model per member, and the
catalogue names which vendor made it, so distinctness across members is enforceable **by
construction** rather than by inspection. What remains unverifiable is whether the proxy served
the model it was asked for — which is a smaller and better-shaped gap than "no signal reaches
the weights", and it is the same gap `TRU-E2` already names when it says the proxy can alter
everything it carries.

*Closes when:* the claim is restated around what is configured rather than what is observed, or
a signal confirming the served model appears. The second has no current candidate.

**OPN-5 — The cloud-account floor.** Cloud vendors want an account, a card, and a recurring
relationship, several times over, and invoice relay cannot fix it. This is what makes lnrent
structural rather than a second tenant, and what makes `OVR-5` hard.

*Closes when:* an operator can obtain machines at two distinct vendors without opening two
billing relationships.

**OPN-6 — What Robot's rescue `host_key` field actually returns.** *Partly answered
2026-08-31, read-only, against a real account.* The field **exists and is an array**, empty
while rescue is inactive. What it holds once rescue is activated — full public keys,
fingerprints, which algorithms — still needs one `POST`, which reboots the machine, so it was
not run.

The same session settled two other things. **Robot is not browser-reachable** (`CHN-R1`): a
previously recorded probe said otherwise and was wrong. And the installer catalogue was read
directly — AlmaLinux, Arch, CentOS Stream, Debian, openSUSE, Rocky, Ubuntu, with **no Alpine and
no NixOS** — so `ARC-24` and `STG-3`'s claim that custom installation is mandatory is verified
rather than inferred.

*Closes when:* `CNF-48` is recorded. This is the cheapest item on the list and the one the most
rests on, which is why `STG-2` gates construction on it.

**OPN-21 — A pinned TLS client inside WebAssembly.** The first stage cannot reach its vendor
API without one (`CHN-R1`, `CHN-12a`, `STG-3a`), so this gates alongside the SSH client.

*Believed cheap, and unverified.* `rustls` is pure Rust and exposes certificate verification as
a replaceable interface, so pinning is a supported use rather than a hack; and it needs a crypto
provider, where `ring` with `wasm32_unknown_unknown_js` is **already required by the SSH client**
(`ADR-0024`). If that holds, this is a pinned verifier over a stack already being built rather
than new cryptography.

**None of that has been checked at source**, and it is the same shape of claim as "Robot CORS:
tested, non-issue" — plausible, load-bearing, and believed for a year without a probe. It should
get the treatment `ADR-0024`'s configuration got before anything is built on it.

*Closes when:* a pinned TLS session from a mobile browser, through the relay, reads a real
response from the vendor API — **and refuses a certificate that does not match the pin.**

**OPN-22 — What "still alive" means in `STA-20`, and whether POSIX can deliver it.** The
requirement says the record holds *"enough to tell whether it is still alive"* and never says
whether *it* is the command or everything the command left running. The two readings need
different mechanisms and only one of them is reachable.

*The narrow reading is satisfiable and the wide one is not, under POSIX.* A process that
daemonises calls `setsid()`, which by POSIX creates a new session **and** a new process group —
so it leaves both of the only groupings POSIX can enumerate. Verified on both declared
distributions: a plain background child stays in the wrapper's process group and is observable;
a detached one is in neither its session nor its group. `wait()` cannot see it either, by
definition, because daemonising orphans it deliberately. **POSIX has no descendant-tracking
primitive at all**, so this is a property of the standard rather than a gap in the search.

*One mechanism does work, at a stated price.* cgroup v2 membership is inherited across `fork()`
and unaffected by `setsid()`; a detached child was verified still listed in `cgroup.procs` after
its wrapper exited. It is a kernel interface rather than a POSIX one, but it holds **no
init-system opinion**, which is the constraint `STA-20` actually cares about. Its cost is an
unverified prerequisite: whether cgroup2 is mounted at boot on a real Alpine install, which the
distribution's own documentation says must be enabled explicitly.

*Also checked and rejected:* an `flock` on an inherited descriptor survives both the wrapper's
exit and `setsid()`, and correctly reports a detached child alive — but the canonical
daemonising recipe closes inherited descriptors, so it reports **dead while the process runs**.
It catches the sloppy daemon and misses the well-behaved one. Advisory at best, and `STA-21`
already spends the corpus's tolerance for advisory.

*Closes when:* `STA-20` says which reading binds. Under the narrow one it closes immediately and
daemon health belongs to `ARC-39`'s delivery declaration, which already covers service
lifecycle. Under the wide one it additionally needs cgroup2-at-boot confirmed on a real Alpine
install, and `STA-20`'s "POSIX" must become "Linux, init-agnostic".

**OPN-23 — The observed provider layer has no source, and the header it was specified around
belonged to a different aggregator.** `ARC-14` counts the inference provider as a third,
*observed* layer, built from `X-Provider-Name`. That is **OpenRouter's** header, written down
while OpenRouter was the live candidate. The aggregator actually chosen exposes no equivalent —
verified 2026-09-05 against its docs and its live API — and page script could not read one if it
did, because the completions endpoint exposes only a request id to a cross-origin caller.

*The reasoning for the layer survives; only the evidence is gone.* The provider is still a party
neither configured layer covers, still picked per request, still able to rewrite everything it
carries. What cannot be done is count it. Deriving the number from the requested model name would
report whoever **made** the weights under a label reading *observed*, which is the overstatement
`SEC-2` forbids everywhere else, so `SEC-9` now requires the count to be **absent** rather than
approximated.

*Three ways out, none free.* Ask the aggregator to return the provider and add it to its
exposed-headers list — cheap if the circumstantial evidence that it resells another aggregator
and strips the field holds, and that is **inference, not verification**. Weigh an aggregator that
already reports it, against the accountless Lightning funding and open CORS that made this one
the choice. Or retire the layer and state that the provider is trusted and uncounted, which is
honest and loses the one thing `TRU-E3` exists to make visible.

*Closes when:* a source exists, or `ARC-14` drops to two layers in writing. Until then nothing
displays a provider count.

## One probe or one boot from closing

Each is an afternoon of work that nobody has spent.

**OPN-7 — Whether the second inference proxy is reachable from a browser at all.** An
OpenAI-compatible API does not imply an origin may call it. **The first proxy is now probed and
passes** (2026-09-05, recorded in ADR-0007), so this is exactly what remains: the *second* one,
which `ARC-14`'s proxy layer needs before it can move off one. *Closes when:* the same probe the
first proxy got is run against it.

**OPN-8 — Whether a second cloud vendor's API permits a browser origin.** Roughly eighty lines
of curl; the existing probe is a template, not a drop-in, since it hardcodes the first vendor's
base URLs, paths and assertions. `OVR-5` depends on the answer. *Closes when:* the forked probe
passes or fails against a named second vendor.

**OPN-9 — Whether the proof of concept's cloud-init boots an unreachable machine.** A code-read
finding, not an observed failure: its user list has no default entry and sets an empty
authorized-keys list, so the vendor's injected keys reach no account. The fix is one line and
nobody has booted the file. *Closes when:* the file is booted once.

## Design-level, still open

Genuinely undecided, and not blocking the first stage.

**OPN-10 — The brief format schema.** Frontmatter fields, the local/remote block marker, how a
block returns structured data to the next one, versioning, signing. Designing a second consumer
for an undefined format is premature until this exists. *Closes when:* the three briefs written
during `STG-2` are generalized into a schema.

**OPN-11 — What executes brief commands locally in the browser.** Either a WASI host with
uutils guests, as the archived specification assumes, or a small set of purpose-built commands.
Deliberately not decided in advance: the scope is to be derived from real briefs rather than
guessed. *Closes when:* `STG-2`'s briefs show which commands genuinely need the browser rather
than the machine.

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

**OPN-17 — Where a wallet could live, if it is ever built.** Paying for machines and services
from inside the harness is an intended capability, and `SEC-13` collides with it. The three live
options are a separate origin — which `ARC-32` rejected for user safety, an objection that would
have to be answered rather than ignored — the same bundle, with `SEC-13` rewritten and the
undefended-bundle risk repriced from misconfiguring machines to spending funds, or a tenant of
its own. None is chosen. Whoever builds it settles this first.

**OPN-19 — Transcript retention.** A maintained machine accumulates command records for its
whole life in an encrypted store on a phone, and nothing states when they compact or expire.
*Closes when:* a retention and compaction policy exists in `03-state-and-recovery.md`.

**OPN-20 — The cost of a WebAssembly TLS client's trust store.** *Narrowed: this is now only
about arbitrary destinations.*

`CHN-12a` settled the known-destination case — a vendor API is pinned to its issuing authority,
shipped in the bundle, adding no trusted party. What remains is `CHN-12b`: reaching a service
that refuses browser CORS and cannot be named in advance, which needs a general
certificate-authority set, currency as authorities are distrusted, and a revocation story. That
is the growth `SEC-10` guards.

*Closes when:* someone states what the set would contain, how it is updated, and what
revocation story it has — or the capability is abandoned and untyped calls to CORS-refusing
services are declared out of reach.

*Separately, and smaller:* `CHN-12a`'s pinning needs a stated rotation procedure, since a vendor
changing issuing authority makes its API unreachable until a release ships.

## Closed

Kept rather than deleted, because a reader who remembers one of these open needs to
know it was closed deliberately, and because the reasoning is worth more than the question was.

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

**OPN-12 — Convergence in practice.** *Substantially closed.* The design is `ARC-10`
(re-running a brief from the top is safe; the AI reads machine state before acting) and
`STA-6` (box-plane work never retries automatically). A declarative distribution (`ARC-24`)
makes it close to free. What remains is empirical and is tested rather than reasoned:
`CNF-37`.

**OPN-13 — Whether injecting the SSH host key is permitted.** **Closed: the route is
abandoned.** No credential-inventory exception is needed, because there is nothing left to
except.

It was blocked on the objection that a private host key rides in user-data, which the vendor
stores. It is abandoned on a stronger one: **user-data is served back to the machine by the
vendor's metadata endpoint for the life of the instance**, so anything running there can
re-fetch the host private key and impersonate the machine, passing the fingerprint check
because it is genuinely the pinned key. Scrubbing deletes cloud-init's disk cache and the
endpoint keeps serving the original, so the proposed mitigation cannot reach it. `ARC-36`
sharpens it further: a guest on a machine renting slices can query that endpoint.

`CHN-R5` covers the same vendors, so nothing is lost. The distinction worth carrying forward:
**a short-lived credential in a permanently-readable place is bounded by its expiry; a permanent
one is not bounded at all.**

**OPN-16 — Content-Security-Policy admission.** *Substantially closed.* The posture is
`ARC-33`: `connect-src` permissive, `script-src`/`object-src`/`base-uri` strict. What stays open
is empirical — runtime admission of the policy is unverified.

**OPN-18 — A durable remote job record.** *Closed by design; open only as implementation.*
`STA-20` makes every box-plane command a job whose record holds the command as received, its
output, its exit code and its liveness, on persistent disk. `STA-21` states the limit: the record
is machine-reported and advisory, and comparing it against the browser journal catches honest
mistakes rather than a hostile machine.
[ADR-0022](./docs/adr/0022-durable-state-is-an-append-only-journal.md)'s amendment carries the
reasoning and the three rejected alternatives. *Closes when:* `CNF-40` passes.
## Status and the next move

Nothing here has touched a real server. The proof of concept can call a cloud vendor's API
directly from a browser and has established there is no CORS obstacle — the one external fact
everything depends on. It cannot yet create a machine, and the provisioning state machine is
unbuilt.

The cheapest way to find out which of these decisions is wrong is still not to write code. It
is to **run the first stage by hand once**, which `STG-2` now requires rather than recommends.
