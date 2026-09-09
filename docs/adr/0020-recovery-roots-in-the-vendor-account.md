# Vendor inventory and seed credentials are separate recovery roots

The vendor account roots **inventory**. A dedicated harness seed roots **credentials**, and
an encrypted recovery sheet carries the allocation metadata needed to select those credentials,
plus host pins, exposure history and the inference account credential. The operative rules
are `STA-14`–`STA-18` and `STA-22`–`STA-23` in
[`03-state-and-recovery.md`](../../03-state-and-recovery.md).

## Current recovery paths

On maintained dedicated machines, the vendor-authenticated Robot rescue ceremony can install
a fresh client public key and re-read the installed host keys. The sheet is an optimization
for that machine-access path, not a prerequisite. This still works when the old seed or its
indices are lost; it costs two reboots and does not recover missing relay quota or inference
balance. Recovery rescues existing data; it does not run the installation brief or wipe disks.

Maintained cloud setup requires a sheet before completion. Seed plus sheet restores known
keys and pins without a reboot. A missing or stale sheet invokes the explicit recreate or
honestly labelled keyed-rescue fallback; it cannot invent a missing pin. Sealed machines have
no management channel to recover; an incomplete federation follows the tenant's abandonment
rule.

Direct Replace uses old seed and allocation metadata to re-enter machines and revoke relay
passes, then installs keys derived from a fresh seed. Missing old material invokes the vendor
fallback and leaves unknown passes unrevoked until expiry; partial recovery never reports
complete revocation. Restore uses existing keys and does not revoke, but a seed imported after
journal loss cannot allocate new identities. A stale sheet cannot prove the latest index, so
allocation resumes only under a fresh seed through Replace (`STA-22b`).

The sheet's password protects its metadata and spendable inference credential. It contains no
seed or derived private keys; both seed backup and allocation metadata are needed for direct
machine-key recovery. The inference credential remains unrevocable, which Replace must say.
Local unlock is independent of both backups (`STA-23`).

## Alternatives and traps

**Publisher-backed pin/index storage.** Rejected: this puts a third party in the recovery
integrity path and adds a service the design does not otherwise need. Missing metadata is
reported rather than guessed or fetched from an unnamed authority.

**Platform sync.** Rejected as the default: syncing custody material would silently elect a
platform cloud account as another key holder. Local encryption is not platform backup.

**Seed alone recovers everything.** Rejected: a seed reconstructs a key at a known path; it
does not discover vendor resource mappings, relay purchases, pins or the latest counter.

**Sheet-only recovery.** Rejected: losing it need not strand dedicated machines, since the
vendor-authenticated rescue path exists. Conversely, a sheet cannot reconstruct past action
transcripts, and its exposure ledger is only as current as its export.

**MAC voucher and relay drop-box for cloud introduction.** Superseded by ADR-0029's derived
sender/recipient keys and Nostr gift wraps. The planted sender key remains an introduction
credential visible in vendor metadata. Browser-side single-use acceptance is its bound;
disk scrubbing cannot remove the vendor's metadata copy.

The dedicated identity chain was rehearsed September 8. Integrated recovery, export/import
and the real cloud first-boot path still require `OPN-3`'s evidence.
