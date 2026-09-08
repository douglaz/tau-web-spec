#!/bin/sh
# Runs INSIDE the Hetzner rescue system (Debian-based), as root, fed by rehearse.sh.
# Installs Alpine onto $DISK from a versioned, hash-checked artifact (ARC-24, ARC-25, CNF-66)
# and prints the installed system's host public keys before any reboot (STG-4, CNF-22).
#
# Recipe status: first run 2026-09-08 on an auction i7-6700 (BIOS boot, static addressing).
# Every step echoes so the transcript shows where it diverges from the text; that divergence is
# a finding, not a failure of the rehearsal.
set -eux

: "${DISK:?set DISK — prefer a stable /dev/disk/by-id/ path; /dev/sdX names swap between boots}"
DISK=$(readlink -f "$DISK")
: "${AUTHORIZED_KEY:?the operator public key line}"

# ARC-25: a versioned release path (never latest-stable/), and the sibling .sha256 at the same path.
ALPINE_BRANCH=v3.24
ALPINE_VER=3.24.1
ARTIFACT="alpine-minirootfs-${ALPINE_VER}-x86_64.tar.gz"
URL="https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/releases/x86_64/${ARTIFACT}"
# Pinned 2026-09-07 from ${URL}.sha256 — the artifact pin (ADR-0027). If this line and the
# downloaded .sha256 disagree, stop: the versioned path was rewritten, which CNF-66 says cannot happen.
PINNED_SHA256=41f73e3cf5fa919b8aa5ca6b30dc48f0da2720776d7423e2a7748211456fe081

# Hetzner dedicated addressing is static; take exactly what the rescue kernel is using.
IP_CIDR=$(ip -4 -o addr show dev eth0 scope global | awk '{print $4}' | head -1)
GATEWAY=$(ip -4 route show default | awk '{print $3}' | head -1)
FIRMWARE=$([ -d /sys/firmware/efi ] && echo uefi || echo bios)
echo "addressing: $IP_CIDR via $GATEWAY; firmware: $FIRMWARE"

cd /tmp
curl -fsSLO "$URL"; curl -fsSLO "$URL.sha256"
echo "$PINNED_SHA256  $ARTIFACT" | sha256sum -c -
sha256sum -c "$ARTIFACT.sha256"

# GPT with a 1M BIOS-boot partition (GRUB i386-pc on GPT needs it), a 512M ESP so the same
# layout also boots UEFI machines, and the rest as root.
sgdisk --zap-all "$DISK"
sgdisk -n1:0:+1M -t1:ef02 -n2:0:+512M -t2:ef00 -n3:0:0 -t3:8300 "$DISK"
partprobe "$DISK"; sleep 2
ESP=$(lsblk -nrpo NAME "$DISK" | sed -n 3p); ROOT=$(lsblk -nrpo NAME "$DISK" | sed -n 4p)
mkfs.vfat -F32 "$ESP"; mkfs.ext4 -F "$ROOT"
mount "$ROOT" /mnt; mkdir -p /mnt/boot/efi; mount "$ESP" /mnt/boot/efi

tar -xzf "$ARTIFACT" -C /mnt
cp /etc/resolv.conf /mnt/etc/
printf 'https://dl-cdn.alpinelinux.org/alpine/%s/main\nhttps://dl-cdn.alpinelinux.org/alpine/%s/community\n' "$ALPINE_BRANCH" "$ALPINE_BRANCH" > /mnt/etc/apk/repositories
for d in dev proc sys; do mount --rbind /$d /mnt/$d; done

ROOT_UUID=$(blkid -s UUID -o value "$ROOT")
chroot /mnt /usr/bin/env DISK="$DISK" ROOT_UUID="$ROOT_UUID" IP_CIDR="$IP_CIDR" GATEWAY="$GATEWAY" FIRMWARE="$FIRMWARE" /bin/sh -eux <<'EOF'
apk update
apk add alpine-base linux-lts openssh grub grub-bios grub-efi e2fsprogs dosfstools
rc-update add sshd default; rc-update add networking boot; rc-update add hostname boot
echo tau-rehearsal > /etc/hostname
printf 'auto lo\niface lo inet loopback\n\nauto eth0\niface eth0 inet static\n    address %s\n    gateway %s\n' "$IP_CIDR" "$GATEWAY" > /etc/network/interfaces
mkdir -p /root/.ssh; chmod 700 /root/.ssh
# ssh-keygen -A makes the host keys NOW, inside rescue, so they can be read before reboot (STG-4).
ssh-keygen -A
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
printf 'UUID=%s / ext4 defaults 0 1\n' "$ROOT_UUID" > /etc/fstab
# BOTH bootloaders, always. Found 2026-09-08: the rescue system is PXE-booted in legacy mode,
# so /sys/firmware/efi says nothing about the target's own firmware — which was UEFI, found no
# EFI bootloader, and fell through to PXE three times. --removable puts GRUB at
# EFI/BOOT/BOOTX64.EFI, the path firmware tries without an NVRAM entry (none can be written
# from a rescue); --no-nvram because efibootmgr has nothing to write to here.
grub-install --target=i386-pc "$DISK"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=alpine --removable --no-nvram
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# Found 2026-09-08: /dev/sdX names are NOT stable across boots on this hardware, and the BIOS
# boots whichever disk it enumerates first. The first run put GRUB on one disk only and the
# machine never booted. So: a BIOS-boot partition and GRUB on EVERY other disk too, as
# Hetzner's own installer does, all pointing at the same /boot.
for other in $(lsblk -dnpo NAME,TYPE | awk '$2=="disk"{print $1}' | grep -vx "$DISK"); do
  sgdisk --zap-all "$other"; sgdisk -n1:0:+1M -t1:ef02 "$other"; partprobe "$other"; sleep 1
  chroot /mnt grub-install --target=i386-pc "$other"
done
echo "$AUTHORIZED_KEY" > /mnt/root/.ssh/authorized_keys; chmod 600 /mnt/root/.ssh/authorized_keys

echo "=== INSTALLED HOST KEYS (read inside rescue, before reboot) ==="
cat /mnt/etc/ssh/ssh_host_*_key.pub
echo "=== END HOST KEYS ==="
sync
