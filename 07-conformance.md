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
      route, asserting on the `Access-Control-*` headers themselves rather than treating HTTP
      success alone as CORS evidence —
      the corpus was fooled once by a probe that measured a 200. The build-failing gate is the
      implementation repository's CI, running it from the pinned spec tree (ADR-0031).
      The table includes the LNVPS VM route with requested POST and account route with
      requested PATCH. Fixture cases check OPTIONS success, origin, requested method and
      requested headers independently of GET's origin header; POST is the default requested
      method, and requested methods are compared case-sensitively. For the uppercase PATCH
      preflight, otherwise identical fixtures with `Access-Control-Allow-Methods: PATCH` pass
      and `Access-Control-Allow-Methods: patch` fail. Header-name comparison remains
      case-insensitive. Missing origin,
      method or headers and transport failure each fail; a readable authentication-refused
      GET with the required header passes. Assert only unauthenticated OPTIONS and GET are
      sent, with no signed mutation or verification-link fetch. The probe establishes declared
      CORS shape, not signed-mutation acceptance or end-to-end browser functionality.

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
- [ ] **CNF-91 · BLOCKING** Within a session, every box-plane command and every harness job
      names its machine, and the harness resolves the name against the session's bound set
      before anything is sent (`ARC-7`, `SEC-1`).
      Verified with a set of two: a command naming a machine outside
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
      every acceptable weaker mode standing on the machine's bound set, shows the application
      name, distinct secret name and purpose as the model's request, and says that a key the
      operator minted at its service with a cap, or one the operator can revoke there, is the
      best practice. Escaped secret.
- [ ] **CNF-94 · BLOCKING** `place_secret` refuses what it must (`ARC-43`): a value equal to a
      credential the harness holds — among them the vendor credential, the seed, either
      inference tier, the relay key and a machine's client key —
      a value below `SEC-5`'s minimum byte length (with its no-override refusal),
      a destination mode that lets another account read the file, a path that is or passes
      through a symbolic link, an existing file not recorded as this placement, an application
      name not recorded on the named machine (including one recorded only on another machine),
      and any placement on a machine where a finding other than a lifecycle finding stands
      (`ARC-17`), on a machine whose fixed lockdown checks have not yet passed — a machine
      never checked included — and on one restored from a sheet before its re-check (`ARC-17`),
      and on a multi-tenant machine any placement the operator has not confirmed as
      non-spendable (`ARC-37`). A lifecycle finding beside any other finding still refuses, and a finding's
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
      (d) Missing file, changed file, failed digest job, a digest `STA-24` refuses, one a
      disposition leaves unknown, or below-minimum machine report (`SEC-5`): offer the local
      paste fallback;
      it writes nothing to the machine, leaves the exposure listed, and changes no declaration
      or weaker-mode approval. Where the operator cannot paste the value, the delivery
      re-check runs on the set though a reference stays unarmed, releasing only its verdict,
      and a rotation through `place_secret` then proceeds once `ARC-17`'s placement gates admit it.
      On a machine under a destructive disposition, both wait until `STA-24` admits them,
      the rotation until those gates do as well, and the card says rotation waits.
      Refuse a below-minimum paste too,
      leaving the reference unarmed. Inspect paste custody
      and clearing under `SEC-5` row 12.
      (e) At a vendor with a typed reinstall, three machines A, B and M are in one bound set
      after local-store loss. M carries placements P1 and P2; P1's `digest_secret` goes
      unresolved and the operator disposes it with a destructive reinstall. P2's digest is
      refused and recorded as refused, never absent or failed; P1's outcome stays unknown
      (`CNF-29`: a disposition "keeps their outcome unknown"). The fallback card is offered
      at once for both placements, disposed P1 included, and says rotation waits. With neither,
      one or both pasted, output on A and B is released only after both. Refuse a below-minimum
      paste, leaving the reference unarmed. A copied key split across output chunks on A is
      redacted. A late P1 record arms nothing even before a paste; it is journaled and shown,
      never replaces a pasted reference, and shows a mismatch on cross-check. A pasted reference
      gets no digest after the reset. Without a paste, no digest is composed or re-issued for
      M's unarmed placements until the operator's one act after the reinstall, which covers
      them together: P2's digest as a first issue, P1's as the operator's re-issue. M's
      traffic shows nothing sent for the paste. At LNVPS the assertions after reinstall run
      after publication confirmation (for its predicate, see `STG-21a`) or the operator's disposition with a
      continuation that continues; every assertion before dispatch runs while the destructive
      disposition stands, and dispatch opens the reinstall's own barrier. For the separate
      pin/barrier conformance pairs, see `CNF-112`. Stage 1 runs
      the assertions on M alone; the A/B output-release and copied-key assertions run at
      stage 2.
      (f) As (e), in an unfinished setup whose abandonment flow `SEC-4` authorizes for M by evidence
      tied to the seed-derived key, but the operator disposes P1's `digest_secret` with abandonment.
      P2's digest is refused and recorded as refused, never absent or failed; P1's outcome stays
      unknown. The fallback card is offered at once for both placements, disposed P1 included. With
      neither, one or both pasted, output on A and B is released only after both. A late P1 record
      arms nothing and never replaces a pasted reference. The abandonment flow's operation naming M
      is dispatched whether or not anything was pasted, and clearing the gate resumes nothing of the
      abandoned setup. At LNVPS that operation is the stop that stands in for a destroy (`ARC-22`):
      once it is dispatched, output on A and B is still released only after both pastes, P1 and
      P2 stay listed and counted whether or not anything was pasted, and the card offers no
      destroy and says the secrets stay listed until they are rotated or the vendor's deletion
      is confirmed.
      P1's digest is never re-issued automatically, and M's traffic shows nothing
      sent for the paste. Stage 1 runs the assertions on M alone; the A/B output-release assertions
      run at stage 2.
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
      browser's (`CHN-5`, `CHN-7`). Verified four ways: a second validly sealed wrap from the
      same sender key after one is accepted is ignored; a wrap whose seal author is not the
      planted sender key is refused even when it decrypts; a wrap arriving after the
      browser's window has closed is refused; and a validly sealed wrap for a machine that
      already holds an installed-system pin from another route is refused, before and after a
      restart: the existing installed-system pin is unchanged, no pin is journaled, and no
      introduction is consumed. No relay-side behaviour may be
      relied on for any of the four.
- [ ] **CNF-61 · PRE-SCALE** The sender key is scrubbed from the machine's cloud-init artifacts
      on the first relay OK or at the deadline (`CHN-6`), verified by reading the machine's disk.
      This is defence in depth: the vendor's metadata endpoint still serves the original
      user-data, so a disk scrub is **not** the bound and must not be recorded as one.
- [ ] **CNF-72 · BLOCKING** Every per-machine credential derives from the seed at a journaled,
      never-reused index (`STA-22`). Verified by deriving twice from the same seed and index and
      getting identical keys, and by confirming the journal refuses to create a machine at an
      index already recorded. Boundary-crossed: a reused index is one client key on two
      machines. Under a generated seed with no `STA-23` ceremony record, allocations in all
      families (machines, relay passes, handoffs) are refused, including across a restart and
      for Replace's migration and new relay pass. Full re-entry and explicit skip each admit
      allocation after their durable record; a failed append leaves no record and still
      refuses allocation (`STA-22b`).
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
- [ ] **CNF-20 · PRE-SCALE** Replace follows `STA-17`, as a model-free harness flow no session
      holds and no model drives: a fresh seed, re-entry using the old
      key and old pin, installation of the new client public key, then removal of the old
      public key on every maintained machine, the old key removed only after a connection
      authenticated by the new one succeeds, then the export of a new sheet for the new
      seed, which a later import accepts and the old sheet no longer matches. Stage 1 confirms publisher retirement of the
      manually recorded relay pass and enrollment of the new key; withholding confirmation
      keeps revocation incomplete. Signed revocation is `CNF-60`'s paid/public case.
      Interrupt machine migration and pass retirement separately: neither partial result is
      complete revocation. The screen names application-secret rotation at its service,
      the unrevocable inference account credential, and possible thief persistence with a
      destroy/rebuild offer; scan re-arm is never described as a remedy for any of these.
      The following relabel cases are **dedicated-path evidence** under the applicability
      table, including the fixture for a non-dedicated vendor:
      (a) On a dedicated machine, after the connection authenticated by the new key succeeds
      and before the old key is removed, `replace_root_label` rewrites the root label to the
      new index's installation id with the same ordinal. Its job is recorded before
      transmission and has its machine-side record (`ARC-8`, `STA-20`); a model request for
      it is refused (`ARC-43`). A harness-composed read shows the new id before the old key
      is removed.
      (b) Make the job fail: the screen reports the machine not migrated with the reason,
      its old key stays, and Replace is not reported complete.
      (c) Make the write succeed but the read not show the new id: the result is the same
      as (b).
      (d) Lose the read-back after the write landed: the machine stays unmigrated and its
      shown id stays at the old index. The harness re-reads the label on the next connection
      to the machine, and a read showing the new id migrates it without a rewrite. Any re-issued write with the same new id is a fresh issue chosen by the
      operator, never automatic; the old key is
      removed only after a read shows the new id.
      (e) A dedicated machine whose root label is missing, damaged or carries another id
      still receives the job: the journal's vendor record decides the path, never the disk.
      (f) With a fixture journal entry recording a non-dedicated vendor, no relabel job is
      sent and nothing is written to the disk.
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
      life. On the LNVPS publication route (`CHN-R7`), absent, empty, incomplete,
      cross-installation overlapping or within-installation contradictory publication
      causes **no contact with the machine before an eligible pin is active**, including after reinstall with a previous pin
      stored and after restart during that wait. Include overlap with an earlier installed
      pin from any source whose group has no publication. Status polling is permitted within
      `lnvps.published_key_wait_max`; after its
      deadline, first contact is unresolved, with no login or timer-driven retry. The harness
      offers operator-chosen reinstall or abandonment, never automatic reinstall, fallback
      login or trust on first use. Abandonment stops the machine, turns renewal off and leaves
      it shown as existing and billed until deletion is confirmed (`ARC-22`). Exercise each
      refusal and deadline against the integrated harness, including a status response that
      still shows the old publication after reinstall. Boundary crossed: a key taken on trust
      through the relay hands the relay the session.
- [ ] **CNF-109 · BLOCKING** The LNVPS retrieved pin route (`CHN-R7`, `ARC-43`) reads only
      the recorded machine status response by direct browser fetch over browser-terminated
      TLS, and takes only its published host-key field as an installed-system pin. With a
      complete Ed25519, RSA and ECDSA set containing all fingerprints observed in the
      current installation and disjoint from every observation and installed-system pin of
      any source in earlier installations of that machine, first contact presenting any
      member is admitted against that pin;
      a presented key outside the set halts without an accepted session (`SEC-11`), on first
      and later contact. Exercise a partial reading completed in the same installation,
      a contradictory complete candidate there, and overlap with an earlier installation's
      incomplete, refused, or older-than-last observation, and with earlier job-read and attest
      pins. Also exercise an exact old job-pin repeat, a disjoint publication after a job pin,
      and another machine whose history shares a fingerprint. Refused observations that add
      fingerprints remain in comparison history. Repeated empty, exact, reordered, and
      subset readings do not grow that history; a reinstall opens a distinct group even
      when its first reading is empty. A job read or attest can open an initial group with
      no observation. Vendor-API reinstall retires every source's installed pin and
      preserves groups across restart; a new valid published, job-read, or unused eligible
      attest introduction can pin under its own rules. A consumed attest introduction stays
      consumed. Without reinstall, no source replaces an active installed pin, including
      a job-read attempt after a published pin. Another machine's history neither blocks nor
      admits this one.
      Inspect the trust display: the pin is labelled **retrieved from the vendor's hypervisor
      scan**, never attested, and the residual is stated as **the vendor, and anyone able to
      answer on the machine's address inside the vendor's network at scan time** (`TRU-E1`,
      `TRU-E13`). The disclosure and every refusal block this route. Export and Restore keep
      `lnvps_retrieve` provenance and installation groups with the pin (`CNF-84`); they do not start
      a new first contact. A pin admitted after an empty prior installation group does not
      confirm reinstall; `STG-21a` says "An empty prior group can admit a pin under `CHN-R7` but cannot confirm this
      reinstall; the cloud barrier and existing permitted-read rules still apply independently."
      An operation receipt or
      status field outside the admitted key field never supplies a pin or survival evidence.
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
      pinned minirootfs, and fails otherwise. On an unpinned installation (`ARC-25`), the
      distribution's own signature checking stays on: an unsigned package is refused, and a
      command lowering the check is refused before it is sent. Boundary-crossed: otherwise
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
      addresses, including a co-tenant allowlist of shared egress. Check eligible-target
      reachability on arbitrary ports; self/environment exclusions and unavailable destination
      families yield unavailable coverage, never closed ports or successful outside-in
      verification. Demonstrate an eligible external route before claiming excluded-target
      coverage (`ARC-41`).
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
      or explicit empty sets. In the stage-1 systemd case, refuse a service name outside
      `ARC-43`'s grammar or byte bound, an instance or unsupported suffix, and a missing or
      malformed service scope/account under the declaration format. Inspect the composed
      command for the `.service` suffix, `--` and wrapper quoting; typed values never become
      shell syntax. Refuse declaration version 1; version 2 is required.
- [ ] **CNF-108 · PRE-SCALE** A delivered maintained machine is re-entered by a later session
      over the same pinned channel, and that session re-runs the delivery check against the
      journaled declaration (`STG-9`, `ARC-26`). Verified by ending the first session, binding
      a new one to the machine, and confirming no new first contact is made, a changed host key
      halts, and the re-check's verdict replaces the earlier one only through findings it
      raises or clears. The machine's unpinned installation is shown at binding and not
      accepted again. Where the session acts on a goal — necessarily a new one (`ARC-11a`) —
      acting with no brief is accepted with it before the model's first command; a session
      that only re-runs the check accepts no mode (`SEC-14`).
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
      states its outbound destinations and its always-on service, and, where it has its own model
      and its secret is placed, the trust display lists its model provider beside it (`TRU-E12`
      says "listed in the trust display beside the application for as long as its secret is placed").
      Recovery of these facts is covered by `CNF-84` under `STA-16`. Where those destinations are declared as
      `listeners.outbound` restrictions, the delivery check finds each in place: verified by
      removing one declared restriction and confirming the check reports the difference as a
      finding. No harness credential is on that machine (`ARC-1`, `CNF-11`); on an attest
      route, the sender key's metadata copy is the one introduction exception (`CNF-61`).
- [ ] **CNF-50 · BLOCKING** An **undeclared** listener is reported as a finding. Verified by
      starting one and confirming both the delivery check and a scanner run name it.
- [ ] **CNF-51 · PRE-SCALE** A declared listener is **not** reported as a finding, so the check
      is usable on a machine whose product is reachable ports.
- [ ] **CNF-53 · PRE-SCALE** The declared **service lifecycle** is demonstrated as declared, and
      the harness asserts nothing beyond it. A tenant declaring a service enabled and
      restart-surviving has that verified when the operator opts into the reboot, otherwise
      labelled; a tenant declaring a deliberately non-durable node
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
      Exercise `ARC-43`'s survival evidence: with an explicit yes after the last placement,
      record the old boot identity, reboot, reconnect on the pin, establish a new boot identity
      and active unit, and run the delivery check before any model command. At LNVPS,
      an exact-call restart receipt clears the cloud barrier; `STG-21a` says
      "It does not establish a completed guest boot or service survival."
      New boot identity and active unit are still independently required. Without
      that receipt the barrier holds; a disposition with a continuation that continues retains
      its unknown outcome and adds no survival evidence. A restriction
      dropped at boot becomes a finding. Declining leaves Delivered with "enabled, restart
      not demonstrated" beside it on the delivery card and trust display, with no lifecycle
      finding. With no enabled-survives-reboot service, no reboot is offered. With an
      enabled-survives-reboot service and a co-declared running-at-delivery service, no reboot
      is offered; with no demonstrated reboot, Delivered carries "enabled, restart not
      demonstrated" on the delivery card and trust display, with no lifecycle finding. On
      re-entry, unit/enablement changes alone offer it again;
      unchanged units do not. A boot-identity change since the last check plus a re-check
      demonstrates survival and lifts the label. A user-scope unit without `Linger=yes`
      raises a lifecycle finding; its read uses its account's manager, never the system manager.
      The reboot's own record settles it with no disposition when collection reads it for that
      machine on a new boot, whatever exit code it carries (usually exit 0, written before shutdown)
      and also when the reboot stopped the job before its record was marked complete; an exit or
      `Ended` read on the old boot, a missing record, an incomplete one with no boot of its own or
      read on its own boot, and another machine's record keep it held; a settlement append that did
      not land leaves it held across replay, and one that landed settles on replay; a model box-plane
      request after the yes journaled with the reboot's intent and before the delivery check's
      verdict, including after the reboot settled, is held; an `exec` of the same reboot command settles by its exit like any command and
      holds when it reads `Ended` or an incomplete record; the settlement is refused for a missing
      yes, the wrong call, and LNVPS's typed restart.
      A model command in flight at the yes holds the reboot, and its later issue asks again;
      that held reboot starts no pending-check hold before its yes is journaled with its intent.
      After the reboot settles, a delivery-check read ends without an exit; its disposition
      with a continuation that continues releases `STA-20`'s hold. No verdict comes, and the
      model's request stays held until the operator's journaled stop, which shows the check as
      stopped, never as a pass.
      After a disposition with a destructive continuation, a new-boot record arriving later
      does not lift the restriction.
      For running-at-delivery, stopped on the same boot is a finding at re-entry; after a
      restart, the note "stopped since a restart, as approved" shows and there is no finding.
      A crash finding followed by a restart stays until the service is found running; a
      never-found-running service still binds. A placing session needs every such service
      running after its last placement, and the note does not count: stopped is a lifecycle
      finding there. An explicit declaration amendment still clears through a re-check:
      withdrawing the promise and re-checking clears the flag; putting the promise back makes
      a stopped service a finding, not the note, until a check finds it running; an edit that
      keeps the promise leaves a standing finding standing and leaves a note a note.
      Re-entry reads every declared service's unit and enablement only for
      enabled-survives-reboot services.
- [ ] **CNF-52 · BLOCKING** On a multi-tenant machine, no spendable key material is present
      (`ARC-37`). Verified by searching the machine for private key material after a full
      install; watch-only public material is expected and permitted. BLOCKING because a wallet
      on a box hosting strangers is the escaped-secret family, and a leak outlives the incident.

## Relay access — `CHN-15`, `CHN-16`

The shared relay demonstrations are at [paid-tcp-relay][relay-source]
(`05-conformance-checklist.md`). That checklist and its fixtures define demonstrations and
data, not an executable suite. The relay implementation owns its executable suite and
conformance record; the harness integration owns a separate client-observable record against
the actual live public base and controlled, recorded destinations. Both records identify the
same implementation/artifact and the selected revision/profile of `CHN-15`. Each identifies
build inputs/artifact digest, intended/effective configuration digest as applicable, exact
commands/status, cases, controls, observation points and exclusions. The live record MUST cite
a deployment record binding its public base to the running artifact digest and effective
configuration; equality of source commits alone is insufficient.

Keep source/static intent, isolated executable results, isolated enforcement, effective
deployment inspections with bounded controlled canaries, and live-public-base client results
distinct. A local/fixture pass cannot discharge required deployment/live assertions. Attribute
every assertion to an observation point that can establish it, with a control that detects its
violation. For every required assertion, record passing evidence or an explicit pending status
and named admission blocker. Correctly bound relay/consumer records may be referenced; do not
require a live repetition to replace adequate evidence at its required observation point.
Pending required deployment/live evidence blocks the relevant admission and stage completion,
while honest local results remain recordable.

Changes to the effective artifact/configuration, network path/policy, capture/collection
components, address inventory, TLS or relevant retained state invalidate affected evidence and
require re-demonstration. Confine instrumentation to synthetic traffic; retained bounded
verdict/configuration/control records MUST NOT contain real-holder topology. These rules apply
to the relay evidence in `CNF-81`, `CNF-87` and `CNF-113`.

- [ ] **CNF-57 · BLOCKING** An unpaid caller is refused: the relay the harness uses is not usable
      without a valid, unexpired, unrevoked pass bound to the key that signs the challenge, and a
      replayed challenge signature is refused (`CHN-15`; [paid-tcp-relay][relay-source] `PAS-1`, `PAS-3`,
      `WIR-6`).
- [ ] **CNF-58 · BLOCKING** A pass reaches only its recorded destinations, on any port where
      eligible under [paid-tcp-relay][relay-source] DST-4. Demonstrate whole-host exclusions
      reported as unavailable coverage rather than closed ports or successful outside-in
      verification, and an unrelated eligible public target on SSH and other ports (`CHN-16`,
      `ARC-41`; shared DST-1, DST-2).
- [ ] **CNF-65 · BLOCKING** Probing a recorded destination is **paced**, and `ARC-26`'s per-run and
      per-target limits hold against the rate the relay actually allows (`CHN-16`; [paid-tcp-relay][relay-source]
      `DST-3`). BLOCKING because pacing is the whole of what stops a wide port range being the
      open proxy `CHN-8` forbids.
- [ ] **CNF-59 · PRE-SCALE** Obtaining a pass requires no account, no email address and no
      identifier the operator supplies beyond a derived public key, and the relay holds nothing
      that links two purchases (`CHN-15`; [paid-tcp-relay][relay-source] `PAS-1`, `PAS-2`).
- [ ] **CNF-60 · PRE-SCALE** A revoked pass stops working immediately, including on a
      connection already open, and revocation is a message signed by the pass's key (`CHN-16`;
      [paid-tcp-relay][relay-source] `PAS-5`).
- [ ] **CNF-76 · BLOCKING** Recording a destination against a pass requires that pass's key's
      signature (`CHN-16`; [paid-tcp-relay][relay-source] `PAS-4`). Boundary-crossed: without it, anyone who
      learns a pass's public key can widen it.

## Approval and recording — `SEC-4`, `SEC-12`

- [ ] **CNF-26 · BLOCKING** A typed operation naming a machine outside the calling session's
      bound set is **refused by the adapter**, before any approval screen renders. One vendor
      credential supplied to two sessions changes nothing: each is refused the other's
      machines. The deterministic abandonment flow (`SEC-4`, `ARC-21`) is refused on a machine
      whose vendor id this setup's own create response never mapped and for which no evidence
      tied to the seed-derived key exists, even if a sheet imported that mapping. The same id
      with this setup's create response or admissible key-tied evidence is permitted subject
      to the other checks. Boundary crossed.
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
      on LNVPS it comes over TLS from the vendor's recorded HTTP order or renew response;
      under an untyped vendor scope it is decoded by harness code from the recorded response
      (`SEC-4`). Before wallet handoff, demonstrate with distinct fixture invoices: successful
      vendor-TLS reads from an order response and a renew response each hand that response's
      invoice to the wallet, associated with its approved machine entry and amount shown beside
      the approved cost; under an untyped vendor scope, harness code decodes an invoice from
      the recorded response and hands that invoice to the wallet with the same entry and cost
      association; a different invoice presented in model text never reaches the wallet;
      when neither LNVPS response supplies an invoice, none reaches the wallet. After an LNVPS
      order, a fixture vendor that reports automatic renewal on is set off and read back off
      before the machine is offered for delivery (`STG-21`, `STG-21a`). Expected previously
      recorded subscription id plus authoritative false passes, including after a lost write
      response; false/None fallback, missing or mismatched baseline subscription and unreadable
      response keep delivery blocked. Before ordering, exact expected account and email with
      email_verified=true passes; false, omitted/null, different email/key, HTML success and
      PATCH success do not. A stored expired token plus repeated PATCH mints nothing; opening
      the original link with successful clearance followed by explicitly requested same-address
      PATCH can reissue. Failed clearing, unavailable link or replacement has honest external
      recovery or abandonment fallback, with no mail access, alternate address or automatic
      resend. A verification read whose append fails permits no order, including after replay;
      a durably appended verification read survives replay. The app holds no funds at any step
      (`SEC-13`). Money out.
- [ ] **CNF-105 · BLOCKING** While a call under an untyped vendor scope is open or unresolved,
      no box-plane command is dispatched to any machine of the session's bound set at that
      vendor, until the call's terminal record (`STA-24`). Where that record is a disposition
      that continues, the pause ends. Where it names a destructive reinstall or abandonment,
      every further call under the scope is refused and the model's box-plane commands to those
      machines stay stopped until the operator replaces the disposition; acting at the vendor
      by hand releases nothing; and before either destructive choice the screen says that the
      harness cannot carry it out there and that the operator acts at the vendor by hand.
      Verified by withholding a vendor response and requesting a disk-writing command, then
      disposing each way and requesting a further call and the command again.
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
      dedicated path's case; `STA-24`'s permitted reads are not refused.
      A second allocation index for the same approved machine entry does not evade the
      refusal; a different approved entry remains permitted. A status read whose journal
      append fails leaves the barrier standing; an operator disposition ends the unresolved
      state of the calls it names and keeps their outcome unknown; what it restricts afterwards
      is `STA-24`'s, and `CNF-110` tests it. Verified with a lost response to a
      Robot reset followed by the model requesting the reset again. Money out and destroyed
      data: an autonomous caller must not turn a lost response into another wipe or another
      purchase. For LNVPS operation evidence, failed append and replay pairs, see `CNF-112`.
      Stage 1: the create, box-plane and inference cases; the Robot cases run on the
      dedicated test bed; the untyped-scope cases pass before that capability is enabled.
- [ ] **CNF-110 · BLOCKING** A standing operator disposition restricts what the calls it names
      barred and, under a destructive continuation, every box-plane job to the machine,
      whoever starts it, and apart from the untyped-scope hold (`CNF-105`) nothing else (`STA-24`).
      With a call that changes what the machine is running
      left unresolved and disposed: a box-plane command to that machine, a harness-owned job the
      model requests included, is refused under a destructive reinstall and under abandonment, and so is every cloud-plane operation the
      continuation does not permit; under either continuation that continues the command is
      dispatched, and so is the same operation requested again under a fresh call id where no
      other call is unresolved, and the operator's recorded assumption is shown and never
      written as an outcome. With an
      unresolved activation, key registration or create disposed to continue, a box-plane
      command is dispatched; with any call disposed toward a destructive reinstall or
      abandonment, an unresolved box-plane command or activation included, the model's command
      is refused. In every case a status read, a pinned SSH attempt, the collection of job
      records and the inference request are dispatched and do not end the restriction: the
      model's command that the disposition refused before one is refused after it.
      Under each of destructive reinstall and abandonment, Replace's key install and old-key
      removal, `digest_secret` and a delivery-check read composed by the harness are refused;
      the permitted reads still pass. These refusal cases run at stage 1.
      The restriction ends at the dispatch of
      the continuation and not before: from that intent the call's own barrier refuses, and
      nothing is refused under the disposition. A disposition naming no call, a call already
      settled, or a call on another resource is refused, journals nothing, and shows the
      operator the refusal, the record that settled the call if one did, and what is unresolved
      now; one naming some of several unresolved calls leaves the others barring. A replacement
      naming the calls the standing disposition disposed is accepted, the operator is shown what
      it replaces, and the continuation in force is then the replacement's: with a destructive
      reinstall replaced by abandonment, the reinstall is refused. A session's destroy under
      abandonment is refused too; the flow's destroy stays barred when its disposition names only
      some unresolved calls, and is permitted once none remain, subject to authorization and approval. At LNVPS renewal-off waits for
      confirmation of the stop. A replacement that omits calls lists them, leaves their outcome
      unknown and settled under the replaced record, adds no restriction through them, and
      refuses ever naming them again, including at LNVPS. These are stage-1 cases.
      On the dedicated test bed, the harness-composed `delivery_reboot` and
      `replace_root_label` are each refused under both destructive continuations.
      With no reinstall approval standing, replace a reinstall by a
      continuing disposition naming only its unresolved activation: the screen says the reinstall
      is cancelled, commands resume, and any reset is admitted subject to other checks, possibly
      booting the installed system while the activation's state is unknown; it offers "retry the
      activation, keep the reinstall" with the activation and reinstall continuation. A replayed
      journal that already holds a disposition this test refuses ends no call and restricts
      nothing, and the record is shown; a valid replacement is still the one in force after a
      restart (`STA-7`).
      Evidence appended after a disposition about a call it disposed neither reopens that call
      nor removes the disposition; a read of the rescue activation decides which reset counts
      (`STA-24`). Destroyed
      data and money out: a command writes the disks of a machine the operator chose to wipe or
      abandon, or a status read hands that machine back to the session. Stage 1: the cases a
      vendor reinstall call, a create, a box-plane command and the inference request reach; the
      reset into rescue — the rescue activation and a key registration admitted without ending
      the restriction; a reset with no confirmed rescue activation refused; after confirmation,
      a reset whose newest journaled activation read reports it inactive refused with the
      disposition still standing; and a reset after a re-read that confirms it admitted and
      ending the restriction — runs on the dedicated test bed. There, an activation confirmed
      before the standing disposition, or dispatched under a disposition since replaced, does
      not count; a fresh activation confirmed under the standing choice does. Include a fresh
      activation requested and dispatched after the standing disposition while rescue remains
      armed, whether the vendor accepts or refuses that second activation. Record Robot's
      actual answer in the test record; whether it refuses there is unverified. In either case,
      the activation predicate read (`STG-4`, `GET /boot/{n}/rescue`) decides confirmation,
      independently of the activation response. Exercise a read that still confirms it:
      the subsequent reset into rescue is admitted and ends the restriction. The untyped-scope
      hold is `CNF-105`.
- [ ] **CNF-30 · BLOCKING** Box-plane commands are recorded per command before transmission,
      and the transcript reconciles against what was sent (`ARC-8`).
- [ ] **CNF-31 · PRE-SCALE** A scoped call is sent with redirect following disabled, and a
      redirect response ends the call (`ARC-6`).
- [ ] **CNF-32 · PRE-SCALE** An origin's route is selected by a dedicated no-side-effect probe
      before any side-effecting call exists, and a real call's failure never selects a new
      route. For the bundle probe's per-route CORS conformance, see `CNF-4`.
- [ ] **CNF-33 · PRE-SCALE** The approval screen for an untyped scope does not present the
      scope as a bound on what the credential can do.

- [ ] **CNF-112 · BLOCKING** LNVPS operation evidence (`STA-5`, `STA-24`, `STG-21a`,
      `ARC-22`, `SEC-5`, `ARC-43`) is operation-limited. Inject the following fixture pairs,
      with failed durable append and replay for every admitted path. A failed append applies
      no confirmation or deletion consequence, including after replay. Successful replay
      retains the recorded result and associations. Run the fresh-call-id, changed-index for
      the same entry, successor-session and different-entry barrier pairs in `CNF-29`/`CNF-110`
      against these operations. Generic 2xx, malformed response, wrong call/signed request,
      account or target, arbitrary response, box-plane output, notify event and proposed text
      confirm no cloud operation. Robot's mutation-response refusal stays intact.
      - Order: a validated exact-call receipt confirms only its returned VM id and durable
        entry association. A missing returned id or absent, wrong-entry or failed-append
        association leaves the order unresolved, including after replay.
        Lost response plus one exact matching unassociated candidate in a
        complete decoded listing confirms even with unrelated nonmatches present. Zero leaves
        unresolved, including after unpaid purge; multiple matching candidates require
        inspection and show each may bill. Partial/truncated/malformed listing, wrong account,
        image, full standard/custom resources, client key or ssh_key.id, and already-associated
        id refuse. Adoption sends no new order and establishes no host/IP creation, invoice,
        payment, boot or readiness. Key-list reconciliation confirms registration; its lost
        insertion response cannot trigger a duplicate insertion. Account PATCH and
        invoice-producing renew never retry automatically; a new call id or session cannot
        bypass an unresolved mutation.
      - Stop: exact-call successful receipt confirms even with stale/running cache. A wrong-call
        receipt, lost/error/timeout response, cached stopped/default/unknown, advancing timestamp
        or delayed pre-dispatch observation written to cache after dispatch cannot confirm.
        Subsequent running is displayed without reopening the settled call. Stop retains
        outstanding-machine and placed-secret duties and proves no billing cessation.
      - Restart: only exact-call hard-reset task success confirms. Running, lower/same uptime,
        power transitions or key equality cannot identify a lost reset. Boot/job/keyscan output
        cannot clear the cloud barrier; completed guest boot and service survival stay independent.
      - Renewal-off: authoritative false with the expected previously recorded subscription
        confirms even after lost response. False/None fallback, true, missing/mismatched
        subscription, missing baseline and malformed/unreadable result leave unresolved.
        Abandonment renewal-off still waits for stop confirmation; neither ends billing duties.
      - Reinstall: complete prior durable nonempty publication followed by running with a complete
        disjoint successor containing current-group knowledge confirms without observing empty.
        Empty baseline plus queued initial-boot fill, partial baseline plus same-algorithm key
        replacement, partial/overlapping/current-group-contradictory candidate, image, power,
        uptime or reinstall 2xx do not. Preserve incomplete/refused observations and pins from
        every source. A stale old-key poll can conservatively prevent later success; do not
        erase it. Pin admission after empty history does not confirm the operation. Timeout
        proves neither failed nor ended; deadlines, permitted reads and scan residual stay intact.
      - Deletion: ordinary host-first soft/hard deletion satisfying every combined read confirms
        and ends the destruction-bound duties. Inventory absence alone, transfer 403, transfer
        then soft delete yielding 403, wrong key, partial/malformed listing, bare/undecodable
        404, 401/403 auth failure, standalone 404/500, elapsed date or SSH loss do not.
        Lost key retains duties, with no operator-carried evidence admission. The durable
        constituent deletion record does not settle a distinct unresolved stop or renewal call.
        Preserve both source-derived administrative-race traces: (a) transfer, original-account
        listing omission, ignored account insert, emptied-account purge, account-id lookup 404
        before VM lookup; (b) receiving-account purge's zero-live guard, transfer of an unpaid
        admin-extended VM, purge transaction removing its row without host teardown, then the
        original verified account's successful combined reads. In both, the chosen conjunction
        is true and host destruction false; confirmation and duty-ending effects are nevertheless
        admitted under the expressly accepted improbable-staff-transfer risk; `TRU-E1` says
        "Both can satisfy the combined reads without host destruction."
        Include ordinary host-first soft deletion followed by later paid-subscription un-delete
        and rebuild: record the billing-display gap and no permanent-absence completion claim;
        no post-confirmation reappearance handling is required. These are fixture/source traces,
        not claimed live observations. Escaped secret, destroyed data and money out: an
        unsupported confirmation can lift barriers or end duties while a host still survives.

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
      (confirmed only by a host-key set on `/rescue/last` sharing no fingerprint with the durably recorded
      pre-reset set); the reset into the installed system (confirmed only by sshd answering
      with the installed pin); and a case where none of those holds, which stays unresolved
      with no automatic retry and need not finish (`STG-4`). In the first three, reconciliation
      lets the ceremony finish without repeating the interrupted mutation. A reordered
      pre-reset set or one sharing a pre-reset fingerprint leaves the rescue reset unresolved,
      including after an intervening empty field; a fresh disjoint set confirms it. A recorded
      empty pre-reset field is a valid baseline: a later fresh nonempty set confirms the reset
      and admits a matching rescue session, while a field never read before reset does not.
      In every case the
      mutation is requested again under a fresh call id before confirmation and is refused
      while the reconciliation reads stay available; an immediate `running`, a changed
      `boot_time`, or a job record claiming success does not substitute for the predicate
      (`STA-24`). Every reset into rescue, ordinary ceremony, disposition's return and the reset a
      reinstall approval binds included, has an immediately preceding durably journaled
      activation read (`STG-4`). The approval-bound reset needs an activation dispatched since
      that approval (`STG-20`). A confirming read satisfies the read condition; withdrawal and
      the since-approval condition can still refuse that reset. A non-confirming read and a
      failed read append each refuse it visibly, with no reset dispatched. A late reset after
      first contact remains the residual described in `STA-24`; pin matching before contact does
      not assert protection after contact.
- [ ] **CNF-39 · PRE-SCALE** After a killed worker, replay classifies incomplete calls, cancels
      those that cannot still exist, and surfaces uncertain ones without resuming them
      (`STA-7`).
- [ ] **CNF-40 · BLOCKING** A command still running when the session dropped is **not** re-run
      on reconnect. Verified by starting a long command, killing the session, and confirming the
      returning session waits on the job record rather than launching a second one (`STA-20`),
      also under a new call id, through `exec` and `request_harness_job`, after a reconnect,
      with the worker alive after a dropped connection, in a successor session, and for two
      requests made together: the later request is not run, records no intent, and its result
      carries the earlier record; a held read is held too; a missing, incomplete or ended record
      keeps the machine held until a finished record of any command but `delivery_reboot`,
      `delivery_reboot`'s boot change, or the operator's disposition; a call disposed with
      a continuation that continues holds nothing,
      and a destructive one still stops every box-plane job; collection started while the earlier call's own dispatch awaits its record
      appends no second result; a held harness-initiated job is issued once after release under
      one intent, and a stopped wait issues nothing, across replay too; another machine is
      unaffected. This is the corruption case, which is why it blocks.
- [ ] **CNF-54 · PRE-SCALE** A completed command's exit code and output are read from the job
      record after a session drop, not inferred from machine state.
- [ ] **CNF-55 · PRE-SCALE** An installed-system job record survives a reboot. Its boot identity
      establishes that an unfinished old command ended; it stays unresolved until disposition.
      `ARC-43`'s `delivery_reboot` settles by its boot change; an ordinary finished record settles
      by its exit code.
      A missing record remains unresolved. Rescue follows `CNF-86`, not a persistence claim.
- [ ] **CNF-56 · PRE-SCALE** The command recorded by the machine matches the command the
      browser journal recorded before sending. A mismatch is surfaced as a finding, and is
      never described as verification (`STA-21`).
- [ ] **CNF-80 · PRE-SCALE** An installed system that does not answer on the channel within
      `installed.wait_max` (`bundle/timing.toml`) of its boot reset is declared failed, the operator is told, and a separately approved destructive reinstall
      returns to rescue from the brief (`STG-20`). Test a missing bootloader and a relay outage: neither a timeout nor
      unreachability clears unresolved operations or triggers a wipe without that decision.
      At the destructive reinstall's dispatch, the reset into rescue on this path, the old
      installed pin is retired; the choice alone retires nothing. The next job read can establish
      a new one, and the installed contact uses that new pin. A second job read without the
      destructive reinstall cannot replace an active pin.
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
      At LNVPS the stop that stands in for a destroy never drops one either.
- [ ] **CNF-93 · BLOCKING** An acceptable weaker mode is accepted by its label for one bound
      set before the first contact it governs — an acceptance after that contact is
      refused — and is never entered by failing
      (`SEC-14`). Verified by these cases: accepting a mode after the first contact it governs is
      refused; an artifact that fails its pin halts and the machine
      does not continue unpinned (`ARC-25`); an installation with no pin is recorded and shown
      as **unpinned**, with no hash or signer named (`ARC-25a`); and every mode standing on a
      set is shown in the trust display and restated, together, at each later irreversible
      act on any machine of the set — a placed secret, a paid invoice, a destroy or reinstall,
      an added machine; and in a later session re-entering the machine (`STG-9`), its history
      modes are shown at binding and restated, with that session's own modes and what earlier
      modes left live, at an irreversible act the test performs there — a placement or a
      rotation — without being accepted again; a model command under a goal with no brief
      before that goal's acceptance is refused; and, on the jump-host route, a reinstall is
      accepted again as an installation and a first contact before it is sent (`CHN-R6`). Escaped secret: a secret placed on a
      set whose standing modes the operator was never shown together.
- [ ] **CNF-43 · PRE-SCALE** The relay's row names its operator and states that it learns the
      machine topology (`CHN-13`).
- [ ] **CNF-44 · DEFERRED** Nothing in the interface uses the words "verified" or "no anomalies
      found" (`SEC-2`), nor "proven", "formally verified" or "machine-checked": the formal
      companion (ADR-0032) proves properties of this specification's definitions and nothing
      about a machine, and a phone screen has no room for that distinction. The trust display
      does not call the bundle "signed" until `OPN-15` closes (glossary, *Signed bundle*).
      Seed-backup display distinguishes full re-entry from skip and calls neither verified
      (`SEC-2`). Wherever Delivered appears for a machine declaring an
      `enabled-survives-reboot` service with no demonstrated reboot, carry `ARC-43`'s evidence label.
      Carry "stopped since a restart, as approved" wherever Delivered appears when `ARC-43`'s
      running-at-delivery note applies.

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

- [ ] **CNF-81 · BLOCKING** A recorded destination still cannot reach relay-private services
      (`CHN-16a`; [paid-tcp-relay][relay-source] DST-4–DST-7, CNF-14). Demonstrate application
      refusal at registration and every dial, including DNS answers, normalized forms, changed
      inventory before queued initiation and unrelated public positive controls. Separate
      injected-inventory results from effective deployment self-address completeness. For the
      publisher default, also pass `CNF-113`; for its mandatory independent barrier and
      precisely declared private resolver TCP/53 exception outside that second wall, see
      `CHN-11`. An application refusal or client timeout establishes no independent denial.
      Before enabling self-host migration, demonstrate SSH re-entry and scanning of the relay
      host through a retained external relay; migration without that route is refused
      (`CHN-11`; shared OPR-4). This migration case remains deferred until that capability is
      enabled. Boundary-crossed: a pass must not grant the relay's private network position.
- [ ] **CNF-82 · BLOCKING** Local storage follows `STA-23`: wrong passphrases, modified
      envelopes/records, cross-store substitution and unknown formats fail closed; no new
      empty store replaces failed decryption. Reload and background/explicit lock require
      unlock again, session workers lose access, and replay preserves unresolved actions.
      Inspect persisted bytes and worker inputs for forbidden plaintext keys. Exercise the
      persistent-storage request and visible refusal; the UI promises no immunity from loss.
      Exercise the generated-seed ceremony at create, creation-finishing unlock and Replace:
      words are always shown outside sessions, hidden while answering, and all twelve words
      are checked as an import yielding the same seed id; a mismatch returns to the display.
      Full re-entry and explicit skip are journaled distinctly and neither is shown as a
      verified backup. Close the tab, hide the page and kill the worker before completion:
      the next unlock still owes the ceremony. A failed append leaves it owed. Re-display
      requires the passphrase again, ends sessions and uses the same ceremony; no other
      display exists. Imported seeds, with sheet or store backup, owe no ceremony.
      Escaped-secret.
- [ ] **CNF-111 · BLOCKING** Worker policy admission (`ARC-32`, `ARC-33`): in the harness
      worker's own context, `import()` of a `data:` module and a cross-origin module,
      `eval` and `Function` are refused. The self-check runs first, before dependencies load
      by dynamic import. With no response header the worker refuses to unlock, saying why
      (negative control); with the policy present, wasm loads and the store opens (positive
      control). A session worker not under the policy refuses credentials, saying why.
      Escaped secret: the harness worker holds the data key and seed.
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
      an unpinned installation and an attested pin restores both. Export and Restore a
      `CHN-R7` installed-system pin too: the distinct `lnvps_retrieve` route survives with
      the stored pin and its retrieval disclosure, while the installation's artifact-pin
      status remains independent. Restore reconnects under that existing pin, not a new
      first contact, only after the vendor's current published set reads complete and equal
      to it; with a fixture vendor reporting an empty or different set, or the status read
      failing, no contact is made, no pin is retired and no new first contact opens on that
      reading: the machine is unresolved until the operator chooses a reinstall or
      abandonment. Round-trip the recorded installation groups, including incomplete and
      refused observations, an initial empty group opened by a job read or attest, empty
      reinstall boundaries and the active or retired status of pins from
      each source. Export and Restore a pin admitted after separate partial observations
      whose complete candidate adds no new fingerprint and leaves no complete observation
      in the group. After Restore, a same-installation completion can admit a pin; after a
      later operator reinstall, a candidate sharing a fingerprint with an older group's
      observation or installed pin of any source is
      refused. A separate active-pin case reconnects under its existing route, while a
      retired pin never authorizes a new contact. Refuse a missing, unknown or malformed
      route, group, observation or installed-pin installation reference
      before binding; absent required data never becomes empty history. The sheet
      has `STA-16`'s placement metadata, pin routes and
      machine states; values, digests, scan keys and lengths are absent, and unsupported
      payload versions, explicitly including versions 1 and 2, are refused rather than read as
      having no placements or applications. In one recovery case export and restore machines
      with and without applications, including an application without its own model: inspect
      the explicit `applications: []` and `model_provider: "no_model"` representations of
      `docs/design/credential-format-v1.md`, and each named provider object. Refuse before
      binding a missing applications field, missing required member, duplicate object member,
      or malformed application or provider data. Refuse before binding two applications on
      one machine with the same exact name, both when their providers agree and when they differ;
      the same name on different machines remains valid. Recording a second application under
      a name already recorded on that machine is refused (`ARC-1a`), so no export can write a
      sheet its own import refuses. Refuse a placement with missing or
      malformed `application_name`, or one naming an application not recorded on that same
      machine, including a name recorded nowhere and one recorded only on another machine.
      Confirm the restored application/provider list is complete, including an application with
      a recorded provider and no restored secret placement: its provider remains recorded and is not listed in the
      trust display. Include a restored placement with distinct `application_name` and secret
      `name`; confirm its named application's provider is listed beside that application on its
      machine (`TRU-E12` says "listed in the trust display beside the
      application for as long as its secret is placed"). The restored facts stay labelled as of
      export, through a machine re-check, until the harness records that application again,
      without a new approval or any implication of current installation or provider state. The no-model marker and empty list never mean unapproved.
      An imported local-store backup's machines are shown unchecked, their findings unknown,
      and refuse a placement until a re-check, as a sheet Restore's do. No imported seed —
      from a current sheet or from a store backup — can allocate new identities;
      Replace with a fresh seed and its ceremony record restores allocation. A bare seed
      with neither sheet nor store backup is refused, explaining that a seed alone restores
      nothing and offering to bring the sheet or start fresh. Round-trip the ceremony record
      or explicit no-record marker; refuse malformed, duplicate or mismatched-seed records
      before binding. Cloud with no
      sheet exposes destroy/recreate, never an unpinned keyed-rescue login; at LNVPS `ARC-22`'s
      forms apply instead — a stop with renewal off for the destroy, and for the recreate a
      reinstall that is a new first contact. Missing relay
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
      the operator's disposition, never automatic re-execution (`STA-20b`, `STA-24`).
      Dispose command A with a continuation that continues, dispatch B, then replace A's
      disposition with a destructive reinstall: the return to rescue waits for B and collects
      its record, and does not wait for the disposed one or require its record; the reset into
      rescue is dispatched with its intent recorded and no installed pins.
      The installation id (`STG-20`) stays the same across restart and Restore; its machine
      component is distinct among machines allocated under the current seed. Check lowercase
      hexadecimal for the machine index and decimal for the installation ordinal, neither with
      leading zeros. The longest label `7fffffff-9999999` fits the root label. A reinstall that
      would make the ordinal 10 000 000 is refused before dispatch on both paths, saying that
      the installation id would exceed its limit. Replace moves the machine component to the
      new index and carries the ordinal; an unmigrated retired-seed index can coincide with
      a migrated machine's new index. Replace refuses to migrate an install unfinished in
      rescue (`STA-17`), including
      after `ready_to_reset` records pins and before the installed-system reset is confirmed;
      its screen names that machine as not yet migrated, says why, and does not report completion.
      After Replace migrates a completed dedicated machine with its relabel confirmed, a
      return to rescue without a destructive reinstall finds one root whose label equals
      the shown id. The install brief treats it as this installation — found complete or
      Resume — never as a predecessor. Also exercise an unconfirmed relabel whose write
      failed without changing the label: the machine keeps its old shown id, still equal
      to its unchanged label; the lost-read-back case is `CNF-20`'s (d).
      The ordinal moves at destructive reinstall dispatch, never at
      its choice: exercise both routes before its reset — replace a reinstall disposition with
      no approval standing, and withdraw a reinstall approval — and confirm the kept root still
      has the shown id. Also replace a reinstall disposition while a separate approval stands:
      choosing to keep the reinstall approval preserves it and its reset opens the installation;
      choosing withdrawal records the replacement and withdrawal separately, refuses that reset
      naming the withdrawal, and keeps the root's id and reset offer. Exercise the approval-only
      change of mind and refusal of withdrawal after dispatch (`STG-20`). End the rendering
      session after approval and before its reset, by lock and by worker restart: the approval
      is shown as no longer usable with no withdrawal offer, the successor cannot dispatch that
      reset under it, and it opens nothing. Approving again in the successor session, followed
      by a rescue activation dispatched since then and still confirmed, opens the installation
      at its reset. A fresh reinstall erases
      the approved predecessor, including an unmarked, foreign-id or hand-installed root, and
      labels the successor at formatting. Interrupt that successor and resume it under the same
      id without formatting again; a complete matching root is kept. Two matching roots or an
      unresolved label probe stop and surface without erasure. Exercise exit 2, empty output
      even at exit 0, other probe errors, and exit 0 with only partition-table or `LABEL_FATBOOT`
      tags. Only exit 0 with a line beginning `TYPE=` and no line beginning `LABEL=` establishes
      an unlabelled filesystem; exit 0 with a line beginning `LABEL=` supplies a label to compare.
      Continuing as if not done with an installed pin keeps the matching root and its keys
      (`STA-20b`). A changed-key `ready_to_reset` read withholds the offer and tells the operator
      before reboot. After reinstall, predecessor prerequisites cannot offer a reset. A first
      `ready_to_reset` read carrying an earlier installation's prerequisite or installed-pin keys,
      including partial overlap, withholds the offer and tells the operator before reboot;
      a later different read does not restore that installation's offer. Kept old keys are
      refused by the freshness backstop, including overlap with earlier observations.
      Disjoint successor keys can establish the new pin and offer the reset. `STG-20` says
      "The label steers the model; nothing checks it". Destroyed-data.
- [ ] **CNF-87 · BLOCKING** The first-stage relay uses the selected `/v2/` profile and a
      hand-recorded pass (`STG-18`; [paid-tcp-relay][relay-source] PAS-6). Demonstrate fresh
      challenge, unknown-key and replayed-signature refusal, recorded-only destination
      reachability, configured timing limits, challenge/AUTH/OK ordering, binary-before-OK
      and text-after-OK termination, **no dial before the AUTH is accepted** and no application
      byte before OK. Use the shared WIR-4–WIR-10 and WIR-12–WIR-13 cases below. Purchase and
      quota accounting remain outside this check. Boundary-crossed.

      For the `/v2/` profile, pass [paid-tcp-relay][relay-source] CNF-3–CNF-5, CNF-10,
      CNF-12–CNF-14 and, for publisher discovery, CNF-21. Include pacing across restart,
      concurrent replicas, aliases and domain moves; when event-derived state is lost, show
      conservative restart refusal. Demonstrate that pass edits are acknowledged only after
      inclusion in the running relay's authoritative state, including failed reload refusal,
      hand retirement/removal during pending, quiet and active connections, cancelled work
      and late successful dials. Include expiry and unrelated-destination positive controls.
      For the publisher default, also pass `CNF-113`.

      Observe attempted outbound initiation at the relay during refused AUTH, with a positive
      control that detects a deliberately early attempt even when no destination accepts it;
      separately observe no application bytes reaching the destination before OK, with its own
      positive control (shared CNF-4). Client refusals/timeouts prove neither assertion. The
      live integration matrix covers client-observable challenge/AUTH/OK ordering, admission
      refusals, recorded-only reachability, arbitrary ports, pacing and the required `/v2/`
      frame/termination behavior observable by its selected client API. Supported behavior
      does not narrow the selected protocol. Do not assume live-service loopback/private
      listeners, fixture pause controls or internal event logs; adapt client cases explicitly.

      At stage 1, apply shared CNF-9 to hand retirement and
      destination removal; require its signed-revocation demonstration before paid/public relay
      access, as the admission table specifies. Shared wire duties and fixtures have their single
      home in that set. For STA-17's manual replacement, confirm publisher retirement of the
      old pass; do not substitute hand retirement for the signed-revocation demonstration.

      Also demonstrate `CHN-19` and `SEC-8` with controlled signed-event fixtures and the
      publisher's public announcement: valid discovery and cached-within-expiry use; bad id,
      signature, key, schema and newly fetched future timestamp refusal; bounded fetch failure
      with and without a valid cache; expiry and empty withdrawal without fallback below a
      retained high-water event, including after local replay and sheet Restore when that record
      survives locally or in the sheet; greatest-timestamp/smallest-id ordering; discovery while
      the former TCP host is unavailable using an independently hosted endpoint; URL-order
      attempts and byte-exact challenge/AUTH binding; no retargeting of an open connection; and
      refusal of list-carried destination, host-pin, capability or policy changes. Open each
      configured alias under its own public origin and verify the matching advertised and AUTH
      names, another-alias refusal before dialing, and a non-default public port.

      Demonstrate that a retained withdrawal survives restart, concurrent discovery completion and
      an older sheet, including completion of a slower attempt after a newer record was retained.
      A retention failure blocks publisher-default contact. Separately demonstrate a fresh Restore
      whose sheet lacks the withdrawal, with discovery withholding or lacking that successor: an
      older still-unexpired signed event may be selected, and the display does not claim
      newest-state knowledge. Do not claim this proves that a conforming publisher or an honest
      current mirror has forgotten a still-valid successor.

      Export and import a version-4 locator and retained withdrawal. Import a correctly signed
      recorded event whose timestamp is ahead of the importing clock: preserve the event, block
      the publisher route while it is future, and do not reveal an older locator or reject
      unrelated valid sheet data for that clock difference. Explicitly convert a version-3 URL as
      direct even when it matches a published URL; preserve historical locator bytes and block a
      nonconforming value pending explicit correction. Show that a recovered publisher-key
      mismatch remains recorded and blocked until explicit migration. Record the observed
      outcomes; make the relevant case fail when each guarded refusal is removed.

- [ ] **CNF-113 · BLOCKING** Publisher-default hosting admission (`CHN-11`, `ARC-41`):
      inspect the effective admitted pod/init configuration, actual forwarding/TLS termination
      path, host collectors and all operated retention surfaces. Demonstrate relay-process TLS
      over L4 passthrough or a dedicated public port, with no destination-logging proxy or
      traffic/logging sidecar. Include certificate issuance/renewal, malformed requests,
      handshake failures, plaintext-origin and redirect/error paths, with no destination logs
      or plaintext fallback. Use [paid-tcp-relay][relay-source] CNF-19 for browser-accepted WSS
      and plain-ws refusal at the actual public origin; trusting a fixture certificate is not
      that public-origin check.

      Apply shared CNF-16 to the complete operated traffic/collection/storage path for
      successful, refused and sparse attempts: ingress/L4 forwarding, relay output/files,
      operated resolvers, node/network flow telemetry, error/debug/trace channels, metric
      labels/exemplars/series, collectors, rotations, backups and joined stores. Include
      retained source-IP/time-only records, connection-derived metrics and collector exports;
      deliberately retaining an event record or event-derived series makes the check fail.
      Identify observers outside operator control. Bounded/static inspection cannot establish
      historical absence of logs or deployment silence.

      Demonstrate shared CNF-14 with complete current self and declared environment
      inventories: pod/workload, underlying node, service/public front door, pod/service
      ranges, control-plane/metadata and shared-host services, including public addresses
      and both families. Include missing/stale/incomplete required inventory refusal,
      registration and every-dial checks, changed queued-dial inventory, DNS/normalized forms,
      unrelated public positive controls, unavailable-coverage reporting and source-privilege
      refusal of an equal-view claim. Treat actual destination-family reachability separately.

      Test application refusal and the independent workload-selecting barrier separately.
      In isolated enforcement tests, bypass the application guard and attempt forbidden,
      self and environment routes in both families. Record effective combined enforcement,
      host/node exceptions and routing/NAT. Exercise the precisely declared private resolver
      TCP/53 endpoint, neighboring addresses and other ports; show that only the declared
      route is excepted and state plainly if the tunnel connector can use it outside the
      second wall. Keep mandatory application refusal on that route. Include public SSH and
      other-port positive controls. Deliberately opening a forbidden rule must make the
      enforcement check fail. Local namespace/firewall tests establish only their tested
      setup, never a future deployment's enforcement.

      Separately inspect effective deployment routing/admission, running image, inventories,
      collectors, mounts/retention, TLS/certificate renewal, replica/reload configuration and
      pacing continuity, with bounded synthetic canaries and required observation controls.
      Bind that deployment to the implementation/artifact, effective configuration and live
      public base used by `CNF-87`. Record required unavailable assertions as pending admission
      blockers; source/static and isolated results alone never pass this item. Relevant
      operated-path changes invalidate affected evidence as the relay evidence introduction
      specifies. Boundary-crossed: publisher hosting must not grant an internal network
      position or retain connection history.

## Stage applicability and admission

This table is exhaustive; every new CNF item must acquire a row before it can gate a stage.
The stages are `06-first-stage.md`'s (`STG-21`, `STG-22`, `STG-23`). **Required** means that stage's completion report must
include passing evidence, even for PRE-SCALE items promoted by `STG-*`. Measurements must have
recorded values. Later features remain unavailable until their BLOCKING checks pass; deferral
never enables an untested capability. A broader deployment still applies the PRE-SCALE
promotion rule above.

| Applies when | CNF items | Interpretation |
|---|---|---|
| Stage 1: required | 1–7, 10–17, 21, 23–26, 28–30, 32, 34–35, 37, 39–44, 49–56, 66–73, 78–79, 81–83, 87–91, 93–95, 99–104, 109–111, 112 | One live LNVPS machine on catalogue plain Arch with no tenant, an initial session from the owner's goal and the later session `STG-9` requires (item 108) with a goal of its own, created through a typed adapter. First contact uses `CHN-R7`'s published-key route; item 23 requires no contact during its wait and item 109 requires published-pin admission, freshness, pin checking and disclosure on the integrated harness. Its new job-read pin admission, initial-group opening by a job read, and job-read attempt after a published pin belong to the dedicated row; its unused attest admission, initial-group opening by an attest, and consumed-introduction case belong to the attest row. Stage 1 keeps every case against earlier job-read and attest pins, on pins a Restore brings in, including item 84's "an initial empty group opened by a job read or attest". Synthetic unbound identities exercise 6 and 26. Item 7's growth and subset cases, and item 91's two-machine case, use fixtures until stage 2. Item 110 runs here the cases its own text assigns to stage 1. Item 12 is exercised with a hostile goal and a hostile fetched document; its untyped-scope restatement, and item 14's, wait for stage 2. Item 14 covers any root password the typed adapter's response carries. Item 23 covers unpinned-first-contact refusal; its attest-window case applies where attest is enabled, and its jump-host label waits for stage 2. Items 18 and 61 remain route-specific attest checks, required before enabling that route, not stage-1 requirements. Items 24 and 66 apply wherever the installation is pinned, and item 67's and item 93's unpinned cases wherever it is not; NixOS evidence is required before enabling NixOS. Interrupted resume (`STG-12`) is carried here by items 37, 39, 40 and 54–56; item 86's cases are a rescue boot's, and stay the test bed's. Item 95's stage-1 cases all require integrated evidence (`OPN-28`); cases (e) and (f) run here on M alone: every assertion but their A/B output-release assertions and case (e)'s copied-key assertions, which belong to stage 2. Item 53's `delivery_reboot` cases belong to the dedicated row: the own-record settlement and its append/replay cases; the hold after the journaled yes, including after the reboot settled; the missing-yes and wrong-call settlement refusals; the command in flight at the yes and its held unjournaled yes; the stopped pending-check case; and the late new-boot record under a destructive disposition. LNVPS's typed-restart survival evidence, its typed-restart settlement refusal, its typed-restart hold after the journaled yes including after the reboot settled, its typed-restart stopped pending-check case, the `exec` of the same reboot bytes and every other item-53 case stay here. Item 55's `delivery_reboot` settlement belongs to the dedicated row; the rest stays here. Item 50 covers the delivery check; its scanner half waits for scanner enablement. Item 10 covers local ledger persistence; its sheet-export half is the recovery row's. Item 72 covers local allocation; imported-state cases are 84. Item 81's migration case waits for self-host migration, which no stage yet offers. Item 32 covers the typed adapter's origin. Items 68–71, 78 and 88–90 apply to the procured inference path; bring-your-own and local inference have no aggregator to test. Item 88 uses injected list fixtures the way 17 uses an injected response. Item 42 covers placed secrets; its untyped-scope half waits for stage 2. Item 104 covers the LNVPS invoice and `ARC-30`'s TLS provenance, with no exemption; its untyped-scope case belongs to the stage-2 row. |
| Stage 1: publisher-default hosting | 113 | Required before admitting the publisher default and before stage 1 completes with it. Include the effective-deployment and live-origin evidence, with the precise resolver TCP/53 route outside the independent-denial guarantee where connector-usable. Isolated results remain recordable while required deployment assertions are pending; pending does not pass admission. This row does not impose the publisher profile on bring-your-own or a self-hosted migration target. |
| Stage 1: record measurements | 45–47 | Require the integrated browser channel, not the rehearsal's timings. |
| Stage 1: model-written check reports | 107 | The report label, verdict isolation and absence of automatic re-execution are required before stage 1 completes. |
| Stage 1: re-entry | 108 | `STG-9`'s later session, re-entering over the same pin and re-running the check, is required before stage 1 completes. Item 93's re-entry case runs with it, using a placement or rotation in the re-entering session. |
| Stage 1: recovery export/import and Replace | 19–20, 84 | Before maintained cloud delivery: export, Restore, allocation refusal, cloud destroy/recreate and partial-Replace cases pass, with item 10's export case. At LNVPS, `ARC-22` owns both forms: a destroy is a stop with renewal off, and a recreate is a reinstall that is a new first contact and cannot reuse the old pin. Item 84 checks `CHN-R7` provenance, earlier and refused publication knowledge, and pending pin retirement through sheet export and Restore; item 109 checks fresh admission after reinstall. Item 20 uses the manual publisher-confirmed pass retirement/enrollment route. Only item 20's relabel cases and item 84's Robot rescue case wait for the dedicated row; signed pass revocation waits for the paid/public row. |
| Attest first-contact route | 18, 23 (attest-window case), 61, 74–75, 109 (attest admission) | Before enabling attest at any vendor that accepts boot configuration, including one used for a jump host. This row does not gate LNVPS stage 1. |
| The dedicated path: the construction test bed | 20 (relabel cases), 22, 38, 48, 53 (`delivery_reboot` cases), 55 (`delivery_reboot` case), 62–64, 80, 84, 85–86, 109 (job-read admission), 110 | The Robot dedicated path's own checks, including item 20's relabel cases, only item 84's Robot rescue case, item 53's `delivery_reboot` cases, as the stage-1 row lists them, item 55's `delivery_reboot` settlement case, and item 110's reset-into-rescue, harness-composed `delivery_reboot` and `replace_root_label` refusal cases. Their by-hand evidence stands (48 is recorded), construction exercises them on the test bed, and they pass on the integrated harness before a dedicated-server path is offered to an operator, which no stage before the third does. Items 62–64 also apply to any typed adapter that rides the pinned tunnel, stage 1's included if its vendor refuses a browser origin. |
| Stage 2: a vendor with no adapter whose API the browser can reach (`CHN-12b`), the jump host, sets above one | 7, 12, 14, 23, 27, 29, 31, 33, 42, 91–93, 95 (cases (e) and (f)'s A/B assertions), 96–98, 104–106 | Before enabling an untyped scope, an untyped vendor scope, the jump-host route or a bound set of more than one machine. Item 95's cases (e) and (f) cover A/B output release only after both pastes; case (e) also covers the copied key on A redacted. Items 7 and 91 cover set growth, subsets and two-machine sets; items 12, 14 and 29 their untyped-scope cases; item 23 the jump-host label; item 42 the untyped-scope half of the trust display; item 93 the jump-host, untyped-scope and larger-set modes, each accepted at the act it governs and restated, with their re-entry and reinstall cases; item 104 an invoice decoded from an untyped response, where the vendor invoices. Item 92's multi-tenant case gates sets above one; its independence-bound case gates the first profile that declares a bound. Repeat item 17 against real untyped responses. |
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
before completion under `SEC-5`'s settled bound. On LNVPS, completion also
waits for T44's coordinated implementation of ADR-0042's decided vendor identity and recovery
behavior: Restore and Replace are demonstrated with that identity after its format is available,
never with one supplied ad hoc for the test. The accepted first-contact route is `CHN-R7`; its integrated checks in items 23 and 109 still gate completion. The recovery row, the
model-written check reports row and the re-entry row also pass.
No tenant's artifact gates this stage: lnrent's delivery declaration and briefs 2–3 gate the
third. Rehearsal/prototype results do not automatically check harness items. This is the
distinction between being ready to construct and ready to deliver.

Every BLOCKING addition must name an irreversible family: escaped secret, crossed boundary,
destroyed data or money out. Tier labels and applicability are separate: a federation blocker
can remain deferred while a first-stage PRE-SCALE behavior is required by that stage.

[relay-source]: https://github.com/douglaz/paid-tcp-relay/tree/49309df54dea3841f3cb1a37527f8d4ec9b5f1ab
