# Recovery roots in the vendor account, and the cloud pin is introduced by attestation

Everything browser-held is rebuildable from the vendor account, restorable from the recovery
sheet, or stated as unrecoverable — nothing unaccounted. The operator's **vendor account is
the recovery root**: it survives a lost phone because it lives in their head or their password
manager and is recoverable through the vendor's own processes, and it is the one party that
always knows which machines exist.

The operative statement of what dies, what survives, and what each recovery path costs is
[`03-state-and-recovery.md`](../../03-state-and-recovery.md). This record holds the decision
and the alternatives rejected.

## The cloud pin is introduced by attestation

**Route 5 of [ADR-0015](./0015-the-browser-reaches-a-machine-over-pinned-ssh.md).** At
creation the browser generates a one-time MAC secret and places it in user-data beside the
client public key. A first-boot hook computes an HMAC of the machine's freshly generated
host-key fingerprints under that secret and posts fingerprints-plus-stamp out through the
relay, to a **drop-box** the browser opened in advance. The browser verifies the stamp against
the secret only it held.

A relay cannot substitute a key it cannot stamp, so there is no trust-on-first-use. The vendor
sees the secret and could forge a stamp — but the vendor owns the machine's disk and memory
and could replace the host keys wholesale regardless, so attest hands it nothing it lacks.
Unlike route 3, **no private key leaves the browser and none rides in user-data.**

### The voucher is a credential

**It authorizes an introduction, which is the whole game.** Possession of the voucher and the
drop-box lets an actor stamp an *arbitrary* fingerprint the browser will then trust. So it
carries a credential's lifecycle: it expires, it is single-use, the first-boot hook scrubs it
from the machine's cloud-init artifacts, and it is redacted from anything recorded or shown to
a model.

> **A trap worth naming, because it is where anyone reasoning from first principles lands.**
> A one-shot secret that is worthless after first boot looks like it needs no credential
> handling at all. It does. "Worthless after first boot" describes the window, not the
> authority, and inside that window the voucher is the only thing standing between a relay and
> a substituted host key.

What keeps it usable in user-data despite the credential inventory is its named row and its
shape: one introduction, once, then worthless — and the party that stores user-data can already
replace the machine's keys wholesale, so the voucher adds nothing to the vendor's power.

### Single-use is the browser's check

**The relay never holds the MAC secret, and a stamp it cannot forge it also cannot verify.**
The drop-box buffers what arrives; the **browser** verifies, accepts the first valid stamp, and
discards the secret. That is what makes the voucher single-use.

> **The second trap, and the more tempting one.** A drop-box that "consumes exactly one valid
> post" is where this mechanism naturally gets designed, because that is where single-use
> checks usually live. The relay cannot implement it. It has no way to distinguish a valid
> stamp from junk, so a drop-box enforcing single-use would be enforcing it on the first post
> of *any* kind, which is a denial of service dressed as a security property.

Anyone holding the drop-box URL — the vendor does — can shadow the box with garbage or a race:
garbage fails verification, and a *validly stamped* race requires the MAC secret, which only
the vendor also holds. A shadowed or empty box is a denial of service that forces the recorded
fallback, nothing more.

### The post retries; the scrub waits for it

The hook retries with backoff until the relay acknowledges or a deadline passes, and scrubs on
whichever comes first, with the deadline inside the voucher's expiry. Networking at first boot
is exactly when routing and DNS are least settled, and a single-shot post followed by an
irreversible scrub would convert a two-second blip into a destroyed machine — on the one route
that has no alternative, since route 2 is dead and route 3 is blocked.

## Considered options

**Store pins at the publisher or relay, synced.** Zero-effort recovery. Rejected because it
puts a third party on the pin path — the exact position from which a substituted key reads
every session — converting the relay or publisher from a carrier into a key authority. The
design refuses this everywhere else and refuses it here.

**Platform sync (passkeys, browser profile sync).** Rejected as silent trust: the pin would
survive via the platform vendor's cloud, a party the unavoidable tier lists for the device but
which nothing here elects for key custody, invisibly to the operator.

**Sheet-only recovery.** Simpler — no ceremony, no attest. Rejected because a lost sheet would
strand every maintained machine behind trust-on-first-use or destruction, and because it leaves
cloud *creation* unsolved: the sheet can only record a pin some other route established first.

**Trust-on-first-use at recovery.** Always available, honestly displayed — and it is the
recorded fallback for a sheetless cloud machine. Rejected as the *default* because recovery is
precisely the moment an attacker who controls the path gets a second first contact; routes that
avoid trust-on-first-use at creation should not reintroduce it at recovery.

## Consequences

**The sheet export is mandatory on maintained cloud machines, optional on dedicated.** A cloud
machine's setup does not complete until the operator confirms the export — the friction is
accepted because without the sheet, recovery costs either the machine's state or the no-TOFU
property. On Robot the ceremony always works, so the sheet is an optimisation. A sealed
tenant's machines need none: their pins die at sealing, and a phone lost mid-setup is answered
by the tenant's own all-or-nothing rule. This asymmetry is stated, not smoothed over.

**The sheet is sensitive in the same way a seed backup is.** It carries the wrapped client keys,
so the export screen must say what it can do in the wrong hands with the passphrase: reach every
maintained machine.

**Recovery after a lost phone revokes; restore after a dead one may not.** A stolen phone's
encrypted store may eventually be unlocked, so **Replace** (new keypairs, old public keys removed
during re-entry, relay token re-issued with the old revoked) and **Restore** (the sheet's same
keys, explicitly non-revoking) are named and distinct, and the screen says which is happening.

**The exposure ledger is recoverable state, or its absence is declared.** It counts every
configured model that ever touched a machine — a history the vendor cannot reconstruct — so it
lives in the encrypted-at-rest store and in the sheet. A machine recovered without it carries
unknown past exposure, displayed as such.

**Those ledger rules bind a tenant that is both maintained and threshold-bearing, and none
exists yet.** Where exposure matters, btc-policy seals, so its ledger is complete at setup and
never drifts. Where the ledger drifts, there is no threshold, so nothing depends on the count.
The rules are kept for the combination that will eventually appear, and scoped so nobody builds
them for a tenant they do not govern.

**Attest needs one empirical probe before it is real.** The first-boot hook must fire reliably
and the post must traverse the relay; cloud-init's `phone_home` module already posts host-key
material, so the mechanism is conventional, but nothing here has run it.

**Question 13 narrows.** Route 3's blocked status was the only path to a cloud pin; attest
removes that pressure. Injection stays recorded and blocked, but it is no longer the cloud
path's only hope.

**Inventory recovery makes the vendor list authoritative.** Listing the account is how a new
phone learns what exists, and that listing is performed by the deterministic recovery flow under
the operator's approval, before any session exists — so it is not a session operation, and the
machine-binding rule for typed operations is not in play.
