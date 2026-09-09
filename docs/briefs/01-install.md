# Brief 1 — install

A brief is instructions, not a script (`ARC-9`, ADR-0001): read it, look at the machine, and
decide what to run. The commands here are examples based on the run of 2026-09-08 on a
Hetzner server-auction machine with two SATA SSDs and legacy boot. Where they will differ on
another machine is said. This is a draft written from that one run; it is not yet in the
signed bundle (ADR-0005), and its resume section has never been exercised. The disk-selection
and resume corrections of 2026-09-09 have not been rehearsed on hardware.

## Where you start, and where you stop

You are in the vendor's **rescue system** — a Debian live environment — over the pinned
channel. The harness got you here: it registered the session's client key with the vendor,
activated rescue, reset the machine, read the rescue host key from the vendor API and
checked it before connecting. **None of that is yours to redo.** If the channel drops,
reconnect through the harness; do not try to re-pin anything.

You stop when the installed system is on the disk, its host public keys have been read out
and reported to the harness, and you have said the machine is ready to reset. **You do not
reboot.** The reset is the harness's typed operation, and the harness will check the
installed system's keys against what you reported. If it does not answer within ten minutes,
the harness reports unreachability and offers a reinstall (`STG-20`). It first reconciles
unresolved jobs and requires an explicit operator decision to discard the install and erase
the selected disks. A relay outage can look like a boot failure; the timeout never authorizes
running this brief again automatically.

## What the browser supplies and checks (not the machine)

Two values come from the signed bundle through the harness, and two checks happen there:

- the **artifact URL** — a versioned release path, never a moving alias (`ARC-25`, `CNF-66`)
  — and its **content hash**. You download on the machine; the harness compares the hash you
  report against the bundle's value and halts the install on a mismatch (`STG-6`). The
  sibling `.sha256` at the same path is checked too, but it is the bundle's value that binds.
- the **host-key fingerprints** of the installed system: you report the public keys; the
  harness derives fingerprints and pins them before the reset (`STG-4`, `CNF-22`).

The bundle also supplies the Alpine repository branch and accepted package-signing keys
(`ARC-25a`). The minirootfs hash does not cover packages fetched later. Check the installed
`/etc/apk/keys` against that set before `apk update`; never use `--allow-untrusted`. Record
the repository URLs, index digests, accepted key fingerprints and installed package versions.

Everything else in this brief runs on the machine. The harness owns job tracking, including
the rescue-system exception and reboot handoff in `STA-20b`; never infer that an interrupted
command finished just because its output or job record is missing.

## Step 1 — look before touching anything

```sh
lsblk -dno NAME,SIZE,MODEL,SERIAL,WWN
ls -l /dev/disk/by-id/ | grep -v part
[ -d /sys/firmware/efi ] && echo uefi || echo legacy
ip -4 -o addr show scope global; ip -4 route show default
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
- Select the complete installation disk set by WWN before any write, recording it in the
  transcript. Set `$DISK` to its root disk. `$OTHER_DISKS` is a newline-separated list of
  explicitly selected additional WWN paths, or empty; never populate it with every disk found.
  Every listed disk will be erased. Resolve and re-check identities in the rescue system
  immediately before destructive work; do not carry `/dev/sdX` names across reboots.

## Step 2 — fetch and check the artifact

```sh
cd /tmp
curl -fsSLO "$URL"; curl -fsSLO "$URL.sha256"
sha256sum "$(basename "$URL")"          # report this value to the harness
sha256sum -c "$(basename "$URL").sha256"
```

Report the hash. Do not proceed until the harness confirms it matches the bundle. Alpine
serves every release with sibling `.sha256`, `.sha512` and `.asc` at the same path; only the
versioned directory (`v3.24/releases/x86_64/`) is immutable.

## Step 3 — partition, format, mount

GPT with a 1 MiB BIOS-boot partition, a 512 MiB EFI system partition, and the rest as root.
The same layout boots both firmware modes.

```sh
sgdisk --zap-all "$DISK"
sgdisk -n1:0:+1M -t1:ef02 -n2:0:+512M -t2:ef00 -n3:0:0 -t3:8300 "$DISK"
partprobe "$DISK"; sleep 2
ESP=$(lsblk -nrpo NAME "$DISK" | sed -n 3p); ROOT=$(lsblk -nrpo NAME "$DISK" | sed -n 4p)
mkfs.vfat -F32 "$ESP"; mkfs.ext4 -F "$ROOT"
mount "$ROOT" /mnt; mkdir -p /mnt/boot/efi; mount "$ESP" /mnt/boot/efi
```

Software RAID across the two disks was not exercised; a single root on one disk was.

## Step 4 — unpack the root filesystem and enter it

```sh
tar -xzf "$(basename "$URL")" -C /mnt
cp /etc/resolv.conf /mnt/etc/
printf 'https://dl-cdn.alpinelinux.org/alpine/v3.24/main\nhttps://dl-cdn.alpinelinux.org/alpine/v3.24/community\n' > /mnt/etc/apk/repositories
for d in dev proc sys; do mount --rbind /$d /mnt/$d; done
chroot /mnt /bin/sh
```

Select the repository branch matching the artifact. The branch's signed indexes can change;
this is package-signer trust, not a pin of the complete installed system (`ARC-25a`). `apk`
will fetch ~150 packages; that took about a minute.

## Step 5 — make it a bootable system, not just a root filesystem

A minirootfs boots to a kernel with **no drivers loaded and no network**. The service set
below is what Alpine's own `setup-disk` enables; without `mdev` and `hwdrivers` in `sysinit`
nothing loads drivers by modalias, `eth0` never appears, and `sshd` listens on a machine
nobody can reach. That was one silent failure on this run.

```sh
apk update
apk add alpine-base linux-lts openssh grub grub-bios grub-efi e2fsprogs dosfstools
for s in devfs dmesg mdev hwdrivers; do rc-update add $s sysinit; done
for s in hwclock modules sysctl hostname bootmisc syslog networking; do rc-update add $s boot; done
rc-update add sshd default
for s in mount-ro killprocs savecache; do rc-update add $s shutdown; done
sed -i 's/^#\?rc_logger=.*/rc_logger="YES"/' /etc/rc.conf     # a boot that reaches userland leaves /var/log/rc.log
```

Network, static, from what you read in step 1:

```sh
printf 'auto lo\niface lo inet loopback\n\nauto eth0\niface eth0 inet static\n    address %s\n    gateway %s\n' "$IP_CIDR" "$GATEWAY" > /etc/network/interfaces
echo "$HOSTNAME" > /etc/hostname
```

`eth0` is the name under Alpine's `mdev`; a system with udev-style names needs the name it
will actually use.

## Step 6 — sshd: keys now, password never

```sh
mkdir -p /root/.ssh; chmod 700 /root/.ssh
ssh-keygen -A                                   # host keys are generated HERE, before any reboot
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/; s/^#\?PasswordAuthentication.*/PasswordAuthentication no/; s/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
```

The session's client public key goes into `/root/.ssh/authorized_keys` (mode 600) after you
leave the chroot; the harness supplies it. Only that key: `STG-13` is tested by sshd refusing
every other one.

## Step 7 — bootloaders, on every disk, for both firmware modes

```sh
ROOT_UUID=$(blkid -s UUID -o value "$ROOT")
printf 'UUID=%s / ext4 defaults 0 1\n' "$ROOT_UUID" > /etc/fstab
printf 'GRUB_TIMEOUT=3\nGRUB_TIMEOUT_STYLE=menu\nGRUB_CMDLINE_LINUX_DEFAULT="modules=sd-mod,usb-storage,ext4 rootfstype=ext4 console=tty0 console=ttyS0,115200"\nGRUB_DISABLE_OS_PROBER=true\n' > /etc/default/grub
grub-install --target=i386-pc "$DISK"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=alpine --removable --no-nvram
grub-mkconfig -o /boot/grub/grub.cfg
```

- The `modules=` kernel arguments are the ones `setup-disk` writes. Without them the
  initramfs did not reach the root filesystem; that was one silent failure on this run.
- `--removable` puts GRUB at `EFI/BOOT/BOOTX64.EFI`, the path firmware tries without an NVRAM
  entry; no NVRAM entry can be written from a rescue, hence `--no-nvram`.
- The serial console line is for the vendor's virtual console, whose screen is otherwise
  black after GRUB; it costs nothing.
- **Each additional selected installation disk gets a BIOS-boot partition and a GRUB core
  image too**, pointing at the same `/boot`, because firmware may enumerate any of them first.
  Exit the chroot before this block; run it in rescue, with `/mnt` still mounted. The root
  disk is excluded by canonical identity even if the same disk appears under another alias.
  Validate the entire list before the first destructive command:

```sh
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

The protective-MBR boot flag (`parted disk_set pmbr_boot on`) was set once on this run and
turned out **not** to be needed; a later pass without it booted. Do not add it on the
strength of this brief.

## Step 8 — read out the host keys, hand back

```sh
cat /mnt/etc/ssh/ssh_host_*_key.pub          # report every line to the harness
sync; umount -R /mnt || umount -l /mnt; sync
```

Report the public keys and say the machine is ready to reset. The harness pins the
fingerprints, resets, and connects to the installed system with those keys and nothing else.
On this run the keys on the wire after the reboot were byte-identical to what was read here.

## Resume — **unrehearsed**

`ARC-10` and `STG-12` want an interrupted install inspected and continued, not repeated. The
rehearsal never resumed; it only ever wiped. What a resume should look like, untested:

- First reconcile the interrupted job through the harness (`STA-20b`). A live job means
  wait; a missing record means unresolved, not permission to retry or wipe.
- Re-identify disks by WWN and inspect partitions and mount state before changing them.
  If a partial Alpine root exists, inspect the package, network and boot state and perform
  only missing work. Steps 5–7 as a whole are **not** declared idempotent: step 7 can erase
  additional disks. Preserve existing host keys and read them back before the handoff.
- If evidence cannot establish a safe continuation, stop and surface the unresolved action.
  A reinstall under `STG-20` is a separately recorded operator decision to discard this
  disposable install, with its disk set shown again. A timer or missing file never authorizes it.

## What you will not be able to see

A machine that fails to boot after the reset is invisible: the vendor API says `running`,
nothing answers, no log is readable. That is why every "silent failure" above is in this
brief, and why the harness reinstalls rather than diagnoses. If a brief is wrong in a sixth
way, the operator has the vendor's virtual console, by hand, outside the harness.
