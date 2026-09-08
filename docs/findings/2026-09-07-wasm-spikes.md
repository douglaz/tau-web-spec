# Findings — the two wasm spikes (OPN-1, OPN-21)

Date: 2026-09-07. Code: `prototypes/wasm-spikes/` on branch `prototype/wasm-spikes`. Evidence:
`2026-09-07-wasm-spikes/` beside this file (the QA driver's summary and two screenshots).

Both questions were run as one Rust crate compiled to `wasm32-unknown-unknown`, so the SSH and
TLS clients share one crypto provider (`ring`), one dependency resolution and one WebSocket
transport. The page was driven in headless Chrome under **mobile emulation** (390×844, touch,
Android user agent); **no physical Android or iOS device was used** — this box has neither.
That is the one gap between these results and the closure criteria as written.

## Verdicts

**OPN-1 — SSH client with host-key pinning: works, refusal is at the SSH layer.**
From the page, through a WebSocket→TCP bridge, to a real OpenSSH 10.5 `sshd`:

- the key exchange completes, the presented host key's SHA-256 fingerprint is compared to a
  pin **supplied as input**, and on a match the session authenticates with an ed25519 key
  derived in the page from a 32-byte seed, opens a channel and runs a command;
- with a wrong pin, `check_server_key` returns `false` and russh aborts with
  `Error::UnknownKey` **before authentication**. `sshd`'s log shows the second connection as
  `Connection closed … [preauth]`. No UI code decides anything; the page merely reports
  what the SSH layer refused, as `pinned: … / presented: …` — the `Changed{old, new}` shape
  `SEC-11`/`CHN-R4` asked for, and it cost two lines.

**OPN-21 — pinned TLS in wasm through the bridge: works, and needed no custom verifier.**
From the page, through the bridge, to `robot-ws.your-server.de:443` (the host named in
Hetzner's own Robot documentation):

- TLS 1.3 (`TLS13_AES_256_GCM_SHA384`) terminates inside the module, the chain is validated
  against **exactly one certificate shipped in the bundle** — Robot's issuing authority — and
  an HTTP `GET /server` reads Robot's real JSON response (a `401` with no credentials supplied;
  the request line, headers and body arrive intact, which is what the corpus needs);
- the same client pointed at `api.hetzner.cloud` (Let's Encrypt-issued, valid) fails the
  handshake with `InvalidCertificate(UnknownIssuer)` **before any application bytes are
  sent**. That is `CNF-62`'s test as written. The page names rotation as the likely cause
  (`CNF-64`).

**On the corpus's "replaceable interface" claim.** It is true and was checked at source:
`rustls::client::danger::ServerCertVerifier` is a public trait, installed through
`ConfigBuilder::dangerous().with_custom_certificate_verifier(...)`. But the pin did not need
it. rustls's ordinary verifier takes a `RootCertStore`, and a store holding one intermediate
CA certificate *is* the pin: webpki treats any trust anchor as an anchor and does full chain,
hostname and validity checking against it. So the verifier is stock code, zero custom crypto
policy, and `CHN-12a`'s "no certificate-authority store" holds in the strict sense — the store
exists but contains the one pinned authority and nothing else.

## Configuration that compiled (exact)

Toolchain from the crate's `flake.nix` (locked): `rustc 1.98.1`, `wasm-bindgen-cli 0.2.127`,
`binaryen 132` (`wasm-opt -Os`), `websocat 1.14.0` as the stub bridge.

| Crate | Version | Features / notes |
|---|---|---|
| `russh` | 0.63.2 | `default-features = false, features = ["ring"]` — no `flate2`, no `rsa` |
| `russh-util` / `russh-cryptovec` | 0.52.0 / 0.62.0 | pulled in; `russh-util` spawns onto `wasm_bindgen_futures` on this target |
| `ssh-key` | 0.7.0-rc.11 | via russh's re-export; `Ed25519Keypair::from_seed(&[u8; 32])` |
| `ring` | 0.17.14 | `wasm32_unknown_unknown_js` |
| `getrandom` | 0.2.17 **and** 0.4.3 | 0.2 via ring (`js`), 0.4 via russh (`wasm_js`). **No `--cfg getrandom_backend` rustflag was needed** with 0.4 |
| `ws_stream_wasm` | 0.7.5 | `tokio_io` feature: the socket is a tokio `AsyncRead + AsyncWrite` directly, no `tokio-util` compat |
| `tokio` | 1.53.1 | `sync`, `io-util` only from us; russh adds `time`, never invoked without keepalive |
| `rustls` | 0.23.44 | `default-features = false, features = ["ring", "std", "logging"]` — no `tls12`, no `aws_lc_rs` |
| `tokio-rustls` | 0.26.5 | `default-features = false, features = ["ring"]` |
| `rustls-pki-types` | 1.15.1 | **`web` feature required** (see below) |
| `rustls-webpki` | 0.103.15 | pulled by rustls |
| `wasm-bindgen` | =0.2.127 | must equal the CLI version exactly |

The reference configuration in ADR-0024 carried over to russh 0.63 with one change: russh now
depends on `getrandom 0.4` itself with `wasm_js`, so the `.cargo/config.toml` rustflag the
reference needed is gone.

## What did not compile on the first try, and why

1. **rustls 0.23 with `std` does not build on `wasm32-unknown-unknown` as-is.** Seven errors,
   all `UnixTime::now()` not found: `rustls-pki-types` only defines it on this target behind
   its `web` feature (backed by `web-time`). Fix: `rustls-pki-types = { features = ["web"] }`.
   This is not documented anywhere the corpus looked; it is the one genuine wasm gotcha in the
   TLS stack. (A custom `TimeProvider` is *also* wired in, using `js_sys::Date::now()`, so the
   certificate validity check uses the browser clock rather than a stubbed one.)
2. One edition-2024 lifetime capture in our own code (`impl Trait` return capturing a `&str`).
   Trivial.

Nothing else. russh, ring, ws_stream_wasm and tokio-rustls compiled for the target unchanged.
**No dependency pulled tokio `net` or `rt-multi-thread`** — the failure mode ADR-0024 warned
about did not occur with this feature set.

## Bundle size (after `wasm-opt -Os`, `lto`, `opt-level = "s"`)

| Build | raw | gzip |
|---|---|---|
| SSH only | 777 KB | 308 KB |
| TLS only | 528 KB | 224 KB |
| both | 1,212 KB | 495 KB |

The TLS client's marginal cost over SSH alone is **187 KB gzipped** (rather than the 224 KB it
costs alone — the shared `ring` is the overlap). The corpus's ~574 KB gzipped figure is for the
reference's whole module including a terminal emulator and UI framework; this spike has no UI
framework and lands under it with both clients. Runtime: wasm linear memory was **1.5 MiB**
after all four cases, JS heap 1.3 MB. `STG-15` wants a full install's peak, not this, but the
floor is tiny.

## Timings (loopback bridge, this box)

SSH connect + KEX + auth + exec: ~190 ms. SSH refusal: ~50 ms. Pinned TLS 1.3 handshake +
GET to Robot: ~1.1 s (network). TLS refusal of the other issuer: ~0.5 s.

## Notes for the real build

- **Seed-derived keys fit.** `STA-22`'s derivation only has to produce 32 bytes;
  `Ed25519Keypair::from_seed` takes exactly that. The spike derives from a random 32-byte hex
  string typed into the page; swapping in a BIP-32 child secret is a function argument.
- **The `Changed{old,new}` status is free** — the handler records what was presented, and
  the refusal message carries both. Nothing in russh needs patching.
- **No tokio runtime exists in the browser.** russh's `client::Handle` and channels work on
  `wasm_bindgen_futures::spawn_local` alone. Do not set `keepalive_interval` or
  `inactivity_timeout` in `client::Config`: those call `tokio::time::sleep`, which panics
  without a tokio timer driver. A browser keepalive, if wanted, is a `gloo_timers` loop that
  sends a channel request.
- **Distance from spike to `STG-13`** ("a channel access that does not present the bound
  session's own keypair is refused, by SSH"): the refusal side is already `sshd`'s job — the
  installed system's `authorized_keys` holds one public key. What remains is the harness
  binding the derived key to a session and never exposing the private half (the
  `SecretString` argument in ADR-0024); this spike keeps the key in a `PrivateKey` inside the
  module and never hands it to JS, which is the right shape but not yet enforced by a type.
  Estimate: the SSH channel as specified is days, not weeks, from this spike, plus whatever
  the terminal/UI layer costs.
- **Pin rotation is a build input.** `src/robot-issuer.pem` is Thawte TLS RSA CA G1
  (DigiCert), SHA-256 `4B:CC:5E:23:…:EB:20:C2`, valid to **2027-11-02**, captured
  2026-09-07. Robot's leaf (`*.your-server.de`) expires 2026-11-02, and a re-issued leaf from
  the same authority keeps working, which is exactly why `CHN-12a` pins the issuer.
- **The bridge is a websocat one-liner per destination.** The real relay's destination
  selection and NIP-42 access (`CHN-15`) were not touched; the spike proves the bytes, not the
  door. `CNF-63` (relay sees only ciphertext) is true by construction here — the bridge
  forwards opaque bytes — but was not inspected from the relay side.

## Physical device run — Android Chrome, 2026-09-08

Pixel 10 Pro XL, Chrome, over the tailnet to this box (`BIND=0.0.0.0 scripts/serve.sh`; the
page took `user`, `seed` and `pin` from the URL so nothing was typed on the phone). The operator
reported all four cases behaving as on the desktop. Server-side evidence for the SSH pair:
`sshd` accepted a publickey session for the seed's key (`SHA256:4oCeGtE/PGrsGrDQ8zJfBGvmYHTTYDAM1XBeJvLZvgk`,
derived on the phone from the seed in the URL and registered here beforehand), and closed the
next connection `[preauth]` — the wrong-pin halt. The TLS bridges are byte-forwarders and log
nothing, so the two TLS cases on the phone rest on the operator's report. The page first tried
HTTPS against port 8000 (Chrome's HTTPS-first upgrade) before falling back; the real app is
served over HTTPS and will not see this.

**A side finding from the same log.** The wrong-pin halt registered with OpenSSH 10.5 as a
"connection without attempting authentication", and `sshd` applied a per-source penalty
(`PerSourcePenalties`, default-on since OpenSSH 9.8: 1 s per preauth close, 5 s per refused
key, enforced once 15 s accrue, capped at 10 min). Every session reaches a machine from the
relay's address, but the penalty is per machine and only one operator's session and the
scanner ever reach a given machine through the relay, so the blast radius is a **self-lockout**
of up to ten minutes plus a scanner blind spot on port 22 for that window. Folded into `ARC-41`
on 2026-09-08 as an accepted narrowing: exempting the relay would be the privilege `ARC-41`
forbids, disabling the penalty would weaken a locked-down default, and the one rule that
follows — a refusal ends the attempt, no automatic reconnect — is stated there.

## What stays open

- `OPN-1` and `OPN-21` are now proven on the mechanism **and on one physical Android
  Chrome**. Each closure criterion also names iOS Safari, which has not been run. Same URL,
  same tailnet; a screenshot of the two red results is the record.
- `CNF-21` and `CNF-62` are demonstrable now, on the prototype. They are checklist items for
  the real build and should not be ticked from this.
- Peak memory during a full install (`STG-15`) is untouched.
