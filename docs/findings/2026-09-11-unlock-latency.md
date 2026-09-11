# Findings — local-store unlock latency (STA-23)

Date: 2026-09-11. Code: `prototypes/unlock-latency/index.html`. Evidence: the report below,
pasted from the page's **Copy report** on the operator's phone.

The page builds the credential-format v1 local envelope with WebCrypto — PBKDF2-HMAC-SHA-256
at the stated iteration count, AES-256-GCM key wrap under the `tau-web/local/v1/<id>` AAD —
and times one unlock, KDF and unwrap separately, median of three.

## Verdict

**v1 keeps 600,000 iterations.** One unlock costs 58 ms on the phone, far below anything an
operator notices, so there is no case for a lower count and no migration to plan. A wrong
passphrase fails closed at the same cost (the GCM tag rejects it after the full KDF), so
latency leaks nothing about the passphrase.

The phone matches the desktop baseline (57 ms on a Ryzen 9 9950X under node's webcrypto)
because both have hardware SHA-256; cost is linear in iterations on both.

## Phone

Android 10 WebView, Chrome 152, 8 cores, 8 GB, inside the Claude app; a physical device, not
an emulation.

| iterations | KDF ms | unwrap ms | total ms | result |
|---|---|---|---|---|
| 100,000 | 10 | 0.1 | 10 | unlocked |
| 210,000 | 20 | 0.2 | 20 | unlocked |
| 600,000 | 57 | 0.2 | 58 | unlocked |
| 600,000 | 56 | 0.2 | 57 | unlocked |
| 1,000,000 | 94 | 0.1 | 94 | unlocked |
| 600,000 | 56 | 3.0 | 59 | failed closed (wrong passphrase) |

## What this does not show

A device without SHA extensions, or a much older phone, was not measured; at the linear rate
seen here even a tenfold-slower device stays under a second. The measurement is on the main
thread; the harness worker runs the same WebCrypto call, so the cost is the same.
