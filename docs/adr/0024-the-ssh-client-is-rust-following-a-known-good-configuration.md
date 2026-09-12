# The SSH client is Rust, following a known-good configuration

The browser SSH client is written in **Rust**, compiled to `wasm32-unknown-unknown`, using
`russh` with the `ring` backend and a WebSocket adapted into an async byte stream. No second
language enters the bundle.

This looks obvious now and was not obvious when it was decided, which is why it is recorded.

## Why it needed deciding at all

Every browser SSH client that could be found at first was written in Go against
`x/crypto/ssh` — five of them, shipping, including Tailscale's SSH Console and Google's
Secure Shell. Against that, the Rust option looked like pioneering: `russh` is async and
tokio-shaped, and the one upstream issue anybody cited about WebAssembly was open.

So the question was whether to admit a Go module into the bundle. Bundle size and build
tidiness both looked like the objection and neither survives scrutiny: the archived
specification already prices WASM size as a Medium risk with lazy loading as the mitigation,
and Go builds are reproducible.

**The objection that does survive is the credential boundary.** The SSH client holds the
per-machine client private key (`SEC-5` row 3) and enforces the host-key halt (`SEC-11`). In
Rust that discipline is *structural*: the proof of concept's `SecretString` implements neither
`Clone` nor `Serialize`, so a credential cannot be copied into a log line or a prompt because
the compiler refuses. A Go module has no equivalent, so the same discipline becomes convention
in a second language with different guarantees, and the seam between the two modules becomes a
place a private key crosses. Everywhere else this design chooses structural enforcement over
policy — per-machine keypairs over routing checks (`SEC-1`), removal over isolation
(`ARC-37`), an inventory over a prohibition (`SEC-5`) — and this is the same choice.

## What research changed

Two beliefs that shaped the earlier framing turned out to be false, and both were load-bearing.

**"Every implementation is Go."** [`Ar4l/sshmux`](https://github.com/Ar4l/sshmux) is a Rust
browser SSH client on `wasm32-unknown-unknown`, served statically, mobile-first, built with
Trunk and Leptos CSR — which is the UI framework and build shape the archived specification
already recommends.

**It is an existence proof, not a production deployment, and this record originally overstated
it.** One author, no stars or forks, created and last pushed in July 2026. What it demonstrates
is that the configuration below works and the architecture is reachable in Rust — which is
exactly what was in doubt. It does not demonstrate maturity, and nothing should be inherited
from it but the configuration. A second Rust instance exists using Chrome's Direct Sockets
and no relay at all, and a third vendors a russh fork carrying `russh-cryptovec`'s WASM
platform module.

**"The blocker is russh's open WebAssembly issue."** That issue concerns WASI under
wasmtime/wasmer. Different target, different obstacles, never about the browser. The actual
blocker on this target is narrower: russh's current *default* crypto backend does not support
`wasm32-unknown-unknown`, which a feature flag settles.

The working configuration is published, was independently derived twice, and **was run here
on 2026-09-07** (`prototypes/wasm-spikes/`, findings in `docs/findings/`). As it compiled:

```toml
russh = { version = "0.63", default-features = false, features = ["ring"] }   # no flate2, no rsa
ring  = { version = "0.17", features = ["wasm32_unknown_unknown_js"] }
ws_stream_wasm = { version = "0.7", features = ["tokio_io"] }   # tokio AsyncRead/Write directly
getrandom = { version = "0.4", features = ["wasm_js"] }         # russh 0.63 needs it; no rustflag
tokio = { version = "1", default-features = false, features = ["sync", "io-util"] }
# the pinned TLS client (CHN-12a) on the same provider:
rustls = { version = "0.23", default-features = false, features = ["ring", "std", "logging"] }
tokio-rustls = { version = "0.26", default-features = false, features = ["ring"] }
rustls-pki-types = { version = "1", features = ["web"] }   # REQUIRED: rustls's std build does not compile for wasm32 without it
```

Connect with `russh::client::connect_stream`, not `connect`: it accepts any
`AsyncRead + AsyncWrite`, which is what makes a WebSocket a valid transport and what removes
`std::net` from the picture entirely. Tokio on this target supports only `sync`, `macros`,
`io-util`, `rt` and `time`; a dependency that enables `net` or `rt-multi-thread` breaks the
build, which is the failure mode to watch for. **There is no tokio runtime in the browser at
all**: russh spawns onto `wasm_bindgen_futures`, and that is enough — but `client::Config`'s
`keepalive_interval` and `inactivity_timeout` call `tokio::time::sleep` and panic without a
timer driver, so they stay `None` and any keepalive is a browser timer.

**Size settles in Rust's favour rather than against it.** The reference build's WebAssembly
module is ~1.5 MB raw and **~574 KB gzipped**; the whole application is ~584 KB gzipped, UI and
in-wasm terminal included — against ~4.94 MB for the Go equivalent. (An earlier version of this
record attributed the 574 KB figure to the whole application; it is the module.) Measured here
with no UI framework: **308 KB gzipped for the SSH client, 495 KB for SSH and the pinned TLS
client together**, `ring` being the overlap.

## Considered options

**A Go module under a narrow exception**, extending the archived specification's precedent for
a scoped shim. Rejected on the credential boundary above. Worth recording because it will be
proposed again, and the argument for it is genuinely strong on availability: five shipping
implementations against one.

**Build on RustCrypto primitives.** `ssh-key`, `ssh-encoding` and `ssh-cipher` cover key
formats, wire encodings and packet ciphers — not the transport protocol or key exchange.
RustCrypto's actual `ssh-protocol` is explicitly work-in-progress. Taking this route means
writing and hardening an SSH implementation: six to twelve engineer-months plus security
review, for no gain over an existing one.

**Compile OpenSSH to WebAssembly.** Google's Secure Shell does exactly this, building the real
OpenSSH C client to `wasm32-wasip1` with the WASI SDK, and it is actively maintained. It has
the lowest protocol risk of any option. Rejected as the primary path because it is a C/WASI
product rather than a Rust library, so it inherits a second toolchain and a socket-shim layer,
and the credential-boundary argument applies to it as much as to Go. **Retained as the
fallback** if russh's crypto backend proves costlier than expected.

**Chrome Direct Sockets, removing the relay entirely.** Genuinely attractive — no relay means
no `TRU-A2` and no metadata observer. Rejected because it requires an Isolated Web App, which
means installation, which `OVR-1` forbids in its first sentence. Recorded because a reader who
finds the Direct Sockets implementation will ask.

## Consequences

**`OPN-1` stops being the item most likely to sink the plan.** It still gates, because nothing
works without a client, but it is now integration work against a published configuration rather
than a bet. This changes what the first stage's fail-fast rationale
([ADR-0018](./0018-first-stage-is-one-lnrent-box-on-dedicated.md)) is actually buying, and that
deserves its own look.

**Host-key pinning is the part nobody has done.** The references skip it — most accept any host
key, and the best of them reaches a `Changed{old, new}` status rather than a boolean. That is
the one property `SEC-11` and `CHN-R4` depend on, so it is the real remaining work and it is
what `OPN-1` now closes on rather than "an SSH session connected." *Done on the spike of
2026-09-07: a mismatched host key is refused from the SSH layer, before authentication, with
both fingerprints reported (`OPN-1` closed); `CNF-21` and `CNF-79` carry it for the real build.*

**The reference is unlicensed.** `Ar4l/sshmux` carries no license file, so it is a
configuration to read and learn from, not code to copy. The dependency versions and feature
flags are facts; the implementation is not ours to take.

**A dependency can break the build silently.** Anything pulling Tokio's `net` or
`rt-multi-thread` fails this target, and the failure surfaces as a confusing compile error far
from its cause. Worth a build check rather than a comment.
