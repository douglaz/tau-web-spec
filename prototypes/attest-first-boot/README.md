# Attest on a real vendor's first boot (T40, OPN-3)

**PROTOTYPE — throwaway.** This is not harness code. It answers one question: on a real cloud
vendor's first boot, does the attest hook (`CHN-R5`, `CHN-4`, `CHN-6`) fire and reach the relay
set? How long does it take from the create call to the browser receiving the wrap, and how does
that compare with the browser's window? Result:
`docs/findings/2026-10-09-attest-first-boot.md`.

The vendor is Hetzner Cloud. It has no Arch image, so the boots are Debian 13 and Ubuntu 24.04,
running the upstream glibc `nak` release. The keys are random, so derivation is not exercised.

## Run

```sh
export HETZNER_CLOUD=...   # a Hetzner Cloud API token; read once into $WORK/auth.hdr (mode 600)
./run.sh all               # selftest, setup, six boots one at a time, clean
```

Steps can also be run one at a time: `./run.sh selftest`, `./run.sh setup`,
`./run.sh boot LOCATION TYPE IMAGE` (for example `boot hel1 cx23 debian-13`), and
`./run.sh clean`. Running `clean` deletes the SSH key this prototype registered, prints the
project's servers and SSH keys, and removes the header file. If `all` stops on a failed boot,
run `./run.sh clean` by hand. It also deletes any labelled server still left.

The script needs `curl`, `jq`, `ssh`, `ssh-keygen` and bash 5. It fetches the pinned `nak`
release itself and checks its sha256. Everything a boot produces lands in `$WORK` (default
`/var/tmp/attest-proto`), never in this directory: the throwaway keys, API responses, addresses
and logs. Delete it afterwards. Every server is labelled `purpose=attest-proto`. Each one is
deleted by ID once its measurements are done, and an exit trap deletes it if the run is
interrupted. The next `boot` or `clean` deletes any labelled server a killed run left behind.
Cost: one hourly unit of the server type per boot.

## What it does

1. **Keys.** Each boot gets a fresh sender keypair, whose secret goes into user-data, and a
   fresh recipient keypair, whose public half goes into user-data.
2. **The browser.** Before the create call, one `nak req --stream` per live relay subscribes to
   kind 1059 filtered by `#p` = recipient, with no `since`, because wrap timestamps are
   randomised into the past. Each line it receives is stamped with the local clock. To accept a
   wrap, the script:
   - decrypts the seal with the recipient key and verifies the seal's signature;
   - requires the seal's author to be the planted sender and the rumor's pubkey to equal it;
   - recomputes the fingerprint of every sealed host-key line, which must equal the fingerprint
     sealed beside it.

   `known_hosts` is built from those lines only. `./run.sh selftest` checks that an impostor
   author and a wrong fingerprint are both refused.
3. **The machine** (`user-data.yaml.in`). A `runcmd` hook runs after cloud-init's ssh module.
   - It records the host-key files' times.
   - It downloads `nak`, timing the download separately, and runs `sha256sum -c` before
     executing it.
   - It seals `<fingerprint> <type> <key>` per host key under the sender key and gift-wraps it
     to the recipient with `--use-our-identity-key --use-their-identity-key`. Every call
     redirects standard input.
   - It publishes to every relay in the set in parallel. Each relay is retried with backoff
     (1 s doubling to 30 s) until it answers OK or the 120 s deadline passes.
   - On the first OK from any relay it scrubs the sender key from cloud-init's artifacts.

   It logs to `/var/log/attest-hook.log`. The set is three public relays plus `wss://192.0.2.1`
   (TEST-NET-1), a dead relay whose connect never completes.
4. **Pass check.** SSH as root with `StrictHostKeyChecking=yes` against the attested
   `known_hosts`. A negative control repeats the check against a `known_hosts` holding a key that
   is not the host's, and must be refused.
5. **After.** The script reads `cloud-init analyze` and the hook log over the pinned session. It
   scans the whole disk for the sender key and asks the metadata endpoint for user-data
   (`CNF-61`). It checks whether each relay still returns the wrap to a fresh REQ, then deletes
   the server.
