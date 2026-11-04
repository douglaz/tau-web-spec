# Issue tracker: beads (`br`)

Issues, specs and tickets for this repo live in beads: `.beads/issues.jsonl`, committed, with
`.beads/beads.db` as the local working copy. Issue prefix `tw`.

## Conventions

- A spec is one issue of type `epic`; its tickets are issues created with `--parent <epic>`.
- Blocking is native: `br dep add <ticket> <blocker>`. `br ready` lists open, unblocked, undeferred
  work; it is the frontier, worked in id order.
- Triage state is a label (see `triage-labels.md`): `br label add <id> <label>`.
- Never hand-edit `issues.jsonl`: `updated_at` goes stale and the next `br update` or `br close`
  silently reverts the edit. Every change goes through `br`.
- Before committing, `br sync --flush-only` so the JSONL matches the database; commit
  `.beads/issues.jsonl` with the change it tracks. `beads.db` is not committed.
- The export is public, and carries no local path. `br create` records `source_repo_path`, the
  absolute path of the checkout that made the issue, and no `br` setting turns that off. After
  `br create`, run `bash tools/tracker-strip-local-paths.sh` before committing: it flushes,
  removes the key from every record, and rebuild-imports (`br sync --import-only --rebuild`), so
  the database stops exporting it. Stripping the JSONL alone does not hold: a plain import keeps
  the database's copy and the next write exports the path again. `tools/check_tracker_paths.py`
  (in `check-all.sh`) is red on the key, or on a home-directory or scratch path in any field, so
  a path that reaches a commit cannot merge. `source_repo` (the repository name) stays.
- 2026-11-04: the key was removed from every record once, by that script's `jq` step and a
  rebuild import: the one edit of the export made outside `br`, and it changed no other field.
  Git history keeps the old values. A working database made before then still holds them: run
  the script once, before its next write. Not a bare `br sync --import-only --rebuild`: the
  rebuild drops whatever the database holds that the export does not, and the script flushes
  first.

## When a skill says "publish to the issue tracker"

A spec: `br create --type epic --title "<spec title>" --description-file <spec.md>
--labels ready-for-agent`. A ticket: `br create --parent <epic> --deps <blocker,...> --title ...
--description-file <ticket.md>`. Then `bash tools/tracker-strip-local-paths.sh`, which flushes.

## When a skill says "fetch the relevant ticket"

`br show <id>`. The user will normally pass the id.

## Wayfinding operations

Used by `/wayfinder`. The **map** is an `epic`; each **child** is an issue under it.

- **Child ticket**: `br create --parent <map> --labels type:<research|prototype|grilling|task>`
  with the question as the description.
- **Blocking**: `br dep add <child> <blocker>`; a child is unblocked when every blocker is closed.
- **Frontier**: `br ready`, filtered to the map's children; lowest id wins.
- **Claim**: `br update <id> --status in_progress` before any work.
- **Resolve**: `br comments add <id> "<answer>"`, `br close <id>`, then append a one-line pointer
  (gist plus the child's id) to the map's description with `br update <map> --description-file`.
