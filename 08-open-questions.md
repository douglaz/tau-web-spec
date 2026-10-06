# 08 — Open questions

This owns open decisions and empirical gaps. `TASKS.md` links execution work back here;
`07-conformance.md` owns the acceptance evidence and stage applicability.

Each entry says **what would close it**, because a question without a closure criterion is a
worry rather than a work item, and because the gating set otherwise mixes a twenty-minute
probe with a multi-week spike as though they were the same size.

## Gates by milestone

Construction admission (`STG-2`) closed with the September 8 installation rehearsal, on the
dedicated path that is now the construction test bed. The stages were re-drawn on 2026-10-05
(`06-first-stage.md`). **Stage 0** is the probes, run now and in parallel with construction:
`OPN-24`, `OPN-25`, and attest on a real first boot under `OPN-3`. **Completing stage 1** gates
on those three, on the generic lockdown checklist of `OPN-14`, on integrated resume
(`OPN-18`), on integrated placed-secret scanning (`OPN-28`, closed by design), and on the
stage-1 acceptance rows in `07-conformance.md`, including local unlock, derivation and
maintained-cloud recovery. `OPN-3`'s evidence is split by milestone below. `OPN-5`
gates stage 2. `OPN-26` gates no route of stage 2 — the jump-host route runs on a separately
supplied credential (`SEC-5` row 21) — and what waits on it there is the untyped vendor scope's
best practice, a vendor identity derived per set, which is shown as missing until it closes.
`OPN-27` gates stage 3. `OPN-4` closed by restating `SEC-CLAIM`
around configured weights; the vault claim stays conditional on `TRU-E2`.

**OPN-3 — The recovery machinery is designed and unproven.** The design is recorded across
`03-state-and-recovery.md` and `CHN-R5`. What stays open is empirical: the attest hook has to
fire reliably on a real first boot and reach the relay set; the rescue ceremony has to be
rehearsed once end to end; and the sheet format needs a demonstrated import on the target device.
Until those run, the channel's loss story is a design, not a property.

*Narrowed 2026-09-06.* The attest pipeline itself has now run — gift-wrap from a no-TTY script,
publish to three public relays, unwrap on the other side — so what is unproven is no longer the
mechanism but its behaviour **on a real first boot**: cloud-init timing, the static binary on
Alpine, and the browser's window against a measured slowest boot (`CHN-6`). The seed also adds
one item: the derivation must be shown deterministic across a reinstall of the app, or
"re-derive from twelve words" is a claim rather than a property.

*Narrowed again 2026-09-08.* The **rescue ceremony has now been rehearsed end to end** on the
dedicated path — register the client key, activate rescue, pin from the API, install, re-read
the installed host keys, reconnect — so that item leaves this entry. What remains is the cloud
route's attest on a real first boot, and the sheet's re-import.

*Format fixed 2026-09-09:* `STA-22a`/`STA-22b` define derivation and recoverable allocation
metadata; the credential-format companion specifies the encrypted sheet. Missing/stale metadata
is handled explicitly, including restored seeds being unavailable for new allocations.

*Moved to the front 2026-10-05.* Attest is stage 1's first contact, so a real first boot is
stage-0 work and no longer second-stage work. The remedy for a post that never arrives
narrowed with it: `CHN-R5` says "If the introduction never arrives, the machine is recreated,
and nothing weaker is entered", so a window measured too short now costs a machine rather than
a displayed leap.

*Closure evidence by milestone (amended 2026-10-06):*

- Stage 0 supplies real-first-boot attest evidence (`CNF-18`), then stage 1 integrates it.
- Stage 1 supplies the recovery row of `07-conformance.md`, including `CNF-10`'s export
  case, and local allocation/derivation evidence (`CNF-72`, `CNF-83`). Its relay replacement
  is the manual route in `STA-17`.
- The dedicated path supplies `CNF-84`'s Robot rescue case on the integrated harness; the
  historical rehearsal is not that evidence.
- Paid/public relay enablement supplies signed revocation (`CNF-60`).

Each part closes on the app and hardware to which its applicability row applies. A format
alone closes none of these empirical gaps.

**OPN-5 — The cloud-account floor.** Cloud vendors want an account, a card, and a recurring
relationship, several times over, and invoice relay cannot fix it. This is what makes lnrent
structural rather than a second tenant, and what makes `OVR-5` hard.

*2026-10-05.* A vendor paid in Bitcoin with no account is one such vendor if `OPN-24`'s probe
passes; the second is stage 2's work.

*Closes when:* an operator can obtain machines at two distinct vendors without opening two
billing relationships.

## One probe or one boot from closing

Each is an afternoon of work that nobody has spent.

**OPN-7 — Whether the second inference proxy is reachable from a browser at all.** An
OpenAI-compatible API does not imply an origin may call it. **The first proxy is now probed and
passes** (2026-09-05, recorded in ADR-0007), so this is exactly what remains: the *second* one,
which `ARC-14`'s proxy layer needs before it can move off one. *Closes when:* the same probe the
first proxy got is run against it.

**OPN-8 — Whether a second cloud vendor's API permits a browser origin.** Roughly eighty lines
of curl; the existing probe is a template, not a drop-in, since it hardcodes the first vendor's
base URLs, paths and assertions. The answer decides direct `fetch` versus the pinned tunnel
(`CHN-12a`), not whether the vendor is usable (ADR-0017). *Closes when:* the forked probe
passes or fails against a named second vendor.

**OPN-24 — Whether LNVPS can be the first vendor, and the jump vendor.** LNVPS (lnvps.net;
its API is published at github.com/LNVPS/api) sells machines for Lightning, identifies a buyer
by a Nostr key, and keeps no account: what `CHN-R6` asks of a jump vendor, and what stage 1
wants of its only vendor (`STG-21`). Nothing about it has been measured. The probe's owning list is:

- **Boot-time user-data, or published host keys** — whether `CHN-R5` or a retrieve route can
  pin a machine there at all.
- **Browser reachability** — whether its API answers a browser origin, or needs the pinned
  tunnel of `CHN-12a`.
- **Inventory and destruction** — whether it **lists a key's machines and can destroy them**.
- **The minimum billing period** — which is what a jump host that lives for minutes costs.
- **An Arch image** — whether stage 1's distribution can be installed from the vendor's own
  catalogue.

*Closes when:* the probe is run and its answers recorded under `docs/findings/`. If it passes,
LNVPS may be the target itself, by attest. If it fails, stage 1 — and only stage 1 — runs on
Hetzner Cloud with attest and a card account; what that drops is listed in `STG-21`. Which answers
make it fail is not yet stated (T39).

**OPN-25 — Whether Omarchy has a server edition, or plain Arch stands in.** The owner's
scenario installs Hermes on Omarchy. Whether Omarchy installs and runs on a machine with no
display is not known. *Closes when:* an Omarchy server installation completes over the
channel, or the scenario is restated on plain Arch. Either way the distribution has no pin in
the bundle today (`ARC-24`), so the scenario runs under the unpinned label unless the publisher
adds an Arch pin first; which of the two it is, is recorded when the publisher takes it.

**OPN-9 — Whether the proof of concept's cloud-init boots an unreachable machine.** A code-read
finding, not an observed failure: its user list has no default entry and sets an empty
authorized-keys list, so the vendor's injected keys reach no account. The fix is one line and
nobody has booted the file. *Closes when:* the file is booted once.

## Design-level, still open

These do not block starting construction. `OPN-14` **does block completing the first stage**;
the remaining entries gate the feature each names.

**OPN-10 — The brief format schema.** Frontmatter fields, the local/remote block marker,
versioning, signing. *"How a block returns structured data to the next one" is answered: it
does not* — every model-issued command is a stateless job and values have named sources
(`ARC-7`). Designing a second consumer
for an undefined format is premature until this exists. *First input 2026-09-08:*
`docs/briefs/01-install.md`, plain prose with example commands and deliberately no format.
A fourth brief, the relay-install brief that `CHN-14` and ADR-0019 rely on, is the harness's,
and is owed when self-host migration is offered, which no stage yet does; nothing has been
written for it.
*Closes when:* the three briefs named in `STG-2` are generalized into a schema.

**OPN-11 — What executes brief commands locally in the browser.** Either a WASI host with
uutils guests, as the archived specification assumes, or a small set of purpose-built commands.
Deliberately not decided in advance: the extent is to be derived from real briefs rather than
guessed. *First evidence 2026-09-08:* in brief 1 exactly two things are browser-side — the
artifact hash comparison against the bundle's value and the host-key fingerprint derivation
— and both are comparisons of values the harness reads from jobs it composed itself
(`ARC-43`), not commands the model runs and not values the model reports. *Closes when:*
`STG-2`'s briefs show which commands genuinely need the browser rather than the machine.

**OPN-14 — What "locked down" means, per vendor.** A pentest can only assert what it checks, so
the checklist is part of the signed brief set — and it does not exist yet for any vendor. Until
it does, `ARC-17`'s deliverable has no definition to be measured against.

Two parts are no longer open. Who may run which check was settled by `ARC-26`. And the *shape* is
settled: a delivery declaration (`ARC-39`) — a tenant's, or with no tenant the one the operator
approved — and the check measures against it.
The declaration format was the missing piece and now exists (below; default credentials are a
field of it). What remains outside any declaration is the **vendor lockdown checklist** —
sshd posture and whatever a given vendor makes possible.

That also makes the question per-**tenant** as much as per-vendor, which the title understates.
*The declaration format exists as of 2026-09-15:*
[`docs/design/delivery-declaration-v1.md`](./docs/design/delivery-declaration-v1.md), with
every field present as a value, an explicit empty set, or `unspecified`, and the lnrent
template shipped with every unstated field `unspecified` so the harness invents nothing.
*Split 2026-10-05.* With no tenant the declaration is the one the operator approved
(`ARC-39`), so no tenant's input gates stage 1. What stage 1 needs from this entry is a
**generic signed lockdown checklist**: the fixed checks `ARC-17` names — default credentials
and sshd posture — keyed on no vendor and no tenant, shipped in the bundle. It does not exist
yet. lnrent's declaration, the Robot checklist and briefs 2–3 gate stage 3.

*Owed 2026-10-06:* the harness-composed reads of `ARC-43` behind `CNF-50` and `CNF-53`:
listeners, unit state and enablement, evidence establishing survival of a restart, and a
service-name grammar that passes a validated name as an argument, never shell syntax.
Neither the concrete grammar, init-specific reads nor restart-demonstration mechanism is
selected here. Also open: whether `STG-9`'s re-entry re-check reads `services` as well as
`drift_checks`, and whether `running-at-delivery` binds after delivery; neither changes how a
lifecycle finding treats placement (`ARC-17`). T42 carries their implementation and stage 1
still owes their evidence.

*Closes when:* the generic checklist ships and `CNF-49`–`CNF-53` and `CNF-99` have integrated
evidence against it — that much for stage 1; and, for stage 3, the lnrent owner fills that
template ([douglaz/lnrent#87](https://github.com/douglaz/lnrent/issues/87)), the Robot lockdown
checklist exists, and briefs 2–3 are authored from them and exercised. The tenant half is a
required tenant input, not permission to invent its operational contract inside the harness.

**OPN-26 — The derived vendor identity has no format, and stage 1's vendor credential no
decided origin.** `SEC-4` names a vendor identity derived per set as the untyped vendor
scope's best practice, and `CHN-R6` wants the jump vendor's identity separate from the
target's. Credential format v1 defines no role for either, and `SEC-5` row 22 records that
none is derived or used until it does. Undecided: what the identity is derived per — a bound
set, a machine or a session; whether it takes a machine-family index or a family of its own,
and what its allocation entry holds; and its key type, which waits on what LNVPS's Nostr
identity requires (`OPN-24`). Undecided beside it: whether stage 1's typed LNVPS adapter runs
on a credential the operator supplies — `SEC-5` row 1, which is what the corpus says today — or
on a derived one. *Closes when:* the format is decided. Markdown, the Lean declarations, the
known-answer vectors, their checker and the witness files then change together (`STA-22a`,
ADR-0032).

**OPN-27 — What shape a multi-machine tenant takes.** A tenant is skill-shaped content —
briefs and presets (`ARC-44`). Whether btc-policy fits that shape is open: atomic creation
across vendors, sealing and the coordinator are profile slots and harness rules today
(`ARC-19`, `ARC-27`), and whether they stay a harness capability a tenant's presets switch on
is undecided. So is whether lnrent is a tenant at all, or a vendor the operator buys from. And
one known gap sits under any declared independence bound: `ARC-31b` gives every session the
highest-ranked candidate, so a different model per machine is not deliverable on the procured
path. *Closes when:* stage 3 is designed.

**OPN-28 — Placed-secret scanning after store loss.** *Closed by design; open as
implementation, 2026-10-06.* `SEC-5` row 23 and its scan semantics define the browser-keyed
reference; `ARC-43` owns placement, machine re-hashing and the local paste fallback. The key
may be held immediately under that design; evidence is a completion gate, not authority to
construct it. T48 carries the build and the still-open numeric minimum secret length.

*Closes when:* `CNF-95`'s cases pass on the integrated harness, paired with `CNF-84` for
Restore and `CNF-42` for the retained exposure display. Construction can proceed; stage 1
requires that evidence, including fallback and output boundaries.

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
[ADR-0025](./docs/adr/0025-relay-access-is-bought-not-granted.md)). Issuance is a payment
bound to a key the browser derives from the seed, scoping and lifetime are the destination
record `CHN-16` describes. Existing access is recoverable when the seed and pass metadata
survive. A compromised seed or missing pass metadata requires a new key and purchase;
unknown old passes expire rather than being reported revoked (`STA-17`, `STA-22b`).

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
output, its exit code and its liveness, on installed-system persistent disk. Rescue uses
`STA-20b`'s same-boot records and browser-journal handoff; missing records never establish success. `STA-21` states the limit: the record
is machine-reported and advisory, and comparing it against the browser journal catches honest
mistakes rather than a hostile machine.
[ADR-0022](./docs/adr/0022-durable-state-is-an-append-only-journal.md)'s amendment carries the
reasoning and the three rejected alternatives. *Closes when:* `CNF-40`, `CNF-54`–`CNF-56` pass
on the integrated harness (T23) — the part stage 1 gates on — and `CNF-86` passes there too,
which the dedicated row of `07-conformance.md` asks for, not stage 1.

**OPN-22 — What "still alive" means in `STA-20`.** **Closed: the narrow reading binds.** `STA-20`
tracks whether **the command** is alive, not everything the command spawned. Daemon and service
health is `ARC-39`'s delivery declaration, which already distinguishes a node that must survive
reboot from one that dies on it by design, so the wide reading would only duplicate `ARC-39` at
the cost of the corpus's one non-POSIX dependency.

The finding that forced the question stands as the reason the answer is cheap. A daemonising
process calls `setsid()`, which by POSIX creates a new session **and** a new process group, so
it leaves both of the only groupings POSIX can enumerate; `wait()` cannot see it either, since
daemonising orphans it deliberately. **POSIX has no descendant-tracking primitive at all.** The
one mechanism that does follow a detached child — cgroup v2, membership inherited across `fork()`
and unaffected by `setsid()` — is a kernel interface, not POSIX, and carries an unverified
prerequisite (cgroup2 mounted at boot on Alpine, which its own docs say must be enabled). An
`flock` on an inherited descriptor was also checked and rejected: it reports a well-behaved
daemon **dead while it runs**, because the canonical recipe closes inherited descriptors. The
narrow reading needs none of that — a command's own process stays in the wrapper's process group
and is observable on both distributions — which is why `STA-20` keeps its "POSIX" and does not
become "Linux, init-agnostic".

Two real defects surfaced on the way and were kept, because they were the useful part of the
finding: output must be captured by file redirection, not a held pipe (`STA-20a`), and no orphan
test may rest on a reparented process's new parent, which differs across the two distributions.

**OPN-23 — The observed provider layer had no source.** **Closed: the layer is requested, not
observed.** `ARC-14` used to count the inference provider as a third, *observed* layer built
from `X-Provider-Name` — **OpenRouter's** header, written down while OpenRouter was the live
candidate. The aggregator actually chosen exposes no equivalent (verified 2026-09-05), and page
script could not read one if it did, because the completions endpoint exposes only a request id
to a cross-origin caller. A count derived from the model name would have reported whoever
**made** the weights under a label reading *observed*, so `SEC-9` forbade it.

*The answer is to stop observing and start asking.* The aggregator accepts a routing object in
the request — the same conventions as the aggregator whose header this layer was built on — so
the harness **requests** a provider per machine exactly as it requests a model, and the display
shows what was asked, labelled *requested*. All three layers are then configured, which is the
shape `OPN-4` had already reached for weights. The aggregator's own documentation says supplied
provider fields "may be overridden" — for a few models with routing rules it enforces, per its
`api-docs` page read 2026-09-23; that is `TRU-E2`'s existing trust, and the label carries it.
`CNF-78` checks the request carries the pin, and whether an unsatisfiable pin fails the call or
silently reroutes — the one thing about the override that *is* observable.

*2026-09-22, measured.* An unsatisfiable pin fails the call: refused with `404` at a named
routing step, on two days (`docs/findings/2026-09-22-provider-routing.md`). And "exposes no
equivalent" is no longer unqualified: a response to a `provider.only` request carries a
`provider` field that follows the pin. It is the proxy's own report in a body, not a header a
browser was shown to read, and not evidence from the party that served; the label stays
*requested*. Whether that field is *the served provider* was T38's question; its use was
decided on 2026-09-24 without answering it, and the standing ask is rewritten below.

*Rejected:* switching to an aggregator that reports the served provider, which trades the
accountless Lightning funding and open CORS that won this one the slot for a number; and
retiring the layer, which throws away reasoning that is still right.

*A standing ask, rewritten 2026-09-24.* The first ask — expose the served provider where a
browser can read it — cannot be met by a response field: what appeared is a *reported provider*,
the proxy's word about itself, in a body whose CORS headers a browser could read. `SEC-9` says
"A response's own report of the provider is compared, never shown as a count", and the
*observed* column stays a *may*. What is asked now costs them as little and is still missing:
document the field's semantics — the party that served, or an echo of the request; publish the
mapping from the display names it prints (`Z.AI`) to the slugs it accepts (`z-ai`); and confirm
or deny the upstream that `TRU-E2` now names by inference. Nothing here waits on any of it.

**OPN-4 — Weights-level diversity may not be enforceable.** *Closed 2026-09-12 by restatement.*
The runtime signal named the *inference provider*, not the weights behind it — and the
provider is a layer nobody configures, so there was nothing there to enforce either. The
honest position was the one `ARC-14` recorded at the time: report what was observed, promise
nothing forward.

*The signal situation changed, and not only for the worse.* On the chosen aggregator there was
no provider signal at all when this closed, so the sentence above described a signal that was
gone; a `provider` field has since appeared on one request path, as the proxy's own report
(2026-09-22, `docs/findings/2026-09-22-provider-routing.md`). But
the **weights are configured, not observed**: the harness picks the model per machine, and the
catalogue names which vendor made it, so distinctness across machines is enforceable **by
construction** rather than by inspection. What remains unverifiable is whether the proxy served
the model it was asked for — which is a smaller and better-shaped gap than "no signal reaches
the weights", and it is the same gap `TRU-E2` already names when it says the proxy can alter
everything it carries. **The provider layer now takes the same shape** (`OPN-23`, closed): it is
requested per machine rather than observed, and the same override caveat applies to both.

*What closed it:* `SEC-CLAIM` now states the condition that way — configured weights, distinct
by construction, with service-as-requested left to `TRU-E2`. A signal confirming the served
model would add an *observed* column; none has a candidate, and nothing waits on it.

*Amended 2026-10-06.* The historical "distinct by construction" account above is not what
the procured path currently delivers: `ARC-31b` says it "takes the highest-ranked candidate
it finds there" at session start. The configured-diversity gap is `OPN-27`'s stage-3 question.
This note does not reopen the served-weights observability question closed here.

**OPN-1 — The SSH client.** *Closed 2026-09-08: the mechanism ran, and it ran on a phone.* An SSH implementation compiled to `wasm32-unknown-unknown` with
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
`getrandom_backend="wasm_js"` in rustflags (that last item has since become unnecessary — see
below). The one genuine blocker is that russh's current
default crypto backend does not support this target, which a feature flag settles
([ADR-0024](./docs/adr/0024-the-ssh-client-is-rust-following-a-known-good-configuration.md)).

**Size is settled too, and it favours Rust.** The reference deployment's WebAssembly module is
~1.5 MB raw and **~574 KB gzipped**, the whole application ~584 KB gzipped — terminal and UI
included — against ~4.94 MB for the Go equivalent (ADR-0024).

*Run 2026-09-07, and the mechanism holds.* A spike (`prototypes/wasm-spikes/`, findings in
[`docs/findings/2026-09-07-wasm-spikes.md`](./docs/findings/2026-09-07-wasm-spikes.md))
carried the configuration to russh 0.63.2, reached a real `sshd` through a WebSocket bridge,
authenticated with an ed25519 key derived in the page from 32 bytes — the shape `STA-22` will
hand it — and **refused a mismatched host key from the SSH layer, before authentication**,
reporting the pinned and the presented fingerprints. That is the `Changed{old, new}` status
`SEC-11` and `CHN-R4` want, and it cost two lines; the references' omission was a choice, not a
difficulty. The getrandom rustflag in ADR-0024 is no longer needed and nothing else in the
configuration changed. The SSH client alone is 308 KB gzipped.

*What closed it:* the spike's cases passed on a physical Android Chrome, which `OVR-1` now
names as the only tested platform; `CNF-79` carries the same cases for the real build. The
channel itself is now days from the spike, not weeks; the terminal and UI layer is separate
work.

**OPN-21 — A pinned TLS client inside WebAssembly.** *Closed 2026-09-08, alongside `OPN-1`.* The first stage cannot reach its vendor
API without one (`CHN-R1`, `CHN-12a`, `STG-3a`), so this gates alongside the SSH client.

*Run 2026-09-07; the belief was right in substance and wrong in one detail.* The same spike
terminated TLS 1.3 inside the module against `robot-ws.your-server.de` — the host Hetzner's
own documentation names — read Robot's real JSON response through the bridge, and **refused a
valid Let's Encrypt certificate presented by `api.hetzner.cloud` before any application byte
was sent**, which is `CNF-62`'s test as written. `rustls`'s verifier interface is replaceable,
checked at source, but the pin needed no custom verifier: a trust store holding exactly the
pinned issuing authority and nothing else *is* the pin, and the stock verifier then checks
chain, name and validity against it (`CHN-12a`). `ring` serves both clients, as `ADR-0024`
assumed. The detail nobody had written down: `rustls` does not compile for this target without
`rustls-pki-types`'s `web` feature, which supplies the clock. TLS costs 187 KB gzipped over the
SSH client alone.

*What closed it:* the same two cases passed on a physical Android Chrome (`CNF-79` carries
them for the real build). One fact is already dated: the pinned authority expires **2027-11-02**, which is
the first rotation `CHN-12a`'s cost clause will be paid on.

**OPN-6 — What Robot's rescue `host_key` field actually returns.** *Closed 2026-09-08: the
first stage ran by hand and `CNF-48` is recorded.* *Partly answered 2026-08-31, read-only,
against a real account.* The field **exists and is an array**, empty
while rescue is inactive. What it holds once rescue is activated — full public keys,
fingerprints, which algorithms — still needs one `POST`, which reboots the machine, so it was
not run.

The same session settled two other things. **Robot is not browser-reachable** (`CHN-R1`): a
previously recorded probe said otherwise and was wrong. And the installer catalogue was read
directly — AlmaLinux, Arch, CentOS Stream, Debian, openSUSE, Rocky, Ubuntu, with **no Alpine and
no NixOS** — so `ARC-24` and `STG-3`'s claim that custom installation is mandatory is verified
rather than inferred.

*What closed it:* one `POST`, one reset, and a disposable auction server. The activation
`POST` publishes **nothing**; `GET /boot/{n}/rescue/last` publishes SHA-256 fingerprints per
algorithm, no public keys, about 80 s after the reset and some 10 s before sshd answers, fresh
on every rescue boot. Both hops of the identity chain then closed with no trust-on-first-use
(`CHN-R1` rewritten, `STG-4` amended; `docs/findings/2026-09-08-first-stage-rehearsal.md`).
The same run found that the first stage's real cost is a machine that does not come back —
see `STG-20`.

## Status and the next move

The installation and identity-chain rehearsal ran on a disposable dedicated server on
2026-09-08 (`docs/findings/2026-09-08-first-stage-rehearsal.md`). Both pinned SSH hops closed;
`OPN-6` is closed. The Rust/WASM SSH and pinned-TLS spikes also ran, including physical
Android evidence. Robot's browser route is the pinned TLS tunnel, not direct CORS fetch.

Construct the integrated harness from those results and the v1 credential/storage contracts,
using the dedicated path as the test bed. In parallel, run stage 0: the LNVPS probe (`OPN-24`),
attest on a real first boot (`OPN-3`), and the Omarchy question (`OPN-25`); and write the
generic lockdown checklist (`OPN-14`). The live rehearsal has not demonstrated the harness, a
goal-driven install, local unlock, or interrupted-install convergence. Complete the stage-1
conformance subset before claiming delivery; do not repeat the already-closed identity-chain
probe as a construction gate.
