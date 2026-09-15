#!/usr/bin/env sh
# CORS probe (CNF-4, ARC-34). Asserts on Access-Control-* headers, never on success:
# the corpus was fooled once by a probe that measured a 200 (02-channel.md, CHN-R1).
# Unauthenticated, harmless, one OPTIONS preflight and one GET per origin with a browser
# Origin, each judged on its own. A transport failure is a probe failure, never evidence.
# Exit 1 when any origin's route differs from the table below. Run from the pinned spec
# tree by the implementation repository's CI (ADR-0031).
set -u
ORIGIN=https://tau-web.invalid
fail=0

# Headers of one request, or "CURL_FAILED <code>" on transport failure.
headers() {  # method path host [extra curl args...]
  m=$1 p=$2 h=$3; shift 3
  out=$(curl -sS -m 20 -o /dev/null -D - -X "$m" "https://$h$p" -H "Origin: $ORIGIN" "$@" 2>/dev/null) \
    || { echo "CURL_FAILED $?"; return; }
  printf '%s\n' "$out"
}

# cors: the preflight must allow this origin and the requested headers, and the GET must
# allow this origin — both, independently, as a browser requires.
# none: neither response carries any Access-Control-* header at all.
probe() {
  host=$1 path=$2 expect=$3
  pre=$(headers OPTIONS "$path" "$host" -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: authorization,content-type")
  get=$(headers GET "$path" "$host")
  case "$pre$get" in *CURL_FAILED*) printf 'FAIL %-28s %-24s transport: %s %s\n' "$host" "$path" "$pre" "$get" | tr -s ' \n' ' '; echo; fail=1; return ;; esac
  allow() { printf '%s' "$1" | grep -i "^access-control-allow-origin:" | grep -q -i -e "\*" -e "$ORIGIN"; }
  hdrs() { printf '%s' "$1" | grep -i "^access-control-allow-headers:" | grep -q -i "authorization"; }
  any() { printf '%s' "$1" | grep -q -i "^access-control-"; }
  case $expect in
    cors) allow "$pre" && hdrs "$pre" && allow "$get" && r=ok || r=FAIL ;;
    none) ! any "$pre" && ! any "$get" && r=ok || r=FAIL ;;
  esac
  printf '%-4s %-28s %-24s expect=%s\n' "$r" "$host" "$path" "$expect"
  [ "$r" = ok ] || fail=1
}

probe api.ppq.ai              /v1/chat/completions   cors   # procured inference, direct (ADR-0028)
probe api.ppq.ai              /v1/api-keys           cors   # session-key minting, direct (ARC-31a)
probe robot-ws.your-server.de /server                none   # Robot: no CORS, rides the pinned tunnel (CHN-R1, CHN-12a)

exit $fail
