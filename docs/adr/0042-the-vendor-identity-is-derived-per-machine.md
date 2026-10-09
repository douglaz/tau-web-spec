# The vendor identity is derived per machine

Decided 2026-10-09, for stage 1's typed LNVPS adapter and every later use of a derived vendor
identity. It amends [ADR-0020](./0020-recovery-roots-in-the-vendor-account.md). The rules
belong to `SEC-5` row 22 (the role), `STA-22a` and the credential format (its derivation),
`STA-17` (Replace) and `STA-18` (inventory recovery); until they are amended they keep their
present text, and this record is what they will carry.

## What was decided

At LNVPS the credential is a Nostr key: every call is signed with it (NIP-98), and the key is
the account. Stage 1's adapter derives that key from the seed, **one per machine**: role 5 at
the machine's own index, a secp256k1 secret used as a BIP-340 x-only key, interpreted as roles
1 and 2 are. A key reaches only its own machine, which is the property `SEC-4` names as best
practice ("a vendor identity derived per set"), held per machine rather than per set. A jump
host has its own machine index, so its identity is separate from its target's with no further
rule, and a later session re-derives the same key from the index.

LNVPS refuses an HTTP order from an account with no verified email address, and an address
belongs to one account only, so an account per machine would need a distinct verified address
per machine. **Orders therefore go through LNVPS's NIP-90 job interface**, which checks no
email. Status, the published host keys, listing, stop and reinstall go over HTTP, signed by the
same key; none of those checks email. The invoice the operator's wallet pays is read over TLS
from the vendor, with the job reply's amount as a cross-check. As read on 2026-10-09 the job
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
the treatment Replace already gives the inference credential it cannot revoke.

**Inventory is found by scanning ahead.** With an account per machine there is no single
account to list. On Restore the harness derives role-5 keys for a bounded number of machine
indices past the sheet's counter, as a wallet's gap limit does, and lists each; a non-empty
listing is a machine, or a jump host, to recover. The scan reads and allocates nothing. Each
probed key leaves an empty account row at the vendor.

## Alternatives considered

| Option | Disposition |
|---|---|
| **An operator-supplied key** (`SEC-5` row 1) | Rejected. It keeps ADR-0020's roots apart and changes no format, but the operator must keep and supply a key the seed cannot recover. |
| **One derived key per vendor account** | Rejected. One account and one address, but the key reaches every machine in the account. |
| **Derived per bound set** | Rejected. A bound set is one session's, so a re-entry would derive another account and not see its machine. |
| **Automating a throwaway mailbox** | Rejected. A new third party, a mailbox credential and an off-machine call, to click one link. |
| **HTTP ordering behind one verified address, if the job interface fails** | Rejected. Stage 1 waits instead. |
| **Rebuild every machine at Replace** | Rejected. A month's rent per machine, and a risk to the application's data. |
| **Keep the retired seed for vendor operations** | Rejected. Replace ends with the retired seed abandoned (`STA-17`). |
