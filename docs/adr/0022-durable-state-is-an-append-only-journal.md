# Durable state is an append-only journal in origin-private storage

State that must survive lives in an **append-only event journal** in the browser's
origin-private file system, written by a **single harness worker**, with in-memory state
authoritative only while that worker runs. A canonical event is appended durably *before* it
is applied. A side-effecting call has a durable record before it executes. After a crash the
worker replays, classifies what was in flight, and resumes only what policy permits.

We chose this because [ADR-0003](./0003-the-ai-runs-only-in-the-browser.md) accepts that
nothing runs while the app is closed, which makes "the app was closed mid-operation" the
normal case rather than an error. A phone locks, iOS suspends the tab, the worker is killed,
and a machine is halfway through an install. Everything else in this design depends on being
able to say what happened.

**This was specified in detail and then stranded.** The archived execution-layer
specification carries the whole model — the journal, the single writer, commit-before-effect,
the crash-recovery procedure, and a per-tool retry-safety type. But `00-overview.md` declares that
document superseded, so four current rules ended up depending on machinery they could not
cite, and two of them restated its invariants in fresh prose rather than pointing at them.
This record states the model in current terms so the archive can go back to being prior art
that is mined rather than authority that is cited.

## What is decided

- **A single writer.** Only the harness worker assigns durable sequence numbers or mutates
  canonical state. Tabs, command workers and adapters submit observations and requests.
- **Append before apply.** If the append fails, the transition does not occur.
- **Intent before effect.** A side-effecting call has a durable record, an approval decision
  and an idempotency identity before execution begins.
- **Origin-private storage, not a key-value store.** Content-addressed, with periodic compact
  snapshots and garbage collection only after a committed snapshot proves chunks unreachable.
- **Per-tool retry safety**, declared rather than inferred: pure, idempotent with a key
  strategy, reconcile-before-retry, or never-retry-automatically.
- **Uncertainty is a state, not an error.** A call that may have produced an external effect
  but has no terminal event requires evidence or operator inspection to leave that state. It
  is never retried automatically and no timer clears it. Establishing *what happened* by a
  status query is permitted and required where a tool supports one; doing it *again* is not.

## Considered options

**A key-value store keyed by entity, mutated in place.** The obvious browser answer, and
simpler to write. Rejected because it cannot answer "what was in flight when we died" — the
question the whole design turns on. Mutation in place destroys exactly the evidence recovery
needs, and bolting a write-ahead log onto it reinvents the journal with worse ergonomics.

**Snapshots only, no event log.** Cheaper, and adequate for state that can be recomputed.
Rejected because provisioning state cannot be recomputed: the machines are real, the money is
spent, and the vendor is the only other party who knows.

**Optimistic retry on reconnect**, replaying whatever did not complete. Rejected outright, and
it is the failure this record most exists to prevent. The caller is a model that retries on
its own initiative, so an automatic replay of an uncertain provider mutation is how one
approved machine becomes two billed machines.

**Multi-tab writers with a lock protocol.** Rejected as complexity without a use case: the
product is one operator on one phone, and concurrency lives in sessions inside one worker
rather than across tabs.

## Consequences

**The journal records what was sent, not what happened at the other end.** This is the honest
limit and it lands entirely on the box plane. Arbitrary shell on a remote machine cannot
declare itself idempotent, so its only honest retry safety is never-automatic, and its
recovery path is to reconnect, read the machine's state and converge — which makes
convergence a **brief-authoring rule** rather than a subsystem. A declarative distribution
([ADR-0018](./0018-first-stage-is-one-lnrent-box-on-dedicated.md)'s Alpine and NixOS) makes
that rule nearly free, since a system whose state is described rather than accumulated is one
a returning session can converge on rather than reconstruct.

For a *long-running* remote command — a build, a disk write — convergence is not enough on its
own, because the returning session cannot cheaply tell "still running" from "died halfway."
The amendment below closes that.

**Recording becomes cheap enough to be mandatory.** Box-plane execution is command-granular
rather than a byte stream, so the durable write happens once per command rather than once per
write. The alternative reading of "every byte recorded before transmission" would have put a
durable commit in front of every keystroke-equivalent on a phone, and the two differ by orders
of magnitude in cost for the same guarantee.

**The recording invariant and this record are the same rule at two layers.** One is about
off-machine calls and the operator's exposure; the other is about durability and replay. They
must not drift, which is why each now points at the other rather than restating it.

**Encrypted at rest is a property of this store, not an exception to a rule.** The client
keys, the relay token, the host-key pins and the exposure ledger persist here because ongoing
operation cannot survive a restart without them. The credential inventory names them with
their lifetimes; this record says where they physically live.

## Amended: the machine keeps its own record, and it is advisory

The consequence above left one thing open — the returning session cannot tell a still-running
command from a dead one — and named a durable remote job record as the answer without designing
it. `STA-20` and `STA-21` now do.

**Every box-plane command is a job, uniformly.** The machine writes, to persistent disk, the
command **as received**, its output, its exit code once it has one, and enough to tell whether
the process is alive. On reconnect the session reads that instead of guessing.

Uniformity is the point rather than an excess. The alternative is marking which commands are
long, and nobody can predict that — a package install is seconds most days and minutes when a
mirror struggles — so the mispredicted command is exactly the one that outlives its session.
Removing the prediction removes the failure, and `ARC-7`'s round trip per command already
dominates the cost.

**Recording the command, not only the result, buys a cross-check nobody asked for.** The browser
journal holds what was sent, written before transmission; the machine holds what it received.
Comparing them catches truncation, quoting damage and mangled multi-line input. It catches
nothing against a hostile machine, which writes whatever it likes, so it stands where the
deterministic verifier stands and is reported as no more than that.

### Considered options

**A terminal multiplexer as the substrate.** The obvious tool for surviving a disconnect, and it
does that well — plus a developer can attach mid-install and watch, which is genuinely useful
during a by-hand rehearsal. Rejected as the *record* for two reasons that are decisive here. It
dies with the machine, taking every session and all scrollback, so after a reboot a returning
session learns nothing at all — and this design's own first stage crosses a reboot, from rescue
into the installed system. And it returns rendered scrollback rather than bytes: escape
sequences, hard-wrapped lines, and a bounded history that silently drops the start of long
output, which is a poor foundation for a transcript meant to reconcile against what was sent.
Exit status is also second-class there, needing `remain-on-exit` and pane polling rather than
`echo $?`.

**Hosting the wrapper inside a multiplexer is not the same choice, and is permitted.** The files
remain the record; the multiplexer only adds a live view. The two compose, and framing them as
alternatives was a mistake.

**A service-manager unit** — `systemd-run` with its status and journal capture — is the nicest
answer available, on one of the two declared distributions. The other uses a different init
system entirely, so adopting it would generalise from one distribution's shape. `setsid` plus a
file behaves identically on both.

**Convergence alone, closing the question as unnecessary.** Tempting because a declarative
distribution makes re-running cheap and its build lock makes a concurrent second run fail
cleanly rather than corrupt. Rejected because the other declared distribution has no equivalent
lock, so this too would generalise from one shape — and a still-running command re-run
concurrently is the corruption case the whole question exists for.
