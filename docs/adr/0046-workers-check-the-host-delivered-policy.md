# Workers check the host-delivered policy before unlocking

Accepted 2026-10-16. `ARC-32` owns the static host's policy header; `ARC-33` owns its reach
and the worker's first-running self-check. `CNF-111` owns the integrated-harness evidence.
No integrated pass is claimed by this decision.

## Why the header and the check

A page's policy does not by itself establish a URL-started worker's policy. The harness
worker holds the data key and seed, so policy admission has to happen in that context before
credentials or dependencies reach it. A patched global can counterfeit an eval-only check.
The host header delivers the policy; the worker checks the four refusals in its own context.
A site-wide header suffices; per-path host control is unnecessary.

## Rejected: a blob shim

Starting workers from a `blob:` shim so they inherit the page's policy works in Chromium 154,
WebKitGTK 2.54.1 and Firefox 157. Measured: a URL-started module worker with no header runs
`eval`, `Function`, `data:` and cross-origin `import()` and opens a `ws:` socket; the shim
worker refuses all of them while its relative imports, `import.meta.url` and
`instantiateStreaming` work.

Rejected because `worker-src blob:` admits a string-to-worker path. A sibling worker made
from text cannot reach the keys, but can read and send the store's ciphertext, corrupt the
journal or hold the writer lock. The measured inheritance does not justify admitting that
path. These measurements support this rejection, not a pass of `CNF-111` on the harness.
