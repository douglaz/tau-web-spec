# Explicit personal goal reuse: an owner-directed relaxation

Decided 2026-11-08 on the owner's instruction. This partially supersedes
[ADR-0034](./0034-general-case-first-tenants-are-optional-skills.md)'s personal cross-session
goal-reuse prohibition. It is a relaxation of the blanket prohibition on applying stored goal
text to another session. ADR-0034's historical decision and rejected
options remain recorded there.

## Why

An operator may want the same installation on a replacement server, the same desired outcome
after a session ended, or a personal recurring maintenance instruction. Retyping that
instruction adds no protection for machines whose profiles permit goals and declare no
independence bound. Choosing retained personal text makes that work easier while keeping
admission and authority attached to the receiving session.

## The decision and its owner

The permission and its guards live only in `ARC-11a`. `ARC-11a` says "Where every target profile
permits goals and declares no independence bound, the harness MAY let the operator
explicitly select their own retained goal text from the same local store for a new session."

The selection is reviewable and recorded: `ARC-11a` says "Before session admission, the harness
MUST show the selected instruction text, its source and intended target, and let the operator
edit the text" and "It MUST journal the selection, source/provenance, chosen text and any edits
with the receiving session before admission."

Instruction text is the only transfer: `ARC-11a` says "Reuse transfers no approval, credential,
binding, limit, execution outcome or authority" and "The harness MUST establish the receiving
session's authority, binding, limits, approvals and applicable weaker-mode acceptances
normally."
In particular, `ARC-11a` says "A failed or ended source session conveys no approvals or
continuation authority" and "Selection MUST NOT trigger command replay".

The relaxation leaves distribution outside the permission: `ARC-11a` says "The harness MUST NOT
offer automatic cross-session propagation, loading a goal from elsewhere, sharing between
operators or a marketplace of unsigned templates."
An operator's own restored history is not "elsewhere": `ARC-11a` says "Goal text in ended
history that the operator's own local-store backup restored on import (`STA-16`) counts as
retained in the importing store; its shown and journaled source names that import." Treating
such text as loading a goal from elsewhere, and refusing it, was considered and rejected: an
operator's own backup on their own new device distributes nothing, and refusing it would take
the reuse away whenever the phone is replaced along with the server. A recovery sheet carries
no goal text, so a sheet-only Restore leaves nothing to select.
This is distinct from runtime-supplied shared briefs: `ARC-11` says "Briefs MUST ship inside
the signed application bundle"; ADR-0005's signed-brief decision stands.

## Tradeoff and preserved boundaries

The owner accepts a common-mode risk across personal sessions: `ARC-11a` says "Repeated
unsigned personal text can repeat the same mistake across the operator's sessions".
The independence-bound refusal remains: `ARC-11a` says "A goal MUST be refused for a machine
under a profile that declares an independence bound" and "No operator act waives this refusal."
The rationale for independence-bound profiles and signed briefs stays with that owner and
ADR-0005, rather than treating personal reuse as an unsigned brief distribution path.

Same-session recovery is separate and `STA-23` is unchanged: `STA-23` says "It does not load
another session's goal" and "Reconstructed context supplies no approval, automatic retry or
permission to bypass holds."

The `STG-21` synchronization is a dependent restatement: `STG-21` says "re-enters the same
machine with a goal of its own, whose provenance is governed by `ARC-11a`".
Only that goal-provenance clause changes. The later session remains required for placement
or rotation on the same machine; selected instruction text becomes its own recorded goal
under the owner, where `ARC-11a` says "The selected instruction, after any edits, becomes that
session's own recorded goal."

## Dependent evidence

`CNF-102` says "If the interface offers explicit personal reuse, select the operator's own
retained text from the same local store for a different session whose target profiles all
permit goals and declare no independence bound."
For re-entry, `CNF-108` says "exercise both freshly entered text and, if offered, explicit
personal selection under `ARC-11a`". Neither changes tier or admission applicability.
`CNF-98` says "The jump-host route's residual trust is shown in full"; those checks are
unrelated to goal provenance and remain unchanged. The glossary and ad-hoc profile point to
the owner; the profiles' independence bounds and capability admission are unchanged.
