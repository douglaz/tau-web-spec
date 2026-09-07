#!/usr/bin/env bash
# Stub bridges (websocat, no auth — the real relay's NIP-42 access is out of scope), a
# non-root sshd on 2223 with a fresh host key, and a static server for www/. Run inside the
# devshell. Everything listens on the address in BIND (default 127.0.0.1; use 0.0.0.0 to
# reach it from a phone on the LAN).
set -euo pipefail
cd "$(dirname "$0")/.."
BIND="${BIND:-127.0.0.1}"
RUN="${RUN:-$PWD/run}"
mkdir -p "$RUN"

[ -f "$RUN/hk" ] || ssh-keygen -q -t ed25519 -N '' -f "$RUN/hk" -C spike-host
touch "$RUN/authorized_keys"
cat > "$RUN/sshd_config" <<EOF
Port 2223
ListenAddress 127.0.0.1
HostKey $RUN/hk
AuthorizedKeysFile $RUN/authorized_keys
PasswordAuthentication no
KbdInteractiveAuthentication no
PidFile none
StrictModes no
LogLevel VERBOSE
EOF
"$(command -v sshd)" -f "$RUN/sshd_config" -D -e >"$RUN/sshd.log" 2>&1 &
websocat -E -b "ws-l:$BIND:8084" tcp:127.0.0.1:2223 >"$RUN/bridge-ssh.log" 2>&1 &
websocat -E -b "ws-l:$BIND:8082" tcp:robot-ws.your-server.de:443 >"$RUN/bridge-robot.log" 2>&1 &
websocat -E -b "ws-l:$BIND:8083" tcp:api.hetzner.cloud:443 >"$RUN/bridge-other.log" 2>&1 &
python3 -m http.server 8000 --bind "$BIND" -d www >"$RUN/http.log" 2>&1 &
echo "$!" > "$RUN/pids"; jobs -p >> "$RUN/pids"
sleep 1
echo "host key fingerprint: $(ssh-keygen -lf "$RUN/hk.pub" | awk '{print $2}')"
echo "page: http://$BIND:8000/   bridges: ws://$BIND:8084 (sshd) 8082 (robot) 8083 (other issuer)"
echo "stop: kill \$(cat $RUN/pids)"
wait
