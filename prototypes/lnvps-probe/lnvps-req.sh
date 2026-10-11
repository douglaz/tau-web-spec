#!/usr/bin/env bash
# One NIP-98-signed request to the LNVPS API, signed by the key in $1 and nothing else.
# Builds the authorization event with `nak event`, which honours the key it is given, rather than
# `nak curl`, which signs with nak's default key whatever --sec says. A random nonce tag keeps
# two identical requests in one second from colliding as a replayed event id; a body is bound
# by its SHA-256 in a `payload` tag.
# Usage: lnvps-req.sh KEYFILE METHOD PATH [JSON-BODY]
set -eu
NAK=${NAK:-nak}
API=${LNVPS_API:-https://api.lnvps.net}
[ $# -ge 3 ] || { echo "usage: $0 KEYFILE METHOD PATH [JSON-BODY]" >&2; exit 2; }
sec=$(cat "$1"); method=$2; url="$API$3"
tags=(-t "u=$url" -t "method=$method" -t "nonce=$(od -An -tx8 -N8 /dev/urandom | tr -d ' ')")
if [ $# -ge 4 ]; then
  tags+=(-t "payload=$(printf %s "$4" | sha256sum | cut -d' ' -f1)")
fi
# The key travels in the environment, never in an argument list another user could read.
ev=$(NOSTR_SECRET_KEY="$sec" $NAK event -k 27235 -c '' "${tags[@]}" </dev/null)
auth="Authorization: Nostr $(printf %s "$ev" | base64 -w0)"
if [ $# -ge 4 ]; then
  curl -sS --fail-with-body -X "$method" -H "$auth" -H 'content-type: application/json' \
    --data-binary "$4" "$url"
else
  curl -sS --fail-with-body -X "$method" -H "$auth" "$url"
fi
