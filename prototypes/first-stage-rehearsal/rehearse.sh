#!/usr/bin/env bash
# The first stage by hand, once (STG-2, TASKS.md T1). See README.md.
set -euo pipefail
cd "$(dirname "$0")"
# Credentials come from rehearse.env, or from the shell (HETZNER_ROBOT_USER/PASS) so nothing
# secret need touch disk. SERVER_NUMBER and SSH_KEY may come from either too.
# shellcheck disable=SC1091
[ -f rehearse.env ] && . ./rehearse.env
ROBOT_USER=${ROBOT_USER:-${HETZNER_ROBOT_USER:-}}; ROBOT_PASS=${ROBOT_PASS:-${HETZNER_ROBOT_PASS:-}}
SSH_KEY=${SSH_KEY:-$HOME/.ssh/tau-rehearsal}
: "${ROBOT_USER:?}" "${ROBOT_PASS:?}" "${SERVER_NUMBER:?set SERVER_NUMBER (Robot server number)}" "${SSH_KEY:?}"
[ -f "$SSH_KEY" ] || { echo "SSH_KEY $SSH_KEY missing: ssh-keygen -t ed25519 -f $SSH_KEY -N ''"; exit 2; }

API=https://robot-ws.your-server.de
F="findings/$(date -u +%F)"; mkdir -p "$F/captures"
NOTES="$F/notes.md"; TL="$F/timeline.tsv"; KH="$F/known_hosts"
touch "$NOTES" "$TL"
stamp() { printf '%s\t%s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "$TL"; }
note() { printf '%s\n' "$*" | tee -a "$NOTES"; }

# Every Robot call: credentials from the env file only; the JSON lands in captures/ with any
# `password` field replaced before it touches disk. Prints the redacted body.
robot() {  # robot <name> <method> <path> [curl data args...]
  local name=$1 method=$2 path=$3; shift 3
  local raw code
  raw=$(curl -sS -u "$ROBOT_USER:$ROBOT_PASS" -X "$method" "$API$path" -w '\n%{http_code}' "$@")
  code=${raw##*$'\n'}; raw=${raw%$'\n'*}
  printf '%s' "$raw" | jq 'walk(if type=="object" and has("password") then .password = (if .password==null then null else "<redacted>" end) else . end)' \
    > "$F/captures/$name.json" 2>/dev/null || printf '%s' "$raw" > "$F/captures/$name.json"
  stamp "$method $path -> $code (captures/$name.json)"
  cat "$F/captures/$name.json"; echo
  [[ $code == 2* ]] || { note "**Robot returned $code for $method $path** — see captures/$name.json"; return 1; }
}

confirm() { read -r -p "$1 — type yes to continue: " a; [ "$a" = yes ] || { echo aborted; exit 1; }; }
server_ip() { jq -r '.server.server_ip' "$F/captures/server.json"; }
wait_ssh() {  # wait_ssh <label>: poll port 22, record when it answers and what host keys it presents
  local ip; ip=$(server_ip)
  stamp "waiting for ssh on $ip ($1)"
  until ssh-keyscan -T 5 "$ip" > "$F/captures/keyscan-$1.txt" 2>/dev/null && [ -s "$F/captures/keyscan-$1.txt" ]; do sleep 5; done
  stamp "ssh answering on $ip ($1)"
  note "Host keys presented on the wire ($1), via ssh-keyscan:"; sed 's/^/    /' "$F/captures/keyscan-$1.txt" | tee -a "$NOTES"
}
ssh_pinned() {  # ssh with ONLY the pre-recorded host key: any TOFU prompt or mismatch is a failure
  ssh -i "$SSH_KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$KH" -o BatchMode=yes "root@$(server_ip)" "$@"
}

preflight() {
  note "# First-stage rehearsal — $(date -u +%F)"
  note "Server number: $SERVER_NUMBER. Robot base URL: $API (from Hetzner's own API docs)."
  robot server GET "/server/$SERVER_NUMBER" >/dev/null
  note "Server: $(jq -c '.server | {server_ip, server_name, product, dc, status}' "$F/captures/server.json")"
  robot rescue-before GET "/boot/$SERVER_NUMBER/rescue" >/dev/null
  note "Rescue before activation — \`host_key\`: $(jq -c '.rescue.host_key' "$F/captures/rescue-before.json"), \`os\` offered: $(jq -c '.rescue.os' "$F/captures/rescue-before.json")"
  robot linux-catalogue GET "/boot/$SERVER_NUMBER/linux" >/dev/null
  note "Automatic-install catalogue (\`dist\`): $(jq -c '.linux.dist' "$F/captures/linux-catalogue.json")"
  robot keys-before GET /key >/dev/null || true
  note "Preflight done; no state changed."
}

rescue() {
  local pub fp
  pub=$(cat "$SSH_KEY.pub")
  # Robot addresses keys by MD5 colon fingerprint; register ours (idempotent: reuse if present).
  fp=$(jq -r --arg d "$pub" '.[] | .key | select((.data|split(" ")[0:2]|join(" ")) == ($d|split(" ")[0:2]|join(" "))) | .fingerprint' "$F/captures/keys-before.json" 2>/dev/null | head -1 || true)
  if [ -z "$fp" ]; then
    robot key-create POST /key --data-urlencode "name=tau-rehearsal-$(date -u +%F)" --data-urlencode "data=$pub" >/dev/null
    fp=$(jq -r '.key.fingerprint' "$F/captures/key-create.json")
  fi
  note "Registered client key fingerprint (Robot format): \`$fp\`; local: \`$(ssh-keygen -lf "$SSH_KEY.pub" | awk '{print $2}')\`"

  confirm "POST /boot/$SERVER_NUMBER/rescue then a hardware reset: the machine reboots into rescue"
  stamp "T0 rescue activation"
  robot rescue-activate POST "/boot/$SERVER_NUMBER/rescue" -d os=linux --data-urlencode "authorized_key[]=$fp" >/dev/null
  note "## OPN-6 — \`host_key\` after activation (CNF-48)"
  note '```json'; jq '.rescue.host_key' "$F/captures/rescue-activate.json" | tee -a "$NOTES"; note '```'
  note "Whole activation object (redacted): captures/rescue-activate.json. \`authorized_key\` echoed as: $(jq -c '.rescue.authorized_key' "$F/captures/rescue-activate.json")"
  robot rescue-after GET "/boot/$SERVER_NUMBER/rescue" >/dev/null
  note "GET after activation, \`host_key\` identical to POST's: $(cmp -s <(jq -S '.rescue.host_key' "$F/captures/rescue-activate.json") <(jq -S '.rescue.host_key' "$F/captures/rescue-after.json") && echo yes || echo NO)"

  # CHN-R1: pin from the API before first contact. Accept either full keys or fingerprints —
  # which one Robot returns is the finding. Full keys become a known_hosts file; fingerprints are
  # compared against the keyscan below.
  : > "$KH"
  jq -r '.rescue.host_key[]' "$F/captures/rescue-activate.json" | while read -r hk; do
    case "$hk" in ssh-*|ecdsa-*|sk-*) echo "$(server_ip) $hk" >> "$KH";; esac
  done
  stamp "T1 hardware reset"
  robot reset POST "/reset/$SERVER_NUMBER" -d type=hw >/dev/null
  wait_ssh rescue
  note "Wire fingerprints (rescue): "; ssh-keygen -lf "$F/captures/keyscan-rescue.txt" | sed 's/^/    /' | tee -a "$NOTES"
  if [ -s "$KH" ]; then
    note "API published full keys → known_hosts built from the API alone. Pinned login:"
    ssh_pinned 'echo PINNED-RESCUE-LOGIN-OK; uname -a; lsblk -dno NAME,SIZE,MODEL' | tee -a "$NOTES" && stamp "T2 rescue login over API-pinned host key"
  else
    note "API published no full keys (fingerprints or empty) — compare the lines above by hand; recording as a finding for CHN-R1."
    cp "$F/captures/keyscan-rescue.txt" "$KH"; stamp "T2 rescue reachable; pin was NOT from the API"
  fi
}

install() {
  [ -s "$KH" ] || { echo "no known_hosts from the rescue step"; exit 1; }
  if [ -z "${DISK:-}" ]; then ssh_pinned 'lsblk -dno NAME,SIZE,MODEL,TRAN'; echo "set DISK in rehearse.env and rerun install"; exit 1; fi
  confirm "install Alpine onto $DISK inside rescue (wipes the disk)"
  stamp "T3 install start"
  ssh_pinned "DISK=$DISK AUTHORIZED_KEY='$(cat "$SSH_KEY.pub")' sh -s" < install-alpine.sh 2>&1 | tee "$F/captures/install-transcript.txt"
  stamp "T4 install end (transcript $(wc -c < "$F/captures/install-transcript.txt") bytes — CNF-47)"
  # STG-4 / CNF-22: the installed system's host keys, read inside rescue, become the pin for hop two.
  sed -n '/=== INSTALLED HOST KEYS/,/=== END HOST KEYS/p' "$F/captures/install-transcript.txt" | grep -E '^(ssh-|ecdsa-)' | sed "s/^/$(server_ip) /" > "$KH.installed"
  note "## STG-4 — installed host keys read inside rescue before reboot"; note '```'; cat "$KH.installed" | tee -a "$NOTES"; note '```'
  [ -s "$KH.installed" ] || note "**No host keys captured from the install transcript** — read captures/install-transcript.txt"
}

reboot_installed() {
  [ -s "$KH.installed" ] || { echo "no installed host keys recorded; run install first"; exit 1; }
  confirm "hardware reset into the installed system"
  stamp "T5 reset into installed system"
  robot reset-installed POST "/reset/$SERVER_NUMBER" -d type=hw >/dev/null
  wait_ssh installed
  cp "$KH.installed" "$KH"
  note "Second hop, pinned from the pre-reboot read (no TOFU):"
  ssh_pinned 'echo PINNED-INSTALLED-LOGIN-OK; cat /etc/alpine-release; uname -a' | tee -a "$NOTES" && stamp "T6 installed login over pre-read host key"
  note "## STG-16 timeline"; note '```'; cat "$TL" | tee -a "$NOTES"; note '```'
  note "Rescue is still the active boot config until it is used once; check \`GET /boot/$SERVER_NUMBER/rescue\` and note \`active\`:"
  robot rescue-final GET "/boot/$SERVER_NUMBER/rescue" | jq -c '.rescue | {active, host_key}' | tee -a "$NOTES"
}

case "${1:-}" in
  preflight) preflight;;
  rescue) rescue;;
  install) install;;
  reboot) reboot_installed;;
  all) preflight; rescue; install; reboot_installed;;
  *) echo "usage: $0 preflight|rescue|install|reboot|all"; exit 2;;
esac
echo "findings in $F"
