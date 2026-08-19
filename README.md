# tau-web

Design work for a client-side AI harness that lets someone with only a phone provision and
operate real infrastructure, without trusting any party that could act on their behalf.

**That is the goal, not an achieved property.** Several parties are still trusted, and the
specification names each of them. The harness's own claim is about isolation: a model's blast
radius is the machines its weights have touched, plus any approved credential scope, plus any
tenant secret placed on those machines — and no session reaches a machine it is not bound to
through anything the harness controls. The vault claim — *no single model provisioned enough
members to reach the threshold* — belongs to btc-policy, the tenant that stacks it on top.
"Verified" is not a claim this design can make.

No code yet. This repository holds the specification, the domain language, the decisions taken
so far, and the reasoning that produced them.

`tau-web` is a working name.

## Start here

**[`00-overview.md`](./00-overview.md)** — the problem, the audience, the constraints, and the
map to everything else.

The specification is split by topic, and every requirement carries a stable identifier so that
`SEC-1` means the same rule wherever it moves:

| | |
|---|---|
| [`01-architecture.md`](./01-architecture.md) | How the system is put together |
| [`02-channel.md`](./02-channel.md) | Reaching a machine, and the five routes to a pinned host key |
| [`03-state-and-recovery.md`](./03-state-and-recovery.md) | Surviving a killed worker, and a lost phone |
| [`04-security-model.md`](./04-security-model.md) | The invariants, the credential inventory, the claim |
| [`05-trust.md`](./05-trust.md) | Who must still be trusted, and who chose them |
| [`06-first-stage.md`](./06-first-stage.md) | What gets built first, and what it must show |
| [`07-conformance.md`](./07-conformance.md) | What an implementation must demonstrate |
| [`08-open-questions.md`](./08-open-questions.md) | Everything still unknown, and what would close it |

[`executive-summary.md`](./executive-summary.md) is a shorter read for the shape without the
detail. [`CONTEXT.md`](./CONTEXT.md) is the glossary. [`TASKS.md`](./TASKS.md) is the open
work.

## The two intended tenants

- [btc-policy](https://github.com/douglaz/btc-policy) — self-hosted Bitcoin custody. Standing
  up a federation of policy co-signers means provisioning and hardening several machines at
  several vendors, which a non-technical operator can neither do nor delegate, because a
  single party that provisions every member has defeated the federation.
- [lnrent](https://github.com/douglaz/lnrent) — server rental over Bitcoin. An operator who
  cannot stand up the daemon cannot participate, and the project keeps AI out of its serving
  path by design, so any AI help has to live on the user's side. **tau-web replaces that
  project's current provisioning path**, which holds a cloud vendor token on the machine — the
  arrangement `SEC-3` exists to forbid.

Nothing here has touched a real server. The next move is to run the first stage by hand, once,
against a disposable dedicated server.
