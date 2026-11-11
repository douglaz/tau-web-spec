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
retired entry's approved-entry identity and its Failed allocation. On the
[recovery sheet](#recovery-sheet) the link is the replacement's `predecessor` member, matched to
its Failed target's `entry` member; it survives export and import with them and supplies no
authority to the retired entry or its replacement.

The rescue rekey's wrong-server record (`STA-17`) survives export and import with its entry and
restores no authority to that entry. Which member of the entry's allocation metadata carries it,
under which payload version, is not decided.

Derivation v1 remains unchanged; the history export amendment below versions the recovery payload. A consumed tombstone survives export as its
allocation with `failed: true` and its `entry` and `predecessor` members; recovering
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
envelope v1, recovery payload versions and every witness schema. Every event and snapshot plaintext
wrapper has `journal_version:2`, authenticated by its existing encrypted record. The version
member loosens no check: the wrapped event or snapshot keeps every closed-object and refusal
check it has without it. Snapshots retain admitted session identities, durable Ends,
approvals and binding history.

**An earlier journal is refused, not read**
([ADR-0072](../adr/0072-an-earlier-session-journal-is-refused-not-replayed.md)). At open,
before replay, a journal holding any record that is not format 2 is refused as a whole: an
earlier wrapper (absent version or journal version 1) or an unknown journal version, on an
event or a snapshot, as the first record or after format-2 records. Nothing is projected or
appended, no session is admitted or resumes, and the stored bytes stay unchanged. The refusal
never deletes, creates, resets or overwrites a store, and nothing offers to do so in one step.
Its message tells an earlier format apart from an unknown version and from corruption (a
record that fails authentication or decoding, which stops replay as above), and says that
the data was left unchanged. It also warns that clearing the store permanently deletes it,
seed record included, without prescribing clearing: the choice is the operator's, and what
survives clearing is what survives a lost phone (`STA-14`).

This refusal comes before any replay or report and reads only the journal version. The local
envelope rules below decide whether a data key unwraps and may encrypt, and stay as written:
a store under either envelope version is refused here when one of its records is not format 2,
and their protected read-only reading applies only to a store whose records are all format 2.
Evidence payload shapes inside a format-2 record, and the recovery sheet and export payloads,
keep their own versions and old-data rules.

The session End event kind is `end`, with session identity and one reason from `explicit`,
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

Import is a separate history-only operation under `STA-16`. A local-store backup's journal is
read under the rule above, so a backup holding a record that is not format 2 is refused at
import the same way and imports nothing.
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

Exports use an authenticated UTF-8 JSON payload containing `version: 8` (below),
`derivation_version: 1`, `seed_id`, `exported_at` (UTC RFC 3339), `journal_sequence`,
`next_indices` (machine/pass/handoff), `seed_backup`, `allocations` (including consumed
tombstones), `retired_allocations`, `host_pins`,
`host_pin_installations`, `relay_discovery`, `exposure_ledger`, `artifact_history`,
`placements: [{seed_id, machine_index, application_name, name, path, placed_at, report, report_events, independent_end}]`, `machine_states`,
and optional
`inference_account_credential`. Each allocation has its family, index, stable
resource identity and expected public key as required by `STA-22b`, and a jump host's entry
carries `jump_host: true`, recording that it is in no session's bound set, and no other
allocation carries the field; a failed allocation may
have no vendor resource ID, but retains its index, and a machine allocation carries `failed: true`
and the `entry` and `predecessor` members as version 8 states below. No seed or derived private
key is included.

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
`relay_discovery:[]`. Never infer publisher identity from URL equality. Versions 4 to 8 use
only the typed locator. Unknown payload versions and versions 1 and 2 remain unsupported. For
publisher-key mismatch and migration, see `CHN-19`.
This compatibility conversion changes neither the v1 encryption envelope nor derivation version 1,
AAD, algorithms or known-answer vectors.

### Actual artifact history, payload version 5

`artifact_history` is a required array with exactly one entry per non-jump machine, including
retained destroyed-machine records: `{machine_index, known_unpinned, legacy}`, and in version 7
also `seed_id` ([version 7](#operator-reports-payload-version-7)). Neither a Failed allocation
nor, in version 7, a reserved migration index is a machine with an entry.
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
version 8 (below), never version 6.

### Operator reports, payload version 7

Version 7 keeps every version-6 rule and adds two required
members, `report` and `seed_id`, to every placement record, a required `seed_id` to every other
record that names a machine (below), a required `reference_ended` to every `machine_states`
entry (below), and one required payload member, `retired_allocations`. It
inherits no wire from version 6 for the partial
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
placement record with a missing member or any member beyond its identity members and `report`
as listed above without the version-8 additions. Version 7 accepts no correction evidence.

A first placement enters the export from the approved record made before its bytes leave,
even if its job exits nonzero, stays unresolved or is disposed. Its record asserts possible
exposure, not successful placement. For which later placements are rotations at that
destination, see `ARC-43`; a rotation's new placement follows the export timing below.
A placement without a report is live: the export writes it until its secret is rotated or its
machine is destroyed (`SEC-5` row 12). Its secret is rotated when `SEC-5` records the rotation
([ADR-0063](../adr/0063-a-rotation-is-recorded-by-its-zero-exit-job-record.md)); the recorded
rotation replaces its record with the rotation's new placement. Its machine's destruction removes
it from every later export. The retained disposed first placement below qualifies that
replacement: its otherwise exportable successor waits until that first placement ends.
After a Restore
from a later sheet, its older output stays withheld through the `reference_ended` mark its end
sets on the `machine_states` entry of each live machine the exposure ledger records in a bound
set with its machine (below).

In version 7, a placement with a report is ended. Its record stays in `placements` on every later export,
after its secret is rotated and after its machine is destroyed (at LNVPS, the vendor's confirmed
deletion); the rotation's new placement is a separate record beside it. Re-arming, the
required-reference wait, the trust display's live listing and a restored provider's listing
read only placements without a report. Version 8 below qualifies this for corrected reports
(`ARC-43`, `STA-16`).

A rotation's new placement enters the export only once `SEC-5` records the rotation, whether or
not the rotated placement has a report: a sheet exported before then holds the rotated placement
as it was and no record for the new one, and a rotation that is never recorded leaves its new
placement on no sheet. Otherwise a rotated placement without a report and its new one, or the new
placements of two attempts at one rotation, would be two records without a report at one machine, application name, secret name
and path, which the importer rejects (below).
For a first placement whose completed root-only job record was admitted before the later
rotation's pre-send record, the recorded rotation replaces that first placement's
unreported sheet record. Where the disposed-placement exception in `SEC-5` retains an
unreported first placement, the sheet keeps that first placement's record and writes none
for any later unreported successor until the first placement ends. This applies through
successive recorded rotations even when one ends a completed successor: the retained first
placement still occupies the sheet position. The general replacement sentence above
is qualified by this case. A completed record admitted after a successor's pre-send
does not by itself end the first placement or free its sheet position. The successor
remains listed and required locally; a sheet exported even after its successful job can
omit that known placement. A Restore from such a sheet restores the first placement only,
owing its re-arm from the recorded path's current bytes, and recovers neither the omitted
successor's identity nor separate references for both historical values. This limitation
includes placements already known before export, not just secrets placed since export;
for the remaining after-Restore labels and coverage treatment, see `STA-16`. Once the
first placement ends, an otherwise exportable successor still live and known locally can enter a
later sheet under the ordinary live-placement, reported-history and destruction rules;
ending the first placement never revives an ended successor or exports a destroyed machine's
unreported successor.
No sheet writes two records without a report at that destination. The first placement's
own pre-send export start is unchanged.

### Report corrections, payload version 8

Every export writes version 8. It preserves version 7's `report` unchanged and adds required
placement members `report_events` and `independent_end`, and on machine entries the members
`entry` and `predecessor` (below). Every other version-7 field and
validation remains, including its unspecified partial-history encoding; this extension defines
no further partial-history machinery. A placement record has exactly the identity members
`seed_id`, `machine_index`, `application_name`, `name`, `path`, `placed_at`, and the members
`report`, `report_events`, `independent_end`.

`report_events` is an array, `[]` when empty. When `report` is an object, that object remains
the original report and timestamp forever. Subsequent facts are appended in journal order:
an object with exactly `operator_corrected_at`, then optionally an object with exactly
`operator_reported_at`, alternating thereafter. Each value is a UTC RFC 3339 time. The first
event must be a correction of the original report, each correction names the immediately
preceding unmatched report, and each later report follows a correction. A placement with
`report:"none"` has `report_events:[]`. Neither a correction nor a later report overwrites the
original `report`. Array order, not clock order, records the sequence; times label the intervals
from each report to its correction, or the open interval after the last uncorrected report.
They classify no output and prove no external revocation or reversal. The report is uncorrected
when its object has no later correction, or the final event is a later report. When the final
event is a correction and `independent_end` is `"none"`, the placement's future reference is
required, unarmed after Restore; the live/provider display follows `ARC-43`, `SEC-6` and
`TRU-E12`. Its original report still supplies `SEC-5`'s pre-loss withholding.

`independent_end` is exactly `"none"`, `"rotation"`, `"destruction"` or `"unknown"`. It records
the first independently recorded end, separately from the report facts: the rotation act that
actually ends this placement under `SEC-5`, or the admitted, durably recorded deletion evidence
of its machine. A later destruction does not erase an already recorded rotation. `"none"`
means the retained history establishes no independent end through export. `"unknown"` records
only the older-data conversion below; it is not permission to correct. Correction requires
`"none"` at its append. No correction is appended after an independent end, and an independent
end after correction leaves the report/events unchanged and ends the restored reference.
A history with an independent end restores no live placement, wait, re-arm or provider listing,
even when its final report event is a correction. An unknown end with an uncorrected report
also restores history only, and supplies no correction eligibility; the display says its
independent-end history is unavailable. Only retained journal evidence establishing eligibility
can supply it, never a missing file, current machine report or operator assertion of no end.

Every reported record stays on all later exports, with its report/events and independent-end
state, after rotation and destruction. The rotation's successor is separate, under the existing
export timing and retained-first-placement omission rules above. Unreported placements retain
those rules unchanged and have `report_events:[]` and `independent_end:"none"` while exported.
An independent end removes an unreported record as before. A reported record sets no
`reference_ended` mark at correction or independent end: the retained original report already
carries its older-output withholding, including after correction. A mark set by any unreported
placement's end is never cleared by correction or re-arm.

Reject before binding a missing field, wrong type, unknown marker, malformed time, extra or
duplicate member, nonalternating events, events without an original report, or an unreported
record with an independent end. Reject `"unknown"` with any correction evidence. On a destroyed
allocation, a reported record must have `"rotation"` or `"destruction"`, never `"none"` or
`"unknown"`; its application name is checked by form only, as in version 7. No correction
revives that allocation or supplies an application/provider list for it. A live allocation
cannot carry `"destruction"`. A live machine with a rotated reported record still owes the
same application association as any reported record on a live machine. Report history is
copied unchanged from the journal, including when migration renames the machine's seed/index.

Duplicate identity is still equality of `seed_id`, `machine_index`, `application_name`, `name`,
`path`, `placed_at`, regardless of `report`, events or end state. Reject duplicates even if
their histories differ; never merge them into correction evidence. The destination refusal of
two records with `report:"none"` at one machine, application, secret name and path remains.
It does not reject corrected reported records beside another placement there: each has its
own identity, history and required-reference state. No correction invents a later placement or
permits an unrelated-file overwrite. All allocation, seed and application association refusals
below still apply.

Validate versions 3 to 7 under their own rules before conversion; version 7 still accepts only
its original placement shape. Perform the earlier explicit conversions unchanged, then supply
`report_events:[]`. Supply `independent_end:"none"` for an unreported placement,
`"destruction"` for a reported record on a destroyed allocation, and `"unknown"` for a
reported record on a live allocation: version 7 did not encode whether that retained record
was independently rotated. For a reported record converted from version 7, including on its
later exports and after a subsequent destruction replaces its `"unknown"`, `"destruction"`
records the known destruction of its allocation, not that no rotation preceded it: version 7
did not encode that order. Conversion invents no correction and cannot establish that such a
reported record is eligible for one. Preserve the unknown on later exports unless retained
journal evidence establishes its end state or a subsequent independent end is recorded.
A sheet before a correction restores only the facts it actually holds, including its
uncorrected report and as-of-export limits. A reader predating version 8 refuses it as an
unknown payload; do not down-convert corrected history to version 7 or drop it. Versions 1 and
2 and unknown payload versions remain refused.

The local correction event has exactly `report_correction_version:1`, `placement` (the exact
identity members listed above), `report_ordinal` (a positive integer: the original report is
ordinal 1, followed by later reports in array order), and `operator_corrected_at` (UTC RFC
3339). The append corrects only that currently uncorrected report; `ARC-43` owns eligibility
and the durable boundary. Subsequent report acts retain the same placement identity and
append their time to `report_events`, never clear `report`. A snapshot containing correction
evidence carries `report_correction_version:1` alongside its retained original report,
ordered follow-up facts and independent-end state. Replay of an incremental correction event
applies the same eligibility test at that event's recorded boundary. Loading a sheet or
snapshot projects its final state: it does not re-execute an earlier correction against an
end that occurred afterward. Ends derive only from admitted rotation/destruction records or
imported end facts. Invalid association or ordinal, nonalternating facts, missing/unknown
correction evidence version, extra/duplicate members or malformed correction encoding stops
replay as a decoding failure; it never skips a record or clears a report. Earlier journal
evidence and snapshots with no correction evidence supply no correction; project their ends
from the admitted records they actually retain, preserving any imported unknown. Failed
appends supply no fact or state change. The evidence extension changes neither
`journal_version:2` nor the journal's encryption envelope, AAD, chain, attempt fences or
session authority.

All report/correction/end data is protected, non-secret metadata. Export no raw application
value, bare digest, scan key, byte length or other secret-derived scan material. Sheet envelope
v1, derivation v1, local envelopes and all witness versions remain separate and unchanged.

In version 7 a machine is named by a seed and a machine index together, and every record that
names a machine carries both: a placement record its `seed_id` and `machine_index`; each
`artifact_history`, `machine_states` and `host_pins` entry and each `host_pin_installations`
group a `seed_id` beside the machine index naming its allocation; and each `exposure_ledger`
entry a `seed_id` beside every machine index it holds, for its own machine and for each machine
of the bound set it records (`STA-10`). This document fixes no other part of a ledger entry's
layout, and no machine reference in it is a bare index. Each such `seed_id` is required and has
the form of the payload's `seed_id`; none defaults to the payload's seed. A name whose `seed_id`
equals the payload's names the machine at that index in `allocations`. A name with any other
`seed_id` names the machine-family entry with that seed and index in `retired_allocations`
(below), never a superseded reservation or a pending removal. A retired-seed index can coincide
with a current machine's index (`STG-20`), and the seed tells them apart. Reject before binding a
missing or malformed `seed_id` in any of these records, and a name that resolves to no allocation
in either member. `artifact_history`'s one entry per non-jump machine includes each destroyed or
outstanding retired machine other than a superseded reservation or a pending removal.

Replace's migration (`STA-17`) moves a machine to its new index under the fresh seed in one
journal act. That act gives every record naming the machine the fresh seed's `seed_id` and the
new index: its placements, a reported record's included, its artifact history, machine state,
host pins and installation groups, and every exposure-ledger reference to it, including those in
other machines' recorded bound sets. The same act ends the machine's retired-seed entry and every
superseded reservation naming it (below) as entries that stand for the machine, so no journal
state, and no export, names one machine under two seeds. It keeps each of their recorded keys as
a pending removal (below), which names a key and not the machine, linked to the machine's new
name, and moves every pending removal already naming the machine to that name. Until that act
every record
keeps the machine's retired-seed name, the name `STG-20`'s installation id uses. Replace does not
migrate a destroyed machine, so its records keep their `seed_id` and index. The machine's new
allocation under the fresh seed takes the machine's `entry` and `predecessor` members (below)
unchanged: a predecessor link names its Failed target by the retired seed and index that target
keeps through every later Replace, so the migration renames no link.

`retired_allocations` is a required array, `[]` when empty. It holds exactly the allocations the
journal keeps under a seed other than the payload's (`STA-22b`):

- each destroyed machine allocated under a retired seed, whether or not a placement record names
  it;
- each Failed allocation under a retired seed, with its consumed index and its `entry` and
  `predecessor` members (below), so a replacement entry's predecessor link (`STA-22b`) still
  resolves;
- each machine Replace has not migrated, a jump host and an LNVPS rebuild's old machine awaiting
  its deletion evidence included;
- each relay pass under a retired seed for as long as `STA-17`'s screen names it unrevoked or
  awaiting its manual retirement's confirmation;
- each handoff allocated under a retired seed for as long as its profile's declared lifetime
  runs (`SEC-5` row 17);
- each superseded reservation (below): a migration index a later Replace found unconfirmed under
  the seed it retires;
- each pending removal (below): a retired public key, the old key of a machine since migrated or
  the key of one of that machine's superseded reservations, whose absence from that machine no
  durably recorded read has yet shown.

A migrated machine has no entry that stands for it; only its pending removals, which are not a
second machine, stay. The exporter copies each entry unchanged from the journal,
keeping its seed through every later Replace: the next Replace's sheet carries this sheet's
retired allocations unchanged beside the entries the then-retired seed adds, except where a
journal act below ends an entry or moves a pending removal's link.

Each entry is the journal's retired-seed entry: its `seed_id`, family `machine`, `pass` or
`handoff`, index, stable resource identity and recorded expected public key as `STA-22b` maps
them, on a machine entry other than a superseded reservation or a pending removal its `entry` and
`predecessor` members (below), `jump_host: true` on a jump host as in `allocations`, and exactly
one state member. A handoff's resource identity is its tenant and handoff ID, and its
recorded key is its post-harness credential's role-4 public half. The state member is one of:

- `destroyed: true`, on a machine whose deletion evidence `SEC-5` admits and the journal durably
  records;
- `failed: true`, on a Failed allocation;
- `outstanding`, on every other entry: an object with exactly the member `reason` and, on a
  machine whose new index Replace has already reserved (`STA-22b`: "Reserve it durably before any
  external effect"), the member `migration_index`, on a superseded reservation, the member
  `reservation_of`, or, on a pending removal, the member `removal_of`.

`reason` records why `STA-17`'s screen names the allocation not yet migrated, unrevoked,
unconfirmed, still needing the retired seed or, for a pending removal, not yet shown removed. It
is exactly one of these
strings. For a machine:

- `"not_started"`: Replace has completed none of its migration steps and recorded no other reason;
- `"key_unconfirmed"`: no connection authenticated by the new key is confirmed, so the old key
  stays in place;
- `"relabel_unconfirmed"`: a dedicated machine whose new root label no read has yet shown;
- `"install_unfinished"`: an install unfinished in rescue, which Replace refuses to migrate;
- `"hold"`: a machine under `STA-20`'s hold;
- `"disposition"`: a machine under a standing destructive reinstall or abandonment disposition
  (`STA-24`);
- `"awaiting_deletion"`: an LNVPS rebuild's old machine, which never migrates, awaiting its
  deletion evidence;
- `"unrecovered"`: a machine whose direct re-entry cannot finish because the retired seed or its
  index is missing;
- `"superseded_reservation"`: a superseded reservation, whose recorded key is one more retired
  public key to remove from the machine it is linked to, kept as a pending removal once that
  machine migrates;
- `"old_key_unremoved"`: a pending removal, whose recorded key's absence from the machine it is
  linked to no durably appended read has yet shown.

For a pass: `"awaiting_revocation"` (the paid/public path's signed revocation is not yet made),
`"awaiting_retirement_confirmation"` (the LNVPS path's manual relay retirement awaits the
publisher's confirmation) and `"unrevocable"` (no revocation can be made, so the pass must
expire). For a handoff: `"lifetime_running"` (its profile's declared lifetime has not ended, so
its use still needs the retired seed). The exporter writes the reason the journal records for the screen. A reason labels the
allocation and authorizes nothing.

Import checks each entry's form. It checks that `seed_id` differs from the payload's, that the
family is `machine`, `pass` or `handoff`, that the entry carries exactly one state member, that
`destroyed`, `failed`, `jump_host`, `migration_index`, `reservation_of`, `removal_of`, `entry` and
`predecessor` appear only on a machine, and that `reason` is one of its family's values. Seed, family and index must be
unique among retired allocations. A `migration_index` must name a machine allocation in
`allocations` that is not destroyed, Failed or a jump host, that has the retired entry's stable
resource identity, and that no other entry's `migration_index` names. That allocation is the
machine's reserved new index, not a second machine: no record names it, it has no
`machine_states` or `artifact_history` entry, and its shared resource identity is a repeated
mapping import accepts.

`reservation_of` appears exactly on an entry whose `reason` is `"superseded_reservation"`, and
such an entry carries neither `migration_index` nor `jump_host`. It is an object with exactly the
members `seed_id` and `machine_index`, in the forms a record's machine name uses, and it must name
an outstanding machine entry in `retired_allocations` that is neither a superseded reservation nor
a pending removal and that has the superseded reservation's stable resource identity. Several
superseded reservations may name one machine. A superseded reservation is not a second machine
either: no record names it, it has no `machine_states` or `artifact_history` entry, and its shared
resource identity is another of the repeated mappings import accepts.

`removal_of` appears exactly on an entry whose `reason` is `"old_key_unremoved"`, a pending
removal, and such an entry carries none of `migration_index`, `reservation_of` and `jump_host`.
It is an object with exactly the members `seed_id` and `machine_index`, in the forms a record's
machine name uses, and it names the machine the recorded key is to be removed from, by that
machine's current name: a machine allocation in `allocations` that is not destroyed or Failed and
that no `migration_index` names, or an outstanding machine entry in
`retired_allocations` that is neither a superseded reservation nor a pending removal, as while a
later Replace has not yet migrated the machine (below). That machine has the pending removal's
stable resource identity, and its own key, derived for an `allocations` machine and recorded for a
retired one, differs from the pending removal's recorded key. Several pending removals may name
one machine. A pending removal is not a second machine either: no record names it, it has no
`machine_states` or `artifact_history` entry, and its shared resource identity is another repeated
mapping import accepts. Every other repeat of a stable resource
identity across both members stays refused, and a handoff's tenant and handoff ID are mapped by
no other entry.

Import accepts each entry's recorded public key without deriving it from any seed, the one
exception to `STA-22b`'s derive-and-compare check. A retired allocation is outside `allocations`,
so that member's derivation, unique-index and next-unused-counter checks stay as they are for
every current-seed allocation. A retired allocation allows no allocation. Reject before binding a
missing or malformed entry, a duplicate, an entry with the payload's seed, another family, a
missing, second or malformed state member, `destroyed` or `failed` other than `true`, an unknown
reason, a reason of another family, a malformed or unmatched `migration_index`, a missing,
malformed or unmatched `reservation_of`, one on another reason, a superseded reservation with a
`migration_index` or `jump_host`, a missing, malformed or unmatched `removal_of`, one on another
reason, one naming a reserved migration index or a machine whose key equals the recorded key, a
pending removal with a
`migration_index`, `reservation_of` or `jump_host`, a record naming a superseded reservation or a
pending removal, a handoff whose tenant
and handoff ID another entry maps, an `outstanding` object with a missing, extra or duplicate
member, and an extra member. The `entry` and `predecessor` members (below) are not extra on a
machine entry that carries them.

A destroyed or Failed retired allocation restores no contact identity, host pin authority,
binding or session, takes part in no vendor reconciliation and has no `machine_states` entry; a
destroyed one keeps exactly the records a destroyed current-seed machine keeps. An outstanding
retired allocation restores its records under its retired seed: a machine's machine state (none
for a jump host), artifact history, host pins, installation groups, placements and ledger
references, a pass's typed relay locator, and a handoff's tenant and handoff ID. Its contact
identity waits for `STA-22b`'s deferred check: before any contact with the machine, any use of the
pass's key, any vendor read or call under its identity, any giving of the handoff's credential to
the post-harness machinery, and any binding, the harness derives the key from the retired seed the
operator supplies and compares it with the recorded key. With no such seed, or on a mismatch, it
makes none of them and the allocation stays outstanding. A superseded reservation restores no
records and no contact identity: its recorded key serves only its removal from the machine it
names, as a pending removal once that machine migrates. A pending removal restores no records and
no contact identity either: its recorded key serves only its removal from the machine
`removal_of` names, a step of Replace's flow that `STA-17` owns, and a Restore removes nothing by
itself. A passing check is no first contact: the machine reconnects under its existing pin, as
`STA-17`'s Restore does. The sheet holds no key, so a Restore from the sheet without the retired
seed runs no deletion check for an `"awaiting_deletion"` machine: until its
key is derived the check has no key and makes no read (`SEC-4`).

A pending removal ends in the journal act `STA-17` names for a read showing its key absent, or in
the act that records the deletion evidence of the machine it names, which records that machine's
destruction, not the key's removal. Either act drops it from the next export. The act that
migrates that machine moves its `removal_of` to the machine's new name (above).

An outstanding retired machine other than a superseded reservation or a pending removal becomes
destroyed when its deletion evidence `SEC-5` admits is durably recorded. One journal act replaces
its `outstanding` with `destroyed: true` and leaves it exactly the records a destroyed machine
keeps: its machine state goes, and so does every placement without a report on it. The same act
ends every superseded reservation and every pending removal naming it, where the act that
migrates the machine keeps their keys as pending removals. After a Restore from this sheet, an
outstanding machine with a `migration_index` may finish its migration to that index, an identity
the sheet lists. One without, other than a superseded reservation or a pending removal, has no
index to move to, since an imported seed
allocates nothing (`STA-22b`), so its migration waits for another Replace with a freshly
generated seed, which re-enters it under its own retired seed.

That later Replace may find a machine whose `migration_index` names an allocation under the seed
it retires. On a dedicated machine it first takes the label read `STA-17` requires. A read
showing that index's id confirms the migration to that index in one journal act, as above: the
machine's original key, and each superseded reservation's naming it, stays as a pending removal
linked to the machine at that index, and the machine then migrates like any machine of the seed
being retired, whose migration act moves those links and keeps that seed's key as one more
pending removal. Otherwise one journal act
supersedes the reservation: the machine keeps its own retired-seed entry without the
`migration_index`, and the reserved allocation becomes its own retired machine entry, under the
seed it was allocated under, with its index, the machine's stable resource identity, its recorded
key and `outstanding` with reason `"superseded_reservation"` and a `reservation_of` naming the
machine. Replace may then reserve the machine a fresh index under its new seed as its
`migration_index`. Before that Replace's export, every `migration_index` naming an allocation
under the seed it retires is settled one way or the other, so the export holds none. A further
Replace copies each superseded reservation and each pending removal unchanged, as it copies every
earlier retired entry, except as the act that migrates or destroys its machine moves its link or
ends it.

A handoff allocated under a retired seed is written only in `retired_allocations`, never in
`allocations`, and Replace issues no new handoff for it: its public half is installed only during
setup, before the handoff point (`ARC-19a`). Giving its credential to the post-harness machinery
needs the retired seed and waits for the deferred check above. Its entry ends in one journal act
when the journal records the end of the lifetime its profile's handoff slot declares.

Two placement records are duplicates when they are equal in the six members `seed_id`,
`machine_index`, `application_name`, `name`, `path` and `placed_at`, whatever `report` holds
(and, in version 8, whatever `report_events` and `independent_end` hold).
`ARC-43` says "The harness records each placement's time later than that of every placement
record already at that machine, application name, secret name and path", so a reported record and
a later placement there are never duplicates.
Reject duplicates and two records without a report at one machine, application name, secret
name and path. Also reject before binding a record whose `seed_id` is malformed or names
neither the payload's seed nor a retired allocation's. Reject too a reported record on an
absent, failed, jump-host or non-machine allocation, where absent means no allocation at that
seed and index; an outstanding retired machine is live, so a placement on it, with or without a
report, is checked as on any live machine.
A machine allocation whose deletion evidence `SEC-5` admits and the journal durably records
carries `destroyed: true`, as a destroyed retired allocation does, and no other allocation carries
the field. A stop, a passed deletion date, a reinstall or a disposition does not set it, and such a
machine stays live here. Reject the field with any other value or on any other allocation. A destroyed allocation has no
`machine_states` entry (below).
A machine allocation the journal records as Failed (`STA-22b`) carries `failed: true`, as a Failed
retired allocation does, and no other allocation carries the field. Reject the field with any
other value or on any other allocation.

In version 8 every machine entry that stands for an approved entry carries the members `entry` and
`predecessor`: each machine allocation in `allocations` other than a reserved migration index, and
each machine entry in `retired_allocations` other than a superseded reservation or a pending
removal, a Failed, destroyed or jump-host entry included. No other entry carries either member: a
pass, a handoff, a reserved migration index, a superseded reservation and a pending removal stand
for no approved entry. A reserved migration index takes the machine's members when Replace's
migration moves the machine to it (above).

`entry` is the approved-entry identity that `STA-22b`'s mapping records for the allocation: the
object `{"id":"<A>"}`, where A is a nonempty string, or the exact string `"unknown"` (conversion,
below). A is opaque. The exporter writes one string per approved entry, the same on every
allocation of that entry and on every export, and a different one for every other entry; import
compares it by exact string equality and derives nothing from it. It is not the
[protected-evidence](protected-evidence-v1.md#closed-raw-and-stored-grammars) `approved_entry`
and is never rebuilt from an allocation index, which can differ between attempts at one entry.

`predecessor` is the backward link that `STA-22b`'s replacement act records. It is the exact
string `"none"` when the journal holds no predecessor for the entry, the exact string `"unknown"`
(conversion, below), or, on each allocation of a replacement entry, an object with exactly the
members `seed_id`, `machine_index` and `entry_id`. `seed_id` and `machine_index` name the retired
entry's Failed allocation in the forms a record's machine name uses, and resolve as a record's name
does, in `allocations` or `retired_allocations`; `entry_id` is that retired entry's A. The link
sits on the replacement's side only: a Failed allocation names no replacement, and a replacement
that is itself later replaced keeps its own link. Several links may name one Failed allocation.
The exporter copies both members unchanged from the journal, and never infers a link from a
matching index, resource identity or vendor. Neither member restores any contact identity,
binding, allocation or authority.

Reject before binding a missing `entry` or `predecessor` on an entry that carries them, either
member on any other entry, a malformed `entry` or `predecessor`, a `predecessor` object with a
missing, extra or duplicate member, a link that names no machine allocation, or names a reserved
migration index, a superseded reservation, a pending removal or an allocation without
`failed: true`, a link whose `entry_id` is not its target's `entry` id, a target with
`entry:"unknown"` included, a link whose `entry_id` is its own entry's id, and a chain of links,
each followed from an entry to the entry its target stands for, that returns to an entry already
on it.

The explicit version-8 conversion of versions 3 to 7 (above) also supplies `entry:"unknown"` and
`predecessor:"unknown"` on every entry that carries them. No older version encoded either, so a
converted link is unknown, never `"none"`. Later exports keep both unknowns unchanged, and nothing
replaces one from a matching index, resource identity or vendor.

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
every placement `report:"none"`, giving every placement, `artifact_history`, `machine_states`
and `host_pins` entry, `host_pin_installations` group and exposure-ledger machine reference the
payload's `seed_id`, giving every `machine_states` entry `reference_ended:false`, and supplying
`retired_allocations:[]`. The conversion invents no report, no mark and no retired allocation:
an older sheet restores each placement's as-of-export wait and each machine's as-of-export
withholding (`STA-16`). Then apply the explicit version-8 conversion above. A reader that predates version 7 refuses
a version-7 sheet as an unknown version. Versions 1 and 2 and unknown versions stay refused. Sheet envelope
v1, derivation v1, algorithms, AAD and known-answer vectors stay unchanged.

Each `host_pins` entry names the host-key route that produced it: `retrieve` (`CHN-R1`),
`attest` (`CHN-R5`), `jump_host` (`CHN-R6`) or `lnvps_retrieve` (`CHN-R7`). The last
value records the retrieved LNVPS hypervisor-scan provenance and is restored with the pin;
it does not authorize a new first contact. Import MUST refuse a missing, unknown or malformed
route value before binding, as it does other malformed payload fields. Each installed-system
pin also carries its `installation` ordinal, starting at zero for that machine; a rescue
pin remains scoped by its rescue boot. Whether the installation
carries an artifact pin is a different fact, carried per machine below. Each `machine_states` entry is
`{machine_index, declaration, class, access_model, installation, weaker_modes, applications}`, and in
version 7 also `seed_id` and `reference_ended` ([version 7](#operator-reports-payload-version-7)): the journaled
declaration in force as a delivery-declaration version 2 document, the class `ARC-36a` records, the
access model of `ARC-27`, `installation` as `"pinned"`, `"unpinned"` (`ARC-25`) or
`"not_installed"` before any installation, and the labels of the acceptable weaker modes standing
on the machine's bound set (`SEC-14`). For `class`, resolution and provenance follow `ARC-36a`;
a recorded harness default carries its class value, not `"unapproved"`, and that value alone
is not an operator answer. A class not yet recorded, or another field not yet approved at
export, carries the explicit marker `"unapproved"`, never an absent field; `installation` and
`applications` are recorded, not approved. Every live machine other than a jump host has exactly one entry, bound to a session or not,
including in version 7 an outstanding retired machine other than a superseded reservation or a
pending removal, whose entry names it by its retired seed; an allocation marked `jump_host: true`
(`STA-22b`) or, in version 7, `destroyed: true` or `failed: true` has none, nor does a reserved
migration index, a superseded reservation or a pending removal (above).
Reject a missing, duplicate or malformed entry and an entry for a jump host or a destroyed
allocation; never interpret a missing entry or an
`"unapproved"` field as a default.

`reference_ended` is `true` or `false`. `SEC-5` owns when it is set: the journal act that
records a rotation of a placement without a report, and the act that records the admitted
deletion evidence of a machine holding one, set it, whether or not that placement's reference is
armed, on that placement's machine while that machine stays live and on every live machine the
exposure ledger records in a bound set with it (`STA-10`). A reported placement's end sets
nothing, since its record stays, including its correction history in version 8. Nothing clears
the mark: a re-arm, a re-check, a reinstall, a new installation, a reapproval, a report, a correction and a
Replace leave it standing, and a migrating machine's entry keeps it. The exporter copies it from
the journal. It is recorded, not approved, and never `"unapproved"`. It is protected and
non-secret: it names no placement, and no value, digest, scan key, byte length or other
value-derived reference accompanies it. Import checks its form only: reject a missing member,
`null` or any other value before binding. After a Restore, a `true` mark keeps every job record
from before the loss on that machine withheld (`SEC-5`). Like the rest of the sheet it is as of
export (`STA-16`): an end the journal records after the export sets no mark on that sheet.

`host_pin_installations` is a required array of installation groups in creation order.
Each group is `{machine_index, installation, observations}`, and in version 7 also `seed_id`
([version 7](#operator-reports-payload-version-7)). The ordinal starts at zero
per machine and increases by one only on an operator-chosen destructive reinstall, through
the vendor API or from rescue. Replace's migration carries that ordinal to the machine's
new index (`STA-17`); it does not restart at zero. `observations` is an array
in recording order; each observation is `{keys: [...]}`, whose elements are
`{family, fingerprint}`. `family` is exactly `ed25519`, `rsa` or `ecdsa`, at most once per
observation; `fingerprint` uses the host-pin fingerprint format, which `CHN-R1` defines. An empty reading that opens
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
these facts, including contact revalidation of a retained pin. These fields remain required in payload version 4 and later and in the version-3
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
are never interpreted as empty. Payload versions 4 to 8 change neither the v1 envelope,
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

For the recovery checklist, see `STA-15`; for the seed ceremony and local unlock explanation,
see `STA-23`.
For maintained cloud, setup completion requires confirmation that the current sheet was
saved (`STA-15`). This confirmation is given in the export view, without an additional modal.
A stale or absent sheet may lose newer machines' metadata and relay quota.
The dedicated test bed covers local storage and derivation. The LNVPS path also requires export,
Restore and Replace for maintained cloud; `CNF-20`'s relabel cases, Robot rescue and paid/public
signed relay revocation follow their own rows in `07-conformance.md`'s applicability
table. These are required implementation demonstrations, not claims that this specification
has run them.

[relay-source]: https://github.com/douglaz/paid-tcp-relay/tree/49309df54dea3841f3cb1a37527f8d4ec9b5f1ab
