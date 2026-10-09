# Findings — LNVPS as the first vendor and the jump vendor (`OPN-24`)

Date: 2026-10-08, with one live catalogue check on 2026-10-09 (the last section). Desk research
against primary sources only; no account, no machine, no payment.
Sources: the API repository `github.com/LNVPS/api` at commit `8352f11` (2026-10-05), cited as
`path:line`; the live API at `https://api.lnvps.net`, read with unauthenticated calls only —
`GET /api/v1/image`, `/api/v1/vm/templates`, `/api/v1/payment/methods`,
`/api/v1/notification/channels`, `/api/v1/exchange-rate`, `/docs/endpoints.md`,
`/docs/changelog.md`, a CORS preflight and an unauthenticated `GET` on `/api/v1/vm`, and one
`POST /api/v1/vm/custom-template/price`, a calculator that takes no auth and writes nothing
(`lnvps_api/src/api/routes.rs:1270-1285`); and three lnvps.net pages — `/`, `/tos` (last updated
2026-07-15) and the API guide the site's footer links, `https://lnvps.net/SKILL.md`. No secondary
source was used. No copy of any response is committed; values are quoted as read at about
05:27 UTC.

**The code read is the code that answers.** The server serves documentation compiled into its
binary (`lnvps_api/src/api/docs.rs:10-11`). Its `/docs/endpoints.md` is byte-identical to
`API_DOCUMENTATION.md` at `8352f11`, and its `/docs/changelog.md` is byte-identical to
`API_CHANGELOG.md` at `b106259` (2026-09-28), lacking only the one entry `9ad8dd1` added on
2026-10-05. Every line cited below reads the same at `b106259` and at `8352f11`.

## Verdict

**LNVPS cannot be attested to as `CHN-R5` is written, and its HTTP API cannot be ordered from
with a Nostr key alone.** `CHN-R5` plants a sender key "whose private half goes into user-data
beside the SSH client public key", and a create request carries no user-data: the cloud-init a
machine boots is composed by the vendor from the one SSH public key the buyer registered. What it
offers instead is a retrieve route — each machine's status carries its SSH host keys, scanned from
the hypervisor after boot. `CHN-R6` pins a jump host "by attest (`CHN-R5`), or by a retrieve route
where the jump vendor offers one"; this one is unmeasured.
The API answers any browser origin and authenticates by NIP-98 or a bearer token, so a static
page can call it directly. A key lists its machines but cannot destroy one: there is no customer
delete route. Ordering through the HTTP API requires a verified email address on the live server
(a NIP-90 job handler orders without that check, and whether it runs in production is unknown;
see section 3), which contradicts `OPN-24`'s premise that LNVPS "identifies a buyer by a Nostr key, and keeps no account". The
shortest period sold is one month (€5.20 before VAT for the smallest custom build), with no
pro-rata and refunds only by email. Arch Linux is in the catalogue; custom images and ISOs are not.

| # | Question (`OPN-24`) | Verdict | Owner of the answer |
|---|---|---|---|
| 1 | Boot-time user-data, or published host keys | **partly** — no user-data; a retrieve route exists, unmeasured | `lnvps_api/src/api/model.rs:380-386`; `lnvps_api_common/src/model.rs:298-303` |
| 2 | Browser reachability | **yes** — wildcard origin, `Authorization` allowed; preflight passed live | `lnvps_api/src/bin/api.rs:34-51` |
| 3 | Inventory and destruction | **partly** — lists yes, destroy no; a verified email gates every HTTP order; NIP-90 ordering unresolved | `routes.rs:95-188`; `routes.rs:1309-1313` |
| 4 | A machine paid for minutes | **no** — one month minimum, no pro-rata | `lnvps_api_common/src/pricing.rs:67-68` |
| 5 | An Arch image | **yes** — image 11, "archlinux Cloud Latest"; no custom image or ISO | live `GET /api/v1/image` |

## 1. Boot-time user-data, or published host keys — partly

**No user-data.** The standard order is `CreateVmRequest { template_id, image_id, ssh_key_id,
ref_code }` (`lnvps_api/src/api/model.rs:380-386`); the custom order adds the machine spec and
nothing else (`model.rs:16-24`, `818-841`). Neither struct denies unknown fields, so an extra
`user_data` member would be dropped by the deserializer rather than refused — read from the code,
not observed.

On Proxmox, the backend the README calls "production-ready" (`README.md:26`), the machine's
`cicustom` names only a `vendor` and a `network` snippet (`lnvps_api_common/src/host/proxmox.rs:1360-1364`),
both written by the vendor; the only buyer-derived input is `ssh_keys` from the stored key
(`proxmox.rs:1389`). The vendor snippet sets `ssh_deletekeys: false` and pins resolvers
(`proxmox.rs:2830-2855`). The libvirt backend's NoCloud user-data is likewise generated —
hostname, the image's default user with the one key, `ssh_pwauth: false`, `disable_root: true`
(`lnvps_api_common/src/host/cloud_init.rs:178-221`). No route takes a script, and no image is
said to honour one; the question of which images honour buyer user-data does not arise.

**The buyer's key** is registered first — `POST /api/v1/ssh-key {name, key_data}`, parsed as an
OpenSSH public key (`routes.rs:1370-1399`) — and named by `ssh_key_id` in the order, which is
refused unless the key belongs to the caller (`lnvps_api/src/provisioner/vm.rs:286`).

**A retrieve route exists.** `VmStatus.host_ssh_keys` is documented as "The VM's own SSH host
keys, for verifying the host on first connect. Empty until captured after first boot;
re-captured after a reinstall" (`API_DOCUMENTATION.md:330`), each entry `{ key_type, public_key,
fingerprint_sha256 }` (`lnvps_api_common/src/ssh_host_key.rs:10-18`). It shipped on 2026-07-29
(`API_CHANGELOG.md:318`) and is in the live server's documentation. How it is captured:

- "Scanned from the Proxmox node rather than from here … Only public keys are read — nothing runs
  inside the guest" (`lnvps_api/src/worker.rs:1685-1687`): the node runs `ssh-keyscan -T 5 -t
  ed25519,rsa,ecdsa` against the machine's first address, IPv4 preferred (`worker.rs:1741`,
  `1771-1789`).
- It runs on the 30-second VM sweep (`lnvps_api/src/bin/api.rs:319`), only once the machine is
  `running` (`worker.rs:1708`), and not at all for a host with no SSH credential configured
  (`worker.rs:1695`).
- The attempt is stamped before the scan, and the next one waits `HOST_KEY_SCAN_RETRY_SECS`
  = 3600 (`worker.rs:119`, `1719-1729`). A first scan that lands before sshd is up therefore
  delays the keys by an hour; a capture missing a family is rescanned hourly.

So the pin is the hypervisor's scan of whatever answered on the machine's address, delivered over
TLS from `api.lnvps.net`. `CHN-R6` admits a jump host "pinned out of band — by attest (`CHN-R5`),
or by a retrieve route where the jump vendor offers one"; whether this one is acceptable is T39's
to decide, not this finding's.

*Left for the probe:* whether an order carrying `user_data` is accepted and ignored; the time from
payment to `running` to a complete `host_ssh_keys`; whether the key the machine presents on first
SSH equals the published one; whether a reinstall re-captures.

## 2. Browser reachability — yes

The CORS layer is `allow_origin(Any)`, `allow_methods(Any)`, `allow_headers(AllowHeaders::mirror_request())`,
`expose_headers(Any)` (`lnvps_api/src/bin/api.rs:46-51`), because "Auth is carried in the
`Authorization` header (NIP-98 / JWT), never cookies, so credentials are NOT needed"
(`api.rs:36-37`). It wraps the whole router, outside rate limiting, so a `429` carries it too
(`api.rs:516-543`).

Live: a preflight `OPTIONS /api/v1/vm` from `Origin: https://example.org` asking for `POST` with
`authorization,content-type` returned `200`, `access-control-allow-origin: *`,
`access-control-allow-headers: authorization,content-type`, `access-control-allow-methods: *`.
`GET /api/v1/image` returned `200` with `access-control-allow-origin: *` and
`access-control-expose-headers: *`; an unauthenticated `GET /api/v1/vm` returned `403` "Auth
header not found" with the same origin header. No browser was exercised; readability is inferred
from the headers. `OPN-24` asks "whether its API answers a browser origin, or needs the pinned
tunnel of `CHN-12a`"; on these headers it answers one.

The serial console is a WebSocket that takes a single-use, path-scoped, 30-second `?ticket=`
from `POST /api/v1/auth/ticket` (`API_DOCUMENTATION.md:77-119`, `998-1002`).

*Left for the probe:* the same calls from a page on an arbitrary origin in a real browser,
including a `PATCH` and the console socket.

## 3. Inventory and destruction — partly

**Listing: yes.** `GET /api/v1/vm` returns the caller's machines as `VmStatus[]`
(`routes.rs:124`, `986-1011`); `GET /api/v1/vm/{id}` returns one (`routes.rs:125`).

**Destruction: no route.** The customer router (`routes.rs:95-188`) has no `DELETE` on a machine.
A machine can be started, stopped, restarted and reinstalled (`routes.rs:147-150`), and `PATCH`
changes only `ssh_key_id`, `reverse_dns` and `auto_renewal_enabled` (`API_DOCUMENTATION.md:604-608`).
Deletion exists on the admin API, `DELETE /api/admin/v1/vms/{id}`
(`lnvps_api_admin/src/admin/vms.rs:35-38`), and in the worker: a never-paid order after an hour
(`worker.rs:2003`; `routes.rs:1292` "Unpaid VM orders will be deleted after 1 hour"), and a paid
one after expiry plus a grace that grows with the subscription's age — 1, 2, 7, 14 days up to
180 days old (`lnvps_api_common/src/model.rs:344-357`). A one-month machine is stopped at expiry
and deleted about 14 days later. The terms say "You may terminate your account at any time via
your control panel or by contacting us" (`/tos` §8); no customer route backs the first half.
`CHN-R6` requires "**One jump host per first contact, per machine, never reused.** It is
destroyed once the target is pinned."

**An account beyond the key: yes, an email address.** Both order handlers refuse with
"Email verification is required before creating a VM" when `this.settings.smtp.is_some() &&
!user.email_verified` (`routes.rs:1309-1313`, `1447-1451`; added `f161c1b`, 2026-02-25). The
public `GET /api/v1/notification/channels` reports `email: this.settings.smtp.is_some()`
(`routes.rs:744-753`), and live it returned `{"nip17":true,"email":true,"telegram":true,"whatsapp":false}`.
The site's API guide says "LNVPS accounts require a verified email address". The terms' "accounts
may be created without providing personal contact details" (`/tos` §9) holds for the account row
— every authenticated call creates one for its key (`routes.rs:991`) — not for an order. No
identity-document step appears in any customer route; each order stores the client's IP address
and its geolocated country as VAT evidence (`routes.rs:196-212`, called at `1303` and `1442`).
`CHN-R6` requires "**The jump vendor is paid in Bitcoin and needs no account**".

**One path skips the email check, and is not the HTTP API.** A NIP-90 handler for job kind 5999
places a custom order and replies with a Lightning invoice, with no email check
(`lnvps_api/src/dvm/lnvps.rs:95-153`). It is a default feature (`lnvps_api/Cargo.toml`, `nostr-dvm`),
the published image keeps the defaults (`Dockerfile:39-41`), and the worker starts it whenever a
Nostr configuration exists (`api.rs:427-436`) — which `nip17: true` implies (`routes.rs:748`).
Whether it listens in production, and on which relays, is unknown from the docs. Its replies are
relay events, not TLS the browser terminates.

*Left for the probe:* the `403` before verification; a `DELETE /api/v1/vm/{id}` answered `405`;
the date a stopped, expired machine leaves the listing.

## 4. The minimum billing period — no, one month

**Prepaid, one invoice per call.** `GET /api/v1/vm/{id}/renew?method=lightning&intervals=N`
(an alias of `/api/v1/subscriptions/{id}/renew`) returns a `VmPayment` whose `data.lightning` is
the invoice, with `amount` in millisatoshis, `tax`, `processing_fee` and `time`, the seconds it
adds (`API_DOCUMENTATION.md:491-518`, `1212-1220`). `N` runs from 1 to 120
(`lnvps_api_common/src/expiry.rs:20`). `GET …/renew/quote` prices the same call "and **creates
nothing**" (`API_DOCUMENTATION.md:1227`). Renewal is the same call again, or opt-in auto-renewal
from a saved wallet connection, off by default (`API_DOCUMENTATION.md:807`).

**Periods.** Cost plans may be `day`, `month` or `year` (`API_DOCUMENTATION.md:18`), but custom
builds are fixed at one month — `CUSTOM_VM_INTERVAL_TYPE: IntervalType = IntervalType::Month`
(`pricing.rs:67-68`). Live, the catalogue holds one standard template, "Medium - Yearly
Discount" (4 vCPU, 4 GiB, 160 GiB, €150 a year, Dublin), and one custom plan, `pricing_id` 7
(1–64 vCPU, 1–32 GiB, SSD 10–500 GiB, exactly one IPv4 and one IPv6). No day plan is on offer.

**The cheapest machine.** The calculator, asked for 1 vCPU, 1 GiB, 10 GiB SSD, one IPv4 and one
IPv6, returned `{"currency":"EUR","amount":520,…,"interval_amount":1,"interval_type":"month"}`
with a BTC price of 7,025,698 msat at the server's rate of the moment. VMs carry no setup fee
(`provisioner/vm.rs:208`, `345`). Lightning lists no processing fee or minimum
(`/api/v1/payment/methods`). VAT is added by place of supply, which the vendor determines from a
declared country "and/or … location evidence such as your IP address" (`/tos` §7.1).

**Refunds.** "Refunds are available within 14 days of initial purchase, provided no excessive
usage has occurred, as determined by us. Refunds of amounts paid in Bitcoin are made in Bitcoin
at the originally invoiced amount" (`/tos` §7). Automated Lightning refunds exist, behind the
admin API only (`lnvps_api_admin/src/admin/vms.rs:60-61`, `lnvps_api/src/refund.rs:1-13`).
Stopping a machine credits nothing.

**So a machine that lives for minutes costs one month of the smallest custom build** — €5.20 plus
any VAT — and then exists, stoppable but not destroyable, until about 14 days after that month
ends. An unpaid order costs nothing, but nothing boots before payment: addresses are assigned in
the spawn pipeline (`provisioner/vm.rs:633`).

*Left for the probe:* the invoice's amount and tax line for the probe's location, its expiry, and
the time from settlement to `running`.

## 5. An Arch image — yes

Live `GET /api/v1/image` lists fourteen images, one of them `{"id":11,"distribution":"archlinux",
"flavour":"Cloud","version":"Latest","release_date":"2026-07-17T00:00:00Z","cpu_arch":"x86_64",
"default_username":"arch","popularity":0.0}`. `popularity` is the "fraction (0.0–1.0) of active VMs
using this image" (`API_DOCUMENTATION.md:461`), so no machine runs it today. The others are
Ubuntu 22.04, 24.04 and 26.04, Debian 13, Fedora 44, CentOS Stream 9 and 10, Rocky 10, Alpine
3.24, AlmaLinux 8 and 10, FreeBSD 14.2 and NixOS 24.11. An image's download source is an admin
field; the admin demo data points Arch at `https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2`
(`lnvps_api_admin/src/bin/generate_demo_data.rs:495`), which is demo data, not production.

**No custom image or ISO.** An image is chosen by `image_id` from that list, at order or by
`PATCH /api/v1/vm/{id}/re-install {image_id}` (`API_DOCUMENTATION.md:991-996`); no customer route
uploads an image or attaches an ISO. Omarchy is not in the catalogue, so `OPN-25` is untouched.

*Left for the probe:* that the image boots, that cloud-init puts the key on `arch`, and that sshd
offers all three key families the capture asks for.

## Reference

**Base URL.** `https://api.lnvps.net` (the site's API guide, "**Base URL:**"; and every live call
above). `API_DOCUMENTATION.md:7` still reads `https://api.lnvps.com` "(replace with actual
production URL)". `/openapi.json` answers `404`: it exists only in builds with the `openapi`
feature (`api.rs:489`). Bodies are `{ "data": … }` or `{ "error": … }`; the general rate limit
is 600 requests a minute per IP (`API_DOCUMENTATION.md:31-40`).

**Authentication.** Every authenticated route takes either `Authorization: Nostr <base64 of a
signed event>` or `Authorization: Bearer <jwt>`, the latter issued by OAuth (Google, GitHub,
Facebook, Apple) or passkey login (`API_DOCUMENTATION.md:42-61`). For the Nostr scheme the server
checks, in order, kind 27235, `created_at` within 60 seconds of its clock, the `u` tag's path
against the request path, the `method` tag, and the signature, then burns the event id so it is
accepted once (`lnvps_api_common/src/nip98.rs:22`, `128-169`). The code compares the path only,
though its own comment says host and path (`nip98.rs:119-120`). A `payload` tag is optional and,
when present, must be the lowercase hex SHA-256 of the exact body. The signing key is the
account: the first authenticated call creates its user row. No cookies are used.

**Order fields.** Standard, `POST /api/v1/vm`: `template_id`, `image_id`, `ssh_key_id`,
`ref_code?`. Custom, `POST /api/v1/vm/custom-template`: `pricing_id`, `cpu`, `memory` (bytes),
`disk` (bytes), `disk_type` (`ssd`|`hdd`), `disk_interface` (`sata`|`scsi`|`pcie`), `cpu_mfg?`,
`cpu_arch?`, `cpu_feature[]`, `ip4_count` and `ip6_count` (each defaulting to 1), `image_id`,
`ssh_key_id`, `ref_code?` (`lnvps_api/src/api/model.rs:16-24`, `818-841`). The documentation's
`CustomVmRequest` omits the two address counts (`API_DOCUMENTATION.md:413-420`). Either returns
a `VmStatus` with no `expires` until paid.

**Addresses.** `VmStatus.ip_assignments` is a list of `{ id, ip, gateway, forward_dns?,
reverse_dns? }`, one entry per address, IPv4 and IPv6 alike, with no family field; `ip` is the
address with its range's prefix, such as `a.b.c.d/24` (`lnvps_api_common/src/model.rs:484-506`).
It fills only after payment, in the spawn pipeline. For an IPv6 range handed out by SLAAC, "The
host hands out the address; what the database holds is informational only"
(`cloud_init.rs:68-69`).

## What the live probe must measure

In order, with a fresh Nostr key, a mailbox the operator controls (never recorded here), and the
operator's wallet:

1. Unauthenticated: `GET /api/v1/image`, `/api/v1/vm/templates`, `/api/v1/payment/methods`,
   `/api/v1/notification/channels` — today's answers, again.
2. From a static page on an arbitrary origin, NIP-98 signed: `GET /api/v1/account`, which creates
   the account row. Record the CORS headers as the browser sees them.
3. `POST /api/v1/ssh-key` with the client public key.
4. Create with user-data, before verifying email: `POST /api/v1/vm/custom-template` with
   `pricing_id` 7, 1 vCPU, 1 GiB, 10 GiB `ssd`/`pcie`, one IPv4, one IPv6, `image_id` 11 and an
   extra `user_data` member. Expect `403` "Email verification is required before creating a VM".
5. `PATCH /api/v1/account {email}`, then the link's `GET /api/v1/account/verify-email?token=…`,
   then `GET /api/v1/account` showing `email_verified: true`.
6. Repeat step 4. Expect a `VmStatus` with no `expires`; record whether `user_data` was refused
   or silently dropped.
7. `GET /api/v1/vm/{id}/renew/quote?method=lightning&intervals=1`, then
   `GET /api/v1/vm/{id}/renew?method=lightning&intervals=1`; pay the invoice from the operator's
   wallet; poll `GET /api/v1/payment/{id}` until `is_paid`.
8. Observe first boot: poll `GET /api/v1/vm/{id}` every 30 seconds and timestamp payment,
   `creating`, `running`, the first non-empty `ip_assignments`, the first non-empty
   `host_ssh_keys`, and the capture holding ed25519, RSA and ECDSA.
9. SSH as `arch` to the reported IPv4 and compare the presented key with `host_ssh_keys`. On the
   machine, read cloud-init's user-data and vendor-data and `cloud-init status --long`: no buyer
   content, the vendor snippet as read above, and the IPv6 address as configured.
10. List: `GET /api/v1/vm` includes the machine.
11. Destroy: `DELETE /api/v1/vm/{id}`, expecting `405`; then `PATCH /api/v1/vm/{id}/stop`, with
    auto-renewal left off. Record the date the machine leaves `GET /api/v1/vm` — expected about
    14 days after the paid month ends.

Optionally, `PATCH /api/v1/vm/{id}/re-install` to time the host-key re-capture, since `CHN-R6`
says "**A reinstall through the vendor's API is a new first contact**".

**Expected cost:** one month of the smallest custom build — €5.20 before VAT, 7,025,698 msat at
the server's rate on 2026-10-08 — plus VAT where the place of supply calls for it, plus the
payer's routing fee. No Lightning processing fee is listed. Under the terms, a refund may be
requested by email within 14 days.

## The fallback's image (`STG-21`), checked 2026-10-09

T39 also asks whether Hetzner Cloud offers the stage's distribution as an image at creation.
It does not. The live `GET /v1/images?type=system` listed AlmaLinux 8–10, CentOS Stream 9–10,
Debian 12–13, Fedora 43–44, openSUSE 16, Rocky 8–10 and Ubuntu 22.04–26.04 on both
architectures, and no Arch Linux. A project snapshot made from an Arch installation could be
named at creation, but it is not the vendor's catalogue. `STG-21` says "The fallback holds only
where Hetzner Cloud offers the stage's distribution as an image at creation", so it does not hold
for Arch either.
