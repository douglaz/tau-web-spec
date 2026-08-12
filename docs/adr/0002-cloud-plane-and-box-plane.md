# Cloud-plane actions are typed operations; box-plane actions are free shell

Actions split into two planes with different rules. **Cloud plane** covers anything
that spends money or changes infrastructure at a vendor: create, destroy, resize,
firewall, register key. These are typed operations carrying structured metadata, and
each is approved individually. **Box plane** covers shell execution on a machine the
operator already owns. It is free-form, never pre-approved, always recorded.

We chose this because [ADR-0001](./0001-briefs-are-instructions-not-scripts.md) makes
what-will-run unknowable in advance, so approval needs structured facts from somewhere
other than the command text. The two planes turn out to have genuinely different
shapes: spending money is an enumerable API, and `ai-vps-harness` demonstrated that by
expressing it as an enum, while configuring a machine is not enumerable and is exactly
where unanticipated problems live. The split therefore costs the AI nothing it needs.

The blast radii differ by orders of magnitude. Box-plane code can ruin one machine the
user already bought. Cloud-plane code can spend a credit card.

## Considered options

**Statically classify the shell the AI emits** and gate the dangerous commands.
Rejected because classifying arbitrary shell by danger is undecidable and adversarially
fragile — variable expansion, `eval`, base64, a `curl` piped to a shell each defeat it.
It would make a bash escape-detector a load-bearing security control for a system
holding Bitcoin keys.

**A single up-front envelope** (spend cap, permitted destructive classes) with no
per-operation approval. Rejected because one tap authorizing "destruction permitted"
covers both destroying a failed attempt and destroying a funded vault, and nothing
distinguishes them at the moment that matters.

## Consequences

The box plane has no path to the cloud plane. A machine never holds a vendor API
token, so work that needs a cloud-plane action must return to the browser, even when
the AI is mid-way through box-plane work. A brief may *suggest* resizing a machine;
only a typed operation can do it.

Approval means two different things and the UI must not blur them: approving one
cloud-plane operation with its facts shown, versus approving a scope that box-plane
work runs under.

**The cloud plane is broadened by
[ADR-0017](./0017-off-machine-calls-and-scope-approval.md).** Defining it as operations *at
a vendor* left the harness's authenticated calls to any other third-party service with
nowhere to sit — neither an infrastructure operation nor shell on a machine the operator
owns. The plane now covers any action taken **off** the operator's machines with a
credential they supplied, and carries a second approval mode for the ones no adapter types.
The reasoning above is unchanged and the axis it was reaching for is stated plainly there:
off-machine versus on-machine, each side with its own bound rather than a shared one.
