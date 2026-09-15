#!/usr/bin/env sh
# CORS probe (CNF-4, ARC-34). Asserts on Access-Control-* headers, never on success:
# the corpus was fooled once by a probe that measured a 200 (02-channel.md, CHN-R1).
# Unauthenticated, harmless, one OPTIONS and one GET per origin with a browser Origin.
# Exit 1 when any origin's route differs from the table below. Run from the pinned
# spec tree by the implementation repository's CI (ADR-0031).
set -u
ORIGIN=https://tau-web.invalid
fail=0

# origin  path  expect  — expect is "cors" (allow-origin present) or "none" (no Access-Control-* at all)
probe() {
  host=$1 path=$2 expect=$3
  hdrs=$(curl -sS -m 20 -o /dev/null -D - -X OPTIONS "https://$host$path" \
    -H "Origin: $ORIGIN" -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: authorization,content-type" 2>&1; echo; \
    curl -sS -m 20 -o /dev/null -D - "https://$host$path" -H "Origin: $ORIGIN" 2>&1)
  got=$(printf '%s' "$hdrs" | grep -i -c '^access-control-allow-origin:')
  any=$(printf '%s' "$hdrs" | grep -i -c '^access-control-')
  case $expect in
    cors) [ "$got" -ge 1 ] && r=ok || r=FAIL ;;
    none) [ "$any" -eq 0 ] && r=ok || r=FAIL ;;
  esac
  printf '%-4s %-28s %-24s expect=%-4s allow-origin=%s any=%s\n' "$r" "$host" "$path" "$expect" "$got" "$any"
  [ "$r" = ok ] || fail=1
}

probe api.ppq.ai              /v1/chat/completions   cors   # procured inference, direct (ADR-0028)
probe api.ppq.ai              /v1/api-keys           cors   # session-key minting, direct (ARC-31a)
probe robot-ws.your-server.de /server                none   # Robot: no CORS, rides the pinned tunnel (CHN-R1, CHN-12a)

exit $fail
