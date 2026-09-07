# The browser reaches a machine over SSH, pinned at the application layer

The browser talks to a machine over SSH, verifying the server's host key against a
fingerprint it obtained by some other means. The bytes travel through a
WebSocket-to-TCP relay, because a browser cannot open a TCP socket to port 22 at all.
The relay is not trusted with the contents of the session — **except at first contact
under route 4 below**, which is the whole reason route 4 is a floor rather than a plan.
That exception belongs in the first paragraph, because this is the sentence that gets
quoted, and stating it without the exception is the specific error this record exists to
correct.

This decision was made in the design session and depended on without ever being
recorded: [ADR-0003](./0003-the-ai-runs-only-in-the-browser.md) states that box-plane
commands ride SSH, and [ADR-0011](./0011-the-ai-delivers-a-locked-down-machine.md) has
the coordinator's calls to five member APIs riding the same channel because a fresh
machine has no valid certificate. It is recorded here.

We chose SSH because the check that matters happens *inside the SSH protocol*, at the
application layer. Once the right host key is pinned, the transport underneath is
irrelevant to confidentiality and integrity: a relay carrying ciphertext cannot forge a
handshake for a key it does not hold. That property is what lets an untrusted third
party sit in the path without becoming a trusted party, which is the whole reason a
phone-only operator can reach a machine at all.

## How the fingerprint is obtained

Everything rests on pinning the *right* key, so the routes to it are part of the
decision rather than an implementation detail. Five are identified — numbered in the
order they were found, listed strongest first, which puts the fifth before the fourth;
the second is verified dead, and the fifth was added by
[ADR-0020](./0020-recovery-roots-in-the-vendor-account.md) after the first four left the
cloud path with no out-of-band introduction at all.

**Route 1 — retrieve, dedicated servers.** Hetzner's Robot webservice exposes `host_key`
on `GET` and `POST /boot/{server-number}/rescue`. The harness activates rescue over
HTTPS, reads the authoritative host key, derives the fingerprint locally, and never
performs trust-on-first-use. Robot's browser reachability has been probed and is not an
obstacle. Two caveats: Robot is a different product from Hetzner Cloud with a different
auth scheme, so it is a second integration rather than a free extension; and the
contents of `host_key` are undocumented. The reachability result rests on a single recorded
probe and has not been re-verified since.

Rescue boots its own sshd with its own host keys, and the installed system's are
different. That is not a gap — the installed system is put there *from inside the trusted
rescue session*, so its host keys are **generated there, per machine, and read before
reboot**. No trust-on-first-use at either hop.

**Host keys are never baked into a reusable image.** An image is built once and booted on
every member, so a host key inside it is the same private key on all five machines: anyone
holding the image, or compromising any one member, can then impersonate every other member
*and pass the fingerprint check*, because the fingerprint is genuinely the one that was
pinned. That defeats host-key pinning and member isolation at the same time, and it does it
silently. Reusing an image for the operating system is fine and is the point; reusing it
for identity is not.

**Route 2 — retrieve, cloud VPS. Dead, and verified dead.** Hetzner Cloud's rescue action
returns an action and a root password and no host key — checked against the API client
when [ADR-0018](./0018-first-stage-is-one-lnrent-box-on-dedicated.md) moved the first
stage to dedicated. The cloud path's identity problem belongs to the second stage: route 5
below is designed for exactly it, with routes 3 and 4 behind it.

**Route 3 — inject. Abandoned.** The browser generates the host keypair and writes it into
`/etc/ssh/` through cloud-init. No retrieval endpoint is needed at any vendor and the browser
knows the fingerprint because it made the key.

It was blocked for a long time on the recorded objection: the *private* host key rides in
user-data, which the vendor stores, contradicting the credential inventory, and the only way out
would be a narrow exception naming that key and no other — never a widening to "vendor and
inference credentials", which would strip the same protection from the SSH client keys and the
relay's own token, a larger hole than the one being patched.

**It is abandoned on a stronger objection that the block never named.** Boot-time user-data is
served back to the machine by the vendor's metadata endpoint for the life of the instance.
Anything on that machine can re-fetch the host private key whenever it likes and impersonate the
machine, passing the fingerprint check because it *is* the pinned key. The proposed mitigation
cannot reach that: scrubbing deletes cloud-init's on-disk cache while the endpoint keeps serving
the original. Rotation afterwards does not help either, because the window is the whole life of
the instance rather than the first boot.

Route 5 covers the same vendors — anywhere with boot-time user-data — so abandoning this costs
nothing but the route itself. The distinction that lets one live and not the other is worth
keeping in mind wherever user-data is used: **a short-lived credential in a permanently-readable
place is bounded by its expiry; a permanent one is not bounded at all.**

**Route 5 — attest.** At creation, the browser generates a one-time MAC secret and places
it in user-data beside the client public key. A first-boot hook computes an HMAC of the
machine's freshly generated host-key fingerprints under the secret and posts
fingerprints-plus-stamp out through the relay; the browser verifies the stamp against the
secret only it held. A relay cannot substitute a key it cannot stamp, so there is no
trust-on-first-use; the vendor could forge a stamp but already owns the machine outright,
so the route hands it nothing. Unlike route 3, no private key rides in user-data — the
secret is a one-shot introduction voucher, worthless after first boot. Works at any
vendor with boot-time user-data, which is exactly the set where routes 1 and 2 do not.
Designed, not yet run: the specification's question 3 tracks the probe
([ADR-0020](./0020-recovery-roots-in-the-vendor-account.md)).

*Superseded in mechanism, not in reasoning* by
[ADR-0029](./0029-the-machine-speaks-nostr-and-keys-derive-from-a-seed.md): the secret is now
a per-machine sender key derived from a seed, and it **is** a private key in user-data. The
sentence above that says no private key rides there is what changed, and the distinction that
lets attest survive the fact that killed route 3 is the one this record already states — what
the key *authorizes*. A host key impersonates for life; a sender key introduces once, and the
browser never listens for it again.

**Route 4 — trust on first use, plus continuity.** Accept the key on first connect, pin
it, alarm on any later change. This is what ordinary SSH clients do. It needs no endpoint
and puts no key in user-data, and it still detects a **network or relay** attacker that
turns hostile later — one that does not hold the key and therefore cannot keep presenting
the pinned fingerprint. It does **not** detect a vendor that turns hostile: the vendor can
read the host private key off the machine's disk or memory and go on presenting the same
fingerprint, so no continuity alarm ever fires. Continuity is protection against the
network, not against the vendor, which is the same limit the consequences below record for
every route.

Continuity also assumes the pin survives, and a pin lives in browser storage — which gets
cleared, evicted, or left behind on a replaced phone. The machine is unchanged and still
holds its key, but nothing local can attest to it any more. Treating that as a fresh first
contact re-opens the exact window this route already concedes; refusing the connection
locks the operator out of their own vault. Route 4 was therefore unusable until pins
could be durably exported or re-verified some other way —
[ADR-0020](./0020-recovery-roots-in-the-vendor-account.md) now supplies both, the
recovery sheet for export and the vendor-account ceremonies for re-verification, so the
objection has an answer; route 4 stays a floor for the reasons below.

Route 4 is a floor, not a plan, and the reason is stated in the consequences below.

## Considered options

**Pinning the TLS certificate of a direct HTTPS connection to the machine.** Rejected
because it is unbuildable, not merely weak: browsers expose no API to inspect, pin, or
override the certificate behind a `fetch`, and a freshly created machine has a bare IP
address with no WebPKI-valid certificate to pin in the first place. SSH needs neither
WebPKI nor TLS, which is what makes it the available answer rather than the preferred
one.

**The machine obtains a real certificate during cloud-init via ACME and serves its own
WebSocket bridge to `localhost:22`**, removing the third party entirely. This is the better
architecture, and it was rejected on a premise that has since weakened: that it requires a
DNS name the operator controls, which a phone-only non-technical person does not have.
Public CAs now issue WebPKI certificates for bare **IP addresses** under short-lived
profiles, and a VPS has a public IP — so the DNS requirement is no longer the blocker it
was when this was first weighed.

**Re-weighed and rejected again, on grounds that stay true: Certificate Transparency.**
Every publicly trusted certificate is published in permanent, searchable logs, and browsers
require it — there is no quiet issuance. A certificate for a bare IP publishes that IP. For
a federation this means the members' addresses appear as a correlated, timestamped set —
several issuances minutes apart across several hosting providers, a distinctive pattern an
observer can mine continuously — which hands an adversary exactly the grouping the vault
tenant's own rule exists to deny ("no correlation class reaches quorum", btc-policy
ADR-0009). The comparison is: one relay learns connection metadata, or everyone learns the
topology, forever, unpublishably. The relay wins.

Renewal compounds it: IP certificates are short-lived, so every member re-announces itself
in the log on a days-long cadence for the life of the vault, and must keep a validation
path open to do so. None of this touches an lnrent box, whose address is already public by
design in its Nostr listing. An lnrent box serving as the operator's own *relay* is the
one machine that does need a WebPKI certificate — a browser demands `wss://` — and the CT
objection does not bite it, because its address is already public by design; certificate
provisioning belongs to the relay-install brief. An lnrent box that is not a relay needs
no certificate, because a relay already reaches it. Owning a domain does not dissolve the objection either, only
relocates it: per-member hostnames under one registrable domain land in the same logs and
resolve in public DNS to the member IPs, regrouping the federation just as visibly. What a
domain buys is the *possibility* of hiding the grouping — a wildcard certificate, names
that resolve nothing publicly — and any such scheme would need its own evaluation before
claiming the log stays silent. Note the option changes *who runs the bridge*, not whether
one is needed — the browser still cannot open a raw TCP socket.

**No remote channel at all**, with every machine configured entirely through boot-time
user-data. This *was* the first stage until
[ADR-0018](./0018-first-stage-is-one-lnrent-box-on-dedicated.md) replaced it: Robot has no
user-data, so the current first stage runs the full channel and this escape hatch is gone
for it. The question stays real for the second stage on Cloud, where user-data could still
shrink the channel's role in provisioning — though never to zero, because the coordinator
still has to reach five member APIs on machines with no valid certificate. (The periodic
re-check is no longer a reason: vault nodes are sealed after setup, so their re-check is
an external probe through the relay, not a session inside —
[ADR-0013](./0013-ongoing-operation-periodic-pentest-and-advisory-watch.md)'s amendment.)

## Consequences

**The relay is untrusted for content — except under route 4, where it is trusted at
first contact.** This exception is easy to state wrongly and was stated wrongly at first.
Under routes 1 to 3 and 5 the fingerprint is known before the first connection, so a hostile
relay is a denial of service and nothing worse. Under route 4 there is nothing to check
the first key against, so a hostile relay can present its own, have it pinned, and read
and alter the session from then on. Every route that retrieves, injects, or attests the
fingerprint exists to avoid exactly this, and it is why route 4 is a floor.

**The relay holds real authority over who may connect where, while holding none over
what is said.** Both halves are true and the second does not cancel the first. It learns
connection metadata — which operator, which destination, when — and the product must say
so plainly rather than describing it as a dumb pipe.

**A relay must not be an open proxy.** A WebSocket-to-arbitrary-TCP bridge with no
authentication will be abused within days of being reachable. The archived specification
already imposes the right requirements on exactly this component (§21): authenticate the
user, enforce destination and operation policy, prevent generic open-proxy behaviour.
Adopting those is the resolution; inventing a looser relay is not.

**This reverses `ai-vps-harness` §4**, which lists an API relay under *explicitly absent*
and deleted its `services/relay`. The reversal is deliberate and belongs recorded in that
repository too.

**The cloud vendor stays in the trusted set under every route.** Retrieval means the
vendor serves the key and could serve a different one; injection means the vendor stores
the user-data carrying the private key and could read it. Pinning buys transport safety,
not vendor independence — vendor independence is what multi-vendor membership buys. This
is acceptable only because the vendor already owns the machine's memory and disk, and
nothing short of a hardware root of trust the vendor will not provide would change it.

**The relay is a candidate lnrent tenant**, and relay redundancy is cheap under routes 1
to 3 and 5 precisely because availability is the only property at stake there — cheap
under the *same operator*; an independently operated relay is a new metadata observer
([ADR-0019](./0019-the-publisher-operates-the-default-relay.md)).

**Content-Security-Policy splits by directive** (`ARC-33`). `connect-src` is permissive for
`https:` and `wss:` alike, because a bring-your-own or self-hosted relay origin cannot live
in a frozen list, and because approval and the relay's own destination policy are what bound
an off-machine call. `script-src`, `object-src` and `base-uri` stay strict, because they bind
a different case entirely: code the harness never meant to run does not call the approval
path. What stands unchanged either way: per-machine addresses never appear in `connect-src`
at all, because the browser connects to a relay origin and the machine address is a parameter
inside the WebSocket.
