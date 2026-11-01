"""Presentation agreement and malformed-input tests; no dispatch guard evaluator."""

from contextlib import redirect_stdout
import copy
import io
import json
from pathlib import Path
import re
import sys
from unittest.mock import patch
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import render_state_machine_atlas as atlas
from check_ids import DEF_RE, ID
from atlas_cases import ADVERSARIAL, LABELS, CASES, TARGETS, mutate, rendered_cells


class OwnerNavigation(unittest.TestCase):
    def test_matrix_cells_point_directly_to_owners_without_local_decisions(self):
        document = (atlas.ROOT / atlas.ATLAS).read_text()
        matrix = document.split("## Combined matrix\n", 1)[1].split("### Authority\n", 1)[0]
        rows = [line for line in matrix.splitlines() if line.startswith("| ")]
        self.assertGreater(len(rows), 1, "missing action-to-owner matrix")
        columns = len(rows[0].strip("|").split("|"))
        link = re.compile(r"\[(" + ID + r"|tw-[a-z0-9.]+)\]\((\.\./[^)#]+)(?:#[^)]*)?\)")
        for row in rows[1:]:
            action, *cells = [cell.strip() for cell in row.strip("|").split("|")]
            self.assertEqual(len(cells), columns - 1, "missing restriction cells")
            for cell in cells:
                with self.subTest(action=action, cell=cell):
                    matches = list(link.finditer(cell))
                    self.assertTrue(matches, "matrix cells must point directly to owners")
                    self.assertEqual(link.sub("", cell).replace(", ", ""), "",
                                     "matrix cells must not maintain local dispatch decisions")
                    for match in matches:
                        owner, target = match.groups()
                        text = (atlas.ROOT / atlas.ATLAS.parent / target).read_text()
                        if owner.startswith("tw-"):
                            self.assertIn(owner, {json.loads(line)["id"] for line in text.splitlines()})
                        else:
                            self.assertIn(owner, {m.group(1) or m.group(2) for m in DEF_RE.finditer(text)},
                                          "matrix links must reach the rule's defining document")


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
        steps = 0
        for module in atlas.VERSIONS:
            source = json.loads((atlas.ROOT / atlas.source_path(module)).read_text())
            region = self.document.split(atlas.begin(module))[1].split(atlas.END)[0]
            cells = rendered_cells(region)
            self.assertEqual(cells.pop(0), {"source": str(atlas.source_path(module)),
                                           **{k: source[k] for k in ("schema", "module", "namespace", "bound")}})
            for name in atlas.SELECTIONS[module]:
                with self.subTest(module=module, declaration=name):
                    matches = [w for w in source["witnesses"] if source["namespace"] + "." + name in w["declarations"]]
                    if name == "receipt_operation_limit":
                        # Independent source lookup: the order case, never the
                        # stop/restart/activation cases sharing its declaration.
                        matches = [w for w in matches if any(s["event"].get("operation") == "create" for s in w["steps"])
                                   and any(s["event"].get("target") == {"vendor_machine_id": 307}
                                           and s["event"]["kind"] == "associate" for s in w["steps"])]
                    self.assertEqual(len(matches), 1)
                    trace = matches[0]
                    provenance = cells.pop(0)
                    self.assertEqual(provenance["source"], str(atlas.source_path(module)))
                    self.assertEqual(provenance["declaration"], source["namespace"] + "." + name)
                    self.assertEqual(provenance["case"], [
                        {"kind": "request", "operation": "create"},
                        {"kind": "associate", "entry": 1, "target": {"vendor_machine_id": 307}}]
                        if name == "receipt_operation_limit" else None)
                    self.assertEqual(cells.pop(0), {k: v for k, v in trace.items() if k not in ("start", "steps")})
                    self.assertEqual(cells.pop(0), trace["start"])
                    state = {"dispatch": "knowledge", "allocation": "journal", "pins": "knowledge", "declaration": "record"}[module]
                    for step in trace["steps"]:
                        self.assertEqual(cells.pop(0), step["event"])
                        self.assertEqual(cells.pop(0), {k: v for k, v in step.items() if k not in ("event", state)})
                        self.assertEqual(cells.pop(0), step[state])
                        steps += 1
            self.assertEqual(cells, [])
        self.assertEqual(steps, 197)

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
        progress = traces["hold_reads_and_other_machines"]["steps"]
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
        self.assertEqual(len(atlas.project(source, self.index)["witnesses"]), len(atlas.SELECTION))

    def test_every_selected_pair_keeps_source_events_start_and_guard_difference(self):
        guards = {"dispatch": ("resourceKey", "commandHold", "durableBeforeApply", "commandHold",
                               "destructiveStops", "destructiveStops", "identityExclusion"),
                  "allocation": ("restoredAllocatesNone",),
                  "pins": ("reinstallRetiresPin", "publishedFresh"),
                  "declaration": ("emptyMeansPerField",)}
        for module, pairs in atlas.PAIR_NAMES.items():
            source = json.loads((atlas.ROOT / atlas.source_path(module)).read_text())
            selected = atlas.project(source, self.index, module=module)["witnesses"]
            for (left, right), guard in zip(pairs, guards[module]):
                with self.subTest(module=module, left=left):
                    a, b = [next(w for w in selected if source["namespace"] + "." + name in w["declarations"])
                            for name in (left, right)]
                    self.assertEqual(a["start"], b["start"])
                    self.assertEqual([s["event"] for s in a["steps"]], [s["event"] for s in b["steps"]])
                    self.assertEqual([k for k in a["assumptions"] if a["assumptions"][k] != b["assumptions"][k]], [guard])
                    self.assertEqual(a["pair"], {"side": "refused", "with": source["namespace"] + "." + right})
                    self.assertEqual(b["pair"], {"side": "admitted", "with": source["namespace"] + "." + left})

    def test_reused_declaration_requires_case_and_is_independent_of_source_order(self):
        source = copy.deepcopy(self.source)
        source["witnesses"].reverse()
        unselected = next(w for w in source["witnesses"] if atlas.NS + "receipt_operation_limit" in w["declarations"]
                          and w["steps"][0]["event"].get("operation") == "destroy")
        source["witnesses"].append(copy.deepcopy(unselected))
        selected = atlas.project(source, self.index)["witnesses"]
        receipt = selected[-1]
        self.assertEqual(receipt["steps"][0]["event"]["operation"], "create")
        self.assertEqual(receipt["steps"][2]["settled"], [1])
        with patch.dict(atlas.CASES, {}, clear=True):
            with self.assertRaisesRegex(atlas.Invalid, "receipt_operation_limit: expected one selected witness"):
                atlas.project(source, self.index)

    def test_multideclaration_quarantine_and_progress_preserve_risk(self):
        selected = atlas.project(self.source, self.index)["witnesses"]
        quarantine = next(w for w in selected if atlas.NS + "quarantine_has_no_target" in w["declarations"])
        self.assertEqual(quarantine["declarations"], [atlas.NS + "quarantine_has_no_target", atlas.NS + "retained_quarantine_conflict"])
        progress = next(w for w in selected if atlas.NS + "unavailable_receipt_never_settles" in w["declarations"])
        last = progress["steps"][-1]["knowledge"]
        self.assertIn({"entry": 1, "target": {"vendor_machine_id": 710}}, last["associations"])
        self.assertEqual(last["receipts"][0]["returned_vendor"], None)
        self.assertTrue(last["receipts"][0]["returned_withheld"])
        self.assertIn(901, last["unresolved"][0]["calls"])
        self.assertTrue(last["identity_exclusions"][1]["records"])

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
        for path in (*[atlas.source_path(m) for m in atlas.VERSIONS], atlas.ATLAS, atlas.INDEX):
            (self.root / path).parent.mkdir(parents=True, exist_ok=True)
            (self.root / path).write_bytes((atlas.ROOT / path).read_bytes())

    def run_gate(self, *options):
        out = io.StringIO()
        with redirect_stdout(out):
            code = atlas.main(["--root", str(self.root), *options])
        return code, out.getvalue()

    def test_each_mutation_has_exactly_its_own_finding_and_names_target(self):
        originals = {p: (self.root / p).read_bytes() for p in (*[atlas.source_path(m) for m in atlas.VERSIONS], atlas.ATLAS, atlas.INDEX)}
        for case, label in CASES.items():
            with self.subTest(case=case):
                for path, data in originals.items():
                    (self.root / path).write_bytes(data)
                mutate(case, self.root)
                code, output = self.run_gate("--check")
                self.assertEqual(code, 1, output)
                self.assertEqual(len(output.splitlines()), 1, output)
                self.assertTrue(output.startswith(label + ":"), output)
                self.assertIn(TARGETS[case], output)


    def test_write_does_not_repair_invalid_source_or_malformed_markers(self):
        originals = {p: (self.root / p).read_bytes() for p in (*[atlas.source_path(m) for m in atlas.VERSIONS], atlas.ATLAS, atlas.INDEX)}
        for case, label in CASES.items():
            if label in ("ATLAS DRIFT", "ATLAS LABELS"):
                continue
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
        for module in atlas.VERSIONS:
            with self.subTest(module=module):
                mutate("safe_label" if module == "dispatch" else module + "_safe_label", self.root)
                self.assertEqual(self.run_gate("--write")[0], 0)
                self.assertEqual(self.run_gate("--check")[0], 0)
                text = (self.root / atlas.ATLAS).read_text()
                self.assertEqual(text.count(atlas.END), len(atlas.VERSIONS))
                region = text.split(atlas.begin(module))[1].split(atlas.END)[0]
                values = rendered_cells(region)
                for label in LABELS:
                    self.assertTrue(any(type(v) is dict and v.get("provenance") == label for v in values), repr(label))



if __name__ == "__main__":
    unittest.main()
