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
that read." `CHN-16` says "It authorizes one addition: the host carried by a matching read
journaled under the source rule above, for that entry, pass and purpose."

For dispatch, `CHN-16` says "An advance-approved addition follows that form except for its host".
`ARC-15` points to `CHN-16` for its one exception. `CNF-22` exercises the advance approval, its
refusals and the recorded request.

## What is loosened and reversed

- EXACT: a server host learned after the setup approval no longer needs approval of that concrete
  addition when the setup screen authorized it in advance. The operator approves the pass,
  purpose, machine entry, server number and host-wide terms, not the concrete host, and does not
  see that host before the relay may connect to it.
- Approved-record dispatch fidelity: the advance approval carries no host, so the request recorded
  before signing takes its host from the journaled matching read. ADR-0071's row applied
  approved-record fidelity to these additions without that exception.
- `ARC-15`'s shared-presentation sentence gains one exception, owned by `CHN-16`.
- The `tw-kx8` decision notes recorded that no SOURCE-BOUND grant, "general permission to
  instantiate an unknown argument after approval" or exception to `SEC-4` was selected. This
  reverses that non-selection for this one case. The qualification is made in `CHN-16`, not in
  `SEC-4` (four of five in round two).
- `CNF-22`'s concrete-host, later-host and exact-request cases now include the advance approval.

## What stays

- `SEC-4` is unchanged, and no sentence declares the addition outside the cloud plane. `CHN-16`
  says the addition follows `SEC-4`'s approval form "without deciding the relay key's cloud-plane
  classification".
- The source rule: a server-specific read naming the entry's immutable server number, the
  response-carried echo, no account listing, relay metadata or model text as a source, and the
  host, source read and relation journaled before any dial, signing or request for recording. A
  host without that journaled matching read stays refused.
- A different server, pass, purpose or host-wide terms, or a host other than the one the addition
  records, needs approval of that concrete addition. No other card acquires the advance authority,
  so a machine added to a bound set afterwards keeps the concrete approval.
- The durable record, approval decision and idempotency identity before signing; a failed
  prerequisite append sends nothing; an uncertain addition stays unresolved with no automatic
  resend; reconnecting needs no new approval.
- Later maintained-machine re-entry, Restore address admission and the LNVPS path's manual
  publisher enrolment are not decided. The rescue rekey stays separate: `STA-17` says "How the
  flow obtains that pass and records its destinations is not decided."
- No theorem, formal declaration, witness or gate changes.

**Formal coverage.** `TauWeb.Dispatch.dispatched_only_if` shows that a dispatched request's facts
equal its approval's. It does not cover a host resolved later falling within an earlier advance
approval; that property rests on `CHN-16` and `CNF-22` alone. This assumption boundary stays
stated and is not closed here.

## Alternatives considered

| Option | Disposition |
|---|---|
| Drop it: every later server host keeps its own concrete approval | Recommended, not chosen by the owner. |
| R07's candidate card verbatim | Not available: it lacks the concrete host and the actual source read (five of five). The adopted form names what the setup screen can know and takes the host only from the journaled read. |
| Amend `SEC-4` with an applicability sentence | Not chosen: the qualification lives in `CHN-16` (four of five in round two). |
