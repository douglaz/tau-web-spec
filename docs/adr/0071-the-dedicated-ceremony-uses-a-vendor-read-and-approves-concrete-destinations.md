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
| EXACT concrete-addition approval | Accepted under the same rule, 4 of 4 in round two |
| Explicit approved-record dispatch fidelity in the addition clause | Accepted under the same rule, 3 of 4 including the required reader |
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

The rescue rekey remains separate: `STA-17` says "How the flow obtains that pass
and records its destinations is not decided." G5B/H3 and that entire open point
are unchanged. Address refresh/export, pass procurement, recording wire and the
addition's retry, reconciliation and resource-barrier contract are not decided here.
