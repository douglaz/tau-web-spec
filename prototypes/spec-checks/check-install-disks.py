"""Run the brief's additional-disk block with fake disks and destructive commands stubbed.

No block device is opened. --baseline checks the reviewed pre-fix commit and must fail.
"""
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BRIEF = "docs/briefs/01-install.md"
BASELINE = "383cca261cf6d44d3cf61f0589b489d42f755690"
if sys.argv[1:] == ["--baseline"]:
    source = subprocess.check_output(["git", "show", f"{BASELINE}:{BRIEF}"], cwd=ROOT, text=True)
elif not sys.argv[1:]:
    source = (ROOT / BRIEF).read_text()
else:
    raise SystemExit("usage: check-install-disks.py [--baseline]")
blocks = re.findall(r"```sh\n(.*?)\n```", source, re.S)
block, = [part for part in blocks if 'sgdisk --zap-all "$other"' in part]

with tempfile.TemporaryDirectory(prefix="tau-disk-check-") as directory:
    base = Path(directory)
    root, extra, untouched = [base / name for name in ("root", "extra", "untouched")]
    for disk in (root, extra, untouched):
        disk.touch()
    alias = base / "root-wwn"
    alias.symlink_to(root)
    extra_alias = base / "extra-wwn"
    extra_alias.symlink_to(extra)
    log = base / "writes"
    # '[' is overridden only for the fake -b predicate. All other checks use bash's builtin.
    # lsblk supports both the old enumeration and the corrected per-device type query.
    stubs = r'''
function [() {
  if builtin [ "$#" -eq 3 ] && builtin [ "$1" = -b ]; then
    case "$2" in "$FAKE_ROOT"|"$FAKE_EXTRA"|"$FAKE_UNTOUCHED") return 0;; *) return 1;; esac
  fi
  builtin [ "$@"
}
lsblk() {
  if [ "$1" = -dnpo ]; then
    printf '%s disk\n' "$FAKE_ROOT" "$FAKE_EXTRA" "$FAKE_UNTOUCHED"
  else
    printf 'disk\n'
  fi
}
sgdisk() { printf '%s\n' "$*" >> "$WRITE_LOG"; }
partprobe() { :; }
sleep() { :; }
chroot() { :; }
'''
    env = dict(os.environ, DISK=str(alias), FAKE_ROOT=str(root), FAKE_EXTRA=str(extra),
               FAKE_UNTOUCHED=str(untouched), WRITE_LOG=str(log))
    cases = [
        ("root alias plus extra", [alias, extra_alias], True, [extra]),
        ("canonical root plus extra", [root, extra_alias], True, [extra]),
        ("duplicate extra aliases", [extra_alias, extra], True, [extra]),
        ("empty additional set", [], True, []),
        ("missing entry after valid disk", [extra, base / "missing"], False, []),
        ("non-block entry after valid disk", [extra, base], False, []),
    ]
    for name, selected, success, expected in cases:
        log.write_text("")
        env["OTHER_DISKS"] = "\n".join(map(str, selected))
        result = subprocess.run(["bash", "-c", stubs + block], env=env, capture_output=True, text=True)
        actual = [line.removeprefix("--zap-all ") for line in log.read_text().splitlines()
                  if line.startswith("--zap-all ")]
        assert (result.returncode == 0) == success, (name, result.returncode, result.stderr)
        assert actual == list(map(str, expected)), (name, "unexpected erasure targets", actual)
        print(f"PASS: {name}")
