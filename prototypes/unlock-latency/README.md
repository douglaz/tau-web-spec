# Unlock latency (STA-23)

Throwaway. Answers one question from `docs/design/credential-format-v1.md`: how long does one
local-store unlock take on the first-stage phone at the v1 work factor (PBKDF2-HMAC-SHA-256,
600,000 iterations, AES-256-GCM key unwrap)?

`index.html` builds the real v1 envelope with WebCrypto, unlocks it, and reports median KDF,
unwrap and total time per iteration count. Open it on the phone (any static host, or a file
URL), press **Measure**, read the 600,000 row, press **Copy report**. **Wrong passphrase**
checks the fail-closed path costs the same as success. Nothing is stored or sent.

Baseline, 2026-09-11, node 24 webcrypto on a Ryzen 9 9950X (same primitive, no browser):

| iterations | ms |
|---|---|
| 100,000 | 10 |
| 600,000 | 57 |
| 1,000,000 | 94 |

Phone result, same day: 58 ms at 600,000 on an Android 10 / Chrome 152 device. Verdict and
full table in `docs/findings/2026-09-11-unlock-latency.md`; v1 keeps 600,000.
