# Bootstrap hashes and package signatures are separate admission steps

`ARC-25` and `ARC-25a` define the current artifact policy. The expected bootstrap URL/hash,
package repository policy and accepted signing keys ship in the signed bundle. Both Alpine
and NixOS depend on package signers for binaries fetched after the bootstrap image.

## Why the distinction changed

The initial decision treated Alpine's versioned release image as the installed system and
contrasted its hash with NixOS's signed cache. The September 8 install rehearsal showed the
missing step: the Alpine minirootfs is followed by `apk update` and installation of the kernel,
SSH server, bootloaders and dependencies from branch repositories. Those binaries are not
covered by the minirootfs hash. Alpine's branch indexes receive updates, as described in the
[upstream package handbook](https://docs.alpinelinux.org/user-handbook/0.1a/Working/apk.html).

The September 9 correction accepts and names this existing dependency. Alpine's branch,
repository URLs and accepted key set come from the bundle; signature checking remains on.
The transcript records index digests and package versions as observations. NixOS retains its
pinned source revision, installer hash and accepted binary-cache keys. Neither route presents
its installer hash as a hash of the resulting system. `TRU-E8a` covers both paths and `CNF-67`
requires rejecting unsigned packages and packages signed by an unaccepted key.

## Alternatives

**Pin the complete binary closure.** This could remove the package signer's ability to change
binaries after the bundle release. It requires constructing and distributing that closure or
an exhaustive immutable package manifest, with update/rehearsal infrastructure this project
does not yet have. It is a different installation design, not a property of the current brief.

**Fetch expected values during installation.** This lets whoever serves those values change
what is admitted. Rejected: expected pins belong in the signed bundle, whose existing
concentrated trust is `TRU-A1`.

**Call a branch or source revision a binary hash.** Rejected. Alpine's branch advances, and
NixOS's source revision fixes requested inputs while cache signatures admit outputs.

## Consequences

The trust display names the bootstrap hash and package signers separately. `STG-6` records
which policy ran. A bad bootstrap hash or package signature stops installation. New upstream
releases do not themselves break an older immutable URL; an unavailable, changed or withdrawn
artifact does. The publisher tracks releases and ships updated pins/policies in new bundles.

Choosing Alpine no longer claims to avoid `TRU-E8a`. Pinning an installer still bounds the
bits present before later signature checks, which is a useful and narrower claim.
