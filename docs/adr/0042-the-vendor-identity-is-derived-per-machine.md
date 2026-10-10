# The vendor identity is derived per machine

Decided 2026-10-09, for stage 1's typed LNVPS adapter and every later use of a derived vendor
identity. It amends [ADR-0020](./0020-recovery-roots-in-the-vendor-account.md). The rules
belong to `SEC-5` row 22 (the role), `STA-22a` and the credential format (its derivation),
`STA-17` (Replace) and `STA-18` (inventory recovery); until they are amended they keep their
present text, and this record is what they will carry.

## Amended 2026-10-10: order over HTTP after email verification

The unique-address premise in the original ordering paragraph below was wrong. A code read
of LNVPS migration `20260220165223_email_verification.sql` found that it dropped the unique
email-address index and recreated it as a plain index. The live server's acceptance of one
operator address on separate accounts has not been checked. Stage 1 accepts that limit and
uses the operator's same address to verify each per-machine account before ordering over HTTP.
For the adapter sequence and invoice provenance, see `STG-21` and `ARC-30`.

This accepts that the shared address links the operator's machines at the vendor, and that an
HTTP order records the buyer's IP address and country (`TRU-E1`;
`docs/findings/2026-10-08-lnvps-research.md` §3). It does not make the derived credential
available: T44 still owes the coordinated format and recovery amendment; `SEC-5` row 22
still says "not derivable today". The per-machine derivation and recovery decisions below
remain in force.

## What was decided on 2026-10-09

At LNVPS the credential is a Nostr key: every call is signed with it (NIP-98), and the key is
the account. Stage 1's adapter derives that key from the seed, **one per machine**: role 5 at
the machine's own index, a secp256k1 secret used as a BIP-340 x-only key, interpreted as roles
1 and 2 are. A key reaches only its own machine, which is the property `SEC-4` names as best
practice ("a vendor identity derived per set"), held per machine rather than per set. A jump
host has its own machine index, so its identity is separate from its target's with no further
rule, and a later session re-derives the same key from the index.

**The following ordering paragraph records the superseded 2026-10-09 choice; it is not a
current stage-1 instruction.** LNVPS refuses an HTTP order from an account with no verified
email address, and an address belongs to one account only, so an account per machine would need a distinct verified address
per machine. **Orders therefore go through LNVPS's NIP-90 job interface**, which checks no
email. Status, the published host keys, listing, stop and reinstall go over HTTP, signed by the
same key; none of those checks email. A job reply counts only when signed by the service key
the vendor publishes over TLS, so the Nostr relays carrying it can withhold a reply but not
forge one. The invoice the operator's wallet pays is read over TLS from the vendor where its
renew route serves one, with the signed reply's amount as a cross-check, and is otherwise the
signed reply's invoice. As read on 2026-10-09 the job
handler orders zero addresses, which the vendor's only plan refuses; stage 1 waits until that
is fixed.

## What it costs, and how recovery keeps working

**At this vendor the two recovery roots become one.** ADR-0020 kept the vendor account, which
roots inventory, apart from the seed, which roots credentials. With a seed-derived vendor key,
whoever holds the seed holds the account too: stop, renew, and reinstall, which wipes the disk.
A lost seed loses both.

**Replace carries the key forward.** LNVPS cannot change an account's key or move a machine
between accounts. Replace derives each machine's old role-5 key once more and keeps that key
alone, encrypted in the new local store, never the retired seed. It states that the retired
seed's holder shares control of the vendor account, and offers a rebuild under the new seed:
the treatment Replace already gives the inference credential it cannot revoke. The rebuild is
a new order under the new seed's key, since a reinstall leaves the machine in the account the
retired seed controls.

**Inventory is found by scanning ahead.** With an account per machine there is no single
account to list. On Restore the harness derives role-5 keys for a bounded number of machine
indices past the sheet's counter, as a wallet's gap limit does, and lists each; a non-empty
listing is a machine, or a jump host, to recover. The machine index is shared by every vendor's
machines, so an index counts as used when any vendor shows a machine at it; only an index no
vendor shows, such as a failed allocation's, counts toward the gap. The scan allocates nothing,
but it is not read-only at the vendor: each probed key leaves an empty account row there.

## Alternatives considered

| Option | Disposition |
|---|---|
| **An operator-supplied key** (`SEC-5` row 1) | Rejected. It keeps ADR-0020's roots apart and changes no format, but the operator must keep and supply a key the seed cannot recover. |
| **One derived key per vendor account** | Rejected. One account and one address, but the key reaches every machine in the account. |
| **Derived per bound set** | Rejected. A bound set is one session's, so a re-entry would derive another account and not see its machine. |
| **Automating a throwaway mailbox** | Rejected. A new third party, a mailbox credential and an off-machine call, to click one link. |
| **NIP-90 ordering for stage 1** | Rejected on 2026-10-10: the order path refuses every order (`docs/findings/2026-10-09-lnvps-nip90-probe.md`, LNVPS/api#422), and it adds Nostr relays as parties. It may return later. |
| **Rebuild every machine at Replace** | Rejected. A month's rent per machine, and a risk to the application's data. |
| **Keep the retired seed for vendor operations** | Rejected. Replace ends with the retired seed abandoned (`STA-17`). |
