#!/usr/bin/env python3
"""Reproduce ARC-31b's selection and snapshot diagnostics using bundle inputs.

python3 eligible-set.py models-2026-09-23.json [--bundle path/to/inference.toml]
The proposing job shares eligibility and ordering, but constructs drafts separately. Makers come from owned_by.
"""
import argparse
import collections
import json
from pathlib import Path
import tomllib

DEFAULT_BUNDLE = Path(__file__).resolve().parents[3] / "bundle/inference.toml"


def read_bundle(path):
    bundle = tomllib.loads(Path(path).read_text())
    validate_session(bundle["session"])
    return bundle


def validate_entries(entries, fields, label, *, nonempty=False):
    if not isinstance(entries, list) or (nonempty and not entries):
        raise ValueError(f"{label} must be a {'nonempty ' if nonempty else ''}list")
    for entry in entries:
        if not isinstance(entry, dict) or set(entry) != fields:
            raise ValueError(f"{label} entries must carry {', '.join(sorted(fields))}")
        if any(not isinstance(v, str) or not v.strip() for v in entry.values()):
            raise ValueError(f"{label} fields must be nonempty strings")


def validate_session(session):
    for key in ("context_floor", "depth"):
        if type(session.get(key)) is not int or session[key] <= 0:
            raise ValueError(f"session.{key} must be a positive integer")
    validate_entries(session.get("allowlist"), {"slug", "provider"}, "allowlist")
    validate_entries(session.get("model"), {"slug", "maker", "provider"},
                     "candidate", nonempty=True)
    if "provider" in session:
        raise ValueError("provider belongs on each entry, not session")
    if session.get("retention") != "strictest":
        raise ValueError("unsupported retention request")


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
    allowlist = {entry["slug"] for entry in session["allowlist"]}
    return [m for m in models
            if (m["privacyLevel"] == "zdr" or m["id"] in allowlist)
            and "tools" in (m.get("supported_parameters") or [])
            and m["context_length"] >= session["context_floor"]]


def ordered_models(models, session):
    eligible = eligible_models(models, session)
    popular = [m for m in eligible if m["popular"]]
    tail = sorted((m for m in eligible if not m["popular"]),
                  key=lambda m: m["created_at"], reverse=True)
    return (popular + tail)[:session["depth"]]


def draft_candidates(models, session):
    """Construct a proposal from valid inputs; unknown pins stay explicitly empty."""
    validate_session(session)
    pins = {entry["slug"]: entry["provider"] for entry in session["allowlist"]}
    # Preserve a current candidate's pin; allowlist pins apply only to entrants.
    pins.update({entry["slug"]: entry["provider"] for entry in session["model"]})
    return [{"slug": m["id"], "maker": m["owned_by"], "provider": pins.get(m["id"], "")}
            for m in ordered_models(models, session)]


def select(models, session):
    """Strict offline selection, including direct callers that did not read a file."""
    candidates = draft_candidates(models, session)
    validate_entries(candidates, {"slug", "maker", "provider"}, "candidate", nonempty=True)
    return candidates


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
    print("candidate order (slug / maker / provider):")
    for m in select(models, session):
        print(f"  {m['slug']} / {m['maker']} / {m['provider']}")
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
