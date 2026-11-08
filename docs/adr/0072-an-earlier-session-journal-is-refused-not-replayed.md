# An earlier session journal is refused, not replayed

Decided 2026-11-08 by the owner. The journal's versions and this refusal live in
[the credential format](../design/credential-format-v1.md#session-journal-format-2), which
`STA-23` points to; `STA-16` owns import and `CNF-116` owns the cases. This record changes
only how the session journal treats an earlier format. The local-key envelopes, the recovery
sheet and export payloads and the protected evidence payloads keep their old-data rules.

## What changed

[ADR-0052](./0052-no-local-event-ends-a-session.md) gave the journal a new version when it
added End, and read a journal of the older version as ended history. A pre-End wrapper (absent
version or journal version 1) kept its original validation and replayed all its sessions as
ended; a version-2 suffix could follow that prefix without rewriting it, and snapshots carried
the version boundary.

The owner, on 2026-11-08: "We need to be careful about overenginnering on backwards
compatibility. This is a greenfield project and any previous stuff using old data can be
handled manually". Asked whether the text should refuse old data with a clear error
everywhere, the owner chose "Journal part only": "Change only the session-journal rules, the
part the PoC touches now. Keys, recovery sheets and evidence keep their old-data rules."

## The shape chosen

**Format 2 or nothing.** A journal holding any record that is not format 2 is refused at open,
before replay: an earlier wrapper or an unknown journal version, on an event or a snapshot,
first or after format-2 records. Nothing is projected or appended, no session is admitted or
resumes, and the stored bytes stay unchanged. The prefix-and-suffix reading and the snapshot's
version boundary are gone.

**Never automatic.** The refusal never deletes, creates, resets or overwrites a store, and no
single action does it for the operator. Clearing an old store is the operator's own choice; it
permanently deletes the store, seed record included, and leaves what a lost phone leaves
(`STA-14`).

**A message that names the cause.** The refusal tells an earlier format apart from an unknown
version and from corruption, says that the data was left unchanged, and warns that clearing
permanently deletes the store, seed record included, without prescribing clearing.

**No check loosens.** The version member wraps the event or snapshot; every closed-object and
refusal check on the wrapped record still applies.

**Import follows the journal.** A local-store backup's journal is read under the same rule, so
a backup in an earlier format is refused at import. A recovery sheet keeps its own payload
versions and conversions.

**The kept rules.** The local envelope rules decide whether a data key unwraps and may
encrypt. This refusal comes before any replay or report, so their protected read-only reading
applies only to a store whose records are all format 2. Evidence payload shapes inside a
format-2 record keep their rules.

## What it costs

- No journal written in an earlier format can be read, not even as ended history. Its
  transcript, unresolved intents and holds stay in the unchanged bytes but are not shown, and
  the app cannot show the store's seed again or export a sheet from it. Once the operator
  clears the store they are gone, as after a lost phone.
- A store under a v1 local envelope is refused like any other when a record is not format 2.
  Only a store whose records are all format 2 reaches the envelope's protected read-only
  reading, still without encryption budget or append authority. The seedless refusal and the
  other key rules stay as written.

## Alternatives considered

| Option | Disposition |
|---|---|
| Keep reading pre-End journals as ended history | Not selected: superseded by the owner's 2026-11-08 rule. |
| Reset or migrate an old store automatically | Rejected: clearing is the operator's choice, never automatic. |
| Refuse old data everywhere, keys, sheets and evidence included | Not selected: the owner chose the journal part only. |

## Consequences

The credential format's journal section, `STA-23`'s pointer to it, `CNF-116`, ADR-0052 and
ADR-0022's 2026-11-04 amendment change together. The local envelope rules, the recovery sheet
and export payloads, protected browser evidence and `STA-16`'s ended-history import are
unchanged. The formal companion has no journal version and is unchanged.
