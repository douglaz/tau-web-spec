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
decision rather than an implementation detail. Four exist, in descending order of
strength.

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

**Route 2 — retrieve, cloud VPS.** Whether the Cloud API's rescue action returns host
keys the way Robot's does is unverified, and matters first, because the cloud product is
where this starts.

**Route 3 — inject.** The browser generates the host keypair and writes it into
`/etc/ssh/` through cloud-init. No retrieval endpoint is needed at any vendor and the
browser knows the fingerprint because it made the key. The cost is that the *private*
host key rides in user-data, which the vendor stores — so this route contradicts the
invariant that credentials never leave browser memory. There is exactly one way to resolve
that and it is not a technical one: **carve a narrow exception for the injected server host
key specifically, before the route is used.** The exception has to name that key and no
other — widening it to "vendor and inference credentials" would strip the same protection
from the SSH client private key and the relay's own token, opening a larger hole than it
closes. Scrubbing and rotating the key after
first boot is worth doing, but it is a mitigation and not a resolution — the key has
already been exported and the vendor may have kept a copy, and nothing done afterwards
makes an absolute invariant retroactively true. The contradiction may not be left standing,
and it may not be papered over with rotation either.

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
locks the operator out of their own vault. Route 4 is therefore not usable until pins can
be durably exported or re-verified some other way.

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

That does not reverse the decision here, and this record does not pretend to have
re-weighed it. What it changes is that the rejection can no longer rest on "the operator
has no domain": a real evaluation now has to cover issuance against an address the operator
does not own long-term, renewal on a days-long cadence for a machine that must stay
reachable, what happens when the address changes, and whether a machine terminating its own
TLS is a better or worse trust story than a relay carrying ciphertext it cannot read.
Question 19 in [`spec.md`](../../spec.md) is where that sits. Note it changes *who runs the
bridge*, not whether one is needed — the browser still cannot open a raw TCP socket.

**No remote channel at all**, with every machine configured entirely through boot-time
user-data. This is not rejected so much as deferred: it is what the first stage actually
does, and if the three hand-written recipes called for under [`spec.md`](../../spec.md)
§ Status and the next move show that every step can be expressed as boot-time
configuration, the channel stops gating provisioning. It cannot
be the whole answer, because the coordinator still has to reach five member APIs on
machines with no valid certificate, and the periodic re-check has to reach a running
member long after boot.

## Consequences

**The relay is untrusted for content — except under route 4, where it is trusted at
first contact.** This exception is easy to state wrongly and was stated wrongly at first.
Under routes 1 to 3 the fingerprint is known before the first connection, so a hostile
relay is a denial of service and nothing worse. Under route 4 there is nothing to check
the first key against, so a hostile relay can present its own, have it pinned, and read
and alter the session from then on. Every route that retrieves or injects the
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
to 3 precisely because availability is the only property at stake there.

**Content-Security-Policy needs a WebSocket entry** it does not have today, and one more
static entry if route 1 is adopted. It must name the relay's **exact `wss://` origin**, not
the bare `wss:` scheme: a scheme-wide source permits a WebSocket to every secure origin
there is, so an injection or an unintended path would reach anywhere while appearing to
respect the policy. Per-machine addresses never appear in `connect-src` at all, because the
browser connects to the relay's fixed origin and the machine address is a parameter inside
the WebSocket — which is precisely why one exact origin suffices.
