#!/usr/bin/env bash
# LNVPS probe, phase B step (1): poll one machine's status and print a line whenever its state,
# address count or published host-key families change, until all three families are published
# or the deadline passes. Every poll is appended to $OUT/watch.jsonl with its UTC time.
# Usage: phase-b-watch.sh KEYFILE VM_ID [DEADLINE_SECONDS]
set -eu
here=$(dirname "$0")
key=$1; vm=$2; deadline=${3:-14400}
OUT=${OUT:-/var/tmp/lnvps-probe-b}
mkdir -p "$OUT"
start=$(date +%s); prev=""
while [ $(( $(date +%s) - start )) -lt "$deadline" ]; do
  now=$(date -u +%FT%TZ)
  if r=$("$here/lnvps-req.sh" "$key" GET "/api/v1/vm/$vm" 2>/dev/null); then
    printf '{"t":"%s","r":%s}\n' "$now" "$r" >>"$OUT/watch.jsonl"
    cur=$(printf %s "$r" | jq -r '.data | "state=\(.status.state) ips=\(.ip_assignments|length) keys=\([.host_ssh_keys[]?.key_type]|sort|join(","))"') \
      || cur="parse failed"
  else
    cur="request failed"
  fi
  [ "$cur" != "$prev" ] && echo "$now $cur"
  prev=$cur
  case "$cur" in *keys=*ecdsa*ed25519*rsa*|*keys=*ed25519*ecdsa*rsa*) exit 0 ;; esac
  printf %s "$cur" | grep -q 'keys=.*ecdsa' && printf %s "$cur" | grep -q 'keys=.*ed25519' \
    && printf %s "$cur" | grep -q 'keys=.*rsa' && exit 0
  sleep 10
done
echo "$(date -u +%FT%TZ) deadline reached without all three key families"; exit 1
