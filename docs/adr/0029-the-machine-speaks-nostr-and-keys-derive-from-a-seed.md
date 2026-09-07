# The machine speaks Nostr, and per-machine keys derive from an operator seed

A machine introduces its host key to the browser as a **gift-wrapped Nostr event** — a NIP-44
seal under a per-machine sender key, wrapped to a per-machine recipient key, published to a
relay set the publisher's own Nostr relay anchors. Both keys, and every machine's SSH client
key, **derive from a seed the operator holds**, so the browser stores none of them and
re-derives any of them on demand. The channel this opens is a **notify channel**: a machine may
tell the harness something, what it tells is an observation, and attest is its only use.

`CHN-R5`, `CHN-4` through `CHN-7`, `CHN-17`, `CHN-18` and `STA-22` are the operative
statements. This record holds why, what it replaced, and what it costs.

## The problem this addresses

The previous attest design generated a random one-time secret, planted it in user-data, and
had the machine post an HMAC of its fingerprints to a drop-box at the relay. Two of its own
rules collided. The secret had to be **redacted from anything recorded**, because possession of
it lets an actor stamp any fingerprint the browser will trust. And the record is what survives
a phone lock — the design's stated normal case. So through the minutes between creating a
machine and receiving its post, the secret had nowhere to live: keep it in memory and a lock
destroys the machine; write it down and the credential rule is broken. The requirement also
referred to a deadline "inside the voucher's expiry" — a relation between two numbers, neither
of which existed anywhere.

A derived key dissolves the first problem outright: nothing is stored, so nothing is lost. The
second turned out to be a confusion about where the clock is, and is answered below.

## What was verified before deciding, 2026-09-06

**The first-boot pipeline works from a script with no terminal.** One tool builds the seal,
gift-wraps it, publishes to several relays and returns one exit code; the agent that checked it
published to three public relays and read the wrap back. Two traps surfaced only by running it:
standard input must be redirected from the null device explicitly, because a *closed*
descriptor crashes the tool; and gift-wrapping must be told to use the identity keys directly,
or it spends seconds on the network looking up optional keys before anything else exists.

**On Alpine there is no binary to download.** The upstream release is glibc-linked and fails on
musl. A static build is possible and was made. That build is therefore an artifact the
publisher ships, pins under `ARC-25` and signs under `TRU-E7` — about thirty megabytes at first
boot. On NixOS it is a distribution package, admitted as everything there is (`ARC-25a`). The
two distributions diverge on this exactly as they diverge on artifact trust.

**The recipient is not hidden from a relay, and on public relays not from anyone.** Gift wrap
hides sender, content and real timestamp; the recipient's key is in the outer event's routing
tag by design. The standard asks relays to serve those events only to the authenticated
recipient. Three of four public relays tested do not, so anyone can list every wrap addressed
to a key. Content stays encrypted. Existence does not.

**Timestamps are meaningless for expiry.** The outer layers are deliberately randomised up to
two days into the past. Any window must run off the browser's own clock from machine creation.

**The derivation path carries an upstream warning.** NIP-06 — BIP-32 by account index from a
BIP-39 mnemonic — is now labelled *unrecommended* in favour of a single key. That is a warning
about wallet interoperability. Nothing outside the harness ever needs to reproduce these keys,
so it does not apply, and it is cited with the label rather than without.

**The browser side compiles.** The Rust Nostr crates build for wasm32 with derivation,
encryption and unwrap, and speak WebSocket through the browser. Their README calls them alpha.
Same posture as the SSH client: a known-good configuration to pin, not a library to trust by
name.

## What the seed does and does not remove

**It does not remove the secret in user-data.** The machine has to prove it read *this*
machine's boot configuration, or the first message from any key claiming to be machine 3 is
trust-on-first-use with extra steps. Anyone can encrypt to a public key. So a per-machine
sender key still rides in user-data, where the vendor sees it and the metadata endpoint serves
it for life — and it is harmless there for the reason the old secret was: the browser accepts
one introduction from it and never listens for it again. This is a **private key in user-data**,
which is the sentence that killed route 3, and the distinction that lets it live is what the key
*authorizes*. A host key impersonates a machine for life. A sender key introduces it once.

**It removes everything the browser had to remember.** Sender key, recipient key and SSH client
key all re-derive from the seed and the machine's index. The recovery sheet stops carrying keys
and carries only what nothing derives — pins, the ledger, the inference balance.

## Considered options

**Store the random secret encrypted at rest, redacted from the journal.** The minimal fix to
the collision, and the one this record would have taken on its own. Rejected once a derived
key was on the table, because it adds a row that exists only to be deleted minutes later,
while the seed removes rows.

**Memory only, accept the loss.** Simplest, nothing new at rest. Rejected because it makes the
design's own stated normal case — the phone locking — destroy a machine on the one route that
has no alternative.

**A seed scoped to attest only.** Derive the introduction keys and nothing else; leave the sheet
as it was. Rejected as a strange object: a seed that re-derives every per-machine credential is
the recovery model this audience already understands, and one that re-derives only the
introduction keys is a seed that does almost nothing at a full seed's cost of ceremony.

**The operator's existing Nostr identity as recipient.** Natural, since many in this audience
have one. Rejected because the recipient key goes into user-data, which is a persistent identity
readable by the vendor and by any guest on a multi-tenant machine — linking a cloud VM to a
person. The old random secret linked to nobody. Recipients are harness-derived and per machine,
so machine 1's user-data says nothing about machine 2 and an inbox that anyone can list maps to
one machine and not to an operator.

**Public relays only, no relay of our own.** Maximally resilient and no new operator burden.
Rejected because first boot is the one message with no other route, and three of four public
relays tested serve a recipient's inbox to anyone. The publisher's relay is mandatory and
authenticates readers; public relays are an operator's addition and a named party.

**Keep the drop-box and only change the key.** Retains a custom protocol at our relay that
standard inboxes make unnecessary. Rejected: the point of the change is fewer things of our own
to get right at first boot.

## Consequences

**`ARC-1` widens by one sentence and stands.** A machine may send the harness an event, and an
event is an observation — typed untrusted, never gating, never acting, exactly as every
box-plane output already is. A machine that can *tell* the browser something is not a machine
that can *make* it do something. The list of uses is one entry long, and each addition is a
stated design change. Candidates exist and none has been added.

**`SEC-5` gains a seed row and loses a token row.** The seed is the browser's root and is never
seen by a session or a machine; the derived keys are what sessions and machines see. Row 3's
origin becomes *derived*, row 7 becomes the sender key, row 8 retires, row 16 is the recipient
key.

**ADR-0020's title is half right, and it says so.** The vendor account still roots inventory.
Credentials root in the seed. Both are stated, and neither does the other's job.

**Replace is a new seed.** A stolen seed is not revocable — a thief who unlocks the store has it
— so the flow that answers a lost phone generates a new one and removes the old keys from every
maintained machine during re-entry. Same flow as before, different origin for the new keys, one
more thing to back up again.

**The sheet becomes less dangerous and its warning changes.** It no longer reaches any machine.
It spends the inference balance, which is now the most valuable thing in it, and the export
screen says that rather than inheriting the old warning.

**A machine's derivation index is journaled before creation and never reused.** The same index
on two machines is the same client key on two machines, which is `SEC-1` broken by bookkeeping.
`CNF-72` tests it.

**The relay's duties drop from three to two, and a second service appears beside it.** The
Nostr relay shares the host and the operator and nothing else. "The relay" means the TCP
bridge; a Nostr relay is always called that in full, because a sentence that says "the relay"
about an inbox is wrong.

**The only clock is the browser's.** Nothing on the machine can expire anything, and event
timestamps are randomised by design. The window runs from machine creation on the browser's own
clock, is set from a measured slowest first boot, and ends in a named fallback. The machine's
deadline is when to stop retrying and scrub.

**Two parties are named that were not.** The publisher's Nostr relay is `TRU-A2` learning what
it already learns by another route. A public relay the operator adds is `TRU-E10`.

**The first-boot tool is an artifact on one distribution and a package on the other.** Which is
one more instance of the split ADR-0027 already records.
