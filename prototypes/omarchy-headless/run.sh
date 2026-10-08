#!/usr/bin/env bash
# PROTOTYPE — throwaway. Route C for OPN-25 (T41): Omarchy's packages on Arch's cloud image,
# driven only over SSH, then a reboot that must answer with the host key pinned before the
# install. Step list: docs/findings/2026-10-08-omarchy-headless-research.md §5. See README.md.
set -euo pipefail
W=${W:-/var/tmp/omarchy-proto}           # everything (image, overlay, keys, logs) lives here
PORT=${PORT:-2247}                       # host-side forward to the guest's port 22
VARIANT=${VARIANT:-novga}                # novga (the VPS case) | virtio-vga (upstream's test)
IMG=${IMG:-Arch-Linux-x86_64-cloudimg-20261001.604814.qcow2}
IMG_URL=https://geo.mirror.pkgbuild.com/images/latest
OMARCHY_KEY=40DFB630FF42BCFFB047046CF0134EE680CAC571   # omarchy-upgrade-to-quattro:456
U=owner                                  # the Omarchy install user (step 5)
KH=$W/known_hosts; SER=$W/logs/serial.log; PIDF=$W/qemu.pid
mkdir -p "$W/logs" "$W/img"

ssh_base=(ssh -i "$W/id_ed25519" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10
  -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$KH" -o GlobalKnownHostsFile=/dev/null
  -o HostKeyAlias=omarchy-proto -p "$PORT")
g() { "${ssh_base[@]}" arch@127.0.0.1 "$@"; }       # as the image's default user (sudo, no password)
gu() { "${ssh_base[@]}" "$U@127.0.0.1" "$@"; }      # as the Omarchy user
hr() { printf '\n===== %s\n' "$*"; }

tools() {  # qemu, OVMF and cloud-localds from nixpkgs; nothing installed on the host
  local p; p=$(nix build --no-link --print-out-paths nixpkgs#qemu nixpkgs#OVMF.fd nixpkgs#cloud-utils)
  QEMU=$(grep -- '-qemu-' <<<"$p")/bin/qemu-system-x86_64
  OVMF=$(grep -- '-OVMF-' <<<"$p")/FV
  LOCALDS=$(grep -- '-cloud-utils-' <<<"$p")/bin/cloud-localds
  echo "qemu: $QEMU"; echo "ovmf: $OVMF"
}

running() { [ -s "$PIDF" ] && grep -qF -- "$W" "/proc/$(cat "$PIDF")/cmdline" 2>/dev/null; }

fetch() {  # the image, its .SHA256 and .sig; the signing key comes from arch-boxes' README
  cd "$W/img"
  for f in "$IMG.SHA256" "$IMG.sig"; do [ -s "$f" ] || curl -fsSLO "$IMG_URL/$f"; done
  [ -s "$IMG" ] || curl -fsSLO "$IMG_URL/$IMG"
  hr "sha256"; sha256sum -c "$IMG.SHA256"
  curl -fsSL https://gitlab.archlinux.org/archlinux/arch-boxes/-/raw/master/README.md |
    sed -n '/BEGIN PGP PUBLIC KEY BLOCK/,/END PGP PUBLIC KEY BLOCK/p' > arch-boxes.asc
  mkdir -p -m 700 "$W/gnupg"
  gpg --homedir "$W/gnupg" -q --import arch-boxes.asc
  hr "signature (key taken from arch-boxes README.md)"; gpg --homedir "$W/gnupg" --verify "$IMG.sig" "$IMG"
}

boot() {  # start the guest daemonized; first call creates the 40G overlay, VARS, seed and keypair
  running && { echo "guest already running, pid $(cat "$PIDF")"; return; }
  local avail; avail=$(awk '/MemAvailable/ {print int($2/1048576)}' /proc/meminfo)
  echo "MemAvailable ${avail} GiB"; [ "$avail" -ge 12 ] || { echo "below 12 GiB, refusing"; exit 1; }
  ss -ltn | grep -q ":$PORT\b" && { echo "port $PORT taken"; exit 1; }
  tools
  [ -f "$W/id_ed25519" ] || ssh-keygen -q -t ed25519 -N '' -C omarchy-proto-operator -f "$W/id_ed25519"
  [ -f "$W/disk.qcow2" ] || "$(dirname "$QEMU")/qemu-img" create -q -f qcow2 -F qcow2 -b "$W/img/$IMG" "$W/disk.qcow2" 40G
  [ -f "$W/vars.fd" ] || install -m 644 "$OVMF/OVMF_VARS.fd" "$W/vars.fd"   # persistent NVRAM: boot entries survive reboots
  if [ ! -f "$W/seed.img" ]; then  # NoCloud; fixed instance-id so cloud-init never regenerates host keys
    printf 'instance-id: omarchy-proto-1\nlocal-hostname: omarchy-proto\n' > "$W/meta-data"
    printf '#cloud-config\nssh_authorized_keys:\n  - %s\n' "$(cat "$W/id_ed25519.pub")" > "$W/user-data"
    "$LOCALDS" "$W/seed.img" "$W/user-data" "$W/meta-data"
  fi
  local display=(-vga none -display none)
  [ "$VARIANT" = virtio-vga ] && display=(-vga none -device virtio-vga -display none)
  echo "--- boot $(date -u +%FT%TZ) variant=$VARIANT" >> "$W/logs/boots.log"
  "$QEMU" -name omarchy-proto -machine q35 -enable-kvm -cpu host -m 4096 -smp 2 \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF/OVMF_CODE.fd" \
    -drive if=pflash,format=raw,file="$W/vars.fd" \
    -drive if=virtio,format=qcow2,file="$W/disk.qcow2" \
    -drive if=virtio,format=raw,file="$W/seed.img" \
    -nic user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:"$PORT"-:22 \
    "${display[@]}" -serial file:"$SER.$VARIANT.$(date -u +%H%M%S)" \
    -daemonize -pidfile "$PIDF"
  ln -sf "$(ls -t "$SER".* | head -1)" "$SER"
  echo "qemu pid $(cat "$PIDF"), serial $(readlink "$SER")"
}

pin() {  # STAND-IN FOR ATTEST: fingerprints from the serial console only; known_hosts holds only matching keys
  local i fps line fp n=0
  for i in $(seq 120); do grep -q 'END SSH HOST KEY FINGERPRINTS' "$SER" && break; sleep 5; done
  fps=$(sed -n '/BEGIN SSH HOST KEY FINGERPRINTS/,/END SSH HOST KEY FINGERPRINTS/p' "$SER" | tr -d '\r' | grep -o 'SHA256:[A-Za-z0-9+/]*' || true)
  hr "fingerprints printed by cloud-init on the serial console"; sed -n '/BEGIN SSH HOST KEY FINGERPRINTS/,/END SSH HOST KEY FINGERPRINTS/p' "$SER" | tr -d '\r'
  [ -n "$fps" ] || { echo "no fingerprints on the serial console; refusing to connect"; exit 1; }
  printf '%s\n' "$fps" > "$W/logs/pin-fingerprints.txt"
  for i in $(seq 60); do ssh-keyscan -T 5 -p "$PORT" 127.0.0.1 > "$W/logs/keyscan-pin.txt" 2>/dev/null && [ -s "$W/logs/keyscan-pin.txt" ] && break; sleep 5; done
  : > "$KH"
  while read -r _ line; do
    fp=$(printf 'x %s\n' "$line" | ssh-keygen -lf /dev/stdin | awk '{print $2}')
    if grep -qxF "$fp" <<<"$fps"; then echo "omarchy-proto $line" >> "$KH"; n=$((n+1)); echo "pinned  $fp"
    else echo "REFUSED $fp (presented, not on the console)"; fi
  done < <(grep -v '^#' "$W/logs/keyscan-pin.txt")
  [ "$n" -gt 0 ] || { echo "no presented key matched the pin"; exit 1; }
  hr "first contact over the pin"; g 'echo PINNED-LOGIN-OK; uname -r; cat /var/lib/cloud/data/instance-id; df -h /; findmnt -no SOURCE,FSTYPE / /efi; cat /proc/cmdline'
  hr "boot state before anything is installed"; g sudo bash -s < <(declare -f state; echo state) | tee "$W/logs/state-0-before.txt"
}

state() {  # runs IN THE GUEST as root: what the bootloader, network and firewall look like now
  echo "== packages"; pacman -Q omarchy omarchy-settings omarchy-keyring omarchy-nvim linux grub mkinitcpio limine limine-mkinitcpio-hook limine-snapper-sync limine-entry-tool snapper efibootmgr networkmanager ufw sddm openssh cloud-init 2>&1; echo "total: $(pacman -Q | wc -l)"
  echo "== kernel image vs modules"; file -bL /boot/vmlinuz-linux 2>&1 | grep -o 'version [^ ]*' || echo "no /boot/vmlinuz-linux"; ls /usr/lib/modules; uname -r
  echo "== /boot"; find /boot -maxdepth 2 -not -path '/boot/grub/*/*' -printf '%TY-%Tm-%Td %TH:%TM %10s %p\n' | sort -k4 | grep -v '/boot/grub/[a-z0-9_-]*/' | head -40
  echo "== /efi"; find /efi -printf '%TY-%Tm-%Td %TH:%TM %10s %p\n' | sort -k4
  echo "== grub.cfg kernels"; grep -E '^\s*(linux|initrd)\s' /boot/grub/grub.cfg | sort -u | head
  echo "== limine config"; ls -la /etc/default/limine /etc/kernel/cmdline /boot/limine.conf /efi/limine.conf /efi/EFI/limine /efi/EFI/BOOT 2>&1
  echo "== initramfs vs linux install (pacman.log)"; grep -E '\] (installed|upgraded) (linux|limine|mkinitcpio) ' /var/log/pacman.log | tail -4
  echo "== EFI boot entries"; if command -v efibootmgr >/dev/null; then efibootmgr; else echo "efibootmgr not installed"; fi
  echo "== mkinitcpio/limine pacman hooks"; ls /usr/share/libalpm/hooks /etc/pacman.d/hooks 2>/dev/null | grep -iE 'mkinitcpio|limine|grub|omarchy|snap' | sort -u
  echo "== units"; for u in sshd systemd-networkd systemd-networkd-wait-online NetworkManager systemd-resolved sddm ufw docker.socket cloud-init-main cloud-init-local cloud-final; do printf '%-32s %-10s %s\n' "$u" "$(systemctl is-enabled $u 2>&1 | head -1)" "$(systemctl is-active $u 2>&1 | head -1)"; done
  echo "== /etc/systemd/network"; ls /etc/systemd/network 2>&1
  echo "== ufw"; ufw status verbose 2>&1 | head -20; grep ENABLED /etc/ufw/ufw.conf 2>/dev/null; echo "-- ufw show added"; ufw show added 2>&1; true
}

# A long job in the guest: started once, detached from ssh, exit code written beside its log.
# Rerunning the same step only polls. Exits 75 if still running after POLL seconds.
job() {  # job <name> <root|user> <script on stdin>
  local name=$1 who=$2 run=g pfx=sudo log=/var/tmp/proto-$1.log ex=/var/tmp/proto-$1.exit t=0
  [ "$who" = user ] && { run=gu; pfx=; }
  if ! $run "test -e $log" </dev/null; then
    $run "cat > /var/tmp/proto-$name.sh"
    $run "$pfx setsid nohup bash -c 'bash /var/tmp/proto-$name.sh; echo \$? > $ex' > $log 2>&1 < /dev/null &" </dev/null
    echo "started $name"
  else cat > /dev/null; fi
  exec </dev/null   # every ssh below must not eat the caller's stdin
  until $run "test -e $ex"; do
    t=$((t+20)); [ "$t" -gt "${POLL:-540}" ] && { $run "tail -3 $log"; echo "STILL RUNNING: rerun this step to keep polling"; exit 75; }
    sleep 20; $run "tail -1 $log" | cut -c1-160
  done
  $run "cat $log" > "$W/logs/job-$name.log"
  echo "job $name exit $($run "cat $ex") (full log: logs/job-$name.log)"; tail -25 "$W/logs/job-$name.log"
}

step3() {  # pacman at Omarchy's sources: mirrorlist-stable, and pacman-stable.conf's [omarchy] section verbatim
  job step3 root <<EOF
set -x
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.arch-boxes
printf '%s\n' 'Server = https://stable-mirror.omarchy.org/\$repo/os/\$arch' > /etc/pacman.d/mirrorlist
printf '\n%s\n%s\n' '[omarchy]' 'Server = https://pkgs.omarchy.org/stable/\$arch' >> /etc/pacman.conf
pacman-conf SigLevel; pacman-conf --repo omarchy
pacman-key --list-keys | grep -c '^pub'
# omarchy-upgrade-to-quattro:452-459, verbatim in effect: keyring packages first, the fingerprint fallback on failure
if pacman -Syy --noconfirm archlinux-keyring omarchy-keyring; then echo KEYRING-PACKAGE-PATH
else echo KEYRING-FALLBACK-PATH
  pacman-key --recv-keys $OMARCHY_KEY --keyserver keys.openpgp.org || true
  pacman-key --lsign-key $OMARCHY_KEY || true
  pacman -Syy --noconfirm archlinux-keyring omarchy-keyring
fi
pacman-key --finger $OMARCHY_KEY
EOF
}

step4() {  # the core packages then the base list (omarchy-upgrade-to-quattro:804-813), guard bypassed as that script does
  job step4 root <<'EOF'
set -x
export OMARCHY_UPDATE_PACMAN=1
pacman -Syu --needed --noconfirm --ask 4 --overwrite='*' omarchy-keyring omarchy-settings omarchy-nvim omarchy
mapfile -t base < <(sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' /usr/share/omarchy/install/omarchy-base.packages)
echo "base list: ${#base[@]} packages"
pacman -S --needed --noconfirm --ask 4 --overwrite='*' "${base[@]}"
EOF
  hr "state after step 4 (failure point 1)"; g sudo bash -s < <(declare -f state; echo state) | tee "$W/logs/state-4.txt"
}

step5() {  # the user: useradd -m, wheel, a sudo rule (no password exists), the operator's key
  g sudo bash -s <<EOF
set -ex
useradd -m -G wheel $U
printf '%s\n' '$U ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/90-$U; chmod 440 /etc/sudoers.d/90-$U
install -d -m 700 -o $U -g $U /home/$U/.ssh
printf '%s\n' '$(cat "$W/id_ed25519.pub")' > /home/$U/.ssh/authorized_keys
chown $U:$U /home/$U/.ssh/authorized_keys; chmod 600 /home/$U/.ssh/authorized_keys
id $U; ls -A /home/$U
EOF
  gu 'echo USER-LOGIN-OK; id'
}

step6() {  # the ISO's two commands; the second over ssh as the user (a real session, not the ISO's chroot)
  job step6a root <<EOF
omarchy-apply-system --install-user $U --first-install; rc=\$?
grep -E 'Failed:|Completed:' /var/log/omarchy-install.log | tail -60; exit \$rc
EOF
  job step6b user <<'EOF'
omarchy-provision-user --force --first-install
EOF
  g sudo cat /var/log/omarchy-install.log > "$W/logs/omarchy-install.log" || true
  hr "state after step 6"; g sudo bash -s < <(declare -f state; echo state) | tee "$W/logs/state-6.txt"
}

# DEVIATION, run only after step6b failed: --first-install forces the ISO-chroot context, whose
# mise-work.sh demands the ISO's bundled Node tarball in /opt/packages. The documented
# runtime form (--force alone) takes Node from the network instead.
step6r() {
  job step6r user <<'EOF'
omarchy-provision-user --force
EOF
}

step7() { g 'sudo ufw allow ssh; sudo ufw show added; grep ENABLED /etc/ufw/ufw.conf'; }

reboot_() {  # step 8: reboot from inside (same QEMU process, same NVRAM); reconnect against the pin ONLY
  local t0 i fp
  g 'cat /var/lib/cloud/data/instance-id' > "$W/logs/instance-id-before.txt"
  t0=$(date +%s); g 'sudo systemctl reboot' || true
  sleep 15
  for i in $(seq 90); do
    if g true 2>"$W/logs/ssh-after-reboot.err"; then echo "SSH answered $(( $(date +%s)-t0 )) s after reboot, over the pre-install pin: SAME KEY"; break; fi
    grep -q 'REMOTE HOST IDENTIFICATION HAS CHANGED\|Host key verification failed' "$W/logs/ssh-after-reboot.err" && { echo "HOST KEY CHANGED"; cat "$W/logs/ssh-after-reboot.err"; break; }
    sleep 10
  done
  ssh-keyscan -T 5 -p "$PORT" 127.0.0.1 2>/dev/null | grep -v '^#' > "$W/logs/keyscan-after.txt" || true
  hr "fingerprints presented after reboot vs pin"
  while read -r _ line; do fp=$(printf 'x %s\n' "$line" | ssh-keygen -lf /dev/stdin | awk '{print $2}')
    grep -qxF "$fp" "$W/logs/pin-fingerprints.txt" && echo "same  $fp" || echo "NEW   $fp"; done < "$W/logs/keyscan-after.txt"
  [ -s "$W/logs/keyscan-after.txt" ] || { echo "port 22 not answering; serial tail:"; tail -40 "$SER" | tr -d '\r'; }
}

after() {  # what came back
  g sudo bash -s <<'EOF' | tee "$W/logs/after.txt"
echo "== instance-id"; cat /var/lib/cloud/data/instance-id
echo "== is-system-running"; systemctl is-system-running
echo "== failed"; systemctl --failed --no-legend
echo "== cmdline (GRUB sets BOOT_IMAGE)"; cat /proc/cmdline
echo "== loader efivars"; for v in /sys/firmware/efi/efivars/Loader{Info,EntrySelected}-*; do [ -e "$v" ] && printf '%s: %s\n' "${v##*/}" "$(tail -c +5 "$v" | tr -d '\0')"; done
echo "== BootCurrent"; command -v efibootmgr >/dev/null && efibootmgr | head -3
echo "== network"; systemctl is-active NetworkManager systemd-networkd; nmcli -t device 2>&1; ip -br a; resolvectl dns 2>&1 | head -3; getent hosts archlinux.org
echo "== ufw"; ufw status verbose
echo "== sddm"; systemctl status sddm --no-pager -n 8 2>&1 | tail -10
echo "== cloud-init"; cloud-init status --long 2>&1 | head -8
echo "== hermes gateway (lingering user service)"; systemctl --user -M owner@ is-active hermes-gateway.service 2>&1
echo "== graphics"; ls /dev/dri 2>&1; loginctl seat-status seat0 2>&1 | grep -iE 'drm|graphics|fb' | head -5; loginctl list-sessions --no-legend
echo "== pacman -Syu (no override)"; pacman -Syu --noconfirm 2>&1 | tail -25; echo "pacman exit ${PIPESTATUS[0]}"
EOF
}

hermes() {  # the scenario's application, with its own installer, as the ordinary user
  g "sudo loginctl enable-linger $U"
  job hermes user <<'EOF'
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
EOF
  # Found 2026-10-08: provision-user's mise.sh leaves an Omarchy stub at ~/.local/bin/hermes
  # (omarchy-install-hermes-cli) that the upstream installer does not replace, so a bare
  # `hermes` is Omarchy's mise-built copy. Name upstream's binary explicitly.
  gu 'H=$HOME/.hermes/hermes-agent/.hermes/bin/hermes; export PATH=$HOME/.local/bin:$PATH
      echo "== which hermes"; type -a hermes; head -3 ~/.local/bin/hermes
      echo "== upstream"; $H --version | head -3
      timeout 120 $H gateway install --force </dev/null; echo "gateway install exit $?"
      systemctl --user daemon-reload; systemctl --user restart hermes-gateway.service   # install does not restart a running one
      sleep 20; systemctl --user cat hermes-gateway.service | grep ExecStart=
      systemctl --user status hermes-gateway.service --no-pager -n 25
      loginctl show-user '"$U"' -p Linger' 2>&1 | tee "$W/logs/hermes-gateway.txt"
}

up() {  # after a relaunch (boot with an existing disk): wait for SSH over the original pin, nothing else
  local i; for i in $(seq 60); do g 'echo PINNED-LOGIN-OK' 2>/dev/null && return; sleep 5; done
  echo "no pinned SSH after 5 min"; tail -20 "$SER" | tr -d '\r'; exit 1
}

lockout() {  # optional, last: drop the ssh rule, reboot, port 22 should stop answering
  g 'sudo ufw delete allow ssh; sudo systemctl reboot' || true
  sleep 90; local i
  for i in $(seq 12); do if g true 2>/dev/null; then echo "SSH ANSWERED: no lockout"; return; fi; sleep 10; done
  echo "no SSH answer 3 min after reboot without the rule: locked out"; tail -5 "$SER" | tr -d '\r'
}

collect() { g 'sudo cat /var/log/pacman.log' > "$W/logs/pacman.log" 2>/dev/null || true; }

stop() {  # poweroff over ssh; if the guest does not exit, kill ONLY the recorded qemu PID
  running || { echo "not running"; return; }
  local pid; pid=$(cat "$PIDF")
  g 'sudo systemctl poweroff' 2>/dev/null || true
  for _ in $(seq 24); do kill -0 "$pid" 2>/dev/null || { echo "guest stopped"; return; }; sleep 5; done
  grep -qF -- "$W" "/proc/$pid/cmdline" && kill "$pid" && echo "killed qemu pid $pid"
}

step=${1:-}; shift || true
case "$step" in
  fetch|boot|up|pin|step3|step4|step5|step6|step6r|step7|after|hermes|lockout|collect|stop) "$step" "$@";;
  reboot) reboot_;;
  all) fetch; boot; pin; step3; step4; step5; step6; step6r; step7; reboot_; after; hermes; collect;;  # step6r: the deviation, see the finding
  *) echo "usage: $0 fetch|boot|up|pin|step3|step4|step5|step6|step6r|step7|reboot|after|hermes|lockout|collect|stop|all"; exit 2;;
esac 2>&1 | tee -a "$W/logs/run-$step.log"
exit "${PIPESTATUS[0]}"
