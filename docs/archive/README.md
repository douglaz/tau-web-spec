# Archive

Superseded documents, kept because later work cites them.

## [`rust-first-ai-harness-pwa-spec.md`](./rust-first-ai-harness-pwa-spec.md)

The original specification: a Rust-first PWA with a Tau-derived harness kernel, an
async shell over `brush-parser`, WASI command modules, a capability-scoped tool layer,
29 crates, and milestones M0–M6.

It is archived rather than deleted for two reasons. It is still the only detailed
treatment of the execution layer — the shell, the WASI module set, the relay
requirements in §21, the untrusted-content rules in §20.5 — and nothing has replaced
that material. And the decision records cite its section numbers directly, so the
numbering has to stay reachable.

Read it as a design study, not as a plan of record. It predates [`spec.md`](../../spec.md),
every decision in [`docs/adr/`](../adr/), and the domain language in
[`CONTEXT.md`](../../CONTEXT.md), and where it disagrees with them, they are newer. In
particular it assumes a scope —
milestone-ordered delivery of a full kernel plus shell — that
[the design session](../design/2026-08-07-office-hours.md) rejected in favour of a much
smaller first move.
