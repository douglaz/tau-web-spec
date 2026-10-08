# Findings — Omarchy route C, run once in a headless VM (`OPN-25`, T41)

Date: 2026-10-08. Script: `prototypes/omarchy-headless/run.sh`. Step list and expected failure
points: `2026-10-08-omarchy-headless-research.md` §5. One disposable QEMU guest on KVM, user-mode
networking, no display adapter; then the same disk relaunched once with `-device virtio-vga`.

**Verdict: passes, with one deviation at step 6.** Over SSH only, Omarchy's packages and the
ISO's root-side command installed on Arch's cloud image, and after the reboot SSH answered with
the **same** host keys pinned from the serial console before the install: all three
fingerprints matched, with no trust-on-first-use. The ISO's user-side command,
`omarchy-provision-user --force --first-install`, **failed** (exit 1) because it needs a file
only the ISO carries. Its runtime form, `omarchy-provision-user --force`, completed and was used
instead. Everything after that ran on a system its maintainers do not support.

## Versions

- Image: `Arch-Linux-x86_64-cloudimg-20261001.604814.qcow2`. Its `.SHA256` matched, and its
  `.sig` verified good against the arch-boxes key printed in arch-boxes' `README.md` (primary
  `1B9A16984A4E8CB448712D2AE0B78BF4326C6F8F`, signing subkey
  `656E4C5AC1CC3B86E539D97E343635A6859A9174`). The key was taken from the README, and nothing
  certifies it beyond that. Kernel `linux 7.2.7.arch1-1`, `grub 2:2.16-1`, `cloud-init 26.2`.
- Omarchy: `omarchy 4.0.4-1`, `omarchy-settings 4.0.4-1`, `omarchy-keyring 20251027-1`,
  `omarchy-nvim 2026.8.13-1`, `limine 12.8.0-1`, `limine-mkinitcpio-hook 1.38.0-1.1`,
  `limine-snapper-sync 1.31.0-1.1`, `snapper 0.13.1-3`. 916 packages installed in total.
- Hermes: upstream installer, `main` at `a28a5d03a9` ("v0.21.5+9141.ga28a5d0").
- Host side: QEMU 10.2.4 and OVMF 202602 from nixpkgs. The guest had 4 GiB of memory, 2 vCPUs,
  q35, a 40G overlay, and a writable OVMF VARS file kept across reboots.

## Steps, observed

1. **Boot, pin.** cloud-init printed `BEGIN SSH HOST KEY FINGERPRINTS` on ttyS0 with ECDSA,
   ED25519 and RSA fingerprints. The block of full keys it printed after them was empty. All
   three keys presented on the wire matched the console, and `known_hosts` held only those keys.
   The root filesystem had grown to 40G. GRUB booted through the fallback path
   `/efi/EFI/BOOT/BOOTX64.EFI`, and `/efi` is an autofs mount over the vfat ESP.
2. **Pacman sources.** `mirrorlist-stable` and `[omarchy]` were copied verbatim, with no
   `SigLevel` override, so the repository inherits the image's `Required DatabaseOptional`.
   Installing the keyring package first failed: "signature from "Omarchy <pkgs@omarchy.org>" is
   unknown trust". The fallback path ran (`--recv-keys` from keys.openpgp.org, then
   `--lsign-key 40DFB630FF42BCFFB047046CF0134EE680CAC571`) and the retry succeeded. Omarchy's
   stable mirror is **older than the image**. It downgraded `archlinux-keyring`
   (20260909 → 20260902), and after the install `pacman -Syu` reported 24 local packages newer
   than the repositories (for example `linux` 7.2.7 local against 7.2.3 in the mirror, and
   `systemd` 262 against 261.2).
3. **Packages** (`-Syu` with the four core packages, then the 158-entry base list, with
   `OMARCHY_UPDATE_PACMAN=1`). Both transactions exited 0.
4. **User.** Created with `useradd -m -G wheel`, a `NOPASSWD` sudo rule (the user has no
   password) and the operator's key.
5. **`omarchy-apply-system --install-user owner --first-install`**: exit 0. Every script in
   `/var/log/omarchy-install.log` completed, with no `Failed:` line.
   **`omarchy-provision-user --force --first-install`**, run over SSH as the user: **exit 1**,
   "Error: bundled Node.js tarball missing from /opt/packages". `--first-install` sets the
   ISO-chroot context, in which `install/user/mise-work.sh` requires the ISO's bundled Node
   tarball. The script runs under `set -e`, so everything after it in `install/user/all.sh` was
   skipped, along with the browser, the mailto handler and the done marker. **Deviation:**
   `omarchy-provision-user --force` (runtime context, Node from the network) exited 0, ending
   with "User finalization complete."
6. **`ufw allow ssh`** printed "ERROR: problem running" and exited 1, but the rule was still
   staged (`ufw show added`: `ufw allow 22`; `user.rules` has tcp and udp 22). The error comes
   from `apply-system` having already set `ENABLED=yes` while no firewall was loaded.
7. **Reboot.** SSH answered **46 s** after `systemctl reboot`, against the pre-install pin. A
   keyscan after the reboot presented the same three fingerprints. `instance-id` was unchanged.

## The six expected failure points

| # | Expected | Observed |
|---|---|---|
| 1 | Limine's hooks vs GRUB | **Fired, harmlessly this time.** In both transactions, "Updating linux initcpios" failed with "ERROR: FAT32 boot partition not found. Make sure it is mounted or configure ESP_PATH in /etc/default/limine." `limine-mkinitcpio-hook` ships `/etc/pacman.d/hooks/90-mkinitcpio-install.hook`, which shadows mkinitcpio's own hook of the same name. GRUB's `vmlinuz-linux`, `initramfs-linux.img` and `grub.cfg` were untouched and still matched `/usr/lib/modules`, and no EFI boot entry was added. GRUB booted (`LoaderInfo` "GRUB 2.16", `BOOT_IMAGE=` on the command line). No kernel upgrade happened, because the mirror is older, so what the shadowed hook does to the next kernel was **not observed** |
| 2 | Network moves to NetworkManager | **Fired; the network came back.** networkd was disabled and its wait-online service masked; NetworkManager was enabled. After the reboot NetworkManager was active with its auto-generated `Wired connection 1` (DHCP), networkd was inactive, and cloud-init's `10-cloud-init-eth0.network` was left in place but unused. Static addressing from a vendor was **not observed** |
| 3 | SDDM fails with no display | **Did not fire.** With no display adapter, `sddm.service` stayed `active`, logged "Starting..." and nothing more, and seat0 had no graphics device. There were no failed units and `is-system-running` reported `running`. With `virtio-vga`, the greeter session started on seat0 |
| 4 | ufw closes port 22 | **Fired, as predicted.** With step 7 the firewall came up active (default deny incoming) with 22 allowed. Lockout check on the same disk: `ufw delete allow ssh` and a reboot, after which the guest reached a login prompt on the serial console but gave no SSH answer for 3 minutes |
| 5 | Update guard on `pacman -Syu` | **Fired when there was something to upgrade.** A plain `pacman -Syu` printed "there is nothing to do" and exited 0, because the mirror is older than the image. `pacman -Syu omarchy-keyring` ran the pre-transaction hook, which aborted with "This looks like a direct pacman system upgrade", exit 1 |
| 6 | Hermes through Omarchy | **Fired in a different form.** Step 6's runtime `provision-user` wrote Omarchy's own `~/.local/bin/hermes` stub (`omarchy-install-hermes-cli`), and upstream's installer did not replace it. A bare `hermes` therefore ran Omarchy's mise-built copy, and the first `hermes gateway install` produced a unit running that copy. Naming upstream's binary (`~/.hermes/hermes-agent/.hermes/bin/hermes gateway install --force`, then a restart) gave a lingering user service on upstream's build. With no provider credential and no messaging platform it stays `active (running)`, logging "No messaging platforms enabled." and that it has no provider authentication. It was still active after the next boot |

One failure point the research did not list: `--first-install` outside the ISO (step 5 above).

## Second variant

The same disk, relaunched with `-device virtio-vga -display none`, came back with the same key,
`running`, no failed units, GRUB, and NetworkManager. This was a re-boot of one install, not a
second install.

## What it means for `OPN-25`

Route C reaches a pinned channel end to end. The host keys cloud-init generated on first boot
survive Omarchy's install and its reboot, so a pin taken before the install still holds
afterwards. The route is not clean, though. It needs two departures from what the ISO runs (the
user command's runtime form, and a staged `ufw allow ssh`). It leaves Limine's hook shadowing the
stock initramfs hook on a GRUB-booted machine. It runs on a mirror older than the vendor image.
And it installs the whole desktop stack. Not observed: a kernel upgrade through the shadowed
hook, `omarchy update`, a vendor's static network configuration, and real hardware or a real
VPS. `OPN-25` can record that route C passes in a VM. Whether stage 1 rests on an unsupported
configuration is still the corpus's decision.

## Reproduce

```sh
cd prototypes/omarchy-headless
./run.sh all                                   # primary run, no display adapter
./run.sh stop; VARIANT=virtio-vga ./run.sh boot; ./run.sh up; ./run.sh after
./run.sh lockout; ./run.sh stop                # optional, last
rm -rf /var/tmp/omarchy-proto
```

`all` includes `step6r`, the deviation, because `step6b` failed here; run steps one by one to
stop at the failure instead.
