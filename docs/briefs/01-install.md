# Brief 1 — install

A brief is instructions, not a script (`ARC-9`, ADR-0001): read it, look at the machine, and
decide what to run. The commands here are examples based on the run of 2026-09-08 on a
Hetzner server-auction machine with two SATA SSDs and legacy boot. Where they will differ on
another machine is said. This is a draft written from that one run; it is not yet in the
signed bundle (ADR-0005), and its resume section has never been exercised. The disk-selection
and resume corrections of 2026-09-09, and the stateless rewrite of 2026-09-15, have not been
rehearsed on hardware.

## How commands run

**Every command you issue is one stateless, detached job** (`ARC-7`, `STA-20b`). Nothing
survives from one to the next: not the working directory, not a variable, not a chroot you
entered. So every example block below is self-contained. Where a block needs the installed
root it wraps its own `chroot /mnt sh -c '…'`. Where a block needs a value, that value has a
named source:

- **the harness**, from the bundle — the artifact URL and hash you never see or type
  (`fetch_artifact` uses them); the repository branch, repository URLs and accepted key
  fingerprints (`bundle/artifact-alpine.toml`) the harness shows you and you copy into the
  commands that need them;
- **the harness, per session** — the bound session's SSH client public key, shown to you for
  the one command that installs it (step 6);
- **you**, from what you read in step 1 — the root disk, the additional disk set, the address,
  gateway and hostname; you compose them into the command you issue, and the harness journals
  that command as sent (`ARC-8`);
- **the machine**, recomputed inside the command that needs it — partition paths, the root
  UUID; never carried from an earlier block.

Two things are not yours to run at all. **Fetching and checking the artifact** and **reading
the installed host keys** are harness jobs you *request* (`ARC-43`): the harness composes the
commands, reads their output from the job record, and compares. You never report a hash or a
key; there is no tool for it.

## Where you start, and where you stop

You are in the vendor's **rescue system** — a Debian live environment — over the pinned
channel. The harness got you here: it registered the session's client key with the vendor,
activated rescue, reset the machine, read the rescue host key from the vendor API and
checked it before connecting. **None of that is yours to redo.** If the channel drops,
reconnect through the harness; do not try to re-pin anything.

You stop when the installed system is on the disk and you have requested `ready_to_reset`.
That job reads the installed host public keys from `/mnt`, journals their fingerprints,
unmounts, and offers the reset to the operator. **You do not reboot and you do not unmount.**
If the installed system does not answer within `installed.wait_max` (`bundle/timing.toml`),
the harness reports unreachability and offers a reinstall (`STG-20`). It first reconciles
unresolved jobs and requires an explicit operator decision to discard the install and erase
the selected disks. A relay outage can look like a boot failure; the timeout never authorizes
running this brief again automatically.

## Step 1 — look before touching anything

```sh
lsblk -dno NAME,SIZE,MODEL,SERIAL,WWN; ls -l /dev/disk/by-id/ | grep -v part; [ -d /sys/firmware/efi ] && echo uefi || echo legacy; ip -4 -o addr show scope global; ip -4 route show default
```

- **Disk names are not stable.** `/dev/sda` in one rescue boot was `/dev/sdb` in the next on
  the same machine. Address disks by `/dev/disk/by-id/wwn-…` and confirm the path is a block
  device before using it. Do not carry an id from another system: `by-id` names differ
  between udev (rescue) and mdev (Alpine) for the same disk; `wwn-` names do not.
- **The rescue's firmware mode says nothing about the target's.** The rescue is PXE-booted
  in legacy mode; this machine booted legacy from disk, and the vendor's virtual console boots
  the same disk under UEFI. Install both bootloaders regardless of what you see here.
- **Addressing is static.** Take the address, prefix and gateway from what the rescue kernel
  is using; there is no DHCP for the installed system to rely on.
- If the disk already holds a partial install, read the **Resume** section before wiping.
- Decide the complete installation disk set by WWN before any write, and state it in your
  next command: the root disk, and the explicitly selected additional disks (or none). Never
  the whole disk list. Every disk you name will be erased. Re-read identities in the rescue
  system immediately before destructive work; do not carry `/dev/sdX` names across reboots.

In the blocks below, `<root-wwn>` is the root disk's `/dev/disk/by-id/wwn-…` path and
`<other-wwn>…` the additional ones, written out literally in the command you issue.

## Step 2 — request `fetch_artifact`

Request the harness job. It downloads the pinned URL to `/tmp/artifact` on this machine,
hashes it, and compares against the bundle's value; a mismatch halts the install (`STG-6`,
`CNF-24`). Do not download the artifact yourself and do not proceed until the job has
succeeded. Alpine serves every release with sibling `.sha256`, `.sha512` and `.asc` at the
same path; only the versioned directory (`v3.24/releases/x86_64/`) is immutable, and only
the bundle's value binds.

## Step 3 — partition, format, mount

GPT with a 1 MiB BIOS-boot partition, a 512 MiB EFI system partition, and the rest as root.
The same layout boots both firmware modes. One block, so the partition paths it computes
are used where they were computed:

```sh
D=<root-wwn>; sgdisk --zap-all "$D" && sgdisk -n1:0:+1M -t1:ef02 -n2:0:+512M -t2:ef00 -n3:0:0 -t3:8300 "$D" && partprobe "$D" && sleep 2 && ESP=$(lsblk -nrpo NAME "$D" | sed -n 3p) && ROOT=$(lsblk -nrpo NAME "$D" | sed -n 4p) && mkfs.vfat -F32 "$ESP" && mkfs.ext4 -F "$ROOT" && mount "$ROOT" /mnt && mkdir -p /mnt/boot/efi && mount "$ESP" /mnt/boot/efi
```

Mounts persist on the machine; shell variables do not. Software RAID across the two disks was
not exercised; a single root on one disk was.

## Step 4 — unpack the root filesystem

```sh
tar -xzf /tmp/artifact -C /mnt && cp /etc/resolv.conf /mnt/etc/ && printf 'https://dl-cdn.alpinelinux.org/alpine/v3.24/main\nhttps://dl-cdn.alpinelinux.org/alpine/v3.24/community\n' > /mnt/etc/apk/repositories && for d in dev proc sys; do mount --rbind /$d /mnt/$d || exit 1; done
```

The repository branch matches the artifact (`bundle/artifact-alpine.toml`). The branch's
signed indexes can change; this is package-signer trust, not a pin of the complete installed
system (`ARC-25a`). Before fetching anything, check the installed keyring against the
bundle's accepted set and never use `--allow-untrusted`:

```sh
sha256sum /mnt/etc/apk/keys/*
```

Compare the output with the fingerprints in `bundle/artifact-alpine.toml` yourself and stop
if any differ; the harness's build has already checked the pinned artifact's keyring against
that list, so a difference here means the unpacked tree is not the pinned one.

## Step 5 — make it a bootable system, not just a root filesystem

A minirootfs boots to a kernel with **no drivers loaded and no network**. The service set
below is what Alpine's own `setup-disk` enables; without `mdev` and `hwdrivers` in `sysinit`
nothing loads drivers by modalias, `eth0` never appears, and `sshd` listens on a machine
nobody can reach. That was one silent failure on this run. `apk` will fetch ~150 packages;
that took about a minute.

```sh
chroot /mnt sh -c 'apk update && apk add alpine-base linux-lts openssh grub grub-bios grub-efi e2fsprogs dosfstools && for s in devfs dmesg mdev hwdrivers; do rc-update add $s sysinit || exit 1; done && for s in hwclock modules sysctl hostname bootmisc syslog networking; do rc-update add $s boot || exit 1; done && rc-update add sshd default && for s in mount-ro killprocs savecache; do rc-update add $s shutdown || exit 1; done && sed -i "s/^#\?rc_logger=.*/rc_logger=\"YES\"/" /etc/rc.conf'
```

Record the repository URLs, index digests, accepted key fingerprints and installed package
versions (`STG-6`): `chroot /mnt sh -c 'apk info -v'` and the `APKINDEX` digests under
`/mnt/var/cache/apk/` or `/mnt/etc/apk/cache/`.

Network, static, from what you read in step 1 — the address in CIDR form, the gateway and
the hostname written literally:

```sh
printf 'auto lo\niface lo inet loopback\n\nauto eth0\niface eth0 inet static\n    address <ip-cidr>\n    gateway <gateway>\n' > /mnt/etc/network/interfaces && echo '<hostname>' > /mnt/etc/hostname
```

`eth0` is the name under Alpine's `mdev`; a system with udev-style names needs the name it
will actually use.

## Step 6 — sshd: keys now, password never

```sh
chroot /mnt sh -c 'mkdir -p /root/.ssh && chmod 700 /root/.ssh && ssh-keygen -A && sed -i "s/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/; s/^#\?PasswordAuthentication.*/PasswordAuthentication no/; s/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/" /etc/ssh/sshd_config'
```

`ssh-keygen -A` generates the host keys **here, before any reboot**; `ready_to_reset` reads
them. Then the session's client public key, which the harness shows you, goes into
`authorized_keys` — written literally, and it is the only key: `STG-13` is tested by sshd
refusing every other one.

```sh
mkdir -p /mnt/root/.ssh && printf '%s\n' '<session-client-public-key>' > /mnt/root/.ssh/authorized_keys && chmod 700 /mnt/root/.ssh && chmod 600 /mnt/root/.ssh/authorized_keys
```

## Step 7 — bootloaders, on every disk, for both firmware modes

```sh
U=$(blkid -s UUID -o value "$(findmnt -no SOURCE /mnt)") && [ -n "$U" ] && chroot /mnt sh -c "printf 'UUID=%s / ext4 defaults 0 1\n' '$U' > /etc/fstab && printf 'GRUB_TIMEOUT=3\nGRUB_TIMEOUT_STYLE=menu\nGRUB_CMDLINE_LINUX_DEFAULT=\"modules=sd-mod,usb-storage,ext4 rootfstype=ext4 console=tty0 console=ttyS0,115200\"\nGRUB_DISABLE_OS_PROBER=true\n' > /etc/default/grub && grub-install --target=i386-pc <root-wwn> && grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=alpine --removable --no-nvram && grub-mkconfig -o /boot/grub/grub.cfg"
```

- The `modules=` kernel arguments are the ones `setup-disk` writes. Without them the
  initramfs did not reach the root filesystem; that was one silent failure on this run.
- `--removable` puts GRUB at `EFI/BOOT/BOOTX64.EFI`, the path firmware tries without an NVRAM
  entry; no NVRAM entry can be written from a rescue, hence `--no-nvram`.
- The serial console line is for the vendor's virtual console, whose screen is otherwise
  black after GRUB; it costs nothing.
- The root UUID is recomputed in the rescue half of the same job (`findmnt` and `blkid` are
  the rescue's; the minirootfs has neither) and passed into the chroot, never carried from an
  earlier block.
- **Each additional selected installation disk gets a BIOS-boot partition and a GRUB core
  image too**, pointing at the same `/boot`, because firmware may enumerate any of them first.
  Run this in rescue, not in the chroot, with `/mnt` still mounted. The root disk is excluded
  by canonical identity even if the same disk appears under another alias. The two
  assignments at the top are part of the same command you issue — the root disk and the
  additional set, one path per line, written literally — and the block validates the whole
  list before the first destructive command:

```sh
DISK=<root-wwn>
OTHER_DISKS='<other-wwn>
<other-wwn>'
(
  set -eu
  root_disk=$(readlink -e -- "$DISK")
  [ -b "$root_disk" ]
  [ "$(lsblk -dnro TYPE "$root_disk")" = disk ]
  selected=$(mktemp)
  trap 'rm -f "$selected"' EXIT
  printf '%s\n' "${OTHER_DISKS:-}" | while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    other=$(readlink -e -- "$candidate") || exit 1
    [ -b "$other" ] || exit 1
    [ "$(lsblk -dnro TYPE "$other")" = disk ] || exit 1
    [ "$other" != "$root_disk" ] || continue
    printf '%s\n' "$other"
  done > "$selected"
  sort -u "$selected" -o "$selected"
  sed 's/^/erasing additional disk: /' "$selected"
  while IFS= read -r other; do
    sgdisk --zap-all "$other"
    sgdisk -n1:0:+1M -t1:ef02 "$other"
    partprobe "$other"
    sleep 1
    chroot /mnt grub-install --target=i386-pc "$other"
  done < "$selected"
)
```

With no additional disks, set `OTHER_DISKS=''` and the block erases nothing.
The protective-MBR boot flag (`parted disk_set pmbr_boot on`) was set once on this run and
turned out **not** to be needed; a later pass without it booted. Do not add it on the
strength of this brief.

## Step 8 — request `ready_to_reset`

Request the harness job. It runs `cat /mnt/etc/ssh/ssh_host_*_key.pub`, derives and journals
the fingerprints, syncs and unmounts `/mnt`, and offers the reset typed operation to the
operator (`STG-4`, `CNF-22`). The harness then resets and connects to the installed system
with those keys and nothing else. On this run the keys on the wire after the reboot were
byte-identical to what was read here. Do not `umount` yourself: a job that unmounts before
the keys are read is exactly the ordering `ready_to_reset` exists to prevent.

## Resume — **unrehearsed**

`ARC-10` and `STG-12` want an interrupted install inspected and continued, not repeated. The
rehearsal never resumed; it only ever wiped. What a resume should look like, untested:

- First reconcile the interrupted job through the harness (`STA-20b`). A live job means
  wait; a missing record means unresolved, not permission to retry or wipe.
- Re-identify disks by WWN and inspect partitions and mount state before changing them.
  Because every block is stateless, a block can be re-issued on its own: if `/mnt` is
  mounted and holds a partial Alpine root, inspect the package, network and boot state and
  re-issue only the blocks whose work is missing. Steps 5–7 as a whole are **not** declared
  idempotent: step 7's additional-disk block erases. Preserve existing host keys; if step 6
  already ran, do not run `ssh-keygen -A` again.
- If evidence cannot establish a safe continuation, stop and surface the unresolved action.
  A reinstall under `STG-20` is a separately recorded operator decision to discard this
  disposable install, with its disk set shown again. A timer or missing file never authorizes it.

## What you will not be able to see

A machine that fails to boot after the reset is invisible: the vendor API says `running`,
nothing answers, no log is readable. That is why every "silent failure" above is in this
brief, and why the harness reinstalls rather than diagnoses. If a brief is wrong in a sixth
way, the operator has the vendor's virtual console, by hand, outside the harness.
