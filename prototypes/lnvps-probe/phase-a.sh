#!/usr/bin/env bash
# LNVPS live probe, phase A: one NIP-90 order, never paid (OPN-24).
# Subscribes for the vendor's job feedback first, because each feedback event carries a
# 30-second NIP-40 expiration (lnvps_api/src/dvm/mod.rs, build_status_for_job), then
# publishes one kind-5999 job and lists the key's machines over NIP-98. An unpaid order is
# deleted by the vendor after an hour. Keys live outside the repository; nothing here is
# committed but this script.
set -u
NAK=${NAK:-nak}
LNVPS=fcd818454002a6c47a980393f0549ac6e629d28d5688114bb60d831b5c1832a7  # lnvps.net/.well-known/nostr.json
RELAYS="wss://nos.lol wss://nostr.oxtr.dev wss://relay.damus.io wss://relay.snort.social"  # its NIP-65 list
KEYS=${KEYS:-$HOME/.config/tau-web/lnvps-probe}
OUT=${OUT:-/var/tmp/lnvps-probe}
mkdir -p "$KEYS" "$OUT" && chmod 700 "$KEYS"
[ -s "$KEYS/nostr.sec" ] || { (umask 077; $NAK key generate </dev/null >"$KEYS/nostr.sec"); }
[ -s "$KEYS/ssh.pub" ] || ssh-keygen -q -t ed25519 -N '' -C lnvps-probe -f "$KEYS/ssh" </dev/null
SEC=$(cat "$KEYS/nostr.sec")
PUB=$($NAK key public "$SEC" </dev/null)
SSH_PUB=$(cat "$KEYS/ssh.pub")

timeout 150 $NAK req --stream -k 7000 -a "$LNVPS" -p "$PUB" $RELAYS \
  </dev/null >"$OUT/feedback.jsonl" 2>"$OUT/req.err" &
sub=$!
sleep 8
date -u +%FT%TZ >"$OUT/published-at"
$NAK event --sec "$SEC" -k 5999 -c '' -p "$LNVPS" \
  -t "param=cpu;1" -t "param=memory;1024" -t "param=disk;10" \
  -t "param=ssh_key;$SSH_PUB" -t "param=os;archlinux" -t "param=os_version;Latest" \
  $RELAYS </dev/null >"$OUT/job.json" 2>"$OUT/event.err"
echo "publish exit $?"
wait "$sub"
echo "subscription exit $? (124 = closed by its timeout, expected)"

$NAK curl --sec "$SEC" -sS https://api.lnvps.net/api/v1/vm </dev/null >"$OUT/vm-list.json" 2>"$OUT/curl.err"
echo "list exit $?"
