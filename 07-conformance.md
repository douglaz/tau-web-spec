# 07 — Conformance checklist

What an implementation must demonstrate before it touches a real vendor account. Each item
names the requirement it proves and is written so it can become a test.

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
- [ ] **CNF-6 · BLOCKING** A session presenting another session's keypair to a machine it is
      not bound to is **refused by SSH**. The harness is not consulted. *(`STG-13`)*
- [ ] **CNF-7 · BLOCKING** Binding is created by an operator act before any connection
      attempt. A connection attempt against an unbound machine does not create a binding, and
      is recorded as refused.
- [ ] **CNF-8 · BLOCKING** The coordinator holds **no channel to any machine, at any point**
      (`ARC-19a`), and its credential is peer-equivalent. Verified by inspecting what the
      coordinator is given — as `CNF-9` does for the scanner — rather than by attempting an
      access and observing refusal: what is under test is the absence of a credential, and a
      refusal test cannot distinguish that from a credential the harness declined to use.
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
- [ ] **CNF-77 · PRE-SCALE** The coordinator's peer credential is a `SEC-5` row, derived from
      the seed, with its public half installed into each member's peer set during setup and its
      private half never stored (`ARC-19a`, `SEC-5` row 17). Verified by inspecting the member
      peer sets after setup and confirming the coordinator holds no channel and no member's own
      key. Federation tenants only.
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
- [ ] **CNF-22 · BLOCKING** The rescue host key is pinned from the API response before the
      first connection, and the installed system's host keys are read from inside the rescue
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
- [ ] **CNF-67 · PRE-SCALE** On the distribution that admits artifacts by signature rather than
      hash, signature checking is **on**, the substituter key is the pinned one, and the install
      is driven from a pinned revision rather than a channel name (`ARC-25a`). The
      browser-supplied hash covering the installer image does not satisfy this item and is not
      reported as if it did.
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
- [ ] **CNF-55 · PRE-SCALE** A job record survives a reboot, and its absence of a live process
      is read as "died" rather than as ambiguous.
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
- [ ] **CNF-47** Transcript size produced by one install.
- [ ] **CNF-48** What Robot's rescue `host_key` field actually returns, and what the automatic
      Linux install operation returns (`OPN-6`, `STG-2`).

## The blocking tier

Every BLOCKING item sits in one of the irreversible families named above. **They are not all
exercisable by the first stage**, and an earlier version of this paragraph wrongly claimed only
`CNF-8` was not. At least four are out of reach: `CNF-8` needs a coordinator; `CNF-18` needs the
attest machinery `STG-19` says the first stage demonstrates none of; `CNF-57`, `CNF-58` and
`CNF-65` need the purchase-and-pass system `STG-18` says the stage does not have, since it runs
on a relay key the publisher recorded by hand. `CNF-6` and `CNF-26` need a second session, and the stage has one.

**The tiers therefore need to say which stage each item gates**, which this file does not yet
do. Until it
does, the header's "before it touches a real vendor account" cannot be met literally — several
items require touching one.

**No count is written here on purpose.** It went stale three times in a week, which is exactly
the drift the identifier scheme exists to prevent — a number restated in prose is a fact with
no owner. `grep -c '· BLOCKING'` is authoritative.

What matters is the rule, not the total: **an addition to this tier must name the irreversible
family behind it.** `CNF-52` is escaped-secret — a multi-tenant machine holding spendable key
material is one container escape from the operator's money. `CNF-40` is destroyed-data —
re-running a command that is still running is the corruption case `STA-20` exists to prevent.
`CNF-57`, `CNF-58` and `CNF-65` are boundary-crossed: an unpaid caller, an undeclared
destination, or an unpaced one turns the relay into the open proxy `CHN-8` forbids. `CNF-66` is
boundary-crossed too, and it is the one that looks like hygiene: a pin against a moving alias
passes today and admits rewritten bits on the next upstream release, which is the bundle-scale
substitution `TRU-E8` names arriving through the control that was supposed to detect it.
`CNF-68` and `CNF-70` are escaped-secret and money-out respectively — an unrevocable bearer
credential in a session's hands, and a prepaid ceiling silently converted into a wallet draw —
and `CNF-69` is what turns row 2's stated lifetime into an enforced one. `CNF-72` is
boundary-crossed and `CNF-73` is escaped-secret: a reused derivation index puts one client key on
two machines, and the seed in a session's hands is every machine at once. `CNF-76` is
boundary-crossed: an unsigned destination record lets a stranger widen a pass they do not hold. If an
item cannot name its family, it is PRE-SCALE and the tier still means something.
