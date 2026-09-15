#!/usr/bin/env sh
# CORS probe (CNF-4, ARC-34). Asserts on Access-Control-* headers, never on success:
# the corpus was fooled once by a probe that measured a 200 (02-channel.md, CHN-R1).
# Unauthenticated, harmless, one OPTIONS preflight and one GET per origin with a browser
# Origin, each judged on its own the way a browser judges it. A transport failure is a
# probe failure, never evidence. Exit 1 when any origin's route differs from the table
# below. Run from the pinned spec tree by the implementation repository's CI (ADR-0031).
set -u
ORIGIN=https://tau-web.invalid
HERE=$(dirname "$0")
fail=0

# The inference host below must be the one bundle/inference.toml names (D5: one entry).
INFER_HOST=api.ppq.ai
grep -q "base_url = \"https://$INFER_HOST\"" "$HERE/inference.toml" \
  || { echo "FAIL inference host $INFER_HOST is not bundle/inference.toml's base_url"; fail=1; }

# Headers of one request, or "CURL_FAILED <code>" on transport failure.
headers() {  # method path host [extra curl args...]
  m=$1 p=$2 h=$3; shift 3
  out=$(curl -sS -m 20 -o /dev/null -D - -X "$m" "https://$h$p" -H "Origin: $ORIGIN" "$@" 2>/dev/null) \
    || { echo "CURL_FAILED $?"; return; }
  printf '%s\n' "$out"
}
hdr() { printf '%s' "$1" | grep -i "^$2:" | tr -d '\r' | cut -d: -f2- | tr 'A-Z' 'a-z'; }
status() { printf '%s' "$1" | grep -i -m1 '^HTTP/' | awk '{print $2}'; }
has() { printf ' %s ' "$1" | tr ',' ' ' | tr -s ' ' | grep -q " $2 "; }

# cors: the preflight must succeed (2xx), allow this origin or *, allow POST or *, and allow
# both requested header tokens; the GET must allow this origin or *. Both, independently.
# none: neither response carries any Access-Control-* header at all.
probe() {
  host=$1 path=$2 expect=$3
  pre=$(headers OPTIONS "$path" "$host" -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: authorization,content-type")
  get=$(headers GET "$path" "$host")
  case "$pre$get" in *CURL_FAILED*)
    printf 'FAIL %-28s %-24s transport failure\n' "$host" "$path"; fail=1; return ;; esac
  ao_pre=$(hdr "$pre" access-control-allow-origin); ao_get=$(hdr "$get" access-control-allow-origin)
  am=$(hdr "$pre" access-control-allow-methods); ah=$(hdr "$pre" access-control-allow-headers)
  st=$(status "$pre")
  case $expect in
    cors)
      r=ok
      case $st in 2*) ;; *) r=FAIL ;; esac
      { has "$ao_pre" '\*' || has "$ao_pre" "$ORIGIN"; } || r=FAIL
      { has "$am" '\*' || has "$am" post; } || r=FAIL
      { has "$ah" '\*' || { has "$ah" authorization && has "$ah" content-type; }; } || r=FAIL
      { has "$ao_get" '\*' || has "$ao_get" "$ORIGIN"; } || r=FAIL ;;
    none)
      if printf '%s%s' "$pre" "$get" | grep -q -i '^access-control-'; then r=FAIL; else r=ok; fi ;;
  esac
  printf '%-4s %-28s %-24s expect=%-4s preflight=%s\n' "$r" "$host" "$path" "$expect" "${st:-none}"
  [ "$r" = ok ] || fail=1
}

probe "$INFER_HOST"           /v1/chat/completions   cors   # procured inference, direct (ADR-0028)
probe "$INFER_HOST"           /v1/api-keys           cors   # session-key minting, direct (ARC-31a)
probe robot-ws.your-server.de /server                none   # Robot: no CORS, rides the pinned tunnel (CHN-R1, CHN-12a)

exit $fail
