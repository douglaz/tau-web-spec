# One device, concurrent sessions, approvals batched up front

A federation is provisioned from a single device running one session per member,
concurrently. Each session is configured with different model weights and touches
exactly one machine. The machine creations are approved together in one screen before
any work starts; unexpected cloud-plane actions during the run join a single queue.

## Why one device

The separation that matters is between **models**, not between pieces of hardware. The
operator's device is already a trusted party — it holds the credentials and runs the
bundle — so putting five sessions on it adds no party that was not already trusted.
Requiring five devices to set up one vault would defend against a compromised phone
while guaranteeing that the target operator, who owns one phone, never finishes setup.

## Why concurrent

[ADR-0003](./0003-the-ai-runs-only-in-the-browser.md) means nothing runs while the app
is closed. Sequential provisioning would therefore multiply the time the operator must
hold a phone awake by the member count: a twenty-minute install becomes a hundred-minute
one. Concurrency costs nothing in security, because the invariant is one trust domain
per machine and running them at the same time does not change which domain touches
which machine.

The limits are mobile memory and proxy rate limits, which are reasons to bound
concurrency, not to serialize it. There is also a demonstration benefit: five different
models doing the same job visibly differently, at the same time, is the thesis rendered
on screen.

## Why approvals batch

The two planes differ in predictability, which is the same observation
[ADR-0002](./0002-cloud-plane-and-box-plane.md) rests on. Every machine creation is
known before anything starts, so all of them fit in one screen that shows the whole
federation and its true recurring cost — the figure
[ADR-0008](./0008-three-of-five-default-and-its-economic-floor.md) requires the operator
to see before the first machine exists. Everything unpredictable is box-plane, and
box-plane needs no approval by construction. Mid-flight cloud-plane actions are rare by
definition, so a queue for them is cheap and never competes with itself for attention.

Rejected: per-member approval as each session reaches its gate. Five concurrent workers
producing interleaved popups on a phone is modal fatigue in its purest form, and the
operator cannot tell which member is asking.

## Consequences

**Cross-instance coordination disappears.** Sharing a provenance record between
sessions was an open problem when sessions were assumed to be on separate devices with
no shared backend. On one device they share storage, so there is nothing to exchange.

**A single approval screen authorizes five machines**, so it has to earn that tap:
total monthly and annual cost, every vendor and region, and what recurring means.

**Partial failure is the normal case.** Four members succeeding and one failing must be
a coherent state the operator can act on, not an error. The recovery ladder in
[ADR-0004](./0004-one-model-one-machine.md) applies per member, independently.

**Concurrency must be bounded and tuned for mobile.** The tau-web spec already rates
mobile memory pressure as a high risk and defaults its command-worker pool to one on
mobile; five concurrent sessions each holding a model stream and a remote session needs
the same treatment.
