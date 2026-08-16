# Recovery roots in the vendor account, and the cloud pin is introduced by attestation

Everything browser-held is rebuildable from the vendor account, restorable from the
recovery sheet, or stated as unrecoverable — nothing unaccounted. The operator's **vendor account is
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
  client public key and re-read the installed system's host keys. Cost: two reboots —
into rescue and back.
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

## Amended: the attest post is delivered to a drop-box, and the exceptions are named

Two gaps a review closed. **First, the reverse channel.** The relay of
[ADR-0015](./0015-the-browser-reaches-a-machine-over-pinned-ssh.md) is browser-initiated,
so a first-boot machine cannot "post through the relay" without a rendezvous. The
mechanism: before creating the machine, the browser obtains a **one-time drop-box** from
the relay — a random collection token that is *not* the MAC secret, which never touches
the relay — and puts the drop-box URL in user-data beside the secret. The machine posts
fingerprints-plus-stamp to the drop-box; the relay buffers until the browser collects or
a TTL expires. A relay that drops the post, or a post that never arrives, forces exactly
the recorded fallback: recreate, or keyed rescue with the leap of faith displayed. The
drop-box is a third relay duty beside the SSH bridge and the untyped tunnel, and it
changes nothing about trust: the relay sees a stamped fingerprint it cannot forge.

**Second, the credential invariant now names what this record implied.** The sheet
exports the wrapped client key, and ongoing operation requires the client key, relay
token, and pins to survive an app restart — both were collisions with the
credentials-in-memory invariant as originally worded. `spec.md` invariant 5 now carves
three named exceptions — encrypted-at-rest persistence unlocked at app open, the
operator-initiated sheet export, and the attest voucher in user-data — before use, per
the same standard route 3 is still held to.

**Scope of the mandatory sheet, sharpened.** The mandate applies to **maintained** cloud
machines. A sealed tenant's machines need no sheet: their pins die at sealing, and a
phone lost mid-setup is answered by the tenant's own all-or-nothing rule — abandon and
recreate. And the inventory listing at recovery is performed by the deterministic
recovery flow under the operator's approval, before any session exists — it is not a
session operation, so the machine-binding rule for typed operations is not in play.

## Amended again: the voucher is a credential, the ledger recovers, the token rides the URL

**The attest voucher is a short-lived introduction credential, not a non-credential.** The
body above called it "a one-shot introduction voucher, worthless after first boot" and
denied it credential handling; that was wrong in the way that matters:
possession of the voucher and the drop-box lets an actor stamp an *arbitrary* fingerprint
the browser will then trust — it authorizes the introduction, which is the whole game. So
it carries a credential's lifecycle: it expires, it is single-use — the browser accepts
the first valid stamp and discards the secret; the drop-box only buffers — the
first-boot hook **scrubs it from the machine's cloud-init artifacts** (user-data
persists on disk otherwise), and it is redacted from anything recorded or shown to a
model. What keeps it usable in user-data despite the credential invariant is its named
exception and its shape: one introduction, once, then worthless — and the party that
stores user-data (the vendor) can already replace the machine's keys wholesale, so the
voucher adds nothing to the vendor's power. The collection token is part of the drop-box
URL in the same user-data: the vendor sees both, which collapses to the same accepted
fact, and anyone else who obtains them post-boot finds them expired and consumed.

**The exposure ledger is recoverable state, or its absence is declared.** Invariant 1
counts every configured model that ever touched a machine, for the machine's life — a
history the vendor cannot reconstruct. It therefore lives in the encrypted-at-rest store
and in the recovery sheet beside the pins. A machine recovered *without* it carries
**unknown past exposure**: the display says so, and re-entry may bind only a configured
model not currently assigned to any other machine — the conservative reading, since the
unknown history could contain any of them.

**What dies with a phone, completed:** the earlier list omitted the vendor API credential
and the inference key. They die too — deliberately: they are re-supplied by the operator
per session and are not in the persisted set, which names only the client key, the relay
token, the pins, and the ledger.

## Amended a third time: single-use is the browser's check, the ledger goes stale, recovery revokes

**Single-use is enforced by the browser, not the drop-box.** An earlier amendment said the
drop-box "consumes exactly one valid post" — but the relay never holds the MAC secret, and
a stamp it cannot forge it also cannot verify, so the drop-box cannot tell a valid post
from junk. What it does is buffer what arrives; the **browser** verifies, accepts the
first valid stamp, and discards the secret, which is what makes the voucher single-use.
Anyone holding the drop-box URL — the vendor does — can shadow the box with garbage or a
race: garbage fails verification, and a *validly stamped* race requires the MAC secret,
which only the vendor also holds — the accepted fact again. A shadowed or empty box is a
denial of service that forces the recorded fallback, nothing more.

**A restored ledger is a floor, not a census.** The sheet is exported when setup
completes, but every later re-entry can add a configured model to a machine's exposure
history, and a downloaded sheet does not update itself. So the sheet records its export
time; the app requires a **re-export whenever the ledger mutates** (the same mechanic as
the original mandate); and a restored ledger is treated as a lower bound — the display
marks it "as of" its export, and where it may be stale, re-entry follows the same
conservative rule as no ledger at all: bind only a model not currently assigned to any
other machine.

**Recovery after a *lost* phone revokes; restore after a *dead* one may not.** A stolen
phone's encrypted store may eventually be unlocked, and restoring the same client key —
or merely adding a new one — leaves the old key in `authorized_keys` and the old relay
token valid. The flows are therefore named and distinct. **Replace** (the default, for a
phone that is lost): a new client key, the old key removed from every maintained machine
during re-entry, and the relay token re-issued with the old one revoked. **Restore** (for
a phone that died in hand): the sheet's same key, explicitly presented as non-revoking.
The screen says which one is happening and why the difference matters.
