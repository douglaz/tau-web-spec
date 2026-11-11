# The rescue rekey keeps a proposed installation ordinal

Decided 2026-11-02, 2026-11-03, 2026-11-04 and 2026-11-05 (`tw-lq8` comments 37000001,
61000001, 66000001, 72000001, 73000001, 75000001, 76000001 and 151000001). `STA-17` owns
the rescue rekey's ordinal acceptance, its relabel, its old-key removal and the session window;
`STG-20` owns the shown id and the reinstall backstop's scope on this path; `STA-16` owns the
partial history and its display; the credential format owns its version; `ARC-43` lists the job.
The install brief carries the surfaced root. This record amends ADR-0045 by note and adds no
rule of its own.

## What was undecided

`STA-22b` says "With no sheet, or for machines missing from a stale sheet, Robot recovery installs
keys from a fresh seed through vendor-authenticated rescue and re-reads host pins", but `STA-17`'s
relabel applied "In this direct re-entry" and `ARC-43`'s job ran "during Replace's model-free direct
re-entry migration". Nothing defined the installation ordinal `n` there, when such a machine counts
as migrated, or which old key it may remove. No representation carried a history whose earlier
installations are unknown, while the credential format says "Missing or invalid history MUST NOT
become empty history". `STG-20`'s backstop compares a later `ready_to_reset` pin against "any
observation or installed-system pin of that machine in any earlier installation", which such a
history cannot show. The install brief treated a root whose label differs from the shown id as the
predecessor, so a return to rescue before the relabel was confirmed could steer the model toward
erasing the machine's own root.

## The shape chosen

Each decision below is an owner's choice, recorded as an amendment.

**The ordinal is a proposal** (decision B, 2026-11-02). With no admissible saved history and a
unique disk label such as `a-7`, the operator may accept 7 after checks against surviving facts,
and the migration to index `b` uses `b-7`. A label is never adopted automatically and proves no
old identity or history. The earlier past stays unknown and every retained fact is kept. The
ordinal does not move during recovery; a later destructive reinstall derives 8 at its dispatch.

**Restart reads the acceptance back** (follow-up A, as settled 2026-11-04). The acceptance is an
ordinary journaled record under `STA-3`, bound to the machine, root and destination allocation.
No restart clause of its own is added; the existing limits on worker authority, changed targets
and automatic retry apply.

**The relabel runs in the installed system after the new-key login** (job-order A). A failed
login leaves `a-7` untouched and stops the migration unfinished (amended 2026-11-06,
`tw-4mz` comment 204000001); a pinned host answer or a rescue login is not acceptance of the
key. The readback is kept apart from access, revocation and the completion of Replace, and the
machine counts as migrated only when a read shows `b-7`. Whether that placement can relabel and
read back the mounted root safely still needs implementation evidence.

**A changed label stops the migration** (changed-label A). An admissible observation of the same
root reporting, say, `a-9` before the write stops it unfinished, with no write, no 9 adopted and
no new installation boundary.

**A refused ordinary host-key read after the key write stops the migration** (2026-11-07,
`tw-4mz` comments 212000001 and 217000001). For the job-refusal and rescue-pin-refusal reach,
see `STA-17`, which says "MUST stop this migration unfinished as a failure other than the
root-label stop". This chooses failure over keeping the flow running for an operator-chosen
later read; it may leave the server in rescue even when the refusal's cause is correctable.
It supplies no repair route or renewed vendor authority. The mount-arrangement open point and
the distinction from a valid read's withheld offer stay at `STA-17`.

**With no ordinal accepted, a successful new-key login stops the migration** (owner-directed
amendment, 2026-11-10, `tw-74f` comment 261000001, rows 01 and 02, after a review panel in two
rounds). Before this, no sentence said what follows a successful installed-system login with
no acceptance on record, and nothing said what happens to a proposal above `STG-20`'s bound.
Now `STA-17` says "If the installed system accepts a login authenticated with the new client key
while no acceptance is on record, `a-7` is left untouched and the flow MUST stop this migration
unfinished: it issues no relabel intent or write and removes no key", and "Migration, Replace and
revocation are reported incomplete, also after restart". For row 02, `STA-17` says "The harness
MUST refuse an acceptance whose ordinal is above 9 999 999 before it is recorded", and it keeps
the route out open: "Whether a later acceptance may leave this stop is not decided". `STG-20`
says "the harness shows it marked unconfirmed and says that no ordinal was accepted" and "No read
ends that mark, not even one showing `b-0` on the disk; only a dispatched destructive reinstall
of the machine does, and that dispatch derives 1"; its reinstall refusal now reads "at or above
10 000 000". The install brief's new branch surfaces every root of that machine, one whose label
equals the shown id included, until that dispatch. `STA-16` says "A machine whose rescue rekey in
`STA-17` stopped after a successful new-key login with no ordinal accepted has a partial history
too, with no accepted ordinal, and export and Restore MUST round-trip it"; the credential
format's partial-history section quotes it and chooses no member name or encoding. These rules
reach only this stop: other stops of a run with no acceptance, such as a failed new-key login,
keep today's text. `STA-17` says "What a root is to the install brief when, after a destructive
reinstall of the machine is dispatched, its old label equals the id that dispatch derives is not
decided".

This amendment adds rules to `STA-17`, `STG-20` and `STA-16`; this record itself still adds none.
Named: it widens the install brief's unconfirmed exception, which covered only
a root whose label differs from the shown id, to a matching root on this path; it widens
`STA-16`'s round-trip duty, which covered only a machine with an accepted ordinal, to this stop;
and leaving the later acceptance undecided is narrower than the stop option first put to the
panel, which let the operator accept later. No theorem, gate or assumption boundary changes, and
no decision above is reopened; a machine left holding a key retained records do not identify
still fails `CNF-5` until a read shows it clean, as decided on 2026-11-05. The panel's counts
and the owner's picks for the shown id ("Show 0, unconfirmed") and the refusal's wording ("Limit
only") are in that comment.

**Only an identified old key is removed** (old-key A). After the login and the readback, the flow
removes the exact old public key that checked retained records identify. An unknown key stays and
revocation reads incomplete.

**A machine that keeps an unknown key fails `CNF-5` until it reads clean** (2026-11-05). `CNF-5`
is unchanged: it requires that "only that machine's public key appears in its
`authorized_keys`", verified by reading the machine. A machine the rekey leaves with an
unidentified key fails it until a read of the machine shows it clean, and is never shown as
holding only its own key. A destructive reinstall stays the operator's choice, never a duty.

**Later reinstall admission compares what is retained** (admission A, 2026-11-03). For this
dedicated Robot path only, a later `ready_to_reset` pin is compared against every fact the harness
retains, those below the accepted base included; any known overlap refuses, and the unknown
comparison is never reported as passed. This narrows `STG-20`'s check: a stale key from the
unknown installations would go undetected. The owner accepted that cost, since refusing would
leave the machine no reset into the installed system after any later reinstall. LNVPS
confirmation and `CHN-R7` admission are unchanged.

**History below the base is kept** (technical common fact, 2026-11-03). Genuine admissible facts
below the accepted base are preserved and the gaps around them shown as unknown.

**An ordinary session waits for the flow to stop** (2026-11-03). `STA-17` says "While this flow
runs, no ordinary session binds the machine", and it owns when a session may bind after the
flow stops unfinished and what that session is shown.
In the install brief, a root not matching an unconfirmed id is surfaced, not erased or resumed,
until a destructive reinstall of the machine is dispatched. This keeps a reinstall route open
after a stop, since a dedicated reinstall needs a session.

**A found sheet stays outside the store** (2026-11-04). No late-evidence act exists. The
2026-11-03 decisions that would have merged, refused or compared a late sheet are withdrawn, and
so is the command-filter decision for unknown history, since the filter was removed (`tw-74e`);
the display rule that the history reads unknown, never unpinned, stands.

## Alternatives considered

| Decision | Option not selected |
|---|---|
| Job order | Write the label in rescue and confirm it from the installed system after login. |
| Changed label | Keep 7 and write `b-7`. |
| Changed label | A separate new confirmation of the same 7. |
| Changed label | Merge it with late-sheet conflict rules. |
| Changed label | A compare-and-set inside the relabel job. |
| Refused ordinary read after the key write | Keep the flow running for an operator-chosen later read. |
| Restart | A restart clause of its own. |
| Reinstall admission | B: refuse whenever the comparison includes unavailable history. |
| Reinstall admission | Reading A as no relaxation of `STG-20`. |
| Ordinary session | No ordinary session until a read shows the new id. |
| Ordinary session | Bind, and accept the observed labels as this installation's. |
| Ordinary session | Show an observed label as the current id. |
| Late sheet | Keep only a found sheet's checked fingerprints. |
| Late sheet | Keep the three withdrawn late-sheet decisions. |
| Command filter | Any command filter on this machine. |
| Unknown key and `CNF-5` | Rewrite `authorized_keys` to the new key alone. |
| Unknown key and `CNF-5` | Exempt from `CNF-5` a machine whose revocation is reported incomplete. |
| No ordinal accepted | Continue with `n` = 0 and relabel to `b-0` after the login. |
| No ordinal accepted | Continue the migration and leave the label `a-7` with no ordinal recorded. |
| No ordinal accepted | Show no installation id until a reinstall, which would derive 0. |
| No ordinal accepted | Let a later acceptance leave the stop. |
| No ordinal accepted | Keep `STA-16`'s partial history to a machine with an accepted ordinal. |
| Ordinal above the bound | Accept it as a proposal and write no relabel. |
| Ordinal above the bound | Keep the reinstall refusal at `n` = 10 000 000 only. |
| Ordinal above the bound | Also refuse on the 16-byte label size, or restate that argument in the refusal. |
| Record of the 2026-11-10 amendment | A new decision record. |

Queued and unchosen: replacing the whole key file, operator-selected deletion of an unidentified
key, admitting a seedless sheet for identification, clearing the unknown from a matching journal
backup, and `tw-l1l`'s distinct T47 edges.

## Consequences

`STA-17`, `STA-16`, `STG-20`, the credential format and `ARC-43` change, with the install brief,
ADR-0045's note, `CNF-117`'s cases, `CNF-86`'s pointer and the state-machine atlas's pointers.
Payload version 6 is defined by what it must carry; its member names and gap encoding are not
chosen here. These rules remain prose only: the formal companion does not carry the accepted
base, and `TauWeb.Pins.fresh` compares against the knowledge it is given. This record makes no
capability, readiness or runtime claim; the dedicated path stays behind its admission row.
The 2026-11-10 amendment changes `STA-17`, `STG-20`, `STA-16`, the credential format's
partial-history section, the install brief, ADR-0045's note, `CNF-86`'s reinstall bound and
`CNF-117`'s cases (q) to (s); it stays prose only as well.
