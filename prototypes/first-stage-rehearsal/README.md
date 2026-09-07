# First-stage rehearsal by hand (T1, STG-2)

One operator, one disposable Hetzner **dedicated** server, one sitting. Answers `OPN-6`
(what Robot's rescue `host_key` holds once rescue is active), checks `ARC-24`/`ARC-25` (Alpine
installed from inside rescue, from a versioned URL with a sibling `.sha256`), `STG-4`/`CNF-22`
(the installed system's host keys read from inside rescue, so the second hop pins without
trust-on-first-use), and times `STG-16`.

Nothing here is harness code. It is `curl` against Robot and `ssh` from this box, scripted so
that every value is captured and nothing is typed twice.

## Before you run it (human-only steps)

1. Rent a dedicated server you are willing to wipe. Note its **server number** (Robot → Servers).
2. Robot → Settings → Webservice/app settings: create a webservice user. This is HTTP Basic;
   Robot has no token scheme.
3. `cp rehearse.env.example rehearse.env` and fill it in. The file is git-ignored and is the
   only place the credentials go. `rehearse.sh` sources it.
4. Make sure `jq`, `curl`, `ssh`, `ssh-keygen` are on the path (the wasm-spikes devshell has them).

## Run

```sh
./rehearse.sh preflight     # read-only: server, current rescue state, installer catalogue, keys
./rehearse.sh rescue        # REBOOTS THE MACHINE: registers the key, activates rescue, resets, waits for ssh
./rehearse.sh install       # runs install-alpine.sh inside rescue, reads the new host keys before reboot
./rehearse.sh reboot        # resets into the installed system, connects with the pre-read host key
./rehearse.sh all           # the four in order, with a confirmation before anything that reboots
```

Everything it learns goes into `findings/<date>/`: redacted JSON captures (`password` fields
are replaced before touching disk), a `timeline.tsv` of wall-clock stamps, and `notes.md`.
Public key material is recorded in full — it is public. Passwords and the Basic credential are
never written.

## What to bring back

`findings/<date>/notes.md` plus the captures, then a `/grill-with-docs` round in the corpus:
`OPN-6` should close, `OPN-3` narrow, `CNF-48` be recorded, and `STG-*` items amended where
Robot or rescue behaved differently from the text.
