# Findings — LNVPS's NIP-90 order path, live (`OPN-24`, probe phase A)

Date: 2026-10-09, 23:37 UTC. Script: `prototypes/lnvps-probe/phase-a.sh` (nak 0.17.4). One
kind-5999 job, never paid; no machine was created and nothing was spent. Code is cited at
`github.com/LNVPS/api` commit `8352f11`, still the repository's head that day. The keys were
generated for this run and are not recorded here.

**Verdict: LNVPS's job listener runs in production, and its order path is broken.** Within two
seconds of the job, the service key answered `processing` and then `error` with "IPv4 count 0
out of range (1-1)". No order exists afterwards. Until the vendor fixes the count, no machine
can be ordered over NIP-90.

## What was sent

A kind-5999 event with params `cpu` 1, `memory` 1024 (MB), `disk` 10 (GB), `ssh_key` (a fresh
Ed25519 public key), `os` `archlinux`, `os_version` `Latest`, and a `p` tag for the service key
`fcd818454002a6c47a980393f0549ac6e629d28d5688114bb60d831b5c1832a7` — the key
`https://lnvps.net/.well-known/nostr.json` names for `_`. It was published to the four relays
of that key's NIP-65 list: `wss://nos.lol`, `wss://nostr.oxtr.dev`, `wss://relay.damus.io` and
`wss://relay.snort.social`. All four accepted it. A subscription for kind 7000 from the service
key, tagged to the requesting key, was open on the same four relays from eight seconds before
the publish.

## What came back

| After publish | Kind 7000 `status` | Extra |
|---|---|---|
| about 1 s | `processing` | — |
| about 2 s | `error` | `IPv4 count 0 out of range (1-1)` |

Both events verified (signature and id), were authored by the service key, and carried an `e`
tag for the job, a `p` tag for the requester, and an `expiration` 30 seconds after their
`created_at`. Then `GET https://api.lnvps.net/api/v1/vm`, NIP-98 signed by the requesting key —
which has no email address — returned `200` with `{"data":[]}`.

## Why

The handler builds its machine spec as `VmCustomTemplate { …, ..Default::default() }`
(`lnvps_api/src/dvm/lnvps.rs`), and the struct derives `Default`
(`lnvps_db/src/model.rs:1357`), so `ip4_count` and `ip6_count` are 0. `provision_custom` runs
`validate_custom_vm_spec`, which bails "IPv4 count {} out of range" for a count outside the
plan's range (`lnvps_api_common/src/pricing.rs:983`). The live custom plan sells exactly one
IPv4 and one IPv6 (`2026-10-08-lnvps-research.md` §4). The HTTP order defaults each count to 1
(`default_ip_count`, `lnvps_api/src/api/model.rs:836-843`), so only the job path fails. The
listener sends `processing` before provisioning and an `error` status when the handler fails
(`lnvps_api/src/dvm/mod.rs:84-122`).

## What this settles, and what it does not

- **The listener runs.** The research finding left open "Whether it listens in production, and
  on which relays"; it listens, and answers on the relays its key lists.
- **Absence of past feedback proves nothing.** Every feedback event expires after 30 seconds
  (`build_status_for_job`, `dvm/mod.rs`), so a relay that honours NIP-40 drops it; a search for
  past answers finds none whether or not the service ever answered.
- **The invoice would expire the same way.** A `payment-required` event carries the invoice in
  its `amount` tag and the same 30-second expiration, so a client must be subscribed when it
  arrives. Whether `GET /api/v1/vm/{id}/renew` returns an invoice for a job-created order is
  not observed: no such order exists.
- **Reads need no email.** A key with no address lists its machines; only the two HTTP order
  routes check verification (`routes.rs:1309`, `1447`).
- **The listener stops on a failed send.** `listen_for_jobs` returns on the first error from
  `send_event_builder` (the `?` after the error status), and jobs then go unanswered until the
  worker restarts. Read from the code, not observed.
- **Not observed:** anything after an order — payment, boot, the published host keys, the
  machine's addresses. Those wait for the vendor's fix.

## Reproduce

```sh
NAK=$(nix build --no-link --print-out-paths nixpkgs#nak)/bin/nak \
  bash prototypes/lnvps-probe/phase-a.sh
```

Keys go to `~/.config/tau-web/lnvps-probe/` and raw events to `/var/tmp/lnvps-probe/`; neither
is committed. Cost: nothing. A job that did create an order would leave it unpaid, and the
vendor deletes unpaid orders after an hour.
