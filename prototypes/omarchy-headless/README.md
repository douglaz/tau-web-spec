# Omarchy over SSH on a headless Arch VM — route C (T41, OPN-25)

**PROTOTYPE — throwaway.** Not harness code. Answers one question: can Omarchy's packages plus
the ISO's two setup commands be driven over SSH on Arch's cloud image, and does the machine come
back after a reboot answering with the host key pinned before the install? Step list and
expected failure points: `docs/findings/2026-10-08-omarchy-headless-research.md` §5. Result:
`docs/findings/2026-10-08-omarchy-route-c-prototype.md`.

## Run

```sh
./run.sh all        # fetch, boot, pin, step3..step7, reboot, after, hermes, collect
./run.sh stop       # ssh poweroff, else kill only the recorded qemu PID
```

Needs `nix`, `ssh`, `gpg`, and `/dev/kvm`; QEMU, OVMF and `cloud-localds` come from nixpkgs.
Everything lands in `$W` (default `/var/tmp/omarchy-proto`); delete it afterwards. `PORT`
(default 2247) is the host-side forward to the guest's port 22. `VARIANT=virtio-vga ./run.sh boot`
relaunches the same disk with upstream's display adapter; `./run.sh up` waits for SSH over the
original pin. `./run.sh lockout` (last, optional) drops the SSH rule and reboots.

Long guest steps run detached in the guest; a step that is still running after `POLL` seconds
(default 540) exits 75, and rerunning the same step resumes polling.

## What it does

1. `fetch`: the arch-boxes cloud image, checked against its `.SHA256` and its `.sig` (key taken
   from arch-boxes' README).
2. `boot`: 40G qcow2 overlay, OVMF with a writable VARS file, a NoCloud seed with the operator's
   key and a fixed `instance-id`, no display adapter, serial console to a file.
3. `pin`: the host-key fingerprints cloud-init prints on the serial console are the pin (the
   stand-in for attest). `known_hosts` holds only presented keys whose fingerprint is on the
   console; every connection uses `StrictHostKeyChecking=yes` against it.
4. `step3`–`step7`: Omarchy's mirrorlist and `[omarchy]` section, its keyring, the packages,
   the user, `omarchy-apply-system`, `omarchy-provision-user`, `ufw allow ssh`. `state` prints
   packages, `/boot`, `/efi`, EFI entries, pacman hooks, unit states and ufw after steps 4 and 6.
5. `reboot`, `after`: reconnect over the pin only; record loader, failed units, network,
   firewall, and `pacman -Syu`. `hermes`: upstream's installer and gateway as a lingering user
   service. `step6r` is a recorded deviation, used only because step 6's second command failed.
