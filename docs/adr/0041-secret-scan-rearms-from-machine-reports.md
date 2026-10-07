# The secret scan re-arms from a machine report, with its key kept in the browser

Decided 2026-10-06. The selected **D** construction re-hashes the recorded placement on the
machine after local-store loss, then keys that hash in the browser. `SEC-5` row 23 owns the
reference and its custody; `SEC-5` owns matching semantics; `ARC-43` owns the jobs, fallback
and release boundary. The sheet's metadata belongs to `STA-16` and its format companion.
This decision supplies the scan design that [ADR-0040](./0040-stage-one-includes-restore-and-replace.md)'s
Restore path needs.

## What the reference buys

A later session needs a reference to redact an ordinary exact copy printed by a command.
Keeping the value itself in browser storage would keep the secret merely to avoid recording
it elsewhere. The chosen local reference is a per-secret CSPRNG key, a keyed digest and the
byte length; it gives the scanner a comparison without retaining the value. The construction
is `HMAC-SHA-256(K, SHA-256(value))`, allowing a machine to return only the inner hash and
byte count while `K` remains in the browser. Nothing about this changes the machine's existing
root access or makes it trustworthy.

Losing the local store loses the reference as well as the key. The placement's path can
survive in the sheet without making the sheet an offline guessing oracle for the secret.
The machine can then report what is at that path now. It cannot prove those are the originally
placed bytes: a model with root may already have changed the file, or the machine may report
a decoy hash. This residual is accepted at the scan's existing PRE-SCALE tier, with the
bounded provenance label owned by `ARC-43`: "re-armed from the machine's report".

The label matters in both directions. Machine-selected current bytes can fail to catch the
old secret and can select other bytes for redaction. The minimum-length requirement and
visible named markers in `SEC-5` bound misleading output, without claiming hostile-machine
protection. The numeric minimum remains open in T48. Encoded, partial and transformed output
and plaintext machine-side output remain outside the scan's claim.

## Alternatives considered

| Option | Disposition |
|---|---|
| **A — export the scan key and digest in the sheet** | Rejected. Together they provide an offline guessing test for an application secret to anyone who unwraps the sheet; the seed would no longer be needed for that attack. Encryption of the sheet does not remove the new authority from its decrypted contents. |
| **B — operator re-paste plus a machine-maintained placement list** | Rejected as proposed. A mutable machine list cannot be the authority for the exposure display, and another list duplicates existing job records. Those records remain useful advisory evidence; the sheet carries the browser's placement metadata. |
| **B′ — paste-only local re-arm** | Retained as the visible fallback, not the default. A pasted value rebuilds a local reference without writing a file; it is neither rotation nor a new placement. It avoids trusting a machine's current bytes but makes every benign Restore depend on finding and pasting each secret. |
| **C — derive the scan key from the seed** | Deferred. A new derivation role is not free, and recovering a key does not recover the digest or placement inventory. It cannot make Restore work without a sheet change. |
| **D as first proposed — machine-side HMAC with the browser key sent over stdin** | Rejected. It exports a harness-held key to a machine and requires a credential-boundary exception merely to compute a reference. |
| **D in its adopted form — machine SHA-256 and byte count; browser keying** | Adopted. It gives benign Restore an automatic re-arm for sheet-recorded placements without sending a harness secret. Machine-only entries still require an operator act before arming. This is the lost-store design, not placing-session-only scanning. |
| **Re-arm from the machine every session** | Rejected. With an intact store the original reference is better evidence than current machine bytes. Replacing it each session would discard the comparison precisely when the file changed. |
| **G1 — exact-file placement and refusal of unrelated existing files** | Adopted in `ARC-43`, with the immediate post-placement hash/count cross-check. A file containing a wrapper or an added newline is not the value the browser scanned for; overwriting an unrelated configuration file is destroyed data. |
| **G2 — keep the byte length on the sheet** | Dropped. It detects some accidental changes but no same-length substitution, while adding value-derived material to the export. The immediate placing-session cross-check catches write mistakes while the browser still knows the original. No inode/ctime variant is adopted. |

## Consequences and boundaries

`ARC-43` owns `digest_secret`, including its exclusion from the model's tools, its advisory
job capture under `STA-20`, its symlink refusal and its status-only release. Existing machine
job records can add labelled placement hints but cannot erase the sheet or journal's entries.
An absent file remains an exposure. Re-arm does not rotate a key, clear that exposure, or
reapprove the declaration and weaker modes restored under `STA-16`.

The release boundary concerns both model context and transcript, across the whole bound set;
read-only commands and historical records are not exceptions. Unknown post-export placements
remain unknown rather than causing an indefinite wait for an unknowable inventory. The
question, known-reference wait and neither-sink exemption belong to `ARC-43`.

Sheet payload version 2 carries the placement metadata; derivation and encryption-envelope
versions stay unchanged. The format companion owns the field list and import refusals.
There is no authoritative machine-side placement-list file, no value-derived sheet material,
and no claim that a seed rebuilds lost history. Further changed-file detection policy remains
T48's question rather than an invented protection.

The design closes `OPN-28`'s construction question now. Integrated evidence remains open:
`CNF-95` owns the scan cases, paired with `CNF-84` for Restore and `CNF-42` for display.
The stage applicability table owns completion. No implementation behavior was tested by
recording this decision.
