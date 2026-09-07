# wasm spikes — OPN-1 and OPN-21

Throwaway prototypes answering two gating questions in `08-open-questions.md`:

- **OPN-1** — a Rust SSH client on `wasm32-unknown-unknown`, transport swapped for a
  WebSocket, that reaches a real `sshd` through a bridge, authenticates with a keypair made in
  the page, and **refuses a host key that does not match the pin — from the SSH layer**.
- **OPN-21** — a TLS client in the same module, pinned to Robot's issuing authority with no
  certificate-authority store, that reads a real Robot response through the bridge and
  **refuses a valid certificate from any other issuer**.

Findings: `docs/findings/2026-09-07-wasm-spikes.md`. Throwaway means the code is written
without ceremony, not that it will be deleted; the implementation issue should point here.

## Run

```sh
nix develop                     # rustc + wasm32 target, wasm-bindgen, wasm-opt, websocat
scripts/build.sh                # → www/pkg, prints raw/gzip size; `scripts/build.sh ssh` for one spike
scripts/serve.sh                # stub bridges (websocat), non-root sshd on 2223, page on :8000
node scripts/qa.mjs             # headless Chrome, mobile emulation, four cases, screenshots in run/qa
```

`scripts/serve.sh` prints the sshd host-key fingerprint; the page shows the public key it
derived from its seed, which must be appended to `run/authorized_keys` before connecting
(`qa.mjs` does this). `BIND=0.0.0.0 scripts/serve.sh` exposes everything on the LAN so a phone
can open `http://<box>:8000/?user=<unix user>`.

The bridges have **no access control**; the relay's real NIP-42-shaped access (`CHN-15`) is
outside this spike. Robot credentials are never stored: paste `base64(user:pass)` into the page
or export `ROBOT_BASIC` for `qa.mjs`; without them Robot answers 401, which is still a real,
pinned, read response.

## Where the pin lives

`src/robot-issuer.pem` — Thawte TLS RSA CA G1, captured 2026-09-07 from
`robot-ws.your-server.de`, valid to 2027-11-02. Rotation means this file changes.
