# A federation is created only when every member works

Federation creation is all-or-nothing. The coordinator does not form a federation until
every member is provisioned, locked down, and reachable. There is no partial or degraded
federation, and a member cannot be added to a live one during setup.

We chose this because a partially-formed federation has no honest description. A 3-of-5
vault with four working members is not "80% set up" — its real threshold, its real
failure modes, and its real security claim are all different from the thing the operator
was shown and approved, and none of those differences are visible from a progress bar.

## Consequences

**"Four up, one stuck" is not a state, it is an unfinished setup.** The recovery ladder
in [ADR-0004](./0004-one-model-one-machine.md) applies to the stuck member: retry;
escalate to a stronger model behind the same proxy — conditional, per that record's
second amendment, since the stronger model is new weights that must not be running
another member; then destroy and restart under different weights.
The other four wait.

**The operator pays for waiting machines.** Approval is batched up front
([ADR-0009](./0009-one-device-concurrent-sessions-batched-approval.md)), so all five
machines exist and bill from the moment they are created, while one member is being
retried or replaced. (The prompt-for-resume-or-abandonment opinion this record asked for
has since been decided: an unfinished setup owns the app's opening screen — `ARC-22`
records the behaviour.) A setup that stalls overnight costs a night of five machines for
zero federations. The approval screen therefore has to say what happens if setup does
not complete, not only what the monthly cost is when it does.

**Abandonment must be a first-class action.** If the operator gives up, something has to
destroy every machine that was created, or they will pay indefinitely for an
unfinished vault. This is a cloud-plane operation and needs the same approval treatment
as creation.

**This bounds how long a setup may be left open.** Since nothing runs while the app is
closed ([ADR-0003](./0003-the-ai-runs-only-in-the-browser.md)), an interrupted setup is
a set of billing machines with no progress. The product needs an opinion about when to
prompt the operator to resume or abandon, rather than leaving it silent.
