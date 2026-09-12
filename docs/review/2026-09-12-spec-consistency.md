# September 12 consistency review

Review baseline: `7dac067`. Two independent readers reviewed the whole corpus for internal
consistency — topic files, glossary, summary, tasks, ADRs, tenant profiles, brief 1 and the
credential format. One reported 37 findings, the other 19; seven overlapped. Every finding
was checked against the text before it was acted on. Nothing here claims an implemented
harness or a new hardware run.

## Contradictions fixed

| Finding | Resolution |
|---|---|
| ADR-0011's Consequences and ADR-0015 still had the coordinator reaching inside every member over the pinned SSH channel, against `ARC-19a` | Both marked superseded in place: the coordinator holds no channel, runs after sealing, and reaches the vault port over the relay as plain TCP (ADR-0026). |
| ADR-0015 Route 1 had the activation `POST` publishing the host key and Robot browser-reachable; `CHN-R1` says neither | Superseded note pointing at `CHN-R1` as run on 2026-09-08 and the pinned tunnel (`CHN-12a`). |
| ADR-0028 said the sheet holds every maintained machine's keys, and that row 14 is the only unrevocable row | Sheet holds no machine key since ADR-0029; the seed is likewise unrevocable but its derived keys are removable. |
| `ARC-26` called the relay pass a bearer credential, which `CHN-15` retired | It is the derived relay key that a scanner must never hold. |
| The glossary's *runtime obligation* forbade any off-machine credential; lnrent's profile places one under `SEC-5` row 12 | Glossary now says no *harness* credential, matching `ARC-35`. |
| The ad-hoc profile's permitted key material excluded the SSH host keys its own access model needs | The profile now names what the harness itself places. |
| `CNF-69`, `CNF-71`, `CNF-78` assumed the aggregator; bring-your-own and local inference have none | Qualified to the procured path, in the items and in the applicability row. |
| `SEC-CLAIM` cited `OPN-4` as "may not be enforceable" while `OPN-4` said weights are enforceable by construction | Claim restated around configured weights; `OPN-4` closed on its own criterion. Service-as-requested stays `TRU-E2`'s trust. |
| `OVR-5` lets a profile relax the vendor default; ADR-0030's guard said a declaration never widens | Guard scoped to the delivery declaration; the independence bound is named as the one slot that relaxes a default, never past the tenant's bound. |
| `04` and ADR-0004 cited `ARC-19a` for the setup-time verifier rule it does not contain | Cite `ARC-26` (anything needing the channel belongs to the machine's own session). |
| `CHN-9`/`CHN-10` omitted the vendor tunnel and the post-harness credential's traffic that `ARC-19a` routes over the relay | Both enumerations complete. |
| Three files pinned "the relay by host key"; no rule pins the relay | Reworded to the machine pinned by host key. |

## Stale claims fixed

Executive summary status and gating list (rehearsal ran 2026-09-08; `OPN-1`, `OPN-6`,
`OPN-21` closed); "no code" in the overview and summary now says no harness code; `TRU-E7`
no longer says artifact pinning is unspecified; `CHN-3`, `CHN-R1`, `STG-3a`, ADR-0018 and
ADR-0024 no longer cite closed questions as open; ADR-0025's Consequences no longer describe a
pasted, stored token; the ADR-0020 and ADR-0027 rows in the overview's decision table match
the records' titles; `TASKS.md`'s applied history no longer states a thirteen-row inventory,
voucher expiry, "both browsers", "coordinator reach" or "member topology" as current;
`CNF-45`/`STG-15` say Android Chrome; the reading map lists `docs/tenants/`, `docs/briefs/`,
`docs/findings/` and marks the credential format normative; `08`'s SSH size figure
distinguishes module from application; the unlock-latency citation notes the WebView.

## Smaller fixes

`SEC-5` row 15 derives row 17; row 16 also authenticates the inbox subscription; row 5 gives
the rescue pin a one-boot lifetime; row 1 covers the pre-session recovery flow. `CNF-80` moved
out of the not-pass/fail measurements section. `CNF-32`'s first-stage reading is stated.
`OPN-18` closes on `CNF-40`, `CNF-55` and `CNF-86`, and the gating sentence says it is closed
by design. `OPN-8` no longer makes `OVR-5` hang on a CORS answer ADR-0017 made routing. The
relay-install brief is named in `OPN-10` as second-stage harness work. `STG-18` states that
no tenant secret is placed in the first stage, so lnrent's receiving credential waits on
`CNF-16`. `STG-2` cites ADR-0030 for brief ownership. ADR-0019 cites `SEC-10` by identifier.
`ARC-42` cites `SEC-12`'s probe rather than `ARC-33`. `ARC-16`'s state diagram uses mermaid's
start and end markers. `STG-10` names the session inference key. `00`'s "`CHN-R2` does not
exist" reads "is dead".

## Not applied, with reason

- `ARC-41`'s count of who reaches a machine through the relay was not widened for
  post-harness traffic: the penalty it describes is sshd's, and that traffic never touches sshd.
- ADR-0018's "three typed operations" enumerates exactly the three it names; `STG-3a`'s count
  was the one that undercounted, and it now says "every Robot call".
- `STA-17`'s "every other item in the flow has an issuer" stands: the seed is the origin of
  the flow's items, not one of them; ADR-0028 carried the overstatement and was corrected there.

## Validation performed

- `git diff --check` → exit 0.
- Every remaining `OPN-4` mention is a pointer to the closed entry or a historical note.
- No server was contacted, no vendor credential was used, and no prototype was re-run.
