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

The password-posture read checks the effective OpenSSH password settings, comparing key
names without regard to case. It does not check root-specific SSH login policy. The read
needs root to read root-only host keys. A separate directive search refuses Match blocks and
Includes other than the main configuration's own standard drop-in glob: effective output
without a connection specification does not cover conditional Match blocks. The search
follows symlinked drop-ins, omits an absent drop-in path and always prints file names. An
unreadable directory or file, missing main configuration or dangling link remains a failed
read, even when other files produced matches.

Every local account password field must be nonempty and marked locked or disabled. Checking
only empty fields would miss a vendor-generated password hash. The field stays in the job
record; the finding names only the account. This deliberately does not try to distinguish an
operator-chosen hash from a vendor default. The route from LNVPS's default login user to root
remains a separate open requirement; locking a password used by that route could break it.

Inbound observation includes loopback-bound sockets. A local-only declaration is measured by
its binding; internet or peer reachability belongs to the outside scan. Unconnected UDP
sockets can be transient, so the read reports what it observes rather than promising that
the observed set is permanent.

Outbound restriction uses one fixed output-chain form, compared as printed JSON expressions,
with one rule per declared destination and no extra rules. Expression order is retained;
sets are compared without order and duplicate rules still count. The fixed exceptions are
loopback, established/related traffic and the selected IPv6 neighbour-discovery and
multicast-listener message types. These types are matched to any address; the check does not
constrain their destinations. Echo requests started by the machine get no blanket exception.

A namespace check on the chosen form retained peer-initiated IPv6 ping, related error replies
and multicast-listener reports while dropping a ping started by the restricted machine. It
used a direct veth pair, no router and addresses with duplicate-address detection disabled:
it establishes neither multicast-snooping switch behaviour nor operation on a fresh LNVPS
image. The fresh-image run and integrated evidence remain T42's work. Necessary DNS or time
service destinations depend on the actual declaration and are not inferred by the checklist.

An empty outbound list declares no restriction and runs no outbound read. A DNS-name host
is refused until a read can measure it. State and enablement reads accept the named
service-manager exit statuses and decide from stdout; inactive or missing units are answers,
not failures to run. Refused or undispatched reads and missing job records settle no verdict.
Service-name grammar, account scope and reboot evidence keep their existing owners.

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
evidence. Nonempty default-credential declarations wait for their own concrete read.
