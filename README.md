# tau-web

Design work for a client-side AI harness that lets someone with only a phone provision
and operate real infrastructure, without trusting any party that could act on their
behalf.

**That is the goal, not an achieved property.** Several parties are still trusted, the
specification names each of them, and the security claim it can actually make is one
sentence: *no single model provisioned enough members to reach the threshold.* "Verified"
is not a claim this design can make.

No code yet. This repository holds the specification, the domain language, the decisions
taken so far, and the reasoning that produced them.

`tau-web` is a working name.

## Start here

**[`spec.md`](./spec.md)** — what the system is, how it works, what it may never do, what
must still be trusted, and every open question. It is the entry point and links to
everything else in the repository.

[`executive-summary.md`](./executive-summary.md) is a shorter read of the same material,
for the shape without the detail.

## The two intended tenants

- [btc-policy](https://github.com/douglaz/btc-policy) — self-hosted Bitcoin custody.
  Standing up a federation of policy co-signers means provisioning and hardening several
  machines at several vendors, which a non-technical operator can neither do nor
  delegate, because a single party that provisions every member has defeated the
  federation.
- [lnrent](https://github.com/douglaz/lnrent) — server rental over Bitcoin. An operator
  who cannot stand up the daemon cannot participate, and the project keeps AI out of its
  serving path by design, so any AI help has to live on the user's side.

Nothing here has touched a real server.
