#!/usr/bin/env python3
"""Reproduce ARC-31b's selection and snapshot diagnostics using bundle inputs.

python3 eligible-set.py models-2026-09-23.json [--bundle path/to/inference.toml]
The proposing job imports the same selection function. Makers come from owned_by.
"""
import argparse
import collections
import json
from pathlib import Path
import tomllib

DEFAULT_BUNDLE = Path(__file__).resolve().parents[3] / "bundle/inference.toml"


def read_bundle(path):
    bundle = tomllib.loads(Path(path).read_text())
    session = bundle["session"]
    for key in ("context_floor", "depth"):
        if type(session.get(key)) is not int or session[key] <= 0:
            raise ValueError(f"session.{key} must be a positive integer")
    allowlist = session.get("allowlist")
    if not isinstance(allowlist, list) or any(not isinstance(s, str) or not s for s in allowlist):
        raise ValueError("session.allowlist must be a list of nonempty slugs")
    candidates = session.get("model")
    if not isinstance(candidates, list) or not candidates:
        raise ValueError("session.model must be a nonempty candidate list")
    for candidate in candidates:
        if not isinstance(candidate, dict) or set(candidate) != {"slug", "maker"}:
            raise ValueError("each candidate must carry slug and maker")
        if any(not isinstance(v, str) or not v for v in candidate.values()):
            raise ValueError("candidate slug and maker must be nonempty strings")
    if not isinstance(session.get("provider"), str) or not session["provider"]:
        raise ValueError("session.provider must be nonempty")
    if session.get("retention") != "strictest":
        raise ValueError("unsupported retention request")
    return bundle


def model_list(payload):
    if (not isinstance(payload, dict) or "error" in payload
            or payload.get("object") != "list" or not isinstance(payload.get("data"), list)):
        raise ValueError("response is not a model list")
    seen = set()
    for model in payload["data"]:
        if not isinstance(model, dict):
            raise ValueError("model entry must be an object")
        for key in ("id", "owned_by", "privacyLevel"):
            if not isinstance(model.get(key), str) or not model[key]:
                raise ValueError(f"model entry has no valid {key}")
        for key in ("context_length", "created_at"):
            if type(model.get(key)) is not int or model[key] < 0:
                raise ValueError(f"model entry has no valid {key}")
        if type(model.get("popular")) is not bool:
            raise ValueError("model entry has no valid popular flag")
        params = model.get("supported_parameters")
        if params is not None and (not isinstance(params, list)
                                   or any(not isinstance(p, str) for p in params)):
            raise ValueError("invalid supported_parameters")
        if model["id"] in seen:
            raise ValueError("duplicate model id")
        seen.add(model["id"])
    return payload["data"]


def eligible_models(models, session):
    return [m for m in models
            if (m["privacyLevel"] == "zdr" or m["id"] in session["allowlist"])
            and "tools" in (m.get("supported_parameters") or [])
            and m["context_length"] >= session["context_floor"]]


def select(models, session):
    eligible = eligible_models(models, session)
    popular = [m for m in eligible if m["popular"]]
    tail = sorted((m for m in eligible if not m["popular"]),
                  key=lambda m: m["created_at"], reverse=True)
    return [{"slug": m["id"], "maker": m["owned_by"]}
            for m in (popular + tail)[:session["depth"]]]


def diagnostics(models, session):
    eligible = eligible_models(models, session)
    flagged = [m for m in eligible if m["popular"]]
    print(f"listed: {len(models)}")
    print(f"privacyLevel: {dict(collections.Counter(m['privacyLevel'] for m in models))}")
    print(f"publisher allowlist: {json.dumps(session['allowlist'])}")
    print(f"context_floor: {session['context_floor']} tokens; depth: {session['depth']}")
    print(f"eligible (badge or allowlist, tool calls, context floor): {len(eligible)}")
    print(f"of those flagged popular: {len(flagged)}")
    for m in flagged:
        print(f"  {m['id']}  context={m['context_length']}  owned_by={m['owned_by']}")
    print("candidate order (slug / maker):")
    for m in select(models, session):
        print(f"  {m['slug']} / {m['maker']}")
    popular = [m for m in models if m["popular"]]
    unbadged = [m for m in popular if m["privacyLevel"] != "zdr"]
    print(f"flagged popular overall: {len(popular)}, of which not badged zdr: {len(unbadged)}")
    print("badge by owner (zdr / all; before tool and context filters):")
    for owner in ("Anthropic", "OpenAI", "Google", "Z.ai", "DeepSeek", "Qwen"):
        own = [m for m in models if m["owned_by"] == owner]
        print(f"  {owner}: {sum(1 for m in own if m['privacyLevel'] == 'zdr')} / {len(own)}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("snapshot", type=Path)
    parser.add_argument("--bundle", type=Path, default=DEFAULT_BUNDLE)
    args = parser.parse_args()
    diagnostics(model_list(json.loads(args.snapshot.read_text())), read_bundle(args.bundle)["session"])


if __name__ == "__main__":
    main()
