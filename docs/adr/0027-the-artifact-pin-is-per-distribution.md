# The artifact pin is per distribution, and one of them adds a party

`ARC-25` requires the artifact source to be pinned and never trusted on retrieval. The
**expected value ships in the signed app bundle**, and the **mechanism differs by
distribution**: Alpine is pinned by content hash over the artifact itself; NixOS is pinned by a
revision, with the installed system admitted on a binary cache's signature against a key the
browser cannot replace. That key's holder is a trusted party, named in `TRU-E8a`.

## The problem this addresses

`ARC-25` was written as a single sentence — *"pinned by content hash supplied from the
browser"* — and read as if it applied uniformly to both distributions `ARC-24` names. Checked
against upstream source on 2026-09-04, it applies to one of them.

Alpine serves every release artifact with sibling checksum and signature files at the same
path, and its versioned release directories accumulate rather than being rewritten, so a
versioned URL plus a hash is exactly the mechanism `ARC-25` describes.

NixOS does not work that way and cannot be made to. Its installer fetches from a binary cache
and admits store paths on **signature**, against a public key baked into the installer's own
configuration with signature checking enabled by default. Nowhere in that path does an outside
party get to supply an expected hash of what is installed. A browser-supplied hash can cover the
installer image and nothing beyond it — and that image carries the *installer's* closure, not
the target's, so its overlap with the installed system is incidental and has no stated fraction.

**The requirement was therefore not merely vague on one path; it was false on it**, and it
claimed a control the design did not have. That is the failure mode `SEC-2` exists to forbid,
appearing in a requirement rather than in a report.

## Where the expected value comes from

Three origins were available and only one of them adds no party.

**The signed bundle** — chosen. The pin is worth exactly what the bundle is worth, and the
bundle is already the largest concentrated risk in the design (`TRU-A1`). Nothing is added.

**Fetched at provisioning time from the publisher.** Always current, no coupling to release
cadence. Rejected because it is not a pin but a lookup: `TRU-E7`, the software signer, would
quietly acquire the same blast radius as `TRU-E8`, and the corpus would hold two parties who
decide what every machine runs with only one of them written down. Buying freshness with an
unnamed party is the trade `SEC-10` prices as a schema migration.

**Operator-supplied.** Rejected on the grounds `ARC-32` already states about this audience: the
target operator will not verify a hash on a phone, and sourcing one is strictly harder than
checking one.

**The cost of the chosen option is an outage, and it is accepted rather than mitigated.** The
hash moves at upstream's tempo and the bundle at the publisher's, so between an upstream release
and the release that carries its hash, provisioning **halts**. Alpine's v3.23 branch took six
point releases in about six and a half months — irregular, security-driven — so the window
recurs on that order, and its length is the publisher's release latency, not upstream's. The
halt is the design working: the only alternative is accepting whatever the source serves today.
What follows is an obligation, recorded in `ARC-25`: the publisher must track upstream releases
and re-pin, and a stale pin is an outage rather than a degradation.

## Considered options for the NixOS half

**Drop NixOS, keep one distribution and one mechanism.** `ARC-25` would then be true as
written, with no second party and nothing to explain. Rejected because NixOS is the half that
repays `ARC-10`: [ADR-0022](./0022-durable-state-is-an-append-only-journal.md) records that only
NixOS of the two is declarative, so a reconnecting session can converge on a described state
rather than reconstruct an accumulated one. Losing a working capability to preserve a
one-sentence uniformity is the wrong trade, and the uniformity was never real — it was an
unchecked claim.

**Install from a prebuilt closure.** Upstream's installer accepts a prebuilt closure rather than
building one, so a single artifact could carry a browser-supplied hash and the pin would be
genuinely uniform. Rejected because somebody must build and host that closure, and that somebody
is the publisher — a new party with bundle-scale reach over every machine, acquired to avoid
naming an existing one. It also requires build infrastructure the project does not have, and
upstream documents the ingredients without an end-to-end procedure, so it would be a path this
design maintains alone.

**Pin the flake revision and call it content addressing.** A flake lock records each input's
revision and tree hash, which fixes the derivation graph. Rejected as a *description*, kept as a
*practice*: ordinary derivation outputs are input-addressed and content-addressed derivations
are still experimental, so the store paths that arrive from the cache are admitted on signature
regardless. A pinned revision buys a reproducible build in principle. It does not convert cache
trust into hash trust, and describing it as if it did would restate the original error in newer
words.

## Consequences

**`TRU-E8a` is a new row in the elective tier**, and it is elective in the only sense that
matters: it follows from choosing that distribution, and choosing the other avoids it. The party
was already relied upon before this record; what changes is that it is written down.

**The two distributions no longer make the same claim, and the first stage must say which it
ran.** `STG-6` requires it. Without that, a completed stage cannot state afterwards which of the
two trust roots it actually demonstrated.

**A moving alias is a conformance failure even while it passes.** `CNF-66` fails a
`latest`-shaped URL or a rewritten-in-place metadata file whether or not the hash matches today,
because such a pin admits substituted bits on the next upstream release — the bundle-scale
substitution arriving through the control meant to detect it.

**`ARC-24`'s comparison argument weakens on one path and survives on both.** Two machines built
from the same pinned revision is still a stronger statement than two machines that ran the same
brief. It is a statement about the build, not a hash of the installed system, and it is written
that way now.

**The pinned installer image keeps a job, just not the advertised one.** The installer passes
its own store as trusted, so paths already present in the image are copied without a signature
check. Pinning it bounds the unsigned-admission surface. That is a smaller claim than `ARC-25`
appeared to make and a real one.
