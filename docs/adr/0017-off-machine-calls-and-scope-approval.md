# Off-machine calls generalize the cloud plane; untyped ones are approved by scope

The cloud plane covers **any action taken off the operator's machines with a credential they
supplied** — not only infrastructure operations at a cloud vendor. It carries two approval
modes:

- **Typed operations** — an adapter exists, so the action is expressed as structured facts
  and approved individually. This is the cloud plane as
  [ADR-0002](./0002-cloud-plane-and-box-plane.md) defined it, unchanged.
- **Untyped calls** — no adapter exists. The operator approves a **scope**: this credential,
  this host. The harness shows what it knows, records every call before sending it, and
  **claims nothing about what the credential can do.**

We chose this because the harness makes authenticated calls on the operator's behalf and the
old taxonomy had nowhere to put them. A call to a third-party API is not an infrastructure
operation at a vendor, and it is not shell on a machine the operator owns — and each plane's
safety argument turned out to cover only its own half.

The real axis was never cloud-vendor-versus-machine. It is **off-machine versus on-machine**:
off-machine acts at a third party and can spend or publish, on-machine can ruin one server
the operator already bought. That is the distinction
[ADR-0002](./0002-cloud-plane-and-box-plane.md) was reaching for, and stating it this way is
what lets the plane generalize without the blast-radius reasoning collapsing.

## What the operator is actually agreeing to

Not a set of actions. **A credential's authority.** A full-access key approved for one host
has authorized everything that key can do at that host, for as long as it is valid, whatever
the brief intended at the time. A read-only or spend-capped key bounds the damage by
construction.

So the boundary is the credential, and the harness does not control it. It could ask for the
narrowest key that works and describe what that key authorizes — but for most services it
cannot determine the answer, and a bound stated on a guess is worse than none. It therefore
**states what it knows and asserts nothing further**, in the same discipline as the rest of
this design: no verification layer, no implied guarantees, no number that looks like a bound
and is not one.

## Considered options

**Typed adapters only**, with a service callable solely where an adapter exists and adapters
shipping signed like briefs ([ADR-0005](./0005-briefs-ship-in-the-signed-bundle.md)). This
keeps "enumerable, therefore approvable" true everywhere and was the tempting answer.
Rejected because it narrows the platform to services someone has already adapted, which
forecloses the ad hoc and unforeseen use cases that are the point of a platform, and puts a
release between an operator and any new service.

**Refuse credentials the harness cannot bound.** The only option under which the approval
means exactly what it appears to mean. Rejected as unimplementable: most services publish no
machine-readable statement of what a credential authorizes, so this refuses nearly
everything.

**Per-call confirmation for untyped calls.** Rejected because it abandons scope approval for
the case it was chosen for, reintroduces the interleaved-popup fatigue
[ADR-0009](./0009-one-device-concurrent-sessions-batched-approval.md) rejected, and still
shows a non-technical operator a raw request they cannot evaluate.

**Run arbitrary calls from a machine instead**, as box-plane work, so the blast radius stays
bounded to hardware the operator owns. Rejected because the credential would have to reach
the machine, breaking the invariant that credentials never leave browser memory and making
the machine a party that can act — the precise thing
[ADR-0003](./0003-the-ai-runs-only-in-the-browser.md) exists to prevent.

## Consequences

**Recording is now a safeguard rather than a convenience**, and it is the only one standing
behind an untyped call. Every off-machine call made with an operator credential is recorded
before it is sent, which is why this is an invariant rather than a described behaviour.

**The interface must not present a scope as a bound.** "This host, this credential" describes
where the key goes, not what it can do. An approval screen that reads like a limit while the
operator is authorizing a key's full authority is the same overstatement this design refuses
everywhere else — and it is easier to commit here, because the honest wording is less
reassuring.

**The box plane's blast-radius argument no longer covers everything.** "Free-form is
acceptable because the worst case is one machine you already paid for" is still true of
box-plane work and was never true of off-machine calls. Both planes now carry their own
reasoning rather than sharing one.

**Narrow credentials are the operator's lever and nobody else's.** The harness can neither
create nor verify them. Where a service offers scoped keys, using one is the only thing that
actually reduces the exposure — and the product should say so, without implying it has
checked.
