# Tasks

Work arising from the [engineering review of 2026-08-19](docs/review/2026-08-19-engineering-review.md),
which reviewed the corpus at `726ad44`, and from the reviews and decision records since
(T21–T23 from the September 9 review, T27–T29 from the September 15 construction decisions).
Each task names the finding or decision it came from, so nobody has to reopen the record to
know why it exists.

**The August review corrections have been applied**, plus further decisions from the grilling sessions that
followed. T1 ran on 2026-09-08 on a disposable auction server; construction is no longer
gated on it.

## Open

- [ ] **T21 — First-stage tenant delivery inputs** (`OPN-14`; tracked in lnrent as
      [douglaz/lnrent#87](https://github.com/douglaz/lnrent/issues/87)). Obtain the lnrent-owned
      declaration, finish the Robot lockdown checklist and briefs 2–3, then exercise
      `CNF-49`–`CNF-53`. This blocks stage completion, not harness construction.
- [ ] **T22 — Implement the clarified credential and recovery contracts** (`OPN-3`).
      Local unlock and v1 derivation gate the first stage (`CNF-82`–`CNF-83`); recovery
      export/import and partial Replace gate recovery enablement (`CNF-84`).
- [ ] **T23 — Demonstrate interrupted rescue installation** (`OPN-18`). Implement the
      `STA-20b` handoff and run `CNF-40`, `CNF-55`, `CNF-85` and `CNF-86` on the integrated
      harness. Non-destructive example checks are not a completed hardware rehearsal.
- [ ] **T27 — Build the first-stage relay** (publisher; `docs/design/relay-protocol-v1.md`,
      `CNF-87`). Challenge, AUTH, OK, then binary frames; destination checked against the
      hand-recorded set; `CHN-16a` and `bundle/timing.toml` limits before any dial. Ahead of
      harness integration: nothing over the channel can be tested without it.
- [ ] **T28 — Restate the three tenant declarations in v1** (`docs/design/delivery-declaration-v1.md`).
      ad-hoc is complete in the schema document; lnrent's template goes to lnrent#87 as the
      answer format; btc-policy's waits on its drift checks and required software. Each profile
      then points at its v1 file.
- [ ] **T29 — Create the implementation repository** (ADR-0031). *Created 2026-09-16 as
      `douglaz/tau-web-rust`, with this repository (renamed `tau-web-spec`) as the `spec/`
      submodule pinned at `b3dec66`; the build gates below are still to be written there.*
      It pins this repository by commit, refuses to build if the tree differs, compiles `bundle/`,
      `docs/tenants/` and the briefs promoted out of draft in — today none: brief 1 is a draft
      (`docs/briefs/`), and which briefs are promoted is decided when it leaves draft — and
      runs `bundle/cors-probe.sh` (`CNF-4`) and
      `prototypes/spec-checks/` (evidence for `CNF-85`, not for `CNF-1`–`CNF-4`; the
      implementation's README carries the same mislabel and is corrected with the next pin
      bump) from the pinned tree as its CI gate.
      `bundle/inference.toml` has an empty model slug on purpose; the build fails until the
      publisher fills it.
- [ ] **T30 — Port the specification gates and the formal companion's scaffold** (ADR-0032).
      From `~/projects/provisiond-spec`: `tools/check-all.sh`, the identifier, fixture,
      obligation, coverage and citation gates with this corpus's namespace table; `tools/formal/`
      with `Req.lean`, `Gate.lean`, `check_formal.sh`, `lakefile.toml` and `lean-toolchain` under a
      `TauWeb` namespace; `flake.nix` pinned to the same Lean; `AGENTS.md`; `ci.yml` with one
      negative control per gate. First run of the identifier gate writes this repository's
      withdrawn-identifier table. The ported gates are adapted, not only renamed: provisiond's
      fixture and coverage parsers expect its heading and item shapes, and this corpus's tiered
      `CNF` items and `docs/design/` JSON must be shown to be what they actually read. No clause
      is formalized by this task. *Tracked as epic `tw-formal-companion-nxy` in beads. Its
      first ticket landed 2026-09-17: `check-all.sh`, the identifier gate with its negative
      controls in `tools/check-controls.sh`, `ci.yml`, `AGENTS.md`, and `README.md`'s
      requirement conventions with the withdrawn-identifier table; the first run found
      `STG-8` and the `ARC-20` duplicate. The Lean package landed 2026-09-18: `flake.nix`,
      `tools/formal/` with `Req.lean`, `Gate.lean` and `check_formal.sh`, the citations
      gate's `TauWeb.*` resolver, and `STA-22a`'s role table as the first clause.*
- [x] **T31 — Formal companion, module 1: allocation** (ADR-0032's inventory). Identities as
      distinct structures — seed epoch, derivation version, role family, index; reserve durably
      before any effect; a failed or destroyed allocation keeps its index as a tombstone; no
      wraparound; a restored seed uses listed identities and allocates none until Replace — that
      guard a parameter with the refused-and-admitted pair. Witnesses: `STA-22`'s one-index-two-
      machines trap, the stale-sheet allocation, a successful allocate-create-destroy-allocate
      trace. Lands with `lake exe witnesses`, its witness file
      `docs/design/allocation-witnesses-v1.json`, and the emission gate that holds the file to
      the emission (ADR-0032, "How the implementation is compared"). Blocked by T30. Modules
      2–5 follow in the ADR's order; module 4's rule is `STA-24`. *The module landed
      2026-09-18 in `tools/formal/TauWeb/Allocation.lean`: the identity structure, the
      allocator as a trace, the theorems over every trace, the guard as a parameter with its
      refused-and-admitted pair, the decided witnesses, and the control that flips the guard.
      `lake exe witnesses`, `docs/design/allocation-witnesses-v1.json` with its schema in
      `docs/design/witness-file-v1.md`, and the emission gate `tools/check_witnesses.py`
      landed the same day, with the bound as `TauWeb.Allocation.bound` and its decided
      enumeration.*
- [x] **T33 — Port the rendering gate** (ADR-0032, "No marked regions yet": "the gate is ported
      when the first one exists"). `TauWeb.Declaration.row` is ADR-0032's first candidate for a
      marked region and `TauWeb.Allocation.row`, formalized first in module 1, is the second: the
      field table in `docs/design/delivery-declaration-v1.md` and the role table in
      `docs/design/credential-format-v1.md` are their regions once the gate holds each equal to
      its declaration. *Landed 2026-09-20: `tools/formal/TauWeb/Render.lean` computes both
      tables' rows from the declarations' own constructors, `lake exe render` emits them before
      the index is written, and `tools/check_regions.py` holds each document to its emission on
      the tokens the declaration determines, so a row's prose and its conformance citations stay
      the document's. The delivery table gained a shape column; the role table gained tokens and
      backticked keys. Twelve controls, one per refusal and one proving an edit outside a region
      stays green. ADR-0032's deviation closes with one adaptation: a region may sit in the
      normative companion its requirement links.*
- [x] **T32 — Formal companion, module 2: declaration presence and meaning** (ADR-0032's
      inventory; `ARC-39`, `docs/design/delivery-declaration-v1.md`). Landed 2026-09-19 in
      `tools/formal/TauWeb/Declaration.lean`: presence as one type for every field, the field
      table as `TauWeb.Declaration.row` with what an empty list means as a column, the delivery
      check as a trace, and over every trace, declaration and machine: no path reaches delivered
      while any field is missing or unspecified; an empty inbound list with any answering socket
      is a finding and an empty outbound list is not; a multi-tenant machine cannot declare
      spendable key material. The 2026-09-16 rule is a parameter with the refused-and-admitted
      pair; `docs/design/declaration-witnesses-v1.json` is its file; the controls add a field
      without its row and flip the rule.
- [x] **T34 — Formal companion, module 3: relay admission** (ADR-0032's inventory; `CHN-15`,
      `CHN-16`, `CHN-16a`, `docs/design/relay-protocol-v1.md`). Landed 2026-09-20 in
      `tools/formal/TauWeb/Relay.lean`: the handshake as a machine whose `authAccepted` and
      `okSent` are two phases with the dial between them, so the two orderings the 2026-09-16 fix
      separated are two theorems over every trace — nothing dialed before the AUTH is accepted,
      nothing forwarded before OK; step 3's check order as `TauWeb.Relay.admit`, total over the
      protocol's refusal reasons; the destination as parse, normalize, classify, dial, with the
      dialer's argument the classified numeric address by type. `CHN-16a`'s special-purpose
      tables and the relay's resolver are an assumption the module quantifies over. The shorthand
      "no dial before OK" is the parameter with the refused-and-admitted pair, and under it the
      relay dials and sends OK having accepted no AUTH. `docs/design/relay-witnesses-v1.json` is
      its file; the controls collapse the two orderings into the shorthand and pass a hostname to
      the dialer. The inventory's second trap for this module — a hostname re-entering the dialer
      after validation — is retained as that type and that control rather than as a trace, since
      no trace in which the dialer receives a name can be written at all; what the file carries of
      it is the positive side, the dialer handed the resolver's answer and never the name.
- [x] **T35 — Formal companion, module 4: dispatch and the unresolved barrier** (ADR-0032's
      inventory; `STA-3`, `STA-4`, `STA-7`, `STA-8`, `STA-24`, `SEC-12`, `STA-20b` and `STG-4`'s
      confirmation predicates, on the decisions of
      `docs/review/2026-09-16-barrier-panel.md`). Landed 2026-09-20 in
      `tools/formal/TauWeb/Dispatch.lean`: harness knowledge and external state as two types, with
      no dispatch function and no theorem statement reading the second; the journal a list of
      records and the barrier derived from it — an intent with no terminal record — rather than an
      event of its own; a disposition a terminal record whose outcome stays unknown; the durable
      journal and the running worker's in-memory state both carried, so `STA-3` is the statement
      that they never diverge. The principal theorem is
      `TauWeb.Dispatch.dispatched_only_if`, and its companions are
      `TauWeb.Dispatch.replay_same_unresolved`, `TauWeb.Dispatch.cloud_confirmed_by_read_only`,
      `TauWeb.Dispatch.failed_append_keeps_barrier` and `TauWeb.Dispatch.inference_unbarred`.
      Each parameter has its refused-and-admitted pair: the resource key, which the panel settled
      at the approved entry rather than the allocation index or the call id; `STA-3`'s
      append-before-apply, which is also `STA-20b`'s reset-offer precondition; the observation
      lattice, which keeps a changed boot ID below success; and the disposition's binding to the
      one continuation it names. `docs/design/dispatch-witnesses-v1.json` is its file; the
      controls switch the key to the call id and add an operation with no plane.
- [x] **T26 — Measure `STA-23` unlock latency on the first-stage phone.**
      `prototypes/unlock-latency/index.html` builds the v1 envelope and times one unlock.
      Done 2026-09-11: 58 ms at 600,000 iterations on the phone, 57 ms on the desktop
      baseline; v1 keeps 600,000. `docs/findings/2026-09-11-unlock-latency.md`.

- [x] **T24 — Relocate tenant content into profiles** (`ADR-0030`). Create
      `docs/tenants/{btc-policy,lnrent,ad-hoc}/profile.md` on the nine-slot schema; move
      `SEC-T1`–`SEC-T4`, `ARC-20`'s atomicity, `ARC-23`, `ARC-36`–`ARC-38` and the
      delivery brief verbatim, keeping identifiers, leaving one-line pointers behind.
      Meaning-preserving by construction; review by diff.
      Done 2026-09-10: `SEC-T1`–`SEC-T4` and `ARC-23` moved to btc-policy; `ARC-20` copied
      to btc-policy and kept in place (until 2026-09-17, when the identifier gate refused the
      duplicate and the root copy became a pointer); no delivery brief exists yet. `ARC-36`–`ARC-38` were
      listed here in error and **stay** in `01-architecture.md`: they hold for every profile,
      so they are the harness's (ADR-0030's own guard says so). lnrent's profile references
      them and carries only its values.
- [x] **T25 — Generalize the harness rules that still name a tenant mechanism.** After T24:
      `ARC-19a` (post-harness machinery never holds a channel), `ARC-37`'s Lightning sentence,
      `SEC-T3`'s harness default, `SEC-5` row 17, the coordinator paragraphs in `SEC-1` and
      `ARC-12`, the federation applicability row in `07-conformance.md`, and derivation role 4
      relabelled "post-harness credential" with path and vectors unchanged. Every edit changes
      a MUST; review with two independent readers, as `ADR-0030` was.
      Done 2026-09-10: `ARC-19`/`ARC-19a` are now a rule about **post-harness machinery** keyed
      on the profile's handoff slot; the coordinator, member endpoints, recovery descriptors,
      federation formation, the vault protocol port, peer-equivalence and the hostile-peer
      argument (`ARC-23`, ADR-0010, ADR-0012) moved verbatim into btc-policy's "Post-harness
      handoff" slot. `ARC-12`'s diagram node and dotted edges, the `SEC-1` coordinator
      paragraph (its history note keeps the word), `SEC-5` row 17, `CNF-8`, `CNF-77` and the
      applicability row followed. `ARC-37`'s two bullets are now watch-only vs. delegated with
      no payment mechanism named; lnrent's profile already carries the Lightning and
      extended-public-key sentences. `OVR-5`/`OVR-6` say "the machines of one setup" and point
      at the profile's independence bound (ADR-0030) instead of `SEC-T3`. Role family 4 is
      **Handoff / post-harness credential** in `STA-22`, `STA-22b` and
      `docs/design/credential-format-v1.md`; path, role number, encoding and every vector are
      byte-identical and `check-credential-vectors.py` passes untouched. `CONTEXT.md` gains
      **Post-harness machinery**; Coordinator and Member are marked btc-policy vocabulary.
      Conformance checks compare installed API authority and target machines with the handoff
      declaration; row 17's lifetime is profile-declared, with btc-policy's lifetime preserved.
      The three leaks the panel found outside its file lock were fixed by hand before merge:
      `TRU-A3`'s summary of `ARC-19a` in `05-trust.md`, the coordinator node in
      `00-overview.md`'s system-context diagram, and the coordinator paragraph in
      `executive-summary.md`. `06-first-stage.md`'s second-stage list keeps "the coordinator"
      as a description of what the vault stage brings. The general files still use *member*
      as vocabulary in the sessions and scanner sections; retiring the word is its own pass.
      Two independent readers reviewed the branch (both MERGE, no P0/P1). Their convergent
      P2, that `ARC-19a` had lost the peer-equivalence bound on the declared credential, and
      Codex's P2, that the provenance sentence overclaimed what the harness never holds, were
      fixed before merge; `ARC-15` now says "the whole setup". Recorded P3 follow-ups:
      `00-overview.md`'s diagram edge "vault protocol port only"; `executive-summary.md`'s
      "Members reach each other only on the vault protocol port" stated without attribution;
      the second Member definition near the end of `CONTEXT.md`; "handoff ID" in `STA-22b` is
      undefined and btc-policy's profile does not say it is the federation ID; the "Member
      networking" heading over `ARC-23`'s pointer; ADR-0021 still cites `ARC-19a` for sealed,
      peer-equivalent coordinator behaviour. All six fixed 2026-09-11, and *member* retired
      from the general files wherever the harness's own machines were meant; it remains where
      btc-policy's federation is (its claim, `ARC-20`, `SEC-T4`, TRU-A3's retirement note).

The September 9 review's specification corrections are applied: canonical disk selection,
rescue job lifetime, local unlock, derivation/allocation metadata, relay destination limits,
Alpine signer trust, rescue sequence and stage applicability. The open tasks above are
implementation/tenant evidence, not claims that the harness already exists.

## Applied

- [x] **T1 — Run the first stage by hand, before any code.** *(`STG-2`)* **Run 2026-09-08**;
      `docs/findings/2026-09-08-first-stage-rehearsal.md`. `CNF-48` recorded, `OPN-6` closed,
      `CHN-R1` rewritten to the route as it actually works. Brief 1 written
      (`docs/briefs/01-install.md`); briefs 2 and 3 wait on `OPN-14` and a delivery
      declaration, so that part of `STG-2` is open by dependency, not by neglect.
      Activate rescue on a disposable dedicated server; read what the rescue endpoint's
      `host_key` field actually returns; read what the automatic Linux install operation
      returns in the same sitting; rehearse the ceremony end to end; write the three briefs
      from the real install as you go.
      *Why:* the item the plan called most likely to fail is de-risked by several production
      implementations of the same architecture; the item that is genuinely unanswered costs
      one authenticated call and the whole identity chain rests on it.
      *Verify:* `CNF-48` recorded. `OPN-6` closes, or `CHN-R1` is refuted and the first stage
      is reconsidered.
      *Where:* `prototypes/first-stage-rehearsal/rehearse.sh` — preflight, rescue, install,
      reboot, with redacted captures and a wall-clock timeline (`STG-16`). Needs a rented
      disposable server and a Robot webservice user, both the operator's to create.

- [x] **T2 — ADR-0022, the state model.** Written: single writer, append-only journal in
      origin-private storage, append-before-apply, intent-before-effect, per-tool retry safety,
      crash recovery. Requirements at `STA-1`–`STA-9`. The archive returns to prior art.
- [x] **T3 — One SSH client keypair per machine.** `SEC-1` now states cryptographic
      enforcement; `SEC-5` row 3 carries the lifecycle; the coordinator's grant is named as
      distinct rather than borrowed. Tested by `CNF-5`, `CNF-6`, `STG-13`.
- [x] **T4 — The AI is a trusted party.** `04-security-model.md` opens with the posture. The
      key-material rule moved to the tenant group as `SEC-T4`; `SEC-3` scopes to the harness's
      own cloud plane; `SEC-6` states minimize-and-count for everything else.
- [x] **T5 — Credential inventory.** `SEC-5` is an enumerated table replacing the
      prohibition-with-exceptions (thirteen rows then; twenty now, two retired), including the
      tenant-secret row and its root-shell caveat. Enforced by `CNF-13`.
- [x] **T6 — Topic files with stable identifiers.** `00`–`08`, prefixes `OVR`/`ARC`/`CHN`/
      `STA`/`SEC`/`TRU`/`STG`/`CNF`/`OPN`. `spec.md` is retired; every cross-reference goes by
      identifier. The glossary is definitions only; the summary carries no counts.
- [x] **T7 — Tiered conformance checklist.** `07-conformance.md`, with the tiering rule and
      a tiered BLOCKING set whose additions must each name an irreversible family. The six new ones were `CNF-6`, `CNF-11`, `CNF-16`, `CNF-26`,
      `CNF-34`, `CNF-37`.
- [x] **T8 — Distributions named, artifact source pinned.** `ARC-24` states Alpine and NixOS
      and why they force custom installation; `ARC-25` pins the source by content hash;
      `TRU-E8` puts it in the elective tier; `CNF-24` tests it.
- [x] **T9 — CSP split by directive.** `ARC-33`: `connect-src` permissive,
      `script-src`/`object-src`/`base-uri` strict, with the injected-code reasoning stated.
- [x] **T10 — Reversed ADR bodies rewritten.** ADR-0020 and ADR-0004 rewritten to state
      current decisions, with superseded reasoning kept **only** where it is a trap a fresh
      reader would re-derive (the voucher-is-not-a-credential reading; the
      drop-box-enforces-single-use design; the middle-rung-is-free reading). Stale narration
      removed from ADR-0015.
- [x] **T11 — Diagrams, GitHub-renderable.** Nine mermaid figures: system context, the two
      planes, session binding and post-harness reach, the recovery ladder, the five fingerprint
      routes, the attest sequence, the recovery matrix, the trust tiers, the first-stage
      sequence.
- [x] **T12 — Ledger scoped; setup device-bound.** `STA-11` states that the staleness rules
      bind only a maintained-plus-threshold tenant and why none exists; `ARC-22` states that an
      unfinished setup is resumed where it started or abandoned.
- [x] **T13 — Relay topology priced.** `CHN-13` and `TRU-A2` say the relay learns the machine
      topology; the Certificate Transparency comparison is restated as one chosen party against
      everyone, permanently.
- [x] **T14 — Tunnel priced and marked unbuilt.** `CHN-12` states the bundled certificate-
      authority cost and marks the capability designed-but-unpriced; `OPN-20` tracks it.
- [x] **T15 — Attest ordering and retry.** `CHN-6`: backoff until acknowledged or a deadline,
      scrub on whichever comes first. *(The "deadline inside the voucher's expiry" this task
      first wrote was superseded by ADR-0029: the only window is the browser's clock from
      machine creation, and the machine's deadline is housekeeping.)* `CNF-18` tests the
      browser's window and single-use; the retry, backoff and deadline ordering are **not yet
      tested**.
- [x] **T16 — Command-granular execution and recording.** `ARC-7` and `ARC-8`, with the cost
      stated: anything interactive is the brief's problem, not a live terminal's.
- [x] **T17 — Memory measurement.** `STG-15` and `CNF-45` require peak memory of one session
      during a full install on Android Chrome (iOS was dropped as a test target since), with
      the five-session projection.
- [x] **T18 — First-stage record corrected.** `STG-3` states why rescue is required; `STG-19`
      narrows the subsetting claim to what dedicated rescue actually covers. *(`STG-8` raised
      the tenant predicate above running-and-reachable, then was retired: it tested lnrent
      rather than tau-web. `ARC-39`'s delivery declaration carries the harness's half.)*
- [x] **T19 — The durable remote job record.** Designed. `STA-20` makes every box-plane
      command a job recording the command as received, its output, its exit code and its
      liveness, on installed-system persistent disk. Rescue has `STA-20b`'s explicit lifetime
      exception. The wrapper is POSIX; boot identity uses the declared Linux platforms.
      `STA-21` states that it is machine-reported and advisory, and that comparing it against
      the browser journal catches honest mistakes rather than a hostile machine.
      [ADR-0022](docs/adr/0022-durable-state-is-an-append-only-journal.md)'s amendment carries
      the reasoning and rejects three alternatives: a terminal multiplexer as the record, a
      service-manager unit, and convergence alone. `CNF-40` moves to BLOCKING; `CNF-54` to
      `CNF-56` cover the rest. `OPN-18` closes on implementation.
- [x] **T20 — What the first stage does not test.** `STG-18`: acquisition, relay enrolment,
      inference funding, and a phone-only operator getting started at all.
