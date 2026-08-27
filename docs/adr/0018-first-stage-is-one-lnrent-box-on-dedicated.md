# The first stage is one lnrent box on a dedicated server, over the full channel

The first thing built is a single dedicated machine running the lnrent daemon, provisioned
and hardened end to end by one session through the real channel: the session's SSH public
key registered with Robot, rescue activated with its fingerprint, and the reboot into it
triggered — three typed operations, since activation only configures the next boot and
`authorized_key` takes fingerprints of registered keys — the host key retrieved from the
rescue API and pinned with no
trust-on-first-use, the system installed from inside the trusted rescue session with
per-machine host keys generated there, box-plane hardening over SSH, the lockdown
demonstrated, and at least one later re-entry — because an lnrent box is a **maintained**
machine and the ongoing-operation story is part of what is being proven.

This replaces the first stage the design session chose and the specification carried: two
cloud machines configured entirely through boot-time user-data, no channel, demonstrating
provenance diversity.

## Why the replacement

**Dedicated is the only place the identity chain closes.** This is the argument that carries
the decision. Hetzner Cloud's rescue returns an action and a root password and **no host
key**, verified against the API client — route 2 of
[ADR-0015](./0015-the-browser-reaches-a-machine-over-pinned-ssh.md) is dead. Injection is
blocked behind the specification's `OPN-13`, and attest is designed but has never run. So on
Cloud today there is no way to obtain a host key without trusting first contact, and `OVR-4`
is satisfied nowhere.

On dedicated it closes at both hops: the rescue host key comes from the API before the first
connection, and the installed system's keys are generated inside that trusted rescue session
and read before reboot. **The "easy" path has the hardest identity story**, which inverts the
intuition and is the whole of why this stage looks backwards and is not.

The corollary is that Robot offers no pre-boot configuration at all — only `os`, `dist`,
`lang`, `keyboard` and `authorized_key`, verified against the API reference — so nothing can
be done to the machine except through the channel. That is a consequence of the choice rather
than a reason for it: it means the channel gates everything, which is a cost this stage
accepts rather than a benefit it seeks.

> **A superseded ranking, kept because it is re-derivable.** This record originally led with
> a different argument: pick the hardest path so that the WASM SSH client, the relay and the
> rescue flow — "the three things most likely to sink the plan" — fail in week one rather
> than month three. That ranking no longer holds. A deployed Rust browser SSH client exists
> on this exact target with a published configuration
> ([ADR-0024](./0024-the-ssh-client-is-rust-following-a-known-good-configuration.md)), and
> the relay has reusable references too. "Browser SSH is the scary part, front-load it" is
> what a fresh reader will conclude on their own, so it is worth saying plainly that it was
> concluded here, and was wrong. What was genuinely unknown, and still is, is what Robot's
> rescue endpoint returns — one authenticated call, which `STG-2` now gates construction on.

**The platform frame removed the old stage's reason to exist.** The two-machine demo
staged the vault thesis — visibly different provenance, the trust panel. Under
[ADR-0016](./0016-the-harness-isolates-and-counts-tenants-set-thresholds.md) the harness's
own claim needs no federation, and under the tenant economics the vault is the tenant whose
hardware this stage's dedicated server would be wrong for — while for lnrent, dedicated is
the best value per unit of capacity. (That argument only earns itself once the box **is** the
capacity being sold, which
[ADR-0023](./0023-a-tenants-runtime-obligations-belong-to-its-machines.md) settled; a box
merely hosting a control plane gains nothing from being good value per unit of capacity.) One stage, one tenant, correct hardware, a real user
at the end: an operator with a rentable box.

## Considered options

**Keep the two-cloud-machine stage.** Something visible in weeks and the provenance panel
gets built. Rejected because it proves the easy machinery while both hard problems wait,
and its demo argues a thesis the platform no longer leads with.

**Both in sequence, channel first.** Rejected as two stages before anything ships, with the
second's identity gap not closed by the first — dedicated retrieval does not transfer to
Cloud.

**The SSH spike alone, then decide.** Rejected because a spike is not a stage: nothing
usable exists at the end, and the spike is the first thing this stage does anyway — it
fails just as fast here, with a product attached if it passes.

## Consequences

**The gating set changes.** The WASM SSH client, the relay and its operation, client
authentication, and the contents of Robot's `host_key` field all gate the *first* stage
now. Cloud identity (route 2 dead; injection blocked; the certificate question) moves to
the second stage, with the vault tenant that needs it.

**Nothing is demonstrable until the channel works.** That is the point — fail-fast on the
most-likely-fatal item — but it must be said: this stage has no intermediate demo, and if
the spike fails, the fallback is the old cloud-first stage with the channel question
reopened.

**The boot-time-only escape hatch is gone for this stage.** The design record held out the
possibility that every step could be expressed as user-data and the channel would stop
gating provisioning. On Robot there is no user-data; the channel gates everything. The
question stays real for the *second* stage on Cloud.

**Some first-stage acceptance criteria do not survive.** Two vendors, two sessions,
collision display, and user-data byte-identity all belonged to the diversity demo. What
replaces them: the pinned-channel predicates, the recorded box-plane transcript matching
what was sent, the lockdown demonstration, one maintained-machine re-entry, a
binding-refusal predicate — channel access without the bound session's authorization
denied, because with
one machine nothing exercises the access rule by accident — and the same
credential and mobile-browser predicates as before — restated for a Robot credential and
an SSH client key.

**The vault is second, and loses nothing.** Federation formation was already
second-stage work waiting on the same channel; the trust panel and multi-session
concurrency arrive with the tenant that needs them.
