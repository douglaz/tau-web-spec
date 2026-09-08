# Findings — the first stage, run once by hand (T1, STG-2)

Date: 2026-09-08. Script: `prototypes/first-stage-rehearsal/`. Evidence:
`2026-09-08-first-stage-rehearsal/` beside this file (redacted Robot captures, keyscans, the
install transcript, the timeline, one screenshot). Machine: a Hetzner server-auction
i7-6700 (server 3064816, `88.99.2.106`, FSN1-DC8), ordered through Robot at 14:48Z and
cancelled through Robot at 17:15Z. Cost: hourly billing, under one euro.

**By hand** meant `curl` against Robot and `ssh` from a workstation, scripted so every value
was captured once. No harness code was involved.

## The answer

**The identity chain closes on real hardware, in the corpus's order, with no
trust-on-first-use at either hop.** Hop one: the rescue system's host key is pinned from
the Robot API before first contact. Hop two: the installed system's host keys are read from
its disk inside rescue before the reboot, and the first connection after the reboot is
checked against those alone. Both hops ran, refused nothing they should have accepted and
accepted nothing they should have refused. A key the machine was never given was refused
by sshd itself (`STG-13`).

**A clean run is 4 min 34 s** from rescue activation to a pinned login on the installed
Alpine, unattended. **This rehearsal took 2 h 27 min**, because the install recipe was wrong
in five ways that no API can see — four of them boot failures, the fifth caught before any
disk was touched — and a dedicated server that does not boot is invisible over the network.
That gap is the most important number here.

## OPN-6 — what Robot's rescue `host_key` actually returns (CNF-48)

1. **`POST /boot/{n}/rescue` returns `host_key: []`.** Activation publishes nothing;
   `active: true`, `boot_time: null`, and `authorized_key` echoes the registered key as
   `{key:{name, fingerprint (MD5 colon), type, size, created_at}}`.
2. **The reset boots a rescue system that generates fresh host keys**, every time. Three
   activations, three different key sets. A pin is per boot, not per machine.
3. **Once rescue has booted, `GET /boot/{n}/rescue` reports `active: false, host_key: []`.**
   Rescue is one-shot and that endpoint shows the *available* configuration, not the
   running one.
4. **`GET /boot/{n}/rescue/last` carries the keys**: three objects
   `{key:{fingerprint, type, size}}` for ECDSA-256, ED25519 and RSA-3072. The fingerprint
   is **SHA-256, base64, unpadded, without the `SHA256:` prefix** — the string `ssh-keygen -lf`
   prints after the prefix. **No public key material is published.** The same object gains
   `boot_time`, a timestamp in **Europe/Berlin local time with no zone marker**.
5. **Timing, three cycles:** the keys and `boot_time` appear on `/rescue/last` **78–82 s after
   the hardware reset** and **8–14 s before the rescue's sshd accepts connections**. A client
   polling `/rescue/last` for a non-null `boot_time` has its pin before first contact is
   possible. (`rescue-last.json`, `keyscan-rescue.txt`, `timeline.tsv`.)
6. Every fingerprint the API published matched a key presented on the wire, three of three,
   on every cycle.
7. **The server-auction order transaction carries `host_key` too**, in the same shape,
   because an ordered server is delivered running the rescue system
   (`dist: "Rescue system"`); those keys matched the wire as well (`order-status.json`,
   `keyscan-order.txt`). The boot endpoint knows nothing of that rescue.

**Consequence for `CHN-R1`.** The route is `POST /boot/{n}/rescue` → `POST /reset` → poll
`GET /boot/{n}/rescue/last` until `host_key` fills → compare the presented key's SHA-256
fingerprint → connect. "Reads the authoritative host key, derives the fingerprint locally" is
backwards: the API gives fingerprints, the client derives the presented key's fingerprint and
compares. The script's first run refused to connect because it pinned from the activation
response, which is empty — the right refusal for the wrong reason, and it cost one cycle.

## The rescue system, and Alpine from inside it (ARC-24, ARC-25)

- Rescue is Debian 12 (`OpenSSH_9.2p1 Debian-2+deb12u7`, kernel 6.12), with `sgdisk`,
  `partprobe`, `mkfs.vfat`, `mkfs.ext4`, `chroot`, `curl` present.
- The installer catalogue (`linux-catalogue.json`) has grown since 2026-08-31 — AlmaLinux 10,
  Debian 13, openSUSE 16, Ubuntu 26.04 — and still has **no Alpine and no NixOS**. The rescue
  `os` list is `linux, linuxold, linuxbeta, vkvm, vkvmbeta`.
- Alpine 3.24.1 installed from the minirootfs at a versioned URL with its sibling `.sha256`,
  checked against the pin recorded on 2026-09-07 and against the downloaded sibling: both OK.
  Download, verify, partition, extract, `apk add` 154 packages in chroot, GRUB: **54–60 s**.
- The installed system's host keys were generated inside the chroot (`ssh-keygen -A`) and read
  from `/mnt/etc/ssh/*.pub` before any reboot (`known_hosts.installed`); the keys on the wire
  after the reboot were byte-identical (`STG-4`, `CNF-22`).

## What was wrong with the recipe, in the order it was found

The recipe that looked complete on paper failed to produce a reachable machine **five resets
in a row**. Each fault was found only by booting back into rescue, and the last two only by
looking at a screen.

1. **Disk names swap between boots.** `/dev/sda` in one rescue boot was `/dev/sdb` in the
   next. GRUB had been installed on one disk; the firmware booted the other, which had an
   all-zero boot sector. Fix: a BIOS-boot partition and GRUB on **every** disk, as Hetzner's
   `installimage` does, and disks addressed by id.
2. **Alpine's initramfs needs the kernel arguments `setup-disk` writes.** The recipe had
   none; the reset after `modules=sd-mod,usb-storage,ext4 rootfstype=ext4` was added is the
   first the logs show reaching userland. Two changes were made together on that attempt —
   the kernel arguments and a protective-MBR boot flag (`parted disk_set pmbr_boot on`) —
   and this record first credited the flag. The **clean pass disproved that**: its recipe
   writes the kernel arguments but never sets the flag (`sgdisk --zap-all` leaves the
   protective MBR without it), and it booted. The flag is unnecessary on this board; the
   kernel arguments are what mattered. (Caught in review by a second model reading the
   recipe against the findings.)
3. **The rescue's firmware mode says nothing about the target's.** The rescue is PXE-booted
   in legacy mode, so `/sys/firmware/efi` was absent and the recipe skipped the EFI
   bootloader. The vKVM console (below) boots the disk under OVMF and showed the firmware
   falling through to PXE for lack of one. Fix: both bootloaders, unconditionally, with the
   EFI removable fallback path, since no NVRAM entry can be written from a rescue.
4. **A minirootfs is not a bootable system.** With `sshd` and `networking` enabled and
   nothing else, the machine booted, `sshd` listened — and `eth0` did not exist:
   `ip: ioctl 0x8913 failed: No such device`. No `mdev`/`hwdrivers` in sysinit means no
   driver is loaded by modalias, so the Intel I219 (`e1000e`, present in `linux-lts`) never
   bound. Fix: the service set Alpine's `setup-disk` enables.
5. **by-id names differ between udev and mdev** for the same disk (full model string vs
   truncated), so an id copied from the installed Alpine did not exist in the rescue. `sgdisk`
   failed before writing anything. Fix: refuse a non-block-device up front; prefer `wwn-`
   names, which both write identically.

Also set while there: `PasswordAuthentication no`, a 3 s GRUB timeout, Alpine's own kernel
arguments, a serial console on the kernel line, and `rc_logger` plus busybox `syslog` so a
boot that reaches userland leaves a trace on disk for the next rescue to read.

## The console this design lacks — vKVM

After three silent failures the only way to see the machine was Hetzner's **vKVM rescue**
(`os=vkvm` on the same endpoint): the board boots a hypervisor that runs the installed disk
inside QEMU (`-machine q35,accel=kvm`, OVMF firmware, both disks as AHCI, `e1000e` with the
physical MAC). Facts:

- `authorized_key` is rejected for `os=vkvm` (`400 INVALID_INPUT`); it is **password-only**,
  the password being the activation response's `password` field.
- The screen is noVNC behind nginx HTTP Basic on port 47773 with a self-signed certificate
  (`CN=<server ip>`, issuer Hetzner Online GmbH / vKVM console); sshd on 47772.
- Inside the rescue, a QEMU monitor on `127.0.0.1:4444` gives `screendump`, which is how
  `vkvm-screen-uefi-no-bootloader.png` was taken, and `quit`, which stops the VM so the disk
  can be mounted and repaired from the rescue host.
- `boot_time` and `host_key` stay null for a vKVM rescue.
- The VM's VGA console is black after GRUB under OVMF with Alpine's default kernel line; a
  serial console is what shows the boot.

The corpus prices the first stage as a ceremony; the rehearsal says its cost is dominated by
**diagnosing a machine that does not come back**, which needs this console, a credential
(`SEC-5` has no row for it), a second known TLS destination on a certificate no pin can
vouch for, and a brief that knows all of the above.

## STG-13, STG-16, CNF-47

- **STG-13:** a fresh ed25519 key, never registered anywhere: `Permission denied
  (publickey)`, exit 255; sshd logs `Connection closed by authenticating user root
  [preauth]`. The refusal is sshd's; no harness is consulted.
- **STG-16:** clean path 4 min 34 s (reset → `host_key` 82 s; `host_key` → rescue sshd 8 s;
  install 60 s; reset → installed sshd 69 s). Full rehearsal 2 h 27 min, five resets into the
  installed disk before one answered, three rescue cycles, two vKVM cycles.
- **CNF-47:** install transcript 16.9 KB (`install-transcript.txt`).

## Smaller facts the corpus did not have

- **Auction servers bill hourly** (`price_hourly` on `/order/server_market/product`) and are
  ordered by API with `authorized_key[]` and `addon[]=primary_ipv4`; there is a `test=true`
  dry run. Delivery took about a minute. `OPN-5`'s account floor is unchanged, but a
  disposable machine is cents, not a month.
- Robot's `POST /reset` returns `operating_status: "running"` immediately; it says nothing
  about the boot.
- OpenSSH's per-source penalty is visible from the other side too: the rescue's sshd logged
  the rehearsal workstation's address on every preauth probe. `ARC-41`'s accepted narrowing
  applies to the rescue system as much as to the installed one.
- `/boot/{n}/rescue` on a server delivered in rescue by an order reports `active: false`.

## What this changes in the corpus

For the `/grill-with-docs` round: `OPN-6` closes and `CNF-48` is recorded; `CHN-R1`'s route
text changes to `/rescue/last` after the reset and to fingerprints rather than keys;
`STG-2` is done and `STG-16` has its number; `06-first-stage.md` gains the diagnosis path
(vKVM), its credential, and the brief items the recipe learned; `SEC-5` may want a row; and
`ARC-25`'s pin for Alpine is verified in use. `OPN-3` narrows: the rescue ceremony has now
been rehearsed end to end on the dedicated path.
