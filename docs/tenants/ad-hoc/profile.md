# ad-hoc — the built-in profile for a machine with no tenant

Owned by the publisher and shipped in the bundle. Records: this file. Briefs supplied: none;
a machine here is steered by the operator's goal (`ARC-11a`).
Profile revision: 3 (2026-10-06).

Schema: ADR-0030. Every machine runs under a profile, and this is the one a machine with no
tenant runs under (`ARC-44`). Its access model is fixed below; its other per-machine slots carry
no preset: the operator fills them by answering the harness's own questions, and each answer is journaled with the machine before
anything is installed. Rules that only make sense inside a profile are that profile's;
everything cited below is the harness's.

## Access model

Maintained (`ARC-27`). The machine is re-entered by a later session bound to it. Sealing is not
offered here: it needs a tenant whose own design calls for it.

## Machine class

Asked per machine, never preset (`ARC-36a`). The operator answers the harness's questions with
nothing preselected, and "not sure" is multi-tenant.

## Vendor products targeted

Any. A vendor with a typed adapter is used through it. A vendor with none is reached through an
untyped vendor scope, on `SEC-4`'s conditions, and no further than `CHN-12b` lets an untyped
call go.

## Machine set

The session's bound set (`SEC-1`): one machine by default, and a larger set where the operator
accepts that weaker mode. Nothing is created as an atomic set.

## Independence bound

None declared. There is no quorum here, so no independence relation binds, and the rules keyed
on a declared bound — one machine per session (`SEC-1`), no goal (`ARC-11a`), no untyped vendor
scope (`SEC-4`) — do not apply to a machine under this profile.

## Delivery declaration

Per machine (`ARC-39`). The minimum below is signed content shipped in the bundle, and it is
where every proposal starts. From the operator's goal the model proposes what to add — what the
installed software listens on, what must be running, where an operator's application connects —
as typed values under `ARC-39`, whose measuring procedures remain the harness's,
and the operator approves the result in plain language; the approved declaration is journaled
with the machine and is the one in force. An unspecified field blocks delivery; an explicit
empty set does not. The minimum's structured v1 form is complete in
[`docs/design/delivery-declaration-v1.md`](../../design/delivery-declaration-v1.md).

### Network policy

The minimum: sshd on port 22 with key-only authentication, and no other listener. Outbound: an
explicit empty set of restrictions, not an unspecified field. A listener the operator approves
for a machine, and the outbound destinations of an operator's application (`ARC-1a`), are that
machine's journaled declaration, not profile content.

### Service lifecycle

The minimum: none — the profile ships no software of its own, so the declared set is empty
rather than unspecified. A proposal states what must be running, an application's always-on
service among it.

### Permitted key material

The minimum: no tenant key material. The scope of `key_material` is defined in
[`delivery-declaration-v1.md`](../../design/delivery-declaration-v1.md); the separately
classified application secrets in `SEC-5` row 12 use `place_secret`. What the harness itself
places is expected: the machine's own SSH host keys, generated at install (`CHN-R1`), and the machine's own client
public key in `authorized_keys` (`SEC-1`). No proposal and no amendment declares spendable key
material on a machine whose class is multi-tenant (`ARC-37`).

### Drift checks

The explicit empty set, or entries drawn from the signed bundle. A check the model writes is a
report under `ARC-39`, with `SEC-2`'s label, and is never one of these.

### Required software and checks

No default credentials. Required checks are the explicit empty set, or entries drawn from the
signed bundle, on the same rule as drift checks.

## Secrets and parties

An application secret reaches a machine through `place_secret` and no other way (`ARC-43`,
`SEC-5` row 12). Where the operator installs an application with a model of its own, that
model's provider is an elective party (`TRU-E12`).

## Runtime obligations

None of the profile's. An operator's application answers on its own machine, with its own
credential and no harness credential (`ARC-35`, `ARC-1a`).

## Post-harness handoff

None.
