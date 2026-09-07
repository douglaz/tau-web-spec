#!/bin/sh
# Runs INSIDE the Hetzner rescue system (Debian-based), as root, fed by rehearse.sh.
# Installs Alpine onto $DISK from a versioned, hash-checked artifact (ARC-24, ARC-25, CNF-66)
# and prints the installed system's host public keys before any reboot (STG-4, CNF-22).
#
# Recipe status: UNTESTED until the rehearsal runs it. Every step echoes so the transcript shows
# where it diverges from the text; that divergence is a finding, not a failure of the rehearsal.
set -eux

: "${DISK:?set DISK, e.g. /dev/nvme0n1 or /dev/sda}"
: "${AUTHORIZED_KEY:?the operator public key line}"

# ARC-25: a versioned release path (never latest-stable/), and the sibling .sha256 at the same path.
ALPINE_BRANCH=v3.24
ALPINE_VER=3.24.1
ARTIFACT="alpine-minirootfs-${ALPINE_VER}-x86_64.tar.gz"
URL="https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/releases/x86_64/${ARTIFACT}"
# Pinned 2026-09-07 from ${URL}.sha256 — the artifact pin (ADR-0027). If this line and the
# downloaded .sha256 disagree, stop: the versioned path was rewritten, which CNF-66 says cannot happen.
PINNED_SHA256=41f73e3cf5fa919b8aa5ca6b30dc48f0da2720776d7423e2a7748211456fe081

cd /tmp
curl -fsSLO "$URL"; curl -fsSLO "$URL.sha256"
echo "$PINNED_SHA256  $ARTIFACT" | sha256sum -c -
sha256sum -c "$ARTIFACT.sha256"

# One disk, two partitions: 512M ESP/boot, the rest root. Rescue boots BIOS or UEFI depending
# on the model; grub handles both from the same layout.
sgdisk --zap-all "$DISK"
sgdisk -n1:0:+512M -t1:ef00 -n2:0:0 -t2:8300 "$DISK"
partprobe "$DISK"; sleep 2
P1=$(lsblk -nrpo NAME "$DISK" | sed -n 2p); P2=$(lsblk -nrpo NAME "$DISK" | sed -n 3p)
mkfs.vfat -F32 "$P1"; mkfs.ext4 -F "$P2"
mount "$P2" /mnt; mkdir -p /mnt/boot/efi; mount "$P1" /mnt/boot/efi

tar -xzf "$ARTIFACT" -C /mnt
cp /etc/resolv.conf /mnt/etc/
printf 'https://dl-cdn.alpinelinux.org/alpine/%s/main\nhttps://dl-cdn.alpinelinux.org/alpine/%s/community\n' "$ALPINE_BRANCH" "$ALPINE_BRANCH" > /mnt/etc/apk/repositories
for d in dev proc sys; do mount --rbind /$d /mnt/$d; done

chroot /mnt /bin/sh -eux <<'EOF'
apk update
apk add alpine-base linux-lts openssh grub grub-efi grub-bios e2fsprogs dosfstools
rc-update add sshd default; rc-update add networking boot; rc-update add hostname boot
echo tau-rehearsal > /etc/hostname
# Alpine's rescue-side DHCP is the simplest thing that can work; Hetzner dedicated hands out
# static addressing, so the rehearsal records whether DHCP actually came up (a finding).
printf 'auto lo\niface lo inet loopback\nauto eth0\niface eth0 inet dhcp\n' > /etc/network/interfaces
mkdir -p /root/.ssh; chmod 700 /root/.ssh
# ssh-keygen -A makes the host keys NOW, inside rescue, so they can be read before reboot (STG-4).
ssh-keygen -A
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
ROOTDEV=$(findmnt -no SOURCE /)
UUID=$(blkid -s UUID -o value "$ROOTDEV")
printf 'UUID=%s / ext4 defaults 0 1\n' "$UUID" > /etc/fstab
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=alpine --removable || true
grub-install --target=i386-pc "${ROOTDEV%p2}" 2>/dev/null || grub-install --target=i386-pc "${ROOTDEV%2}" || true
grub-mkconfig -o /boot/grub/grub.cfg
EOF
echo "$AUTHORIZED_KEY" > /mnt/root/.ssh/authorized_keys; chmod 600 /mnt/root/.ssh/authorized_keys

echo "=== INSTALLED HOST KEYS (read inside rescue, before reboot) ==="
cat /mnt/etc/ssh/ssh_host_*_key.pub
echo "=== END HOST KEYS ==="
sync
