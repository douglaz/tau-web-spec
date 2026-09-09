# September 9 specification corrections

Review baseline: `383cca261cf6d44d3cf61f0589b489d42f755690`. These corrections address the
nine findings from the full-spec review, plus its stale-readiness note. They do not claim an
implemented harness or a new hardware rehearsal.

| Finding | Resolution |
|---|---|
| Installation disk erased by its alias mismatch | The install brief uses an explicit additional-disk set, canonical identity comparison, complete validation before writes and duplicate elimination. Resume no longer treats missing evidence as permission to wipe. |
| Remote jobs cannot persist through disk installation | `STA-20b` defines same-boot rescue records outside installation disks, collection into the browser journal before planned reset and unresolved handling after unexpected reboot. |
| Missing local unlock boundary | `STA-23`, credential inventory rows 18–20 and the v1 format define passphrase wrapping, data-key ownership and lock/restart behavior. |
| Lost derivation indices | `STA-22b` exports allocation mappings/counters/tombstones and prevents new allocation under an imported seed. Missing metadata has explicit vendor and relay outcomes. |
| Unspecified derivation paths | `STA-22a` and the v1 companion fix role-separated hardened paths, encodings and public known-answer fixtures. |
| Relay-private access | `CHN-16a` requires validation at registration and every dial, including DNS changes and self-address refusal. `CHN-11` retains an external management route for a self-hosted relay. |
| Alpine hash-only trust claim | `ARC-25a`, `TRU-E8a`, `STG-6` and ADR-0027 now name package signatures on both distributions; the bootstrap hash covers only the bootstrap. |
| Rescue diagram pins before boot | The diagram now resets, polls `/rescue/last`, pins, then connects. |
| Undefined first-stage acceptance subset | `07-conformance.md` assigns every CNF item to a stage, distinguishes fixture admission from live completion and makes `OPN-14` a completion prerequisite. |
| Stale next action | README, open questions and tasks acknowledge the completed installation rehearsal and identify construction plus tenant delivery inputs as next work. |

## Validation performed

- `python prototypes/spec-checks/check-install-disks.py --baseline` → **exit 1, expected**:
  the original block selects the root and an unselected disk for erasure. Every destructive
  command is stubbed; fake disk files stand in for devices.
- `python prototypes/spec-checks/check-install-disks.py` → **exit 0**: six cases cover root
  aliases, canonical root paths, duplicate aliases, empty selection, missing paths and
  non-block entries. Invalid selections produce no erasure calls.
- `uv run docs/design/check-credential-vectors.py` → **exit 0**: ten role/index vectors
  agree across stdlib/cryptography and bip-utils; a changed public-key fixture is rejected.
  These are public test secrets. This is not a test of an implemented browser key store.
- `git diff --check` → **exit 0**.
- Independent architecture, reliability and maintainability reviewers accepted the corrected
  specification. The reliability follow-up added the retained external management route;
  the documentation follow-up synchronized timeout wording and feature applicability.

## Still to build or demonstrate

`TASKS.md` records the remaining tenant declaration/checklist and briefs 2–3, integrated
credential storage/derivation, rescue interruption handling and later recovery implementation.
The changes make those obligations concrete; they do not mark their conformance boxes passed.
The corrected install commands have not been run on a real server. No server was contacted,
no deployment was performed and no vendor credential was used for these corrections.
