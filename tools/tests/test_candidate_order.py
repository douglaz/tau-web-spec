"""Offline checks for selection, network failures, and the actual proposal command path."""
import copy
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import urllib.error

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("proposer", ROOT / "tools/propose_candidates.py")
job = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(job)
select = job.selection
FINDING = ROOT / "docs/findings/2026-09-22-provider-routing"
BUNDLE = ROOT / "bundle/inference.toml"
HISTORICAL = [
    {"slug": "glm-5.3", "maker": "Z.ai", "provider": "z-ai"},
    {"slug": "xiaomi/mimo-v2.6-flash", "maker": "Xiaomi", "provider": "xiaomi"},
    {"slug": "xiaomi/mimo-v2.6-pro", "maker": "Xiaomi", "provider": "xiaomi"},
    {"slug": "deepseek/deepseek-v4.1-flash", "maker": "DeepSeek", "provider": "deepseek"},
    {"slug": "tencent/hy4-preview", "maker": "Tencent", "provider": "tencent"},
]


def model(slug, *, popular=False, created=1, context=500000, tools=True, badge="zdr"):
    return {"id": slug, "owned_by": "Maker unrelated to slug", "popular": popular,
            "created_at": created, "context_length": context, "privacyLevel": badge,
            "supported_parameters": ["tools"] if tools else []}


def payload(*models):
    return {"object": "list", "data": list(models)}


def bundle_source(candidates=HISTORICAL, allowlist=None):
    original = select.read_bundle(BUNDLE)
    return job.bundle_patch(BUNDLE.read_text(), original, candidates, allowlist or [])


def session_inputs(**overrides):
    return {"context_floor": 500000, "depth": 5, "allowlist": [],
            "model": copy.deepcopy(HISTORICAL), "retention": "strictest", **overrides}


def draft(path):
    return select.tomllib.loads(path.read_text())


def discovery(*providers):
    return (404, {"error": {"code": 404, "metadata": {
        "failed_routing_step": "Filter by Allowed Providers",
        "requested_providers": [job.IMPOSSIBLE_PROVIDER],
        "available_providers": list(providers)}}})


class Selection(unittest.TestCase):
    def test_historical_record(self):
        # Freeze the inputs for this dated record even when later proposals land.
        session = session_inputs()
        models = select.model_list(json.loads((FINDING / "models-2026-09-23.json").read_text()))
        self.assertEqual(select.select(models, session), HISTORICAL)
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            select.diagnostics(models, session)
        self.assertEqual(output.getvalue(), (FINDING / "eligible-set.2026-09-23.txt").read_text())

    def test_filters_order_depth_and_makers(self):
        models = [model("tail-old", created=3), model("popular-first", created=2, popular=True),
                  model("tail-new", created=10), model("popular-second", created=20, popular=True),
                  model("allow", badge="anon", created=8), model("unbadged", badge="anon"),
                  model("short", context=499999), model("no-tools", tools=False),
                  model("allow-short", badge="anon", context=499999),
                  model("allow-no-tools", badge="anon", tools=False)]
        session = session_inputs(allowlist=[{"slug": slug, "provider": "private-pin"}
                    for slug in ("allow", "allow-short", "allow-no-tools")], depth=4)
        selected = select.draft_candidates(select.model_list(payload(*models)), session)
        self.assertEqual([m["slug"] for m in selected],
                         ["popular-first", "popular-second", "tail-new", "allow"])
        self.assertEqual({m["maker"] for m in selected}, {"Maker unrelated to slug"})
        self.assertEqual([m["id"] for m in select.eligible_models(models, session)],
                         ["tail-old", "popular-first", "tail-new", "popular-second", "allow"])

    def test_invalid_lists(self):
        bad_entry = model("bad")
        bad_entry["created_at"] = "yesterday"
        for data in ({"error": "no"}, {"object": "list", "data": [], "error": "no"},
                     [], {"data": {}}, payload(None), payload(bad_entry),
                     payload(model("duplicate"), model("duplicate"))):
            with self.subTest(data=data), self.assertRaises(ValueError):
                select.model_list(data)

    def test_empty_bundle_fields_refused(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "inference.toml"
            for old, new in (("context_floor = 500000", 'context_floor = ""'),
                             ("depth = 5", "depth = 0")):
                path.write_text(BUNDLE.read_text().replace(old, new))
                with self.assertRaises(ValueError):
                    select.read_bundle(path)
            path.write_text(bundle_source([]))
            with self.assertRaises(ValueError):
                select.read_bundle(path)

    def test_entry_roundtrips_and_strict_selection_boundary(self):
        session = session_inputs(allowlist=[{"slug": 'private/"\\value]💡', "provider": "own-pin"}])
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "inference.toml"
            path.write_text(bundle_source(session["model"], session["allowlist"]))
            self.assertEqual(select.read_bundle(path)["session"], session)
            # Replacing an existing inline table must not stop at a quoted bracket.
            source = path.read_text().replace("# TRU-A1a", "# TRU-A1a [comment]")
            changed = job.bundle_patch(source, draft(path), session["model"], [])
            self.assertIn("# TRU-A1a [comment]", changed)
            self.assertEqual(select.tomllib.loads(changed)["session"]["allowlist"], [])
            for group in ("model", "allowlist"):
                for value in (None, "", "   ", 1):
                    invalid = copy.deepcopy(session)
                    if value is None:
                        del invalid[group][0]["provider"]
                    else:
                        invalid[group][0]["provider"] = value
                    with self.subTest(group=group, value=value):
                        path.write_text(bundle_source(invalid["model"], invalid["allowlist"]))
                        # Neither file reading nor a direct selector can certify it.
                        with self.assertRaises(ValueError):
                            select.read_bundle(path)
                        with self.assertRaises(ValueError):
                            select.select([model("glm-5.3")], invalid)
                        with self.assertRaises(ValueError):
                            select.draft_candidates([model("glm-5.3")], invalid)

    def test_reordering_preserves_pins_and_entrant_inherits_allowlist_pin(self):
        session = session_inputs(allowlist=[{"slug": "admitted", "provider": "chosen-by-publisher"}])
        models = [model("admitted", popular=True, badge="anon"),
                  model("xiaomi/mimo-v2.6-flash", created=10), model("glm-5.3")]
        selected = select.select(models, session)
        self.assertEqual([(c["slug"], c["provider"]) for c in selected],
                         [("admitted", "chosen-by-publisher"),
                          ("xiaomi/mimo-v2.6-flash", "xiaomi"), ("glm-5.3", "z-ai")])

    def test_new_entrant_is_draft_only_and_never_filtered_from_order(self):
        models = [model("new", popular=True), model("glm-5.3")]
        session = session_inputs()
        candidates = select.draft_candidates(models, session)
        self.assertEqual([c["slug"] for c in candidates], ["new", "glm-5.3"])
        self.assertEqual(candidates[0]["provider"], "")
        self.assertEqual(candidates[1]["provider"], "z-ai")
        with self.assertRaises(ValueError):
            select.select(models, session)
        parsed = select.tomllib.loads(bundle_source(candidates))
        self.assertEqual(parsed["session"]["model"], candidates)
        with self.assertRaises(ValueError):
            select.select(models, parsed["session"])


class Update(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / "inference.toml"
        self.path.write_text(bundle_source())
        self.env = patch.dict(os.environ, {}, clear=True)
        self.env.start()
        self.addCleanup(self.env.stop)

    def test_empty_allowlist_no_secret_no_probe_and_noop(self):
        data = json.loads((FINDING / "models-2026-09-23.json").read_text())
        before = self.path.read_bytes()
        with patch.object(job, "request_json", return_value=(200, data)) as request:
            self.assertFalse(job.update_bundle(self.path))
        request.assert_called_once_with("https://api.ppq.ai/v1/models")
        self.assertEqual(self.path.read_bytes(), before)

    def test_changed_order_preserves_unrelated_values_and_treats_slugs_as_data(self):
        slug = 'strange/$(touch unwanted);`command`"\\\nvalue'
        data = payload(model(slug))
        before = select.read_bundle(self.path)
        with patch.dict(os.environ, {job.SECRET: "fixture-only-key"}), patch.object(
                job, "request_json", side_effect=[(200, data), discovery("provider-data")]):
            self.assertEqual(job.update_bundle(self.path), {slug: ["provider-data"]})
        after = draft(self.path)
        self.assertEqual(after["session"].pop("model"),
                         [{"slug": slug, "maker": "Maker unrelated to slug", "provider": ""}])
        before["session"].pop("model")
        self.assertEqual(before, after)
        self.assertIn('provider = ""', self.path.read_text())
        self.assertIn('retention = "strictest"', self.path.read_text())

    def test_failed_fetch_or_invalid_list_never_changes_bundle(self):
        before = self.path.read_bytes()
        for response in ((503, {}), (200, {"error": "not a list"}),
                         (200, payload({"id": "incomplete"})), (200, payload())):
            with self.subTest(response=response), patch.object(job, "request_json", return_value=response):
                with self.assertRaises(ValueError):
                    job.update_bundle(self.path)
            self.assertEqual(self.path.read_bytes(), before)
        with patch.object(job, "request_json", side_effect=urllib.error.URLError("offline")):
            with self.assertRaises(urllib.error.URLError):
                job.update_bundle(self.path)
        self.assertEqual(self.path.read_bytes(), before)

    def test_missing_secret_fails_before_any_network_call(self):
        self.path.write_text(bundle_source(allowlist=[{"slug": "private-choice", "provider": "private-pin"}]))
        before = self.path.read_bytes()
        with patch.object(job, "request_json") as request:
            with self.assertRaisesRegex(ValueError, job.SECRET):
                job.update_bundle(self.path)
            request.assert_not_called()
        self.assertEqual(self.path.read_bytes(), before)

    def allowlisted(self):
        chosen = {"slug": "private-choice", "maker": "Maker unrelated to slug", "provider": "private-pin"}
        self.path.write_text(bundle_source([chosen], [{"slug": chosen["slug"], "provider": chosen["provider"]}]))
        os.environ[job.SECRET] = "fixture-only-key"
        return payload(model("private-choice", badge="anon", popular=True), model("replacement"))

    def test_probe_success_sends_case_g_routing_shape(self):
        data = self.allowlisted()
        response = json.loads((FINDING / "run-2026-09-23/case-G.json").read_text())
        with patch.object(job, "request_json", side_effect=[(200, data), (200, response), discovery("replacement-pin")]) as request:
            self.assertTrue(job.update_bundle(self.path))
        url, body, credential = request.call_args_list[1].args
        self.assertEqual(url, "https://api.ppq.ai/v1/chat/completions")
        expected = json.loads((FINDING / "run-2026-09-23/case-G.request.json").read_text())
        expected["model"] = "private-choice"
        expected["provider"]["only"] = ["private-pin"]
        self.assertEqual(body, expected)
        self.assertEqual(credential, "fixture-only-key")
        self.assertEqual(draft(self.path)["session"]["allowlist"],
                         [{"slug": "private-choice", "provider": "private-pin"}])

    def test_routing_refusal_proposes_removal(self):
        data = self.allowlisted()
        refusal = json.loads((FINDING / "run-2026-09-23/case-C.json").read_text())
        with patch.object(job, "request_json", side_effect=[(200, data), (404, refusal), discovery("replacement-pin")]):
            self.assertTrue(job.update_bundle(self.path))
        session = draft(self.path)["session"]
        self.assertEqual(session["allowlist"], [])
        self.assertEqual([m["slug"] for m in session["model"]], ["replacement"])
        self.assertEqual(session["model"][0]["provider"], "")

    def test_inconclusive_probe_aborts_without_removal(self):
        for response in ((401, {"error": {"code": 401}}), (429, {}), (503, {}),
                         (404, {"error": {"code": 404}}), (200, {"error": {"code": 404}}),
                         (200, {"choices": []}), (200, {"choices": [None]})):
            data = self.allowlisted()
            before = self.path.read_bytes()
            with self.subTest(response=response), patch.object(
                    job, "request_json", side_effect=[(200, data), response]):
                with self.assertRaises(ValueError):
                    job.update_bundle(self.path)
            self.assertEqual(self.path.read_bytes(), before)

    def test_refusal_outside_candidate_order_is_no_proposal(self):
        data = self.allowlisted()
        self.path.write_text(bundle_source(
            [{"slug": "replacement", "maker": "Maker unrelated to slug", "provider": "kept-pin"}],
            [{"slug": "private-choice", "provider": "private-pin"}]))
        before = self.path.read_bytes()
        refusal = json.loads((FINDING / "run-2026-09-23/case-C.json").read_text())
        with patch.object(job, "request_json", side_effect=[(200, data), (404, refusal)]):
            self.assertFalse(job.update_bundle(self.path))
        self.assertEqual(self.path.read_bytes(), before)

    def test_discovery_needs_secret_even_with_empty_allowlist(self):
        before = self.path.read_bytes()
        with patch.object(job, "request_json", return_value=(200, payload(model("new")))) as request:
            with self.assertRaisesRegex(ValueError, job.SECRET):
                job.update_bundle(self.path)
        request.assert_called_once_with("https://api.ppq.ai/v1/models")
        self.assertEqual(self.path.read_bytes(), before)

    def test_discovery_request_and_inconclusive_responses(self):
        os.environ[job.SECRET] = "fixture-only-key"
        data = payload(model("new"))
        before = self.path.read_bytes()
        for response in ((401, {}), (429, {}), (503, {}), (200, {"choices": [{}]}),
                         (404, {"error": {"code": 404}}), discovery(), discovery(""),
                         discovery(None), discovery(job.IMPOSSIBLE_PROVIDER)):
            with self.subTest(response=response), patch.object(
                    job, "request_json", side_effect=[(200, data), response]):
                with self.assertRaisesRegex(ValueError, "discovery"):
                    job.update_bundle(self.path)
            self.assertEqual(self.path.read_bytes(), before)
        with patch.object(job, "request_json", side_effect=[
                (200, data), urllib.error.URLError("offline")]):
            with self.assertRaises(urllib.error.URLError):
                job.update_bundle(self.path)
        self.assertEqual(self.path.read_bytes(), before)
        with patch.object(job, "request_json", side_effect=[
                (200, data), discovery("human-choice", "other")]) as request:
            self.assertEqual(job.update_bundle(self.path), {"new": ["human-choice", "other"]})
        request.assert_any_call("https://api.ppq.ai/v1/models")
        url, body, credential = request.call_args.args
        self.assertEqual(url, "https://api.ppq.ai/v1/chat/completions")
        self.assertEqual(body["model"], "new")
        self.assertEqual(body["provider"], {"only": [job.IMPOSSIBLE_PROVIDER], "zdr": True})
        self.assertEqual(credential, "fixture-only-key")
        self.assertEqual(draft(self.path)["session"]["model"][0]["provider"], "")

    def test_each_allowlist_probe_uses_its_own_pin_even_outside_order(self):
        entries = [{"slug": "admitted", "provider": "first-pin"},
                   {"slug": "outside", "provider": "second-pin"}]
        self.path.write_text(bundle_source(allowlist=entries))
        data = payload(model("admitted", badge="anon"))
        success = (200, {"choices": [{"message": {"content": "ok"}}]})
        with patch.dict(os.environ, {job.SECRET: "fixture-only-key"}), patch.object(
                job, "request_json", side_effect=[(200, data), success, success]) as request:
            self.assertEqual(job.update_bundle(self.path), {})
        for call, entry in zip(request.call_args_list[1:], entries):
            self.assertEqual(call.args[1]["model"], entry["slug"])
            self.assertEqual(call.args[1]["provider"], {"only": [entry["provider"]], "zdr": True})
        self.assertEqual(draft(self.path)["session"]["model"][0]["provider"], "first-pin")
        self.assertEqual(select.read_bundle(self.path)["session"]["allowlist"], entries)


class Transport(unittest.TestCase):
    def test_public_fetch_and_authenticated_probe_encoding(self):
        response = io.BytesIO(b'{"object":"list","data":[]}')
        response.code = 200
        with patch.object(job.urllib.request, "build_opener") as opener:
            opener.return_value.open.return_value = response
            self.assertEqual(job.request_json("https://example.invalid/v1/models"),
                             (200, {"object": "list", "data": []}))
            request = opener.return_value.open.call_args.args[0]
            self.assertIsNone(request.data)
            self.assertNotIn("Authorization", request.headers)
            self.assertEqual(opener.return_value.open.call_args.kwargs["timeout"], 60)
        response = io.BytesIO(b'{"choices":[{"message":{"content":"ok"}}]}')
        response.code = 200
        body = {"model": "example", "provider": {"only": ["z-ai"], "zdr": True}}
        with patch.object(job.urllib.request, "build_opener") as opener:
            opener.return_value.open.return_value = response
            job.request_json("https://example.invalid/v1/chat/completions", body, "fixture-only-key")
            request = opener.return_value.open.call_args.args[0]
            self.assertEqual(request.get_method(), "POST")
            self.assertEqual(json.loads(request.data), body)
            self.assertEqual(request.headers["Authorization"], "Bearer fixture-only-key")
        self.assertIsNone(job.NoRedirect().redirect_request(None, None, 302, "", {}, "https://other.invalid"))

    def test_http_error_and_non_json(self):
        error = urllib.error.HTTPError("https://example.invalid", 503, "", {}, io.BytesIO(b'{}'))
        with patch.object(job.urllib.request, "build_opener") as opener:
            opener.return_value.open.side_effect = error
            self.assertEqual(job.request_json("https://example.invalid"), (503, {}))
        response = io.BytesIO(b"not JSON")
        response.code = 200
        with patch.object(job.urllib.request, "build_opener") as opener:
            opener.return_value.open.return_value = response
            with self.assertRaisesRegex(ValueError, "invalid JSON"):
                job.request_json("https://example.invalid")


class Proposal(unittest.TestCase):
    def test_real_git_proposal_create_update_and_noop(self):
        real_command = job.command
        gh_calls = []
        pr_exists = False
        bodies = []

        def command(*args):
            nonlocal pr_exists
            if args[0] != "gh":
                return real_command(*args)
            gh_calls.append(args)
            if args[1:3] == ("pr", "list"):
                return '[{"number": 1}]' if pr_exists else '[]'
            self.assertEqual(args[1:3], ("pr", "edit") if pr_exists else ("pr", "create"))
            if not pr_exists:
                self.assertEqual(args[args.index("--head") + 1], job.BRANCH)
                self.assertEqual(args[args.index("--base") + 1], "main")
            else:
                self.assertEqual(args[3], "1")
            body = Path(args[args.index("--body-file") + 1]).read_text()
            self.assertIn("Publisher review", body)
            bodies.append(json.loads(body.split("```json\n")[1].split("\n```")[0]))
            pr_exists = True
            return "https://example.invalid/pull/1"

        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            subprocess.run(["git", "init", "--bare", str(root / "remote.git")], check=True, capture_output=True)
            work = root / "work"
            work.mkdir()
            with contextlib.chdir(work):
                real_command("git", "init", "-b", "main")
                real_command("git", "config", "user.name", "Fixture")
                real_command("git", "config", "user.email", "fixture@example.invalid")
                Path("bundle").mkdir()
                Path("bundle/inference.toml").write_text(bundle_source())
                real_command("git", "add", ".")
                real_command("git", "commit", "-m", "fixture")
                real_command("git", "remote", "add", "origin", str(root / "remote.git"))
                real_command("git", "push", "-u", "origin", "main")
                original = real_command("git", "rev-parse", "HEAD")
                historical = json.loads((FINDING / "models-2026-09-23.json").read_text())
                with patch.object(sys, "argv", ["propose_candidates.py", "--default-branch", "main"]), \
                        patch.object(job, "command", side_effect=command), \
                        patch.dict(os.environ, {job.SECRET: "fixture-only-key"}):
                    # No proposal on unchanged order, invalid response, or network failure.
                    with patch.object(job, "request_json", return_value=(200, historical)):
                        job.main()
                    for response in ((503, {}), (200, {"error": "bad"})):
                        with patch.object(job, "request_json", return_value=response):
                            with self.assertRaises(ValueError):
                                job.main()
                    self.assertEqual(gh_calls, [])
                    self.assertEqual(real_command("git", "ls-remote", "origin", f"refs/heads/{job.BRANCH}"), "")
                    for slug in ('next/$(touch unwanted);`command`"\\\nvalue', "later"):
                        real_command("git", "checkout", "main")
                        with patch.object(job, "request_json", side_effect=[
                                (200, payload(model(slug))), discovery(slug + "-provider", "other")]):
                            job.main()
                        self.assertEqual(real_command("git", "branch", "--show-current"), job.BRANCH)
                        proposed = draft(Path("bundle/inference.toml"))
                        self.assertEqual(proposed["session"]["model"][0]["slug"], slug)
                        self.assertEqual(proposed["session"]["model"][0]["provider"], "")
                        self.assertEqual(bodies[-1], {slug: [slug + "-provider", "other"]})
                        with self.assertRaises(ValueError):
                            select.read_bundle(Path("bundle/inference.toml"))
                        self.assertEqual(real_command("git", "diff", "--name-only", "main", "HEAD"),
                                         "bundle/inference.toml")
                        self.assertEqual(real_command("git", "ls-remote", "origin", "refs/heads/main").split()[0], original)
                self.assertEqual(sum(c[1:3] == ("pr", "create") for c in gh_calls), 1)
                self.assertEqual(sum(c[1:3] == ("pr", "list") for c in gh_calls), 2)
                self.assertEqual(sum(c[1:3] == ("pr", "edit") for c in gh_calls), 1)
                self.assertEqual(real_command("git", "status", "--porcelain"), "")

    def test_default_branch_guard(self):
        with patch.object(job, "command") as command:
            with self.assertRaises(ValueError):
                job.publish(job.BRANCH, {})
            command.assert_not_called()


if __name__ == "__main__":
    unittest.main()
