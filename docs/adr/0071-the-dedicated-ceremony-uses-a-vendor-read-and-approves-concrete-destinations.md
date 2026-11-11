# The dedicated ceremony uses a vendor read and approves concrete destinations

Decided 2026-11-07 (`tw-kx8`, append-only decision notes). The rule's sole home is
`CHN-16`; `STG-4` points there and `CNF-22` owns its ordinary-path exercises. This
record explains the choices and adds no separate destination rule.

## What was open

The jump route had an address source: `CHN-R6` says "The target's address comes
from the target's vendor". Ordinary dedicated first contact had no corresponding
source rule. A relay-key signature identifies the holder authorizing a host;
it does not explain why the harness chose that host for an approved machine.
Host-key pinning acts after destination selection and does not establish its source.

The server address and the bootstrap API destination are different questions.
`CHN-12a` says "A vendor API is named at build time and there are a handful of them."
That source breaks any apparent requirement to read through Robot before its own
host can be recorded. What admits a later concrete pass addition was still open.

## Decisions

| Point | Disposition |
|---|---|
| VENDOR source core | Accepted under the owner's 2026-11-05 panel rule, 4 of 4 |
| CHN-16 home, STG-4 pointer | Accepted under the same rule, 3 of 4 including the required reader |
| Durable-effect core | Accepted under the same rule, 4 of 4 |
| SINGLE source form and USE reach | Each accepted under the same rule, 4 of 4 in round two |
| EXACT concrete-addition approval | Accepted under the same rule, 4 of 4 in round two; relaxed 2026-11-10 by [ADR-0079](./0079-setup-approval-server-destination-relaxation.md) |
| Explicit approved-record dispatch fidelity in the addition clause | Accepted under the same rule, 3 of 4 including the required reader; relaxed 2026-11-10 by [ADR-0079](./0079-setup-approval-server-destination-relaxation.md) |
| SERVER account condition | Owner pick on the surviving 2-to-2 round-two split |
| ECHO server identity evidence | Owner pick on the surviving 2-to-2 round-two split |

Round-two tallies are recorded in commits 291794a and 3315947; SERVER in 404439a.
The decision notes retain the owner's exact ECHO selection. The source packet's
SHA-256 is fa25fdb43ef846fcb3f3895cb3053681c8beb46a70d2414aabdc8d94cf768684;
the approval packet's is 0c7bbd1632a9c3038bc12effac3c9ac0e48817d39abab94037b36ad603441a06.
Edited paragraphs and conditional fallbacks were not counted as verbatim votes.

## Reasons and semantic changes

The decisions narrow previously unspecified source and approval choices. SINGLE
narrows the generic VENDOR observation forms; ECHO further excludes a reply without
its own matching server number. The retained reply can identify itself rather than
depending solely on request/reply bookkeeping. The committed rehearsal captures
contain that field, but scripted curl is not integrated harness evidence.

USE widens the original signed-addition-only proposal to dialing and requests for
recording, so a pre-recorded pass cannot bypass source admission. This selects no
enrolment mechanism. SERVER preserves existing account checks without adding the
unimplemented account-context proof prerequisite proposed by ACCOUNT.

EXACT makes approval about a concrete host-wide pass change, not independent
operator verification of a vendor address. It constrains approval granularity and
explicitly applies structured-facts and approved-record fidelity to these signed
additions. SOURCE-BOUND, authorizing a later host through an earlier selection grant,
was not selected; no earlier binding card acquires that authority.

The shared relay still cannot prove ownership. `CNF-58` includes "an unrelated
eligible public target on SSH and other ports". Its case and shared eligibility
remain separate from the consumer's source check. No formal declaration or theorem
changes, and no runtime conformance or capability admission is claimed.

The rescue rekey remained separate: `STA-17` said "How the flow obtains that pass
and records its destinations is not decided." G5B/H3 and that entire open point
were unchanged here (see the 2026-11-11 note below). Address refresh/export, pass procurement, recording wire and the
addition's retry, reconciliation and resource-barrier contract are not decided here.

*Amended 2026-11-10: EXACT and the dispatch-fidelity row are relaxed for one case.*
[ADR-0079](./0079-setup-approval-server-destination-relaxation.md) records the
owner-directed amendment that lets `ARC-15`'s setup screen authorize in advance the
addition of a server host resolved later from the server-specific read, with the
recorded request taking its host from that journaled read. SOURCE-BOUND's
non-selection above is history for that case; the other decisions, alternatives and
reasoning remain the historical record.

*Amended 2026-11-11: the rescue rekey's pass takes these rules.*
[ADR-0083](./0083-old-key-removal-reads-cover-the-login-route-and-the-rescue-pass-takes-the-ceremony-destination-rules.md)
records the owner-directed amendment (`tw-74f` row 17) that applies `CHN-16`'s source, journal,
structured-approval and durable-record rules to the rescue rekey's fresh-seed pass, with the server
host taken from the granted `/boot/{n}/rescue/last` read and a concrete approval of its addition.
The advance approval of ADR-0079 does not extend to it. The destinations half of the open point
quoted above is closed; how the flow obtains the pass stays not decided, and no recording wire is
chosen.
