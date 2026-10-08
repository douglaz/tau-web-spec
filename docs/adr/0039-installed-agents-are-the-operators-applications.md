# An agent the operator installs is the operator's application, not the harness's AI

The rule that the AI runs only in the browser is a rule about the **harness's** AI and the
harness's credentials. Software the operator has the harness install that acts on its own —
an always-on agent with a model of its own, Hermes being the first — is the **operator's
application**, and the harness's claims do not cover it. Decided 2026-10-05.

This amends [ADR-0003](./0003-the-ai-runs-only-in-the-browser.md), which says a provisioned
machine "never holds an inference key or a vendor API token and never initiates work".

## Why

The operator's own first goal is to install an always-on agent on a rented machine. Read as
written, ADR-0003 forbids it: that machine holds an inference key and initiates work. But the
record's reasons were about the harness. An inference key of the harness on a machine is a
harness credential outside browser memory; a machine that can call the harness's model can act
for the harness with no operator present. Neither is true of a program the operator chose to
run, with a key the operator obtained for it, answering to nobody but the operator.

A rule that forbade this would forbid most of what anybody installs on a server. A rule that
permitted it silently would let a vault's guarantee appear to cover software the harness never
wrote and cannot see into.

## The decision

**The rule is narrowed to what the harness can answer for.** `ARC-1` says "The harness's AI
MUST run in the operator's browser, and only there". No harness credential reaches a machine
but the attest sender key `ARC-1` excepts,
and the harness never asks a machine to act; what a machine sends is an observation, typed
untrusted, exactly as before.

**The installed agent has a name, and the facts about it are `ARC-1a`'s.** Of its key,
`ARC-1a` says "It is the operator's credential for the application, never a harness
credential"; of its reach, which the machine's delivery declaration (`ARC-39`) states,
`ARC-1a` says "The harness does not constrain an installed agent's reach beyond what that
declaration states".

**The operator is told at delivery, in one sentence.** `ARC-1a` says "Hermes is an AI that acts
on this server by itself", and the card goes on to say whose promises cover what.

## Considered options

**Refuse to install software that acts on its own.** The literal reading. Rejected: it is the
operator's machine and the operator's choice, and the harness refusing it would be the harness
deciding what the operator may run.

**Install it and constrain it** — a sandbox, an egress policy the harness enforces, a monitor.
Rejected: the harness is not on the machine after the session ends and has no credential there
to enforce anything with. What it can do is measure the machine against a declaration, so the
application's destinations and its service are declared, and the delivery check reports a
difference.

**Give the application a capped key minted from the harness's inference account.** Rejected:
that is a harness credential on a machine, which this record exists to keep impossible. The
operator obtains the application's key at its own service; a capped or revocable one is the
better key, and the placement card says so.

**Hand the application the session's own inference key.** Rejected for the same reason, and
because that key is revoked when the session ends.

**Treat the application as a tenant.** Rejected: a tenant is briefs and presets in the bundle,
not a program running on a machine. A tenant may one day ship a brief for installing this
application; the application would still be the operator's.

**Count the application's model in the trust display's layers.** Rejected: those layers count
the harness's own inference, which the harness configures and requests. The application's
provider is a party the operator brought with the application, and it is listed as that
(`TRU-E12`).

## Consequences

**The security claim says what it does not cover.** `SEC-CLAIM` says "The claim covers the
harness's own AI and nothing else that thinks", and a machine carrying an application says so
on its delivery card.

**A machine with an application on it may be multi-tenant.** If the application answers
parties the operator has never met, the machine is in the class `ARC-36` defines, and the
operator is asked (`ARC-36a`). Whether a given application does so as shipped is a fact about
that application, not something this record settles.

**The application's provider receives what the application reads.** The retention request the
harness makes on its own calls does not travel with the application's. That is why the
provider is a named row and not a footnote.

**The placed key is inside every model's reach that has root there**, the application's own
included. That caveat is `SEC-5`'s, and the card states it.
