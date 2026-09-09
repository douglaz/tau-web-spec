# 08 — Open questions

This owns open decisions and empirical gaps. `TASKS.md` links execution work back here;
`07-conformance.md` owns the acceptance evidence and stage applicability.

Each entry says **what would close it**, because a question without a closure criterion is a
worry rather than a work item, and because the gating set otherwise mixes a twenty-minute
probe with a multi-week spike as though they were the same size.

## Gates by milestone

Construction admission (`STG-2`) closed with the September 8 installation rehearsal.
Completing the first stage still gates on `OPN-14`, integrated resume (`OPN-18`), and the
first-stage acceptance subset in `07-conformance.md`, including `STA-23` unlock and v1
derivation evidence. `OPN-3` gates recovery/cloud enablement; `OPN-4` gates the vault claim;
`OPN-5` gates the eventual phone-only acquisition experience, not first-stage construction.

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

*Closes when:* `CNF-18`, `CNF-19`, `CNF-20`, `CNF-72`, `CNF-83` and `CNF-84` pass on the
app and hardware to which each applies. The format alone does not close the recovery gate.

**OPN-4 — Weights-level diversity may not be enforceable.** The runtime signal named the
*inference provider*, not the weights behind it — and the provider is a layer nobody
configures, so there was nothing there to enforce either. The honest position is the one
`ARC-14` records: report what was observed, promise nothing forward. `SEC-CLAIM` stays
conditional on weights-level distinctness.

*The signal situation changed, and not only for the worse.* On the chosen aggregator there is
no provider signal at all, so the sentence above describes a signal that is gone. But
the **weights are configured, not observed**: the harness picks the model per member, and the
catalogue names which vendor made it, so distinctness across members is enforceable **by
construction** rather than by inspection. What remains unverifiable is whether the proxy served
the model it was asked for — which is a smaller and better-shaped gap than "no signal reaches
the weights", and it is the same gap `TRU-E2` already names when it says the proxy can alter
everything it carries. **The provider layer now takes the same shape** (`OPN-23`, closed): it is
requested per member rather than observed, and the same override caveat applies to both.

*Closes when:* the claim is restated around what is configured rather than what is observed, or
a signal confirming the served model appears. The second has no current candidate.

**OPN-5 — The cloud-account floor.** Cloud vendors want an account, a card, and a recurring
relationship, several times over, and invoice relay cannot fix it. This is what makes lnrent
structural rather than a second tenant, and what makes `OVR-5` hard.

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
base URLs, paths and assertions. `OVR-5` depends on the answer. *Closes when:* the forked probe
passes or fails against a named second vendor.

**OPN-9 — Whether the proof of concept's cloud-init boots an unreachable machine.** A code-read
finding, not an observed failure: its user list has no default entry and sets an empty
authorized-keys list, so the vendor's injected keys reach no account. The fix is one line and
nobody has booted the file. *Closes when:* the file is booted once.

## Design-level, still open

These do not block starting construction. `OPN-14` **does block completing the first stage**;
the remaining entries gate the feature each names.

**OPN-10 — The brief format schema.** Frontmatter fields, the local/remote block marker, how a
block returns structured data to the next one, versioning, signing. Designing a second consumer
for an undefined format is premature until this exists. *First input 2026-09-08:*
`docs/briefs/01-install.md`, plain prose with example commands and deliberately no format.
*Closes when:* the three briefs named in `STG-2` are generalized into a schema.

**OPN-11 — What executes brief commands locally in the browser.** Either a WASI host with
uutils guests, as the archived specification assumes, or a small set of purpose-built commands.
Deliberately not decided in advance: the extent is to be derived from real briefs rather than
guessed. *First evidence 2026-09-08:* in brief 1 exactly two things are browser-side — the
artifact hash comparison against the bundle's value and the host-key fingerprint derivation
— and both are comparisons of values the machine reports, not commands. *Closes when:*
`STG-2`'s briefs show which commands genuinely need the browser rather than the machine.

**OPN-14 — What "locked down" means, per vendor.** A pentest can only assert what it checks, so
the checklist is part of the signed brief set — and it does not exist yet for any vendor. Until
it does, `ARC-17`'s deliverable has no definition to be measured against.

Two parts are no longer open. Who may run which check was settled by `ARC-26`. And the *shape* is
settled by `ARC-39`: the tenant supplies a delivery declaration and the check measures against it,
so what is actually missing is the **declaration format** plus the items no declaration covers —
default credentials, sshd posture, and whatever a given vendor makes possible.

That also makes the question per-**tenant** as much as per-vendor, which the title understates.
*Closes when:* the lnrent owner supplies its concrete delivery declaration
([douglaz/lnrent#87](https://github.com/douglaz/lnrent/issues/87)) (listeners,
service lifecycle, permitted key material and drift checks), a declaration format and Robot
lockdown checklist exist, and briefs 2–3 are authored from them and exercised. `CNF-49`–`CNF-53`
then need integrated evidence. This is a required tenant input, not permission to invent its
operational contract inside the harness.

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
reasoning and the three rejected alternatives. *Closes when:* `CNF-40` passes.

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
the harness **requests** a provider per member exactly as it requests a model, and the display
shows what was asked, labelled *requested*. All three layers are then configured, which is the
shape `OPN-4` had already reached for weights. The aggregator's own documentation says supplied
provider fields "may be overridden"; that is `TRU-E2`'s existing trust, and the label carries it.
`CNF-78` checks the request carries the pin, and whether an unsatisfiable pin fails the call or
silently reroutes — the one thing about the override that *is* observable.

*Rejected:* switching to an aggregator that reports the served provider, which trades the
accountless Lightning funding and open CORS that won this one the slot for a number; and
retiring the layer, which throws away reasoning that is still right.

*A standing ask, not a dependency.* If the aggregator exposes the served provider and adds it to
the headers a browser may read, an *observed* column sits beside the requested one and override
becomes visible per response. Cheap for them if the circumstantial evidence that they resell
another aggregator holds — **inference, not verification** — and nothing here waits on it.

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

**Size is settled too, and it favours Rust.** The reference deployment is ~1.5 MB raw and
**~574 KB gzipped for the whole application** — terminal and UI included — against ~4.94 MB for
the Go equivalent.

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

Construct the integrated harness from those results and the v1 credential/storage contracts.
In parallel, obtain the lnrent declaration and finish the lockdown checklist and briefs 2–3
(`OPN-14`). The live rehearsal has not demonstrated the harness, tenant delivery, local unlock,
or interrupted-install convergence. Complete the first-stage conformance subset before
claiming delivery; do not repeat the already-closed identity-chain probe as a construction gate.
