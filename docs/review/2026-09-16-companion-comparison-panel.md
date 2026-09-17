# How the implementation is compared: two-reader panel, 2026-09-16

One brief, two independent readers — a fresh Fable reader and codex gpt-6-astra at xhigh —
neither seeing the other's answer, read-only against the working tree of that day, with
tau-web-rust and provisiond-spec in reach. The question: by what mechanism is tau-web-rust
compared against the formal companion? Three candidates — the implementation's CI runs Lean;
the companion emits files the implementation compares against; both — with the owner's
assistant recommending the second. The outcome is ADR-0032's section "How the implementation
is compared".

## Where the readers converged

- Option 2. Neither wants Lean in the implementation's toolchain; both read ADR-0031's "checks
  live here, gates live there" as deciding it; both cite provisiond's emit-and-refuse pattern.
  A scheduled live run only when someone will read it.
- One file per module under `docs/design/`, read by tests from the pinned tree, never compiled
  in. Not build output under `tools/formal/`, not a new top-level directory.
- The bound is the declaration's, shared by the decided theorem and the emitter. A bound too
  small is noticed by a missing named witness, a `CNF-*` case the file lacks, or a
  refused-and-admitted pair with one side missing. Beyond the bound is the theorem's job.
- A conformance item may cite the file (`CNF-83` already does so for the credential vectors);
  the file never cites a conformance item. A pass is evidence about harness knowledge only.
- The files are an additional evidence source, never the only one an item accepts, or module 1
  would gate the first live rehearsal through the fixture paragraph.
- `CNF-3` for the comparison harness: a flipped outcome, a missing or empty file, an
  unrecognised event kind, each red and naming the trace.
- Independence is two implementations of one Markdown that share no code, and holds only while
  the Rust core is written from the requirement text. The theorem makes agreement on the sample
  more than two programs agreeing; it does not protect a wrong statement.
- Drift: a stale pin stays green as "conformant to X"; a Markdown change with an unchanged
  companion stays green until the rendering gate covers that clause.

## Where they diverged, and what was taken

| Question | Fable | astra | Taken |
|---|---|---|---|
| The name | *Witness file*, *bound*, *companion comparison*; "trace vector" collides with the glossary, where a checked trace is already a witness and *test vector* is the credential file's | *Trace fixture*, *fixture replay*, *exploration bound* | Fable's; *replay* stays the journal's word |
| Guard-disabled traces | The admitted-without-the-guard trace is the baseline the Rust harness must see fail | The production core must never be expected to accept one; counterfactuals are the companion's | Both, compatible: each pair appears whole and marked; the core must match the refused trace and differ from the admitted one |
| Where the requirement sentence goes | The fixture paragraph of `07-conformance.md` | A new MUST in the build-and-gate section | Fable's; no new item |

Taken from astra without debate: expected outcomes at each step, not only the end; a lost
response and a crash are driver instructions and the harness sees only absence; the file
supplies requests, never an already-correct resource key; `CNF-29` also covers a different
mutation on a barred resource; a disposition is a terminal record of its own kind with the
outcome written as unknown, so the barrier stays one derivation. Taken from Fable: T29 and the
implementation's README mislabelled the disk check as evidence for `CNF-1`–`CNF-4` when it
evidences `CNF-85`; ADR-0031 gains two lines, no Lean in the implementation's toolchain and a
stale pin is a release fact.

## Left open, stated as such

- The witness-file schema itself is written with module 1 (T31), not here.
- Whether a stale pin should ever warn is settled as "no" for now; a policy requiring timely
  adoption would need its own owner and enforcement.

The readers' full answers are not retained; this record and the text they changed are.
