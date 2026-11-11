# No local event ends a session

Decided 2026-11-04. `STA-23` owns a session's lifetime, its pause and resume, the ceremony
pause and the End fence; `STA-3` owns the durable append that admits a session; `ARC-31a`
owns the procured key's one mint, its seal and its revocation; `STG-20` owns when an approval
stands; `SEC-1` owns bindings; `ARC-21` owns abandonment; `STA-16` owns import.
The formats below those owners distinguish session journal format 2 and the new recovery
payload version 5 from the unchanged local encryption envelopes and derivation version 1.

## What was undecided

A session ended at explicit app Lock, pagehide including entry to the back-forward cache,
reload and worker shutdown, and a replay ended it without a journaled record. A paused install
could only continue in a fresh session, and a decision of 2026-11-03 would have carried a
no-brief install's mode into such a fresh session after a Lock. The owner kept that decision
("the session should just resume"), then gave a new direction: "Do not kill sessions". This
record supersedes the 2026-11-03 decision, which was never written into the text. Under this
record Lock ends no session, so the case it covered does not arise, and no rule it would have
qualified carries any of its exceptions.

## The shape chosen

A session survives explicit app Lock, pagehide (including entry to the back-forward cache),
reload, worker shutdown, and the browser freezing or discarding the page. Approvals, bound
machines and the procured paid session key, sealed under the data key, carry on across those
events until End. Replay resumes a session that has not ended.

**What ends a session:**
- an explicit, journaled End;
- an Abandon whose card says it ends that session (below);
- Replace;
- for a paid session, its key's expiry or cap exhaustion. Hidden, frozen and suspended time
  still counts toward the key's lifetime, and a reload, kill or Lock does not extend it;
- loss of the phone's data. Such a session ends by absence, not by a journaled transition, so
  no proof or conformance case claims it as one.

Ending one session still does not by itself lock the whole store or end another eligible
session.
Replace and paid expiry/cap exhaustion use durable End under `STA-23`; failed append
authorizes no dependent work, and established expiry/exhaustion still withholds ordinary work.

**The End record.** A session counts as started from the journal's existing admission records,
each durably appended before the session gains authority; a failed append admits nothing. The
only new record kind is the journaled End, which is irreversible: an ended session's authority
and pending approvals do not revive, and the fence is not reset to implement continuation. The
journal format that adds End records takes a new version. A journal of the older version is
refused at open, not replayed
([ADR-0072](./0072-an-earlier-session-journal-is-refused-not-replayed.md)). For the existing
admission records, see `STA-3` and, on the paid path,
`ARC-31a`; for journal versions, see
[the credential format](../design/credential-format-v1.md#session-journal-format-2).

**Key custody.** The procured paid session key is sealed under the data key and restored from
its own sealed record on replay. It is the only credential this changes: every other
credential is re-supplied or re-derived as before, none is written in cleartext, and replay
still restores no authority to re-mint. There is still one mint per session, and the key's cap
and original expiry are unchanged. Revocation comes at End, not at Lock or close.

**A paid key lost before its seal is durable** leaves the session held until End or the key's
original expiry: nothing runs, and approvals and machines stay. There is no second mint and no
recovery of the same key. The operator presses End and starts a new paid session. While held,
exposure is bounded only conditionally, by the accepted cap where issuer acceptance was
evidenced, with issuer enforcement and automatic top-up off; where acceptance was unseen, the
hard bound is the account balance. Spend stays unaccounted, never zero. An unknown revocation
stays unknown through replay. For seal/validation ordering, a seal without a committed
validated terminal, the SSH hold and pre-End known-id revocation, see `ARC-31a`.
For outstanding revocation after End but before a revoke intent, see the same owner.

**The ceremony pauses.** Viewing the backup words again pauses running sessions as Lock does,
and they resume afterwards with their approvals. The words are still shown outside a session
(ADR-0047), which this does not change.

**Import is ended history.** A restored backup brings back the history of its sessions, never a
live session; the operator starts a new session and approves again. The old phone, if any,
keeps its own session. An export never makes the sealed key usable from an import, and an
import never revokes it.

**No timer.** A bring-your-own or local session that is never reopened keeps its approvals and
machines with no time limit and no idle timer. It ends only on End, an Abandon that says so,
Replace or loss of the phone's data. A paid session still ends at its key's expiry.

**Abandon ends the sessions holding the setup.** Abandoning an unfinished setup is one approval,
made outside any session, whose card says plainly that it ends every session holding any of the
setup's machines. Each such session, as a whole, gets a journaled End with its paid-key
revocation attempted and journaled, and every End is durable before the first destroy. The flow
then destroys what it can and shows what may still bill. Sessions holding none of the setup's
machines are untouched. A holding session's machines outside the setup lose their session but
are not destroyed. Abandonment still never runs through a session, no live bound set shrinks
and no session sends a destroy. For the card, ordering, failed End append and continuation
across openings, see `ARC-21`; for an outstanding revocation and its account-credential
prerequisites, see `ARC-31a`; for bound-set selection, see `SEC-1`.

**What does not change.** Nothing runs while the app is closed, and no hosted, off-device or
machine-resident executor is added. Model context is not saved to disk, and prompt bodies are
still not journaled. No unjournaled continuation is resumed and no unload callback is relied on
for journaling. For context reconstruction and the unfinished model turn, see `STA-23`.
A crash during a dispatch leaves the intent unresolved for reconciliation, with no
automatic retry, and validation comes before any send. A machine is in at most one live
session's set at a time. An unfinished setup stays device-bound. Each newly approved reinstall
still needs its own fresh acceptance.

**Strengthened.** A session's end is a journaled, irreversible record that replay can see, and
the dispatch check reads it. Old page or worker incarnations are refused after a reload, replay
or shutdown.

## What it costs

The owner accepted each of these knowingly:
- Lock and reload are no longer a kill switch; End is. The way to end local sessions is End,
  not App Lock.
- An approved wipe can run after a reload or kill with no new tap: a journaled approval,
  including a destructive one, stands until End.
- A live paid key sits encrypted on the phone.
- A paused session keeps its machines, and no other session can bind them until it ends.
- Worker loss can return the sealed key's authority, and a session that has not ended resumes
  without fresh admission.
- A held session keeps its approvals and machines while its key is lost, under the conditional
  exposure bound above.
- A bring-your-own or local session that is never reopened has no time bound.
- Abandon joins the ways a dormant session ends, only where its card says so, and a holding
  session's machines outside the setup lose their session.

## Alternatives considered

| Option | Disposition |
|---|---|
| Lock only survives; reload and page loss end the session | Rejected by the owner, who chose every local event. |
| Lock, plus a hidden or cached page that is still alive | Rejected by the owner, who chose every local event. |
| Keep progress, ask again for approvals and do not save the paid key | Rejected by the owner, who chose to keep all until End. |
| A model-context checkpoint saved to disk | Rejected: model context is not saved to disk. |
| A second mint, or recovery of the same key, after a lost key | Rejected: one mint per session stands. |
| End the session on its own when its key is lost | Rejected: the session is held until End or expiry. |
| End sessions at the ceremony | Rejected by the owner, who chose a pause. |
| Live sessions from an import | Rejected: an import brings back ended history. |
| An idle or hidden-time timer | Rejected: no new timer. |
| A new admission record, or the guarded admission option | Rejected: existing admission records start a session; the End record is the only new kind. |
| Abandon leaves the holding sessions paused, or requires End first | Rejected: one Abandon approval ends the holders. |
| End every session at Abandon | Rejected: only the sessions holding the setup's machines end. |
| Shrink a live bound set, or send the destroy from a session | Rejected: neither is admitted. |
| Carry an ended session's no-brief mode into a fresh session after a Lock (the 2026-11-03 decision) | Superseded: Lock ends no session, so nothing is carried over. |

## Consequences

`STA-23`, `STG-20`, `ARC-31a`, `SEC-1`, `SEC-5`, `STA-14`, `STA-16`, the abandonment places
and the affected conformance items change together, with the executive summary, `CONTEXT.md`, the state-machine
atlas, `credential-format-v1.md` and `protected-evidence-v1.md`. The formal companion splits
the global end-and-replay theorem into an incarnation fence and a session End, adds a resume
step and a witness that a resume with no sealed terminal keeps the key withheld until End,
turns the ceremony step into a pause, and withdraws the assumption that replay ends the
rendering session; the abandonment theorems stay.
ADR-0003, ADR-0009, ADR-0022, ADR-0023, ADR-0028 and ADR-0045 are amended. This record makes no
capability, readiness or runtime claim.
ADR-0047's all-or-zero completion and outside-session display remain intact.

Changed-file navigation for this amendment:

- `01-architecture.md`.
- `03-state-and-recovery.md`.
- `04-security-model.md`.
- `06-first-stage.md`.
- `07-conformance.md`.
- `CONTEXT.md`.
- `TASKS.md`.
- `docs/adr/0003-the-ai-runs-only-in-the-browser.md`.
- `docs/adr/0009-one-device-concurrent-sessions-batched-approval.md`.
- `docs/adr/0022-durable-state-is-an-append-only-journal.md`.
- `docs/adr/0023-a-tenants-runtime-obligations-belong-to-its-machines.md`.
- `docs/adr/0028-procured-inference-is-the-operators-balance.md`.
- `docs/adr/0035-non-waivable-rules-and-acceptable-weaker-modes.md`.
- `docs/adr/0037-bound-sets.md`.
- `docs/adr/0045-the-installation-label-moves-at-reinstall-dispatch.md`.
- `docs/adr/0052-no-local-event-ends-a-session.md`.
- `docs/design/atlas-implementation-handoff.md`.
- `docs/design/authority-witnesses-v3.json` (removed; superseded witness schema).
- `docs/design/authority-witnesses-v4.json`.
- `docs/design/credential-format-v1.md`.
- `docs/design/dispatch-witnesses-v10.json`.
- `docs/design/dispatch-witnesses-v9.json` (removed; superseded witness schema).
- `docs/design/protected-evidence-v1.md`.
- `docs/design/witness-file-v1.md`.
- `docs/state-machine-atlas.md`.
- `executive-summary.md`.
- `tools/check-controls.sh`.
- `tools/check_witnesses.py`.
- `tools/formal/TauWeb/Authority.lean`.
- `tools/formal/TauWeb/Dispatch.lean`.
- `tools/formal/Witnesses.lean`.
- `tools/render_state_machine_atlas.py`.
- `tools/tests/atlas_cases.py`.
- `tools/tests/coverage_control.py`.
- `tools/tests/test_coverage_control.py`.
- `tools/tests/test_witness_note.py`.

## Amended 2026-11-11: one automatic renewal at expiry

[ADR-0085](./0085-one-automatic-paid-key-renewal-at-expiry.md) amends this record in part, as an
owner-directed amendment that loosens a security rule. "There is still one mint per session" and
the "one mint per session stands" disposition of a second mint now admit the one automatic
renewal that the Start action confirms at a cap of 50.00 or less. A paid session ends at its
key's expiry only with no renewal left; with the renewal left it withholds work and renews once.
Cap exhaustion still ends it. A lost-key hold still gets no second mint and no recovery of the
same key: the hold bars the renewal, and the session ends at that key's own expiry. Revocation
still comes at End, now for every key the session minted. Lock and close still end no session,
and the rest of this record stands. The body above records what was decided then.
