# Credential format v1

Normative companion to `STA-22a`, `STA-22b` and `STA-23`. These are the identities and
storage formats new implementations must reproduce; there is no deployed legacy format to
migrate. The fixtures beside this document contain public test secrets, never operator data.

## Seed and child keys

Generate a dedicated 128-bit entropy value with the browser CSPRNG and encode it as a
12-word English [BIP-39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
mnemonic. Import requires that word list, length and valid checksum. Derive the 64-byte
BIP-39 seed with its standard NFKD normalization and **empty BIP-39 passphrase**. The local
unlock passphrase is never the BIP-39 passphrase. Other word counts, languages and extensions
are unsupported in v1; reject them explicitly, never silently normalize into another seed.

Use [BIP-32](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki) private derivation
on secp256k1 with master HMAC key `Bitcoin seed`. Every path component below is hardened:

`m/707285'/1'/role'/index'`

`707285` is this application's namespace, not a registered wallet purpose or coin type;
`1` is the derivation version. This deliberately replaces the underspecified NIP-06 path.
Indices are integers from 0 through 2^31−1; each family has its own monotonic allocator.
No wraparound is allowed. Derivation rejects an invalid BIP-32 master or child rather than
silently skipping to another path; a failed reserved allocation remains consumed.

| Role | Family/index | Credential | Child-secret interpretation |
|---|---|---|---|
| 0 | Machine | SSH client | 32-byte big-endian child scalar used as an RFC 8032 Ed25519 seed; OpenSSH `ssh-ed25519` public-key encoding |
| 1 | Same machine index | Attest sender | secp256k1 secret; Nostr BIP-340 x-only public key |
| 2 | Same machine index | Attest recipient | secp256k1 secret; Nostr BIP-340 x-only public key |
| 3 | Pass | Relay | secp256k1 secret; Nostr BIP-340 x-only public key |
| 4 | Handoff | Post-harness credential | 32-byte big-endian child scalar used as an RFC 8032 Ed25519 seed |

The Ed25519 mapping uses the child bytes as the **seed**, never as an already-expanded
Ed25519 scalar. Nostr signing follows BIP-340's parity normalization. Only raw child secrets
are passed to their authorized holders; no chain code or extended key leaves the harness.
A tenant whose handoff slot declares a credential must accept the role-4 Ed25519 identity
at its peer API before that feature can ship; a different algorithm requires a new
role/version, never reinterpretation.

The seed identifier is lowercase hex SHA-256 of the UTF-8 bytes `tau-web seed id v1`, one
zero byte, and the 64-byte BIP-39 seed. It is an integrity association inside the encrypted
store/sheet, not authentication and not an identifier sent to vendors or relays.

[`credential-vectors-v1.json`](./credential-vectors-v1.json) fixes outputs for every role
at indices 0 and 1. An implementation must also pass upstream BIP-32 leading-zero and
invalid-key vectors and RFC 8032 Ed25519 vectors. Reproducing a fixture through the same
implementation that generated it is insufficient independent validation.

## Local encryption envelope

The operator supplies a local passphrase of at least 16 Unicode code points; encourage a
password manager. Encode it as UTF-8 **without normalization or trimming**. Derive a 32-byte
wrapping key with PBKDF2-HMAC-SHA-256, 600,000 iterations and a fresh CSPRNG 16-byte salt.
This uses WebCrypto's native KDF; the work factor follows the
[OWASP PBKDF2 guidance](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#pbkdf2).
Measure unlock latency on the first-stage phone; changing the KDF requires a versioned
migration, not a silent downgrade. A weak passphrase remains vulnerable to offline guessing.

Generate a fresh 32-byte data key and 16-byte store ID. AES-256-GCM wraps the data key under
the wrapping key with a fresh random 12-byte nonce and a 128-bit tag. Persist a JSON envelope
with fields `version: 1`, `purpose: "local"`, `id`, `kdf: "PBKDF2-SHA256"`,
`iterations: 600000`, `salt`, `nonce`, `wrapped_key` (ciphertext followed by tag). Binary
fields use unpadded base64url. The authenticated additional data is exactly UTF-8
`tau-web/local/v1/` followed by the encoded ID. Reject wrong lengths, unknown fields,
unknown algorithms or versions and wrong parameters before invoking the KDF. Duplicate keys
need not be detected (the platform parser cannot); the envelope is written only by this
implementation, and any altered field fails the tag.

Encrypt each journal record and snapshot separately under the data key, using AES-256-GCM
with a fresh CSPRNG 12-byte nonce and a 128-bit tag. Bind store ID, record type, monotonically
allocated record number and the predecessor's content address in authenticated additional
data: UTF-8 `tau-web/local/v1/<id>/<type>/<number>/<previous>`; `type` is `event` or
`snapshot`, `number` is unsigned decimal without leading zeros and `previous` is the
predecessor's content address as defined below, lowercase SHA-256 hex (64 zeroes for the
first record). Record numbers share one allocator across both types.
The journal envelope carries these fields plus nonce and ciphertext/tag. Snapshots include
their replay position inside the ciphertext. Hash the complete serialized record for content
addressing; store that exact serialization instead of reconstructing it on read.

Never perform 2^32 encryptions under one data key; re-encrypt under a fresh key before that
bound. A passphrase change uses a fresh salt and nonce to rewrap the data key and commits the
replacement atomically. It does not revoke a previously copied envelope. Corruption or
authentication failure stops replay; never skip a record. This detects modification and
mixing, **not rollback of the entire store** by a compromised device. Importing a backup
therefore invokes the allocation restrictions in `STA-22b`.

Only the harness worker holds the unwrapped data/wrapping keys. Clear the passphrase and
wrapping key after unlocking; hold the data key only until lock. No local unlock material
is derived from the recoverable seed: doing so would require persisting the seed in order
to unlock itself. Credential inventory rows 18–20 cover this boundary.

## Recovery sheet

The sheet uses an independent data key, salt, nonce, ID and operator-supplied passphrase,
with the same KDF and wrapping algorithm, `purpose: "sheet"` and AAD
`tau-web/sheet/v1/<id>`. Its payload is one AES-256-GCM ciphertext with a separate fresh
nonce and AAD `tau-web/sheet/v1/<id>/payload`; only the wrapped key persists. The JSON outer
envelope adds `payload_nonce` and `payload` to the fields above. Never reuse a local-store
key or envelope as a sheet. Local and sheet purposes cannot be interchanged.

The authenticated UTF-8 JSON payload contains `version: 1`, `derivation_version: 1`,
`seed_id`, `exported_at` (UTC RFC 3339), `journal_sequence`, `next_indices` (machine/pass/
handoff), `allocations` (including consumed tombstones), `host_pins`, `exposure_ledger`,
and optional `inference_account_credential`. Each allocation has its family, index, stable
resource identity and expected public key as required by `STA-22b`; a failed allocation may
have no vendor resource ID, but retains its index. No seed or derived private key is included.
Reject unknown versions, duplicate identities/indices and malformed fields before binding
anything; imported data never creates a binding without vendor reconciliation and an
operator act. Never merge two counters and call the result proof that a backup is current.

Export asks the operator to retain both the seed backup and the separate sheet passphrase.
For maintained cloud, setup completion requires confirmation that the current sheet was
saved (`STA-15`). A stale or absent sheet may lose newer machines' metadata and relay quota.
The first stage implements local storage and derivation; sheet export/import and recovery
remain later-stage work, with these formats fixed in advance.
