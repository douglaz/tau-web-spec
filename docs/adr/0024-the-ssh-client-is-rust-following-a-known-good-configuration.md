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

**"Every implementation is Go."** [`Ar4l/sshmux`](https://github.com/Ar4l/sshmux) is a deployed
Rust browser SSH client on `wasm32-unknown-unknown`, served statically, mobile-first, built
with Trunk and Leptos CSR — which is the UI framework and build shape the archived
specification already recommends. A second Rust instance exists using Chrome's Direct Sockets
and no relay at all, and a third vendors a russh fork carrying `russh-cryptovec`'s WASM
platform module.

**"The blocker is russh's open WebAssembly issue."** That issue concerns WASI under
wasmtime/wasmer. Different target, different obstacles, never about the browser. The actual
blocker on this target is narrower: russh's current *default* crypto backend does not support
`wasm32-unknown-unknown`, which a feature flag settles.

The working configuration is published and was independently derived twice:

```toml
russh = { version = "…", default-features = false, features = ["flate2", "ring"] }
ring  = { version = "0.17", features = ["wasm32_unknown_unknown_js"] }
ws_stream_wasm = "0.7"          # under cfg(target_arch = "wasm32")
# rustflags: --cfg getrandom_backend="wasm_js"
```

Connect with `russh::client::connect_stream`, not `connect`: it accepts any
`AsyncRead + AsyncWrite`, which is what makes a WebSocket a valid transport and what removes
`std::net` from the picture entirely. Tokio on this target supports only `sync`, `macros`,
`io-util`, `rt` and `time`; a dependency that enables `net` or `rt-multi-thread` breaks the
build, which is the failure mode to watch for.

**Size settles in Rust's favour rather than against it.** The reference deployment is ~1.5 MB
raw and **~574 KB gzipped over the wire** for the entire application — Leptos UI and an in-wasm
terminal included — against ~4.94 MB for the Go equivalent.

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
what `OPN-1` now closes on rather than "an SSH session connected."

**The reference is unlicensed.** `Ar4l/sshmux` carries no license file, so it is a
configuration to read and learn from, not code to copy. The dependency versions and feature
flags are facts; the implementation is not ours to take.

**A dependency can break the build silently.** Anything pulling Tokio's `net` or
`rt-multi-thread` fails this target, and the failure surfaces as a confusing compile error far
from its cause. Worth a build check rather than a comment.
