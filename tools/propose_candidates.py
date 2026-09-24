#!/usr/bin/env python3
"""Daily candidate proposal mechanism; contract owners: ARC-31b and TRU-A1a."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "eligible_set", ROOT / "docs/findings/2026-09-22-provider-routing/eligible-set.py")
selection = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(selection)
BRANCH = "proposals/candidate-order"
SECRET = "PUBLISHER_AGGREGATOR_KEY"


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def request_json(url, body=None, credential=None):
    headers = {"Accept": "application/json"}
    if credential:
        headers["Authorization"] = f"Bearer {credential}"
    if body is not None:
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(
        url, data=None if body is None else json.dumps(body).encode(), headers=headers)
    try:
        response = urllib.request.build_opener(NoRedirect).open(request, timeout=60)
    except urllib.error.HTTPError as error:
        response = error
    with response:
        status = response.code
        try:
            payload = json.load(response)
        except (ValueError, UnicodeError) as error:
            raise ValueError(f"HTTP {status}: invalid JSON response") from error
    return status, payload


def probe(base_url, slug, session, credential):
    status, payload = request_json(base_url + "/v1/chat/completions", {
        "model": slug,
        "messages": [{"role": "user", "content": "Reply with exactly: ok"}],
        "max_tokens": 5,
        "provider": {"only": [session["provider"]], "zdr": True},
    }, credential)
    # The recorded refusal shape is case C/E beside the case G request fixture.
    error = payload.get("error") if isinstance(payload, dict) else None
    if status == 404 and isinstance(error, dict) and error.get("code") == 404:
        metadata = error.get("metadata")
        if isinstance(metadata, dict) and isinstance(metadata.get("failed_routing_step"), str):
            if metadata["failed_routing_step"]:
                return False
    if (status != 200 or not isinstance(payload, dict) or "error" in payload
            or not isinstance(payload.get("choices"), list) or not payload["choices"]
            or not all(isinstance(c, dict) and isinstance(c.get("message"), dict)
                       for c in payload["choices"])):
        raise ValueError(f"probe did not establish routing (HTTP {status}); no proposal")
    return True


def bundle_patch(source, original, candidates, allowlist):
    # Replace only these session assignments; preserve every other byte. Parse the
    # result and compare every other value before permitting a proposal.
    start = re.search(r"(?m)^\[session\]\s*$", source)
    if start is None:
        raise ValueError("missing session table")
    following = re.search(r"(?m)^\[", source[start.end():])
    end = start.end() + following.start() if following else len(source)
    section = source[start.end():end]
    models = "model = [\n" + "".join(
        "  { slug = " + json.dumps(c["slug"]) + ", maker = " + json.dumps(c["maker"]) + " },\n"
        for c in candidates) + "]"
    section, count = re.subn(r"(?ms)^model = \[\n.*?^\]", lambda _: models, section)
    if count != 1:
        raise ValueError("expected one multiline session.model assignment")
    section, count = re.subn(r"(?m)^allowlist = \[[^\n]*?\]",
                             lambda _: "allowlist = " + json.dumps(allowlist), section)
    if count != 1:
        raise ValueError("expected one single-line session.allowlist assignment")
    patched = source[:start.end()] + section + source[end:]
    expected = {**original, "session": {**original["session"],
                                       "model": candidates, "allowlist": allowlist}}
    if selection.tomllib.loads(patched) != expected:
        raise ValueError("bundle patch changed unrelated values")
    return patched


def update_bundle(path):
    original = selection.read_bundle(path)
    session = original["session"]
    credential = os.environ.get(SECRET)
    if session["allowlist"] and not credential:
        raise ValueError(f"non-empty allowlist requires repository secret {SECRET}")
    base_url = original["aggregator"]["base_url"].rstrip("/")
    if not base_url.startswith("https://"):
        raise ValueError("aggregator URL must use HTTPS")
    status, payload = request_json(base_url + "/v1/models")
    if status != 200:
        raise ValueError(f"model-list fetch failed (HTTP {status})")
    models = selection.model_list(payload)
    allowlist = [slug for slug in session["allowlist"] if probe(base_url, slug, session, credential)]
    candidates = selection.select(models, {**session, "allowlist": allowlist})
    if not candidates:
        raise ValueError("selection is empty; no proposal")
    if candidates == session["model"]:
        print("Candidate order unchanged; no proposal.")
        return False
    patched = bundle_patch(path.read_text(), original, candidates, allowlist)
    path.write_text(patched)
    print("Candidate order changed; prepared bundle proposal.")
    return True


def command(*args):
    return subprocess.run(args, check=True, text=True, stdout=subprocess.PIPE).stdout.strip()


def publish(default_branch):
    if not default_branch or default_branch == BRANCH:
        raise ValueError("proposal branch must differ from the default branch")
    ref = f"refs/heads/{BRANCH}"
    remote = command("git", "ls-remote", "origin", ref)
    old = remote.split()[0] if remote else ""
    command("git", "checkout", "-B", BRANCH)
    command("git", "add", "--", "bundle/inference.toml")
    command("git", "-c", "user.name=Candidate proposals", "-c",
            "user.email=candidate-proposals@users.noreply.github.com", "commit",
            "-m", "chore(bundle): refresh candidate order", "--", "bundle/inference.toml")
    command("git", "push", f"--force-with-lease={ref}:{old}", "origin", f"HEAD:{ref}")
    existing = json.loads(command("gh", "pr", "list", "--state", "open", "--head", BRANCH,
                                  "--base", default_branch, "--json", "number"))
    # Updating the same head branch updates its open PR. No merge command exists here.
    if not existing:
        with tempfile.NamedTemporaryFile(mode="w+", suffix=".md") as body:
            body.write("Recompute the candidate order from the public model list using the "
                       "bundle's selection inputs. Apply any allowlist routing refusals to "
                       "the proposed bundle. Provider, retention and aggregator values are preserved.\n\n"
                       "Contract owners: ARC-31b and TRU-A1a. Publisher review and merge required.\n")
            body.flush()
            print(command("gh", "pr", "create", "--base", default_branch, "--head", BRANCH,
                          "--title", "chore(bundle): refresh candidate order", "--body-file", body.name))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--default-branch", required=True)
    args = parser.parse_args()
    if args.default_branch == BRANCH:
        parser.error("proposal branch cannot be the default branch")
    # Scheduled runs check out the default branch. Refuse a dirty checkout or a
    # different ref rather than include another change in a proposal.
    if command("git", "status", "--porcelain"):
        raise ValueError("proposal requires a clean checkout")
    if command("git", "rev-parse", "HEAD") != command(
            "git", "rev-parse", f"refs/remotes/origin/{args.default_branch}"):
        raise ValueError("proposal must start at the checked-out default branch")
    if update_bundle(Path("bundle/inference.toml")):
        publish(args.default_branch)


if __name__ == "__main__":
    main()
