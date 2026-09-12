# The publisher operates the default relay; bring-your-own is the escape hatch

The WebSocket-to-TCP relay of
[ADR-0015](./0015-the-browser-reaches-a-machine-over-pinned-ssh.md) is operated by the
**publisher** on the default path. The operator may point the app at any other relay
origin instead — bring-your-own, the same escape hatch
[ADR-0007](./0007-trust-is-counted-in-two-layers-and-shown.md) holds open for inference —
and a rentable relay remains a candidate lnrent tenant for later. For the first stage,
the relay credential is a **token issued out of band and pasted once**: it is held under
the credential invariant (encrypted at rest, per its named persistence exception), and it
adds no issuer, no identity model,
and no new party. The identity system a real user base needs is deliberately not designed
here; it is the second-stage half of the open question this record narrows.

We chose this because the design already solved the same shape once. Procured inference
is publisher-selected and publisher-routed, acceptable only because the publisher is
already trusted for the bundle — a compromised bundle can do strictly more than a
compromised relay or model choice — and defensible only while bring-your-own exists.
The relay fits that mold exactly: publisher-default adds no new *party* to the trusted
set, it adds a new *capability* to a party already held to be the largest concentrated
risk, and the honest statement is the capability, not a pretense of neutrality.

**What the publisher additionally sees under the default: connection metadata.** Which
operator, which destination, when. It cannot read or alter a session pinned out of band
([ADR-0015](./0015-the-browser-reaches-a-machine-over-pinned-ssh.md)), so the addition is
visibility, not authority over content — but a party that serves the bundle *and* sees
every connection is a bigger observer than one that serves the bundle alone, and the
trust accounting must say so rather than average it away.

## Considered options

**The operator self-hosts the relay.** The option that moves metadata visibility to the
smallest set — the hosting machine's own vendor still sees it, since the vendor owns the
machine, but no party beyond those already trusted for that machine. Rejected as the
*starting point* because it contradicts the audience: a phone-only non-technical
operator cannot stand up a relay, and a design whose first step requires the thing the
product exists to make unnecessary has failed before it starts. (The amendment below
supersedes the finality of this rejection: self-hosting is the *destination*, reached
through the product itself once a maintained machine exists — just never the starting
point.)

**An independent third party.** Splits metadata visibility from the bundle holder, which
is genuinely better on paper. Rejected for now because it adds a real new trusted party —
the exact move `SEC-10` prices as a schema migration — and because no such party
exists to do the work; naming a vacancy is not a decision. Bring-your-own leaves the door
open for one to emerge.

**Decide later, dev-run for the first stage.** Rejected because the operator question is
load-bearing for the trust accounting *now* — the Added-tier relay entry reads
differently depending on who runs it — and deferring it would leave the first stage
running on an unrecorded arrangement that hardens into the default by inertia.

## Consequences

**The relay's Added-tier entry changes character.** Under the default, the relay is not a
new third party — it is a new capability of the publisher, and the tier's honest reading
is "the publisher, twice: bundle and relay." Under bring-your-own it is whoever the
operator pointed at. The trust display must name the relay's operator, not just its
existence.

**Bring-your-own relay is load-bearing, not decorative.** Exactly as with inference: if
the escape hatch is ever dropped, publisher-default stops being defensible and this
record stops holding. The Content-Security-Policy consequence follows — the relay origin
becomes a configured value rather than a constant, which is exactly why the policy does
not pin it: a frozen list cannot hold an operator-chosen origin, and the specification's
Content-Security-Policy question records that the policy is not the boundary.

**The first stage runs on the publisher's relay with a pasted token.** No account system,
no issuer, no reacquisition story — those are second-stage work, and doing them
carelessly is how an identity party gets added to the trusted list. What the first stage
proves is the channel; what it deliberately does not prove is enrollment.

*Amended:* the token is gone. Per
[ADR-0025](./0025-relay-access-is-bought-not-granted.md)'s amendment the relay binds a pass to a
**public key** the browser derives from the operator's seed, and the first stage hands the
publisher that public key out of band. Nothing secret is issued, pasted or held. The rest of
this paragraph stands: it is still enrolment by hand, and still not the purchase flow.

**Relay redundancy stays cheap — under the same operator.** Under out-of-band pinning a
hostile relay is a denial
of service and nothing worse, so a second relay under the operator already trusted is an
availability move. An **independently operated** second relay is different: its operator
becomes another observer of connection metadata and enters the trust display like any
relay operator — an availability move *and* a trust change, priced as such.

## Amended: the publisher relay is a bootstrap, and minimum usage is the goal

Two clarifications sharpen the decision above. **First, direct-first**: the relay is never
in a path the browser can take alone. An off-machine call goes straight from the browser
to the service whenever the service permits it; the relay carries only what cannot go
direct — raw TCP always (SSH); as a fallback, untyped calls whose destination refuses
browser CORS, tunneled under TLS that terminates in the browser so the relay stays a
carrier of ciphertext. (The attest post used to be a third item here, delivered to a
drop-box the browser opened in advance; it now travels as a gift-wrapped event to a Nostr
relay the publisher runs beside the bridge, and never crosses the bridge at all —
[ADR-0029](./0029-the-machine-speaks-nostr-and-keys-derive-from-a-seed.md).) Minimum usage
is a design property, not an accident.

**Second, the publisher's seat is transitional.** The trajectory is a relay on the
operator's **own machine** — the first lnrent box can host it, and a relay is deliberately
cheap to run — with the product actively offering the move once such a machine exists,
not merely tolerating it. The publisher relay exists to solve the bootstrap: before the
operator has any machine, someone must carry the bytes that provision the first one.
After that, ordinary traffic can move, but the relay-host machine still needs an external
relay for management, recovery and outside-in scans: `CHN-16a` correctly forbids dialing
the relay's own addresses. Migration must retain and demonstrate that external route before
switching defaults. The external relay can be the publisher's or another operator-chosen one;
its availability and metadata exposure remain visible. A single self-hosted relay therefore
does not end the dependency. Self-hosting has its own honest price, named rather than
hidden: the hosting machine's **bound model** has box-plane reach over whatever the relay
retains, so the relay-install brief configures no connection logging, and the trust
display prices the host machine's model as a potential metadata observer regardless —
for a vault, that model can see the member topology, the same cost the scanner's row
already names.
