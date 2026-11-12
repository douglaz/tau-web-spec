# A lone plain swap area is not a possible root: an owner-directed amendment

Decided 2026-11-11 on the owner's instruction ("Step past lone swap"), after a review panel in two
rounds. The counts and the owner's pick are `tw-0vq` comment 279000001. This is an owner-directed
amendment. It widens recovery eligibility by name, against ADR-0082, and narrows one open reading
by name (below). `STA-17` owns the rescue rekey's plain-layout probe; `CNF-117` owns the cases.

## What was undecided

The quotes are the text as it stood before this change (commit `32d1f75`).

`STA-17` said "A probe resolves only when its reads succeed and establish one of three results:
one file system whose label reads in `STG-20`'s form, one file system with no such label, or
definitely no file-system signature", and "A read error, a partial read, empty output, more than
one signature or a signature the job does not recognise leaves the probe unresolved, which is the
root-label stop". A swap area is neither a file system nor a volume layer, and no requirement named
one. Whether a lone swap signature was "definitely no file-system signature", so resolved, or "a
signature" outside the three results, so the stop, was open: two conforming jobs could differ, and
no `CNF-117` (p) run told them apart. The panel found the text open (three of four in round one).

The cost of the open text was on the safe side: no reading wrote a key where it should not, and
the loss was eligibility only (four of four in round one). A realistic way in is a leftover swap on
a disk the install did not select, since the probe covers every partition on the server's disks
and the install erases only the selected disks. A server that took the stop "gets no rescue rekey
from the harness, and nothing here grants a reinstall or an erasure to repair it".

## The shape chosen

- **A lone plain swap resolves.** A probe whose reads succeed and establish exactly one plain swap
  signature, and nothing else, resolves as not a root, whatever label it carries. The captured
  output lists the device with that result, and the job writes nothing to it. A swap label in
  `STG-20`'s form never counts as a root whose label reads in that form (four of four in round one).
- **Swap with anything else stops.** A swap signature beside any other signature on the same device
  is more than one signature, and leaves the probe unresolved (four of four in round two).
- **A swap area holding a saved hibernation image stops.** It is not a plain swap area, so its
  probe stays unresolved, and the reset never boots an installed system that could resume an image
  over the root the key was written to (four of four in round two).
- **Every other signature that is neither a file system's nor a volume layer's stays unresolved.**
  ADR-0082 recorded this ("Anything else is the root-label stop"); `STA-17` now says it outright.
- **One swap case in `CNF-117` (p):** a server with one in-form root beside a lone plain swap
  partition, unlabelled and with an in-form label, each in its own run. A swap case tells the two
  readings apart (four of four in round two).

Round two split two to two on the rule itself (resolve a lone plain swap, against stop on any swap)
and the split survived, so it went to the owner, who picked the bounded resolve rule.

## What this widens and narrows

- **Widened, by name:** recovery eligibility, against ADR-0082's "Nothing is widened" and its
  "Anything else is the root-label stop". A server whose only device besides its root is a plain
  swap area can now take the rescue rekey, where under the stop reading it could not.
- **Narrowed, by name:** a signature that is neither a file system's, a volume layer's nor a plain
  swap area's. Today's text was open on such a signature as well; the rule now says it leaves the
  probe unresolved, so a job that read one as "definitely no file-system signature" no longer
  conforms. The third result now reads "definitely no file-system or other signature" to say so.
- **Decided, by name:** `STA-17` left "whether the job writes anything else to that root's disk"
  not decided. For a lone plain swap device on that disk it is now decided: the job writes nothing
  to it. The rest of that open point stays.
- The mixed swap-and-file-system run and the hibernation-image run were each suggested by one
  reader and not voted. They go beyond the one swap case the owner picked, so `CNF-117` (p) does
  not add them; the rule covers both.

## What stays

- Which probe tool a job uses and which swap forms it knows are not fixed. A swap form the job does
  not recognise is "a signature the job does not recognise" and stops. The install brief's `blkid`
  outcomes stay that brief's, not this job's rule (ADR-0082).
- The three earlier results, the BIOS-boot run in `CNF-117` (p), the volume-layer exclusion and
  rows 13 and 14's open points.
- `CNF-117` (p)'s run of "a partition whose probe finds more than one file-system signature" is
  unchanged; the panel noted it is narrower than `STA-17`'s "more than one signature", and a
  swap-plus-file-system run was not voted.
- No journal field, export member or change to `STG-20`'s label form.
- The formal companion: no theorem, gate, witness or assumption boundary moves (three of four in
  round one); the companion does not model the probe.

## Alternatives considered

| Option | Disposition |
|---|---|
| Leave it open | Not chosen. Both behaviours kept conforming, and no run told them apart. |
| Stop on any swap signature | Not chosen by the owner after the two-to-two split. It would keep ADR-0082's "Anything else is the root-label stop" and accept the eligibility loss. |
| Resolve every swap area, a hibernation image included | Not offered: a resumed image could overwrite the root the key was written to. |
