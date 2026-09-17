**Yes. I would use Lean for tau-web, but specifically to formalize the deterministic security and recovery core—not to rewrite the browser application or claim that AI-provisioned machines are verified.**

The strongest opportunities are **credential allocation, authorization, crash-safe dispatch, relay admission, and lifecycle transitions**. These are areas where a small implementation mistake can violate an otherwise carefully written security argument.

I reviewed the specification at commit `9c58b444`, including its security, architecture, recovery, channel, conformance, and normative interface documents. The linked `tau-web-rust` repository currently contains its README, Git configuration, and the pinned specification submodule, rather than a production harness implementation. That makes this a particularly good point to shape the implementation around a small, testable policy core.

My recommendation is:

> **Keep the prose as the explanation of the design. Add an executable Lean model for selected normative behavior. Test the Rust implementation against that model, then selectively connect actual Rust code to Lean proofs.**

## 1. Why this specification is a good fit

Your design already has several properties that make formalization useful rather than decorative.

The durable state is owned by one harness worker and reconstructed from an append-only journal. Requirements have stable identifiers. Authorization and credential placement are explicit. The specification also distinguishes what the harness controls from what remains a trust assumption about the browser, vendor, model, or machine. Those provide unusually clear boundaries for a formal model.

The main opportunity is to check **interactions between requirements**.

For example, “reserve an index before creating a machine” is straightforward in isolation. The difficult question is whether index uniqueness survives an append failure, a worker crash, an uncertain vendor response, a destroyed machine, an imported backup, and a subsequent Replace operation.

Lean can check proofs covering all executions admitted by a model, rather than just selected examples. Its proof kernel checks the logical argument, including proofs produced with automation. It does not, however, check that your chosen model faithfully represents the browser and remote services. That correspondence must be addressed separately. ([Lean Language][1])

**The right scope is therefore a small formal model of the decisions tau-web itself makes.**

### Where the return looks strongest

The priorities below are my proposed order, not existing project commitments.

| Area                                | Relevant contracts               | What I would establish                                                                 | Priority                               |
| ----------------------------------- | -------------------------------- | -------------------------------------------------------------------------------------- | -------------------------------------- |
| Credential allocation               | `STA-22a/b`, `CNF-72`            | No derivation-identity reuse, including failures, destruction, restore, and exhaustion | Start here                             |
| Journal and effect dispatch         | `STA-1–8`, `STA-20b`, `SEC-12`   | No effect without durable authorization, no unsafe retry from uncertainty              | Start here                             |
| Session and operation authorization | `SEC-1`, `SEC-3–5`, `SEC-8`      | Operations cannot escape their binding or manufacture authority from external content  | First core                             |
| Relay admission                     | `CHN-15/16a`, `CNF-81/87`        | No dial before admission, no unchecked destination reaches the dialer                  | First-stage companion                  |
| Host-pin lifecycle                  | `SEC-11`, `CHN-R1`, `ARC-43`     | Connections use pins admitted for the right machine and phase                          | First-stage companion                  |
| Declaration and handoff rules       | `ARC-39`, `ARC-19a`, `CNF-49–53` | Incomplete declarations cannot pass, handoff cannot acquire administrative reach       | Next                                   |
| Exposure and tenant bounds          | `STA-10–13`, `SEC-9`, `SEC-T3`   | Historical exposure and per-layer reach are counted correctly                          | Before relevant multi-machine features |

I would not make the first lnrent stage wait for a comprehensive formalization of future federation features.

## 2. The first proof effort: allocation, authorization, and effects

These should be connected parts of one model, not three independent demonstrations.

The following are **proposed proof obligations**, not proofs I have implemented or checked during this review.

### A. Credential allocation: small enough to start, important enough to matter

Your allocation design already contains strong rules: indices are reserved durably, failed allocations remain consumed, destroyed allocations leave tombstones, and a seed restored after losing the canonical journal cannot allocate new identities. The credential format also prohibits index wraparound and silently skipping invalid derivations.

I would model an allocation identity as:

```text
(seed epoch, derivation version, role family, index)
```

Then prove that no two allocations assign that identity to different resources.

The interesting cases are not normal allocation. They are a reservation followed by a failed create, an uncertain create response, destruction followed by another allocation, and restoration from a stale sheet.

The model should distinguish:

```text
Canonical journal available → new allocations may be permitted
Restored identities only    → listed identities may be used
                              new allocations are forbidden
```

That distinction should survive every subsequent transition. A successful connection after Restore must not accidentally promote the restored seed back into an allocation-capable seed.

Two details are particularly important.

**Destroying a machine must not free its derivation index.** Ending a machine’s exposure lifetime and recycling its cryptographic identity are different operations.

**Prove uniqueness of allocation identities and derivation paths, not the mathematical impossibility of cryptographic key collisions.** The latter would require a different, cryptographic argument. The useful software theorem is that tau-web never deliberately derives the same identity for different allocations.

This would be my first standalone Lean module.

### B. Crash recovery: model uncertainty, not just successful replay

The recovery specification correctly distinguishes the browser’s record from remote execution. A command may not have arrived, may have stopped, may still be running, or may have finished without the browser receiving its result. Remote job records are explicitly advisory, and a changed rescue boot identity proves that an old process ended, not that its work succeeded.

A useful formalization therefore needs **two kinds of state**:

| State             | Meaning                                                        |
| ----------------- | -------------------------------------------------------------- |
| Harness knowledge | What was durably authorized, prepared, attempted, and observed |
| External state    | What the vendor or machine may actually have done              |

Do not collapse them into a single `operation.status`.

The central proof obligation would be approximately:

```text
An effect is dispatched
    only if its matching intent and authorization are durable,
    its current authorization checks pass,
    and no unresolved-operation barrier forbids dispatch.
```

Then prove that recovery preserves the barrier.

Consider this trace:

```text
Authorize destructive operation
→ persist intent
→ transmit request
→ remote service performs it
→ response is lost
→ worker dies
→ replay journal
```

The recovered state must not become “failed, retry permitted” merely because there is no terminal success record.

A particularly valuable case is **a model requesting the same destructive action with a new request ID**. Deduplicating one call ID is insufficient if an autonomous caller can evade the protection by producing another. I would make the unresolved barrier apply at the relevant session or resource level, while still allowing the specific inspection and reconciliation operations needed to resolve it.

This strengthens the implementation interpretation of `STA-7/8`, rather than introducing a generic ban on all work after every network error.

For Robot, your specification already says mutations lack request identities and must reconcile through observable state. That is precisely why the theorem should be “no unsafe harness redispatch,” not an unconditional claim of exactly-once remote execution. A local journal does not turn an external API into an idempotent service.

### C. Authorization: prove that approval applies to the operation actually sent

`SEC-4` already requires structured approval and adapter-enforced checks against the calling session’s machine binding. I would make the identity of that approval more explicit in the formal contract.

An approval should cover an immutable operation containing, as applicable:

```text
actor/session
vendor and account
immutable machine identity
operation kind and arguments
declared cost or other approved bounds
relevant configuration revision
```

The adapter should execute that approved object—not rebuild a request later from mutable session state or model-provided arguments.

This makes the following questions precise:

Can the selected machine change between approval and dispatch? Can a scope be revoked while a request waits? Can an adapter resolve a display name to a different resource? Can a queued request outlive the session grant that authorized it?

The desired theorem is not simply “there was an approval.” It is:

> **The dispatched operation matches the approved operation, and the authorization is still applicable when dispatch occurs.**

The actor distinction also matters. Your deterministic vendor-inventory recovery flow runs before a session exists. It should be a separate authorized actor in the model, not an exception implemented by bypassing session checks.

For external content, the useful guarantee is similarly specific:

> No external observation can mint an approval, change a binding, or grant itself a capability.

That does **not** mean prompt injection becomes impossible. Untrusted content can still influence a model into proposing harmful actions within its permitted authority. The theorem concerns the authorization boundary, not the model’s judgment.

## 3. Concrete specification clarifications this review exposed

Lean would not automatically discover these by reading the Markdown. But translating the prose into one executable contract forces these ambiguities to be resolved.

### A. Is the SSH identity per session or per machine?

`SEC-1` describes each session as having its own SSH keypair. The credential inventory and `STA-22`, however, specify an SSH key derived per machine and retained for that machine’s lifetime. Later sessions re-enter maintained machines using re-derived credentials.

These can form a coherent design, but they are not identical claims.

I would distinguish:

**Machine credential:** the long-lived identity that authenticates to one machine.

**Session grant:** the temporary authority allowing a particular session to use that machine credential through the harness.

Under that interpretation, separate machines have separate SSH identities, while successive sessions on the same machine can use the same underlying machine identity.

The spec should then explicitly define predecessor-session termination, overlapping sessions, and stale channel handles. It should not imply that SSH itself distinguishes two sessions using the same private key.

That is a specification clarification, not evidence of an existing implementation exploit.

### B. The relay has inconsistent shorthand about dialing order

The normative relay sequence is:

```text
Challenge
→ AUTH accepted
→ TCP dial succeeds
→ OK sent
→ binary traffic
```

Its body correctly requires authorization before dialing, and `CNF-87` uses that formulation. But the relay document’s first-stage summary says “no dial before OK,” which reverses the relationship between dialing and the success response.

I would replace that shorthand with two independent invariants:

**No dial before successful admission.**

**No application byte forwarding before OK.**

A formal relay state machine should distinguish internal `AuthAccepted` from wire-level `OkSent`. Otherwise a test and an implementation can appear to follow the same requirement while enforcing different orderings.

The destination side is equally valuable: authorize and validate a parsed destination, then pass the validated numeric address to the dialer. Your conformance requirements already call for this, including mixed public/private DNS answers and rebinding cases. Lean could check that the decision pipeline never discards the validated address and reintroduces an unchecked hostname.

### C. Empty declaration fields do not share one meaning

The declaration document’s general presence rule describes `[]` as nothing to check. Its individual fields have materially different semantics:

| Field                         | Meaning of an empty list                                        |
| ----------------------------- | --------------------------------------------------------------- |
| Inbound listeners             | No answering listener is declared, so any listener is a finding |
| Outbound restrictions         | No outbound restriction is declared                             |
| Required services             | No service obligation is declared                               |
| Permitted tenant key material | No tenant key material is declared permissible                  |

A generic “empty means success” implementation would therefore be wrong. The field-specific definitions are what matter.

I would represent **presence** separately from **meaning**:

```text
Missing       → schema error
Unspecified   → delivery blocked
Specified(x)  → evaluate x using this field’s semantics
```

Then use distinct types for inbound policy, outbound policy, service obligations, and permitted key material.

A JSON schema and ordinary Rust tests can handle much of this initially. Lean becomes more valuable when proving that declaration validation composes correctly with delivery and handoff—for example, that no path reaches `Delivered` while a required field remains unspecified.

### D. Attest single-use needs a durable consumed state

The browser must accept only the first valid introduction, and acceptance must remain single-use even though the sender credential remains readable from vendor metadata. Your design correctly places the enforcement in the browser rather than relying on relay behavior.

The corresponding formal obligation should include restarts:

```text
Introduction accepted and committed
→ restart
→ re-derive recipient key
→ receive another valid introduction
→ refuse it
```

Re-deriving a key must not recreate an open acceptance window.

I would explicitly journal the pin together with the consumed introduction state, its machine identity, and its applicable window. Acceptance should become externally usable only after the required durable commit.

Your general journal rules provide the basis for this. Making the specific transition explicit would eliminate an easy implementation gap between “stop listening now” and “never accept again after recovery.”

## 4. Where Lean could improve the larger security argument

### Exposure accounting should measure reach, not only distinct counts

Your spec already separates configured weights, proxies, and requested providers, and warns against blending those layers into one score. The exposure ledger also records historical model access rather than only the current assignment.

A useful extension is to formalize the **set of machines each domain can affect**.

For example, both of these configurations have three distinct model domains across five machines:

```text
Configuration A: 3 + 1 + 1 machines per domain
Configuration B: 2 + 2 + 1 machines per domain
```

For a 3-of-5 threshold, one domain reaches the threshold in A but not in B. The distinct-domain count alone does not capture the relevant property.

For a chosen layer, define:

$$
R(d) = \{\text{current members exposed to domain }d\}
$$

The single-domain bound is:

$$
\forall d,\quad |R(d)| < k
$$

Lean could prove that the counting implementation computes that relationship correctly, preserves relevant historical exposure, and does not treat an unknown past as an empty history.

But **the meaning of the domain labels remains an assumption**. A theorem about configured models cannot prove that an inference service actually served distinct weights. Your specification already makes that limitation explicit, and the formalization should preserve it.

The vendor quorum constraint belongs in the btc-policy tenant layer, as your profile already specifies, not as a universal harness invariant.

### Formalize the provenance of evidence

I would also distinguish types such as:

```text
ModelProposal
MachineReportedObservation
HarnessCapturedObservation
OperatorApproval
AdmittedHostPin
```

Your `ARC-43` change already moves in this direction: artifact hashes and installed host keys come from captured output of harness-composed jobs, not from model text.

Lean could establish that a model’s claimed hash never substitutes for the required job result, or that a notification claiming completion cannot advance a protected lifecycle state.

However, a harness-captured response from a root-controlled machine is still a response from that machine. **Authenticating the source and preserving the observation’s provenance does not establish that its contents describe an honest installation.**

That distinction should be visible in the types and theorem statements.

## 5. How I would connect Lean to the Rust project

There are three materially different levels of assurance.

### Level 1: a proved executable specification

Add a small Lean package to `tau-web-spec`, initially covering allocation and effect-dispatch policy.

The package should define executable decisions and transitions, then prove their properties. Keep explanatory Markdown and stable requirement identifiers.

A coverage record should connect:

```text
Requirement
↔ formal definition
↔ theorem
↔ explicit assumptions
↔ implementation module
↔ conformance tests
```

Do not describe a requirement as fully covered when a theorem addresses only one of its clauses.

The main benefit at this level is a more precise specification. **It does not yet prove the Rust implementation correct.**

### Level 2: Rust checked against the executable model

In `tau-web-rust`, separate the pure decision logic from the browser and network integrations.

The architecture I would aim for is:

```text
Typed input
    ↓
Pure policy/state-transition core
    ↓
Proposed durable events
    ↓
Persistence and commit acknowledgement
    ↓
Effect authorization
    ↓
Browser / SSH / TLS / vendor adapters
```

The persistence boundary is essential. A reducer returning an effect and a journal event in the same result is not sufficient if the caller can execute the effect before the event is durable.

Run generated event sequences against both the Lean model and Rust core. Compare accepted and rejected operations, state transitions, recovery classifications, and emitted effect permissions.

Include storage failures, missing responses, stale grants, restored metadata, and worker restarts—not just successful provisioning traces.

This provides strong regression evidence, but differential testing is still testing, not a refinement proof.

### Level 3: prove selected Rust logic against the model

Aeneas is a relevant later option. Its toolchain uses Charon to translate Rust into an intermediate representation, then produces functional definitions suitable for Lean proofs. Its documented target remains a subset of safe Rust, with concurrency and unsafe-code support still under development. External dependencies may require hand-written models. ([GitHub][2])

That makes your future pure allocator, authorization checks, and replay classifier much better candidates than the whole asynchronous browser application.

The eventual objective would be:

```text
Actual Rust core
→ translated definitions
→ proof that their behavior refines the Lean specification
```

Pin the Rust source, extraction toolchain, Lean dependencies, and specification revision together. Review any external models as assumptions.

Even then, the proof scope must distinguish the extracted logic from the compiler, browser bindings, storage implementation, and effectful adapters. I would not start by trying to put the complete PWA through this pipeline.

## 6. What I would deliberately leave outside the first formalization

**Do not attempt to prove arbitrary AI-generated shell commands converge.** Your briefs are adaptive instructions, not fixed programs. Model the harness rules for dispatching and recovering those commands, and test actual installation behavior separately.

**Do not turn a model of credential placement into a claim that root cannot recover secrets.** Your security model correctly acknowledges that a tenant secret placed on a machine is reachable by a model with root. Exact-value redaction protects specific delivery paths, not all possible information flows.

**Do not treat Lean as remote attestation.** A proof of the harness’s pin-admission logic does not prove the vendor is honest, the model left no backdoor, the package signer is uncompromised, or the browser received the intended application bundle. Those remain named trust dependencies in your design.

**Do not replace empirical acceptance gates.** Cloud first-boot behavior, phone interruption handling, actual SSH refusal, and the tenant’s lockdown declaration still need implementation evidence. In particular, the open declaration/checklist work and integrated recovery tests remain necessary even with a correct formal model.

I would preserve `SEC-2`’s prohibition on presenting deployed machines as verified. Documentation can accurately say “these source-level policy properties have machine-checked proofs” without changing the product’s remote-machine security claim.

## 7. Keep the proof project honest

The main risk is not that Lean accepts a wrong proof. It is that you prove the wrong statement, omit an important transition, or assume away the boundary you intended to examine.

For example, defining a valid transition as “a transition that preserves all invariants” makes the preservation theorem nearly useless. The formal model should implement the actual admission rules, state updates, and failure handling, then prove that they establish the desired invariant.

Likewise, a system that refuses every operation is safe in many narrow senses. Include successful execution examples and useful progress properties under explicit environmental assumptions. Availability should not be silently assumed merely to make a safety proof convenient.

For CI, I would require a pinned Lean toolchain, explicit coverage, and an audit of transitive axiom dependencies. A passing build alone is not an adequate completeness check: Lean supports `sorry`, whose underlying axiom can prove anything, and `#print axioms` exposes such dependencies. Current documentation also makes compiler-backed reasoning through `native_decide` separately auditable. Decide explicitly which proof dependencies the project accepts. ([Lean Language][3])

For AI-assisted proof development, the important review question is:

> Did the proof become complete because the implementation was corrected, or because the theorem became weaker?

Changing an assumption or narrowing a theorem should receive the same attention as changing a security requirement.

## 8. The adoption plan I would choose

### First: allocation and crash-safe dispatch

Start with the allocator because it has a compact state space and an immediate security consequence. Then connect it to the durable-intent and dispatch model.

The initial acceptance cases should include failed persistence producing no external effect, committed reservations remaining consumed after crashes, restored seeds refusing new allocations, exhaustion refusing wraparound, and uncertain destructive operations remaining blocked even when a caller proposes a new request ID.

Keep this scope small enough that the model is reviewed alongside the implementation rather than becoming a parallel research project.

### Next: use the model in implementation conformance

Build the Rust core with the same explicit identities, authority objects, and uncertainty states. Add differential and crash-injection tests mapped to your existing `CNF-*` identifiers.

Formalize the relay and pin-admission state machines as their first-stage implementations land. Correct the session-versus-machine terminology, relay-order shorthand, and declaration empty-list semantics before those interpretations become embedded in code.

### Later: selective implementation proofs and tenant composition

Once the pure Rust modules stabilize, evaluate extraction and refinement proofs for those modules. Add attest recovery, Replace, exposure history, and tenant quorum composition when their corresponding features are being built.

The success criterion should be **fewer ambiguous contracts, stronger regression tests, and proved behavior of specific implementation components**—not the number of Lean files or the percentage of prose translated.

---

## Bottom line

**Tau-web is a good candidate for selective formalization because its most important guarantees are about who may do what, with which identity, after which durable events.**

I would begin with **credential allocation and crash-safe effect authorization**, then extend to relay admission and lifecycle rules. Keep Lean beside the specification, keep the production application in Rust, and progressively strengthen the connection between them.

The most valuable outcome is not “tau-web is verified.” It is a much narrower and more defensible statement:

> **The modeled policy cannot reuse an allocation identity, authorize an operation against the wrong binding, or silently redispatch an unresolved destructive action—and the implementation is continuously checked against those exact rules.**

[1]: https://lean-lang.org/doc/reference/latest/Introduction/ "Introduction"
[2]: https://github.com/AeneasVerif/aeneas "GitHub - AeneasVerif/aeneas: A verification toolchain for Rust programs · GitHub"
[3]: https://lean-lang.org/doc/reference/latest/Axioms/ "Axioms"

