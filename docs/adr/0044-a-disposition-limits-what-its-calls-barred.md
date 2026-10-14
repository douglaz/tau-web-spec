# A disposition limits what its calls barred, and a destructive one stops the model's commands

Decided 2026-10-13. `STA-24` owns the rule, its lapse, what a disposition may name and what a
replay makes of one; `STG-20` and `ARC-21` own the two destructive continuations' own steps;
`STA-20b` owns the stop and the wait before a planned reset. This record adds no second rule. It says why the
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
therefore keeps the box plane stopped except as the continuation permits; a disposed
activation, which barred nothing on the box, bars nothing there by this limit. With the one
exception of the next paragraph, a disposition never forbids more than the unresolved state
did. Reads
and the inference request were never barred, so they are never limited, and an operation
outside the limit does not end it either: otherwise a status read, which is how a barrier
clears, would lift an abandonment.

**A destructive continuation adds its own stop.** When the operator chooses a destructive
reinstall or abandonment, the model's box-plane commands to that machine stop whatever the
disposed call was. This is the one place the limit exceeds what the disposed call barred, and
the reason is the choice, not the call: `STA-20b` already stops dispatch before a planned reset,
and a command admitted between the choice and the reinstall would be open when the reinstall
is requested and would bar it. The reads that show whether a reinstall landed stay permitted,
the pinned SSH attempt and the collection of job records among them, because that is how the
operator learns the outcome.

**The two continuations that continue restrict nothing.** They record what the operator
assumed and let everything through that the disposed calls barred, a re-issue of the same
operation included. The corpus forbids an *automatic* retry; a re-issue the operator chose with
the uncertainty stated is the purpose of the record. A continuation that continues has no
operation to be dispatched at, so it stands, restricting nothing, until it is replaced.

**It stands until its continuation is dispatched, or the operator replaces it.** From the
continuation's own intent that call's barrier governs, which for a reinstall already holds the
box plane until confirmation. Evidence about the calls the disposition names arriving
afterwards is recorded and shown and removes nothing: the operator decided, and nothing but
the operator undoes it. Replacement exists so that a change of mind is possible; without it a machine disposed toward a reinstall could be
taken nowhere else. A replacement names the calls the standing disposition disposed, which is
the one exception to naming only unresolved calls. One disposition stands per resource, the
latest, and its continuation is the one in force.

**A continuation is its owner's flow, dispatched at one operation.** A reinstall or an
abandonment can take several operations. The limit admits, without ending, those that touch no
running system, and ends at the one that changes what the machine is running: the vendor's
reinstall call where the vendor offers one, the reset into rescue on a dedicated server, the
destroy, or the stop that stands in for a destroy where the vendor offers none. On a dedicated
server that reset is the one `STA-24` calls "a reset dispatched after that rescue activation is
confirmed and while the newest read of that activation still confirms it". Any other reset is
refused, because it would boot the installed system again and hand back the machine the operator
chose to wipe. A reinstall chosen while the machine is already in rescue returns to rescue the
same way, so the limit always has an operation to end at, and that reset does not wait for a
command the disposition names: ending it is what the operator chose. Every other command is
still waited for.

**Where the harness cannot recognise the continuation, a destructive choice is a hold.** Under
an untyped vendor scope no call can be told from another, so none counts as the reinstall or
the abandonment. The disposition then refuses every further call under the scope and keeps the
model's commands to the machines of the session's bound set at that vendor stopped until the
operator replaces it. The operator acts at the vendor by hand and is told so before choosing.
This is the one place a limit that holds anything back ends only by a new decision, and it is
confined to where nothing else could end it.

**It names unresolved calls on its own resource, or it is not recorded.** It names at least
one, and for an untyped call the resource is the scope. The replacement above is the one
exception: its calls are the ones the standing disposition disposed. A disposition that is
refused shows the operator that it was refused, the record that settled the call if one did,
and what is unresolved now. The same test, the exception included, reads a journal on replay,
where a record that fails it means nothing and is shown. One test at both moments keeps the
journal's meaning independent of which build wrote it.

## Alternatives considered

| Option | Disposition |
|---|---|
| **The limit applies to every dispatch naming the resource** | Rejected. A disposed activation would begin to bar the box plane, which the unresolved activation never did, and a read request would be refused under a standing disposition, against the read permission the barrier depends on to clear. |
| **The limit applies to nothing on the box plane** | Rejected. A disposition of an unresolved reinstall would lift the box-plane stop for every command at the moment the operator chose to abandon the machine. |
| **A named recovery flow, with its steps and expiry written into the rule** | Rejected as the rule's shape, kept as where content lives. The steps of a reinstall and of abandonment have owners already; restating them beside the barrier would be a second copy. The rule says what a continuation limits and for how long, and points at the owner for what it does. |
| **A destructive continuation adds nothing beyond what the disposed call barred** | Rejected. A stray command would pre-empt the reinstall the operator chose, and each further one would defer it again. |
| **The limit ends at the continuation's confirmation, or never without a new decision** | Rejected. The first adds nothing the continuation's own barrier does not already hold; the second leaves a machine limited after its reinstall succeeded. It is kept only under an untyped vendor scope, where the harness cannot see a reinstall succeed at all. |
| **Under a reinstall only the reset is admitted, the rescue activation refused** | Rejected. The reset boots the installed system again and the reinstall can never start. |
| **The limit ends at the reinstall's first operation** | Rejected. A rescue activation holds nothing on the box, so a command would be admitted between it and the reset and could then bar the reset. |
| **A reinstall chosen in rescue proceeds in the current boot** | Rejected as a reinstall. The new install could run beside the command left unresolved, on the same disks. Keeping the boot is the continuation that continues as if not done. |
| **A separate reinstall-from-rescue operation with a hold of its own** | Rejected. It is a second mechanism beside the reset into rescue, and it still needs a rule for a command that never ends. |
| **Under an untyped scope, the next call counts as the continuation** | Rejected. It asserts what an untyped call does, and a status query would end the limit. |
| **Under an untyped scope, the destructive choices are not offered** | Rejected. Abandonment would stop being available exactly where the harness can do least, and the operator would have no way to hold the scope while acting by hand. |
| **Spending the activation on later evidence** | Rejected. No read is required in that window; `active: false` has no positive meaning; a reboot report has no baseline. |
| **Evidence arriving later lifts the disposition** | Rejected. A status read would hand a machine the operator chose to abandon back to the session. |
| **A disposition naming no unresolved call is accepted and limits nothing** | Rejected. The operator would be shown a standing abandonment that holds nothing, and a disposition recorded against one machine could end a call on another. |
| **A record that fails the test on replay stops dispatch until a recovery step** | Rejected. It needs a procedure nobody has specified, for a record a conforming harness cannot write; read as nothing, every call it failed to dispose still bars. |

## How it was reached

The question came from the implementation: a ticket for box-plane dispatch carried the
criterion that a disposition permits only the continuation it names, and the only dispatch in
that ticket is a box-plane command. Independent readers took the same briefs in successive
rounds, none seeing another's answer. All rejected both readings first put to them, all but
one converged on limiting by the disposed calls, and that one's objection, a stray command
after a destructive choice, became the second paragraph of the shape above. The rounds also
found three defects that hold under any reading and are fixed with this decision: the
companion refused a read request under a standing disposition, it let any later intent end the
limit, and it matched a disposition to a call by call id alone, so one recorded against a
machine could end a call on another.

A first attempt to write the rule down stopped before changing anything, on what the reinstall
is where it is not one call: a dedicated server's return to rescue, a server already in rescue,
and a vendor with no adapter. The shape's paragraphs on a continuation as its owner's flow and
on the hold answer it, after a further round of readers.

## Consequences

The companion's dispatch module changes with the text: the continuation becomes the operator's
four choices, the limit is consulted only for a request a disposed call barred or a destructive
choice stops, a reinstall's preparation is admitted without ending it, and its theorem that every dispatch under a standing disposition is the named
continuation is restated over that reach. That is a change of statement, made deliberately.
The witness file is regenerated as schema 2 under a new name; its enumerated traces that
disposed a call that was never unresolved now record the disposition refused.

The same amendment corrects a sentence beside the rule. `STA-24` said the worker admits at most
one outstanding effect per resource, and the companion's bounded property said the same of
every resource whose unresolved calls are not all box-plane. An activation unresolved beside a
box-plane command, which the carve-outs admit, refutes both; the enumeration had not reached
it because its alphabet held no activation. Both now state what may be unresolved together.
