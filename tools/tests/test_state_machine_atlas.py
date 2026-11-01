"""Presentation agreement and malformed-input tests; no dispatch guard evaluator."""

from contextlib import redirect_stdout
import copy
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import render_state_machine_atlas as atlas
from atlas_cases import ADVERSARIAL, LABELS, CASES, mutate, rendered_cells


class SourceAgreement(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads((atlas.ROOT / atlas.SOURCE).read_text())
        cls.document = (atlas.ROOT / atlas.ATLAS).read_text()
        cls.index = atlas.declarations(atlas.ROOT / atlas.INDEX)

    def test_every_displayed_step_and_all_context_agree_with_committed_source(self):
        # Decode the actual committed artifact, not the renderer's expected
        # output. Compare each column directly with the source JSON members.
        region = self.document.split(atlas.BEGIN)[1].split(atlas.END)[0]
        cells = rendered_cells(region)
        self.assertEqual(cells.pop(0), {k: self.source[k] for k in ("schema", "module", "namespace", "bound")})
        steps = 0
        for name in atlas.SELECTION:
            with self.subTest(declaration=name):
                trace = next(w for w in self.source["witnesses"] if atlas.NS + name in w["declarations"])
                self.assertEqual(cells.pop(0), {k: v for k, v in trace.items() if k not in ("start", "steps")})
                self.assertEqual(cells.pop(0), trace["start"])
                for step in trace["steps"]:
                    self.assertEqual(cells.pop(0), step["event"])
                    self.assertEqual(cells.pop(0), {k: v for k, v in step.items() if k not in ("event", "knowledge")})
                    self.assertEqual(cells.pop(0), step["knowledge"])
                    steps += 1
        self.assertEqual(steps, 19)
        self.assertEqual(cells, [])

    def test_required_pair_differences_and_progress_are_preserved(self):
        traces = {name: next(w for w in self.source["witnesses"] if atlas.NS + name in w["declarations"])
                  for name in atlas.SELECTION}
        for left, right, guard, before, after in (
                (atlas.SELECTION[0], atlas.SELECTION[1], "resourceKey", "entry", "call"),
                (atlas.SELECTION[3], atlas.SELECTION[4], "commandHold", True, False)):
            a, b = traces[left], traces[right]
            self.assertEqual([s["event"] for s in a["steps"]], [s["event"] for s in b["steps"]])
            self.assertEqual(a["start"], b["start"])
            self.assertEqual(a["assumptions"][guard], before)
            self.assertEqual(b["assumptions"][guard], after)
            self.assertEqual([k for k in a["assumptions"] if a["assumptions"][k] != b["assumptions"][k]], [guard])
            self.assertEqual(a["pair"], {"side": "refused", "with": atlas.NS + right})
            self.assertEqual(b["pair"], {"side": "admitted", "with": atlas.NS + left})
        fresh = traces[atlas.SELECTION[0]]
        self.assertEqual([s["event"]["kind"] for s in fresh["steps"]], ["request", "request"])
        self.assertEqual([s["event"]["call"] for s in fresh["steps"]], [1, 2])
        progress = traces[atlas.SELECTION[-1]]["steps"]
        self.assertEqual([s["event"].get("call") for s in progress], [7, None, 12, 13, 14, 17, None, 20])
        self.assertEqual(progress[2]["event"]["session"], 2)
        self.assertEqual(progress[2]["refusal"], {"reason": "barrier", "calls": [7]})
        self.assertEqual(progress[3]["event"]["operation"], "read")
        self.assertEqual(progress[6]["event"]["source"], "job_record")
        self.assertEqual(progress[6]["settled"], [7])
        self.assertEqual(progress[7]["dispatch"], "dispatched")
        self.assertEqual(progress[-1]["knowledge"]["unresolved"], [
            {"calls": [20], "resource": {"machine_entry": 1}},
            {"calls": [17], "resource": {"machine_entry": 2}},
            {"calls": [14], "resource": {"inference": True}}])

    def test_unrelated_receipt_reuse_is_valid_and_not_selected(self):
        source = copy.deepcopy(self.source)
        receipt = next(w for w in source["witnesses"] if atlas.NS + "lnvps_receipt_refusals" in w["declarations"])
        source["witnesses"].append(receipt)
        self.assertEqual(len(atlas.project(source, self.index)["witnesses"]), 6)

    def test_duplicate_selection_fails(self):
        with self.assertRaisesRegex(atlas.Invalid, "duplicate selection"):
            atlas.project(self.source, self.index, atlas.SELECTION + (atlas.SELECTION[0],))

    def test_schema_continuation_spellings_are_accepted(self):
        for token in ("as_if_done", "as_if_not_done"):
            source = copy.deepcopy(self.source)
            source["bound"]["alphabet"][4]["continuation"] = token
            self.assertEqual(atlas.project(source, self.index)["bound"]["alphabet"][4]["continuation"], token)

    def test_safe_encoding_preserves_adversarial_data(self):
        for value in (*LABELS, {ADVERSARIAL: list(LABELS)}):
            with self.subTest(value=value):
                cell = atlas.cell(value)
                self.assertEqual(rendered_cells("| Value |\n|---|\n| " + cell + " |\n"), [value])
                for forbidden in ("<script>", "<!--", "\n"):
                    self.assertNotIn(forbidden, cell)

    def test_gfm_displays_accepted_labels_literally(self):
        for label in LABELS:
            with self.subTest(label=label):
                source = copy.deepcopy(self.source)
                witness = next(w for w in source["witnesses"] if atlas.NS + atlas.SELECTION[0] in w["declarations"])
                witness["steps"][0]["event"]["provenance"] = label
                event = atlas.project(source, self.index)["witnesses"][0]["steps"][0]["event"]
                table = "| Event |\n|---|\n| " + atlas.cell(event) + " |\n"
                self.assertEqual(rendered_cells(table), [event])
        value = {ADVERSARIAL: list(LABELS)}
        self.assertEqual(rendered_cells("| Value |\n|---|\n| " + atlas.cell(value) + " |\n"), [value])

    def test_gfm_oracle_rejects_nested_markup_in_raw_code(self):
        for value, tag in (("~~atlas-label~~", "del"), ("https://example.com/atlas-label", "a")):
            with self.subTest(value=value):
                table = '| Value |\n|---|\n| <code>"' + value + '"</code> |\n'
                with self.assertRaisesRegex(AssertionError, f"unexpected <{tag}>"):
                    rendered_cells(table)


class GateControls(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="tau-atlas-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for path in (atlas.SOURCE, atlas.ATLAS, atlas.INDEX):
            (self.root / path).parent.mkdir(parents=True, exist_ok=True)
            (self.root / path).write_bytes((atlas.ROOT / path).read_bytes())

    def run_gate(self, *options):
        out = io.StringIO()
        with redirect_stdout(out):
            code = atlas.main(["--root", str(self.root), *options])
        return code, out.getvalue()

    def test_each_mutation_has_exactly_its_own_finding_and_names_target(self):
        originals = {p: (self.root / p).read_bytes() for p in (atlas.SOURCE, atlas.ATLAS, atlas.INDEX)}
        for case, label in CASES.items():
            with self.subTest(case=case):
                for path, data in originals.items():
                    (self.root / path).write_bytes(data)
                mutate(case, self.root)
                code, output = self.run_gate("--check")
                self.assertEqual(code, 1, output)
                self.assertEqual(len(output.splitlines()), 1, output)
                self.assertTrue(output.startswith(label + ":"), output)
                self.assertIn("atlas" if case in ("stale", "evidence", "step_evidence", "applicability", "markers", "index")
                              else ("schema" if case == "duplicate_member" else
                                    "absent_atlas_declaration" if case == "unresolved" else
                                    "dispatch-witnesses" if case in ("schema", "module", "namespace", "conformance_id") else
                                    "state-machine-atlas" if case == "outcome" else
                                    "bound.alphabet" if case == "continuation_token" else "same_action_new_call_id_refused"), output)

    def test_write_does_not_repair_invalid_source_or_malformed_markers(self):
        originals = {p: (self.root / p).read_bytes() for p in (atlas.SOURCE, atlas.ATLAS, atlas.INDEX)}
        for case in ("schema", "missing", "ambiguous", "unresolved", "nested", "missing_data", "pair", "partner", "markers", "index"):
            with self.subTest(case=case):
                for path, data in originals.items():
                    (self.root / path).write_bytes(data)
                mutate(case, self.root)
                before = (self.root / atlas.ATLAS).read_bytes()
                self.assertEqual(self.run_gate("--write")[0], 1)
                self.assertEqual((self.root / atlas.ATLAS).read_bytes(), before)

    def test_two_regenerations_identical_and_preserve_handwritten_text(self):
        path = self.root / atlas.ATLAS
        original = path.read_text()
        path.write_text("Private fixture prefix\n" + original + "\nPrivate fixture suffix\n")
        self.assertEqual(self.run_gate("--write")[0], 0)
        first = path.read_bytes()
        self.assertEqual(self.run_gate("--write")[0], 0)
        self.assertEqual(first, path.read_bytes())
        self.assertEqual(path.read_text(), "Private fixture prefix\n" + original + "\nPrivate fixture suffix\n")
        self.assertEqual(self.run_gate("--check")[0], 0)

    def test_positive_adversarial_source_is_accepted_and_preserved(self):
        mutate("safe_label", self.root)
        self.assertEqual(self.run_gate("--write")[0], 0)
        self.assertEqual(self.run_gate("--check")[0], 0)
        text = (self.root / atlas.ATLAS).read_text()
        self.assertEqual(text.count(atlas.END), 1)
        region = text.split(atlas.BEGIN)[1].split(atlas.END)[0]
        values = rendered_cells(region)
        for label in LABELS:
            self.assertTrue(any(type(v) is dict and v.get("provenance") == label for v in values), repr(label))


if __name__ == "__main__":
    unittest.main()
