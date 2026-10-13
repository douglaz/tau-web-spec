# A disposition limits what its calls barred, and a destructive one stops the model's commands

Decided 2026-10-13. `STA-24` owns the rule, its lapse, what a disposition may name and what a
replay makes of one; `STG-20` and `ARC-21` own the two destructive continuations' own steps;
`STA-20b` owns the stop before a planned reset. This record adds no second rule. It says why the
rule has this shape and what was turned down to reach it.

## What was undecided

`STA-24` gave a disposition two properties and never said how far the second one went. It ends
the unresolved state of the calls it names, so the barrier no longer stands on them. And it
permits one continuation, which is a limit that has to outlast the barrier it just ended. The
text did not say which operations that limit applies to. The formal companion applied it to
every request naming the resource, a read included; the box-plane carve-out, read alone,
applied it to none of the box plane. An implementation of box-plane dispatch could be written
either way and disagree with one of the two.

The case that forces an answer: a reinstall is requested, the response is lost, the operator
disposes naming abandonment, and the model then asks to run a command on that machine.

## The shape chosen

**The limit follows the calls, not the resource.** A disposition restricts, to its
continuation, what the calls it names barred while they were unresolved. A disposed reinstall
therefore keeps the box plane stopped; a disposed activation, which barred nothing on the box,
still bars nothing there. A permission never forbids more than the unresolved state did. Reads
and the inference request were never barred, so they are never limited, and an operation
outside the limit does not end it either: otherwise a status read, which is how a barrier
clears, would lift an abandonment.

**A destructive continuation adds its own stop.** When the operator chooses a destructive
reinstall or abandonment, the model's box-plane commands to that machine stop whatever the
disposed call was. This is the one place the limit exceeds what the disposed call barred, and
the reason is the choice, not the call: `STA-20b` already stops dispatch before a planned reset,
and a command admitted between the choice and the reinstall would be open when the reinstall
is requested and would bar it. The reads that show whether a reinstall landed stay permitted,
the pinned SSH attempt among them, because that is how the operator learns the outcome.

**The two continuations that continue restrict nothing.** They record what the operator
assumed and let everything through that the disposed calls barred, a re-issue of the same
operation included. The corpus forbids an *automatic* retry; a retry the operator chose with
the uncertainty stated is the purpose of the record.

**It stands until its continuation is dispatched, or the operator replaces it.** From the
continuation's own intent that call's barrier governs, which for a reinstall already holds the
box plane until confirmation. Evidence arriving afterwards is recorded and shown and removes
nothing: the operator decided, and nothing but the operator undoes it. Replacement exists so
that a change of mind is possible; without it a machine disposed toward a reinstall could be
taken nowhere else.

**It names unresolved calls on its own resource, or it is not recorded.** The same test reads a
journal on replay, where a record that fails it means nothing and is shown. One test at both
moments keeps the journal's meaning independent of which build wrote it.

## Alternatives considered

| Option | Disposition |
|---|---|
| **The limit applies to every dispatch naming the resource** | Rejected. A disposed activation would begin to bar the box plane, which the unresolved activation never did, and a read request would be refused under a standing disposition, against the read permission the barrier depends on to clear. |
| **The limit applies to nothing on the box plane** | Rejected. A disposition of an unresolved reinstall would lift the box-plane stop for every command at the moment the operator chose to abandon the machine. |
| **A named recovery flow, with its steps and expiry written into the rule** | Rejected as the rule's shape, kept as where content lives. The steps of a reinstall and of abandonment have owners already; restating them beside the barrier would be a second copy. The rule says what a continuation limits and for how long, and points at the owner for what it does. |
| **A destructive continuation adds nothing beyond what the disposed call barred** | Rejected. A stray command would pre-empt the reinstall the operator chose, and each further one would defer it again. |
| **The limit ends at the continuation's confirmation, or never without a new decision** | Rejected. The first adds nothing the continuation's own barrier does not already hold; the second leaves a machine limited after its reinstall succeeded. |
| **Evidence arriving later lifts the disposition** | Rejected. A status read would hand a machine the operator chose to abandon back to the session. |
| **A disposition naming no unresolved call is accepted and limits nothing** | Rejected. The operator would be shown a standing abandonment that holds nothing, and a disposition recorded against one machine could end a call on another. |
| **A record that fails the test on replay stops dispatch until a recovery step** | Rejected. It needs a procedure nobody has specified, for a record a conforming harness cannot write; read as nothing, every call it failed to dispose still bars. |

## How it was reached

The question came from the implementation: a ticket for box-plane dispatch carried the
criterion that a disposition permits only the continuation it names, and the only dispatch in
that ticket is a box-plane command. Four independent readers took the same brief in three
rounds, none seeing another's answer. All four rejected both readings first put to them, three
of four converged on limiting by the disposed calls, and the fourth's objection, a stray
command after a destructive choice, became the second paragraph of the shape above. The rounds
also found three defects that hold under any reading and are fixed with this decision: the
companion refused a read request under a standing disposition, it let any later intent end the
limit, and it matched a disposition to a call by call id alone, so one recorded against a
machine could end a call on another.

## Consequences

The companion's dispatch module changes with the text: the continuation becomes the operator's
four choices, the limit is consulted only for a request a disposed call barred or a destructive
choice stops, and its theorem that every dispatch under a standing disposition is the named
continuation is restated over that reach. That is a change of statement, made deliberately.
The witness file is regenerated; its enumerated traces that disposed a call that was never
unresolved now record the disposition refused.
