# The lockdown checklist's fixed checks and reads

Decided 2026-10-25. `bundle/lockdown.toml` supplies the generic checklist under `OPN-14`,
including `ARC-36a`'s machine-class question and `ARC-39`'s declaration rendering. `ARC-17`
owns lockdown findings and `ARC-43` owns the harness-composed reads. This record explains
the choices; the checklist holds the commands and their verdicts.

## What was undecided

Stage 1 had a declaration shape and service-lifecycle evidence, but no concrete generic
lockdown checklist or listener and outbound-restriction reads. A delivery check could not
measure against an unspecified procedure. Vendor-specific lockdown remains separate.

## The shape chosen

The checklist's `sshd-password-off`, `sshd-no-match` and `no-account-password` entries own
the fixed checks, their reads and their verdicts. The LNVPS access decision is recorded in
the dated amendment below; the checklist remains vendor-neutral.

The checklist's `[read.listeners_inbound]` owns inbound observation and matching, including
local bindings and the distinction from the outside scan. Unconnected UDP sockets can be
transient; this is an observation, not evidence of a permanent set.

The checklist's `[read.listeners_outbound]` owns the fixed output-chain form, its comparison
and its exceptions.

A namespace check on the chosen form retained peer-initiated IPv6 ping, related error replies
and multicast-listener reports while dropping a ping started by the restricted machine. It
used a direct veth pair, no router and addresses with duplicate-address detection disabled:
it establishes neither multicast-snooping switch behaviour nor operation on a fresh LNVPS
image. The fresh-image run and integrated evidence remain T42's work. Necessary DNS or time
service destinations depend on the actual declaration and are not inferred by the checklist.

The checklist's `[read.service_state]`, `[read.service_enablement]`, `[read.linger]` and
`[read.boot_identity]` own those commands and accepted exit statuses. General read-failure
and unresolved-read behavior belongs to `ARC-43`. Declaration value grammar stays in
`docs/design/delivery-declaration-v1.md`; service-name grammar, account scope and reboot
evidence keep their existing owners.

## Alternatives considered

| Option | Disposition |
|---|---|
| Effective sshd output alone | Rejected: conditional Match settings and outside Includes can escape it. |
| Refuse only empty password fields | Rejected: a password hash is not marked locked or disabled. |
| Exclude loopback sockets | Rejected: local-only bindings would have no observation. |
| Interpret any firewall ruleset | Rejected: the read would need to prove arbitrary rule semantics. The fixed form is compared whole. |
| Omit IPv6 control messages | Rejected: the output drop policy blocks neighbour discovery. |
| Permit all ICMPv6 | Rejected: it also permits pings initiated by the machine. The chosen ND and MLD types preserve the measured participation traffic. |
| Resolve DNS names when loading the rules | Rejected: static addresses do not measure a name whose answers can change. |
| Defer outbound reads beyond stage 1 | Rejected: the stage-1 applicability row in `07-conformance.md` includes item 103 without that carve-out. |

## Consequences

The checklist is available for implementation; its existence is not evidence that a machine
passes it. T42 and `OPN-14` remain open for implementation, the fresh-image run and integrated
evidence. The declaration format owns admissible default-credential values.

## Dated amendment — persistent LNVPS root route, 2026-11-01

The selected choice is A. `STG-21` says "The harness MUST enter as `arch` over pin-checked SSH,
authenticated by the existing per-machine client key, and acquire root through password-free,
non-interactive sudo for each job." For persistence, privileged collection, model-free Replace
and admission after destructive reinstall, see that same owner. The choice keeps root access
usable alongside the generic password-locking checks, without a second credential.

`STA-20` says "A single journaled launcher MUST acquire any required privilege, create and use
the root-only installed-system directory and its own root-only job record, and only then begin
ordinary payload work." For startup and collection outcomes, see that same owner. The choice
preserves uncertainty where an elevation attempt may have run without producing a record.
This resolves the formerly open access requirement without changing terminal evidence or the
command hold.

| Alternative | Disposition |
|---|---|
| Password or interactive elevation | Rejected: the selected route works with locked or disabled password fields and fresh connections, without an elevation secret or prompt. |
| Direct-root login or an alternate-login fallback | Rejected by the selected access decision, independently of the credential inventory. |
| A separately dispatched untracked setup command | Rejected: it would act before the tracking it is supposed to establish; startup belongs to the single tracked launch. |

The phase-B finding establishes pin-checked `arch` login, not the image's sudo configuration
or a successful lockdown check. No installation mechanics or live-image result is decided by
this amendment. T42's fresh-image run and integrated evidence remain outstanding, including
startup and collection after reinstall. For downstream obligations, see `07-conformance.md`;
consistent specification gates do not satisfy them. `OPN-24`'s vendor target criteria remain
the qualification decision's home.
