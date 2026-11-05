# Credential format v1

Normative companion to `STA-22a`, `STA-22b` and `STA-23`. These are the identities and
storage formats implementations must reproduce. The dated fenced-key extension below
distinguishes newly born local keys from pre-protocol local stores; no migration is implied. The fixtures beside this document contain public test secrets, never operator data.

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

<!-- formal: TauWeb.Render.roleTable -->
| Role | Family/index | Credential | Child-secret interpretation |
|---|---|---|---|
| `0` | **machine** index | **SSH client** | 32-byte big-endian child scalar used as an RFC 8032 **Ed25519 seed**; OpenSSH `ssh-ed25519` public-key encoding |
| `1` | Same **machine** index | **Attest sender** | **secp256k1** secret; Nostr BIP-340 x-only public key |
| `2` | Same **machine** index | **Attest recipient** | **secp256k1** secret; Nostr BIP-340 x-only public key |
| `3` | **pass** | **Relay** | **secp256k1** secret; Nostr BIP-340 x-only public key |
| `4` | **handoff** | **Post-harness credential** | 32-byte big-endian child scalar used as an RFC 8032 **Ed25519 seed** |
<!-- /formal -->

The family, credential and child-secret columns of this table are carried as
`TauWeb.Allocation.row` (ADR-0032): its totality over the roles it defines is decided, and
`TauWeb.Allocation.machine_index_shared` proves that roles 0, 1 and 2 share the machine index
and roles 3 and 4 do not. The public-key encoding stays here, as prose in the last column.

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

## Allocation failure record

The local terminal proof for `STA-22b` names the allocation identity (seed identifier,
derivation version, family and consumed index), approved-entry identity and predecessor
allocation, and the checked journal prefix/sequence covering its complete local create history.
It records the writer's pre-intent, pre-handoff terminalization and its durable append, retaining
all prior mappings and associations. It is local journal evidence, never a negative vendor
receipt or a portable certificate that an imported prefix has no later sends. The sole-writer
check, sender fence and admission duties have one home in `STA-22b`.

A replacement entry admitted by `STA-22b`'s replacement act names, as its predecessor, the
retired entry's approved-entry identity and its Failed allocation. The link is carried in the
existing entry/predecessor metadata, survives export and import as that metadata does, and
supplies no authority to the retired entry or its replacement.

Derivation v1 remains unchanged; the history export amendment below versions the recovery payload. A consumed tombstone and its existing
entry/predecessor metadata survive export under the existing allocation metadata; recovering
that tombstone does not create fresh failure proof or authority. This local journal proof is
not a new mandatory recovery-payload field, and existing payloads remain readable. See
[Allocation schema 3](witness-file-v1.md#allocation-schema-3) for the separate symbolic witness
representation and its limitations.

## Local encryption envelope

The operator supplies a local passphrase of at least 16 Unicode code points; encourage a
password manager. Encode it as UTF-8 **without normalization or trimming**. Derive a 32-byte
wrapping key with PBKDF2-HMAC-SHA-256, 600,000 iterations and a fresh CSPRNG 16-byte salt.
This uses WebCrypto's native KDF; the work factor follows the
[OWASP PBKDF2 guidance](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#pbkdf2).
Unlock latency was measured at 58 ms on the first-stage phone, in an Android WebView rather
than the Chrome tab `OVR-1` names — the same WebCrypto, not yet the same host
([findings, 2026-09-11](../findings/2026-09-11-unlock-latency.md)); changing the KDF requires
a versioned migration, not a silent downgrade. A weak passphrase remains vulnerable to offline guessing.

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
authentication failure stops replay; never skip a record. A disposition that `STA-24`'s test
refuses is not a skipped record: it stays in the journal and is replayed, ends no call,
restricts nothing and is shown. This detects modification and
mixing, **not rollback of the entire store** by a compromised device. Importing a backup
therefore invokes the allocation restrictions in `STA-22b`.

Only the harness worker holds the unwrapped data/wrapping keys. Clear the passphrase and
wrapping key after unlocking; hold the data key only until lock. No local unlock material
is derived from the recoverable seed: doing so would require persisting the seed in order
to unlock itself. Credential inventory rows 18–20 cover this boundary.

## Session journal format 2

This journal version is distinct from derivation v1, local wrapping envelope v1/v2, sheet
envelope v1, recovery payload v5 and every witness schema. New event/snapshot plaintext
wrappers have `journal_version:2`, authenticated by their existing encrypted record. A
pre-End wrapper (absent version or journal version 1) retains its original validation and
replays all its sessions as ended. A version-2 suffix can follow that validated prefix without
rewriting old ciphertext: only admissions in the suffix can start a live session. Reject an
unknown journal version or a version-1 record after a version-2 suffix. Snapshots retain the
version boundary, admitted session identities, durable Ends, approvals and binding history;
they cannot promote prefix sessions to live authority.

The only new event kind is `end`, with session identity and one reason from `explicit`,
`replace`, `expiry`, `cap_exhaustion`, `abandon`. End is irreversible, including for a
not-currently-running session; an idempotent repeat cannot revive it. The existing admission
approval remains `STA-3`'s. The existing mint terminal gains a private paid-key member inside
its encrypted record, associated with the original session/account/choice/mint identity and
issuer-validated terminal; its eligibility and loss hold are `ARC-31a`'s. In the format-2 wrapper of that existing mint-terminal event, `evidence` retains the
unchanged protected terminal object and optional `paid_key` holds the private procured key
only with its successful validated terminal. It is encrypted once as part of that record,
never another public evidence field. Every original closed-object and refusal check applies
to `evidence`; the key member is absent from projections and imports supply no usability.
No separate seal or resume event kind is added. Staged append recovery, nonce uniqueness, combined encryption
attempt budget, canonical chain bytes and record/snapshot AAD remain unchanged. Invalid
terminal evidence, a missing terminal or a seal alone supplies no usable key.

Import is a separate history-only operation under `STA-16`, even for a format-2 backup.
A copied paid-key seal never becomes usable through import and import revokes no old-phone key.

## Fenced local-key birth extension, 2026-10-28

Fresh local-store creation uses an envelope with the same exact fields, types, binary
lengths, KDF and wrapping algorithm as the local envelope above, except `version:2` and
wrapping AAD exactly `tau-web/local/v2/<id>`. This authenticated distinction certifies the
private constructor's fresh data-key birth under the attempt-counting protocol in
[Protected browser evidence v1](protected-evidence-v1.md#5-scan-reservations-and-attempt-fences).
The constructor generates a new data key, commits this envelope, and performs no data-key
AEAD before that commit; every later data-key AEAD follows that protocol, including the
first seed append. A v1 key is never upgraded or rewrapped into v2. A passphrase rewrap
preserves the version and its AAD. Unknown versions fail before the KDF. No extra field is
accepted in either version. The distinction remains authenticated even with no seed record.

RecordJson, record/snapshot AAD under `tau-web/local/v1/`, canonical chain bytes, nonce
generation, derivation and sheet v1 envelopes remain unchanged. V1 local envelopes remain
readable with their original AAD but carry no provable remaining encryption budget; their
nonempty prefix is read-only, and a seedless v1 envelope is operationally refused. Exact
recovery/eligibility transitions and the combined journal/scan/attempt bound are owned by
the linked protocol. No records or old keys are silently migrated. Old local bytes stay
unchanged; an old binary rejects a v2 local envelope. For the extension's known-answer
demonstrations, see `CNF-82` in `07-conformance.md`.

## Recovery sheet

The sheet uses an independent data key, salt, nonce, ID and operator-supplied passphrase,
with the same KDF and wrapping algorithm, `purpose: "sheet"` and AAD
`tau-web/sheet/v1/<id>`. Its payload is one AES-256-GCM ciphertext with a separate fresh
nonce and AAD `tau-web/sheet/v1/<id>/payload`; only the wrapped key persists. The JSON outer
envelope adds `payload_nonce` and `payload` to the fields above. Never reuse a local-store
key or envelope as a sheet. Local and sheet purposes cannot be interchanged.

New exports use an authenticated UTF-8 JSON payload containing `version: 7` (below),
`derivation_version: 1`, `seed_id`, `exported_at` (UTC RFC 3339), `journal_sequence`,
`next_indices` (machine/pass/handoff), `seed_backup`, `allocations` (including consumed
tombstones), `retired_allocations`, `host_pins`,
`host_pin_installations`, `relay_discovery`, `exposure_ledger`, `artifact_history`,
`placements: [{seed_id, machine_index, application_name, name, path, placed_at, report}]`, `machine_states`,
and optional
`inference_account_credential`. Each allocation has its family, index, stable
resource identity and expected public key as required by `STA-22b`, and a jump host's entry
carries `jump_host: true`, recording that it is in no session's bound set, and no other
allocation carries the field; a failed allocation may
have no vendor resource ID, but retains its index. No seed or derived private key is included.

In payload version 4, a pass allocation's resource identity is the member `relay_locator`, exactly
one of `{"publisher":"<P>"}` and `{"url":"<R>"}`. For P's encoding and R's contact admission,
see `CHN-19`. The allocation's expected public key remains the holder's derived relay key. Reject
unknown locator tags, extra members, both alternatives, missing values and wrong types; never
infer an alternative from a URL. For direct-locator recording and correction, see `CHN-19`.

Version 4 also requires `relay_discovery`, an array of `{"publisher":"<P>","event":<complete
signed WIR-14 event>}` records, or `[]` if none are known. At most one record is permitted per P.
For the event format, see [paid-tcp-relay][relay-source] `WIR-14`.
Validate each signed event's NIP-01 id, BIP-340 signature, key association with the record's P,
and complete WIR-14 schema before merging it under `CHN-19`. For retained-event ordering and
route usability, see `CHN-19`. Reject malformed or duplicate records before binding.
Imported starting URLs never replace the compiled discovery set B.

Version 3 is accepted only by an explicit compatibility conversion that preserves every other
version-3 field and its validation, wraps each recorded relay URL as `{"url":R}`, and supplies
`relay_discovery:[]`. Never infer publisher identity from URL equality. Versions 4 to 7 use
only the typed locator. Unknown payload versions and versions 1 and 2 remain unsupported. For
publisher-key mismatch and migration, see `CHN-19`.
This compatibility conversion changes neither the v1 encryption envelope nor derivation version 1,
AAD, algorithms or known-answer vectors.

### Actual artifact history, payload version 5

`artifact_history` is a required array with exactly one entry per non-jump machine, including
retained destroyed-machine records: `{machine_index, known_unpinned, legacy}`.
`known_unpinned` contains distinct increasing installation ordinals. Artifact history is
independent of host-pin group creation: ordinal zero can record an actual initial
installation/order dispatch before any publication, job-read or attest opens pin group zero.
A later ordinal must follow an actual reinstall boundary; no ordinal is created by acceptance.
`known_unpinned` records actual dispatched unpinned installations, never acceptance alone.
`legacy` is exactly `"none"`, `"unpinned"` or `"unknown"`: what conversion from an older
payload established about installations it recorded no ordinal for, and `"none"` on every
entry a version-5 export creates; `"none"` records only that no conversion line below applied
and asserts no clean past. An empty `known_unpinned` is explicit `[]`. Current unpinned status requires
its current ordinal in `known_unpinned`; pinned present erases neither field. Reject missing,
duplicate, out-of-range or malformed entries before binding; the allowed initial zero with no
pin group is not out of range. Preserve both fields on subsequent exports and migration to a
new machine index; do not infer observations or pins from them. Their display belongs to
`STA-16`.

Validate version 3 under its original rules before its explicit locator conversion above,
and version 4 under all its original rules, before converting either to version 5 in memory.
A machine's own recorded `installation` value keeps its meaning: a current `"unpinned"`
installation is a known unpinned ordinal. An older payload's unpinned-installation label stands
on the machine's bound set, not on a machine. That set is the one the exported exposure ledger's
latest entry for the labelled machine records (`STA-10`: an entry "records the set that machine
was bound in"), including any retained destroyed machine that entry names. When that label
stands on a bound set of more than one machine, each machine of the set restores with `legacy:"unknown"`: history unknown, shown
and restated at binding as `SEC-14` requires of installation history, and never unpinned or
clean history for any of them. When the set has one machine, the history belongs to that
machine: `legacy:"unpinned"`. Every other converted entry has `legacy:"none"`. Absent required
data never becomes empty history: conversion creates no group, ordinal, observation or pin,
and current unpinned status with no pin group preserves the actual initial ordinal zero with
`host_pin_installations:[]` and `host_pins:[]` unchanged.

The v3-to-v4 conversion remains exactly the locator conversion above. The v4-to-v5 history
conversion changes no allocation, pin, observation, application, placement or seed-backup
validation. Versions 1, 2 and unknown versions are still refused. New exports always retain
the v5 history, even after a pinned successor. Sheet envelope v1, derivation v1, algorithms,
AAD and known-answer vectors stay unchanged.

### Partial history, payload version 6

Version 6 keeps every version-5 rule for every machine without a partial history, and adds the
partial history `STA-16` requires: "A machine whose installation ordinal was accepted as a
proposal in `STA-17`'s rescue rekey has a partial history, and export and Restore MUST
round-trip it". It carries the accepted ordinal with its acceptance basis, the earlier
installations it holds no facts for marked unknown, and the facts retained below the accepted
ordinal. Import reconstructs that
partial history from the payload alone, without the journal. The unknown never becomes
`legacy:"none"`, a known unpinned or pinned installation, an empty `known_unpinned` or empty
history, and missing or invalid partial history is refused before binding. Validation of
versions 3, 4 and 5 is unchanged, including the refusal of a duplicate or skipped installation
ordinal below. Version 6 carries no representation for a recovery sheet found later. Its member
names, the encoding of its gaps, whether the per-machine `installation` value needs an explicit
unknown, what that machine's `legacy` and `known_unpinned` members hold, and how the
ordinal-continuity rules apply to that machine are not yet specified. A new export writes
version 7 (below), never version 6.

### Operator reports, payload version 7

Every new export writes version 7. Version 7 keeps every version-6 rule and adds two required
members, `report` and `seed_id`, to every placement record, and one required payload member,
`retired_allocations`. It inherits no wire from version 6 for the partial
history: those member names and encodings, not yet specified above, are equally unspecified for
version 7.

`report` is exactly the string `"none"` or an object with exactly the member
`operator_reported_at`, a UTC RFC 3339 time. The object records that the operator reported this
one placement's key revoked at its service (`ARC-43`), at the time the journal recorded the
report. `"none"` records that no report was recorded for the placement as of export; it asserts
no clean past: not that the value was never lost, copied or disclosed, nor that it is still valid
at its service. `operator_reported_at` labels history and classifies no output: which output a
report ends that placement's scan for follows journal dispatch order (`SEC-5`), never this time
or a machine-reported time. It is protected and non-secret: an operator-act time, never
secret-derived data, and no value, digest, scan key, byte length or other value-derived
reference accompanies it. Reject a missing `report`, `null`, any other string, an object with a
missing, extra or duplicate member, and a malformed time before binding. Reject too a version-7
placement record with a missing member or any member other than its seven.

A placement without a report is live: the export writes it until its secret is rotated or its
machine is destroyed (`SEC-5` row 12). Rotation replaces its record with the rotation's new
placement, and its machine's destruction removes it from every later export. What keeps output
withheld for such an ended placement after a Restore from a later sheet is not yet specified.

A placement with a report is ended. Its record stays in `placements` on every later export,
after its secret is rotated and after its machine is destroyed (at LNVPS, the vendor's confirmed
deletion); the rotation's new placement is a separate record beside it. Re-arming, the
required-reference wait, the trust display's live listing and a restored provider's listing
read only placements without a report (`ARC-43`, `STA-16`).

A placement record's `seed_id` and `machine_index` together name its machine. `seed_id` has the
form of the payload's `seed_id`. It equals the payload's for a machine allocated under the
current seed, named in `allocations`. It names a retired seed for a destroyed machine allocated
under it, named in `retired_allocations` (below). Replace's migration moves a placement's
`machine_index` with its machine and sets its `seed_id` to the fresh seed's (`STA-17`), a
reported record's included. Replace does not migrate a destroyed machine, so a reported record
on one keeps its `seed_id` and `machine_index`, and the new seed's sheet carries that machine as
a retired allocation. A retired-seed index can coincide with a current machine's index
(`STG-20`), and the seed tells them apart. Only a placement record names a retired allocation.
How artifact history, host pins, installation groups and exposure-ledger entries name a machine
allocated under a retired seed is not yet specified, and neither is what the new seed's sheet
holds for a live machine that Replace leaves unmigrated.

`retired_allocations` is a required array, `[]` when empty. Each entry is the journal's
retired-seed machine entry: its `seed_id`, family `machine`, index, stable resource identity
and recorded expected public key as `STA-22b` maps them, and `destroyed: true`. The exporter
copies that entry unchanged from the journal and writes it exactly while a written reported
record names it, keeping its seed through every later Replace. Import checks each entry's form.
It checks that `seed_id` differs from the payload's, that `destroyed` is `true`, and that a
placement record names the entry. Seed, family and index must be unique among retired
allocations. Import accepts the recorded public key without deriving it from any seed, the one
exception to `STA-22b`'s derive-and-compare check. A retired allocation is outside
`allocations`, so that member's derivation, unique-index and next-unused-counter checks stay as
they are for every current-seed allocation. A retired allocation restores no contact identity,
host pin, binding or session, allows no allocation, takes part in no vendor reconciliation and
has no `machine_states` entry. Reject a missing or malformed entry, a duplicate, an entry with
the payload's seed, a non-machine family, `destroyed` absent or other than `true`, an extra
member and an entry no placement record names before binding.

Two placement records are duplicates when they are equal in the six members `seed_id`,
`machine_index`, `application_name`, `name`, `path` and `placed_at`, whatever `report` holds.
`ARC-43` records a later placement's time after every earlier record's at its machine,
application name, secret name and path, so a reported record and a later placement there are
never duplicates.
Reject duplicates and two records without a report at one machine, application name, secret
name and path. Also reject before binding a record whose `seed_id` is malformed or names
neither the payload's seed nor a retired allocation's, and a record without a report naming a
retired allocation. Reject too a reported record on an absent, failed, jump-host or non-machine
allocation, where absent means no allocation at that seed and index.
A machine allocation whose deletion evidence `SEC-5` admits and the journal durably records
carries `destroyed: true`, as every retired allocation does, and no other allocation carries the
field. A stop, a passed deletion date, a reinstall or a disposition does not set it, and such a
machine stays live here. Reject the field with any other value or on any other allocation. A destroyed allocation has no
`machine_states` entry (below).

A reported record whose machine is live satisfies the application association below as any
placement does. A reported record whose allocation carries `destroyed: true` is checked by form
only: its `application_name` must satisfy the application-name rule below, and it is matched
against no list, since its machine has no `applications` array. It is the only placement for
which the refusal of a placement naming no application on its machine is narrowed. The exporter
copies such a record unchanged from the journal's report and placement records, never from a
reconstructed or renamed application. The sheet keeps no list of a destroyed machine's
applications or providers, and a Restore lists no provider for such a record. Reject a record
without a report on a destroyed allocation before binding.

Validate versions 3 to 6 under their own rules, then convert to version 7 in memory by giving
every placement `report:"none"` and the payload's `seed_id`, and supplying
`retired_allocations:[]`. The conversion invents no report and no retired allocation: an older sheet restores each
placement's as-of-export wait (`STA-16`). A reader that predates version 7 refuses a version-7
sheet as an unknown version. Versions 1 and 2 and unknown versions stay refused. Sheet envelope
v1, derivation v1, algorithms, AAD and known-answer vectors stay unchanged.

Each `host_pins` entry names the host-key route that produced it: `retrieve` (`CHN-R1`),
`attest` (`CHN-R5`), `jump_host` (`CHN-R6`) or `lnvps_retrieve` (`CHN-R7`). The last
value records the retrieved LNVPS hypervisor-scan provenance and is restored with the pin;
it does not authorize a new first contact. Import MUST refuse a missing, unknown or malformed
route value before binding, as it does other malformed payload fields. Each installed-system
pin also carries its `installation` ordinal, starting at zero for that machine; a rescue
pin remains scoped by its rescue boot. Whether the installation
carries an artifact pin is a different fact, carried per machine below. Each `machine_states` entry is
`{machine_index, declaration, class, access_model, installation, weaker_modes, applications}`: the journaled
declaration in force as a delivery-declaration version 2 document, the class `ARC-36a` records, the
access model of `ARC-27`, `installation` as `"pinned"`, `"unpinned"` (`ARC-25`) or
`"not_installed"` before any installation, and the labels of the acceptable weaker modes standing
on the machine's bound set (`SEC-14`). A field not yet approved at export carries the explicit
marker `"unapproved"`, never an absent field; `installation` and `applications` are recorded,
not approved. Every live machine other than a jump host has exactly one entry, bound to a session or not; an
allocation marked `jump_host: true` (`STA-22b`) or, in version 7, `destroyed: true` has none,
nor does a retired allocation.
Reject a missing, duplicate or malformed entry and an entry for a jump host or a destroyed
allocation; never interpret a missing entry or an
`"unapproved"` field as a default.

`host_pin_installations` is a required array of installation groups in creation order.
Each group is `{machine_index, installation, observations}`. The ordinal starts at zero
per machine and increases by one only on an operator-chosen destructive reinstall, through
the vendor API or from rescue. Replace's migration carries that ordinal to the machine's
new index (`STA-17`); it does not restart at zero. `observations` is an array
in recording order; each observation is `{keys: [...]}`, whose elements are
`{family, fingerprint}`. `family` is exactly `ed25519`, `rsa` or `ecdsa`, at most once per
observation; `fingerprint` uses the host-pin fingerprint format. An empty reading that opens
the initial group appears as an empty `keys` array. Any installation's group may have
`observations: []`, including the initial group opened by a job-read or attest pin without a
publication. A reinstall group with no newly observed fingerprint also has
`observations: []` and must remain distinct from every earlier group; its
first empty reading adds no observation. Within a group,
record a subsequent observation only if it adds a fingerprint absent from that group's
accumulated knowledge; exact, reordered, empty, and subset repeats add no record. Include
incomplete readings and refused complete candidates that add knowledge. Do not reconstruct
observations from admitted `host_pins`.

The latest group for a machine is its current installation. An installed pin with that
group's ordinal is active; pins from earlier groups are retired. At most one installed pin
may be recorded per machine and installation. A group may have no installed pin, including
immediately after reinstall. Route provenance remains the `host_pins` route field and is
independent of the installation's artifact-pin status in `machine_states`.
`host_pin_installations` and `host_pins` are explicitly `[]` when empty. A historical attest pin records that its introduction was
consumed; import reconstructs that consumed state even when the pin is retired. Before
binding, import MUST refuse a missing array, malformed
group or observation, repeated family within one observation, a redundant observation,
duplicate or skipped installation ordinal, a pin referencing a missing group, a second
installed pin in one group, or a reference to an absent or non-machine allocation.
For an `lnvps_retrieve` pin, import MUST verify that its own keys form a complete
Ed25519/RSA/ECDSA set, share no fingerprint with any earlier installation group's
observations or installed-system pin of any source for that machine, and equal the
accumulated distinct family/fingerprint facts at some
prefix of its installation group's recorded observations. A complete candidate may
add no fact after separate partial observations, so no complete observation is
required in the group. Later refused observations may add facts after that prefix;
they remain recorded and MUST NOT invalidate an already admitted pin. Missing
or invalid history MUST NOT become empty history. `STA-16` owns what Restore does with
these facts. These fields remain required in payload version 4 and later and in the version-3
compatibility input; the envelope and derivation are unchanged.

`applications` is a required JSON array of objects, each with exactly the required members
`name` and `model_provider`. `name` is a nonempty string without leading or trailing
whitespace, where whitespace is a character with Unicode's `White_Space` property.
`model_provider` is either an object with exactly `name`, a nonempty string under the same
whitespace rule naming the application's model provider as the machine's application records
hold it (`TRU-E12`), or the exact
string `"no_model"` for an application without its own model. No applications is exactly `[]`.
For example, `[{"name":"Application A","model_provider":{"name":"Provider A"}},
{"name":"Application B","model_provider":"no_model"}]` records both cases. The exporter uses
the application and provider names as the machine's application records hold them. Application
names are unique within each machine by exact string equality (`ARC-1a`); another machine
may use the same name. Reject repeated application names on one machine before binding whether
their providers agree or differ. Do not case-fold, normalize or generate application
identifiers. Reject
absent fields or required members, duplicate JSON object member names anywhere in the
payload, extra application/provider members, nulls,
wrong types, empty or whitespace-padded names, and any other marker, including `"unapproved"`, before binding.
Neither absence nor malformed data is interpreted as `[]` or `"no_model"`. These records
contain only application and provider names, never secret-derived data. Export and restored
display are governed by `STA-16`.

Each placement associates a machine-family allocation, named in version 7 by its `seed_id` and
`machine_index`, with `application_name`, the exact name
of an application in that machine's `applications` array, and separately with `name`, the
nonempty secret name, recorded path and UTC RFC 3339 placement time. `application_name` is a
required nonempty string under the application-name whitespace rule above. Reject a missing or
malformed `application_name`, one naming no application on that same machine, missing or
ambiguous machine associations, duplicate placement records (version 7 above defines them),
duplicate JSON object member names in a placement and malformed fields before binding.
An application recorded only on another machine cannot satisfy the reference. The one exception
is version 7's reported record on a destroyed allocation (above), whose `application_name` is
checked by form only. No placement
value, digest, scan key, byte length or other value-derived reference is included. Payload
versions 1 and 2 and unknown payload versions are unsupported: refuse them explicitly. Version 3
has only the explicit compatibility conversion above, and missing placement or application lists
are never interpreted as empty. Payload versions 4 to 7 change neither the v1 envelope,
derivation paths, algorithms, AAD nor known-answer vectors.
Reject unknown versions, duplicate identities/indices and malformed fields before binding
anything; imported data never creates a binding without vendor reconciliation and an
operator act. Never merge two counters and call the result proof that a backup is current.

`seed_backup` is always present: the string `"none"`, or the object
`{"seed_id": "<payload seed_id>", "completion": "full_reentry"}` with completion either
`"full_reentry"` or `"skipped"`. It copies the journal's ceremony record for this seed id
(`STA-23`); the explicit marker means no record exists. Import MUST refuse before binding a
missing, malformed or duplicate record, duplicate object members, an unknown completion,
or a seed id different from the payload's. Restore brings it back into the journal; an
imported seed owes no ceremony and allocates nothing regardless of this record (`STA-22b`).
Replace clears it for the fresh seed. This member remains required in payload version 4 and later and the
version-3 compatibility input; the envelope and derivation stay unchanged.

Export asks the operator to retain both the seed backup and the separate sheet passphrase.
For maintained cloud, setup completion requires confirmation that the current sheet was
saved (`STA-15`). A stale or absent sheet may lose newer machines' metadata and relay quota.
The dedicated test bed covers local storage and derivation. The LNVPS path also requires export,
Restore and Replace for maintained cloud; `CNF-20`'s relabel cases, Robot rescue and paid/public
signed relay revocation follow their own rows in `07-conformance.md`'s applicability
table. These are required implementation demonstrations, not claims that this specification
has run them.

[relay-source]: https://github.com/douglaz/paid-tcp-relay/tree/49309df54dea3841f3cb1a37527f8d4ec9b5f1ab
