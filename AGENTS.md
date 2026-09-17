# AGENTS.md

Specification only. `tools/` holds the gates that check it and will hold, under `tools/formal/`,
the formal companion (ADR-0032); `.github/workflows/` runs the same scripts. Nothing that implements
the harness belongs here — that is `douglaz/tau-web-rust`, which pins this repository as its
`spec/` submodule (ADR-0031).

## Gates

`bash tools/check-all.sh`, before you start and again before you report done. Run it unpiped — a
pipe reports the pipeline's status, not the gate's, which is why `check-all.sh` captures each exit
code directly. When the Lean package lands (ADR-0032; TASKS T30), the command becomes
`nix develop --command bash tools/check-all.sh`, and a missing toolchain is a red gate, not a
skipped one.

A formalized clause's home is its Lean declaration in `tools/formal/`, tagged `@[req "STA-22b"]`
(ADR-0032, "Authority is per clause"). The Markdown keeps the identifier, the MUST, the rationale
and the retained traps, and stays authoritative for every clause until a rendering gate covers it.
Change the declaration and the Markdown together; a theorem that stops proving is the gate telling
you the amendment contradicts a property the corpus claims — read the theorem before weakening it,
since weakening a statement to make a proof pass is a semantic change like any other. Never put a
`CNF` identifier in `tools/formal/` or in a witness file.

Green is evidence only because `tools/check-controls.sh` breaks a document on every run and asserts
the gates reject it — one negative control per refusal, each requiring exactly one finding under
the label it targets. `CNF-3` says "The test suite fails when a test is deliberately broken —
verified once, by hand, so that 'tests passed' means something"; the controls are that, for the
gates, on every run.

## Writing a requirement

The rule and the record are two edits with two different failure rates. Land the rule; write the
record after.

**Quote the sentence.** A claim about what another requirement says carries that requirement's own
words. `` `STA-24` says "The unresolved barrier holds per resource, not per call" `` is checkable;
"`STA-8` already forbids that" is an assertion. `lean-01.md` §A is what an unchecked assertion
costs: "`SEC-1` describes each session as having its own SSH keypair. The credential inventory and
`STA-22`, however, specify an SSH key derived per machine", and every reader had passed both.

**Cite the owner.** One rule, one home; everywhere else points at it. A requirement moved to a
tenant profile (ADR-0030) leaves a one-line "Moved to" pointer behind and nothing more; `ARC-20`
was a full second copy until the identifier gate refused it. **Arguments have owners too** —
re-explaining a rule in a second document is how a second normative copy gets written, because you
cannot explain a rule without restating it.

**Cite the list; let it hold the number.** A count written into prose is wrong the first time either
end moves. The conformance item count is what `tools/check_ids.py` prints, and lives nowhere in
prose.

**Completion:** every sentence asserting what another requirement says carries its quote, and every
list or count names its source instead of restating it.

## Agent skills

### Issue tracker

Beads (`br`), local-first in `.beads/`, committed with the specification. See
`docs/agents/issue-tracker.md`.

### Triage labels

The five default roles as `br` labels. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` and `docs/adr/` at the root. See `docs/agents/domain.md`.

## Conventions with a home already

- Identifiers, pointers, withdrawn ids → `README.md`, *Requirement conventions*.
- Vocabulary, overloaded and banned words → `CONTEXT.md`.
- Decisions and what was rejected to reach them → `docs/adr/`.
- What an implementation must demonstrate → `07-conformance.md`.
- Tenant-specific rules → `docs/tenants/<tenant>/profile.md` (ADR-0030).
