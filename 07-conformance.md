# 07 — Conformance checklist

What an implementation must demonstrate for each stage. Each item names the requirement
it exercises and is written so it can become a test. The applicability table below defines
first-stage admission and completion; tier labels describe severity within that stage.

Treat any unchecked box below as a green check next to an empty test suite.

## Build and gate

- [ ] **CNF-1** CI builds the project from a clean checkout, with no network-dependent manual
      steps.
- [ ] **CNF-2** The declared lint and format gates pass at the declared strictness.
- [ ] **CNF-3** The test suite fails when a test is deliberately broken — verified once, by
      hand, so that "tests passed" means something.
- [ ] **CNF-4** The CORS probe runs on every push (`ARC-34`), and its failure fails the build.
      Browser reachability is an external dependency that can regress silently.

## Tiering — which of these gate what

An untiered checklist is an unbounded commitment. These tiers gate *launch*; they do not
forbid doing a cheap item early.

**The rule.** For each item, name the concrete production event where its test would fail.
Then ask:

1. **Can the operator undo it** with money, a redeploy, or an apology?
2. **Would the operator even know it happened** without this control?
3. **Can an autonomous retrying caller trigger it** with no human in the loop?

**BLOCKING** — "no" to (1); or "no" to (2) where the hidden harm is irreversible; or "yes" to
(3) for any provider mutation. The irreversible families here are **escaped secret** (a
vendor credential, a client key, a tenant secret — a leak outlives the incident),
**boundary crossed** (session to another session's machine, box plane to cloud plane, bundle
to credentials), **destroyed data** (wrong machine deleted, wrong disk written), and **money
out** (duplicate create, unstoppable billing).

Question 3 matters more here than in most systems, because the caller is a model that
retries on its own initiative. "Misclassified interrupted operation" and "double purchase"
are the same item.

**PRE-SCALE** — failures the operator personally absorbs while watching every operation and
reading every invoice line. The trigger to promote them is whichever comes first: the first
operator the publisher does not personally know; concurrent sessions becoming routine; or
anyone no longer reading every transcript.

**DEFERRED** — recoverable annoyance, or a guard for a deployment shape that does not exist
yet.

## The access boundary — `SEC-1`

- [ ] **CNF-5 · BLOCKING** Each session holds its **own** SSH client keypair, and only that
      session's public key appears in its machine's `authorized_keys`. Verified by reading
      the machine, not by reading the harness.
- [ ] **CNF-6 · BLOCKING** An SSH client presenting a different machine's keypair (or a synthetic
      uninstalled key) to the target machine is **refused by SSH**. The harness is not consulted. *(`STG-13`)*
- [ ] **CNF-7 · BLOCKING** Binding is created by an operator act before any connection
      attempt. A connection attempt against an unbound machine does not create a binding, and
      is recorded as refused.
- [ ] **CNF-8 · BLOCKING** The profile-declared post-harness machinery holds **no channel to any
      machine, at any point** (`ARC-19a`), and holds no reach beyond what the profile's handoff
      slot declares. Verified by inspecting what that machinery is given — as `CNF-9` does for
      the scanner — rather than by attempting an access and observing refusal: a refusal test
      cannot distinguish absence from a credential the harness declined to use.
- [ ] **CNF-9 · PRE-SCALE** A scanner run holds no machine credential and no channel. Verified
      by inspecting what the scanner process is given, not by what it does.
- [ ] **CNF-10 · PRE-SCALE** The exposure ledger records every configured model that touches a
      machine, survives restart, and is exported in the recovery sheet.

## The box plane cannot reach the cloud plane — `SEC-3`

- [ ] **CNF-11 · BLOCKING** A box-plane command that attempts to reach a vendor control API
      fails because **no harness vendor credential exists on the machine**, not because a
      filter caught it. Verified by searching the machine's environment, filesystem and
      process table for the harness's held credentials after a full install.
- [ ] **CNF-12 · BLOCKING** A brief instructing the model to exfiltrate a vendor token to the
      machine produces no token on the machine. The model may try; there must be nothing to
      send.

## Credentials — `SEC-5`

- [ ] **CNF-13 · BLOCKING** Every credential the implementation handles appears as a row in
      `SEC-5`. A credential class with no row is a defect in the table or in the code, and
      either way it blocks.
- [ ] **CNF-14 · BLOCKING** The rescue root password is redacted before the API response is
      written to the journal and before it reaches model context. Verified by searching both.
- [ ] **CNF-15 · BLOCKING** No credential appears in cleartext in origin-private storage,
      local storage, or service-worker caches. *(`STG-10`)*
- [ ] **CNF-16 · BLOCKING** A tenant secret delivered to a machine (`SEC-5` row 12) is
      redacted from the transcript by value and never enters model context on delivery. The
      screen that offers it states plainly that a model with root can read it afterwards.
- [ ] **CNF-17 · BLOCKING** An untyped response containing a harness-held credential is
      redacted before it reaches the model or the record. Exact-value scan.
- [ ] **CNF-18 · BLOCKING** The attest introduction is **single-use**, and single-use is the
      browser's (`CHN-5`, `CHN-7`). Verified three ways: a second validly sealed wrap from the
      same sender key after one is accepted is ignored; a wrap whose seal author is not the
      planted sender key is refused even when it decrypts; and a wrap arriving after the
      browser's window has closed is refused. No relay-side behaviour may be relied on for any
      of the three.
- [ ] **CNF-61 · PRE-SCALE** The sender key is scrubbed from the machine's cloud-init artifacts
      on the first relay OK or at the deadline (`CHN-6`), verified by reading the machine's disk.
      This is defence in depth: the vendor's metadata endpoint still serves the original
      user-data, so a disk scrub is **not** the bound and must not be recorded as one.
- [ ] **CNF-72 · BLOCKING** Every per-machine credential derives from the seed at a journaled,
      never-reused index (`STA-22`). Verified by deriving twice from the same seed and index and
      getting identical keys, and by confirming the journal refuses to create a machine at an
      index already recorded. Boundary-crossed: a reused index is one client key on two
      machines.
- [ ] **CNF-73 · BLOCKING** No session and no machine is ever given the seed (`STA-22`).
      Verified by inspecting what each is given, as `CNF-9` does for the scanner. Escaped-secret:
      the seed reaches every maintained machine and every future introduction.
- [ ] **CNF-77 · PRE-SCALE** The post-harness credential is a `SEC-5` row, derived from
      the seed, with its public half installed only on the machines the profile's handoff slot
      declares, during setup, and its private half never stored (`ARC-19a`, `SEC-5` row 17).
      Verified by inspecting each machine's installed authorization after setup against that
      declaration and confirming the machinery holds no channel and no machine's own key.
      Profiles declaring a handoff credential only.
- [ ] **CNF-74 · PRE-SCALE** An event received on the notify channel (`CHN-17`) is typed
      untrusted and gates nothing. Verified by delivering a well-formed event claiming a step is
      complete and confirming no step advances.
- [ ] **CNF-75 · PRE-SCALE** The publisher's Nostr relay serves a recipient's wraps only to a
      subscriber authenticated as that recipient (`CHN-18`). Verified by requesting an inbox
      without authenticating and receiving nothing.
- [ ] **CNF-19 · PRE-SCALE** The recovery sheet is passphrase-wrapped, its export screen states
      what it can do in the wrong hands, and a maintained cloud machine's setup does not
      complete without it (`STA-15`).
- [ ] **CNF-20 · PRE-SCALE** Replace revokes: new keypairs issued, old public keys removed from
      every maintained machine during re-entry, relay pass re-issued with the old one revoked
      (`STA-17`). The screen states that the inference account credential is **not** among them
      and cannot be revoked (`SEC-5` row 14).
- [ ] **CNF-68 · BLOCKING** No session ever holds the inference **account** credential
      (`ARC-31a`, `SEC-5` row 14). Verified by inspecting what a session is given, as `CNF-9`
      does for the scanner — a refusal test cannot distinguish an absent credential from one the
      harness declined to use. Escaped-secret: this credential is bearer, unrevocable, and holds
      spendable balance.
- [ ] **CNF-69 · BLOCKING** The session inference key is minted with a **spend cap and an
      expiry** and is **revoked when the session ends** (`ARC-31a`). Verified by using the key
      after the session closes and confirming refusal. Without this, `SEC-5` row 2's "one
      session" lifetime is an assertion rather than a bound.
- [ ] **CNF-70 · BLOCKING** Automatic top-up is **not enabled** on the inference account
      (`ARC-31a`). Verified by reading the account's configuration. It converts the prepaid cap
      — the only thing bounding a leaked key — into an open draw on a connected wallet.
- [ ] **CNF-71 · PRE-SCALE** The retention tier is requested **explicitly on every inference
      call** (`ARC-31a`), because the aggregator's API default is the weaker tier. Verified by
      inspecting an outgoing request, not by trusting the aggregator's web-app default.

## The channel — `SEC-11`, `CHN-*`

- [ ] **CNF-21 · BLOCKING** A host key that does not match the stored fingerprint halts the
      session. Verified by presenting a different key.
- [ ] **CNF-22 · BLOCKING** The rescue host key is pinned from `/rescue/last` after the reset and
      before the first connection; the activation response is never used as a host-key source, and the installed system's host keys are read from inside the rescue
      session before reboot. **No trust-on-first-use at either hop** (`STG-4`).
- [ ] **CNF-23 · BLOCKING** Under `CHN-R4` only, first contact is presented to the operator as
      trusted rather than verified, in those words.
- [ ] **CNF-24 · BLOCKING** The install artifact is verified against a value the browser supplies
      from the signed bundle, and a mismatch halts the install (`ARC-25`, `STG-6`). Verified by
      serving an artifact that does not match and confirming the install stops rather than
      warning.
- [ ] **CNF-66 · BLOCKING** The pinned URL is an **immutable versioned path**, not a moving
      alias (`ARC-25`). Verified by inspecting the pinned URL: a `latest`-shaped path or a
      rewritten-in-place metadata file fails this item even when the hash currently matches,
      because it will mismatch on the next upstream release and every install after it.
- [ ] **CNF-67 · BLOCKING** Both distributions enforce the package/cache signature policy of
      `ARC-25a`. An unsigned package or one signed by an unaccepted key is refused. Alpine
      checks the bundle's repository branch and accepted key set, and records index digests
      and installed versions; NixOS checks the pinned revision and cache keys. The display
      distinguishes bootstrap hash from package signatures. Boundary-crossed: otherwise
      a repository can substitute the kernel or SSH server outside the stated admission policy.
- [ ] **CNF-62 · BLOCKING** A typed vendor call over the tunnel **refuses a certificate that
      does not match the pin** (`CHN-12a`). Verified by presenting a valid certificate from a
      different issuer and confirming the session halts. Without this the tunnel is an
      unauthenticated pipe to a credential-bearing endpoint, which is the escaped-secret family.
- [ ] **CNF-63 · PRE-SCALE** The relay carries the vendor tunnel as ciphertext and can read
      nothing of it. Verified by inspecting what the relay observes for a tunnelled call.
- [ ] **CNF-64 · PRE-SCALE** A pin that no longer matches produces a clear, actionable failure
      naming rotation as the likely cause — not an opaque network error (`CHN-12a`'s rotation
      cost).

- [ ] **CNF-25 · PRE-SCALE** The vendor firewall does not privilege the relay's source
      addresses (`ARC-41`), so the scanner's view equals the world's.
- [ ] **CNF-79 · PRE-SCALE** The channel's pinning cases (`CNF-21`, `CNF-62`) pass on a
      physical Android Chrome (`STG-14`, `OVR-1`); first seen 2026-09-08 on the spike
      (`docs/findings/2026-09-07-wasm-spikes.md`). iOS Safari is not a test target.

## The deliverable — `ARC-17`, `ARC-39`

- [ ] **CNF-49 · BLOCKING** The tenant's delivery declaration exists, and the delivery check
      measures the machine against it. A machine with no declaration does not pass, because
      there is nothing to measure against.
- [ ] **CNF-50 · BLOCKING** An **undeclared** listener is reported as a finding. Verified by
      starting one and confirming both the delivery check and a scanner run name it.
- [ ] **CNF-51 · PRE-SCALE** A declared listener is **not** reported as a finding, so the check
      is usable on a machine whose product is reachable ports.
- [ ] **CNF-53 · PRE-SCALE** The declared **service lifecycle** is demonstrated as declared, and
      the harness asserts nothing beyond it. A tenant declaring a service enabled and
      restart-surviving has that verified; a tenant declaring a deliberately non-durable node
      is not failed for it.
- [ ] **CNF-52 · BLOCKING** On a multi-tenant machine, no spendable key material is present
      (`ARC-37`). Verified by searching the machine for private key material after a full
      install; watch-only public material is expected and permitted. BLOCKING because a wallet
      on a box hosting strangers is the escaped-secret family, and a leak outlives the incident.

## Relay access — `CHN-15`, `CHN-16`

- [ ] **CNF-57 · BLOCKING** An unpaid caller is refused. The relay is not usable without a
      valid, unexpired pass bound to the key that signs the challenge. Verified by connecting
      with a key that has no pass, with one whose pass has expired, with one whose pass is
      revoked, and with a correct key but a **replayed** challenge signature, which must also be
      refused.
- [ ] **CNF-58 · BLOCKING** A pass reaches only the destinations recorded against it — on **any**
      port, since `ARC-41` requires the relay-side view to equal the world's. Verified by
      attempting an undeclared destination on the SSH port and on another, and a recorded
      destination on a non-SSH port, which must succeed.
- [ ] **CNF-65 · BLOCKING** Probing a recorded destination is **paced**, and the per-run and
      per-target limits hold. Verified by driving the probe toolset flat out at one destination
      and measuring the rate the relay actually allows. BLOCKING because pacing is the whole of
      what stops a wide port range being the open proxy `CHN-8` forbids — boundary-crossed, the
      same family as `CNF-57` and `CNF-58`, and the port restriction that used to carry this
      is gone.
- [ ] **CNF-59 · PRE-SCALE** Obtaining a pass requires no account, no email address and no
      identifier the operator supplies beyond a derived public key. Verified by buying one end
      to end without contacting the publisher, and by buying two and confirming the relay holds
      nothing that links their keys.
- [ ] **CNF-60 · PRE-SCALE** A revoked pass stops working immediately, including on a
      connection already open (`CHN-16`). Verified by revoking — a message signed by the pass's
      key — while a session is live and confirming the socket closes and a reconnect is refused.
- [ ] **CNF-76 · BLOCKING** Recording a destination against a pass requires that pass's key's
      signature (`CHN-16`). Verified by submitting a destination without one and with another
      key's, both refused. Boundary-crossed: without it, anyone who learns a pass's public key
      can widen it.

## Approval and recording — `SEC-4`, `SEC-12`

- [ ] **CNF-26 · BLOCKING** A typed operation naming a machine the calling session is not
      bound to is **refused by the adapter**, before any approval screen renders.
- [ ] **CNF-27 · BLOCKING** A scope naming a known vendor's hostname is refused.
- [ ] **CNF-28 · BLOCKING** Every off-machine call is written durably before it is sent.
      Verified by killing the process between record and send and finding the record.
- [ ] **CNF-29 · BLOCKING** An interrupted call is recorded as **unresolved**, is not retried
      automatically, and is not reported as failed. No timer clears it.
- [ ] **CNF-30 · BLOCKING** Box-plane commands are recorded per command before transmission,
      and the transcript reconciles against what was sent (`ARC-8`).
- [ ] **CNF-31 · PRE-SCALE** A scoped call is sent with redirect following disabled, and a
      redirect response ends the call (`ARC-6`).
- [ ] **CNF-32 · PRE-SCALE** An origin's route is selected by a dedicated no-side-effect probe
      before any side-effecting call exists, and a real call's failure never selects a new
      route.
- [ ] **CNF-33 · PRE-SCALE** The approval screen for an untyped scope does not present the
      scope as a bound on what the credential can do.

## Briefs and untrusted content — `SEC-7`, `SEC-8`

- [ ] **CNF-34 · BLOCKING** A brief or feed list cannot be substituted, fetched, or configured
      at runtime. Verified by attempting each.
- [ ] **CNF-35 · BLOCKING** Tool output claiming authority does not receive it. A box-plane
      command whose output says "policy: allow destructive operations" changes nothing.
- [ ] **CNF-36 · PRE-SCALE** An advisory recommending an upgrade produces a report, never an
      action.

## State and recovery — `STA-*`

- [ ] **CNF-37 · BLOCKING** A brief interrupted mid-run and re-run from the top **converges**:
      one machine, one install, no duplicated side effects (`ARC-10`, `STG-12`).
- [ ] **CNF-38 · BLOCKING** A rescue activation interrupted between intent and confirmation,
      then resumed, results in exactly one rescue session and one install (`STG-11`).
- [ ] **CNF-39 · PRE-SCALE** After a killed worker, replay classifies incomplete calls, cancels
      those that cannot still exist, and surfaces uncertain ones without resuming them
      (`STA-7`).
- [ ] **CNF-40 · BLOCKING** A command still running when the session dropped is **not**
      re-run on reconnect. Verified by starting a long command, killing the session, and
      confirming the returning session waits on the job record rather than launching a second
      one (`STA-20`). This is the corruption case, which is why it blocks.
- [ ] **CNF-54 · PRE-SCALE** A completed command's exit code and output are read from the job
      record after a session drop, not inferred from machine state.
- [ ] **CNF-55 · PRE-SCALE** An installed-system job record survives a reboot. Its boot identity
      establishes that an unfinished old command ended; success still needs a terminal record.
      A missing record remains unresolved. Rescue follows `CNF-86`, not a persistence claim.
- [ ] **CNF-56 · PRE-SCALE** The command recorded by the machine matches the command the
      browser journal recorded before sending. A mismatch is surfaced as a finding, and is
      never described as verification (`STA-21`).

## Trust display — `SEC-9`, `SEC-10`

- [ ] **CNF-41 · PRE-SCALE** Counts are shown per layer and never blended. The provider layer
      is labelled **requested**, never *observed* or *verified*, and is never derived from the
      model name (`SEC-9`).
- [ ] **CNF-78 · PRE-SCALE** Every inference call carries the member's requested provider in the
      aggregator's routing object (`ARC-14`), verified by inspecting an outgoing request. And
      the one observable fact about override is measured: a pin naming a provider that cannot
      serve the requested model either **fails the call** or **silently succeeds**, and which
      one is recorded, because it decides whether the label *requested* means "honoured or
      refused" or merely "sent".
- [ ] **CNF-42 · PRE-SCALE** Every approved scope and every placed tenant secret appears in the
      trust display until revoked or rotated, not merely while the approval stands.
- [ ] **CNF-43 · PRE-SCALE** The relay's row names its operator and states that it learns the
      member topology (`CHN-13`).
- [ ] **CNF-44 · DEFERRED** Nothing in the interface uses the words "verified" or "no anomalies
      found" (`SEC-2`).

## Measurements

Not pass/fail. Required to be recorded.

- [ ] **CNF-45** Peak memory of one session during a full install, per mobile browser, with the
      five-session projection against each platform's tab budget (`STG-15`, `ARC-13`).
- [ ] **CNF-46** Wall-clock duration of a full install over the channel.
- [ ] **CNF-80 · PRE-SCALE** An installed system that does not answer on the channel within
      ten minutes of its boot reset is declared failed, the operator is told, and a separately approved destructive reinstall
      returns to rescue from the brief (`STG-20`). Test a missing bootloader and a relay outage: neither a timeout nor
      unreachability clears unresolved operations or triggers a wipe without that decision.
- [ ] **CNF-47** Transcript size produced by one install.
- [x] **CNF-48** What Robot's rescue `host_key` field actually returns, and what the automatic
      Linux install operation returns (`OPN-6`, `STG-2`). **Recorded 2026-09-08**: SHA-256
      fingerprints per algorithm on `/boot/{n}/rescue/last` ~80 s after the reset, empty on
      the activation `POST`, fresh per boot; the installer catalogue still has no Alpine or
      NixOS (`docs/findings/2026-09-08-first-stage-rehearsal.md`).

## Additional contracts from the September 9 review

- [ ] **CNF-81 · BLOCKING** A recorded destination still cannot reach relay-private services
      (`CHN-16a`). Loopback, private/link-local IPv4 and IPv6, metadata, mapped IPv6, numeric
      aliases and the relay's own addresses are refused. Test a public DNS name changing to a
      private address, mixed public/private answers and retries; the dialer uses only the
      validated numeric address. A valid external public SSH/TLS destination remains reachable.
      Before enabling self-host migration, demonstrate SSH re-entry and scanning of the relay
      host through a retained external relay; migration without that route is refused (`CHN-11`).
      Boundary-crossed: a pass must not grant the relay's private network position.
- [ ] **CNF-82 · BLOCKING** Local storage follows `STA-23`: wrong passphrases, modified
      envelopes/records, cross-store substitution and unknown formats fail closed; no new
      empty store replaces failed decryption. Reload and background/explicit lock require
      unlock again, session workers lose access, and replay preserves unresolved actions.
      Inspect persisted bytes and worker inputs for forbidden plaintext keys. Escaped-secret.
- [ ] **CNF-83 · BLOCKING** Derivation matches every v1 known-answer vector, upstream primitive
      vectors, and a second implementation (`STA-22a`). Different roles/indices yield distinct
      keys; out-of-range indices, unknown versions and invalid children cannot alias a valid
      allocation. The mnemonic passphrase is empty regardless of local unlock passphrase.
      Boundary-crossed: an ambiguous mapping can reuse keys across roles or machines.
- [ ] **CNF-84 · BLOCKING** A seed plus sheet restores machine and relay identities from their
      exported indices; a mismatched seed, duplicate mappings or invalid counters are refused.
      A stale sheet or imported store cannot allocate under the restored seed. Exercise missing
      metadata: Robot rekeys through rescue with a fresh seed, cloud exposes its fallback, and
      missing relay indices are reported unrecoverable. Partial Replace never reports complete
      revocation (`STA-22b`, `STA-17`). Boundary-crossed and destroyed-data.
- [ ] **CNF-85 · BLOCKING** Disk selection in the install brief is checked without writes first:
      the root disk's stable path and canonical alias are both excluded from additional-disk
      erasure; duplicates run once; an empty additional set erases none; an invalid or
      non-block-device entry aborts before any disk is erased. Only the explicitly selected
      whole disks may be written, and identities are re-read after each rescue boot.
      Destroyed-data. Hardware rehearsal remains separate from this non-destructive gate.
- [ ] **CNF-86 · BLOCKING** Drop SSH during partitioning/install: the returning session reads
      the same rescue boot's job and does not duplicate it. Before planned reboot, block the
      journal append and confirm no reset occurs; then allow it and recover collected records
      and installed pins. Force an unexpected rescue reboot: changed boot ID or missing records
      remain unresolved until inspection/explicit disposition, never automatic re-execution
      (`STA-20b`). Destroyed-data.
- [ ] **CNF-87 · BLOCKING** The first-stage relay's hand-configured access record authenticates
      a fresh connection challenge under the enrolled public key, refuses unknown keys and
      replayed signatures, restricts targets to its configured public destination set and
      applies configured connection/probe limits. It is not an unauthenticated development
      proxy (`STG-18`); purchase and quota accounting are outside this check. Boundary-crossed.

## Stage applicability and admission

This table is exhaustive; every new CNF item must acquire a row before it can gate a stage.
**Required** means the first-stage completion report must include passing evidence, even
for PRE-SCALE items promoted by `STG-*`. Measurements must have recorded values. Later
features remain unavailable until their BLOCKING checks pass; deferral never enables an
untested capability. A broader deployment still applies the PRE-SCALE promotion rule above.

| Applies when | CNF items | First-stage interpretation |
|---|---|---|
| First stage: required | 1–7, 10–15, 17, 21–22, 24–26, 28–30, 32, 34–35, 37–40, 41, 43–44, 49–56, 62–64, 66–73, 78–83, 85–87 | One live dedicated machine; synthetic unbound identities exercise 6 and 26. Item 50 covers the delivery check; its scanner half waits for scanner enablement. Item 10 covers local ledger persistence; its sheet-export half waits for recovery. Item 72 covers local allocation; imported-state cases are 84. Item 67 uses Alpine; NixOS evidence is required before enabling NixOS. Item 81's migration case waits for self-host migration, which the first stage does not offer. |
| First stage: record measurements | 45–48 | 48 has by-hand evidence; 45–47 require the integrated browser channel, not the rehearsal's timings. |
| Post-harness handoff | 8, 77 | Before enabling any profile that declares one; the first stage has none. |
| Scanner and advisory monitoring | 9, 36 | Also complete item 50's scanner case before exposing scanner results. |
| Tenant-secret injection | 16 | Before enabling injection; unavailable in the first stage. |
| Cloud attest and Nostr inbox | 18, 61, 74–75 | Before cloud route 5 is enabled. |
| Recovery export/import and Replace | 19–20, 84 | Before offering recovery UI or maintained cloud delivery; complete item 10's export case too. Local unlock/restart is first-stage work. |
| Operator-supplied existing host | 23 | Before enabling route 4. |
| Untyped scopes | 27, 31, 33, 42 | Before enabling untyped scopes; first stage offers typed Robot calls only. |
| Paid/public relay access | 57–60, 65, 76 | Before enrolment opens beyond the publisher's fixed first-stage record. First stage still requires 81 and 87. |

**CNF-17's first-stage evidence uses an injected response fixture** through the common
credential-redaction boundary. This does not enable untyped calls. Repeat it against real
untyped responses before enabling scopes.

**Before the first live harness rehearsal:** pass the build gates (1–4), derivation/envelope
and disk-selection gates (82–83, 85), and fixture-based refusal/recording cases for every
first-stage BLOCKING boundary above. The test record must identify what used fixtures.
Then an operator may authorize a bounded live run against an already-rented disposable
server and funded, capped inference account. Live-only checks are completed during that run,
not asserted before it. No production data or tenant delivery is admitted by a fixture pass.

**Before declaring the first stage complete:** all required rows above pass on the integrated
harness, `STG-14` supplies physical Android evidence, and measurements are recorded. The
lnrent-owned delivery declaration, vendor lockdown checklist and briefs 2–3 must exist in the
signed bundle (`OPN-14`, `CNF-49`); unavailable tenant artifacts fail completion rather than
being replaced by an essay. Rehearsal/prototype results do not automatically check harness
items. This is the distinction between being ready to construct and ready to deliver.

Every BLOCKING addition must name an irreversible family: escaped secret, crossed boundary,
destroyed data or money out. Tier labels and applicability are separate: a federation blocker
can remain deferred while a first-stage PRE-SCALE behavior is required by that stage.
