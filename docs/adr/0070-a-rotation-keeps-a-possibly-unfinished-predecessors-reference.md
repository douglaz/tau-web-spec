# A rotation keeps a possibly unfinished predecessor's reference

Decided 2026-11-06 (`tw-x7k` comment 144000001). `SEC-5` owns the rotation's end set and
scan boundary; `ARC-43` owns listing, wait and card; `SEC-6` owns the display; the credential
format owns export; `STA-16` points to its recovery limit; `CNF-95(l)` and `(m)` own the
cases. This record closes ADR-0069's disposed-predecessor question and adds no rule of its own.

## What was open

PR #121 settled first-placement starts and the completed-attempt core, leaving the case
of a disposed predecessor without a completed record admitted before the later rotation's
pre-send. The same case reached the first placement's sheet replacement. ADR-0069 records
the first-round split; the owner requested another panel on that question alone.

## Decision and reason

**NARROW, including the first-placement sheet consequence.** The disposed predecessor stays
listed and required under the exception now in `SEC-5`: "The act does not record the rotation
of a placement at that machine, application name, secret name and path whose call the journal
records as disposed and whose completed root-only job record was not admitted before this
rotation's pre-send record". The first placement's retained sheet record and the delayed
successor follow the credential format, which states the resulting recovery limitation.
The completed-before-pre-send core and the rotation's recording act keep their decisions.

Round two gave every reader all first-round answers and their strongest arguments, plus
the original option text. All four recommended NARROW; independently, all four accepted
retaining the first sheet record and delaying its successor until that predecessor ends.
A fifth seat was unavailable. Both parts are accepted under the owner's 2026-11-05 panel
rule. Packet SHA-256: 1d4e96829d558bb152058237bcda19e572fd6952c2bb5d4768058ec6799ed2bf.

The argument that changed the first-round majority's premise was a concrete late writer:
the disposed job may write after the replacement finishes. `STA-9` includes "**still running**"
among the outcomes the journal cannot distinguish. A later successful rewrite does not
establish that the earlier job finished first. Preserving pre-rotation withheld output
alone would not protect a fresh job that reads that later write. The limit at the
credential format's owner records the cost accepted in recovery instead.

## Alternatives

| Option | Disposition |
|---|---|
| FULL: the later recorded rotation ends every earlier unreported attempt at the destination, even a possibly unfinished one | Not selected in round two. It can end the comparison for a value that the harness's own disposed job writes after the replacement. |
| NARROW: retain a disposed predecessor without completed-record admission before the replacement's pre-send, with its first-placement sheet consequence | Accepted. Later completion evidence does not retroactively change an already-fixed end set. |

No additional retirement act, evidence form, schema member or importer change was selected.

## Semantic changes named

- Against ADR-0063's older generic P-end language, this narrows which predecessor a
  recorded rotation ends. It resolves ADR-0069's explicit open case without changing
  that record's completed-before-pre-send core.
- Against the older generic sheet replacement, it widens the export omission: a
  recorded successful successor can remain off a later sheet while the first placement
  stays required. The sheet's knowledge can omit a placement known before export.
- A recorded rotation can end no predecessor and set no mark. Retained references are
  still live, not expired material kept after an end. Each actual end keeps ADR-0060's
  mark and ADR-0061's output boundary.
- ADR-0068's armed-placement explanation now qualifies which rotation ends that placement.
  The scan-limit statement recorded by ADR-0064 applies only to references the act actually
  ended; it never describes a retained predecessor's value as unchecked.
  ADR-0062's unarmed-only final report and ADR-0064's no-revocation and no-erasure limits
  retain their decisions. Dispatch, authority and placement guards remain in force.

## Consequences

The cases distinguish a record admitted before pre-send from one admitted after it,
including between pre-send and zero-exit admission; retained-value scanning of a fresh
post-rotation job; a successor omitted from a later sheet; failed appends; and later
retirement by an eligible rotation. No call outcome is rewritten by any of those ends.
No formal declaration, theorem, assumption or gate changes, and no runtime evidence is claimed.

The separate proposed export exception for a reported failed rotation attempt, an optional
failure label and an older conformance-wording concern were not questions in this round
and acquire no decision here.
