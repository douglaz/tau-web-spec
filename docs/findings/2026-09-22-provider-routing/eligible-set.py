#!/usr/bin/env python3
"""The eligible set and the flagged candidates, computed from a committed model-list snapshot.

ADR-0033's rule, applied to `models-<date>.json` as the aggregator returned it. Every count the
ADR or the bundle cites comes from running this, never from prose: `python3 eligible-set.py
models-2026-09-23.json`.
"""
import json
import sys

models = json.load(open(sys.argv[1]))["data"]
eligible = [
    m for m in models
    if m.get("privacyLevel") == "zdr" and "tools" in (m.get("supported_parameters") or [])
]
flagged = [m for m in eligible if m.get("popular")]
print(f"listed: {len(models)}")
print(f"eligible (zero-retention tier + tool calls): {len(eligible)}")
print(f"of those flagged popular: {len(flagged)}")
for m in flagged:
    print(f"  {m['id']}  context={m.get('context_length')}  owned_by={m.get('owned_by')}")
