# Design: tau-web — a client-side acting AI for people who only have a phone

Design session, 2026-08-07. Revised twice; three rounds of adversarial review, scoring
5 → 7 → 8.

**Status: superseded in part, 2026-08-10.** The decision records in
[`docs/adr/`](../adr/) and the glossary in [`CONTEXT.md`](../../CONTEXT.md) came out of
grilling this document, and where they disagree with it, they win. Two things here are
withdrawn outright: premise 5's browser-side deviation diff, since
[ADR-0001](../adr/0001-recipes-are-instructions-not-scripts.md) makes recipes prose and
there is nothing left to diff; and the cross-check this document proposed, since
[ADR-0004](../adr/0004-one-model-one-machine.md) establishes that any model inspecting
another's machine gains a second foothold. The rest stands. This is the only record of
why approach C was chosen over A and B, and of what the reviews found.

**Repos referenced.** Two local, two remote. Every `§` below is prefixed with which
spec it belongs to, because both local specs have a §2, §3, §8, §10, §12 and §14.

| Short name | Location | What it is |
|---|---|---|
| `AVH` | `ai-vps-harness`, a companion repo not published here (a bare `§` means its `docs/spec.md`, other files named explicitly) | Working PoC: browser provisions one Hetzner server, no relay |
| `TWS` | [`docs/archive/rust-first-ai-harness-pwa-spec.md`](../archive/rust-first-ai-harness-pwa-spec.md) | The 1610-line tau-web spec, no code yet |
| btc-policy | https://github.com/douglaz/btc-policy | Bitcoin custody: multisig + Miniscript, policy co-signer federation |
| lnrent | https://github.com/douglaz/lnrent | Server rental over Bitcoin, Nostr discovery, Lightning/Fedimint payment |

**Effort estimates** are given on two scales: unaided human time, and time with an
agentic coding assistant driving.

**v0 scope decision, stated once and propagated.** v0 provisions **two independent
machines and does not join them into a federation.** Federation join depends on
cross-instance coordination (Open Question 9) and moves to v1. Everything below that
says "member" means "a machine that will become a federation member," not one that has
joined.

## Problem Statement

There is a divide in AI usage. Technical users run agentic CLI harnesses against the
best models and get an AI that *acts*. Non-technical users,
who would benefit more, are stuck with chat-only AI that cannot act, because
installing and configuring a harness requires technical knowledge and usually a
desktop. Most of them have only a phone, and cannot bootstrap a remote server that
would host a real tool-using agent.

The obvious fix, a hosted agent platform, is unavailable for an entire class of
high-value tasks: anything whose value depends on *not* trusting a host. Self
custody, key management, sovereign infrastructure. For those tasks the gap can only
be closed client-side.

tau-web is the client-side acting AI. Its first two tenants:

- **btc-policy** — self-hosted Bitcoin custody: multisig plus Miniscript descriptors,
  a federation of policy co-signers that inspect exact PSBTs, delayed sovereign
  recovery. Setting up the federation means provisioning and hardening several
  machines at several vendors. A non-technical user can do neither that nor delegate
  it, because a single party that provisions every federation member has defeated the
  federation.
- **lnrent** — decentralized server rental over Bitcoin. Operators run `lnrentd`,
  publish over Nostr, buyers pay Lightning/Fedimint. Same shape: a non-technical
  operator cannot stand up the daemon, and the project keeps AI out of its serving
  path by design, so any AI help has to live on the user's side.

btc-policy's own spec is being revised because mobile-browser operation turned out to
be fundamental rather than a convenience.

## What Makes This Cool

That is the multisig argument applied one layer down, to provisioning itself. It is
the same idea the vault already rests on, which is why it is the right one, and it is
a thing you can show someone in thirty seconds.

**The v1 pitch, which is the real one:** two browser instances, two inference
providers, each provisions one member of a Bitcoin vault federation. You are holding a
phone, and a vault now exists that no single AI could have backdoored.

**What v0 actually demonstrates, and it is less than that:** one device running two
concurrent sessions on different model weights, two independently provisioned
machines, and a trust panel showing that no single model touched both. **No federation
exists in v0 and no vault exists in v0.** The claim v0 supports is "these two machines
have provably different provenance," not "your bitcoin is safe." Do not demo it as the
latter. The gap is Open Question 9b.

## Constraints

- **Mobile browser is the runtime.** No install, no extension, no native package, no
  desktop, no terminal. (`AVH` §12 criteria 1-3.)
- **No party the user must trust with the ability to act.** A transport that can only
  stall or drop is acceptable; one that can read or inject is not. **Unsatisfied
  today, which is exactly why v0 has no remote channel.** Expected to be satisfied
  once Open Question 1b passes; SSH host key verification is the intended mechanism
  but it is chosen, not proven.
- **The AI must be free to act.** Future VPS adversity is not enumerable in advance.
  Restricting authority to keep the AI safe breaks the only reason the AI is there.
- **Multi-vendor by necessity.** Federation members must not share a cloud vendor or
  an inference provider.
- **Credentials stay in browser memory.** `AVH` enforces this structurally:
  `SecretString` implements neither `Clone` nor `Serialize`, `build_prompt` takes
  types that cannot carry one, and the transport re-checks the joined origin before
  attaching a token. Note this is *structurally enforced*, not *verified end to end*:
  `AVH` §8.1 lists runtime CSP admission as unverified, §9 notes neither transport
  sets `cache: no-store` today, and `cors-findings.md` residual risk covers our own
  plumbing. `AVH`'s README status line reads "feasibility spike" with the network
  question settled; `docs/spec.md`'s own status reads "active."

## Premises

1. **The product is the access gap, not the vault.** btc-policy and lnrent are proof
   #1 and #2.
2. **The AI must be free to act.** Narrowing authority is rejected on purpose;
   unknown adversity is the AI's job.
   *Consequence not yet absorbed:* `AVH`'s README section "How the AI is contained"
   claims "the model's entire authority is to name one `option_id` from a list it was
   handed." A free-to-act AI running recipe bash voids that sentence. Premise 7 keeps
   the typed operation layer, but the repo's central claim must be **rewritten**, not
   inherited. See Next Step 5.
3. **The defense against a malicious AI is key isolation plus per-member AI
   diversity.** *Conditional on two things this document does not yet have.* If key
   isolation holds and diversity is real, then a compromised AI compromises only its
   own member and the threshold absorbs it. Both conditions are currently open:
   - **Key isolation is asserted, not specified.** Where a member's key material is
     generated, where it lives, and what prevents instance A from reading instance
     B's are undefined. See Open Question 8. The threshold-absorption conclusion above
     depends entirely on this.
   - Diversity must be at the **model-weights** level. The
     [zero-trust multi-LLM survey](https://arxiv.org/pdf/2508.19870) names the exact
     failure: a compromised model provider "can simultaneously compromise all agents
     using that backend, bypassing the multi-agent diversity assumption."
   - **As stated, weights-level diversity is not enforceable.** The available signal
     is OpenRouter's `X-Provider-Name`, exposed per `AVH` `cors-findings.md` (the
     *OpenRouter* section, line 105, restated in `AVH` §3.1) and *not* per C2, which
     is the Hetzner `expose-headers` consequence. `X-Provider-Name` names the
     *serving* provider, i.e. the endpoint-level signal this premise rejects as
     insufficient. Until Open Question 2 resolves, the product can enforce *endpoint*
     diversity and must **say so plainly in the UI** rather than claim weights-level
     diversity it cannot verify.
4. **The verifier is a Rust WASM program inside the vault app, and is out of scope
   for this plan.** Drift detection, honest-mistake catching, the periodic re-audit.
   It is *not* a security boundary: it reads what the machine chooses to tell it, and
   without a hardware root of trust the VPS will not give you, an adversary that owns
   the machine owns the report. Recorded here so it is not re-derived later. It
   appears in no success criterion and no next step.
5. **The shell exists to run recipes.** Recipes are skills: markdown plus bash blocks,
   the format models are best at and humans can review.
   - The containment value depends entirely on **where the deviation diff is
     computed**. If the box reports what it ran, this is premise 4's refuted verifier
     wearing different clothes. It is only a real boundary if **the runner diffs the
     byte stream it is about to transmit against the recipe, in the browser, before
     transmitting**. That is the design; anything else is theatre.
   - **This is a v1 mechanism.** v0 transmits no commands: it ships user-data at
     create time, and byte-identity there is already covered by success criterion 4
     via the approval screen.
6. **Recipes are a *candidate* shared primitive with lnrent**, which already
   provisions via deterministic scripts tied to service templates. Not a commitment:
   the schema does not exist yet (Open Question 3), and designing a second consumer
   for an undefined format is premature.
7. **`AVH`'s crates are the foundation of tau-web's tool layer.** `HetznerOperation`
   (`crates/hetzner/src/operation.rs:132`) and `PolicyConfig::prefilter`
   (`crates/policy/src/lib.rs:187`) stay and become how a tool call acts. Note
   `agentctl` is a `TWS` concept (§11.1C, §16.5, M3) with zero occurrences in `AVH`;
   it does not exist yet.
8. **The browser-side execution engine is an open question deferred to Next Step 7,
   not a premise.** An earlier draft asserted "use `browser_wasi_shim`." Three things
   killed that:
   - It contradicts this plan's own method, which is to derive shell scope from real
     recipes rather than guess it.
   - The chosen v0 local command set needs no WASI host at all, so the decision buys
     nothing now.
   - The citations supporting it were wrong. `TWS` §12.2 (line 668) permits a scoped
     shim **conditionally**, "if a browser or binding limitation makes a fully
     Rust-authored import object impractical," a condition discharged by the §12.2
     spike and the §25 M0 gate; and what it permits is a WASI *import-object* shim,
     not adopting a third-party JS WASI host wholesale. The no-JS constraint is in
     `TWS` §1 (line 24), not §2, and `TWS` §2.2 (line 59) additionally says "avoid npm
     and a JavaScript bundler in the core build" while §26 criterion 14 restates the
     ban. `browser_wasi_shim` is a TypeScript/npm package, so it collides with more of
     the spec than the earlier draft admitted. And `TWS` §27 has an *Impact* column,
     not a rating: that row is High, tied with five other High rows, and its own
     mitigation already reads "permit a tiny isolated JS import shim **as fallback**."
     Taking the fallback is not deleting the risk, it is exercising §27's contingency
     and trading it for the npm constraint.

   The [uutils playground](https://uutils.org/playground-how-it-works/) and
   [`browser_wasi_shim`](https://github.com/bjorn3/browser_wasi_shim) remain the best
   evidence that the capability is real and the best reference implementation. Revisit
   at Next Step 7, with recipes in hand.

## Approaches Considered

### Approach A: full vault flow
Grow `AVH` to a working btc-policy federation setup. Recipes, multi-vendor, remote
channel, approvals, diversity enforcement, the verifier.
Human ~2-3 months / assisted ~2-3 weeks. Risk: **high** — A is a strict superset of C,
adding the unresolved remote channel, the verifier, and full diversity enforcement,
so it cannot be less risky than C.
Con: does not test whether the platform thesis generalizes beyond vaults.

### Approach B: kernel first, `TWS` milestone order corrected
Build tau-web's harness kernel (events, replay, tools, policy, approvals) as the
substrate, fold `AVH`'s crates in as the first tool set, then vault, then shell.
`TWS` M2 before M1; M1 last.
Human ~4-6 months / assisted ~4-6 weeks. Risk: medium-high.
Pro: tenant #2 (lnrent) costs a fraction of tenant #1.
Con: months before anyone sees anything.

### Approach C: two-machine diversity demo — **CHOSEN**
Two browser instances, two inference providers, each provisions one machine. The app
records and displays provenance. Build only what that needs. Risk: **medium**, not low.

Effort, split to the stage the plan is organized around:
- **v0: human ~10-12 weeks / assisted ~2-3 weeks.** This assumes provenance exchange is
  manual export/paste, which Open Question 9a now decides, and that federation join is
  out of scope, which the v0 scope decision now states. Both conditions are discharged
  rather than pending.
- **v1: not estimable until Open Question 1b resolves.** One branch of Next Step 3
  (cloud-init only, cut remote blocks) makes v1 cost zero. The other requires a WASM
  SSH client spike plus a relay to build or operate.

Coverage against the full platform vision: A 8/10, B 10/10, C 4/10. Same metric.

Risk is medium because several success criteria rest on things neither repo contains:
a second vendor's typed operation layer, the provisioning state machine that `AVH` §11
says is not built, and a real-device matrix on both mobile browsers that `AVH` has
never run. The earlier "Risk: low / ~6 weeks" was not credible.

### Recipe execution sub-decision
- Remote-first, no browser shell: cheapest, but nothing runs before machine #1 exists.
- Full local shell per `TWS` §10 and §12 (brush-parser, async interpreter, five WASI
  modules: coreutils, grep, sed, findutils, diffutils per `TWS` §11.1B): uniform
  environment, but every scope decision there is currently a guess.
- **Hybrid, grow from real recipes — CHOSEN.**

## Recommended Approach

**Approach C, staged, as the first move inside the platform bet rather than instead
of it.** The staging is new since the review and is a faithful reading of "grow from
real recipes," not a reversal: you cannot have remote-capable recipes before the
remote channel exists.

### v0 — cloud-init only, no remote channel

Both machines are provisioned entirely through user-data at create time, and are not
joined into a federation (see the v0 scope decision above). Recipes are **local-only**
in v0. This is the bootstrap with the fewest moving parts: it needs no relay, no WASM
SSH client, and no answer to Open Question 1. It is not the only one — a box can also
fetch its payload from a public URL at boot — but that adds a hosting dependency and
an integrity problem for no gain at this stage.

Starting local command set: `template`, `jq`, `sha256`, `base64`.

````markdown
```bash local
template cloud-init.tmpl > /workspace/init.yaml
```
````

v0 delivers: two vendors, two inference providers, provenance capture, collision
detection, approval screen showing the exact user-data before it is submitted, and
resumable creates.

### v1 — remote blocks, once Open Question 1 has an answer

Recipe blocks gain a `remote` marker; those blocks ship to the box's real GNU bash
over whatever channel OQ1 settles on. The local set grows only when an actual recipe
reaches for something it does not have. By recipe #4 you will know whether the answer
is a WASI host plus uutils modules or forty lines of Rust, and you will know it from
evidence.

Recipes are the requirements document for the shell, and none are written yet.
Writing three real ones costs days and settles scope questions that `TWS` §10 and §12
currently answer by guess.

## Open Questions

**1. The browser↔VPS channel. Mechanism chosen, not settled; 1b can still fail.**

**The mechanism is SSH, with host key verification as the pin.** A WASM SSH client in
the browser connects to the box's sshd through a WebSocket-to-TCP relay, and verifies
the server's host key against a fingerprint obtained out-of-band. Because that check
happens inside the SSH protocol at the application layer, the transport underneath is
irrelevant to confidentiality and integrity. The relay carries ciphertext and cannot
forge a handshake it has no host key for.

This is worth stating precisely because two earlier framings were wrong:

- An earlier draft said "cert-pinned channel," which suggested pinning TLS. Browsers
  expose no API to inspect, pin, or override the certificate behind a `fetch`, and a
  fresh box has an IP with no WebPKI-valid cert. That framing was unbuildable. It is
  also unnecessary: **SSH does not use WebPKI and does not need TLS.**
- A reviewer objected that "nothing on the box is listening." **sshd is listening**,
  verified in the file: `cloud-init/machine-only.yaml` writes
  `/etc/ssh/sshd_config.d/60-harness.conf` and runs `systemctl restart ssh`.

**Client authentication is NOT already solved, and the current cloud-init probably
locks you out.** This is a code-read finding, not an observed failure, because the
file has never executed (`AVH` README: "nothing here can create a server yet"; §14
calls it a placeholder; its own header says "Do not treat this as a secure baseline").

`machine-only.yaml`'s `users:` list contains only `- name: harness` with **no
`- default` entry**, and sets `ssh_authorized_keys: []` explicitly. cloud-init's
`cc_ssh` applies datasource `public-keys` to the user flagged *default*; with no such
user, `extract_default` yields nothing and the keys reach no regular account. They
fall through to root carrying `disable_root_opts`' forced command, and the drop-in
sets `PermitRootLogin no` regardless. Net effect: sshd up, password auth off, root
refused, no `authorized_keys` anywhere. The comment "Populated by Hetzner from the
ssh_keys given at create time" is the only evidence for the old claim and it is a
comment in an unbooted file.

Fix is one line (`- default` in the `users:` list, or keys placed on `harness`
explicitly), but it must be confirmed by an actual boot. See Next Step 3.

Consequences that follow and should not be re-derived later: for **confidentiality and
integrity** the relay is an availability dependency, not a trust one, so relay
redundancy is cheap, a hostile relay is a denial-of-service and nothing worse, and the
relay itself is a candidate lnrent tenant.

**But "availability dependency only" is too clean, and the gap is operational.** A
WebSocket-to-arbitrary-TCP relay with no authentication is an open proxy and will be
abused within days of being reachable. `TWS` §21 already specifies exactly this
component ("WebSocket/WebTransport-to-TCP bridging", "SSH transport", lines 1280-1281,
scheduled at §25 M6 line 1497) and already imposes MUSTs that this document skipped:
the relay MUST "authenticate the PWA/user," MUST "enforce destination and operation
policy," and MUST "prevent generic open-proxy behavior." A relay that authenticates
callers and constrains destinations holds real authority over *who may connect where*,
even though it holds none over *what is said*. Both statements are true and the second
does not cancel the first.

Resolve it by adopting `TWS` §21's MUSTs rather than inventing a looser relay, and by
saying plainly in the UI that the relay learns connection metadata (which user, which
destination, when) while learning nothing of the session contents.

This also reverses `AVH` §4, which lists "API relay" under *Explicitly absent* and
deleted `services/relay`. That reversal is now justified rather than unflagged, and it
belongs recorded in `AVH` too, not only here.

**1a. How does the browser learn the host key fingerprint?** Partly answered. The goal
is to **never perform SSH trust-on-first-use at all**.

*Conflation risk to avoid:* the `fingerprint` field that appears throughout Hetzner's
Cloud API and every SDK belongs to the **`ssh_keys` resource**, which is the *user's
uploaded public key*, not the server's host key. Different object.

**Route 1: retrieve, dedicated servers, documented.** Hetzner's **Robot** webservice
(`robot.hetzner.com`, the *dedicated-server* API) exposes `host_key` (Array) on both
`GET` and `POST /boot/{server-number}/rescue`. Hetzner's SSH docs state that when
Rescue is activated "these fingerprints are also displayed on Robot," and defines a
fingerprint as a condensed form of the server's public host key, which is what SSH
asks you to verify on first connection. So the harness can activate Rescue over
HTTPS, read the authoritative host key, derive and pin the fingerprint locally, and
skip TOFU.
- Sources: [Hetzner SSH docs](https://docs.hetzner.com/robot/dedicated-server/security/ssh/),
  [Robot webservice reference](https://robot.hetzner.com/doc/webservice/en.html).
- **Status of the three follow-ups:**
  - **Robot CORS: TESTED, non-issue.** Confirmed browser-reachable. The concern that
    Basic auth plus undocumented CORS headers would block this is closed, and the
    no-TOFU host key chain is available for the dedicated-server path.
  - **Robot is still not Cloud.** `robot.hetzner.com` remains a different product with
    a different auth scheme (HTTP Basic, not Bearer). It is a **second integration**,
    not a free extension of the Cloud work, and v0 runs on Cloud.
  - **`host_key` contents are still undocumented** — full public keys, fingerprints, or
    which algorithms is unspecified. One authenticated call answers it.
- **Rescue is the install environment, and that is the point.** Rescue boots with its
  own sshd and its own host keys; the installed system has different ones. That is not
  a gap, because the installed system is put there **from inside the trusted rescue
  session**: the harness pins the API-published rescue key, connects, and installs a
  **custom image**. The installed system's host keys are then either generated inside
  that trusted session and read before reboot, or baked into an image you built and
  therefore already known. No trust-on-first-use at either hop.
- **What the custom image buys beyond key continuity.** The vendor's stock OS leaves
  the trust set. You build the image, you know its hash, the box boots exactly what
  you built. Most of "harden the box" moves from runtime commands into image build
  time, where it is reproducible and reviewable, which shrinks the recipe surface and
  strengthens the diversity claim: *two members running the same image hash* is a
  stronger statement than *two members that ran the same recipe*.
  - This does not weaken premise 3. The image is produced by the user's build
    toolchain, not by the AI, so a shared image is not a shared AI. It narrows the
    AI's job to provisioning plus installing a known artifact, which is a smaller and
    more checkable surface than free-form hardening.
- **New component this introduces: image distribution.** Streaming a multi-GB image
  through the browser and the relay is not viable on mobile. The realistic shape is
  that the rescue session pulls the image from a URL while the browser supplies the
  URL **and the expected hash**. That makes the image host an *untrusted* dependency,
  pinned by hash, exactly like the relay is an untrusted dependency pinned by host
  key. Same pattern, and worth reusing deliberately.
- **Mechanics differ by product.** On dedicated servers this is Robot rescue plus
  `installimage`. On Cloud it is enable-rescue plus writing the image to the block
  device over the network. Both are established techniques; neither is implemented
  here.

**Route 2: retrieve, Cloud VPS. Unverified.** Whether `api.hetzner.cloud`'s rescue
actions return host keys the way Robot's do is unknown and worth the same probe. v0
runs on Cloud, so this is the one that matters first.

**Route 3: inject. Always available, and the reason 1a is not a blocker.** The browser
generates the host keypair and writes it into `/etc/ssh/` via cloud-init `write_files`.
No retrieval endpoint needed on any product, and the browser knows the fingerprint
because it made the key. Two costs: the private host key rides in `user_data`, which
the vendor stores (see 1c), and **this route violates Constraint 5** by deliberately
moving a private key out of browser memory into third-party storage. If this route is
taken, either amend Constraint 5 to scope it to *provider and vendor API credentials*,
or scrub and rotate the host key after first boot. Do not leave the contradiction
standing.

**Route 4: TOFU plus continuity. The pragmatic floor, omitted from earlier drafts.**
Accept the host key on first connect, pin it locally, and alarm on any later change.
This is what real SSH clients do. It is strictly weaker than routes 1-3 against a
vendor hostile from t=0, but it needs no API endpoint, puts no key in `user_data`, and
still detects a vendor or network that *turns* hostile later. Worth having as the
always-works baseline so that a failed probe in 1a never blocks the channel.

**1b. Which WASM SSH client?** A real spike, not a library choice. `russh` is the
realistic Rust candidate but is async and tokio-shaped; compiling it for
`wasm32-unknown-unknown` and swapping its transport for a WebSocket is unproven work
of the same character as `TWS` §25's M0 gates. Budget it as a gate, and treat a
failure here as the thing that pushes remote blocks past v1.

**1c. What the pin does and does not defend against.** State this on the record so it
is not overclaimed later.

- **Defends against:** the relay, and anyone on the network path. Neither can read or
  inject, because neither holds the host key.
- **Does not defend against: the cloud vendor.** Under every route in 1a. *Retrieve*
  means the vendor serves the host key and could serve a different one. *Inject* means
  the vendor stores the `user_data` carrying the private host key and could read it.
  The Robot route is no exception: Hetzner publishes the value you pin, so pinning it
  trusts Hetzner. What all three routes buy is the elimination of **trust-on-first-use
  against the network**, which is a real and worthwhile gain. What none of them buys
  is independence from the vendor.
- **Why that is acceptable:** the vendor already owns the VM's memory and disk, and
  `AVH` §10 already places it in the trust set. Nothing short of a hardware root of
  trust with remote attestation would change this, and premise 4 already records that
  the VPS will not provide one. The pin buys transport safety, not vendor
  independence. Vendor independence is what *multi-vendor federation members* buy,
  which is why **Constraints bullet 4** requires members not to share a cloud vendor.

**1d. The alternative to a relay, rejected on the record.** The box could obtain a
WebPKI-valid certificate during cloud-init via ACME and serve its own
WebSocket-to-`localhost:22` bridge, removing the third party entirely. That requires a
DNS name the user controls, which a phone-only non-technical user does not have. It is
rejected for the target user, not because it does not work, and it becomes attractive
the moment a user does own a domain. Note also that the relay is genuinely forced for
the SSH path regardless of certificates, because a browser cannot open a TCP socket to
port 22 at all (`TWS` §3 non-goals, line 72); ACME changes who runs the bridge, not
whether one is needed.

**2. Can the app distinguish model weights from an API endpoint?** Premise 3 depends
on it, and the evidence currently points at "no." Provisional answer if it stays no:
enforce endpoint diversity, label it honestly in the UI, and stop claiming more.

**3. Recipe format schema.** Frontmatter fields, the local/remote block marker, how a
block returns structured data to the next block, versioning, signing. The example
above uses one candidate marker; it is illustrative, not settled.

**4. How much does the model deviate from a recipe in practice, and is the browser-side
deviation diff legible to a non-technical user?** Premise 5's containment story
depends on the answer and it is empirical.

**5. Second cloud vendor: which one?** Must be CORS-verified the same way Hetzner was.
`tests/browser-network/probe-cors.sh` is the template but not a drop-in: it hardcodes
the Hetzner and OpenRouter base URLs, the `/servers` and `/ssh_keys` paths, and
Hetzner-specific assertions. Only `ORIGIN` is parameterized. Budget a fork, roughly
80 lines of curl. Candidates: Vultr, DigitalOcean, Linode, and lnrent itself, which is
interesting because it needs no cloud account at all.

**6. Mid-recipe recovery.** `AVH` §7.1 *designs* duplicate-create protection (an
IndexedDB intent record, the deployment ID carried in the server `name`, `ListServers`
plus reconcile-by-name) but §11 states the provisioning state machine is not built. A
multi-step recipe needs the same idea at step granularity, on top of a state machine
that has to be written first.

**7. Hosting integrity.** The static host can alter the delivered WASM and there is no
reproducible-build attestation (`AVH` §14, §10). For a vault this is the largest
unmitigated item in the trust model. An earlier draft floated a browser extension as a
better pinning story; that is dead on arrival, because Android Chrome has no extension
support and it contradicts `AVH` §12 criterion 3. The live options are reproducible
builds plus a published hash, and a way for a second party to attest the served bundle.

**8. What does "key isolation" actually mean here?** Where member key material is
generated, where it lives, what prevents instance A from reading instance B's, and
what "two browser instances" means concretely (two devices, two profiles, two origins,
one phone). If both instances are the same origin on one device, premise 3's isolation
claim is false while success criterion 1 still passes.

**9. Cross-session exchange. Two separable problems; one has since dissolved.**

**9a. Exchanging a provenance record between sessions. CLOSED, not by solving it but by
removing it.** This was a problem only while sessions were assumed to live on separate
devices sharing no backend. Per
[ADR-0009](../adr/0009-one-device-concurrent-sessions-batched-approval.md)
a federation is provisioned by concurrent sessions on **one device**, which share
storage. There is nothing to exchange and no manual export/paste step. The earlier v0
effort estimate was conditioned on this being scoped to paste; the condition is now
satisfied more cheaply than assumed.

**9b. Agreeing on one federation. v1, open.** Exchanging member descriptors and public
keys and running a join between instances that share no backend is a multi-party
protocol, not a paste. Candidates: QR between devices, the federation's own state
carried on member #1, btc-policy's own setup ceremony. This is why v0 provisions two
independent machines and joins nothing (see the v0 scope decision), and it is the gap
between the v0 demo and the v1 pitch.

**10. CSP for a multi-endpoint app. Largely closed by the channel decision.** `AVH`
§8.1 ships a static `connect-src` meta tag naming `api.hetzner.cloud` and
`openrouter.ai`. v0 adds a second cloud vendor and a second inference vendor, both
static entries. An earlier draft worried that v1's per-machine endpoints could not be
enumerated at build time; **under SSH-over-relay they never appear in `connect-src` at
all**, because the browser connects to the relay's fixed origin and the machine
address is a parameter *inside* the WebSocket. v1 therefore needs one more static
entry, not a dynamic policy.

Two concrete follow-ups remain: WebSocket connections are governed by `connect-src`
and `AVH` §8.1 currently has no `wss:` entry, and `AVH` §8.1 itself notes that runtime
admission of the policy is unverified. If the Robot path is adopted (OQ1a route 1),
`robot.hetzner.com` is a third static entry.

## Success Criteria

Written as pass/fail predicates, v0 unless marked. Two carry a stated precondition
rather than being unconditionally testable; that is called out inline rather than
hidden behind the word "predicate."

1. Two browser instances, each configured with a different inference provider, each
   create exactly one server at a different cloud vendor. **Precondition:** the
   definition of "instance" must be fixed per Open Question 8, or this passes
   vacuously with two tabs on one origin.
2. For each machine, the app persists a provenance record naming the cloud vendor, the
   inference provider (from `X-Provider-Name`), and the model identifier (from the
   OpenRouter response body's `model` field, not from a header). The record survives a
   page reload and a browser restart. **Forgery resistance is explicitly out of scope
   for v0**; a v0 record is a local claim, not evidence.
3. Given a provenance record naming the same inference provider **or the same cloud
   vendor** as an existing machine, the app blocks the create and displays the reason.
   Blocking, not warning. **Precondition:** v0's two instances share no backend, so
   the record must reach instance B by the mechanism Open Question 9 settles. Scoped
   to **manual export and paste** for v0; if that is rejected, this criterion moves to
   v1 and v0's effort estimate no longer holds.
4. A local-only recipe with at least two blocks runs end to end, and the exact
   user-data submitted to the vendor API is byte-identical to what the approval screen
   displayed. (v1: the same predicate for command bytes sent over the OQ1 SSH channel,
   which is where premise 5's deviation diff lives.)
5. None of the four v0 credentials (cloud vendor #1 token, cloud vendor #2 token,
   inference key A, inference key B) appears in a request to the app origin, in any
   model request body, in IndexedDB, in local storage, in service-worker caches, or in
   any log. Extends `AVH` §12 criteria 8-10 and 18, which cover two credentials.
   **v1 adds a fifth credential class, the SSH client private key**, and under OQ1a
   route 3 a sixth, the SSH host private key, which by design leaves browser memory
   inside `user_data`. Both need this criterion restated with their own handling
   rules, not a silent extension of the list.
6. A create interrupted between intent and confirmation, then resumed, results in
   exactly one server. Tested by killing the tab mid-request.
7. Criteria 1-6 pass on Android Chrome and on iOS Safari, through a normal HTTPS URL,
   with no install. Matches `AVH` §12 criteria 1-3.

## Distribution Plan

Static HTTPS host serving HTML/JS/WASM/CSS/manifest/service-worker with
`Content-Type: application/wasm`, per `AVH` §8. No app store, no package manager, no
install step; that is the product.

Build via `nix develop` plus `trunk`, gated by `check.sh`. CI should run `check.sh`
and a forked `probe-cors.sh` on every push, because the CORS finding is an external
dependency that can regress silently: Hetzner could tighten its headers any day and
the probe is the only thing that would tell you.

Two open items belong here: the CSP question (Open Question 10) and reproducible-build
attestation (Open Question 7).

## Next Steps

1. **Write three recipes as plain markdown**, before any code. Hetzner create, harden
   a box, install one btc-policy member. This is the assignment below.
2. **Extract the block marker and the command set** those three recipes actually used.
   That is your v0 shell scope, derived rather than guessed. Note which steps could
   *not* be expressed as cloud-init user-data; that set is the real requirement for
   Open Question 1.
3. **Boot `machine-only.yaml` once, before anything depends on it.** The `users:` list
   has no `- default` entry and sets `ssh_authorized_keys: []`, so Hetzner's injected
   keys probably reach no account and the box comes up unreachable. One boot against a
   disposable project confirms or refutes it; the fix is one line. Do this first
   because every remote-channel plan assumes you can log in.
4. **Close Open Question 1's sub-questions.** Probe the Robot rescue `host_key`
   endpoint and its CORS behaviour, check whether Cloud has an equivalent (1a), and
   spike a WASM SSH client over a WebSocket (1b). Route 4 (TOFU plus continuity) is
   the fallback that keeps the channel alive if 1a fails entirely. Reinstating a relay
   reverses `AVH` §4 and should be recorded there, along with `TWS` §21's MUSTs for
   authentication and destination policy.
5. **CORS-probe two new targets** with forks of `probe-cors.sh`: cloud vendor #2, and
   `robot.hetzner.com` for the dedicated-server path (OQ1a route 1). The Robot probe
   is the higher-value one and the more likely to fail, because Robot documents no
   CORS headers and uses HTTP Basic. Twenty minutes of curl either unlocks the
   no-TOFU host key chain or removes it from the plan.
6. **Rewrite `AVH`'s "How the AI is contained" section** to describe what containment
   means once the AI can author recipes. The current text will be false and it is the
   repo's most load-bearing paragraph.
7. **Build the v0 recipe runner** in `AVH`: parse blocks, execute local ones against
   the native command set, render the resulting user-data, hand it to the approval
   screen, then to `HetznerOperation`. Includes the provisioning state machine `AVH`
   §11 says is missing.
8. **Add provenance tracking and collision blocking** (criteria 2 and 3).
9. **Only then** revisit browser-side execution scope, and revisit a Rust WASI host as
   a publishable crate rather than as a dependency.

## The Assignment

Write the three recipes by hand and run them yourself against a disposable Hetzner
project. No code, no AI in the loop. Just you, a markdown file, and a real server that
has to come up hardened with a btc-policy member on it.

Three things you cannot learn any other way. Which commands genuinely need to run in
the browser versus on the box. Whether the local/remote split is a seam a recipe author
trips over. And, most valuable given Open Question 1: **which steps could not be
expressed as cloud-init user-data at all.** If the answer turns out to be "none," v1
and its whole channel problem disappear, and this plan gets dramatically smaller.

Every scope decision in `TWS` §10 and §12 is currently a guess that those three files
would settle in an afternoon.

## Reviewer Concerns

Three rounds of adversarial review, scoring 5 → 7 → 8. What remains unresolved:

1. **The `machine-only.yaml` lockout is a code-read, not an observed failure.** The
   reasoning is in Open Question 1 and the fix is one line, but nobody has booted the
   file. Next Step 3 exists to settle it. Treat the finding as high-confidence and
   unconfirmed, and do not build on either answer until it is.
2. **Two premises rest on questions this document leaves open.** Premise 3's
   threshold-absorption conclusion depends on key isolation (OQ8), which is
   undefined; and its weights-level diversity requirement is currently unenforceable
   (OQ2), with the honest fallback being endpoint diversity plus truthful UI
   labelling. Both are stated conditionally in the text rather than resolved. A reader
   who needs premise 3 to be true should treat it as a design goal, not a property.

Not re-reviewed: the Hetzner Robot `host_key` material, the custom-image install flow,
and the relay abuse-control section were added after the third round. They carry the
same status as any unreviewed text.
