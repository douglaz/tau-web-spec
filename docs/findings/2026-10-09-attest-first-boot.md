# Findings — attest on a real vendor's first boot (`OPN-3`, T40)

Date: 2026-10-09. Script: `prototypes/attest-first-boot/run.sh`, with the user-data template
beside it. Six Hetzner Cloud servers were created, measured and deleted one at a time.

**Verdict: attest fired on six of six first boots and reached the relay set every time.** On all
six, the browser stand-in received and accepted the wrap between **37.1 s and 52.2 s** after
the create call. On all six, SSH as root with `StrictHostKeyChecking=yes`, against a
`known_hosts` built only from the attested keys, logged in between **38.1 s and 54.1 s** after
the create call. The slowest boot was 52.2 s to the wrap and 54.1 s to the login (fsn1, cx23,
Debian 13). After the scrub, no file on the filesystem held the sender key. The metadata
endpoint still served it on every boot, as expected.

## Scope

Hetzner Cloud has no Arch image. The boots were five of Debian 13 and one of Ubuntu 24.04, and
they ran the upstream glibc release of the first-boot tool. This run measures attest on a real
vendor's first boot: cloud-init's timing, publishing over first-boot networking, and the
browser's window. It does not show how the tool reaches an Arch machine. The keys were random,
so it says nothing about derivation (`STA-22`). `CHN-18` says "The publisher's Nostr relay, on
the same host as the TCP bridge (`CHN-11`), is **mandatory**"; that relay does not exist yet, so
the relay set was public relays only. The "browser" was a
local script: one `nak` subscriber per relay plus an acceptance check. It was not the harness.

## Versions

- **Images.** Hetzner `debian-13` (`os_version` 13). On first boot it ran kernel
  `6.12.107+deb13-cloud-amd64` and cloud-init 25.1.4. Hetzner `ubuntu-24.04` reported
  "Ubuntu 24.04.4 LTS" and ran kernel `6.8.0-138-generic` and cloud-init
  `26.1-0ubuntu1~24.04.1`.
- **Server types.** The task named cpx11. The API listed it, but as not available in fsn1, nbg1
  or hel1, so the boots used cx23 (2 vCPU, 4 GB) in fsn1 and hel1. cx23 is not available in
  nbg1, so the nbg1 boot used cpx12 (1 vCPU, 2 GB).
- **Tool.** `nak` v0.20.7, release asset `nak-v0.20.7-linux-amd64`, 44,829,528 bytes, sha256
  `ba918fafd1b030bc50958a5b218c6386f4c3a57c1e469562d3947e858e0ba56e`. The hash was taken
  locally and matched the digest GitHub lists for the asset. The same binary ran locally and on
  each machine, and each machine ran `sha256sum -c` before executing it.
- **Relays.** `wss://nos.lol`, `wss://relay.primal.net`, `wss://nostr.mom`, and a dead entry,
  `wss://192.0.2.1` (TEST-NET-1), whose connect never completes. That tests a relay that hangs
  until a connect timeout. A name that fails to resolve was not tested.
- **Both traps from ADR-0029 were applied.** Every `nak` call had standard input redirected.
  Gift-wrapping used `--use-our-identity-key --use-their-identity-key`. With both flags, the
  event and the wrap together took 0.3–1.1 s on the machines.
- **Template.** Boots 4–6 ran the committed template exactly. Boots 1–3 differed in one header
  comment, described under `CNF-61` below. Boot 1 also ran `sha256sum -c` without `--quiet`,
  which only changes what is logged.

## Timings

All times are seconds after the create call, on the local clock. Machine-side events, marked
*(m)*, were logged on the machine's clock and corrected by an offset measured over the pinned
session. The offset ranged from −1.05 s to +0.32 s, each measured to within ±0.05 s. `running`
and port 22 were polled about once a second, so they are late by up to that much. Wrap receipt
is stamped as each line arrived.

| Event | 1 fsn1 cx23 Debian | 2 hel1 cx23 Debian | 3 nbg1 cpx12 Debian | 4 fsn1 cx23 Debian | 5 hel1 cx23 Debian | 6 hel1 cx23 Ubuntu |
|---|---|---|---|---|---|---|
| Create call returned | 0.4 | 0.4 | 0.4 | 0.3 | 0.3 | 0.3 |
| API status `running` | 19.5 | 13.2 | 10.0 | 19.4 | 16.2 | 19.4 |
| Kernel start *(m)* (hook's wall clock minus uptime) | 25.4 | 16.8 | 21.3 | 22.2 | 22.0 | 18.9 |
| Host keys written *(m)* (file mtime) | 45.1 | 34.4 | 36.1 | 42.0 | 40.6 | 34.9 |
| Port 22 open | 45.7 | 35.3 | 37.2 | 42.6 | 41.3 | 35.5 |
| Hook start *(m)* | 45.8 | 34.9 | 36.6 | 42.7 | 41.4 | 38.3 |
| Tool download *(m)*, duration | 3.4 | 0.5 | 0.5 | 0.7 | 0.5 | 0.7 |
| Tool verified and ready *(m)* | 49.9 | 35.7 | 37.3 | 44.0 | 42.5 | 39.6 |
| Wrap built, publish start *(m)* | 51.0 | 36.2 | 37.7 | 44.7 | 43.4 | 40.5 |
| First relay OK *(m)* | 52.0 | 37.0 | 38.5 | 45.6 | 44.5 | 41.5 |
| Scrub done *(m)* | 52.4 | 37.3 | 38.7 | 45.9 | 44.9 | 42.0 |
| **Wrap received and accepted** | **52.2** | **37.1** | **38.6** | **45.7** | **44.6** | **41.6** |
| Delivered by nos.lol / primal / nostr.mom | 52.2 / 52.5 / 52.3 | 37.1 / 37.2 / 37.1 | 38.6 / 38.6 / 38.6 | 45.7 / 45.7 / 45.8 | 44.6 / 44.8 / 44.6 | 41.6 / 42.3 / 42.6 |
| **Pinned SSH login** | **54.1** | **38.1** | **40.2** | **48.0** | **46.6** | **44.5** |
| Dead relay gave up *(m)*, eighth attempt; hook end | 192.7 | 176.5 | 176.7 | 186.1 | 185.4 | 181.6 |

`cloud-init analyze` shows the host keys come from cloud-init's own `config-ssh` module, in the
init-network stage. `config-ssh` ran 8.4–10.9 s after cloud-init's first event on Debian and
6.4 s after it on Ubuntu. On Debian, `networking.service` took 7.2–9.0 s of that gap. The hook
started 0.5–0.8 s after the host-key files were written on Debian, and 3.4 s after on Ubuntu.
Attest's own path, from hook start to the browser holding the wrap, took 2.0–6.4 s. The slowest
of those was boot 1, where the tool download took 3.4 s; elsewhere it took 0.5–0.7 s.
Everything before the hook is the vendor's provisioning plus the OS boot, which took 35–46 s of
the total.

Cloud-init's own end of boot is not the measure here. The dead relay holds the hook in the
foreground until its deadline, so `config-scripts-user` took 140–147 s. systemd's "Startup
finished" (2 min 35 s to 2 min 47 s) measures that retrying, not the boot.

## The slowest boot and the window (`CHN-6`)

`CHN-6` requires the browser's window to be set "from a **measured** slowest first boot rather
than a guess". Here the slowest was boot 1: **52.2 s** from the create call to an accepted wrap,
and 54.1 s to a pinned login. Of that, 45.8 s passed before the hook started, and boot 1 also
had the latest kernel start of the six (25.4 s). That is a floor, not a window. Six boots at one
vendor in one hour do not show a tail.

Two further numbers bear on the choice:

- The machine's housekeeping deadline, 120 s from publish start, fell 156–171 s after the
  create call. With the last 30 s wait, the hook stopped retrying 176–193 s after it. A browser
  window shorter than that can close while the machine is still retrying. Here that would only have mattered if every live relay had been unreachable for the
  first minute or more, which did not happen.
- Every wrap's `created_at` was 12.9 h to 33.9 h before it arrived, as NIP-59 randomises it.
  A `since` filter at the create call would have dropped all six. The subscription used `#p`
  only.

## Retries and the dead relay

Each relay had its own retry loop, and all of them ran in parallel. Every one of the 18
live-relay publishes (three relays, six boots) answered OK on the first attempt, between 0.75 s
and 1.94 s after publish start. The first OK of each boot came 0.75–1.14 s after publish start.
**A live relay that failed and then recovered was not observed**, so backoff against a real
outage is not exercised here.

The dead relay was attempted eight times per boot, 48 attempts in total. Each failed after
2.2–3.3 s with "context deadline exceeded". The waits between attempts were 1, 2, 4, 8 and 16 s,
then 30 s, and the relay was given up at the deadline. It delayed neither the first OK, nor the
scrub, nor the browser, because nothing waited on it. Its only effect was to hold cloud-init's
final stage open for the full deadline.

## Pass check

Pinned SSH passed on six of six. On each boot, every sealed host-key line's recomputed
fingerprint equalled the fingerprint sealed beside it, and `known_hosts` held exactly those
three keys (ECDSA, Ed25519, RSA). Nothing was fetched from the machine to build it.

The negative control repeated the same connection against a `known_hosts` that held a key not
belonging to the host. It was refused with "Host key verification failed" on all six.

The 18 attested fingerprints were all distinct, so the image does not ship baked host keys.

The acceptance check refused nothing, because no relay delivered anything else to these
recipients. Offline, `run.sh selftest` shows the check refuses a wrap sealed by a key other than
the planted sender, and refuses a key line whose fingerprint does not match. Of `CNF-18`'s three
checks, only the wrong-author one was exercised, and only offline. A second validly sealed wrap
after acceptance, and a wrap after the window, were **not observed**.

## The create response (`CNF-14`)

An SSH key was registered through the API and named in each create call. On all six boots the
create response carried the top-level fields `action`, `next_actions`, `root_password` and
`server`. `root_password` was present and `null`, and `next_actions` was `start_server`. A
create call without an SSH key was not made, so what it carries was **not observed**.

## The scrub and the metadata endpoint (`CNF-61`)

On the first OK, the hook searched `/var/lib/cloud`, `/run`, `/var/log`, `/root`, `/etc`,
`/tmp` and `/var/tmp` for the sender key, and redacted it in place in every file that held it.
It also deleted the env file the template wrote. The same five files held it on every boot:

- `/var/lib/cloud/instances/<id>/user-data.txt`
- `/var/lib/cloud/instances/<id>/user-data.txt.i`
- `/var/lib/cloud/instances/<id>/cloud-config.txt`
- `/var/lib/cloud/instances/<id>/obj.pkl`
- `/run/cloud-init/combined-cloud-config.json`

The hook's own re-check found no residue, and the scrub finished 0.2–0.5 s after the first OK.

After the hook ended, the whole disk was read over the pinned session, everything except
`/proc`, `/sys` and `/dev`. No file held the sender key, and `grep` exited 1, meaning no match
and no read error. The key reached that `grep` on the same stdin path as the metadata check
below, which did find it.

That was a file-level search for the key in plaintext hex. Two things it could not see were
**not observed**:

- **The raw block device.** The in-place edit writes a new file and unlinks the old one, so the
  original copies' blocks are freed but not wiped.
- **Encoded or compressed copies of the key.**

Then, from the machine, `http://169.254.169.254/hetzner/v1/userdata` **still served the
original user-data, sender key included, on all six boots**, about two to three minutes after
the scrub. Boots 1–3 carried the key twice, because the template's header comment repeated the
placeholder, which was fixed before boot 4; the scrub handled both copies. So the disk scrub is
defence in depth. What bounds the exposure is single use in the browser (`CHN-5`), and this run
does not exercise that.

## Relays and kind 1059

All three live relays accepted the write and served the wrap to an unauthenticated subscriber
filtering by `#p`. That matches `CHN-18`: serving a recipient's wraps only to a subscriber
authenticated as that recipient is "what the standard asks of relays and what three of four
public relays tested did not do". A fresh REQ after each boot returned the stored wrap from all
three, and every subscriber was still connected at the end of its boot.

`wss://relay.damus.io` was tried first and dropped. It accepted a write on a second attempt; its
first connect returned HTTP 503. It answered the kind-1059 REQ with `CLOSED`, "auth-required:
requested filter requires authentication", including when the recipient's key was supplied and
`--auth` was set. With `--force-pre-auth` the client reported no challenge, or the connect
returned 503. NIP-42 authentication as the recipient therefore did not complete with this
client, and the relay was left out of the set.

## What stays open in T40 and `OPN-3`

Shown by this run, for Hetzner Cloud with Debian 13 and Ubuntu 24.04:

- The hook fires from `runcmd` after cloud-init has written the host keys.
- It reaches public relays over first-boot networking.
- It delivers a wrap the browser accepts and pins, within 37–52 s of the create call.

Still open:

- **The Arch case.** How the tool reaches an Arch machine, and the static build on Alpine.
- **Derivation.** Determinism across a reinstall of the app (`STA-22`).
- **The publisher's Nostr relay.** It does not exist yet (see the scope above), and its NIP-42
  behaviour is untested.
- **Recovery after a failed publish.** No live relay failed, so this was not observed.
- **A distribution of boot times.** That needs more boots, other vendors, and busier hours.
- **The browser-side checks of `CNF-18`.**
- **The sheet's re-import.** `OPN-3` also lists it, and this run does not touch it.

## Reproduce

```sh
cd prototypes/attest-first-boot
export HETZNER_CLOUD=...      # an API token; the script writes it once to a mode-600 header file
./run.sh all                  # selftest, setup, six boots, clean
rm -rf /var/tmp/attest-proto
```

Cost: six servers, each billed one hour: five cx23 at €0.0104 and one cpx12 at €0.0216 (gross
list prices), about €0.07, plus their primary IPv4 addresses for an hour.
