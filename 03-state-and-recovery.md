# 03 — Durable state and recovery

Two halves of one problem. **State** is what survives the worker being killed while the
phone is in the operator's hand. **Recovery** is what survives the phone being lost. The
decisions are in [ADR-0022](./docs/adr/0022-durable-state-is-an-append-only-journal.md) and
[ADR-0020](./docs/adr/0020-recovery-roots-in-the-vendor-account.md).

## Durable state

**STA-1** A single **harness worker** MUST be the only writer of durable state. Tabs,
command workers and adapters submit observations and requests; they do not mutate canonical
state.

**STA-2** Canonical state MUST be an **append-only event journal** with replayable
transitions, held in origin-private storage. Content-addressed with periodic compact
snapshots; in-memory state is authoritative only while a worker is running.

**STA-3** A canonical event MUST be durably appended **before** it is applied to in-memory
state. If the append fails, the transition does not occur.

**STA-4** A side-effecting call MUST have a durable record, an approval decision, and an
idempotency identity **before execution begins**. For an off-machine call this is `SEC-12`;
for box-plane work it is the per-command record of `ARC-8`.

**STA-5** Every tool MUST declare its retry safety: pure, idempotent with a key strategy,
reconcile-before-retry, or never-retry-automatically.

**STA-6 Box-plane work is never-retry-automatically.** Arbitrary shell on a remote machine
cannot declare itself idempotent, so no honest declaration other than this exists. Its
recovery path is `ARC-10`: reconnect, read the machine's state, converge.

**STA-7** After a crash the worker MUST acquire its lock, load the latest snapshot, replay
subsequent events, classify incomplete calls, cancel those that cannot still exist,
reconcile or surface uncertain ones, and resume only where policy permits. **No model turn
is silently resumed from an uncertain destructive operation.**

**STA-8** A call that may have produced an external effect but has no terminal event MUST
enter an unresolved state requiring evidence or operator inspection to leave. It MUST NOT be
retried automatically and no timer may clear it. Establishing *what happened* by a status
query is permitted and required where a tool supports one; doing it *again* is not.

**STA-9 The journal records what was sent, not what the machine did with it.** This is the
honest limit of `STA-2` across the channel. A phone that locks mid-install kills the worker
and the SSH session with it; on reconnect the journal knows exactly which commands were
transmitted and nothing about which completed. Four outcomes are indistinguishable from the
journal alone: never arrived, started and died with the session, **still running**, or finished
with the output lost. Re-running is safe for three of them and is the corruption case for the
third.

**STA-20 Every box-plane command runs as a tracked job**, and on an installed system the
machine keeps a record on persistent disk (`/var/lib/tau-web/jobs`, root-only) holding:
the **command as received**, its output, its exit code once it has
one, and enough to tell whether **the command itself** is still alive. On reconnect the session
reads that record rather than guessing — exit code present means finished, the command's own
process alive means wait. A record with no exit code and a proven-ended command means it
died and `ARC-10`'s convergence applies. A missing record is unresolved, never proof of death.
Record the boot identity with the job; a PID from another boot cannot establish liveness.

***"It" is the command, not everything the command started.*** A command that launches a daemon
finishes when the command finishes; whether the daemon it started is still up is a **service**
question, and services are `ARC-39`'s delivery declaration, which already distinguishes a tenant
needing a daemon *"enabled and surviving every reboot"* from one whose node *"dies on the first
reboot by design"*. Reading `STA-20`'s liveness to cover the spawned tree would duplicate that
requirement and cost the corpus its only non-POSIX dependency — because POSIX has no way to
observe a process that has left its session (`OPN-22`, closed on this reading). The job record
tracks the command; service lifecycle is declared, checked and owned elsewhere.

*Uniformly, rather than only for commands somebody marked long.* Nobody can reliably predict
which command is slow — a package install is ten seconds most days and ten minutes when a
mirror is struggling — and the mispredicted one is precisely the command that outlives its
session. Removing the prediction removes the failure. `ARC-7` already pays a round trip per
command, so the marginal cost is small against latency already being spent.

**STA-20a Output MUST be captured by redirection to a file, never by reading a pipe the job
holds open.** A command that starts a background process leaves that process holding the pipe's
write end, so a reader blocks until *the background process* exits rather than until the command
does. Measured on both declared distributions: a command that prints and exits immediately
returns after twenty seconds when captured through a pipe and immediately when redirected to a
file. This is not a liveness subtlety — it is `STA-20`'s "its output" field hanging, and it
inverts the failure mode in the damaging direction, since the record then reads *still running*
indefinitely and `CNF-40` requires the returning session to wait on exactly that.

**No orphan test may rest on a reparented process's new parent.** Verified: an orphan reparents
to PID 1 on one declared distribution and to a user-level subreaper on the other, so `PPID == 1`
is precisely the kind of check that is false on the other distribution.

The mechanism is POSIX and holds no init-system opinion, because `ARC-24` declares two
distributions with different init systems and anything specific to one would be false on the
other. That is a real constraint and a satisfiable one **precisely because `STA-20` tracks the
command**: a command's own process stays in the wrapper's process group and is observable by
ordinary POSIX means on both distributions. The wider reading — following a daemon that has
called `setsid()` out of its session — is what POSIX cannot do, and it is the service question
`ARC-39` owns rather than a gap here (`OPN-22`). **Jobs may be hosted inside a terminal multiplexer** so a human can attach and watch a
long install — useful during `STG-2`'s by-hand rehearsal — but that is an observation
convenience and never the record. On the installed system the files survive a reboot; the
recorded boot identity establishes that the old command ended, but not whether it succeeded.

**STA-20b Rescue installation has a bounded exception to disk persistence.** Its tracked
jobs live in root-only `/run/tau-web/jobs` in the rescue system, outside every installation
disk. They survive an SSH disconnect, not a reboot. Each record carries the rescue boot ID
(`/proc/sys/kernel/random/boot_id`), the browser's command ID and the command fields of
`STA-20`. The wrapper runs detached from the SSH connection, captures output to files and
refuses to launch an existing command ID again within that boot. A reconnect checks this
record before issuing more work; a still-running job is waited on, including during partitioning.

Before a planned reset, the harness stops dispatch, waits for all tracked commands to end,
copies their records into the encrypted browser journal as **advisory observations**, and
durably records installed host-key pins and the reset intent. If collection or the durable
append fails, it does not reset. On installed-system entry it creates the persistent job
directory before ordinary work. Rescue records are not claimed to survive this transition.

After an unexpected rescue reboot, a changed boot ID proves the old command cannot still be
running; it does **not** prove its effects or exit status. Missing output, a missing job record,
or a record from the old boot leaves the operation unresolved under `STA-8` until inspection
supports convergence or the operator explicitly chooses a new destructive reinstall. The
browser's record of what was sent remains authoritative throughout (`STA-21`).

**STA-21 The job record is machine-reported and advisory.** The browser journal is authoritative
for what was **sent** (`STA-3`, `ARC-8`); the machine's record says what it **received** and what
happened next. Comparing the two catches truncation, quoting damage and a mangled multi-line
command — the honest-mistake class, and a real one. It catches nothing against a machine that
lies, because such a machine writes whatever it likes. This stands exactly where the
deterministic verifier stands and MUST NOT be reported as more (`SEC-2`).

## The exposure ledger

**STA-10** The **exposure ledger** is the per-machine history of every configured model that
has ever touched a machine. It is how `SEC-1`'s permanence clause is tracked, it lives in the
encrypted-at-rest store, and it is exported in the recovery sheet.

**STA-11 The ledger's staleness rules bind only a tenant that is both maintained and
threshold-bearing, and none currently is.** The two halves cancel, and stating so keeps an
implementer from building machinery that governs nothing:

- Where exposure **matters** — a tenant with a threshold — btc-policy **seals** its machines,
  so nothing re-enters, so the ledger is complete when setup ends and never changes again. A
  recovery sheet's snapshot is therefore always current.
- Where the ledger **drifts** — a maintained machine, re-entered by later sessions — there is
  no threshold, so nothing depends on the count. One machine has no collision to display.

For a tenant that is both, which is possible and does not yet exist, the rules below apply.
They are recorded rather than deleted for that reason.

**STA-12** A restored ledger is a **floor, not a census**. The sheet records its export time;
the app requires a re-export whenever the ledger mutates; and a restored ledger is displayed
"as of" its export. Where it may be stale, re-entry binds only a configured model not
currently assigned to any other machine.

**STA-13** A machine recovered *without* a ledger carries **unknown past exposure**, displayed
as such, and re-entry then binds only a configured model not currently assigned to any other
machine — the conservative reading, since the unknown history could contain any of them.

## What survives a lost phone

**STA-14** The operator's **vendor account is the recovery root**. It survives because it
lives in their head or their password manager and is recoverable through the vendor's own
processes, and it is the one party that always knows which machines exist.

| Dies with the phone | Survives |
|---|---|
| Host-key pins | The vendor login |
| The machine inventory | **The seed** — in the operator's head or seed backup, never on the phone alone (`STA-22`) |
| Action transcripts | **The SSH client keys, re-derived from the seed plus allocation metadata** (`STA-22b`) |
| Provenance records | **The relay pass**, if its relay address and derivation index were exported (`STA-22b`) |
| The exposure ledger | The app URL |
| | The recovery sheet, **if exported** |
| **The inference account credential**, unless exported: it is bearer, there is no account behind it, and nothing re-derives it | The inference balance — **only** through the sheet (`SEC-5` row 14) |
| The vendor API credential and the session inference key — re-supplied or re-minted per session, deliberately not persisted | |

**Transcripts and provenance are gone and stated as gone.** They were records, not secrets;
nothing re-derives the past.

**STA-22 The operator holds a seed, and every per-machine credential the browser needs derives
from it.** A BIP-39 mnemonic, held encrypted at rest and backed up by the operator the way
this audience already backs up seeds. For machine *m*, the browser derives at index *m*: the
SSH client keypair (`SEC-5` row 3), the attest sender key (row 7) and the attest recipient key
(row 16); and for relay pass *n*, on its own branch, the relay key (row 4). A tenant whose
handoff slot declares a credential also derives one **post-harness credential** (row 17)
on its own branch. Derivation is the versioned, role-separated contract in `STA-22a`; an
implementation must not choose paths independently.

- **No session and no machine ever sees the seed.** What machine *m* receives is its client
  public key, its sender private key, its recipient public key, and — where the handoff slot
  declares that machine a target — the post-harness credential's *public* key: values nothing
  derives *from*. `SEC-1`'s cryptographic enforcement is untouched: machine 3 still holds
  machine 3's public key alone.
- **A machine's index is journaled before the create call and never reused.** The same index
  on two machines is the same client key on two machines, which is `SEC-1` broken by
  bookkeeping. `STA-3` already requires the record before the effect; the index is part of
  that record, and indices are monotonic.
- **The sheet no longer carries keys.** It holds allocation metadata, pins, the ledger and
  the inference account credential (`STA-16`). The seed reconstructs a key only when its role
  and index are known. Seed-only recovery does not discover indices or relay purchases.
- **A stolen seed is not revocable.** Replace (`STA-17`) is therefore a **new seed**, from which
  new client keys derive, with the old public keys removed from every maintained machine during
  re-entry — the same flow as before, with a different origin for the new keys and one more
  thing to back up again.

*What this reverses.* ADR-0020 rooted recovery in the vendor account and rejected a seed-shaped
root by omission; the sheet existed because nothing re-derived the client keys. The vendor
account still roots **inventory** — it is the one party that always knows which machines exist.
The seed roots **credentials**. Both are stated, and neither does the other's job.

**STA-22a Credential format v1 is normative.**
[`docs/design/credential-format-v1.md`](./docs/design/credential-format-v1.md) fixes mnemonic
handling, hardened derivation paths, role numbers, key encodings and known-answer vectors.
Every allocation and recovery export records that version. Unknown versions are refused;
an upgrade never silently reinterprets an existing identity. The seed is a dedicated harness
seed, never an existing wallet or social-identity seed.

**STA-22b Allocation metadata is recoverable state.** The journal owns a seed identifier,
derivation version, next unused index for each role family (machines, passes, handoffs),
and allocated entries, including tombstones for failed or destroyed allocations. A machine
entry maps vendor/account reference and immutable vendor machine ID to its index and expected
SSH public key; a pass entry maps relay URL and public key to its index; a handoff entry
maps tenant and handoff ID to its index. Machine roles share one machine index. Reserve it
durably before any external effect, including registering a key for an already-rented server.
All this metadata is included in `STA-16` exports, with an export time and journal sequence.

Import checks the seed identifier, derives each listed public key and compares it, validates
unique indices within each family and next-unused counters above all listed indices, and
cross-checks vendor inventory before binding machines. A stale sheet cannot prove the latest
counter. Therefore **a seed imported after loss of the canonical journal may restore listed
identities but MUST NOT allocate new ones**, even when the sheet claims to be current. To
allocate again, use Replace with a freshly generated seed; old records are retained until
migration is complete. This restriction also applies to an imported local-store backup.
Existing identities remain usable during non-revoking Restore.

With no sheet, or for machines missing from a stale sheet, Robot recovery installs keys from
a fresh seed through vendor-authenticated rescue and re-reads host pins; it does not guess old
indices. Cloud uses `STA-15`'s explicit fallback. A pass whose metadata is missing cannot be
discovered or revoked from the seed alone: it must expire, its remaining quota may be lost,
and a new pass uses the fresh seed. Neither vendor inventory nor the publisher is an index
backup service. Export is recommended after each allocation, including on dedicated.

**STA-23 The local store has an explicit unlock boundary.** The operator chooses a local
passphrase, separate from the seed backup and the recovery-sheet passphrase. A random data
key encrypts the journal, snapshots, seed, pins, ledger and inference account credential;
only a passphrase-wrapped data key persists. The v1 envelope, KDF and authentication rules
are defined in the credential format. There is no plaintext or device-synced fallback.

The harness worker alone unwraps and holds the data key and seed. The UI passes the
passphrase once and clears its input; it never receives the unwrapped data key. The mnemonic
may be displayed only in the dedicated seed-backup ceremony, outside session/model context.
Key derivation gives a session only its permitted child credentials. Explicit lock, page
hide/backgrounding, or worker shutdown stops dispatch, ends session workers and closes
channels; the worker clears its keys and credential buffers and returns locked. No unload
callback is relied on for journaling. A killed worker restarts locked; after unlock it follows
`STA-7`, requiring memory-only credentials to be supplied or minted again. Clearing buffers
is best effort in a browser, not a claim of physical memory erasure. Wrong passphrases,
tampered envelopes or unsupported versions fail closed without creating a replacement store.
Lost local passphrases require seed/sheet/vendor recovery; the publisher cannot reset them.

## Recovery, by access model and vendor

```mermaid
flowchart TD
    LOST([New phone, no local state]) --> AM{Tenant's access model}
    AM -->|Sealed| SEALED["Nothing to recover.<br/>The channel ended at sealing,<br/>so a lost pin loses nothing"]
    AM -->|Maintained| VEND{Which vendor product?}
    VEND -->|Dedicated / Robot| CER["Rescue ceremony<br/>register the new phone's client key ·<br/>activate rescue · pin the rescue host key<br/>from the API, no TOFU · install the new<br/>client pubkey from inside rescue ·<br/>re-read the installed host keys<br/><br/>Cost: two reboots. Always works,<br/>so the sheet is optional here"]
    VEND -->|Cloud| SHEET{Was a sheet exported?}
    SHEET -->|Yes| ZERO["Seed re-derives client keys ·<br/>sheet restores pins. Zero downtime"]
    SHEET -->|"No — MUST NOT happen:<br/>the sheet is mandatory<br/>on maintained cloud"| TWO["Two honest options"]
    TWO --> DR["Destroy and recreate<br/>re-runs attest. Loses machine state"]
    TWO --> KR["Keyed rescue, leap of faith displayed<br/>the login is keyed, but the rescue<br/>host key is unverifiable (CHN-R2 is dead).<br/>The screen says trusted, not verified"]
    classDef good fill:#e8f5e9,stroke:#4a7c59
    classDef bad fill:#ffebee,stroke:#a54a4a
    class SEALED,CER,ZERO good
    class DR,KR bad
```

**STA-15** The recovery sheet MUST be exported before a **maintained cloud** machine's setup
completes. On Robot the ceremony always works, so there the sheet is an optimisation and
stays optional. A sealed tenant's machines need none: their pins die at sealing, and a phone
lost mid-setup is answered by the tenant's own all-or-nothing rule — abandon and recreate.
This asymmetry is stated, not smoothed over.

**STA-16** The recovery sheet holds the allocation metadata of `STA-22b`, host-key
fingerprints, the exposure ledger, and — on the
procured path — the **inference account credential**, wrapped under a passphrase the operator
chooses. **It no longer carries the SSH client keys**, which re-derive from the seed
(`STA-22`). The export screen MUST say what the sheet can do in the wrong hands with the
passphrase: **spend the remaining inference balance**. Reaching a machine needs the seed, and
the seed is never in the sheet.

**The balance is in the sheet because the alternative is worse, not because it is comfortable.**
The account credential is bearer and unrevocable (`SEC-5` row 14), so exporting it raises the
value of a stolen sheet. Leaving it out means a lost phone burns whatever the operator funded,
with no recovery path at all. Now that the keys have moved to the seed, the balance is the
**most** valuable thing in the sheet rather than an addition to something worse, and the screen
must say so plainly rather than inheriting the old warning.

**STA-17** Recovery after a *lost* phone revokes; restore after a *dead* one may not. A
stolen phone's encrypted store may eventually be unlocked, so the flows are named and
distinct, and the screen says which one is happening:

- **Replace** (the default, for a phone that is lost): a **new seed** (`STA-22`), from which
  new client keypairs derive; the old public keys removed from every maintained machine during
  re-entry; the old relay pass revoked by its own key's signature and a new pass bought against
  a key from the new seed. The old seed is not revocable — a thief who unlocks the store has it
  — which is why the keys it derives are removed from the machines rather than merely stopped
  being used.
- **Restore** (for a phone that died in hand): the same seed re-derives the same keys,
  explicitly presented as non-revoking.

**Direct Replace needs both seeds and the old allocation metadata, and MUST say so before
it starts.** Re-entering a machine to remove
the old key uses the old key; revoking the old pass is signed by the old key. Both derive from
the seed being retired, so the operator needs its backup *during* Replace and abandons it after.
If the old seed or an index is missing, direct re-entry and pass revocation cannot finish.
Robot machines can still be rekeyed through vendor-authenticated rescue (`STA-15`); cloud
machines require that section's explicit fallback. The screen names unrecovered machines
and unrevocable passes, and never reports a complete Replace while either remains outstanding.

**Replace cannot cover the inference account credential, and MUST say so.** Every other item in
the flow has an issuer that can kill the old value; this one has no account behind it, so there
is nothing to revoke against (`SEC-5` row 14). What Replace *can* do is revoke every session key
minted from it and mint no more — which stops the harness's own use and does nothing about a
thief's. The only real remedy is to spend the balance down or move it, and the screen should
offer that rather than implying the Replace flow handled it.

**STA-18** Inventory recovery makes the vendor list authoritative. Listing the account is how
a new phone learns what exists. That listing is performed by the deterministic recovery flow
under the operator's approval, **before any session exists**, so it is not a session
operation and `SEC-4`'s machine-binding rule for typed operations is not in play.

**STA-19** Transcript retention has no policy yet. A maintained machine accumulates command
records for its whole life in an encrypted store on a phone, and nothing states when they
compact or expire. `OPN-19` tracks it.
