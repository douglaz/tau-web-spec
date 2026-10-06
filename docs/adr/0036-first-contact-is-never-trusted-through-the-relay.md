# First contact is never trusted through the relay; a jump host carries it where no route exists

Trust on first use is refused through the relay. Where a vendor offers no route to an
independently obtained host key, the browser makes the first contact from a temporary jump
host no model has touched, inside a session pinned out of band. Decided 2026-10-05.

This amends [ADR-0015](./0015-the-browser-reaches-a-machine-over-pinned-ssh.md), whose fourth
route — accept the key on first connect, and pin it — was the route of last resort behind every
other.

## Why

ADR-0015 already said what was wrong with its last resort: under it the relay is trusted at
first contact and can have its own key pinned. It kept the route anyway, because without it a
vendor with no retrieval endpoint and no usable boot configuration could not be used at all.
Two things changed. The general case makes "a vendor with no route of its own" the ordinary
vendor rather than the exception. And the harness now places secrets on machines: an impostor
pinned at first contact receives every one of them afterwards.

Every connection the browser makes to a machine runs through the relay. A key accepted there
with nothing to check it against is the relay's word, and `OVR-4` allows the relay no such
word: `OVR-4` says "it MUST NOT be able to read or inject".

## The decision

**Through the relay, no first contact is taken on trust.** `CHN-R4` says "the harness MUST NOT
do it through the relay". Continuity — halting on a later change of key — survives as what
`SEC-11` does with every pin.

**Attest has one remedy when it fails.** `CHN-R5` says "If the introduction never arrives, the
machine is recreated, and nothing weaker is entered". The keyed rescue login that used to stand
beside the recreate, with its leap of faith displayed, is withdrawn: it was the refused route
under another name.

**Where no route exists, the first contact comes from a jump host.** The route is `CHN-R6`,
and its conditions are that requirement's. In outline: a temporary machine, created by harness
code through a typed adapter and pinned by retrieve or attest; a pinned session from the
browser to it; and the target's own handshake run end to end through a forwarded channel
inside that session, so that the relay carries one layer of ciphertext and can alter nothing
in the first contact.

**What it is, said plainly.** `CHN-R6` says "This is trust on first use moved from the relay's
position to the jump host's". The jump host, its vendor and the route to the target can still
put their own key in front of the browser. It is an acceptable weaker mode
([ADR-0035](./0035-non-waivable-rules-and-acceptable-weaker-modes.md)), labelled for the
machine's life, and its parties are a row in `05-trust.md` (`TRU-E11`).

## Considered options

**Keep trust on first use through the relay as the last resort, labelled.** This is what the
corpus did. Rejected: the party trusted is the relay, which on the default path is the
publisher, which already serves the bundle — so the last resort concentrated the first contact
of every such machine in the one party the design most needs to keep out of content.

**Keep the keyed rescue login for a cloud machine whose introduction never arrived or whose
pin was lost.** Rejected with the route it was an instance of. Recreating costs a machine's
state; logging into a system whose key nothing can check costs whatever is placed on it next.

**Have the publisher run the jump hosts.** Rejected: that is the relay's own operator standing
in a second place. The route exists to take that party out of the first contact.

**Let a session create the jump host**, through its own vendor credential or an untyped vendor
scope. Rejected: a model that writes a machine's boot configuration, chooses its image or
holds a credential that can rebuild it has touched it, and a jump host a model has touched can
alter the first contact of the machine behind it. The jump host is model-free by construction
or it is nothing — creation composed by harness code, in a flow that is not a session, with
keys and a vendor identity no session holds.

**Reuse one jump host** for several machines, or for the machines of one set. Rejected: a
model with root on the first target could attack the jump host over the network while it
serves the second. One jump host serves one first contact and is destroyed.

**Run the jump host under the target's vendor identity.** Rejected: a session that can reach
the target's account through the vendor's API can then reach the jump host through it —
console, rebuild, password reset. The identities are separate, and until one can be derived
(`OPN-26`) the route needs a separately supplied credential or is unavailable.

**Describe the result as pinned out of band.** Rejected. The outer session is; the target's
key is not. The display says the first contact was trusted through a jump host at a named
vendor, and keeps saying it after the jump host is gone.

**Take the pin from the jump host and stop there.** Rejected for a second look on another
path: the first direct connection through the relay must present the same key. A substitution
then needs one party on both paths, which leaves the target's own vendor, its last-hop network,
or the jump side together with the relay.

**An operator-entered fingerprint for a machine that already exists.** Noted and not taken up:
nothing in the stages calls for it yet.

## Consequences

**A jump vendor is a new elective party, and is paid for.** It must be paid in Bitcoin and
need no account, or it reintroduces the billing relationship the general case was escaping.
The first candidate is unprobed (`OPN-24`). A jump host that lives for minutes costs whatever
that vendor's minimum billing period is.

**Attest becomes load-bearing twice.** It is the first stage's first contact, and it is how a
jump host at a vendor with boot-time user-data is pinned. It has never run on a real first
boot (`OPN-3`).

**The residual is stated in full and shown.** `CHN-R6` lists it, common mode included: one
jump vendor introducing machines at several target vendors is one party at the first contact
of all of them.

**The cloud path has no route for a machine the harness cannot create or reach this way.** A
maintained cloud machine whose pin is lost with no sheet is destroyed and recreated
(`STA-15`). Under the current rules a jump host cannot re-pin it: `CHN-R6` serves a vendor
with no route of its own, and a weaker mode is never entered because a stronger check failed
(`SEC-14`). Whether a later rule should allow it is not decided.

**The formal companion carries none of this yet.** Its pin sources are the dedicated path's;
a jump-host source is owed with the route (`TASKS.md`).
