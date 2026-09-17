# The specification and the implementation are separate repositories, pinned by commit

This repository, `douglaz/tau-web-spec`, holds the specification and never the harness code.
The implementation lives in `douglaz/tau-web-rust`, which vendors this one at an exact commit
under `spec/` and compiles the publisher-chosen inputs under `bundle/`, the tenant profiles and
the briefs into the served build. Decided 2026-09-15; the repositories were named and created
2026-09-16.

## Why

The corpus says of a dozen things that they "ship in the signed bundle": briefs (`ARC-11`),
the artifact pin (`ARC-25`), accepted signers (`ARC-25a`), model choice (`ARC-31`), tenant
profiles (ADR-0030). Every one of them is a value a reviewer of *this* repository must see,
because `TRU-A1` and `ARC-40` name the publisher's authority over them and an unnamed power is
what `05-trust.md` exists to prevent. Keeping the values here keeps that authority visible in
one place; keeping the code elsewhere keeps this repository readable as a specification, which
is what its reviewers read it as.

## How the boundary works

- **Pinned by commit.** The implementation repository carries this one as a git submodule or
  subtree at an exact commit. Its build refuses to run if the checked-out tree does not match
  the pin. "Compiled into the build" means "from spec commit X", and every release records X.
- **Inputs live here.** `bundle/` holds the artifact pin and signer list, the inference target,
  the timing values and the CORS probe; `docs/tenants/` and `docs/briefs/` hold profiles and
  briefs. A key rotation, a model change or a new minirootfs is a commit here and a pin bump
  there.
- **Checks live here, gates live there.** `bundle/cors-probe.sh` and `prototypes/spec-checks/`
  are the facts this repository records; the implementation's CI runs them from the pinned
  tree, and the build-failing form of `CNF-4` is that CI's.
- **"Signed bundle"** means, until `OPN-15` closes, compiled into the build the origin serves
  and verifiable against `ARC-32`'s published hash (glossary).
- **Witness files are checks, not inputs** (ADR-0032, 2026-09-16). The formal companion's
  witness files under `docs/design/` are read by the implementation's tests from the pinned
  tree, never compiled in, and no Lean enters the implementation's toolchain. A stale pin is a
  release fact — "conformant to spec commit X" — not a warning the build raises.

## Considered options

**One repository holding spec and code**, so the bundle ships one tree. Rejected by the
publisher: the specification's readers and the code's are different, and a spec that shares a
tree with a build acquires the build's churn in its history.

**Tagged releases of the spec** fetched and hash-checked by the build. Rejected: a release
ceremony on a repository that has no builds, buying nothing a commit pin does not.

**Copy by hand at each release.** Rejected: the drift the corpus has already paid for twice
(`00-overview.md`, "two renumberings").

## Consequences

`00-overview.md` says the repository holds no harness code and never will. `ARC-32` points
here for where the served build comes from. `CNF-4`'s build gate is named as the
implementation's. TASKS T29 creates the implementation repository with the pin.
