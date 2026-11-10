# Setup approval of a later server destination: an owner-directed relaxation

Decided 2026-11-10 (`tw-qe7.14`) on the owner's instruction, from review item R07, "Reconsider
the extra approval for a provider-resolved relay destination". The owner picked "Fold" over the
recommended "Drop it". This is an owner-directed relaxation, not a clarification. It partially
supersedes two rows of
[ADR-0071](./0071-the-dedicated-ceremony-uses-a-vendor-read-and-approves-concrete-destinations.md),
the EXACT concrete-addition approval and the explicit approved-record dispatch fidelity, for one
case: a server host on the ordinary install ceremony that is resolved after the setup approval.
ADR-0071's other decisions, alternatives and reasoning remain the historical record.

## Why

A review panel, five readers in two rounds with no seat missing, settled the mechanics under the
owner's 2026-11-05 panel rule:

- The server host is learned after the setup approval. The admissible read names the approved
  machine entry and is authorized against the session's binding, both of which that approval
  creates, so batching could not fold the addition into the setup screen (four of five, one could
  not tell from the text).
- ADR-0071's reasons still hold. Batching changed presentation only: `ARC-15` says "Shared
  presentation does not authorize facts unavailable for approval" (five of five).
- R07's candidate card lacks facts today's approval names, the concrete host and the actual source
  read; journaling the host before use is not approval (five of five).

The saving is at most one approval separate from the setup screen, and only on setups where the
server host reaches the pass by a signed addition after setup; the build-named API host needs none
and reconnecting adds none (five of five). Whether a fresh setup always makes that addition did
not settle (three to two); the owner picked "At most one". The owner adopted the fold knowing that
the operator no longer sees the exact address before the relay may connect, and that ADR-0071's
reasons still hold.

## Decision and owner

The rule lives in `CHN-16`, its sole home under ADR-0071. `CHN-16` says "`ARC-15`'s setup screen
MAY authorize, for an approved machine entry it names, the signed addition of the server host that
the server-specific Robot read above later returns for that entry's immutable server number."
`CHN-16` says "That advance approval MUST name the affected pass, the purpose, the approved
machine entry and its server number, and that the host is not yet known and will come only from
that read." `CHN-16` says "It authorizes one addition, to that pass for that purpose, of the host
carried by a matching read for that entry journaled under the source rule above."

For dispatch, `CHN-16` says "An advance-approved addition follows that form except for its host".
`ARC-15` points to `CHN-16` for its one exception. `CNF-22` exercises the advance approval, its
refusals and the recorded request.

## What is loosened and reversed

- EXACT: a server host learned after the setup approval no longer needs approval of that concrete
  addition when the setup screen authorized it in advance. The operator approves the pass,
  purpose, machine entry, server number and host-wide terms, not the concrete host or the source
  read, and need not see that host before the relay may connect to it.
- Approved-record dispatch fidelity: the advance approval carries no host, so the request recorded
  before signing takes its host from the journaled matching read. ADR-0071's row applied
  approved-record fidelity to these additions without that exception.
- `ARC-15`'s shared-presentation sentence gains one exception, owned by `CHN-16`.
- The `tw-kx8` decision notes recorded that neither SOURCE-BOUND, a "general permission to
  instantiate an unknown argument after approval", nor an exception to `SEC-4` was selected. This
  reverses that non-selection for this one case. The qualification is made in `CHN-16`, not in
  `SEC-4` (four of five in round two).
- `CNF-22`'s concrete-host, later-host and exact-request cases now include the advance approval.

## What stays

- `SEC-4` is unchanged, and no sentence declares the addition outside the cloud plane. `CHN-16`
  says the addition follows `SEC-4`'s approval form "without deciding the relay key's cloud-plane
  classification".
- `CHN-16`'s source rule for the server host is unchanged, and the advance approval rests on it:
  `CHN-16` says "a host without that journaled matching read stays refused by the source rule
  above".
- Every addition outside the advance approval keeps the concrete approval: `CHN-16` says "A
  second addition, or a different server, pass, purpose or host-wide terms, requires approval of
  that concrete addition" and "No other card acquires that authority", so a machine added to a
  bound set afterwards keeps it too.
- `CHN-16`'s durable-record, failed-append, unresolved-addition and reconnection sentences are
  unchanged.
- This decision does not reach the LNVPS path's manual publisher enrolment, and `CHN-16` still
  says "address admission on later maintained-machine re-entry or Restore is not decided here".
  The rescue rekey stays separate: `STA-17` says "How the
  flow obtains that pass and records its destinations is not decided."
- No theorem, formal declaration, witness or gate changes.

**Formal coverage.** `TauWeb.Dispatch.dispatched_only_if` shows that a dispatched request's facts
equal its approval's, for the request kinds the dispatch model carries. That model carries no
relay destination addition, so neither ADR-0071's concrete addition nor this advance-approved one
is formally covered, and nothing proves that a host resolved later falls within an earlier
advance approval; that property rests on `CHN-16` and `CNF-22` alone. This assumption boundary
stays stated and is not closed here.

## Alternatives considered

| Option | Disposition |
|---|---|
| Drop it: every later server host keeps its own concrete approval | Recommended, not chosen by the owner. |
| R07's candidate text verbatim | Adopted in substance, with revised wording. Like the candidate, the advance approval lacks the concrete host and the actual source read that today's approval names (five of five); it adds the machine entry, its server number and the statement that the host is not yet known, and takes the host only from the journaled matching read. |
| Amend `SEC-4` with an applicability sentence | Not chosen: the qualification lives in `CHN-16` (four of five in round two). |
