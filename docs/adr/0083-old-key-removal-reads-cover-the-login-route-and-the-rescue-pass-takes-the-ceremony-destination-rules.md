# Old-key removal reads cover the login route, and the rescue pass takes the ceremony's destination rules: an owner-directed amendment

Decided 2026-11-10 on the owner's instruction ("Adopt it", row by row), after a review panel in
two rounds. The counts and the owner's picks are `tw-74f` comment 262000001 (rows 05 with 07, and
row 17). This is an owner-directed amendment. It closes two retained boundaries and narrows the
rescue removal permission by name (below). `STA-17` owns pending removals, the rescue rekey and
Replace's limits statement; `CHN-16` owns destination records; `CNF-20` and `CNF-117` own the
cases.

## What was undecided

Each quote is the text as it stood before this change (commit `120951e`).

- **Row 05, what an absence read covers.** One journal act ends a pending removal once "a
  harness-composed read of the machine's authorized keys" shows the key absent, and `STA-17` said
  "Which accounts, files or other authorization sources that read covers is not decided". A read
  of one file could end the removal while the key still authorized a login through another source
  sshd honours for the account the harness enters as, and revocation would then read complete.
- **Row 07, how the rescue removal ends.** The rescue rekey removes the identified old key after
  the installed-system login and the readback, but `STA-17` said "How this rescue removal's
  confirmation and ending relate to the ordinary pending-removal journal act and absent-key read
  above is not decided". Nothing kept that removal on the sheet, so a Restore could lose it, and
  nothing stopped the job's own report from being read as its confirmation.
- **Row 17, the rescue rekey's relay pass.** The flow needs a pass under its fresh seed, but
  `STA-17` said "How the flow obtains that pass and records its destinations is not decided", and
  `CHN-16` said its source and approval rules "decide nothing for the rescue rekey". A host
  recorded on that pass with no source read or structured approval would widen it on the shared
  any-port terms unchecked.

## The shape chosen

- **Row 05, coverage.** The read ends a pending removal only when its captured output establishes,
  for each account on the machine's login route, every authorization source the machine's sshd
  honours for that account by its effective configuration, and shows the key absent from each.
  The route's accounts are those the harness enters the machine as over SSH, `arch` at LNVPS
  (`STG-21`); an account reached only by elevation is not one. A read that cannot establish those sources, cannot read one it lists, or meets
  one it cannot enumerate (a key command, a condition it cannot evaluate) ends nothing, and the
  removal stays pending until a covering read or the deletion-evidence act. The core is five of
  five in round one; the login route's accounts only is four of five, with the required reader in
  the majority. The deletion-evidence ending is unchanged.
- **Row 05, the limits statement.** Replace's existing limits statement also names the accounts on
  each machine's login route as the scope of an old key's revocation by an absence read,
  and claims nothing about any other account. No new completion state is added. Four of four in
  round two.
- **Row 07, an ordinary pending removal.** Before the rescue removal job is sent, one durable
  journal act does what Replace's migration act does for a migrated machine: it ends the
  retired-seed entry naming the key as an entry that stands for the machine, and keeps the key as
  a pending removal at that entry's seed and index, linked to the machine at `b`. Only a covering
  read or the deletion-evidence act ends it; the job's own result ends nothing. Replace and
  revocation stay reported incomplete across restart, export and Restore, and a Restore removes
  nothing. Five of five in round one, as the ordinary act. The credential format already carries
  it: its pending removal is "the old key of a machine since migrated", and the rescue rekey is
  that machine's migration to `b`.
- **Row 07, a key no retired-seed entry names.** It is not removed, no entry, seed or index is
  invented for it, and revocation is reported incomplete; having no pending removal for it never
  reads as complete. Three of four in round two, with the required reader in the majority.
- **Row 17, the ceremony's rules on the fresh-seed pass.** `CHN-16`'s source, journal,
  structured-approval and durable-record rules govern the rescue rekey's pass, allocated only after
  the fresh seed's ceremony record: Robot's build-named host recorded before the flow's first
  tunneled Robot call; the server host only from a read of `/boot/{n}/rescue/last` the grant
  already permits, whose response echoes the entry's server number, journaled before any dial;
  then an approval of that concrete addition. No call and no dial before a recorded destination,
  and the flow's card approves no destination. Five of five in round one. How the flow obtains
  the pass stays not decided.
- **Row 17, the address source.** The panel checked whether the rescue grant includes a read
  carrying the server's address (262000001). The committed rehearsal capture of
  `GET /boot/{n}/rescue/last` (`docs/findings/2026-09-08-first-stage-rehearsal/rescue-last.json`)
  carries `server_number` and `server_ip`: one observation of the vendor's response, not integrated
  harness evidence. That read is already in the grant, so no grant is widened. Where a response
  lacks the matching number, `CHN-16`'s source rule leaves no admissible host and the flow dials
  nothing.

## What this amends and narrows

- **Closed, by name (row 05):** the retained boundary recorded in `tw-4mz` comment 212000001, N2A:
  "Document beside the ordinary pending-removal read that its account/file/authorization-source
  coverage is not decided" and "This selects no source inventory, edited-path substitute or
  absence proof". The read's coverage is now the login route's sshd sources, named by the
  machine's own configuration; no path or inventory is fixed.
- **Closed, by name (row 07):** the retained boundary in the same comment, N3aA: "Add no
  absence-read, later-connection reread, retired-seed identity, removal record, export carriage or
  new completion rule". The rescue removal now has the ordinary removal record, its export
  carriage and its read. No reread on every connection is added.
- **Narrowed, by name (row 07):** the rescue removal permission. `STA-17`'s "removes only the exact
  old client public key that checked retained machine records for the same authorized machine
  identify" now also requires a retired-seed entry that names the key.
- **Amended, by name (row 17):** the destinations half of `STA-17`'s open point on the pass, and
  `CHN-16`'s "They decide nothing for the rescue rekey". The rescue rekey takes the ordinary
  ceremony's rules; `ADR-0079`'s advance approval stays `ARC-15`'s setup screen's alone.
- Nothing is widened.

## What stays

- Row 06: whether another hard-link name still shows the key after a removal stays not decided.
- Row 18: how the flow ties the credential it calls under to the entry's account reference stays
  not decided. `tw-kx8` is not reopened.
- How the flow obtains its pass stays not decided, and no pass-procurement or recording wire,
  address refresh or export rule is chosen.
- Whether any history reaches the removal is not established here. The card is refused where
  another entry's admitted mapping equals the server number ([Protected browser evidence v1
  §3a](../design/protected-evidence-v1.md#3a-protected-operation-evidence)), and `STA-17` says
  "This opens no route for a server an entry already holds", so a retired-seed entry naming the
  identified key may never stand beside an approved card. Where none does, nothing is removed
  and revocation stays reported incomplete, which is the narrowing's fail-safe side; no rule is
  added for it.
- A pending removal linked to an entry the wrong-server record bars stays pending, as `ADR-0081`
  records; this change adds no refusal for it.
- Accounts off the login route are outside the read; the limits statement says so rather than
  claiming them.
- `SEC-4`'s rescue grant is unchanged.
- The formal companion: nothing there models removals or the rescue pass, and `TauWeb.Relay` is
  unchanged. No theorem, gate or assumption boundary moves (five of five in round one), and no
  witness changes.

## Alternatives considered

| Option | Disposition |
|---|---|
| Leave each point open | The retained boundaries, now amended by the owner's "Adopt it". |
| Row 05: the read covers only a recorded target file | Not selected (five of five for the sources sshd honours). It needs a new record, and a key elsewhere on the route would read as revoked. |
| Row 05: cover root too, or every account | Not selected (four of five for the login route's accounts). It widens the duty beyond the route. |
| Row 05: a separate revocation report naming its scope, or no new wording | Not selected (four of four for naming the scope in the existing limits statement, with no new completion state). |
| Row 07: the rescue removal confirmed by its own read, with no record | Not selected (five of five for the ordinary act). Nothing would carry it across a Restore. |
| Row 07: remove a key no retired-seed entry names, through a new format member | Not selected (three of four for leaving it untouched). |
| Row 07: leave that case not decided, or treat it as unable to occur | Not selected. No text guarantees a seed and index for every key the flow identifies, and an open case could yield a false completion claim. |
| Row 17: the rescue card approves the destinations | Not selected (five of five). The card comes before the pass and the address exist. |
| Row 17: widen the rescue grant with a new address read | Not needed. The granted `/boot/{n}/rescue/last` read carries the number and the address. |
