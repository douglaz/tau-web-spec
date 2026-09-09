# Tasks

Work arising from the [engineering review of 2026-08-19](docs/review/2026-08-19-engineering-review.md),
which reviewed the corpus at `726ad44`. Each task names the finding it came from, so nobody
has to reopen the review to know why it exists.

**The August review corrections have been applied**, plus further decisions from the grilling sessions that
followed. T1 ran on 2026-09-08 on a disposable auction server; construction is no longer
gated on it.

## Open

- [ ] **T21 — First-stage tenant delivery inputs** (`OPN-14`). Obtain the lnrent-owned
      declaration, finish the Robot lockdown checklist and briefs 2–3, then exercise
      `CNF-49`–`CNF-53`. This blocks stage completion, not harness construction.
- [ ] **T22 — Implement the clarified credential and recovery contracts** (`OPN-3`).
      Local unlock and v1 derivation gate the first stage (`CNF-82`–`CNF-83`); recovery
      export/import and partial Replace gate recovery enablement (`CNF-84`).
- [ ] **T23 — Demonstrate interrupted rescue installation** (`OPN-18`). Implement the
      `STA-20b` handoff and run `CNF-40`, `CNF-55`, `CNF-85` and `CNF-86` on the integrated
      harness. Non-destructive example checks are not a completed hardware rehearsal.

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
- [x] **T5 — Credential inventory.** `SEC-5` is a thirteen-row table replacing the
      prohibition-with-exceptions, including the tenant-secret row and its root-shell caveat.
      Enforced by `CNF-13`.
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
      planes, session binding and coordinator reach, the recovery ladder, the five fingerprint
      routes, the attest sequence, the recovery matrix, the trust tiers, the first-stage
      sequence.
- [x] **T12 — Ledger scoped; setup device-bound.** `STA-11` states that the staleness rules
      bind only a maintained-plus-threshold tenant and why none exists; `ARC-22` states that an
      unfinished setup is resumed where it started or abandoned.
- [x] **T13 — Relay topology priced.** `CHN-13` and `TRU-A2` say the relay learns the member
      topology; the Certificate Transparency comparison is restated as one chosen party against
      everyone, permanently.
- [x] **T14 — Tunnel priced and marked unbuilt.** `CHN-12` states the bundled certificate-
      authority cost and marks the capability designed-but-unpriced; `OPN-20` tracks it.
- [x] **T15 — Attest ordering and retry.** `CHN-6`: backoff until acknowledged or a deadline,
      scrub on whichever comes first, deadline inside the voucher's expiry. `CNF-18` tests the
      voucher's expiry and single-use; the retry, backoff and deadline ordering are **not yet
      tested**.
- [x] **T16 — Command-granular execution and recording.** `ARC-7` and `ARC-8`, with the cost
      stated: anything interactive is the brief's problem, not a live terminal's.
- [x] **T17 — Memory measurement.** `STG-15` and `CNF-45` require peak memory of one session
      during a full install on both browsers, with the five-session projection.
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
