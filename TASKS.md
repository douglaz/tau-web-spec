# Tasks

Work arising from the [engineering review of 2026-08-19](docs/review/2026-08-19-engineering-review.md),
which reviewed the corpus at `726ad44`. Each task names the finding it came from, so nobody
has to reopen the review to know why it exists.

Nothing here has been applied yet. Until a task is checked, the current text in `spec.md`
and the decision records is what ships.

**T6 is a barrier.** It moves every file the other documentation tasks edit. Do it first, or
do those edits twice.

## Blocking

- [ ] **T1 — Run the first stage by hand, before any code.**
      Activate rescue on a disposable dedicated server; read what the rescue endpoint's
      `host_key` field actually returns; read what the automatic Linux install operation
      returns in the same sitting; rehearse the ceremony end to end; write the three briefs
      from the real install as you go.
      *Why:* the item the plan calls most likely to fail is de-risked by five production
      implementations of the same architecture; the item that is genuinely unanswered costs
      one authenticated call and gates route 1.
      *Verify:* open question 6 closes, or route 1 is refuted and the first stage is
      reconsidered. Record the install path decision either way.

- [ ] **T2 — Write ADR-0022: the state model.**
      Where durable state lives, the append-only journal, the single-writer worker,
      commit-before-side-effect, crash recovery, per-tool replay safety. State it in current
      terms rather than citing the archive.
      *Why:* four current rules depend on machinery specified only in a document the
      specification declares superseded, which is why the recording invariant restates two
      of the archive's invariants in fresh prose.
      *Files:* `docs/adr/0022-*.md`, `spec.md`
      *Verify:* the recording invariant and the mid-brief-recovery question both cite it;
      neither restates it.

- [ ] **T3 — One SSH client keypair per machine.**
      Only that session's public key reaches that machine's `authorized_keys`. The
      coordinator holds all of them during setup, stated explicitly. Recovery sheet carries
      N; Robot registration becomes one typed operation per machine.
      *Why:* one shared key opens every machine, so the access invariant is enforced only by
      the harness's own routing code, and the eighth predicate cannot demonstrate a mechanism.
      *Files:* `spec.md`, `docs/adr/0015-*.md`, `docs/adr/0020-*.md`
      *Verify:* a session cannot authenticate to a machine it is not bound to. The failure
      comes from SSH.

- [ ] **T4 — The AI is a trusted party; rewrite the two invariants that pretend otherwise.**
      Move "the AI never touches key material" to the tenant group. Scope "no path to the
      cloud plane" to the harness's own. State the general posture: minimize what the model
      can reach, count what remains.
      *Why:* both are unenforceable once the model holds root, and both are tenant
      requirements wearing harness clothes.
      *Files:* `spec.md`, `docs/adr/0016-*.md`
      *Verify:* every remaining MUST NOT in the invariant list is enforceable by something
      other than intent.

- [ ] **T5 — Replace the credential prohibition with an inventory.**
      Every credential class, where it lives, its lifetime, what it authorizes, how it dies.
      Anything without a row is forbidden. Include the operator-supplied tenant secret:
      redacted by value from the transcript, out of model context on delivery, counted in
      the blast radius.
      *Why:* a ban with exceptions has needed correction three times, against eleven
      credential classes actually in play.
      *Files:* `spec.md`
      *Verify:* the credential predicate asserts against the table rather than against a
      prose list.

- [ ] **T6 — Restructure into topic files with stable requirement identifiers.**
      Numbered topic files; every constraint, invariant, question and predicate gets a
      permanent identifier with a topic prefix; cross-references go by identifier. The
      summary and glossary stop carrying counts and normative rules.
      *Why:* rules identified by list position mean two renumberings have already consumed
      reviewer rounds re-verifying cross-references, and the same fact lives in four files.
      *Files:* all
      *Verify:* no cross-reference in the corpus is a bare ordinal.

- [ ] **T7 — Build the conformance checklist, tiered, with six new blocking items.**
      Each item names the requirement it proves and is written so it can become a test.
      Tier by whether the operator can undo it, would know without the control, and whether
      an autonomous retrying caller can trigger it. Add: box-plane cannot reach the cloud
      plane; a typed operation on an unbound machine is refused; briefs and feeds cannot be
      substituted at runtime; tool output claiming authority does not get it; a session
      cannot authenticate to a machine it is not bound to; an interrupted brief converges on
      re-run.
      *Why:* three of thirteen invariants have a predicate that would catch a violation.
      *Verify:* every stage-one-exercisable invariant has an item.

- [ ] **T8 — Name the distributions and pin the artifact source.**
      State Alpine and NixOS and why they force custom installation on this vendor. Add the
      artifact source as an untrusted dependency pinned by content hash supplied from the
      browser, and give it a row in the elective trust tier.
      *Why:* a party that decides what every machine runs is currently unnamed and unpinned,
      with the same blast radius as the bundle.
      *Files:* `spec.md`, `docs/adr/0011-*.md`, `docs/adr/0018-*.md`

## Same branch

- [ ] **T9 — Split the CSP decision by directive.** `connect-src` permissive as decided;
      `script-src`, `object-src` and `base-uri` strict, with the bundle-injection reasoning
      stated. *Injected code never calls the approval path.*
      *Files:* `spec.md`, `docs/adr/0017-*.md`

- [ ] **T10 — Rewrite decision-record bodies that amendments reversed.** Append for
      additions; rewrite for reversals. Carry superseded reasoning forward only where the
      old approach is one a fresh reader would arrive at independently.
      *Files:* `docs/adr/0020-*.md`, `docs/adr/0004-*.md`, `docs/adr/0015-*.md`

- [ ] **T11 — Add seven diagrams, renderable on GitHub (```mermaid).** The five fingerprint
      routes as a decision tree; the attest sequence; session binding and the coordinator's
      reach; the recovery ladder; the recovery matrix; the two planes and their approval
      modes; the first-stage sequence.

- [ ] **T12 — Scope the exposure ledger; state that an unfinished setup is device-bound.**
      Staleness and conservative-binding rules bind only a maintained-plus-threshold tenant,
      which none currently is. Resume where the setup started, or abandon.
      *Files:* `spec.md`, `docs/adr/0020-*.md`

- [ ] **T13 — Price the relay as learning member topology.** Restate the Certificate
      Transparency comparison as one chosen party against everyone, permanently.
      *Files:* `docs/adr/0015-*.md`, `docs/adr/0019-*.md`, `spec.md`

- [ ] **T14 — Price the tunnel's root store; mark it designed-but-unbuilt.** A bundled
      certificate-authority set grows the trusted list against the invariant that guards it.
      *Files:* `spec.md`, `docs/adr/0017-*.md`, `docs/adr/0019-*.md`

- [ ] **T15 — State attest post ordering and bounded retry.** Backoff until acknowledged or
      a deadline; scrub on whichever comes first; deadline inside the voucher's expiry.
      *Files:* `docs/adr/0020-*.md`

- [ ] **T16 — State that remote box-plane execution is command-granular**, and that
      recording commits per command before transmission.
      *Files:* `spec.md`

- [ ] **T17 — Add the memory measurement as a conformance item.** Peak memory of one session
      during a full install, both mobile browsers, with the five-session projection stated
      against the platform's tab budget.
      *Files:* conformance checklist, `docs/adr/0009-*.md`

- [ ] **T18 — Correct the first-stage record.** Say why rescue is required. Narrow "the rest
      is subsetting" to what dedicated rescue actually covers. Raise the tenant predicate
      above "running and reachable."
      *Files:* `docs/adr/0018-*.md`, `spec.md`

## Follow-up

- [ ] **T19 — Specify a durable remote job record**, so a reconnecting session can learn
      whether a long-running command finished rather than inferring it. Declarative system
      state reduces this without removing it.

- [ ] **T20 — State what the first stage does not test:** account acquisition, webservice
      user setup, relay enrolment, inference funding. A developer can pass every predicate
      while a phone-only operator still cannot begin.
