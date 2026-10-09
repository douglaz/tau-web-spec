# Findings — Omarchy on a machine with no display (`OPN-25`, T41)

Date: 2026-10-08. A read of code and documentation; nothing was installed or booted. Sources,
all read that day:

- `omacom/omarchy` (`basecamp/omarchy` now redirects there). Default branch `quattro` at
  `902fd8a`. Release tag `v4.0.4` is `c668141`, the commit the packaged `omarchy` 4.0.4 builds
  from (`omacom/omarchy-pkgs` `pkgbuilds/omarchy/PKGBUILD:14–15`). Tag `v3.8.4` (`8fcc9d6`) is
  used only for the retired installer. Paths are at `902fd8a` unless marked; every install-path
  file cited below is byte-identical at `v4.0.4` unless noted.
- `omacom/omarchy-iso` at `595d38c` (it carries no tags); `omacom/omarchy-pkgs` at `d37fcd0`.
- `archlinux/arch-boxes` (gitlab.archlinux.org) at `7f733af`, and the image index at
  `https://geo.mirror.pkgbuild.com/images/latest/`.
- `NousResearch/hermes-agent` `README.md` at `457a1e1`.
- omarchy.org, the hosted manual, GitHub releases and issues, Hetzner's documentation and
  LNVPS's public API, each cited where used.

## Summary

Omarchy ships no server edition and no headless switch. Its maintainers support one install
path, the ISO, which wipes a disk (or fills free space), installs Arch with Limine on btrfs,
and finishes the system inside a chroot. That ISO installs with nobody at the keyboard when a
second drive labelled `cidata` carries the wizard's answers, and Omarchy's own integration
suite does exactly that in a QEMU guest with no display window, then logs in by SSH — so
"installs on a headless VM" is already shown upstream. It is not "installs over SSH": the
installer runs only on the local console, the installed system's host keys are generated on
that machine and published nowhere, and the `cidata` drive is read for eight named files and
runs nothing, so no attest hook can ride it. The curl-to-bash installer that ran on an existing
Arch was the Omarchy 3 path and is broken today. What is left for a channel-driven install is
unsupported: put Omarchy's packages on a vendor's stock Arch image and run the two setup
commands the ISO runs in its chroot. The code says that route brings the whole desktop stack
(the runtime package depends on Hyprland, Quickshell, uwsm and SDDM), moves networking to
NetworkManager, and arms a firewall with port 22 closed for the next boot. A server edition
exists only as a plan committed on 2026-08-17, unimplemented, and it puts the edition choice in
the ISO.

**Verdict: no server edition, and no supported way to install Omarchy over SSH. Restate stage 1
on plain Arch unless the package-route prototype in §5 passes over a pinned channel. This is a
code-read finding, not an observed failure: nothing was booted, and `OPN-25` stays open.**

## 1 — What the installer assumes, and what it asks

Three routes exist, and only the first is supported.

| Route | Status | Over the channel? | Disk |
|---|---|---|---|
| A. The ISO, by its wizard or a `cidata` drive | The only supported route | No: it runs on the local console | Wipes the chosen disk, or uses free space (UEFI only) |
| B. `curl -fsSL https://omarchy.org/install \| bash` on an installed Arch | Omarchy 3's route; broken | In principle, but its guards prompt | The existing system |
| C. Omarchy's packages on a stock Arch, then its two setup commands | Unsupported; plausible in the code | Yes | The existing system |

### Route A — the ISO

- `omarchy-iso` `README.md:3`: "The Omarchy ISO is the only supported way to install Omarchy."
  omarchy.org's install section: "On Linux, the ISO is the way in." The manual,
  `manual/02-getting-started.md:3`: "Omarchy is installed using an ISO."
- **Order of work.** `configs/airootfs/usr/share/omarchy-iso/orchestrator/main.py:153–170`:
  archinstall installs Arch and the packages, `omarchy-apply-system` runs the root-side setup,
  Limine is finalised, `omarchy-provision-user` runs as the user, then SSH access, Tailscale,
  DNS, a boot validation and a btrfs `@factory` snapshot.
- **UEFI is not required for a full-disk install.** `configs/airootfs/root/configurator:940–941`:
  "The free-space/protected path registers an EFI boot entry and is UEFI-only. Full-disk
  installs still support BIOS through the orchestrator's BIOS branch." The branch is
  `phases_impl.py:360–374` (`limine bios-install`); on BIOS the unified kernel images are
  turned off (`:557–558`). Secure Boot must be off: "You must turn off Secure Boot and/or TPM
  in the BIOS" (`manual/02-getting-started.md:7`).
- **Limine and btrfs.** The configuration upstream's own test generates
  (`test/integration.d/base-test.sh:401–492`) sets `"bootloader": "Limine"`, a 2 GiB ESP and a
  btrfs partition with subvolumes `@`, `@home`, `@log` and `@pkg`. The factory snapshot is
  skipped on a root that is not btrfs (`phases_impl.py:1804–1808`).
- **A user and sudo.** `bin/omarchy-apply-system:61–78` refuses to run as anyone but root, and
  refuses an install user that is root or does not exist; the test's credentials file creates
  the user with `"sudo": true` (`base-test.sh:387–399`).

**The prompts, and what pre-answers each.** No prompt has an environment variable or flag of its
own. The `cidata` drive is the only pre-answer, and it is all or nothing:
`configs/airootfs/usr/local/bin/omarchy-cidata-load:52` takes the drive only when it carries
`user_configuration.json` and either `user_credentials.json` or a `defer-provisioning` marker;
otherwise the wizard runs.

| Prompt | Where | Pre-answered by |
|---|---|---|
| Keyboard layout | `configurator:206` | `user_configuration.json` |
| Username, password, full name, email | `configurator:259` | `user_credentials.json` (an `openssl passwd -6` hash), `user_full_name.txt`, `user_email_address.txt` |
| Hostname, timezone | `configurator:272–273` | `user_configuration.json` |
| "Does this look right?" | `configurator:305` | Skipped |
| Install disk, mode, overwrite confirmation | `configurator:893, 948, 968` | `user_configuration.json` (`disk_config`, `omarchy_install.mode`) |
| Encryption (Ctrl+C at the overwrite confirmation turns it off, `manual/02-getting-started.md:35`) | | A `disk_encryption` block plus `user_encrypt_installation.txt` |
| Prepare for another owner | `configurator:251` | The `defer-provisioning` marker |
| "Reboot Now" | `omarchy-install-dashboard:767–788` | Skipped: `.automated_script.sh:97–99` sets `OMARCHY_UI_INTERACTIVE=no` on a `cidata` load, `reboot_prompt` returns at `:772`, and the machine reboots itself (`:1116–1121`) |
| Failure menu | `omarchy-install-dashboard:945–951` | Skipped the same way; the failure stays on the console |
| LUKS passphrase at first boot | | Not pre-answerable — `README.md:91`: "Encrypted autoinstalls are not fully unattended — the LUKS passphrase prompt still needs someone at the first boot." Only an unencrypted install avoids it |

The drive is found by the label `cidata` or `CIDATA` (`omarchy-cidata-load:33–35`), the
cloud-init NoCloud label, but it is not cloud-init: the loader copies `user_configuration.json`
and the seven names on `:46` (`user_credentials.json`, `defer-provisioning`,
`user_full_name.txt`, `user_email_address.txt`, `user_encrypt_installation.txt`,
`authorized_keys`, `tailscale_authkey`) and executes nothing. `cidata` support landed on
`omarchy-iso`'s `quattro` on 2026-07-28 (`a4ec97d`), and `.automated_script.sh` at that branch's
head on the 4.0.4 release date (`7cfb711`) calls the loader. The released ISO's own build
commit, recorded on the medium as `build-info`, was not read.

### Route B — the Omarchy 3 installer

`https://omarchy.org/install` still serves one line:
`eval "$(curl -fsSL https://raw.githubusercontent.com/basecamp/omarchy/refs/heads/master/boot.sh)"`.
That URL returns 404: the `master` branch is gone (`git ls-remote` shows `quattro`, `dev`, `rc`
and release branches). Issue #12436, "Deletion of master branch breaks updates + manual
install", opened 2026-09-18, is open with no maintainer reply. The page that documents the
route is titled "The Omarchy 3 Manual"
(`learn.omacom.io/2/the-omarchy-manual/96/manual-installation`); the current manual has no such
chapter (`https://omarchy.org/manual/manual-installation/` is 404).

Pinned to `v3.8.4`, the route's guards (`install/preflight/guard.sh:7–43`) wanted Arch and not a
derivative, a non-root user, x86_64, Secure Boot off, no GNOME or KDE, Limine, and a btrfs root.
Each failure asks "Proceed anyway on your own accord and without assistance?" through
`gum confirm` (`:4`), which needs a terminal; the arch-boxes image boots GRUB, so the Limine
guard would ask. Its other prompts were the sudo password, name and email (pre-answerable by
`OMARCHY_USER_NAME` and `OMARCHY_USER_EMAIL`, `install/config/git.sh:2–7`) and a reboot
(`install/post-install/finished.sh:28`). Even when it ran, it installed Omarchy 3, which then
needs `omarchy-upgrade-to-quattro`.

### Route C — the packages, then the ISO's two commands

What the ISO runs after installing packages is documented. `docs/file-layout.md:223–225`: "The
ISO calls it as `omarchy-provision-user --force --first-install` in the target chroot as the
install user, after `omarchy-apply-system` has finished the root-side work." The repository and
package steps exist in self-contained form in `bin/omarchy-upgrade-to-quattro:393–460` and
`:781–832`, a script that says it can be "run directly with curl | bash on older systems"
(`:15–16`) but was written for pre-4 Omarchy installs. Nothing in Omarchy documents Route C; it
is simply the shortest route the code allows. It asks nothing: no script that either command
sources calls `gum` or `read`, and the ISO runs the whole installer "as a non-interactive child"
(`.automated_script.sh:114–116`). Its known failure points are in §5.

## 2 — What breaks with no display or GPU

- **No headless option exists, documented or in the code.** `omarchy-apply-system` accepts
  `--install-user`, `--defer-provisioning`, `--first-install` and `--upgrade` and nothing else
  (`bin/omarchy-apply-system:31–59`); the `cidata` drive has no such file
  (`omarchy-cidata-load:46`); and the runtime package depends on `hyprland`, `quickshell`,
  `uwsm` and `sddm` (`omarchy-pkgs` `pkgbuilds/omarchy/PKGBUILD:38–41`), so no package subset
  leaves the desktop out. "Headless" in the code means monitor handling or the test harness.
- **The install needs no GPU.** Upstream's integration runner logs "Installing … unattended via
  cidata (headless)" (`omarchy-iso` `test/integration.d/base-test.sh:517`) for a guest started
  with `-device virtio-vga` and `-display none` (`:174–175`), and takes SSH answering as the
  sign the install finished (`:539–545`). That guest has a virtual display adapter and no
  window. A guest with no display adapter at all was not exercised by anything read here.
- **It does need the console.** `.automated_script.sh:13` is
  `[[ $(tty) == /dev/tty1 ]] || exit 0`: the install runs on the first virtual terminal, never on
  a serial getty or over SSH. The ISO's boot entries carry no `console=ttyS0`
  (`configs/efiboot/loader/entries/01-archiso-x86_64-linux.conf:5`, `configs/grub/grub.cfg:57`),
  so a serial-only console shows none of it. A failed unattended install leaves its failure on
  that screen and exits (`omarchy-install-dashboard:948–951`). From the network that is silence:
  `STG-20`'s invisible machine, on a vendor's VPS.
- **After the install, only the graphical session needs a display.** The ISO enables SDDM
  (`install/config/enable-services.sh:14`; `phases_impl.py:1443–1446`), and the first-run steps
  wait for a graphical login (`docs/file-layout.md:263–268`). sshd is enabled only when the
  `cidata` drive carries `authorized_keys` (`phases_impl.py:1456–1513`;
  `manual/51-unattended-installs.md:27`). Upstream's acceptance suite drives a full graphical
  session in a VM on a virtual adapter (`omarchy-iso` `README.md:107`), and on `quattro` only —
  the file is absent at `v4.0.4` — animations are turned off when `systemd-detect-virt` reports
  a VM (`install/user/hardware/vm-no-animations.sh:5`). With no display device at all, the code
  predicts a failed `sddm.service` beside a working sshd. Not observed.

## 3 — An official server edition

None ships. A plan does: `plans/server.md` on `quattro`, "Revision 1", committed by David
Heinemeier Hansson on 2026-08-17 (`f32ebbd`, "Omarchy Server Edition"), and absent from
`v4.0.4`. From it:

- `:7` — "There is no story for the second machine most Omarchy users have: the home-lab box,
  the VPS, the closet server running Docker."
- `:7` — "People who want "Omarchy for servers" today either drag the entire Hyprland/GUI stack
  onto a headless machine or hand-strip it and lose the update pipeline."
- `:15` — "No Hyprland, no Quickshell, no GUI packages. Boots to a getty on the console; SSH is
  the primary access and is on from first boot (key-only)."
- `:23`, among rejected approaches — "**"Server mode" toggle on an installed desktop**:
  uninstalling a GUI stack in place is a migration minefield in both directions. Edition is
  chosen at install time; changing your mind is a reinstall (dots + backup make that cheap)."
- `:74` — "Phase 2 (coordinated): ISO/installer work in the ISO pipeline repo — a Server choice
  at install (or a separate slim ISO; open question), provisioning flow, offline mirror subset."

It is unimplemented: neither of phase 1's named pieces, `omarchy-edition` and
`install/omarchy-server.packages` (`:73`), exists anywhere in the tree at `902fd8a`. As planned,
the edition arrives through the ISO, so even shipped it answers "is there a server edition" and
not "does it install over SSH on a vendor's image". The other first-party statements are the
two quoted under Route A. Searches on 2026-10-08 of the issue tracker ("server edition",
"headless", "VPS", "omarchy server") and of the repository's discussions ("server", "headless",
"VPS") found no maintainer statement beyond these. The nearest discussions — #10481, "Publish an
official headless Omarchy Quattro container image for testing and CI", and #12144, on PXE
provisioning — have no replies.

## 4 — Plain Arch at a vendor

- **Arch's own cloud image.** arch-boxes `README.md:16–17`: "The cloud image is meant to be used
  in "the cloud" and comes with [`cloud-init`](https://cloud-init.io/) preinstalled." Built daily
  and released fortnightly (`:6`), signed by the project's CI key (`:39`). Current:
  `Arch-Linux-x86_64-cloudimg-20261001.604814.qcow2` with `.SHA256` and `.sig`. Its shape: a
  BIOS-boot partition, a 300 MiB ESP and a btrfs root (`build.sh:49–60`); GRUB installed for
  both BIOS and UEFI (`images/base.sh:56–57`); kernel and GRUB on the serial console
  (`images/cloud-image.sh:14–16`); cloud-init's services (`:10–11`); sshd and systemd-networkd
  enabled (`images/base.sh:47–48`). Against Omarchy's assumptions: btrfs yes, Limine no,
  NetworkManager no.
- **Hetzner Cloud.** `https://docs.hetzner.com/cloud/servers/overview/`, *Operating systems*:
  "You can choose from Ubuntu, Fedora, Debian, CentOS, Rocky Linux, and AlmaLinux as your
  operating system." An ISO is attached after creation, and a custom one is mounted on a support
  ticket (`https://docs.hetzner.com/cloud/servers/faq/`, "How can I get a custom ISO?"). The live
  `/v1/images` and `/v1/isos` catalogues need an API token and were not read. On the documents,
  `STG-21`'s fallback condition — "The fallback holds only where Hetzner Cloud offers the
  stage's distribution as an image at creation" — is met neither by Arch nor by the Omarchy ISO;
  T39's probe should check the API before that is relied on.
- **LNVPS.** `GET https://api.lnvps.net/api/v1/image`, unauthenticated, lists id 11:
  `distribution` `archlinux`, `flavour` `Cloud`, `version` `Latest`, `default_username` `arch`,
  `release_date` 2026-07-17. The `arch` user matches arch-boxes' cloud image; whether it is
  that image, and which build, is `OPN-24`'s probe to settle.

## 5 — A prototype

Route A needs no prototype of ours. Upstream's `test/integration` already installs the ISO
headless from a generated `cidata` drive and logs in by SSH (`base-test.sh:166–184` is the QEMU
line, `:516–597` the install). Running it would re-observe that, and could not show the one
thing that matters here: the installed machine's host keys reach nobody before first contact.
The installer generates none itself (nothing in `omarchy-iso`'s `configs/` calls `ssh-keygen`).

The open question is Route C, in a disposable QEMU guest:

1. Boot the arch-boxes cloud image (check `.SHA256` and `.sig`) as a 40 GB qcow2 overlay with
   4 GB of memory and OVMF, plus a NoCloud seed carrying the operator's SSH key in `user-data`.
   Two variants: no display adapter at all (`-vga none -nographic`, the VPS case), and upstream's
   `-device virtio-vga -display none`.
2. Pin the host key from the serial log, where cloud-init prints the fingerprints, as a stand-in
   for attest; connect as `arch` against that pin only.
3. As root, point pacman at Omarchy's sources: `/etc/pacman.d/mirrorlist` from
   `default/pacman/mirrorlist-stable`, and the `[omarchy]` section of
   `default/pacman/pacman-stable.conf:28–29`. Trust the packaging key as
   `omarchy-upgrade-to-quattro:454–458` does, and record the `SigLevel` in force.
4. Install `omarchy-keyring omarchy-settings omarchy-nvim omarchy`, then the list in
   `/usr/share/omarchy/install/omarchy-base.packages`, with `OMARCHY_UPDATE_PACMAN=1`
   (`omarchy-upgrade-to-quattro:804`), because the update guard arrives with the first
   transaction. `omarchy-settings` must be in before the user is created
   (`docs/file-layout.md:14–16`). Limine's pacman hooks first fire in this transaction, so list
   `/boot` and `/efi` afterwards and confirm GRUB's kernel, initramfs and `grub.cfg` are intact
   (failure point 1).
5. Create the user with `useradd -m`, give it `wheel`, a sudo rule and its `authorized_keys`.
6. `omarchy-apply-system --install-user <user> --first-install`, then as the user
   `omarchy-provision-user --force --first-install`. Keep `/var/log/omarchy-install.log`, and
   repeat step 4's boot check, since the hardware scripts can rebuild boot images.
7. Before rebooting, `ufw allow ssh` (failure point 4). Once, on a second overlay, skip it to
   confirm the lockout.
8. Reboot. It passes when SSH answers with the **same** pinned host key. Record
   `systemctl --failed`, `systemctl is-system-running`, which loader booted, whether the network
   came up under NetworkManager, and a plain `pacman -Syu`. Then install Hermes with its own
   installer (`hermes-agent` `README.md:40`) and run `hermes gateway` (`:115`) as a lingering
   user service.

Expected failure points, from the code:

1. **The bootloader.** The runtime package depends on `limine`, `limine-mkinitcpio-hook`,
   `limine-snapper-sync` and `snapper` on x86_64 (`pkgbuilds/omarchy/PKGBUILD:70–75`); the
   comment above them records the hook failing with "Cannot detect an ESP path" where it finds
   none (`:63–66`). arch-boxes mounts its ESP at `/efi` and boots GRUB (`images/base.sh:57`),
   and the ISO writes `/etc/default/limine` and `/etc/kernel/cmdline` from a template
   (`phases_impl.py:540–570`), which Route C does not. Whether GRUB's initramfs survives
   Limine's mkinitcpio hooks is the first thing to watch.
2. **The network.** `install/hardware/network.sh:7–18` disables every systemd-networkd unit and
   masks its wait-online service; `install/config/enable-services.sh:8` enables NetworkManager.
   After the reboot the image's cloud-init networkd configuration no longer applies. A
   DHCP-only guest should come back; a vendor that hands static addressing through cloud-init
   may not.
3. **The display manager.** `enable-services.sh:14` enables SDDM, which has nothing to drive
   without a display adapter. It should fail on its own.
4. **The firewall.** `install/config/firewall.sh:2` sets `ufw default deny incoming`, `:6–11`
   open only LocalSend and Docker's DNS, and `:53–54` arm ufw for the next boot. Port 22 is
   opened only by the ISO's `cidata` path (`phases_impl.py:1507–1513`) or by
   `omarchy-setup-security-sshd`. Without step 7 the reboot shuts the channel out.
5. **Later package operations.** `default/libalpm/hooks/00-omarchy-update-guard.hook` runs
   `omarchy-update-pacman-guard`, which aborts any `pacman -Syu` that does not come through
   `omarchy update` unless `OMARCHY_ALLOW_DIRECT_PACMAN=1` is set
   (`bin/omarchy-update-pacman-guard:8, 40–44`).
6. **Hermes through Omarchy.** `bin/omarchy-install-hermes-cli:8`: "There is one Hermes on a
   machine, and it is the desktop app's." Omarchy installs Hermes only as the `hermes-desktop`
   package, which depends on `gtk3`, `libdrm` and `libx11`
   (`pkgbuilds/hermes-desktop/PKGBUILD:14, 26, 29, 33`), and its `--now` mode installs the app
   "whatever else answered to hermes before" (`:17`). The scenario should install Hermes with
   the upstream installer, not through Omarchy; upstream says of it "Run it on a $5 VPS"
   (`README.md:19`).

## What this means for the corpus

`OPN-25` does not close. Its first branch, "an Omarchy server installation completes over the
channel", has no supported route. The ISO is not reachable over the channel, and its first
contact is unpinned, which `CHN-R4` refuses: "A first contact with no independently obtained pin
is admitted only from a jump host". Route C is the only candidate, and if it passes, what runs
is Omarchy's desktop packages on a vendor's Arch image, a configuration its maintainers do not
support. The second branch, plain Arch, is available as arch-boxes' cloud image wherever a
vendor's catalogue offers it: LNVPS appears to, and Hetzner Cloud's documents say it does not.

The distribution is unpinned on either branch — `ARC-24`: "Another distribution an operator's
goal names — Arch, Omarchy — is installed **unpinned** under `ARC-25`'s rule until the bundle
carries a pin for it (`OPN-25`)". Omarchy also changes the artifact source. Its mirrorlist sends
every Arch repository to `stable-mirror.omarchy.org` (`default/pacman/mirrorlist-stable`), and
it adds `[omarchy]` at `pkgs.omarchy.org`. Signature policy differs from file to file. The
installed template gives `[omarchy]` no override, so it inherits `SigLevel = Required
DatabaseOptional` (`default/pacman/pacman-stable.conf:15, 28–29`). The ISO's online
configuration (`omarchy-iso` `configs/pacman-online-stable.conf:28–30`) and the Quattro upgrade
(`omarchy-upgrade-to-quattro:418`) both write `SigLevel = Optional TrustAll`. Issue #9199,
"omarchy repo signing key exists in keyring but SigLevel still Optional TrustAll", is open. The
packaging key reaches a machine either in the `omarchy-keyring` package or, when that install
fails, by fingerprint `40DFB630FF42BCFFB047046CF0134EE680CAC571` fetched from keys.openpgp.org
(`omarchy-upgrade-to-quattro:454–458`), which is trust on retrieval. A publisher pin for
Omarchy, under `ARC-25a`'s two layers, would start from those three files and that fingerprint.

Nothing else in the corpus is changed by this finding.
