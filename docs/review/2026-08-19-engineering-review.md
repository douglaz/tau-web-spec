# Engineering review, 2026-08-19

An architecture, code-quality, test and performance review of the whole corpus at commit
`726ad44`, followed by an independent second-opinion pass. Twenty-one findings, all
resolved into decisions.

**Nothing here has been applied.** The specification, the glossary, the summary and the
twenty-one decision records are unchanged. This document states what the review found and
what was decided; [`TASKS.md`](../../TASKS.md) states the work that follows. Where a
decision below contradicts current text in `spec.md` or an ADR, the current text is what
still ships, and the task list says how it changes.

This is a record, not a maintained document. Once its tasks are done it is history, in the
same standing as [`docs/design/`](../design/).

## Why this review found what earlier ones did not

Three reviewer rounds preceded this one, against bases `349f369` and `68c5961`. They found
108 findings between them and the corpus is materially better for it. But their budget went
overwhelmingly to **propagation and consistency** — the same fact stated in four documents,
drifting — and to re-verifying every numbered cross-reference after two renumberings.

Two structural facts explain most of what they could not reach:

- **The corpus was reviewed against itself.** Every round read `spec.md`, the summary, the
  glossary and the ADRs, and checked them for internal agreement. None read the sources
  those documents depend on. The single most serious finding below came from reading the
  *tenant's* repository, and the second came from reading the archived execution-layer
  specification the current documents had stopped citing.
- **Rules are identified by position in a list.** "Invariant 5" means whatever is fifth
  today. That is why renumbering keeps consuming review budget, and it is why this review
  recommends stable identifiers.

## What was verified externally

Stated with provenance, in the discipline the specification already applies to the Robot
and Cloud findings.

- **Browser-resident SSH over a WebSocket-to-TCP bridge is shipping in production**, in at
  least five independent implementations, including Tailscale's SSH Console (a full
  userspace network stack and SSH client compiled to WebAssembly) and Google's WASSH in
  Secure Shell. Every one is written in Go against `x/crypto/ssh`. The open item on the
  Rust candidate is its WebAssembly target, which is a library-selection risk rather than
  an architectural unknown. Verified by search, 2026-08-19.
- **The lnrent daemon, as implemented today, requires a DigitalOcean API token at runtime**
  (`DO_TOKEN`), and creates and destroys machines itself through recipe hooks. Only
  DigitalOcean is implemented; the README lists Hetzner and bring-your-own-host as not yet
  delivered. Its Fedimint mnemonic is a bootstrap input rather than a runtime one, and the
  README explicitly advises against placing it in the run environment. Verified against the
  lnrent README, 2026-08-19.

  **This describes the proof of concept tau-web replaces, not a defect in this design.**
  Under the replacement, the harness holds the vendor credential in the browser and
  provisions through typed operations; the daemon holds no cloud credential, and lnrent's
  current provisioning scripts move into the harness. Recording it because the contradiction
  is real against the *current* lnrent, and anyone comparing the two repositories will hit
  it.

## The decisions

### The AI is a trusted party by default

The harness's posture is that the model is the operator's agent: it holds a root shell, it
can read what is on the machine, and that is ordinary. Two invariants were written as
absolutes that root already defeats:

- **"The AI MUST NOT touch key material"** is achievable only where a tenant designs the
  whole procedure for it — descriptors supplied by the operator, member keys generated on
  the machine, and sealing that removes the model before anything valuable exists. That is
  btc-policy's arrangement, not the harness's, and the rule belongs with the tenant
  invariants.
- **"A machine never holds a vendor API token"** scopes to *the harness's* cloud plane. A
  tenant's own credential, on the tenant's own machine, is a different thing and is counted
  rather than forbidden.

For everything else the honest verb is **minimize**, not avoid: deliver redacted, keep out
of model context, prefer on-machine generation, prefer sealing — and count whatever remains
reachable in the blast radius, exactly as an approved untyped scope is counted. The
specification already states the consequence correctly ("a compromised one owns the machine
it just configured"); the absolutes were what stood out of step.

### The access invariant needs a lock, not bookkeeping

One SSH client keypair currently serves every machine. Every reference in the corpus is
singular, and the recovery flow confirms it: "a new client key, the old key removed from
**every maintained machine** during re-entry."

So no machine and no relay can distinguish one session from another, and the rule that a
session touches exactly one machine is enforced only by the harness's own routing code.
The first stage's eighth predicate asks for more than that — it exists to show the refusal
is "enforced by mechanism rather than satisfied by scarcity" — and with a shared key it can
only ever demonstrate the harness declining to call its own transport.

**One keypair per machine.** Only that session's public key reaches that machine's
`authorized_keys`, so a wrong-machine connection fails inside SSH rather than inside an
`if`. Keypairs are free, the rescue session already installs one, and revocation is already
per-machine. The coordinator's reach during setup becomes a stated credential fact rather
than an unstated exemption.

### The state model gets a decision record

Persistence, journaling, crash recovery and per-tool replay safety are specified in detail
— in the archived execution-layer specification, which the current documents declare
superseded. Four current rules depend on that machinery and none can cite anything current,
which is why the recording invariant ended up restating two of the archive's invariants in
fresh prose.

**ADR-0022 states it directly**, in current terms: where durable state lives, the
append-only journal, the single-writer worker, commit-before-side-effect, crash recovery,
and per-tool retry safety. The archive returns to being prior art that is mined, not
authority that is cited.

The genuinely open part is narrower than it looked and lands entirely on the box plane. A
journal records what was sent over the channel; it cannot record what the machine did with
it. Arbitrary shell cannot declare itself idempotent, so its honest retry policy is never,
and its recovery path is **reconnect, read the machine, converge**. That is a rule for
whoever writes briefs rather than a missing subsystem, and the declarative distributions
chosen below make it nearly free.

### Credentials are enumerated, not prohibited with exceptions

The credential invariant is a ban with a list of things it does not apply to. The list has
grown three times, each addition made after a review found the rule already being broken,
with a fourth pending behind the injection question. Eleven credential classes are actually
in play.

**Inverted into an inventory**: every credential the harness touches, with where it lives,
how long, what it authorizes, and how it dies. Anything without a row is forbidden. A new
class cannot be introduced without noticing, which is precisely the failure that produced
all three existing exceptions.

The inventory gains an entry for an **operator-supplied tenant secret** delivered to a
machine: redacted by value from the transcript in the same way the rescue root password
already is, kept out of model context on delivery, and counted in the blast radius —
because a model with root can read it afterwards, and pretending otherwise would be the
overstatement this design refuses everywhere else.

### Content-Security-Policy has more than one directive

Resolving `connect-src` to permissive was right: bring-your-own and self-hosted relays make
the origin a configured value, and a frozen list cannot hold one. But that conclusion was
generalized into "the policy is not the security boundary," which silently discarded
`script-src`, `object-src` and `base-uri`.

Those bind a case the scope model cannot: **injected code never calls the approval path.**
Approval and recording are functions inside the bundle, and code that was never meant to run
does not invoke them. The bundle is already named as the largest concentrated risk, with no
reproducible builds and no watchdogs today, so discarding its cheapest mitigation as a side
effect of a decision about a different directive is the one CSP change worth making.
`connect-src` stays permissive; the rest stay strict.

### The rescue path is forced, and it names a party nobody counted

The install runs from inside a rescue session for two reasons, neither of which the corpus
states: the rescue endpoint is what publishes the host key, and **Alpine and NixOS are the
chosen distributions and neither is offered by the vendor's automatic installer.** Custom
image installation is therefore mandatory on this path rather than the optimisation the
delivery record calls it.

That makes the **artifact source** — an image, a mirror, a channel — a party that decides
what every machine runs, and it appears in no trust tier. The design session solved this and
the answer never moved forward: the rescue session pulls from a URL while the browser
supplies the expected hash, which makes the source an untrusted dependency pinned by
content hash. It is the same shape as the relay pinned by host key and the bundle pinned by
published hash, and it is the third instance of a pattern already in use.

A declarative distribution also repays the convergence rule above, and strengthens the
observation that two machines running the same image hash is a stronger statement than two
machines that ran the same brief.

### Smaller resolutions

- **The untyped-call tunnel needs a TLS client with its own bundled root store**, because
  browsers do not expose theirs. That is a trust decision about roughly 150 certificate
  authorities and a revocation problem the design would own, sitting directly in a credential
  path — a different and harder thing than pinning one known host key. Marked
  designed-but-unpriced rather than settled routing. No first-stage work touches it.
- **The exposure ledger's staleness rules bind only a tenant that is both maintained and
  threshold-bearing**, and none exists: btc-policy seals, so its ledger is complete when
  setup ends; maintained tenants have no threshold, so nothing depends on the count. An
  unfinished setup is **device-bound** — resume where it started or abandon — which follows
  from all-or-nothing plus exposure ending with the machine, and needs no new mechanism.
- **The relay learns member topology**, not merely connection metadata. Which operator,
  which destination, when, accumulated, is the member set. The surface-pentest record already
  prices that same knowledge as a named trust row for the scanner. The Certificate
  Transparency rejection survives and reads stronger stated honestly: one chosen party learns
  the topology, against everyone learning it permanently in a public log.
- **Attest posts once and then scrubs its voucher**, with the ordering unstated. A transient
  first-boot network failure therefore costs the machine, on the only out-of-band
  introduction route the cloud path has. Retry with backoff until acknowledged or a deadline
  passes; scrub on whichever comes first; keep the deadline inside the voucher's expiry.
- **Remote box-plane execution is command-granular**, and recording commits per command
  before transmission. "Every byte recorded before transmission" implied a granularity
  nobody had chosen, resting on an execution model nobody had stated, and the two plausible
  readings differ by orders of magnitude in cost.
- **Amendments append for additions and rewrite the body for reversals.** Three layers of
  correction accumulated on one mechanism, leaving the opening description stating the
  opposite of the decision. Superseded reasoning is carried forward only where the old
  approach is one a fresh reader would arrive at independently, and then as a rejected
  option with its reason rather than as narration.

## What the first stage must demonstrate, revised

Three predicates are added and one is raised.

- A box-plane command cannot reach the harness's cloud plane, even when the model tries.
- A typed operation naming a machine the calling session is not bound to is refused by the
  adapter.
- A brief or feed cannot be substituted at runtime.
- Box-plane output claiming authority does not receive it.
- A session cannot authenticate to a machine it is not bound to.
- A brief interrupted mid-run and re-run from the top converges rather than duplicating.
- **Raised:** "the daemon running and reachable" demonstrates the installer, not the tenant.

Of the thirteen harness invariants, three had a predicate that would catch a violation and
one had half of one. The six above close every gap the first stage can exercise; the
remainder are honestly second-stage or not mechanically testable.

Two measurements are also required, neither pass/fail: **peak memory of one session during
a full install**, on both mobile browsers, and the wall-clock duration of that install. The
concurrency decision rests on five sessions sharing a phone, chosen against an acknowledged
high memory risk, and no number has ever been taken. The first stage runs exactly one
session, which makes it the only cheap opportunity to learn whether five is possible.

## Construction gates on a rehearsal

Running the first stage by hand, once, against a disposable dedicated server, moves from
recommendation to prerequisite. It settles in an afternoon what the corpus otherwise
discovers over weeks: what the rescue endpoint's host-key field actually returns, whether
the automatic installer returns anything comparable, whether the ceremony works end to end,
and what the three first briefs actually need to say. The item the plan names as most likely
to fail is substantially de-risked by the implementations listed above; the item that is
genuinely unanswered costs one authenticated call.

## What this review did not settle

- Whether the first stage is end to end **for the target operator**. It assumes an existing
  vendor account, an already-rented server, a webservice user, funded inference and a relay
  token obtained out of band. A developer can pass every predicate while a phone-only
  operator still cannot begin.
- The claim that "if the maximal path works, the rest is subsetting." Dedicated rescue
  demonstrates none of attestation, boot-time configuration, recovery-sheet handling,
  second-vendor reachability, concurrent sessions, federation formation or threshold
  isolation. Those are orthogonal systems, and the claim should be narrowed to what it
  actually covers.
- A durable remote job record, so a reconnecting session can learn whether a long-running
  command finished rather than inferring it. Declarative system state reduces this problem
  substantially without removing it.
- Transcript retention and compaction on a device that keeps them for the life of a
  maintained machine.
