# Findings — LNVPS probe phase B: one paid machine, observed end to end (`OPN-24`)

Date: 2026-10-11, 04:07–06:30 UTC, run from a server in a Hetzner datacentre. One machine at
LNVPS: the smallest custom build (1 vCPU, 1 GiB, 10 GiB SSD, one IPv4, one IPv6), image 11
(`archlinux`, "Cloud", "Latest"), one month, paid over Lightning from the operator's wallet.
Two fresh Nostr keys, one per account, both verified to the same operator address. Scripts:
`prototypes/lnvps-probe/lnvps-req.sh` (every request signed explicitly by its key),
`phase-b-watch.sh` and `reinstall-watch.sh`. No machine identifier, address, host-key
fingerprint, payment hash or key is recorded here.

**Verdict: none of `OPN-24`'s target-failure conditions was observed.** The keys it publishes
equal, byte for byte and in all three families, the keys the machine presents, before and after
a reinstall; Arch boots, takes the operator's key on `arch`, and answers at its static address,
also after a reboot; a Lightning payment settled into a booted machine; the listing shows it.
The recorded costs are below.

## The sequence (`STG-21`)

| UTC | Event |
|---|---|
| 04:07:29 | the operator address set on both accounts (`PATCH /api/v1/account`); both read unverified |
| 04:11:17, 04:11:47 | each account read verified, after the operator opened its link (polled every 30 s) |
| 04:11:25 | HTTP order (`POST /api/v1/vm/custom-template`) on the first account: a machine status with no expiry and **no invoice** |
| 04:11:33 | `GET /api/v1/vm/{id}/renew?method=lightning&intervals=1`: **an invoice**, 7,033,000 msat plus 1,687,920 msat tax (24%), 10-minute expiry |
| 04:11:48–04:11:57 | paid from the operator's wallet: 8,721 sat plus 43 sat routing fee, settled |
| 04:11:50 | the vendor's recorded payment time (expiry set to one month later) |
| 04:12:10 | the guest's boot time, read later from `uptime -s` |
| ≤04:12:22 | status `running`, two addresses assigned (polled every 10 s from 04:12:22) |
| 05:12:21 | **first published host keys**, all three families (between 05:12:11 and 05:12:21) |

The order response carries no invoice; the renew route serves it. `ARC-30` says "the wallet
invoice MUST come over TLS from the vendor's recorded HTTP order or renew response". Of the 24% tax, the research finding's §4 says the
vendor sets VAT from a declared country "and/or … location evidence such as your IP address";
none was declared here.

**The key fill took one hour, as the code predicted.** sshd answered with all three families by
04:42 at the latest (a scan from the probe host, recorded but not trusted), and the vendor
published nothing until 05:12:21. The research finding (§1) reads `HOST_KEY_SCAN_RETRY_SECS` =
3600 and an attempt stamped before its scan, so a first scan that lands before sshd is up waits
an hour. The same happened after the reinstall below.

## The observations (`OPN-24` phase B, in its order)

1. **Fill:** about 60 minutes from `running` to a complete published set.
2. **Presented equals published:** each published key's full public key equals the key the
   machine presented, in every family, and each published fingerprint matches its key.
3. **Arch, the key, the address, cloud-init:** an SSH login as `arch`, with a known-hosts file
   built only from the published keys and strict checking, succeeded. `ID=arch`,
   `BUILD_ID=rolling`, kernel `7.2.6-arch2-1`; `cloud-init status` done with no errors, from a
   NoCloud seed. The address is **static**: cloud-init wrote a systemd-networkd file with
   `DHCP=no`, fixed IPv4 and IPv6 addresses and gateways; NetworkManager is not running. The
   user-data is the vendor's: hostname, the registered SSH key, `chpasswd` with no expiry, the
   default user, and **`package_upgrade: true`**, so the vendor upgrades every package at first
   boot. The vendor-data sets resolvers and `ssh_deletekeys: false`. Nothing of the buyer's beyond
   the key reached the machine. With strict checking and no known key, a login is refused.
4. **Reboot:** a reboot issued at 05:13:28 gave a new boot at 05:13:38; afterwards the machine
   answered at the same static address with the same three keys, accepted by the same pin, and
   systemd reported `running`.
5. **Listing:** `GET /api/v1/vm` lists the machine.
6. **Reinstall:** `PATCH /api/v1/vm/{id}/re-install` with no body at 05:18:05. The published
   keys were **cleared at once** (empty by 05:18:15), the reinstalled system booted at 05:18:22,
   and a new set was published at 06:18:31, an hour later, sharing no fingerprint with the old
   one. The reinstalled system presented exactly the newly published keys in every family; the
   old pin was refused ("REMOTE HOST IDENTIFICATION HAS CHANGED") and the new one admitted a
   login. `ARC-22` says "a vendor-API reinstall of the same machine stands in and is a **new first
   contact**", and this is what the old and new pins showed.
7. **Destroy and stop:** `DELETE /api/v1/vm/{id}` was refused with `405`. A stop
   (`PATCH …/stop`) left the machine `stopped` and still listed, with `deleting_on` one day after
   the expiry (the grace may lengthen with the subscription's age; it was read at day 0). The
   machine's `auto_renewal_enabled` read **true** before the stop — the research finding read
   auto-renewal as opt-in and off by default — and a `PATCH` turned it off.
8. **CORS from a real browser:** Chromium 154, headless, on the origin
   `http://127.0.0.1:18765`, read `GET /api/v1/image` (200) and a NIP-98-signed
   `GET /api/v1/vm` (200, the machine listed) from page JavaScript. The signed call carries an
   `Authorization` header, so it was preflighted. A cross-origin write, a no-op
   `PATCH /api/v1/account` with `Authorization` and a JSON `Content-Type`, also returned a
   readable 200. None of these calls went through a pinned tunnel (`CHN-12a`).
9. **Second account, same address:** the second key's account accepted the same operator
   address and read verified 30 seconds after the first, and placed no order.

## Costs recorded, not failures

- Keys arrive an hour after `running`, and again after a reinstall.
- One month is the shortest period; the tax was 24% on an order from this host.
- No destroy route the operator can call: `405`.
- Auto-renewal reads on for a new machine; turning it off is `STG-21`'s.
- The vendor's own user-data upgrades every package at first boot.
- A stopped machine is deleted a day after expiry at this subscription age.

## What went wrong during the run

The first account update went out through `nak curl`, which signs with nak's default key
whatever `--sec` says. It changed the email of the account belonging to that default key, a key
anyone can use, to the operator's address; the address and both contact settings were restored
minutes later, and that account's verification could not be. The probe's own accounts were not
touched by it. Every request after that, and the phase-A script's listing, now goes through
`lnvps-req.sh`, which hands the key to `nak event` through `NOSTR_SECRET_KEY`, never as an
argument; each write was
preceded by a read of the account it targets. Phase A's record is corrected to match
(`2026-10-09-lnvps-nip90-probe.md`).

## Cost

8,721 sat (7,033 sat plus 1,688 sat tax) and 43 sat in routing fees, for one month.
