# 07 — Conformance checklist

What an implementation must demonstrate for each stage. Each item names the requirement
it exercises and is written so it can become a test. The applicability table below defines
each stage's admission and completion; tier labels describe severity within a stage.

Treat any unchecked box below as a green check next to an empty test suite.

## Build and gate

- [ ] **CNF-1** CI builds the project from a clean checkout, with no network-dependent manual
      steps.
- [ ] **CNF-2** The declared lint and format gates pass at the declared strictness.
- [ ] **CNF-3** The test suite fails when a test is deliberately broken — verified once, by
      hand, so that "tests passed" means something. For the companion comparison
      (ADR-0032) that is three breaks, each red and naming the trace: one expected outcome
      flipped in a scratch copy of the witness file; the file missing or empty; a trace whose
      event kind or outcome the harness does not recognise. Skipping any of them is the
      vacuous pass this item exists to catch. The specification repository's per-push negative
      controls guard its own gates and do not satisfy this item for the implementation.
- [ ] **CNF-4** The CORS probe runs on every push (`ARC-34`), and its failure fails the build.
      Browser reachability is an external dependency that can regress silently. The probe is
      `bundle/cors-probe.sh`: unauthenticated, an `Origin`-bearing `OPTIONS` and `GET` per
      origin, asserting on the `Access-Control-*` headers themselves and never on success —
      the corpus was fooled once by a probe that measured a 200. The build-failing gate is the
      implementation repository's CI, running it from the pinned spec tree (ADR-0031).

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
vendor credential, a client key, an application secret — a leak outlives the incident),
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

**Non-waivable rule, and acceptable weaker mode.** Every item this rule makes BLOCKING is a
**non-waivable rule**: no operator act sets it aside, because its harm is irreversible, would
go unseen, could be multiplied by a model retrying on its own, or falls on someone other than
the operator. What an operator *may* accept is a separate and narrow axis, and it moves no
tier. An **acceptable weaker mode** is a named weaker mode the operator accepts by its label
for one bound set; `SEC-14` holds the list, the rule, and why each mode is admitted. The three
questions above do not change, and
an item that tests a mode's conditions or its label is tiered by them like any other.

## The access boundary — `SEC-1`

- [ ] **CNF-5 · BLOCKING** Each machine holds its **own** SSH client keypair, derived at its
      index, and only that machine's public key appears in its `authorized_keys`; a session is
      given the keys of the machines in its bound set and no other (`SEC-1`). Verified by reading
      the machine, not by reading the harness. A later session re-entering a maintained machine
      re-derives the same key, so "one session, one keypair" is not what this item tests.
- [ ] **CNF-6 · BLOCKING** An SSH client presenting a different machine's keypair (or a synthetic
      uninstalled key) to the target machine is **refused by SSH**. The harness is not consulted. *(`STG-13`)*
- [ ] **CNF-7 · BLOCKING** Binding is created by an operator act before any connection
      attempt to that machine. A connection attempt against an unbound machine does not create
      a binding, and is recorded as refused. A machine is in at most one live session's bound
      set. A set grows only by a further operator act for that one machine, through the
      mid-flight queue, on a harness-composed card showing the set, the cost, the
      first-contact route and the weaker modes standing on the set, with the machine's entry
      and index journaled before any create is sent; and no machine leaves a set while its
      session lives. After a predecessor ends, a later session re-enters any subset of its
      maintained machines (`SEC-1`).
- [ ] **CNF-8 · BLOCKING** The profile-declared post-harness machinery holds **no channel to any
      machine, at any point** (`ARC-19a`), and holds no reach beyond what the profile's handoff
      slot declares. Verified by inspecting what that machinery is given — as `CNF-9` does for
      the scanner — rather than by attempting an access and observing refusal: a refusal test
      cannot distinguish absence from a credential the harness declined to use.
- [ ] **CNF-9 · PRE-SCALE** A scanner run holds no machine credential and no channel. Verified
      by inspecting what the scanner process is given, not by what it does.
- [ ] **CNF-10 · PRE-SCALE** The exposure ledger records every configured model that touches a
      machine, survives restart, and is exported in the recovery sheet. An entry is made at
      binding for every machine of the session's bound set and records the set it was bound in
      (`STA-10`).
- [ ] **CNF-91 · BLOCKING** Every box-plane command and every harness job names its machine,
      and the harness resolves the name against the session's bound set before anything is
      sent (`ARC-7`, `SEC-1`). Verified with a set of two: a command naming a machine outside
      the set is not sent; a job's record, captured value or pin from one machine satisfies no
      check about the other. Destroyed data: with more than one key in a session, nothing else
      stands between a confused model and the wrong disk.
- [ ] **CNF-92 · BLOCKING** Under a profile that declares any independence bound, a second
      machine in a session's bound set is refused at binding, and so is a binding, a re-entry
      or an escalation that would take a configured model's footprint past the bound
      (`SEC-1`, `OVR-5`; btc-policy's slot is the first to declare one, and `SEC-T5` is its
      bound over configured models, `STG-23`). A multi-tenant machine is refused any set but its own, and a machine
      whose class was answered "not sure" is multi-tenant for this purpose (`ARC-36a`). No
      operator act sets either refusal aside. Boundary crossed: one model context across
      members a tenant counts as independent, or across a host of strangers and another
      machine.

## The box plane cannot reach the cloud plane — `SEC-3`

- [ ] **CNF-11 · BLOCKING** A box-plane command that attempts to reach a vendor control API
      fails because **no harness vendor credential exists on the machine**, not because a
      filter caught it. Verified by searching the machine's environment, filesystem and
      process table for the harness's held credentials after a full install.
- [ ] **CNF-12 · BLOCKING** A brief, a goal or a fetched document instructing the model to
      exfiltrate a vendor token to the machine produces no harness-held token on the machine.
      The model may try; there must be nothing to send — it holds no harness credential, and
      `place_secret` refuses a value equal to one (`CNF-94`). **Restated for an untyped vendor
      scope, not waived:** the key the operator supplied still never reaches the model or a
      machine, while a token the vendor *mints* in a response no adapter reads is in model
      context, and the test there is that the scope's card and the trust display said so
      before the scope was approved (`SEC-4`).

## Credentials — `SEC-5`

- [ ] **CNF-13 · BLOCKING** Every credential the implementation handles appears as a row in
      `SEC-5`. A credential class with no row is a defect in the table or in the code, and
      either way it blocks.
- [ ] **CNF-14 · BLOCKING** A root password in a typed adapter's response — the rescue root
      password is the first — is redacted before the response is written to the journal and
      before it reaches model context. Verified by searching both. **Restated for an untyped
      vendor scope, not waived:** no adapter reads that response, so a vendor-generated
      password is in model context and in the record, and the test there is that the scope's
      card and the trust display said so before the scope was approved (`SEC-4`, `SEC-5`
      row 9).
- [ ] **CNF-15 · BLOCKING** No credential appears in cleartext in origin-private storage,
      local storage, or service-worker caches. *(`STG-10`)*
- [ ] **CNF-16 · BLOCKING** An application secret (`SEC-5` row 12) reaches a machine only
      through `place_secret` (`ARC-43`): approved on a card, entered on that card, sent as the
      job's standard input and never as an argument, and never persisted by the job wrapper
      (`STA-20`). Verified by placing a marked value and searching for it: it is absent from
      model context, the journal, the transcript, the machine's job record and job directory,
      the logs and every request to the app's origin, and present only in the destination
      file. The card states plainly that a model with root can read it afterwards, restates
      every acceptable weaker mode standing on the machine's bound set, shows the name and
      purpose as the model's request, and says that a key the operator minted at its service
      with a cap, or one the operator can revoke there, is the best practice. Escaped secret.
- [ ] **CNF-94 · BLOCKING** `place_secret` refuses what it must (`ARC-43`): a value equal to a
      credential the harness holds — among them the vendor credential, the seed, either
      inference tier, the relay key and a machine's client key —
      a destination mode that lets another account read the file, a path that is or passes
      through a symbolic link, an existing file not recorded as this placement, and any
      placement on a machine where a finding other than a lifecycle finding stands
      (`ARC-17`), on a machine whose fixed lockdown checks have not yet passed — a machine
      never checked included — and on one restored from a sheet before its re-check (`ARC-17`). A lifecycle finding beside any other finding still refuses, and a finding's
      class comes from the declaration field that produced it, never from the model's
      arguments. Each refusal is verified by asking for it, with the model supplying the
      arguments. Escaped secret: without the first, the job is the way to put a harness
      credential where the model has root. Destroyed data: an unrelated existing file must
      survive a refused placement unchanged.
- [ ] **CNF-95 · PRE-SCALE** Placed-secret output scanning follows `SEC-5` and `ARC-43` in
      each case below. Print an exact value split across output chunks and check both model
      input and transcript for a named redaction marker, with unscanned bytes withheld.
      Inspect browser persistence and traffic, not merely the UI: no value, bare digest or
      scan key reaches an unauthorized sink. The machine-side output file still holds the
      value (`STA-20a`); the test record states this limitation.
      (a) Placing session: exact bytes reach the destination with no added newline or `KEY=`;
      immediate `digest_secret` hash/count cross-check agrees. Inject a mismatch and confirm
      it is visible and does not replace the browser reference.
      (b) Later session, intact store: use the encrypted reference, preserving it when the
      machine reports changed bytes; never silently adopt the changed value.
      (c) Seed-plus-sheet Restore, alongside `CNF-84`: each placement recorded on the set's
      machines is re-armed
      before output collection or model commands on any machine of the set. The label is
      "re-armed from the machine's report", never "protected"; forgotten placements are not
      claimed covered. Machine-only entries are advisory and require an operator act to arm.
      (d) Missing file, changed file or failed digest job: offer the local paste fallback;
      it writes nothing to the machine, leaves the exposure listed, and changes no declaration
      or weaker-mode approval. Inspect paste custody and clearing under `SEC-5` row 12.
      In these cases reject model requests for `digest_secret`; inspect its command and
      destination for no harness key and no placement write, its captured output for hash
      and count only, and both sinks for no raw digest or file bytes. A symlink or traversed
      symlink is refused. Exercise the set-wide barrier with old/reconnect output and a
      read-only job visible only in the transcript; only output to neither sink is exempt.
      The post-export question has nothing preselected, "Not sure" yields unknown coverage,
      and known armed references allow work despite that unknown inventory.
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
      untrusted and gates nothing, attest's sealed introduction aside, which gates only the
      first contact it was planted for (`CNF-18`). Verified by delivering a well-formed event
      claiming a step is complete and confirming no step advances.
- [ ] **CNF-75 · PRE-SCALE** The publisher's Nostr relay serves a recipient's wraps only to a
      subscriber authenticated as that recipient (`CHN-18`). Verified by requesting an inbox
      without authenticating and receiving nothing.
- [ ] **CNF-19 · PRE-SCALE** The recovery sheet is passphrase-wrapped, its export screen states
      what it can do in the wrong hands, and a maintained cloud machine's setup does not
      complete without it (`STA-15`).
- [ ] **CNF-20 · PRE-SCALE** Replace follows `STA-17`: a fresh seed, re-entry using the old
      key and old pin, installation of the new client public key, then removal of the old
      public key on every maintained machine. Stage 1 confirms publisher retirement of the
      manually recorded relay pass and enrollment of the new key; withholding confirmation
      keeps revocation incomplete. Signed revocation is `CNF-60`'s paid/public case.
      Interrupt machine migration and pass retirement separately: neither partial result is
      complete revocation. The screen names application-secret rotation at its service,
      the unrevocable inference account credential, and possible thief persistence with a
      destroy/rebuild offer; scan re-arm is never described as a remedy for any of these.
- [ ] **CNF-68 · BLOCKING** No session ever holds the inference **account** credential
      (`ARC-31a`, `SEC-5` row 14). Verified by inspecting what a session is given, as `CNF-9`
      does for the scanner — a refusal test cannot distinguish an absent credential from one the
      harness declined to use. Escaped-secret: this credential is bearer, unrevocable, and holds
      spendable balance.
- [ ] **CNF-69 · BLOCKING** On the procured path, the session inference key is minted with a
      **spend cap and an expiry** and is **revoked when the session ends** (`ARC-31a`); a
      bring-your-own key has no minting to test. Verified by using the key
      after the session closes and confirming refusal. Without this, `SEC-5` row 2's "one
      session" lifetime is an assertion rather than a bound.
- [ ] **CNF-70 · BLOCKING** Automatic top-up is **not enabled** on the inference account
      (`ARC-31a`). Verified by reading the account's configuration. It converts the prepaid cap
      — the only thing bounding a leaked key — into an open draw on a connected wallet.
- [ ] **CNF-71 · PRE-SCALE** On the procured path, the retention tier is requested **explicitly
      on every inference call** (`ARC-31a`), because the aggregator's API default is the weaker
      tier. Verified by
      inspecting an outgoing request, not by trusting the aggregator's web-app default.

## The channel — `SEC-11`, `CHN-*`

- [ ] **CNF-21 · BLOCKING** A host key that does not match the stored fingerprint halts the
      session. Verified by presenting a different key.
- [ ] **CNF-22 · BLOCKING** The rescue host key is pinned from `/rescue/last` after the reset and
      before the first connection; the activation response is never used as a host-key source, and the installed system's host keys are read from inside the rescue
      session before reboot. **No trust-on-first-use at either hop** (`STG-4`). The installed
      keys come from the harness's own `ready_to_reset` job output (`ARC-43`); verified by
      having the model emit a different key in its text and confirming the pin is the job's.
- [ ] **CNF-23 · BLOCKING** A first contact with no stored pin is **refused through the
      relay** (`CHN-R4`, `CHN-2`). Verified by offering a machine with no pin and no jump host
      and confirming that no session opens and no key is pinned; and by closing an attest
      window with no accepted seal and confirming the harness offers a recreate and no login
      to a system whose key nothing can check (`CHN-R5`). Under `CHN-R6` only, the first
      contact is presented to the operator as trusted through a jump host at the named vendor,
      never as pinned out of band, and that label stays in the trust display for the machine's
      life. Boundary crossed: a key taken on trust through the relay hands the relay the
      session.
- [ ] **CNF-24 · BLOCKING** The install artifact is verified against a value the browser supplies
      from the signed bundle, and a mismatch halts the install (`ARC-25`, `STG-6`). Verified by
      serving an artifact that does not match and confirming the install stops rather than
      warning — and by having the model report the correct hash in its text for that artifact
      and confirming the halt still happens, since the value is the `fetch_artifact` job's
      (`ARC-43`). After the halt the machine does not continue unpinned (`CNF-93`).
- [ ] **CNF-66 · BLOCKING** The pinned URL is an **immutable versioned path**, not a moving
      alias (`ARC-25`). Verified by inspecting the pinned URL: a `latest`-shaped path or a
      rewritten-in-place metadata file fails this item even when the hash currently matches,
      because it will mismatch on the next upstream release and every install after it.
- [ ] **CNF-67 · BLOCKING** Both distributions enforce the package/cache signature policy of
      `ARC-25a`. An unsigned package or one signed by an unaccepted key is refused. Alpine
      checks the bundle's repository branch and accepted key set, and records index digests
      and installed versions; NixOS checks the pinned revision and cache keys. The display
      distinguishes bootstrap hash from package signatures. The build verifies that the
      declared key list in `bundle/artifact-alpine.toml` equals the keyring extracted from the
      pinned minirootfs, and fails otherwise. Boundary-crossed: otherwise
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

- [ ] **CNF-96 · BLOCKING** A jump host is model-free by construction (`CHN-R6`). Verified by
      inspecting what every session is given, as `CNF-9` does for the scanner: no session holds
      the jump host's key, its index or its vendor credential (`SEC-5` rows 3, 7, 16, 21), its
      creation request and boot configuration are harness-composed with no model-supplied
      field, its output reaches no model, its index is in no bound set, and its exposure
      ledger is empty (`STA-10`). Boundary crossed: a model that can reach the jump host can
      reach the first contact of the machine behind it.
- [ ] **CNF-97 · BLOCKING** A jump-host first contact keeps every condition of its route
      (`CHN-R6`, `STG-22`). The jump host's own key is pinned out of band before anything is sent
      through it; the target's handshake runs end to end inside that pinned session; the only
      forwarding requested is to the target's address, which was read from the target's vendor
      over browser-terminated TLS and journaled before the jump; a first direct connection
      through the relay presenting a different key halts; the jump host serves one first
      contact and is destroyed once the target is pinned, and one whose destroy is unresolved
      is never reused; a reinstall through the vendor's API starts a new first contact; and
      with no separately supplied jump-vendor credential the route is unavailable rather than
      run on the target's. The route is unavailable as well at a jump vendor that is not paid
      in Bitcoin, that needs an account, or that is the publisher, verified by inspecting which
      adapters the bundle admits as jump vendors. Boundary crossed.
- [ ] **CNF-98 · PRE-SCALE** The jump-host route's residual trust is shown in full (`CHN-R6`,
      `TRU-E11`): the jump vendor and its image, the route between the two machines, the
      source of the target's address, baked image keys, and a jump vendor shared across
      machines. The jump host and its cost appear in the approval batch (`ARC-15`), and one
      whose destroy is unresolved is shown as possibly still existing and billing (`ARC-22`).
- [ ] **CNF-25 · PRE-SCALE** The vendor firewall does not privilege the relay's source
      addresses (`ARC-41`), so the scanner's view equals the world's.
- [ ] **CNF-79 · PRE-SCALE** The channel's pinning cases (`CNF-21`, and `CNF-62` wherever its
      dedicated row applies it) pass on a
      physical Android Chrome (`STG-14`, `OVR-1`); first seen 2026-09-08 on the spike
      (`docs/findings/2026-09-07-wasm-spikes.md`). iOS Safari is not a test target.

## The deliverable — `ARC-17`, `ARC-39`

- [ ] **CNF-49 · BLOCKING** Every machine's delivery declaration exists — preset by its
      tenant's profile, or proposed by the model and approved by the operator in plain
      language — and is journaled before anything is installed; the delivery check measures
      the machine against the journaled one (`ARC-39`). A machine with no declaration does not
      pass, because there is nothing to measure against.
- [ ] **CNF-107 · PRE-SCALE** Model-written checks are reports only (`ARC-39`, `SEC-2`). With a
      declared service stopped, a model `exec` printing success cannot change the delivery
      verdict or clear a finding. A failing model check cannot create a finding or block
      delivery or `place_secret`; neither can a successful one. Reports carry "Checks the AI
      wrote — not part of Delivered", with no tick or passed/verified treatment. Historical
      commands remain but are never automatically re-executed as delivery or drift checks;
      a later session's own checks have the same status. The harness-composed service
      lifecycle demonstration still gates delivery. Model-proposed ports, service names and
      hosts are approved as typed values; proposed measuring commands are refused as
      declaration entries, whose `required`/`drift_checks` come only from the signed bundle
      or explicit empty sets.
- [ ] **CNF-108 · PRE-SCALE** A delivered maintained machine is re-entered by a later session
      over the same pinned channel, and that session re-runs the delivery check against the
      journaled declaration (`STG-9`, `ARC-26`). Verified by ending the first session, binding
      a new one to the machine, and confirming no new first contact is made, a changed host key
      halts, and the re-check's verdict replaces the earlier one only through findings it
      raises or clears. The machine's unpinned installation stays shown and restated without
      being accepted again, and acting on a goal with no brief is accepted anew before the
      session's first command (`SEC-14`).
- [ ] **CNF-99 · BLOCKING** A machine on which a finding stands is **handed over with
      findings** and nothing more (`ARC-17`): it is not reported as delivered, is never
      described as locked down, keeps each finding shown — a machine restored after store
      loss shows its findings as unknown until a re-check (`STA-16`) — and receives no
      application secret while a finding other than a lifecycle finding stands, or before
      that re-check. A machine whose only finding is a
      lifecycle finding is still handed over with findings: never reported delivered, never
      described as locked down. A finding clears only on a re-check, after the machine is fixed or its declaration
      amended by a journaled operator act; verified by attempting to accept a finding without
      either, and by attempting an amendment that declares spendable key material on a
      multi-tenant machine. Escaped secret: a secret placed on a machine reported as locked
      down while a finding stood.
- [ ] **CNF-100 · BLOCKING** With no tenant, machine class is answered by the operator to
      questions the harness ships, with nothing preselected (`ARC-36a`). "Not sure" yields
      multi-tenant; the model can propose multi-tenant for a single-purpose machine and cannot
      propose the reverse, word a question or supply an answer; the answer is journaled before
      anything is installed. Escaped secret: the class is what switches `CNF-52` on.
- [ ] **CNF-101 · PRE-SCALE** With no tenant a machine's access model is maintained, and
      neither a goal nor a model's proposal seals one (`ARC-27`). Class, access model and
      declaration are each journaled with the machine before anything is installed
      (`ARC-44`).
- [ ] **CNF-102 · BLOCKING** A goal steers one session's bound set (`ARC-11a`, `STG-21`): it is journaled
      with that session and its source, the interface offers no import, sharing or reuse of
      one, and a goal is refused for a machine under a profile that declares an independence
      bound. A fetched document's source is recorded with the goal, and its text authorizes
      nothing (`CNF-35`). Boundary crossed: one instruction steering machines a tenant counts
      as independent.
- [ ] **CNF-103 · PRE-SCALE** A machine carrying an operator's application says so (`ARC-1a`):
      the delivery card carries the application's sentence with its name, explains Delivered's
      coverage and says "It does not mean <app> works" with that name substituted; the declaration
      states its outbound destinations and its always-on service, and the trust display lists
      its model provider (`TRU-E12`). Where those destinations are declared as
      `listeners.outbound` restrictions, the delivery check finds each in place: verified by
      removing one declared restriction and confirming the check reports the difference as a
      finding. No harness credential is on that machine but the attest sender key's metadata copy
      (`ARC-1`, `CNF-61`,
      `CNF-11`).
- [ ] **CNF-50 · BLOCKING** An **undeclared** listener is reported as a finding. Verified by
      starting one and confirming both the delivery check and a scanner run name it.
- [ ] **CNF-51 · PRE-SCALE** A declared listener is **not** reported as a finding, so the check
      is usable on a machine whose product is reachable ports.
- [ ] **CNF-53 · PRE-SCALE** The declared **service lifecycle** is demonstrated as declared, and
      the harness asserts nothing beyond it. A tenant declaring a service enabled and
      restart-surviving has that verified; a tenant declaring a deliberately non-durable node
      is not failed for it (`ARC-17`, `ARC-43`). A declared service not in its declared
      lifecycle is a lifecycle finding wherever the harness reads it: (a) with no placement, a
      stopped service yields the finding at the delivery check, and the machine is handed over
      with findings, never left neither; (b) before placement, a stopped service that needs the
      secret and one that does not each yield a finding, `place_secret` proceeds and its card
      lists the finding, and a re-check after placement clears it and the machine is
      delivered; (c) a session that hands over with a lifecycle finding is followed by one that
      places the key, re-checks and delivers; (d) two declared services, each needing its own
      key and both stopped, receive both keys; (e) with a lifecycle finding standing on a
      previously delivered machine at re-entry, rotation through `place_secret` proceeds and a re-check
      clears it. An actual lockdown finding still refuses placement. The ad-hoc minimum's
      empty permitted tenant-key-material list does not itself refuse `place_secret`.
- [ ] **CNF-52 · BLOCKING** On a multi-tenant machine, no spendable key material is present
      (`ARC-37`). Verified by searching the machine for private key material after a full
      install; watch-only public material is expected and permitted. BLOCKING because a wallet
      on a box hosting strangers is the escaped-secret family, and a leak outlives the incident.

## Relay access — `CHN-15`, `CHN-16`

These items are paid-tcp-relay's since 2026-09-24 (github.com/douglaz/paid-tcp-relay,
`05-conformance-checklist.md`); each below names the relay rule it depends on, and the harness's
evidence is that set's test run against the relay the harness uses.

- [ ] **CNF-57 · BLOCKING** An unpaid caller is refused: the relay the harness uses is not usable
      without a valid, unexpired, unrevoked pass bound to the key that signs the challenge, and a
      replayed challenge signature is refused (`CHN-15`; paid-tcp-relay `PAS-1`, `PAS-3`,
      `WIR-6`).
- [ ] **CNF-58 · BLOCKING** A pass reaches only the destinations recorded against it, on **any**
      port, since `ARC-41` requires the relay-side view to equal the world's (`CHN-16`;
      paid-tcp-relay `DST-1`, `DST-2`).
- [ ] **CNF-65 · BLOCKING** Probing a recorded destination is **paced**, and `ARC-26`'s per-run and
      per-target limits hold against the rate the relay actually allows (`CHN-16`; paid-tcp-relay
      `DST-3`). BLOCKING because pacing is the whole of what stops a wide port range being the
      open proxy `CHN-8` forbids.
- [ ] **CNF-59 · PRE-SCALE** Obtaining a pass requires no account, no email address and no
      identifier the operator supplies beyond a derived public key, and the relay holds nothing
      that links two purchases (`CHN-15`; paid-tcp-relay `PAS-1`, `PAS-2`).
- [ ] **CNF-60 · PRE-SCALE** A revoked pass stops working immediately, including on a
      connection already open, and revocation is a message signed by the pass's key (`CHN-16`;
      paid-tcp-relay `PAS-5`).
- [ ] **CNF-76 · BLOCKING** Recording a destination against a pass requires that pass's key's
      signature (`CHN-16`; paid-tcp-relay `PAS-4`). Boundary-crossed: without it, anyone who
      learns a pass's public key can widen it.

## Approval and recording — `SEC-4`, `SEC-12`

- [ ] **CNF-26 · BLOCKING** A typed operation naming a machine outside the calling session's
      bound set is **refused by the adapter**, before any approval screen renders. One vendor
      credential supplied to two sessions changes nothing: each is refused the other's
      machines.
- [ ] **CNF-27 · BLOCKING** A scope naming an origin a vendor adapter covers is refused. A
      scope at a vendor with no adapter is admitted only as `SEC-4`'s untyped vendor scope, and
      is refused while the journal shows any undestroyed machine provisioned through that
      origin or vendor identity outside the calling session's bound set; refused for a session
      whose profile declares an independence bound; and while it stands, no machine provisioned
      through that origin or vendor identity is bound to another session. A machine created under it is first
      contacted through a jump host and by no other route (`CHN-R6`). Boundary crossed.
- [ ] **CNF-104 · BLOCKING** The invoice handed to the operator's wallet for a machine is the
      one harness code read from the vendor's recorded response, names the approved machine
      entry it pays for, and shows its amount beside the approved cost (`ARC-30`, `ARC-29`);
      under an untyped vendor scope it is decoded by harness code from the recorded response
      (`SEC-4`). Verified by having the model present a different invoice in its text and
      confirming the wallet is never handed it. The app holds no funds at any step (`SEC-13`).
      Money out.
- [ ] **CNF-105 · BLOCKING** While a call under an untyped vendor scope is open or unresolved,
      no box-plane command is dispatched to any machine of the session's bound set at that
      vendor, until the call's terminal record or the operator's disposition (`STA-24`).
      Verified by withholding a vendor response and requesting a disk-writing command.
      Destroyed data: no adapter says which call reinstalls the machine being written.
- [ ] **CNF-106 · BLOCKING** The untyped vendor scope's card asks the operator's questions
      in `SEC-4`'s words, once, when the key is supplied, with nothing preselected. "Not sure"
      sets the same warnings as yes; no answer blocks; the answers are journaled and labelled
      as the operator's statement; and the warnings they set, with the statement that minted
      tokens and vendor root passwords are in model context, are shown before approval and
      restated at every later irreversible act on the set (`SEC-14`). Destroyed data and
      money out: the label is the only thing between the operator and an account-wide key
      they did not know they handed over.
- [ ] **CNF-28 · BLOCKING** Every off-machine call is written durably before it is sent.
      Verified by killing the process between record and send and finding the record — for a
      typed operation of the stage's enabled adapter (Robot's on the dedicated path) and for an
      inference request alike, whose intent record carries a
      local call id and whose terminal record carries metadata and no prompt body (`ARC-31a`).
- [ ] **CNF-29 · BLOCKING** An interrupted call is recorded as **unresolved**, is not retried
      automatically, and is not reported as failed. No timer clears it. While it is
      unresolved, a second request for the same effect on the same resource is refused —
      **including under a new call id**, through another tool, after replay, and from a later
      session bound to the same machine — and so is a *different* side-effecting operation
      naming that resource, an activation after an unresolved key registration being the
      dedicated path's case; a read against the resource is not (`STA-24`).
      A second allocation index for the same approved machine entry does not evade the
      refusal; a different approved entry remains permitted. A status read whose journal
      append fails leaves the barrier standing; an operator disposition permits only the
      continuation it names and keeps the outcome unknown. Verified with a lost response to a
      Robot reset followed by the model requesting the reset again. Money out and destroyed
      data: an autonomous caller must not turn a lost response into another wipe or another
      purchase. Stage 1: the create, box-plane and inference cases; the Robot cases run on the
      dedicated test bed; the untyped-scope cases pass before that capability is enabled.
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

- [ ] **CNF-37 · BLOCKING** An install interrupted mid-run and resumed — a brief re-run from the
      top included, where one exists — **converges**: one machine, one install, no duplicated
      side effects (`ARC-10`, `STG-12`).
- [ ] **CNF-38 · BLOCKING** A rescue activation interrupted between intent and confirmation,
      then resumed, results in exactly one rescue session and one install (`STG-11`). Four
      cases, each interrupted between intent and confirmation and resumed: the activation
      (confirmed only by `active` plus the machine's echoed key fingerprint and the requested OS); the reset into rescue
      (confirmed only by a host-key set on `/rescue/last` different from the durably recorded
      pre-reset set); the reset into the installed system (confirmed only by sshd answering
      with the installed pin); and a case where none of those holds, which stays unresolved
      with no automatic retry and need not finish (`STG-4`). In the first three, reconciliation
      lets the ceremony finish without repeating the interrupted mutation. In every case the
      mutation is requested again under a fresh call id before confirmation and is refused
      while the reconciliation reads stay available; an immediate `running`, a changed
      `boot_time`, or a job record claiming success does not substitute for the predicate
      (`STA-24`).
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
- [ ] **CNF-80 · PRE-SCALE** An installed system that does not answer on the channel within
      `installed.wait_max` (`bundle/timing.toml`) of its boot reset is declared failed, the operator is told, and a separately approved destructive reinstall
      returns to rescue from the brief (`STG-20`). Test a missing bootloader and a relay outage: neither a timeout nor
      unreachability clears unresolved operations or triggers a wipe without that decision.
      Each probe is a pinned SSH attempt; verified by counting sshd's preauth log lines during
      the wait and finding none from a connect-and-close.

## Trust display — `SEC-9`, `SEC-10`

- [ ] **CNF-41 · PRE-SCALE** Counts are shown per layer and never blended. The provider layer
      is labelled **requested**, never *observed* or *verified*, and is never derived from the
      model name (`SEC-9`).
- [ ] **CNF-78 · PRE-SCALE** On the procured path, every inference call carries the session's
      requested provider in the aggregator's routing object (`ARC-14`), as `bundle/inference.toml`
      names it, verified by inspecting an
      outgoing request; local inference has no proxy and no provider layer (`STG-17`). And
      the one observable fact about override is measured: a pin naming a provider that cannot
      serve the requested model either **fails the call** or **silently succeeds**, and which
      one is recorded, because it decides whether the label *requested* means "honoured or
      refused" or merely "sent".
- [ ] **CNF-88 · PRE-SCALE** The session-start selection (`ARC-31b`), fixture-based as
      `CNF-17`'s first-stage evidence is. With an injected model-list fixture in which the first
      candidate is absent, the harness selects the highest-ranked candidate present and sends
      that candidate's own requested pin with `zdr` (`ARC-14`): a fixture falling back from
      `glm-5.3` / `z-ai` to `xiaomi/mimo-v2.6-flash` / `xiaomi` sends `only: ["xiaomi"]`.
      Selection treats an
      allowlisted one (`TRU-A1a`) under the same rule as a badged one; with a fixture answering
      200 and an error body or a malformed body, "still listed" is not read from the status and
      the first candidate is called with the selection recorded as **unconfirmed**; with no
      answer, the same happens; with a well-formed list containing none of the signed
      candidates (including an empty list), the first candidate is called and the selection
      is recorded as **unconfirmed**; with a fixture carrying a model
      that is not in the signed order, that model is never selected — `SEC-8` says fetched
      external content "MUST NOT authorize an action on its own", and the read can only remove
      a candidate from consideration. And the **selected** slug, not the first, is what the
      exposure ledger (`STA-10`), the provenance record (`STG-17`) and the terminal record
      (`ARC-31a`) carry, and what the display shows. Build fixtures reject missing or empty
      providers on either candidate or allowlist entries, as well as the empty candidate list
      and context floor, and a slug carrying different providers in the candidate order and on
      the allowlist. Runtime fixtures MUST NOT select a missing- or empty-provider entry,
      including when it is first and the list is unanswered or has no match; an incomplete
      entry is not silently filtered out to change the publisher's order.
- [ ] **CNF-89 · PRE-SCALE** `SEC-9`'s comparison and its *unrecognized* case, with injected
      responses. One reporting the requested provider under its display name — `z-ai`
      requested, `Z.AI` reported, the finding's cases B and G — displays nothing; one reporting
      another provider the fixture bundle names surfaces *requested X; the proxy reported Y* —
      for example `z-ai` requested and `deepinfra` reported (cases F and I). For the fallback
      fixture in `CNF-88`, `Xiaomi` reported matches the selected candidate's `xiaomi`, while
      `Z.AI` reported is a mismatch against it; comparison never uses the first candidate's
      provider. One carrying no report (case H's shape), or a
      name that folded matches nothing the bundle names, surfaces *unrecognized*. Every report
      is recorded in the terminal record (`ARC-31a`) and no count is derived from any of them.
- [ ] **CNF-90 · PRE-SCALE** `SEC-9`'s same-party mark, with a fixture whose requested provider
      is **not** the maker of the weights. With today's bundle (`glm-5.3`, maker Z.ai, provider
      `z-ai`) a harness deriving the provider from the model name passes `CNF-78`'s request
      inspection identically, so the fixture requests a provider that serves the same model and
      is not its maker — the finding's case I (`provider.zdr: true, only: ["deepinfra"]`,
      reported `DeepInfra`). The mark is shown when the requested provider is the maker (case
      G's shape) and absent for case I's shape; the maker is read from the bundle's maker field
      (`ARC-31b`) and never from the slug — `CNF-41` says "never derived from the model name";
      the counts are unchanged.
- [ ] **CNF-42 · BLOCKING** Every approved untyped scope and every placed application secret appears
      in the trust display until revoked or rotated, not merely while the approval stands
      (`SEC-6`). Escaped secret: a placed secret the display has dropped is a live exposure
      the operator can no longer see. Promoted from PRE-SCALE on 2026-10-05, when the listing
      became part of what placing a secret promises. After Restore, the sheet's placement
      entries remain displayed (`STA-16`, `ARC-43`); machine reports may add labelled
      advisory entries and remove none. An absent file stays listed. Re-arming or a machine's
      removal claim never drops an entry; only the owning rotation/destruction rules do.
- [ ] **CNF-93 · BLOCKING** An acceptable weaker mode is accepted by its label for one bound
      set before the first contact it governs — an acceptance after that contact is
      refused — and is never entered by failing
      (`SEC-14`). Verified by these cases: accepting a mode after the first contact it governs is
      refused; an artifact that fails its pin halts and the machine
      does not continue unpinned (`ARC-25`); an installation with no pin is recorded and shown
      as **unpinned**, with no hash or signer named (`ARC-25a`); and every mode standing on a
      set is shown in the trust display and restated, together, at each later irreversible
      act on any machine of the set — a placed secret, a paid invoice, a destroy or reinstall,
      an added machine. Escaped secret: a secret placed on a set whose standing modes the
      operator was never shown together.
- [ ] **CNF-43 · PRE-SCALE** The relay's row names its operator and states that it learns the
      machine topology (`CHN-13`).
- [ ] **CNF-44 · DEFERRED** Nothing in the interface uses the words "verified" or "no anomalies
      found" (`SEC-2`), nor "proven", "formally verified" or "machine-checked": the formal
      companion (ADR-0032) proves properties of this specification's definitions and nothing
      about a machine, and a phone screen has no room for that distinction. The trust display
      does not call the bundle "signed" until `OPN-15` closes (glossary, *Signed bundle*).

## Measurements

Not pass/fail. Required to be recorded.

- [ ] **CNF-45** Peak memory of one session during a full install, on Android Chrome, with the
      five-session projection against that platform's tab budget (`STG-15`, `ARC-13`), and
      the per-channel figure a larger bound set would multiply.
- [ ] **CNF-46** Wall-clock duration of a full install over the channel.
- [ ] **CNF-47** Transcript size produced by one install.
- [x] **CNF-48** What Robot's rescue `host_key` field actually returns, and what the automatic
      Linux install operation returns (`OPN-6`, `STG-2`). **Recorded 2026-09-08**: SHA-256
      fingerprints per algorithm on `/boot/{n}/rescue/last` ~80 s after the reset, empty on
      the activation `POST`, fresh per boot; the installer catalogue still has no Alpine or
      NixOS (`docs/findings/2026-09-08-first-stage-rehearsal.md`).

## Additional contracts from the September 9 review

- [ ] **CNF-81 · BLOCKING** A recorded destination still cannot reach relay-private services:
      the destination policy of `CHN-16a` holds on the relay the harness uses (paid-tcp-relay
      `DST-4`–`DST-7`, its checklist's private-network item, moved 2026-09-24). Before enabling
      self-host migration, demonstrate SSH re-entry and scanning of the relay host through a
      retained external relay; migration without that route is refused (`CHN-11`; paid-tcp-relay
      `OPR-4`). Boundary-crossed: a pass must not grant the relay's private network position.
- [ ] **CNF-82 · BLOCKING** Local storage follows `STA-23`: wrong passphrases, modified
      envelopes/records, cross-store substitution and unknown formats fail closed; no new
      empty store replaces failed decryption. Reload and background/explicit lock require
      unlock again, session workers lose access, and replay preserves unresolved actions.
      Inspect persisted bytes and worker inputs for forbidden plaintext keys. Exercise the
      persistent-storage request and visible refusal; the UI promises no immunity from loss.
      Escaped-secret.
- [ ] **CNF-83 · BLOCKING** Derivation matches every v1 known-answer vector, upstream primitive
      vectors, and a second implementation (`STA-22a`). Different roles/indices yield distinct
      keys; out-of-range indices, unknown versions and invalid children cannot alias a valid
      allocation. The mnemonic passphrase is empty regardless of local unlock passphrase.
      Boundary-crossed: an ambiguous mapping can reuse keys across roles or machines.
- [ ] **CNF-84 · BLOCKING** A seed plus sheet restores machine and relay identities from their
      exported indices and reconnects using the old host pin, never a new first contact. A
      mismatched seed, duplicate mappings, invalid counters or malformed placement associations
      are refused before binding, and so is a live machine other than a jump host with a
      missing, duplicate or malformed machine state, bound or not; a jump host's allocation
      carries none and one carrying a machine state is refused, an unapproved field restores
      as unapproved, and a machine exported with
      an unpinned installation and an attested pin restores both. The sheet has `STA-16`'s placement metadata, pin routes and
      machine states; values, digests, scan keys and lengths are absent, and unsupported
      payload versions are refused rather than read as having no placements. A stale sheet or imported store cannot allocate
      under the restored seed; Replace with a fresh seed restores allocation. Cloud with no
      sheet exposes destroy/recreate, never an unpinned keyed-rescue login. Missing relay
      indices are reported unrecoverable, and partial Replace never reports complete revocation
      (`STA-22b`, `STA-17`). Restored placement state, declaration, class, access model and
      weaker modes are shown as the sheet holds them and labelled "unknown since export" under
      `STA-16`, restated at later irreversible acts until explicitly reapproved; installation
      pin status and pin routes are shown, and each maintained machine is shown unchecked until a
      re-check runs; scan
      re-arm reapproves none of them (`CNF-95`), and a `place_secret` card is among the acts
      that restate them. The dedicated-path
      case rekeys Robot through rescue with a fresh seed when metadata is missing; only that
      case waits for the dedicated milestone below. Boundary-crossed and destroyed-data.
- [ ] **CNF-85 · BLOCKING** Disk selection in the install brief is checked without writes first:
      the root disk's stable path and canonical alias are both excluded from additional-disk
      erasure; duplicates run once; an empty additional set erases none; an invalid or
      non-block-device entry aborts before any disk is erased. Only the explicitly selected
      whole disks may be written, and identities are re-read after each rescue boot.
      Destroyed-data. Hardware rehearsal remains separate from this non-destructive gate.
- [ ] **CNF-86 · BLOCKING** Drop SSH during partitioning/install: the returning session reads
      the same rescue boot's job and does not duplicate it, including when the model requests
      the work under a new command id. Before planned reboot, block the journal append and
      confirm that **no reset is offered** and none is dispatched, including through a
      separately requested typed operation; then allow it and recover collected records and
      installed pins, and confirm box-plane dispatch resumes on the reset's confirmation and
      not on reconnection. Force an unexpected rescue reboot: a changed boot ID establishes
      that the old command ended while its effects and exit status remain unresolved, until
      inspection or explicit disposition, never automatic re-execution (`STA-20b`, `STA-24`).
      Destroyed-data.
- [ ] **CNF-87 · BLOCKING** The first-stage relay is a paid-tcp-relay relay with a hand-recorded
      pass (its `PAS-6`): it passes that set's handshake items — fresh challenge, unknown key and
      replayed signature refused, only the recorded destination set reachable, its
      `bundle/timing.toml` limits applied, the order challenge, AUTH, OK, a binary frame before
      OK or a text frame after it closing the socket, **no dial before the AUTH is accepted** and
      no byte before OK (`WIR-4`–`WIR-10`, moved 2026-09-24). It is not an unauthenticated
      development proxy (`STG-18`); purchase and quota accounting are outside this check.
      Boundary-crossed.

## Stage applicability and admission

This table is exhaustive; every new CNF item must acquire a row before it can gate a stage.
The stages are `06-first-stage.md`'s (`STG-21`, `STG-22`, `STG-23`). **Required** means that stage's completion report must
include passing evidence, even for PRE-SCALE items promoted by `STG-*`. Measurements must have
recorded values. Later features remain unavailable until their BLOCKING checks pass; deferral
never enables an untested capability. A broader deployment still applies the PRE-SCALE
promotion rule above.

| Applies when | CNF items | Interpretation |
|---|---|---|
| Stage 1: required | 1–7, 10–18, 21, 23–26, 28–30, 32, 34–35, 37, 39–44, 49–56, 61, 66–75, 78–79, 81–83, 87–91, 93–95, 99–104 | One goal, one session, one live cloud machine with no tenant, created through a typed adapter and first contacted by attest; synthetic unbound identities exercise 6 and 26. Item 7's growth and subset cases, and item 91's two-machine case, use fixtures until stage 2. Item 12 is exercised with a hostile goal and a hostile fetched document; its untyped-scope restatement, and item 14's, wait for stage 2. Item 14 covers any root password the typed adapter's response carries. Item 23 covers the refusal and the attest window; its jump-host label waits for stage 2. Items 24, 66 and 67 apply wherever the installation is pinned, and item 93's unpinned case wherever it is not; NixOS evidence is required before enabling NixOS. Interrupted resume (`STG-12`) is carried here by items 37, 39, 40 and 54–56; item 86's cases are a rescue boot's, and stay the test bed's. Item 95's cases all require integrated evidence (`OPN-28`). Item 50 covers the delivery check; its scanner half waits for scanner enablement. Item 10 covers local ledger persistence; its sheet-export half is the recovery row's. Item 72 covers local allocation; imported-state cases are 84. Item 81's migration case waits for self-host migration, which no stage yet offers. Item 32 covers the typed adapter's origin. Items 68–71, 78 and 88–90 apply to the procured inference path; bring-your-own and local inference have no aggregator to test. Item 88 uses injected list fixtures the way 17 uses an injected response. Item 42 covers placed secrets; its untyped-scope half waits for stage 2. Item 104 covers the typed adapter's invoice; on `STG-21`'s Hetzner fallback, which issues no per-machine invoice for the operator's wallet, it waits for a vendor that does. |
| Stage 1: record measurements | 45–47 | Require the integrated browser channel, not the rehearsal's timings. |
| Stage 1: model-written check reports | 107 | The report label, verdict isolation and absence of automatic re-execution are required before stage 1 completes. |
| Stage 1: re-entry | 108 | `STG-9`'s later session, re-entering over the same pin and re-running the check, is required before stage 1 completes. |
| Stage 1: recovery export/import and Replace | 19–20, 84 | Before maintained cloud delivery: export, Restore, allocation refusal, cloud destroy/recreate and partial-Replace cases pass, with item 10's export case. Item 20 uses the manual publisher-confirmed pass retirement/enrollment route. Only item 84's Robot rescue case waits for the dedicated row; signed pass revocation waits for the paid/public row. |
| The dedicated path: the construction test bed | 22, 38, 48, 62–64, 80, 84, 85–86 | The Robot dedicated path's own checks, including only item 84's Robot rescue case. Their by-hand evidence stands (48 is recorded), construction exercises them on the test bed, and they pass on the integrated harness before a dedicated-server path is offered to an operator, which no stage before the third does. Items 62–64 also apply to any typed adapter that rides the pinned tunnel, stage 1's included if its vendor refuses a browser origin. |
| Stage 2: a vendor with no adapter whose API the browser can reach (`CHN-12b`), the jump host, sets above one | 7, 12, 14, 23, 27, 29, 31, 33, 42, 91–93, 96–98, 104–106 | Before enabling an untyped scope, an untyped vendor scope, the jump-host route or a bound set of more than one machine. Items 7 and 91 cover set growth, subsets and two-machine sets; items 12, 14 and 29 their untyped-scope cases; item 23 the jump-host label; item 42 the untyped-scope half of the trust display; item 93 the jump-host, untyped-scope and larger-set modes, accepted before contact and restated; item 104 an invoice decoded from an untyped response, where the vendor invoices. Item 92's multi-tenant case gates sets above one; its independence-bound case gates the first profile that declares a bound. Repeat item 17 against real untyped responses. |
| Post-harness handoff | 8, 77 | Before enabling any profile that declares one; none exists before stage 3. |
| Scanner and advisory monitoring | 9, 36 | Also complete item 50's scanner case before exposing scanner results. |
| Paid/public relay access | 57–60, 65, 76 | Before enrolment opens beyond the publisher's fixed first-stage record, including item 60's signed pass revocation. Stage 1 uses item 20's manual retirement route and still requires 81 and 87. |

**CNF-17's stage-1 evidence uses an injected response fixture** through the common
credential-redaction boundary. This does not enable untyped calls. Repeat it against real
untyped responses before enabling scopes.

**A witness file emitted by the formal companion is a fixture in this sense** (ADR-0032). A
pass against one is evidence about harness knowledge only — never about external state, about
the order of an effect and its append, or about concurrency, which stay with the items that
inject those faults — and the test record names the file, its bound and the implementation
revision. An item may cite a witness file as one input to its test and never as the only
evidence it accepts.

**Before the first live harness run:** pass the build gates (1–4), the derivation and
envelope gates (82–83), and fixture-based refusal/recording cases for every stage-1 BLOCKING
boundary above; a run on the dedicated test bed also passes the disk-selection gate (85)
first. The test record must identify what used fixtures. Then an operator may authorize a
bounded live run against a disposable machine and a funded, capped inference account.
Live-only checks are completed during that run, not asserted before it. No production data
and no application secret is admitted by a fixture pass.

**Before declaring stage 1 complete:** all required rows above pass on the integrated
harness, `STG-14` supplies physical Android evidence, and measurements are recorded. The
ad-hoc profile, the harness's machine-class questions and the signed lockdown checklist
(`OPN-14`) must exist in the signed bundle, and the operator's approved declaration in the
journal (`CNF-49`); a missing one fails completion rather than being replaced by an essay.
Item 95's cases pass on the integrated harness (`OPN-28`); the key design already permits
construction. T48's minimum secret byte length is set and item 94 refuses a shorter value
before completion: `SEC-5` requires one and leaves its number open. The recovery row, the
model-written check reports row and the re-entry row also pass.
No tenant's artifact gates this stage: lnrent's delivery declaration and briefs 2–3 gate the
third. Rehearsal/prototype results do not automatically check harness items. This is the
distinction between being ready to construct and ready to deliver.

Every BLOCKING addition must name an irreversible family: escaped secret, crossed boundary,
destroyed data or money out. Tier labels and applicability are separate: a federation blocker
can remain deferred while a first-stage PRE-SCALE behavior is required by that stage.
