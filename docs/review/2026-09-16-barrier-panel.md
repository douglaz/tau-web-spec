# The unresolved barrier: two-reader panel, 2026-09-16

One brief, two independent readers — a fresh Fable reader and codex gpt-6-astra at xhigh —
neither seeing the other's answer, both read-only against the working tree of that day. The
question came from `lean-01.md` §2B: `STA-8` bars retrying an unresolved *call*, and a model
does not retry a call; it requests the action again under a fresh call id. At what level does
the barrier hold? The brief offered per call, per resource and per session, with the owner's
assistant recommending per resource keyed on the allocation index for a create and the vendor
machine id otherwise. The outcome is `STA-24`.

## Where the readers converged

- Per resource, as a new `STA-24` with a pointer from `STA-8`: the state rule and the dispatch
  guard are different declarations for the formal companion, and `STA-8` is cited eight times
  for the state.
- The barrier is a derived fact of the journal, an intent with no terminal record, and survives
  replay and session succession without an event of its own. Both added that it must outlive
  the session: with binding exclusive and successive (`SEC-1`, same day), a per-session barrier
  would let a re-entering or successor session reset a machine whose last reset is unresolved.
- Reads clear it; the machine's word does not. A job record settles its own box-plane command
  (`STA-20`, advisory); it cannot clear a cloud-plane barrier (`SEC-8`). A changed `boot_id`
  proves the old command ended, never that it succeeded.
- Under an untyped scope no call is a read, so no call is dispatched until the operator
  disposes.
- A disposition is a record of its own kind, distinct from evidence: it names the outstanding
  calls and the one continuation it permits and keeps the outcome unknown.
- The reset offer after `ready_to_reset` needs durable pins and intent first, and a rendered
  approval is checked again at dispatch; `CNF-86` tests the offer, not only the dispatch.
- `CNF-28`'s kill between record and send: with one pre-send record, intent-without-terminal
  must be read as "may have been sent", and a "sent" record written after transmission cannot
  help. Fable's conservative one-sentence rule went into `STA-4`; astra's prepare-then-arm
  refinement is available if the sub-second operator decision ever proves costly.
- Robot's predicates were incomplete: no negative form (Fable), and no predicate for key
  registration (astra). Both went into `STG-4`.
- Text defects on the way: `STA-9` claimed the journal "knows exactly which commands were
  transmitted"; `CNF-38` lacked the requested-OS check and still said "the session's echoed
  key"; `STA-8` said *terminal event* where the rest says *terminal record*.

## Where they diverged, and what was taken

| Question | Fable | astra | Taken |
|---|---|---|---|
| The resource for a create | The allocation entry, one key for everything | The approved machine entry: a fresh index for the same approved creation is the same hole one level up | astra's entry, in Fable's single-key form: entry ← index ← vendor id |
| Box-plane dispatch while a cloud call on the machine is unresolved | Permitted, bounded by `ARC-3`; `STA-20b` stops dispatch across a planned reset and gains a resume point | Refuse `exec` and harness jobs, permit harness-controlled reads only; concedes this is a dead end without an inspection interface the corpus lacks | Fable's, generalized: a cloud-plane operation that changes what the machine is running stops box-plane dispatch from intent to confirmation or disposition; activation and key registration block nothing |
| The inference request | Exempt from the dispatch block; unresolved intent shown as unaccounted spend against the cap | Stop the stream until reconciliation or disposition; admits nothing identifies the stream durably | Fable's, with the missing `STA-5` declaration written |

Taken from astra without debate: abandonment cannot borrow one session to destroy its
siblings (`CNF-26`), so `ARC-21` names `STA-18`'s deterministic operator flow as its actor; an
unresolved create with no vendor id cannot be destroyed by abandonment and the screen says it
may still exist and bill (`ARC-22`); admission is serialized by the single writer.

## Left open, stated as such

- Whether a Robot reset can be delayed or dropped. The rehearsal's three cycles at about eighty
  seconds are the only data; a vendor statement or a measured bound would settle it.
- Whether the aggregator offers an idempotency key that would let the inference adapter declare
  "idempotent with a key strategy" rather than never-retry. Its documentation settles it.
- A general reset of an already-running installed system reuses `STG-4`'s installed-pin
  predicate, which in the first stage has the rescue-to-installed transition as context. The
  adapter states any further precondition before that predicate is reused elsewhere.

The readers' full answers are not retained; this record and the requirements they changed are.
