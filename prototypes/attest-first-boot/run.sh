#!/usr/bin/env bash
# PROTOTYPE - throwaway. Attest on a real vendor's first boot (T40, OPN-3). See README.md.
# Everything a boot produces (keys, API responses, IPs, logs) lands under $WORK, never here.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${WORK:-/var/tmp/attest-proto}
API=https://api.hetzner.cloud/v1
NAK_VERSION=v0.20.7
NAK_URL=https://github.com/fiatjaf/nak/releases/download/$NAK_VERSION/nak-$NAK_VERSION-linux-amd64
NAK_SHA256=ba918fafd1b030bc50958a5b218c6386f4c3a57c1e469562d3947e858e0ba56e
RELAYS_LIVE="wss://nos.lol wss://relay.primal.net wss://nostr.mom"
RELAY_DEAD=wss://192.0.2.1   # TEST-NET-1 (RFC 5737): a connect that never completes
DEADLINE=120                 # the machine's housekeeping deadline (CHN-6), not the browser's window
umask 077
mkdir -p "$WORK"; chmod 700 "$WORK"
HDR=$WORK/auth.hdr NAK=$WORK/nak SSH_KEY=$WORK/ssh/id_ed25519
SERVER_ID='' PIDS=() CM=''

# The token is read once, from the environment, into a mode-600 header file; never into argv.
hdr() {
  [ -s "$HDR" ] && return
  : "${HETZNER_CLOUD:?export HETZNER_CLOUD (a Hetzner Cloud API token)}"
  printf 'Authorization: Bearer %s\n' "$HETZNER_CLOUD" > "$HDR"
}
api() {  # api METHOD PATH [curl args...]: body on stdout, non-2xx fails
  local m=$1 p=$2; shift 2
  curl -sS --fail-with-body -H @"$HDR" -H 'Content-Type: application/json' -X "$m" "$API$p" "$@"
}
nak_local() {  # the same pinned release binary the machine runs
  [ -x "$NAK" ] && return
  curl -fsSL -o "$NAK.part" "$NAK_URL"
  echo "$NAK_SHA256  $NAK.part" | sha256sum -c - >/dev/null
  chmod 755 "$NAK.part"; mv "$NAK.part" "$NAK"
}
stamp() { while IFS= read -r l; do printf '%s %s\n' "$EPOCHREALTIME" "$l"; done; }
rel() { awk -v a="$1" -v b="$T0" 'BEGIN{printf "%.1f", a-b}'; }
ev() {  # ev EVENT [epoch]: one timeline row, seconds since the create call
  local t=${2:-$EPOCHREALTIME}
  printf '%s\t%s\t%s\n' "$(rel "$t")" "$t" "$1" >> "$B/timeline.tsv"
  printf '%8ss  %s\n' "$(rel "$t")" "$1"
}
pubkey() { printf '%s\n' "$1" | "$NAK" key public; }   # secret on stdin, not argv
ssh_pinned() {  # known_hosts holds ONLY the attested keys; never accept-new
  ssh -i "$SSH_KEY" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$B/known_hosts" -o GlobalKnownHostsFile=/dev/null \
    -o ControlMaster=auto -o ControlPath="$CM" -o ControlPersist=600 "root@$IP" "$@"
}

# The browser's acceptance (CHN-R5, CHN-5): unwrap with the recipient key and accept only a
# seal whose verified author is the planted sender key. Prints the sealed content.
accept() {  # accept WRAP_JSON RECIPIENT_SEC SENDER_PUB
  local w=$1 rs=$2 sp=$3 seal rumor
  seal=$(NOSTR_SECRET_KEY=$rs "$NAK" decrypt --from "$(jq -r .pubkey <<<"$w")" "$(jq -r .content <<<"$w")" </dev/null 2>/dev/null) || return 1
  "$NAK" verify <<<"$seal" >/dev/null 2>&1 || return 1
  [ "$(jq -r .kind <<<"$seal")" = 13 ] && [ "$(jq -r .pubkey <<<"$seal")" = "$sp" ] || return 1
  rumor=$(NOSTR_SECRET_KEY=$rs "$NAK" decrypt --from "$sp" "$(jq -r .content <<<"$seal")" </dev/null 2>/dev/null) || return 1
  [ "$(jq -r .pubkey <<<"$rumor")" = "$sp" ] || return 1
  jq -r .content <<<"$rumor"
}

# known_hosts from the sealed lines only: each key's recomputed fingerprint must equal the
# fingerprint sealed beside it, or nothing is pinned.
pin() {  # pin CONTENT
  local fp type key
  : > "$B/known_hosts"
  while read -r fp type key; do
    [ "$(printf '%s %s\n' "$type" "$key" | ssh-keygen -lf /dev/stdin | awk '{print $2}')" = "$fp" ] || { echo "fingerprint mismatch for $type"; : > "$B/known_hosts"; return 1; }
    printf '%s %s %s\n' "$IP" "$type" "$key" >> "$B/known_hosts"
  done <<<"$1"
  [ -s "$B/known_hosts" ]
}

sweep() {  # delete any server this prototype labelled, e.g. one a killed run left behind
  local id
  for id in $(api GET "/servers?label_selector=purpose%3Dattest-proto" | jq -r '.servers[].id'); do
    echo "sweep: deleting leftover server $id"; api DELETE "/servers/$id" >/dev/null
  done
}
cleanup() {
  local p
  for p in "${PIDS[@]}"; do kill "$p" 2>/dev/null || true; done; PIDS=()
  [ -n "$CM" ] && [ -S "$CM" ] && ssh -o ControlPath="$CM" -O exit x 2>/dev/null || true
  if [ -n "$SERVER_ID" ]; then
    echo "cleanup: deleting server $SERVER_ID"; api DELETE "/servers/$SERVER_ID" >/dev/null || true; SERVER_ID=''
  fi
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT TERM HUP

setup() {
  hdr; nak_local
  [ -f "$SSH_KEY" ] || { mkdir -p "$WORK/ssh"; ssh-keygen -q -t ed25519 -N '' -C attest-proto -f "$SSH_KEY"; }
  [ -s "$WORK/ssh-key-id" ] && return
  jq -n --rawfile k "$SSH_KEY.pub" --arg n "attest-proto-$(date -u +%m%dT%H%M)" \
    '{name: $n, public_key: ($k | rtrimstr("\n")), labels: {purpose: "attest-proto"}}' \
    | api POST /ssh_keys --data @- | jq -r .ssh_key.id > "$WORK/ssh-key-id"
  echo "registered ssh key $(cat "$WORK/ssh-key-id")"
}

boot() {  # boot LOCATION SERVER_TYPE IMAGE
  local loc=$1 type=$2 image=$3 S R SP RP r n f ud resp t line content a b rt off T_RUN='' T_PORT='' T_WRAP=''
  hdr; nak_local; sweep
  [ -s "$WORK/ssh-key-id" ] || { echo "run setup first"; exit 2; }
  B=$WORK/boots/$(date -u +%m%dT%H%M%S)-$loc-$type-$image; mkdir -p "$B"; CM=$B/cm
  printf 'location=%s type=%s image=%s nak=%s relays=%s dead=%s deadline=%s\n' \
    "$loc" "$type" "$image" "$NAK_VERSION" "$RELAYS_LIVE" "$RELAY_DEAD" "$DEADLINE" > "$B/params"

  # Throwaway keys for this boot. The sender secret goes into user-data; the recipient secret
  # never leaves $B.
  S=$("$NAK" key generate </dev/null); R=$("$NAK" key generate </dev/null)
  SP=$(pubkey "$S"); RP=$(pubkey "$R")
  printf '%s\n' "$S" > "$B/sender.sec"; printf '%s\n' "$R" > "$B/recipient.sec"
  printf 'sender %s\nrecipient %s\n' "$SP" "$RP" > "$B/pubkeys"
  ud=$(<"$HERE/user-data.yaml.in")
  ud=${ud//@SENDER_SEC@/$S}; ud=${ud//@RECIPIENT_PUB@/$RP}; ud=${ud//@RELAYS@/$RELAYS_LIVE $RELAY_DEAD}
  ud=${ud//@NAK_URL@/$NAK_URL}; ud=${ud//@NAK_SHA256@/$NAK_SHA256}; ud=${ud//@DEADLINE@/$DEADLINE}
  printf '%s\n' "$ud" > "$B/user-data"
  jq -n --rawfile ud "$B/user-data" --arg name "attest-proto-$loc-$(date -u +%H%M%S)" --arg type "$type" \
    --arg image "$image" --arg loc "$loc" --argjson key "$(cat "$WORK/ssh-key-id")" \
    '{name: $name, server_type: $type, image: $image, location: $loc, ssh_keys: [$key],
      user_data: $ud, labels: {purpose: "attest-proto"}, start_after_create: true}' > "$B/create.json"

  # The "browser": subscribed BEFORE the create call, kind 1059 by #p only, no `since`.
  for r in $RELAYS_LIVE; do
    n=${r#wss://}
    "$NAK" req -k 1059 -p "$RP" --stream "$r" </dev/null 2>"$B/sub-$n.err" > >(stamp > "$B/sub-$n.out") &
    PIDS+=($!); echo "$n $!" >> "$B/subscriber-pids"
  done
  for t in $(seq 40); do
    [ "$(cat "$B"/sub-*.err 2>/dev/null | grep -c '\.\.\. ok\.')" -eq 3 ] && break; sleep 0.5
  done
  [ "$(cat "$B"/sub-*.err | grep -c '\.\.\. ok\.')" -eq 3 ] || { echo "a subscriber did not connect"; cat "$B"/sub-*.err; exit 1; }
  sleep 2

  T0=$EPOCHREALTIME; : > "$B/timeline.tsv"; ev create-call
  resp=$(api POST /servers --data @"$B/create.json"); ev create-returned
  SERVER_ID=$(jq -r .server.id <<<"$resp"); echo "$SERVER_ID" > "$B/server-id"
  IP=$(jq -r .server.public_net.ipv4.ip <<<"$resp")
  jq '.root_password |= (if . == null then null else "<redacted>" end)' <<<"$resp" > "$B/create-response.json"
  jq -c '{top_level_keys: keys, root_password_null: (.root_password == null), next_actions: [.next_actions[].command]}' \
    <<<"$resp" | tee "$B/cnf14.json"

  for t in $(seq 900); do
    if [ -z "$T_RUN" ] && [ "$(api GET "/servers/$SERVER_ID" | jq -r .server.status)" = running ]; then T_RUN=1; ev status-running; fi
    if [ -z "$T_PORT" ] && timeout 2 bash -c "</dev/tcp/$IP/22" 2>/dev/null; then T_PORT=1; ev port22-open; fi
    if [ -z "$T_WRAP" ]; then
      # first wrap received, in receipt order across relays, that passes the author check wins
      while read -r rt line; do
        if content=$(accept "$line" "$R" "$SP") && pin "$content"; then
          T_WRAP=1; ev "wrap-received-and-accepted" "$rt"; printf '%s\n' "$content" > "$B/attested"; break
        fi
        echo "refused a wrap received at $rt" | tee -a "$B/refused"
      done < <(cat "$B"/sub-*.out 2>/dev/null | sort -n)
    fi
    if [ -n "$T_WRAP" ] && [ -n "$T_PORT" ] && ssh_pinned true 2>>"$B/ssh.err"; then ev pinned-ssh-login; break; fi
    sleep 1
  done
  [ -n "$T_WRAP" ] || { echo "FAIL: no accepted wrap"; ev no-wrap; }
  for r in $RELAYS_LIVE; do  # each relay's first delivery to its subscriber
    n=${r#wss://}; rt=$(head -1 "$B/sub-$n.out" 2>/dev/null | cut -d' ' -f1)
    [ -n "$rt" ] && ev "delivered-by $n" "$rt" || ev "not-delivered-by $n"
  done
  [ -n "$T_WRAP" ] || exit 1

  # Negative control: the same check with a known_hosts holding a key that is not the host's.
  printf '%s %s\n' "$IP" "$(cut -d' ' -f1,2 "$SSH_KEY.pub")" > "$B/known_hosts.wrong"
  if ssh -i "$SSH_KEY" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=yes \
       -o UserKnownHostsFile="$B/known_hosts.wrong" -o GlobalKnownHostsFile=/dev/null -o ControlPath=none \
       "root@$IP" true 2>"$B/negative-control.err"; then
    echo "NEGATIVE CONTROL FAILED: logged in against a wrong pin" | tee "$B/negative-control"; exit 1
  elif grep -qi 'host key verification failed' "$B/negative-control.err"; then
    echo "negative control refused: $(grep -m1 -i 'verification failed' "$B/negative-control.err")" | tee "$B/negative-control"
  else  # a timeout or auth error is not a pin refusal
    echo "NEGATIVE CONTROL INCONCLUSIVE: $(head -1 "$B/negative-control.err")" | tee "$B/negative-control"; exit 1
  fi

  # Clock offset machine - local, bounded by half the round trip over the open master.
  a=$EPOCHREALTIME; rt=$(ssh_pinned 'date +%s.%N'); b=$EPOCHREALTIME
  off=$(awk -v a="$a" -v b="$b" -v r="$rt" 'BEGIN{printf "%.3f", r-(a+b)/2}')
  awk -v a="$a" -v b="$b" -v o="$off" 'BEGIN{printf "offset=%s s (+/- %.3f s)\n", o, (b-a)/2}' | tee "$B/clock"

  # Wait for the hook to finish (the dead relay holds it to the deadline), then read the machine.
  for t in $(seq 60); do ssh_pinned 'grep -q hook-end /var/log/attest-hook.log' && break; sleep 5; done
  ssh_pinned 'cat /var/log/attest-hook.log' > "$B/attest-hook.log"
  while read -r t line; do
    [[ $t =~ ^[0-9]+\.[0-9]+$ ]] || continue
    case $line in hook-start*|nak-*|wrap-built*|publish-start*|OK*|scrub-*|GIVE-UP*|hook-end) ;; *) continue;; esac
    ev "machine: $(cut -c1-90 <<<"$line")" "$(awk -v t="$t" -v o="$off" 'BEGIN{printf "%.6f", t-o}')"
  done < "$B/attest-hook.log"
  while read -r f a b; do  # host key files' mtime, as the machine's clock saw it
    ev "machine: host key written $f" "$(awk -v t="$b" -v o="$off" 'BEGIN{printf "%.6f", t-o}')"
  done < <(sed -n 's/^[0-9.]* hostkey-file \(\S*\) birth=\(\S*\) mtime=\(\S*\)$/\1 \2 \3/p' "$B/attest-hook.log")
  ssh_pinned 'grep PRETTY_NAME /etc/os-release; cloud-init --version; uname -r; cut -d" " -f1 /proc/uptime' > "$B/versions"
  ssh_pinned 'cloud-init status --long; echo; cloud-init analyze show; echo; cloud-init analyze blame; echo; systemd-analyze; systemd-analyze blame | head -15' > "$B/boot-analysis.txt" 2>&1 || true
  ssh_pinned 'journalctl -o short-unix --no-pager -u ssh -u sshd -u cloud-init -u cloud-config -u cloud-final -b | head -60' > "$B/journal.txt" 2>&1 || true

  # CNF-61: read the disk for the sender key, and ask the metadata endpoint for user-data.
  printf '%s\n' "$S" | ssh_pinned 'grep -rlF -f - / --exclude-dir=proc --exclude-dir=sys --exclude-dir=dev 2>/dev/null; echo "grep-exit=$?"' > "$B/disk-scan" || true
  ssh_pinned 'grep -rlF "RECIPIENT_PUB=" /var/lib/cloud /run/cloud-init /var/log /root /etc 2>/dev/null' > "$B/userdata-copies" || true
  printf '%s\n' "$S" | ssh_pinned 'k=$(cat); u=$(curl -s http://169.254.169.254/hetzner/v1/userdata); printf "metadata-userdata-bytes=%s sender-key-occurrences=%s\n" "${#u}" "$(grep -cFf <(printf "%s\n" "$k") <<<"$u")"' > "$B/metadata" || true
  echo "disk: $(tr '\n' ' ' < "$B/disk-scan")"; cat "$B/metadata"

  # Stored vs delivered live: is each subscriber still alive, and does a fresh REQ return it?
  while read -r n p; do
    kill -0 "$p" 2>/dev/null && a=alive || a=exited
    b=$("$NAK" req -k 1059 -p "$RP" "wss://$n" </dev/null 2>/dev/null | grep -c . || true)
    echo "$n subscriber=$a stored-wraps=$b" | tee -a "$B/relay-check"
  done < "$B/subscriber-pids"

  ssh -o ControlPath="$CM" -O exit x 2>/dev/null || true
  api DELETE "/servers/$SERVER_ID" > /dev/null; ev server-deleted; echo "$SERVER_ID" >> "$WORK/deleted-server-ids"
  # Gone only on a 404; a transient error keeps SERVER_ID so the EXIT trap retries the delete.
  for t in $(seq 30); do
    [ "$(curl -s -o /dev/null -w '%{http_code}' -H @"$HDR" "$API/servers/$SERVER_ID")" = 404 ] && { SERVER_ID=''; break; }
    sleep 2
  done
  [ -z "$SERVER_ID" ] || { echo "server $SERVER_ID not confirmed deleted"; exit 1; }
  cleanup
  echo "boot record: $B"
}

clean() {  # sweep, delete our ssh key, show what the project holds, drop the header file
  hdr; sweep
  if [ -s "$WORK/ssh-key-id" ]; then api DELETE "/ssh_keys/$(cat "$WORK/ssh-key-id")" >/dev/null; rm "$WORK/ssh-key-id"; fi
  echo "servers: $(api GET /servers | jq -c '[.servers[] | {name, labels}]')"
  echo "ssh_keys: $(api GET /ssh_keys | jq -c '[.ssh_keys[].name]')"
  rm -f "$HDR"
}

selftest() {  # the acceptance check accepts the planted sender and refuses an impostor
  local S X R RP B=$WORK/selftest w content
  nak_local; mkdir -p "$B"; IP=192.0.2.9
  S=$("$NAK" key generate </dev/null); X=$("$NAK" key generate </dev/null); R=$("$NAK" key generate </dev/null)
  RP=$(pubkey "$R")
  rm -f "$B/hk" "$B/hk.pub"; ssh-keygen -q -t ed25519 -N '' -f "$B/hk"
  content="$(ssh-keygen -lf "$B/hk.pub" | awk '{print $2}') $(cut -d' ' -f1,2 "$B/hk.pub")"
  w=$(NOSTR_SECRET_KEY=$S "$NAK" event -k 14 -c "$content" </dev/null 2>/dev/null \
      | NOSTR_SECRET_KEY=$S "$NAK" gift wrap -p "$RP" --use-our-identity-key --use-their-identity-key 2>/dev/null)
  [ "$(accept "$w" "$R" "$(pubkey "$S")")" = "$content" ] || { echo "FAIL: planted sender refused"; exit 1; }
  pin "$content" || { echo "FAIL: pin refused a matching fingerprint"; exit 1; }
  ! accept "$w" "$R" "$(pubkey "$X")" >/dev/null || { echo "FAIL: impostor author accepted"; exit 1; }
  ! pin "SHA256:AAAA $(cut -d' ' -f1,2 "$B/hk.pub")" || { echo "FAIL: pin accepted a wrong fingerprint"; exit 1; }
  rm -rf "$B"; echo "selftest ok"
}

case "${1:-}" in
  setup) setup;;
  boot) shift; boot "$@";;
  clean) clean;;
  selftest) selftest;;
  all)
    selftest; setup
    boot fsn1 cx23 debian-13; boot hel1 cx23 debian-13; boot nbg1 cpx12 debian-13
    boot fsn1 cx23 debian-13; boot hel1 cx23 debian-13; boot hel1 cx23 ubuntu-24.04
    clean;;
  *) echo "usage: $0 selftest|setup|boot LOCATION TYPE IMAGE|clean|all"; exit 2;;
esac
