# Tasks

Work arising from the [engineering review of 2026-08-19](docs/review/2026-08-19-engineering-review.md),
which reviewed the corpus at `726ad44`, and from the reviews and decision records since
(T21–T23 from the September 9 review, T27–T29 from the September 15 construction decisions,
the general-case tasks from the decisions of 2026-10-04 through 2026-10-06).
Each task names the finding or decision it came from, so nobody has to reopen the record to
know why it exists.

**The August review corrections have been applied**, plus further decisions from the grilling sessions that
followed. T1 ran on 2026-09-08 on a disposable auction server; construction is no longer
gated on it.

## Open

- [ ] **T21 — Stage-3 tenant delivery inputs** (`OPN-14`; tracked in lnrent as
      [douglaz/lnrent#87](https://github.com/douglaz/lnrent/issues/87)). Obtain the lnrent-owned
      declaration, finish the Robot lockdown checklist and briefs 2–3, then exercise
      `CNF-49`–`CNF-53` on a tenant's machine. *Until 2026-10-05 this blocked completing the
      first stage. It no longer does:* stage 1 has no tenant (`STG-21`), and what it needs from
      `OPN-14` is T42's generic checklist. This task now gates stage 3 (`STG-23`).
- [ ] **T22 — Implement the clarified credential and recovery contracts** (`OPN-3`).
      Local unlock and v1 derivation gate the first stage (`CNF-82`–`CNF-83`); recovery
      export/import and Replace gate maintained-cloud stage-1 completion under the recovery
      row of `07-conformance.md`. Implement `STA-17`'s manual relay retirement, with signed
      revocation and Robot rescue following their separate applicability rows.
- [ ] **T23 — Demonstrate interrupted rescue installation** (`OPN-18`). Implement the
      `STA-20b` handoff and run `CNF-40` and `CNF-54`–`CNF-56` (stage 1's part of `OPN-18`), with
      `CNF-85` and `CNF-86` for the test bed, on the integrated
      harness. Non-destructive example checks are not a completed hardware rehearsal.
- [ ] **T27 — Build the first-stage relay** (publisher; `CNF-87`). *Moved 2026-09-24: the relay
      is paid-tcp-relay's product (github.com/douglaz/paid-tcp-relay) and its checklist is the
      build's gate; what stays here is integrating a relay that passes it, with a hand-recorded
      pass (its `PAS-6`).* Ahead of harness integration: nothing over the channel can be tested
      without it.
- [ ] **T30 — Port `TauWeb.Relay` to paid-tcp-relay** (its `F4`). The module, its witness file
      `docs/design/relay-witnesses-v1.json` and the controls that read them move when that set
      grows a formal layer; until then `CHN-15`, `CHN-16` and `CHN-16a` keep their `@[req]` tags
      and tau-web's index is the proof of record for the handshake and the destination pipeline.
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
      implementation's README carried the same mislabel and was corrected on 2026-09-21, at
      the pin bump that took it to the commit closing the formal companion) from the pinned
      tree as its CI gate.
      `bundle/inference.toml` has an empty model slug on purpose; the build fails until the
      publisher fills it.
- [ ] **T39 — Stage 0: probe LNVPS**. Exercise the owning list in `OPN-24`.
      Record it under `docs/findings/`. If it fails, stage 1 and only stage 1 runs on Hetzner
      Cloud with attest and a card account (`STG-21`). Still to decide: which answers count as
      failing, for stage 1's target and, separately, for stage 2's jump vendor (`CHN-R6`).
- [ ] **T40 — Stage 0: attest on a real first boot** (`OPN-3`). Cloud-init timing, the static
      first-boot tool, and the browser's window against a measured slowest boot (`CHN-6`). It
      is stage 1's first contact, and a window that closes now ends in a recreate (`CHN-R5`).
      The formal companion owes an attest pin source beside its dedicated-path ones (`ARC-43`,
      `SEC-11`); until it lands, `TauWeb.Pins.check` covers the dedicated path only.
- [ ] **T41 — Stage 0: Omarchy's server edition, or plain Arch** (`OPN-25`). And the
      publisher's choice that follows from it: run stage 1 under the unpinned label, or add an
      Arch pin to the bundle first (`ARC-24`, `ARC-25`).
- [ ] **T42 — The generic signed lockdown checklist, and the harness's questions** (`OPN-14`,
      `ARC-17`, `ARC-36a`). The fixed checks, keyed on no vendor and no tenant; the machine-class
      questions, in the harness's words; and the plain-language rendering of a proposed
      declaration the operator approves (`ARC-39`). These ship in the bundle and gate stage 1.
      Implement `ARC-43`'s harness-composed listener, outbound-restriction, unit-state and
      enablement reads behind `CNF-50`, `CNF-53` and `CNF-103`. Still to decide: what establishes survival of a restart, and the
      service-name grammar for a validated argument, never shell syntax. No init-specific
      procedure or physical-restart requirement is selected by this task, nor are the two
      re-check points `OPN-14` leaves open.
- [ ] **T43 — Stage 1's build list**. Implement `STG-21`'s owning list and the stage-1
      applicability rows in `07-conformance.md` at tau-web-rust's next spec pin. These include
      the recovery, scan and report-only evidence; specification edits exercise no harness.
- [ ] **T48 — Stage 1: build placed-secret scanning and recovery re-arm** (`OPN-28`).
      Implement `SEC-5` row 23 and scan semantics, `ARC-43`'s jobs and fallback, and `STA-16`'s
      sheet metadata; demonstrate `CNF-95` with `CNF-42` and `CNF-84`. The design permits
      construction now. Still open: the numeric minimum accepted secret byte length, which
      stage 1's completion requires (`07-conformance.md`); any
      further changed-file detection policy after loss of the old reference; and compatibility
      policy beyond the adopted sheet-payload version bump, should it become necessary. No
      length/value-derived reference belongs on the sheet and no legacy migration is selected.
- [ ] **T49 — Later best practice: a signed library of read-only typed checks** (`ARC-39`).
      Bundle-owned unit-state, TCP/HTTP on a declared listener, and binary-version checks whose
      results can count toward the declaration, using no secret and no third party. This is
      later work, not a stage-1 gate or an acceptable weaker mode. It does not change the
      declaration schema; model-written reports remain reports. Before it lands, the bundle
      classes each check as refusing placement or not: a TCP/HTTP check that counts would
      otherwise refuse the key of an application that only listens once it has its key — the
      trap `ARC-17`'s lifecycle-finding rule removed for `services`.
- [ ] **T44 — The derived vendor identity's format** (`OPN-26`). Not decided: what it is derived
      per — a bound set, a machine or a session; its index family and what its allocation entry
      holds; its key type, pending T39. Until it lands, `SEC-5` row 22 keeps it unavailable and
      `CHN-R6` runs only on a separately supplied jump-vendor credential (row 21). When it
      lands, the Markdown, the Lean declarations, the known-answer vectors, their checker and
      the witness files change together (`STA-22a`, ADR-0032). Decide with it: whether stage 1's
      typed LNVPS adapter uses an operator-supplied credential (`SEC-5` row 1, today's text) or
      a derived one.
- [ ] **T45 — Stage 2: the jump host and the untyped vendor scope** (`STG-22`, `CHN-R6`,
      `SEC-4`). Includes one thing the rules name and nothing yet carries: a jump-host source
      for a pin in the formal companion (`ARC-43` says "a pin taken at a jump-host first
      contact (`CHN-R6`) is not among them"). The placed secret's digest key is not here: it is
      stage 1's (T48). Also owed before an untyped vendor scope is enabled: how the target's
      address is taken from a response no adapter reads without passing through model text
      (`CHN-R6`), and how an unfinished machine at a vendor with no typed destroy is abandoned
      (`ARC-22`).
- [ ] **T46 — What the sibling repositories now owe.** Recorded here; none of them was edited.
      **tau-web-rust:** at its next spec pin bump, implement as tests the new and restated
      cases owned by `07-conformance.md`: `CNF-91`–`CNF-108`, with `CNF-16` and `CNF-42`, and
      the untyped-scope restatements of `CNF-12`, `CNF-14` and `CNF-27`.
      This prior cross-stage handoff debt remains open alongside T43's stage-1 recovery,
      scan and report-only evidence. The applicability table in `07-conformance.md` still
      assigns each case to its stage; stage-2 cases do not gate stage-1 completion.
      **btc-policy:** state its independence rule over configured models as `SEC-T5` records
      it, and say which members a footprint is counted across — one federation, overlapping
      successor federations, or more; its drift checks and required software are still T28.
      **lnrent:** its declaration (lnrent#87) now gates stage 3, and the project decides with
      the publisher whether it is a tenant or a vendor the operator buys from (`OPN-27`).
      **paid-tcp-relay:** wherever its text describes a client that accepts a first contact
      through the relay on trust, this client no longer does (`CHN-R4`); a jump host is an
      ordinary recorded destination and should need nothing new, which is to be confirmed
      against that set and not assumed.
- [ ] **T47 — Questions the general-case decisions left open.** Each is recorded because the
      decisions are silent on it; where one touched a requirement, the requirement kept what it
      said. None is a rule until decided.
      - **A different model per machine is not deliverable on the procured path.** `ARC-31b`
        gives every session the highest-ranked candidate, so several one-machine sessions are
        one configured model, and `SEC-T5`'s footprint reaches quorum at once. Pre-existing;
        stage 3 cannot ship past it (`OPN-27`).
      - **Whether a multi-machine tenant fits the skill shape**, and whether atomic
        multi-vendor creation, sealing and the coordinator stay a harness capability
        (`OPN-27`). **Whether lnrent is a tenant or a vendor** (`OPN-27`).
      - **The recovery ladder's middle rung under a bound set of more than one.** `SEC-1` still
        speaks of re-binding "a half-provisioning machine"; whether escalation re-binds the
        whole set, a subset the operator picks, or is never automatic is undecided.
      - **`OVR-4` and the jump host.** The constraint stayed unconditional and the jump vendor is
        priced as `TRU-E11`. Whether `OVR-4`'s "**one** component in every session's path" should
        itself name the jump host is undecided.
      - **A goal against a shipped brief.** Which wins when the operator's goal contradicts a
        brief the bundle carries for the same software is undecided.
      - **Convergence with no brief.** `ARC-10` makes convergence an authoring rule, and a
        goal-driven run has no author. Whether the bundle ships a harness-level convergence
        instruction is undecided; `CNF-37` is exercised on the goal-driven run meanwhile.
      - **Whether what a model reads under an untyped vendor scope needs a `SEC-5` row.** A
        token the vendor mints and a root password the vendor generates are in model context
        and in the recorded response there (`SEC-4`, `CNF-14`). `SEC-5` puts a secret returned
        in an untyped response "outside the harness's sight and outside this table's reach",
        and row 9 puts such a password outside itself; whether the recorded copy makes either
        a credential the harness holds, owed a row for `CNF-13` to pass, is undecided.
      - **Harm that moves between the machines of one set.** `SEC-14` admits a mode whose harm
        "shows when it happens", and a bound set is one unit of harm, shown as one (`SEC-1`).
        Whether harm crossing from one machine of a set to another meets that test, or the test
        needs wording for a set, is undecided.
      - **The recovery root at an account-free vendor.** `STA-14` names the vendor account as
        "the recovery root" and as "recoverable through the vendor's own processes", while
        stage 1's vendor keeps no account and identifies the operator by a key (`OPN-24`). What
        the recovery root is there is undecided; `STA-14` keeps its text and points here.
      - **An unpinned installation under an independence bound.** The decisions bar a goal, a
        larger set and an untyped vendor scope there, and say nothing of an unpinned OS.
      - **`CNF-67` on an unpinned installation.** Whether the item splits into a pinned and an
        unpinned case, or stays one item that applies where a pin exists, as the applicability
        table reads today.
      - **The untyped vendor scope's remaining edges.** `STA-24` keys an untyped call's barrier
        on "the same origin and credential", so a rotated token at the same origin starts with
        none. `ARC-22`'s abandonment destroys "through typed operations", which an untyped
        vendor has none of. A vendor with no adapter that refuses a browser origin is out of
        reach until `CHN-12b` exists. And under such a scope the target's address arrives in a
        response the model reads, while `CHN-R6` wants it read by harness code.
      - **Host keys baked into a stock image.** `CHN-R6` lists them as a residual. Whether a
        harness job regenerates and re-pins them, and whether a placed secret waits on that, is
        undecided.
      - **Which irreversible family "a multi-tenant machine is bound alone" belongs to.**
        `CNF-92` files it under boundary crossed with the independence-bound case; harm to
        the machine's guests and an escaped secret were both argued.
      - **Two additions argued for machine class and not decided:** running `CNF-52`'s search
        on every machine whatever its class, and asking the class again when a machine gains a
        public listener beyond sshd. And whether Hermes, as shipped, serves parties the operator
        has never met — which would make its machine multi-tenant by `ARC-36`'s definition.
      - **A maintained cloud machine whose pin is lost with no sheet.** `STA-15` says "the
        machine is destroyed and recreated, which re-runs its first contact and loses its
        state", and neither attest nor a jump host re-pins a machine that already exists.
        Whether a later rule should allow it is undecided.
      - **Found by the branch review of 2026-10-06, not fixed there.** `SEC-5`'s minimum byte length has no
        refusal case in `CNF-94` until T48 sets the bound, which stage 1's completion requires. The sheet carries neither `SEC-4`'s two answers for an
        untyped vendor scope nor `CHN-R6`'s jump vendor and date, both stage 2's. After store loss,
        rotating a placement whose file is absent waits for the re-check, while model work on
        the set waits for unarmed references; whether that re-check releases only a status, so
        the two waits cannot hold each other, is unstated (`ARC-43`, `STA-16`). An imported
        local-store backup (`STA-22b`) also loses findings raised after it was taken.
      - **Found by the pull request's review of 2026-10-07, not fixed there.** A renewal
        invoice at an invoicing vendor can be relayed only while the app is open (`ARC-30`,
        `ARC-2`), while stage 1's application is always on. And `ARC-36a` lets the model
        propose a tightening to multi-tenant after binding, while a multi-tenant machine is
        always bound alone and a set never shrinks (`SEC-1`): whether such a tightening is
        refused or deferred in a larger set is undecided (stage 2).

- [x] **T30 — Port the specification gates and the formal companion's scaffold** (ADR-0032).
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
      gate's `TauWeb.*` resolver, and `STA-22a`'s role table as the first clause. The epic
      closed 2026-09-20 with its last ticket: every gate the corpus has, the five modules of
      ADR-0032's inventory with a witness file each and the gate that holds each file to its
      emission, and the rendering gate over the two formalized tables — each landed with its
      own negative controls, which `tools/check-controls.sh` runs on every push. What remains
      of the inventory is the row ADR-0032 defers to cloud-route and btc-policy work, which is
      not this task's and has no ticket.*
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
- [x] **T36 — Formal companion, module 5: the host-pin lifecycle** (ADR-0032's inventory;
      `SEC-11`, `CHN-R1`, `ARC-43`, with `STA-20b`'s resume rule and `STG-4`'s third
      confirmation predicate). Landed 2026-09-20 in `tools/formal/TauWeb/Pins.lean`: what a pin
      is held per is `TauWeb.Pins.Per`, a boot for rescue and the machine for the installed
      system, and where it may come from is `TauWeb.Pins.Source`, paired with what each source
      may pin by `TauWeb.Pins.admits`. The four theorems over every trace are
      `TauWeb.Pins.rescue_pin_per_boot`, `TauWeb.Pins.installed_pin_from_job`,
      `TauWeb.Pins.no_rescue_session_before_fill` and
      `TauWeb.Pins.halt_on_expected_pin_confirms`, the last with
      `TauWeb.Pins.mismatch_not_the_reset` beside it over every state: the halt the reset
      explains and the error are two answers and never one. The one parameter is the source
      distinction, with `TauWeb.Pins.installed_pin_from_model_text_refused` and
      `TauWeb.Pins.installed_pin_from_model_text_admitted` its pair.
      `docs/design/pins-witnesses-v1.json` is its file; the controls collapse the source
      distinction, which must red on the model-text witness and on the bounded property and
      nowhere else, and add a scope with no system.
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

- [x] **T37 — The candidate order and the job that maintains it** (ADR-0033).
      *Initial schema/job completed 2026-09-24 in the specification repository.* The rules first landed in
      PR #8; their owners are `ARC-31a`, `ARC-31b`, `ARC-43`, `TRU-A1a`, `SEC-9` and `STG-17`.
      Conformance fixtures: `CNF-88`–`CNF-90`, with their existing applicability unchanged.
      The initial schema carried ordered `{ slug, maker }` entries, the publisher allowlist,
      `context_floor` and `depth`. `eligible-set.py` applies those inputs to the unchanged
      `models-2026-09-23.json`; the candidate order and diagnostics are recorded in
      `docs/findings/2026-09-22-provider-routing/eligible-set.2026-09-23.txt`, not counted here.
      Makers come from the snapshot's `owned_by`. The bundle and recorded order agree.
      *Decided by the publisher on 2026-09-24:* depth **5**, context floor **500000** tokens,
      an empty allowlist today, and a daily job proposing only candidate-order changes.
      A fetch failure fails the run; the platform's failed-run notification is the alert,
      with no cross-run streak or history. The public model-list fetch uses no credential.
      The initial job probed only a non-empty allowlist, requiring the publisher's repository
      secret, and kept the bundle-wide `z-ai` pin; the amendment below supersedes that shape.
      Retention `strictest` and the aggregator values remain unchanged.
      The runtime no-match decision is now in its owner: `ARC-31b` says "A well-formed list
      containing none of the signed candidates is also treated as unanswered" and "MUST
      record the selection as **unconfirmed**". Its fixture is in `CNF-88`; no running
      harness was exercised by these prose edits.
      *What landed:* `.github/workflows/candidate-order.yml` runs at 06:17 UTC daily and uses
      `tools/propose_candidates.py` with shared eligibility and ordering. It creates or updates a proposal
      branch and pull request, preserving unrelated bundle values. `ARC-31b` says "MUST NOT
      commit directly to the default branch or merge its proposal". The optional repository
      secret was `PUBLISHER_AGGREGATOR_KEY`; the amendment below also requires it for discovery.
      None was obtained or used here. Probe fixtures
      exercise the case G request shape and case C refusal, including a removal proposal.
      The deferred schema pointers and directly affected descriptions are updated.
      *Verification:* `python3 -m unittest discover -s tools/tests -v` passed; the fixtures
      cover historical reproduction, filters and order, no-op and changed bundles, fetch
      and probe failures, secret gating, and proposal create/update against a temporary Git
      remote with mocked pull-request commands. Both required Nix gate commands passed:
      `tools/check-all.sh` and `tools/check-controls.sh`. Workflow syntax passed `actionlint`.
      *Owed to tau-web-rust at its spec pin bump:* migrate `build.rs` to consume the new schema
      and reject missing or empty candidate or allowlist providers alongside the existing empty
      candidate-list and context-floor gates. That build gate was not changed here. Runtime
      selection, requested pins and report comparison remain implementation obligations there.
      *Reopened 2026-09-24 for per-candidate requested providers (tw-xe0).* The publisher's
      values and empty-provider proposal rule were decided; completed below.
      *Clarification raised, now resolved:* with the bundle-wide provider
      removed and the allowlist retained as slugs, an allowlisted entry outside the candidate
      order had no place to carry its publisher-taken provider. The existing
      `test_refusal_outside_candidate_order_is_no_proposal` fixture covers that case.
      *Clarified by the publisher, 2026-09-24:* the pin belongs on the allowlist entry. The
      allowlist becomes a list of `{ slug, provider }`, the provider hand-taken exactly as a
      candidate's is, so no publisher-named model appears in the bundle without the provider the
      publisher chose for it; the probe pins that provider, and a candidate that enters the order
      from the allowlist inherits it. Discovery without a pin does not replace the probe. The
      implementation's build gate rejecting an empty candidate or allowlist provider remains
      owed at the spec pin bump, alongside the migration recorded above.
      *Amendment completed 2026-09-24:* the bundle carries the publisher's per-entry pins;
      the allowlist clarification is resolved. Strict offline selection rejects incomplete
      inputs, while separate draft construction preserves candidate pins and inherits entrant
      allowlist pins. Unpinned entrants remain empty and the PR creation/update body carries
      model-associated provider evidence from impossible-`only` requests with `zdr`.
      The unchanged snapshot reproduces with provider columns. Conformance fixtures remain
      obligations for tau-web-rust; no build/runtime behavior there was exercised.
      *Remaining questions:* a candidate and allowlist entry naming the same slug with different
      pins still have no general conflict policy. No equality requirement or new removal policy
      was introduced. The outside-order refusal/no-proposal fixture is retained; the wording
      tension between `TRU-A1a`'s "proposes removal when one stops routing" and `ARC-31b`'s
      "opens a pull request only when the candidate order changes" remains for the publisher.
      *Amendment verification:* `nix develop --command bash tools/check-all.sh`,
      `nix develop --command bash tools/check-controls.sh`, and
      `nix develop --command python3 -m unittest discover -s tools/tests -v` each exited zero,
      run sequentially and unpiped. The unit suite includes snapshot reproduction and actual
      PR creation/update paths against a temporary remote with mocked network/PR commands.
      Coverage is unchanged, so no baseline ratchet was needed. `actionlint` was unavailable
      on PATH and in the Nix development shell. No live probe or real proposal was published.
      *Resolved by the publisher, 2026-10-04 (tw-awh, tw-2a2):* both remaining questions.
      **The job proposes whenever the proposed bundle changes — the candidate order or the
      allowlist.** `ARC-31b` said "opens a pull request only when the candidate order changes"
      until 2026-10-04; `ARC-31b` says "opens a pull request only when the proposed bundle
      changes", with its trigger list unchanged. `tools/propose_candidates.py` formerly
      discarded an allowlist removal when the order was unchanged; it is now a no-op only when
      both the drafted candidates and the probed allowlist equal the bundle's, and its two
      messages speak of the proposed bundle. An allowlist-only removal has no entrant, so its
      evidence is empty and the pull-request body says there is no provider evidence instead of
      printing an empty block. The outside-order fixture is flipped and renamed
      `test_refusal_outside_candidate_order_proposes_allowlist_removal`; the real-git fixture
      publishes such a removal through `main()`. The workflow comment, `CONTEXT.md`'s
      *Proposing job* and ADR-0033 (its quote and a dated consequence) follow. The proposal
      branch name and the commit and pull-request title are unchanged. The earlier retention of
      the outside-order no-proposal fixture came from that amendment's task brief, not from a
      publisher decision.
      **One slug, one provider.** `TRU-A1a` says "A slug that appears both in the candidate
      order and on the allowlist MUST carry the same provider in both; a mismatch MUST be
      rejected as a selection input and MUST fail the build". `eligible-set.py`'s
      `validate_session` raises on such a bundle, so file reading, strict selection, draft
      construction and the proposing job (before any network call) all refuse it;
      `test_slug_in_both_lists_carries_one_provider` covers the mismatch and the agreeing case,
      and the recorded snapshot output still reproduces. `CNF-88`'s build-fixture sentence
      names the case; no conformance item was added.
      *Owed to tau-web-rust at its spec pin bump,* beside the migration recorded above: its
      build gate rejects a slug carrying different providers in the candidate order and on the
      allowlist. No build gate changed here.
      *Undecided:* a slug listed twice within one list. Today `validate_entries` does not
      reject it, `draft_candidates` keeps the last entry's pin, and the new check compares
      every candidate with every allowlist entry of the same slug; no rule, validation or
      fixture was added for it. As fact, not rule: the tool compares the two provider strings
      exactly, without folding case or normalising. Also undecided: an allowlisted entry whose
      slug is in the candidate order and still badged, when its probe is refused — the job
      proposes the allowlist removal and the candidate keeps the same pin the probe saw
      refused; and a proposal left open when a later run finds the proposed bundle unchanged —
      the job does nothing and the pull request stays for the publisher.
      *Verification:* `nix develop --command bash tools/check-all.sh`,
      `nix develop --command bash tools/check-controls.sh`, and
      `nix develop --command python3 -m unittest discover -s tools/tests -v` each exited zero,
      run sequentially and unpiped. Coverage is unchanged, so the baseline was not ratcheted.
      No live probe or real proposal was published.

- [x] **T38 — What the provider measurement left open**
      (`docs/findings/2026-09-22-provider-routing.md`). *Decided 2026-09-24, and the rules
      landed with the decisions.* The reported provider is a mismatch detector and nothing more
      — `SEC-9` says "A response's own report of the provider is compared, never shown as a
      count"; the proxy's upstream is named by inference on `TRU-E2`'s row, not a new row, since
      `SEC-10` says "The trusted-party list MUST NOT grow silently" and a dated name is not
      silence; the "may be overridden" text is the aggregator's `api-docs` page, which documents
      the routing object and scopes the override, and the corrections that had called the object
      undocumented are reversed; `SEC-9` says "When the requested provider is the maker of the
      weights, the display MUST say so on that machine"; `OPN-23` stays closed with its standing
      ask rewritten. The conformance items for the comparison and the
      same-party mark are T37's.

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
