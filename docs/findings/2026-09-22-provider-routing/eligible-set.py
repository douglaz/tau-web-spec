#!/usr/bin/env python3
"""The eligible set and the flagged candidates, computed from a committed model-list snapshot.

ADR-0033's badge rule, applied to `models-<date>.json` as the aggregator returned it. Every
count the ADR, the finding or the bundle cites comes from running this, never from prose:
`python3 eligible-set.py models-2026-09-23.json`. The allowlist ADR-0033 adds beside the badge
is the publisher's and is not computed here.
"""
import collections
import json
import sys

models = json.load(open(sys.argv[1]))["data"]
has_tools = lambda m: "tools" in (m.get("supported_parameters") or [])
eligible = [m for m in models if m.get("privacyLevel") == "zdr" and has_tools(m)]
flagged = [m for m in eligible if m.get("popular")]

print(f"listed: {len(models)}")
print(f"privacyLevel: {dict(collections.Counter(m.get('privacyLevel') for m in models))}")
print(f"eligible (zero-retention badge + tool calls): {len(eligible)}")
print(f"of those flagged popular: {len(flagged)}")
for m in flagged:
    print(f"  {m['id']}  context={m.get('context_length')}  owned_by={m.get('owned_by')}")

popular = [m for m in models if m.get("popular")]
unbadged = [m for m in popular if m.get("privacyLevel") != "zdr"]
print(f"flagged popular overall: {len(popular)}, of which not badged zdr: {len(unbadged)}")

print("badge by owner (zdr / all):")
for owner in ("Anthropic", "OpenAI", "Google", "Z.ai", "DeepSeek", "Qwen"):
    own = [m for m in models if m.get("owned_by") == owner]
    print(f"  {owner}: {sum(1 for m in own if m.get('privacyLevel') == 'zdr')} / {len(own)}")
