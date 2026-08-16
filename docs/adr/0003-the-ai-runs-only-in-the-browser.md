# The AI runs only in the browser; a machine is a target, never an actor

The AI lives in the operator's browser. It issues box-plane commands over SSH
([ADR-0015](./0015-the-browser-reaches-a-machine-over-pinned-ssh.md)) and cloud-plane
operations through typed operations. A provisioned machine never holds an inference key
or a vendor API token and never initiates work. (The one machine-originated message to the harness added
later — the attest introduction of ADR-0020 — acts on nothing on the machine's behalf;
its only authority is the one-time introduction, handled as the short-lived credential
ADR-0020 classifies. The rule stands.)

We chose this because an inference key on a machine is a credential living outside
browser memory, which violates the constraint the whole product rests on: credentials
never leave the operator's browser. A machine that holds an inference key is a party
that can act, and the reason this project exists is that no such party should exist.

An earlier draft of this ADR justified the decision by saying it protected a
"cross-check" comparing what two models did. That justification is withdrawn. See
[ADR-0004](./0004-one-model-one-machine.md): there is no cross-check, because any
mechanism where one model inspects another's machine from inside gives that model a
second
foothold. The decision stands on the credential argument alone, which is stronger and
does not depend on a verification mechanism that does not exist.

## Considered options

**A box-resident agent with box-plane authority only** — an inference key on the
machine but no vendor token, so unattended progress with a blast radius of one
machine. This looks like the balanced answer and is the one worth recording as
rejected, because it will be proposed again. It fails on the credential constraint: the
inference key is a live credential sitting on a machine the operator cannot inspect
from a phone, and a machine that can call a model unprompted is a machine that can act
unprompted.

**A full agent on the machine**, holding both credentials and operating autonomously.
Rejected because a machine holding vault key material would also hold a cloud token
and be able to act unprompted, which is the architecture this project exists to avoid.

## Consequences

**Nothing runs while the app is closed.** This is consistent with the archived
specification ([`docs/archive/rust-first-ai-harness-pwa-spec.md`](../archive/rust-first-ai-harness-pwa-spec.md),
the source of every `§` in this record), which already lists background execution after
the PWA is closed as a non-goal (§3) and treats browser suspension as a first-class
problem (§19), so it is a confirmation rather than a new limit.

Long operations must be resumable across a locked phone rather than assuming a screen
stays awake, which is a real constraint on iOS. Brief steps therefore need to be
individually resumable, and progress must survive the harness worker being killed.

The periodic security audit of a running vault requires the operator to open the app.
It cannot be scheduled server-side without reversing this decision.
