# A tenant's runtime obligations belong to its machines

The harness runs only while the operator's browser is open. So **any obligation a tenant must
meet while it is closed has to be met on the machine, by the tenant's own software, without a
harness credential.** The harness provisions and operates; it does not serve.

This is a constraint on what can be a tenant, and it is stated as one because it is easier to
discover here than to discover after building.

We chose this because the alternative is a machine that acts on its own initiative, which is
the arrangement [ADR-0003](./0003-the-ai-runs-only-in-the-browser.md) exists to prevent, and
because [ADR-0010](./0010-members-reach-each-other-on-one-authenticated-port.md) already
settled the identical question for the other tenant. There, routing member traffic through
the operator's device was rejected in one sentence: *a vault that also cannot operate while
the app is closed is not a vault.* The same sentence rewrites for any tenant with a runtime.

## What it means for the first tenant

lnrent sells servers, and a buyer who pays at 03:14 cannot wait for the seller to wake up. As
implemented today the daemon answers that buyer by creating a cloud VPS with a vendor token it
holds — which is the arrangement `SEC-3` forbids, and which is why tau-web replaces that path
rather than automating it.

Under this decision the resolution is that **the operator's machine is the capacity being
sold.** The daemon rents slices of the hardware it runs on. Fulfilment is local, needs no
cloud-plane action and no browser, and the daemon never needs a vendor credential because it
never provisions off-machine. `SEC-3` then holds by construction rather than by policy.

This also repairs an argument [ADR-0018](./0018-first-stage-is-one-lnrent-box-on-dedicated.md)
was making without the architecture to support it. It justifies dedicated hardware as "the best
value per unit of capacity for rental," which is only true if the dedicated box **is** the
capacity. A box that merely hosts a control plane brokering VPSs elsewhere gets no benefit from
being good value per unit of capacity. The claim and the design now agree.

**Whether lnrent takes that shape is lnrent's decision, not this one.** What this record fixes
is the harness side: a tenant needing fulfilment while the operator sleeps must put it on the
machine, and the harness will not supply a credential that lets the machine reach off it.

## Considered options

**Queue the obligation until the operator opens the app.** Requires no change to anything and
is honest about the constraint, which is this design's habit elsewhere. Rejected because it
does not survive the scenario: a buyer who paid for a two-hour server and receives it eleven
hours later did not buy a server, and no marketplace survives that. The same objection sinks any
tenant with a real-time obligation.

**Give the tenant's software a narrow, capped credential** — one vendor, spend-limited,
create-only — so it can provision on demand with bounded damage. This is the tempting answer and
it deserves recording, because the cap is real: `ARC-5` already names narrow credentials as the
operator's genuine lever. Rejected because the cap is a vendor feature the harness can neither
create nor verify, and because a credential-holding daemon on a machine the model has root on is
a credential the model can read (`SEC-6`). Bounding the damage is not the same as not creating
the actor, and `ADR-0003` is about the actor.

**Let the harness hold a background worker that acts on the tenant's behalf.** Rejected because
it is a hosted orchestrator with extra steps, and the absence of one is the product.

## Amended: an obligation may be delegated, and a selling machine holds no spending authority

The body above offers a tenant two dispositions — meet the obligation on the machine, or accept
that the harness is not a fit. There is a third, and it is the one that makes a selling machine
safe: **discharge the obligation at a third party the operator chose, which notifies the
machine.**

This matters because following the original rule to its end produces a bad place. A machine that
sells slices hosts strangers. A machine that takes payment for those slices holds payment
credentials, because receiving is a runtime obligation and the body above puts those on the
machine. So the two rules together put a hot wallet on a box running untrusted guest code, and a
single container escape takes the operator's money.

**The resolution is removal, not isolation** (`ARC-37`). A multi-tenant machine holds no
spendable key material:

- **On-chain**, it holds an extended *public* key. It derives a fresh receive address per order
  and observes settlement, and it cannot spend. An escaped guest finds nothing worth taking.
- **Lightning cannot be watch-only** — receiving requires an online node holding channel state
  and signing — so it is delegated to a receiving service that notifies the machine.

Stated as removal on purpose: a boundary between a stranger and a hot wallet has to hold every
time, while a machine with no spending authority has nothing for a boundary to protect. It is
the move `SEC-13` already makes for the app and `ARC-30` for inference credits, applied to a
machine that sells.

The delegation has an honest price and it is named rather than absorbed: the receiving service
is an elective trusted party (`TRU-E9`), it sees the payment flow, and it custodies value
between receipt and sweep. That exposure is bounded by sweep frequency and by the operator's
choice of service, and it is far smaller than the one it replaces.

## Consequences

**Not every project can be a tenant, and that is now sayable in advance.** A project whose value
depends on responding to the outside world while the operator is away must either put that
response on the machine with no off-machine credential, or accept that it is not a fit. Checking
this early is cheaper than discovering it during a first stage.

**The machine may become multi-tenant, and "locked down" has to absorb that.** If a machine sells
slices of itself, it hosts parties the operator has never met. `ARC-17`'s deliverable and the
per-vendor checklist behind `OPN-14` were written for a single-purpose box, and a box with hostile
local guests is a different hardening problem. This is a real cost of the decision and it is named
rather than discovered.

**The network posture needed a tenant-shaped answer, and has one.** `SEC-T1`'s
deny-everything-but-one-port is btc-policy's rule and binds only there. `ARC-39` supplies the
general form: the tenant declares its intended listening surface and the checks measure against
that declaration, so undeclared surface is the finding rather than open ports as such.

**The harness's own claim is unchanged.** It still provisions, hardens, and re-enters. What it
does not do is stay awake, and this record makes that a property tenants design around rather
than a gap they discover.
