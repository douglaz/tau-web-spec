# Publisher discovery input schema

CHN-19 owns the compiled publisher key and public discovery starting set; [paid-tcp-relay][relay-source]
WIR-14 owns the announcement format. This is a schema template for the required
`bundle/relay-discovery.toml`, not a bundle file or deployment values:

```toml
# CHN-19: compiled from the pinned specification commit.
publisher_pubkey = "<64 lowercase hex characters>"
nostr_relays = [
  { url = "wss://<public discovery endpoint>/", operator = "<operator name>" },
  { url = "wss://<independently hosted discovery endpoint>/", operator = "<operator name>" },
]
```

Select and validate deployment values under `CHN-19`; for the trust display, see `TRU-A2`.
Commit the usable bundle file with its row in `bundle/README.md`. No TCP domain, signing key
or discovery service is selected by these example strings. For starting-set and notify-input
authority, see `CHN-19` and `SEC-8`.

[relay-source]: https://github.com/douglaz/paid-tcp-relay/tree/ba316fc4f734deb93d76561d8703551377987654
