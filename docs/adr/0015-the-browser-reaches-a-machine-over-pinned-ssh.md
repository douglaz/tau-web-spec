# The browser reaches a machine over SSH, pinned at the application layer

The browser talks to a machine over SSH, verifying the server's host key against a
fingerprint it obtained by some other means. The bytes travel through a
WebSocket-to-TCP relay, because a browser cannot open a TCP socket to port 22 at all.
The relay is not trusted with the contents of the session.

This decision was made in the design session and used by
[ADR-0003](./0003-the-ai-runs-only-in-the-browser.md) and
[ADR-0011](./0011-the-ai-delivers-a-locked-down-machine.md) — both of which assert that
box-plane commands ride SSH — without ever being recorded. It is recorded here.

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
contents of `host_key` are undocumented.

Rescue boots its own sshd with its own host keys, and the installed system's are
different. That is not a gap — the installed system is put there *from inside the
trusted rescue session*, so its keys are either generated there and read before reboot,
or baked into an image whose hash is already known. No trust-on-first-use at either hop.

**Route 2 — retrieve, cloud VPS.** Whether the Cloud API's rescue action returns host
keys the way Robot's does is unverified, and matters first, because the cloud product is
where this starts.

**Route 3 — inject.** The browser generates the host keypair and writes it into
`/etc/ssh/` through cloud-init. No retrieval endpoint is needed at any vendor and the
browser knows the fingerprint because it made the key. The cost is that the *private*
host key rides in user-data, which the vendor stores — so this route contradicts the
invariant that credentials never leave browser memory. Taking it means either scoping
that invariant to vendor and inference credentials explicitly, or scrubbing and rotating
the host key after first boot. The contradiction may not be left standing.

**Route 4 — trust on first use, plus continuity.** Accept the key on first connect, pin
it, alarm on any later change. This is what ordinary SSH clients do. It needs no
endpoint and puts no key in user-data, and it still detects a network or vendor that
*turns* hostile later.

Route 4 is a floor, not a plan, and the reason is stated in the consequences below.

## Considered options

**Pinning the TLS certificate of a direct HTTPS connection to the machine.** Rejected
because it is unbuildable, not merely weak: browsers expose no API to inspect, pin, or
override the certificate behind a `fetch`, and a freshly created machine has a bare IP
address with no WebPKI-valid certificate to pin in the first place. SSH needs neither
WebPKI nor TLS, which is what makes it the available answer rather than the preferred
one.

**The machine obtains a real certificate during cloud-init via ACME and serves its own
WebSocket bridge to `localhost:22`**, removing the third party entirely. This is the
better architecture and it is rejected for the target operator, not on its merits: it
requires a DNS name the operator controls, and a phone-only non-technical person does
not have one. It becomes attractive the moment a user does own a domain. Note that it
changes *who runs the bridge*, not whether one is needed — the browser still cannot open
a raw TCP socket.

**No remote channel at all**, with every machine configured entirely through boot-time
user-data. This is not rejected so much as deferred: it is what the first stage actually
does, and if the three recipes in the open questions show that every step can be
expressed as boot-time configuration, the channel stops gating provisioning. It cannot
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

**Content-Security-Policy needs a `wss:` entry** it does not have today, and one more
static entry if route 1 is adopted. Per-machine addresses never appear in `connect-src`
at all, because the browser connects to the relay's fixed origin and the machine address
is a parameter inside the WebSocket.
