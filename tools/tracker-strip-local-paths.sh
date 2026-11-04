#!/usr/bin/env bash
# Remove `source_repo_path` from every record of the issue export and make the stripped
# export the working database's truth. Run it after `br create` (which records the absolute
# path of the checkout that made the issue) and before committing `.beads/issues.jsonl`;
# tools/check_tracker_paths.py turns a path that reaches a commit red.
#
# Stripping the export alone does not hold: a plain import sees every record as up to date
# and keeps the database's copy, and the next write exports the paths again. The rebuild
# import replaces the database's records with the export's.
#
# Uses the database and export `br` resolves (BEADS_DB included). Changes no other field.
# Exit status 0 = the export and the database carry no `source_repo_path`.
set -euo pipefail

for tool in br jq; do
  command -v "$tool" >/dev/null 2>&1 || { echo "FAIL: $tool not on PATH"; exit 1; }
done

# Flush first, so the export holds every database change before it becomes the truth.
br sync --flush-only
jsonl="$(br --no-auto-flush --no-auto-import where --json | jq -er .jsonl_path)"

tmp="$(mktemp "$jsonl.strip.XXXXXXXX")"
trap 'rm -f -- "$tmp"' EXIT
jq -c 'del(.source_repo_path)' "$jsonl" > "$tmp"
if cmp -s "$tmp" "$jsonl"; then
  echo "no source_repo_path in $jsonl"
else
  mv -- "$tmp" "$jsonl"
  echo "stripped source_repo_path from $(basename "$jsonl")"
fi
br sync --import-only --rebuild

# The proof: a flush after the rebuild must not bring the field back.
br sync --flush-only
if [ "$(jq -s 'any(.[]; has("source_repo_path"))' "$jsonl")" != false ]; then
  echo "FAIL: source_repo_path is back in $jsonl after the rebuild import"
  exit 1
fi
