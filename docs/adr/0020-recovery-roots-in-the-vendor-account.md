# Recovery roots in the vendor account, and the cloud pin is introduced by attestation

Everything browser-held is rebuildable from credentials that never lived in the browser,
or it is stated as unrecoverable — nothing in between. The operator's **vendor account is
the recovery root**: it survives a lost phone because it lives in their head or their
password manager and is recoverable through the vendor's own processes, and it is the one
party that always knows which machines exist.

What dies with a phone: host-key pins, the SSH client private key, the machine inventory,
the relay token, action transcripts, provenance records. What survives: the vendor login,
the inference account, the app URL, a relay token re-issued out of band
([ADR-0019](./0019-the-publisher-operates-the-default-relay.md)) — and, if exported, the
**recovery sheet**: host-key fingerprints plus the client key wrapped under a passphrase.

Recovery on a new phone, per access model and vendor capability:

- **Sealed machines** (btc-policy): nothing to recover. The channel ended at sealing
  ([ADR-0013](./0013-ongoing-operation-periodic-pentest-and-advisory-watch.md)), so a lost
  pin loses nothing.
- **Maintained, dedicated (Robot)**: the **rescue ceremony** — register the new phone's
  client key (typed operation), activate rescue with its fingerprint, pin the rescue host
  key **from the API, no trust-on-first-use**, and from inside rescue install the new
  client public key and re-read the installed system's host keys. Cost: one reboot.
- **Maintained, cloud**: the sheet restores pins and client key with zero downtime.
  Without it, two honest options: **destroy-and-recreate**, which re-runs the attest
  introduction below and loses the machine's state; or **keyed rescue with a displayed
  leap of faith** — Cloud's `enable_rescue` injects a registered SSH key, so the login is
  keyed, but the rescue system's host key is unverifiable (route 2 is dead) and the
  screen says "trusted, not verified" rather than pretending.
- **Transcripts and provenance are gone and stated as gone.** They were records, not
  secrets; nothing re-derives the past.

**The cloud pin is introduced by attestation — route 5 of
[ADR-0015](./0015-the-browser-reaches-a-machine-over-pinned-ssh.md).** At creation, the
browser generates a one-time MAC secret and places it in user-data beside the client
public key. A first-boot hook computes an HMAC of the machine's freshly generated host-key
fingerprints under that secret and posts fingerprints-plus-stamp out through the relay.
The browser verifies the stamp against the secret only it held: a relay cannot substitute
a key it cannot stamp, so there is no trust-on-first-use. The vendor sees the secret and
could forge a stamp — but the vendor owns the machine's disk and memory and could replace
the host keys wholesale regardless, so attest hands it nothing it lacks. Unlike route 3,
**no private key leaves the browser and none rides in user-data**: the secret is a
one-shot introduction voucher, worthless after first boot.

## Considered options

**Store pins at the publisher or relay, synced.** Zero-effort recovery. Rejected because
it puts a third party on the pin path — the exact position from which a substituted key
reads every session — converting the relay or publisher from a carrier into a key
authority. The design refuses this everywhere else and refuses it here.

**Platform sync (passkeys, browser profile sync).** Rejected as silent trust: the pin
would survive via the platform vendor's cloud, a party the unavoidable tier lists for the
device but which nothing here elects for key custody, invisibly to the operator.

**Sheet-only recovery.** Simpler — no ceremony, no attest. Rejected because a lost sheet
would strand every maintained machine behind trust-on-first-use or destruction, and
because it leaves cloud *creation* unsolved: the sheet can only record a pin some other
route established first.

**Trust-on-first-use at recovery.** Always available, honestly displayed — and it is the
recorded fallback for a sheetless cloud machine. Rejected as the *default* because
recovery is precisely the moment an attacker who controls the path gets a second first
contact; routes that avoid TOFU at creation should not reintroduce it at recovery.

## Consequences

**The sheet export is mandatory on cloud machines, optional on dedicated.** A cloud
machine's setup does not complete until the operator confirms the export — the friction
is accepted because without the sheet, recovery costs either the machine's state or the
no-TOFU property. On Robot the ceremony always works, so the sheet is an optimization
and stays optional. This asymmetry is stated, not smoothed over.

**The wrapped client key makes the sheet sensitive.** It is encrypted under a passphrase
the operator chooses, and the export screen must say what the sheet can do in the wrong
hands with the passphrase: reach every maintained machine. This is the same posture the
target audience already holds toward seed backups.

**Attest needs one empirical probe before it is real.** The first-boot hook must fire
reliably on Hetzner Cloud and the post must traverse the relay; cloud-init's `phone_home`
module already posts host-key material, so the mechanism is conventional, but nothing
here has run it. The specification's question 3 tracks the probe and the ceremony
rehearsal.

**Question 13 narrows.** Route 3's blocked status was the only path to a cloud pin;
attest removes that pressure. Injection stays recorded and blocked — but it is no longer
the cloud path's only hope, which changes how urgently the exception decision is needed.

**Inventory recovery makes the vendor list authoritative.** Listing the account is how
the new phone learns what exists — one more reason typed vendor operations are bound to
the session's machine, since the recovery flow reads the whole account by design.
