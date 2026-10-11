#!/usr/bin/env bash
# LNVPS probe, phase B step (6): after a reinstall, print a line whenever the machine's state or
# its published host-key fingerprints change, until a complete set of three families appears
# that shares no fingerprint with the set published before the reinstall, or the deadline passes.
# Usage: reinstall-watch.sh KEYFILE VM_ID OLD_FINGERPRINTS_FILE [DEADLINE_SECONDS]
set -eu
here=$(dirname "$0")
key=$1; vm=$2; old=$3; deadline=${4:-14400}
OUT=${OUT:-/var/tmp/lnvps-probe-b}
[ -r "$old" ] && [ -s "$old" ] \
  || { echo "old fingerprints file missing or empty: $old" >&2; exit 2; }
start=$(date +%s); prev=""
while [ $(( $(date +%s) - start )) -lt "$deadline" ]; do
  now=$(date -u +%FT%TZ)
  if r=$("$here/lnvps-req.sh" "$key" GET "/api/v1/vm/$vm" 2>/dev/null); then
    printf '{"t":"%s","r":%s}\n' "$now" "$r" >>"$OUT/reinstall-watch.jsonl"
    fps=$(printf %s "$r" | jq -r '[.data.host_ssh_keys[]?.fingerprint_sha256] | sort | join(" ")') || fps=""
    fams=$(printf %s "$r" | jq -r '[.data.host_ssh_keys[]?.key_type] | unique | sort | join(",")') || fams=""
    st=$(printf %s "$r" | jq -r '.data.status.state') || st="unknown"
    cur="state=$st keys=[${fps}]"
  else
    cur="request failed"; fps=""; fams=""
  fi
  [ "$cur" != "$prev" ] && echo "$now $cur"
  prev=$cur
  # Complete means exactly the three families the scan asks for, none sharing an old fingerprint.
  if [ "$fams" = "ecdsa-sha2-nistp256,ssh-ed25519,ssh-rsa" ] && ! printf '%s\n' $fps | grep -qxFf "$old"; then
    exit 0
  fi
  sleep 10
done
echo "$(date -u +%FT%TZ) deadline reached without a complete new key set"; exit 1
