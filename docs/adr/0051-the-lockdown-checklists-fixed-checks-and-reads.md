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
the fixed checks, their reads and their verdicts. The route from LNVPS's default login user
to root remains a separate open requirement; locking a password used by that route could
break it.

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
