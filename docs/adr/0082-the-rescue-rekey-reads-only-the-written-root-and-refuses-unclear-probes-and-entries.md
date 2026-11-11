# The rescue rekey reads only the written root and refuses unclear probes and entries: an owner-directed amendment

Decided 2026-11-10 on the owner's instruction ("Adopt it", row by row), after a review panel in
two rounds. The counts and the owner's picks are `tw-74f` comment 262000001 (rows 09, 15 and 26),
with the record correction in comment 264000001. This is an owner-directed amendment. It amends
two earlier recorded boundaries and narrows recovery eligibility by name (below). `STA-17` owns
the rescue rekey, its jobs and the scoped read; `ARC-43` owns `ready_to_reset`'s refusals;
`CNF-117` owns the cases.

## What was undecided

Each quote is the text as it stood before this change (commit `bcee94d`).

- **Row 09, which root the later host-key read uses.** Where `rescue_install_key` writes the new
  client key, `ready_to_reset` then reads the host keys at `/mnt` before the reset into the
  installed system. The text said what mounts a root there "is not decided", and `CNF-117` (l)
  said its fixtures "do not identify the fixed path's root with the root that received the client
  key". So a mount of another tree holding valid host keys that are not rescue's could pass every
  discovery check and be journaled as the installed pins. A later failed confirmation would not
  undo that admission: wrong-tree pins are a false result either way.
- **Row 15, which devices are possible roots and when a probe resolves.** The root-label stop
  fires when "a label probe it makes of a device it reads as a possible root does not resolve",
  but the text left "what makes a label probe resolve" not decided and did not say which devices
  are read as possible roots. An implementer could count a partial or ambiguous probe as "no
  label", or never probe some device, find "exactly one" labelled root on a server that has two,
  and write a key there.
- **Row 26, the scoped read's other entry types and parents.** After the root-label stop the
  scoped read refused as a whole only when an entry "is a symbolic link". A FIFO, device node or
  socket that yields one public key, or a key reached through a linked parent directory, could
  become the reset's expected next key.

## The shape chosen

- **Row 09, the written root's identity.** `rescue_install_key`'s captured output records the
  identity of the root it writes: the file system's UUID and the major and minor numbers of the
  device that carries it, under the rescue boot ID its job record carries. On that key-written
  path `ready_to_reset` refuses its entire read unless `/mnt` is the root directory of that file
  system on that device under the same boot ID. A missing or unestablished identity, a different
  file system or device, a directory below the right root and a changed boot ID are each that
  refusal. It is an `ARC-43` job refusal, so `STA-17`'s existing rule stops the migration
  unfinished and ends any grant still standing. The core is five of five in round one; the
  identity's form is three of four in round two, with the required reader in the majority.
- **Row 15, every plain-layout device, three definite results.** Where each root is one file
  system on one disk and no disk carries a volume layer, the job probes every partition, and every
  whole disk without a partition table, that the rescue kernel lists on the server's disks, and its
  captured output lists them with each result. A probe resolves only when its reads succeed and
  establish one labelled file system, one file system with no such label, or definitely no
  file-system signature, so a BIOS-boot partition whose probe establishes no signature is not a
  stop. Anything else is the root-label stop. Five of five in round one. Volume layers get no
  result here and stay with rows 13 and 14 (four of five, with the required reader in the
  majority); a server any of whose disks carries one is outside the layout.
- **Row 26, whole-read refusal.** The scoped read refuses as a whole when any entry it would read
  as an installed host public key is not a regular file, or anything on the path from its root to
  that entry, other than the entry itself, is a symbolic link or not a directory. The selection is
  evaluated before any exclusion, as the link rule already was; no such entry is opened, and a
  regular key beside such an entry supplies "no successful partial prerequisite result". Five of
  five in round one. A missing parent needs no words (four of four in round two).

Rows 09 and 15 both add to `rescue_install_key`'s captured output. Row 09's refusal is named
among the discovery refusals that `ARC-43` and `STA-20b` disclose as Markdown-only. Row 15's is
the root-label stop, and row 26's belongs to the scoped read, which stays outside
`TauWeb.Dispatch.offersReset`.

## What this amends and narrows

- **Amended, by name (row 09):** the boundary recorded in `tw-4mz` comments 163000001 ("no
  sentence naming the root is added"), 201000001 ("No new mount job, rule, identity check, reset
  guard, reader waiver or conformance case"; "no root-identity clause") and 204000001, M5 ("No
  behavioral narrowing or widening, same-root identity clause, mount actor, reset guard,
  interrupted-write guarantee or conformance case"). The identity check and its conformance case
  are added. No mount actor or arrangement, unmount duty on refusal or reset waiver is chosen, and
  what mounts `/mnt` stays not decided.
- **Narrowed, by name (row 09):** recovery eligibility. A key-written flow whose later read is not
  of the written root now stops unfinished.
- **Amended, by name (row 15):** `STA-17`'s "what makes a label probe resolve" is decided for
  the plain layout and stays not decided outside it.
- **Narrowed, by name (row 15):** `STA-15`'s "On Robot the ceremony always works". Its sheet
  exception already points at `STA-17`'s sentence that opens "So with no sheet", which names "a
  possible root whose label probe does not resolve". That set now includes every probe that ends in
  a read error, a partial read, empty output, more than one signature or an unknown signature, so
  more servers without a sheet get no rescue rekey. `STA-15`'s own text is unchanged. `CNF-117`
  (p)'s quote of the open point is replaced in the same edit.
- **Amended, by name (row 26):** the scope retention in `tw-4mz` comment 223000001: "No bundled
  note or new outcome for FIFO, device, socket, directory or linked parent components is needed
  for the symlink amendment".
- **Narrowed, by name (row 26):** recovery eligibility. A scoped read that meets such an entry or
  parent refuses, and the reset back is neither offered nor sent.
- Nothing is widened.

## What stays

- What mounts a root at `/mnt`, and when the job's read-write mount ends.
- Rows 13 and 14: what counts as one root outside the plain layout, under a volume layer or an
  assembled volume, and what the rescue boot writes while either job runs.
- The root-label stop and its pinned case of a device every read of which fails. The install
  brief's `blkid` outcomes stay that brief's, not this job's rule.
- The scoped read imports no `ready_to_reset` path, pattern or refusal. It stays journal-only
  (`SEC-5` row 5), with no-follow, no-private-key and file-scoped journaling.
- The formal companion: no theorem, gate or assumption boundary moves (five of five in round
  one), and no witness changes.

## Alternatives considered

| Option | Disposition |
|---|---|
| Leave each point open | The earlier recorded boundaries, now amended by the owner's "Adopt it". |
| Row 09: the root's label | Not selected: "A label that passes proves nothing". |
| Row 09: the file-system UUID alone | Not selected (three of four for the combined form). A copy of the file system with the same UUID on another device would pass. |
| Row 09: the device in the same rescue boot, plus the UUID or the root directory's inode | Not selected (three of four for the combined form). It did not require `/mnt` to be the file system's root directory, so with the UUID as the file part a directory below the right root would pass. |
| Row 09: withhold the offer until the root is identified, with no refusal | Not selected (five of five for the refusal core). |
| Row 15: adopt the install brief's `blkid` outcomes | Not selected. They belong to that brief. |
| Row 15: probe every kernel-exposed device and stop on any volume signature | Not selected (four of five). It would decide rows 13 and 14. |
| Row 26: skip a non-regular entry and keep sibling keys | Not selected (five of five for the whole-read refusal). It conflicts with the link rule's "no successful partial prerequisite result". |
| Row 26: refuse a missing parent too | Not selected (four of four in round two). It would refuse every server with a data or boot partition that lacks host keys. |
