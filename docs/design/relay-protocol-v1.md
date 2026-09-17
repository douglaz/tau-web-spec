# Relay protocol v1

Normative companion to `CHN-15`, `CHN-16`, `CHN-16a` and `CNF-87`. The TCP bridge the browser
opens to reach a machine or a vendor API (`CHN-9`). Three messages, then bytes. The publisher
builds the first-stage relay to this note (TASKS T27).

## Destination

The destination rides in the WebSocket URL path: `wss://<relay>/v1/tcp/<host>/<port>`.

- `host` is a DNS name (lowercase, IDNA A-labels, no trailing dot) **or** a numeric address in
  canonical text form: dotted decimal IPv4, or RFC 5952 IPv6 without brackets. Nothing else:
  no percent-decoding, no scope identifiers, no alternate numeric spellings.
- `port` is a strict decimal integer, 1–65535, no leading zeros.
- Anything that does not parse is refused before any other check, with close code 1008.

One grammar, so the authorization check and the dialer cannot parse the same string
differently. After parsing, `CHN-16a`'s normalization and refusal rules run on the result.

## Handshake

1. **Challenge.** On open, the relay sends one text frame: a JSON object
   `{"challenge": "<32 random bytes, base64url>", "relay": "<relay URL>"}`. The challenge is
   fresh per connection and never reused.
2. **AUTH.** The browser answers with one text frame: a NIP-42-shaped event signed by the relay
   key (`SEC-5` row 4, `STA-22` role 3): kind 22242, tags `["relay", "<relay URL>"]`,
   `["challenge", "<challenge>"]`, `["destination", "<host>", "<port>"]`, `created_at` within
   `relay.auth_skew` (`bundle/timing.toml`) of the relay's clock, signature BIP-340 over the
   NIP-01 event id. The destination tag must equal the URL path; a mismatch is refused.
3. **OK or close.** The relay checks, in order: the event shape — kind 22242, the relay tag
   naming this relay, `created_at` within skew, one destination tag equal to the path — then
   signature and challenge match; the key has a
   pass that is unexpired and not revoked; the destination is in that pass's recorded set
   (`CHN-16`: the record *is* the authorization); `CHN-16a` admits the address; the pass's
   pacing and window cap allow a dial now (`bundle/timing.toml`). All pass: the relay dials,
   and once the TCP connection is up sends one text frame `{"ok": true}`. Any failed check:
   one text frame `{"ok": false, "reason": "<auth|pass|destination|address|pace>"}` and
   close 1008, **before any dial**. A dial that fails after the checks passed: `{"ok": false,
   "reason": "dial"}` and close 1011. So OK means "authorized and connected"; the invariant
   `CNF-87` tests is that **nothing is dialed before the AUTH is accepted**.
4. **Bytes.** After OK, every frame in both directions is a binary frame carrying raw TCP.
   A text frame after OK, or a binary frame before it, closes the connection with 1002.
   Either side closing the socket closes the TCP connection.

A replayed AUTH fails at step 3 because its challenge is not this connection's. The relay
learns the destination and the key; it never sees plaintext, because the SSH or TLS session
inside the bytes is pinned end to end (`CHN-1`, `CHN-12a`).

## First stage

There is no purchase flow (`STG-18`). The publisher records the operator's relay public key,
its destination set and **an expiry** by hand — no hand-recorded pass is unbounded — and steps
1–4 are unchanged; `CNF-87` tests them: fresh
challenge, unknown key refused, replayed signature refused, undeclared destination refused,
private address refused, limits applied, and the two orderings of step 3 and step 4: **no dial
before the AUTH is accepted**, and **no application byte forwarded before OK**. They are two
invariants, not one: OK is sent *after* the dial succeeds, so "no dial before OK" — the shorthand
this section carried until 2026-09-16 — named an order the protocol does not have, and a relay
and a test could each satisfy it while enforcing different things.

## Not in v1

Multiplexing several TCP streams over one socket, DNS-name destinations resolved to more than
one address (v1 dials the first admitted answer and refuses if any answer is forbidden, per
`CHN-16a`), and the purchase and revocation messages of `CHN-15`/`CHN-16`, which arrive with
the paid relay.
