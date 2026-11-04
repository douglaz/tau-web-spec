"""Scratch-only mutations shared by atlas tests and discriminating gate controls."""

import json
from html.parser import HTMLParser
from pathlib import Path
import subprocess
import string
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import render_state_machine_atlas as atlas

ADVERSARIAL = 'label | `tick` **bold** _word_ [link](javascript:bad) <script>x</script> & &#124;\n<!-- /atlas-info -->\n```json\n{}'
LABELS = (ADVERSARIAL, "~~atlas-label~~", "https://example.com/atlas-label",
          "www.example.com/atlas-label", "atlas@example.com",
          "\r\n\t\x00\x1f\\`|<>&\"'", "&#96; &amp; &lt;code&gt;", "λ",
          string.punctuation, '</code><a href="https://example.com">link</a>',
          r'| \| \\| \\\| ` `` ``` ````  repeated  spaces')


def rendered_cells(markdown):
    """Decode JSON from actual GFM table cells, refusing nested inline markup.

    Raw HTML is enabled as in the viewer that exposed the bug. Missing parser
    tooling is an error; flake.nix supplies the pinned cmark-gfm for tests/CI.
    """
    rendered = subprocess.run(
        ["cmark-gfm", "--unsafe", "-e", "table", "-e", "strikethrough", "-e", "autolink"],
        input=markdown, text=True, capture_output=True, check=True).stdout

    class Cells(HTMLParser):
        def __init__(self):
            super().__init__(convert_charrefs=True)
            self.stack = []
            self.parts = None
            self.values = []

        def handle_starttag(self, tag, attrs):
            assert self.parts is None, f"unexpected <{tag}> inside literal code cell"
            if tag == "code":
                assert self.stack and self.stack[-1] == "td", "code must remain in a table cell"
                assert not attrs, "unexpected code attributes"
                self.parts = []
            self.stack.append(tag)

        def handle_endtag(self, tag):
            assert self.stack and self.stack.pop() == tag, f"unbalanced </{tag}>"
            if tag == "code":
                self.values.append(json.loads("".join(self.parts)))
                self.parts = None

        def handle_data(self, data):
            if self.parts is not None:
                self.parts.append(data)

        def handle_comment(self, data):
            assert self.parts is None, "unexpected comment inside literal code cell"

    cells = Cells()
    cells.feed(rendered)
    cells.close()
    assert not cells.stack and cells.parts is None, "unclosed HTML"
    return cells.values


CASES = {
    "stale": "ATLAS DRIFT", "schema": "ATLAS HEADER", "module": "ATLAS HEADER",
    "namespace": "ATLAS HEADER", "missing": "ATLAS SELECTION", "ambiguous": "ATLAS SELECTION",
    "unresolved": "ATLAS DECLARATIONS", "index": "ATLAS DECLARATIONS",
    "outcome": "ATLAS DRIFT", "shape": "ATLAS INPUT", "nested": "ATLAS INPUT",
    "missing_data": "ATLAS INPUT", "unknown_event": "ATLAS INPUT", "missing_outcome": "ATLAS INPUT",
    "boolean_ordinal": "ATLAS INPUT", "unsupported_collection": "ATLAS INPUT",
    "continuation_token": "ATLAS INPUT", "false_tag": "ATLAS INPUT",
    "duplicate_member": "ATLAS INPUT", "conformance_id": "ATLAS INPUT",
    "evidence": "ATLAS LABELS", "step_evidence": "ATLAS LABELS", "applicability": "ATLAS LABELS",
    "pair": "ATLAS PAIRS", "pair_side": "ATLAS PAIRS", "partner": "ATLAS PAIRS",
    "markers": "ATLAS REGIONS",
}


TARGETS = {
    'stale': 'docs/state-machine-atlas.md',
    'schema': 'docs/design/dispatch-witnesses-v9.json',
    'module': 'docs/design/dispatch-witnesses-v9.json',
    'namespace': 'docs/design/dispatch-witnesses-v9.json',
    'missing': 'same_action_new_call_id_refused',
    'ambiguous': 'same_action_new_call_id_refused',
    'unresolved': 'absent_atlas_declaration',
    'index': 'index.jsonl',
    'outcome': 'docs/design/dispatch-witnesses-v9.json',
    'shape': 'same_action_new_call_id_refused.start',
    'nested': 'receipt_binding',
    'missing_data': 'knowledge',
    'unknown_event': 'event',
    'missing_outcome': 'refusal',
    'boolean_ordinal': 'event.call',
    'unsupported_collection': 'start.standing',
    'continuation_token': 'bound.alphabet',
    'false_tag': 'inference_cap',
    'duplicate_member': 'schema',
    'conformance_id': 'docs/design/dispatch-witnesses-v9.json',
    'evidence': 'docs/state-machine-atlas.md',
    'step_evidence': 'docs/state-machine-atlas.md',
    'applicability': 'docs/state-machine-atlas.md',
    'pair': 'same_action_new_call_id_refused',
    'pair_side': 'same_action_new_call_id_refused',
    'partner': 'same_action_new_call_id_refused',
    'markers': 'docs/state-machine-atlas.md',
}

# Every newly supported module gets its own malformed header, selected case,
# context, nested/collection/step shape, pair, emission drift and label controls.
for module in ("allocation", "pins", "declaration"):
    first = atlas.SELECTIONS[module][0]
    for case, label in {
        "schema": "ATLAS HEADER", "module": "ATLAS HEADER", "namespace": "ATLAS HEADER",
        "missing": "ATLAS SELECTION", "ambiguous": "ATLAS SELECTION",
        "unresolved": "ATLAS DECLARATIONS", "bound": "ATLAS INPUT", "nested": "ATLAS INPUT",
        "collection": "ATLAS INPUT", "step": "ATLAS INPUT", "missing_data": "ATLAS INPUT", "unknown_event": "ATLAS INPUT", "pair": "ATLAS PAIRS", "partner": "ATLAS PAIRS",
        "outcome": "ATLAS DRIFT", "start": "ATLAS DRIFT", "evidence": "ATLAS LABELS",
        "step_evidence": "ATLAS LABELS", "applicability": "ATLAS LABELS", "conformance_id": "ATLAS INPUT",
    }.items():
        name = module + "_" + case
        CASES[name] = label
        TARGETS[name] = (str(atlas.source_path(module)) if label == "ATLAS HEADER" or case == "conformance_id" else
                         "bound" if case == "bound" else
                         "state-machine-atlas.md" if label in ("ATLAS DRIFT", "ATLAS LABELS") else
                         "absent_atlas_declaration" if case == "unresolved" else
                         atlas.SELECTIONS[module][-3] if module == "declaration" and case in ("pair", "partner") else first)
for case, label, target in (
    ("case_absent", "ATLAS SELECTION", "receipt_operation_limit"),
    ("case_ambiguous", "ATLAS SELECTION", "receipt_operation_limit"),
    ("secondary_declaration", "ATLAS DECLARATIONS", "absent_atlas_declaration"),
    ("quarantine_shape", "ATLAS INPUT", "quarantine_has_no_target"),
    ("reboot_result_shape", "ATLAS INPUT", "delivery_reboot_failed_append_holds"),
    ("standing_shape", "ATLAS INPUT", "destructive_choice_stops_delivery_reboot"),
    ("marker_unknown", "ATLAS REGIONS", "state-machine-atlas.md"),
    ("marker_nested", "ATLAS REGIONS", "state-machine-atlas.md"),
    ("marker_duplicate", "ATLAS REGIONS", "state-machine-atlas.md"),
    ("marker_inline", "ATLAS REGIONS", "state-machine-atlas.md"),
    ("marker_reversed", "ATLAS REGIONS", "state-machine-atlas.md"),
):
    CASES[case] = label
    TARGETS[case] = target


def mutate_module(case, module, root):
    path = root / atlas.source_path(module)
    source = json.loads(path.read_text())
    namespace = source["namespace"] + "."
    name = atlas.SELECTIONS[module][0]
    witness = next(w for w in source["witnesses"] if namespace + name in w["declarations"])
    if case in ("schema", "module", "namespace"):
        source[case] = 999 if case == "schema" else "unsupported"
    elif case == "missing":
        source["witnesses"].remove(witness)
    elif case == "ambiguous":
        source["witnesses"].append(witness)
    elif case == "unresolved":
        witness["declarations"].append(namespace + "absent_atlas_declaration")
    elif case == "bound":
        source["bound"]["unexpected"] = True
    elif case == "nested":
        if module == "allocation":
            witness["start"]["next_unused"]["machines"] = True
        elif module == "pins":
            witness["steps"][0]["knowledge"]["publication_groups"][0]["observations"] = [[{}]]
        else:
            witness["start"]["machine"]["observed"]["services"] = [{}]
    elif case == "collection":
        if module == "allocation":
            witness["start"]["entries"] = [{}]
        elif module == "pins":
            witness["start"]["pending_reinstall"] = [{}]
        else:
            witness["start"]["record"]["verdicts"]["services"] = {}
    elif case == "missing_data":
        del witness["steps"][0][atlas.PROJECTIONS[module]]
    elif case == "unknown_event":
        witness["steps"][0]["event"]["kind"] = "invented_transition"
    elif case == "step":
        witness["steps"][0]["invented"] = True
    elif case in ("pair", "partner"):
        if module == "declaration":
            witness = next(w for w in source["witnesses"] if namespace + "empty_inbound_refused" in w["declarations"])
        if case == "pair":
            del witness["pair"]
        else:
            witness["pair"]["with"] = namespace + atlas.SELECTIONS[module][-1]
    elif case == "outcome":
        if module == "allocation":
            witness["steps"][0]["recorded"] = False
        elif module == "pins":
            witness["steps"][0]["pinned"] = False
        else:
            witness["steps"][0]["verdict"] = "finding"
    elif case == "start":
        if module == "allocation":
            witness["start"]["seed"] = 999
        elif module == "pins":
            witness["start"]["planted_senders"][0]["sender"] = 999
        else:
            witness["start"]["machine"]["multi_tenant"] = True
    elif case == "conformance_id":
        witness["steps"][0]["event"]["provenance"] = "CNF-999"
    elif case == "safe_label":
        for label, step in zip(LABELS, (s for w in source["witnesses"]
                                      if any(namespace + n in w["declarations"] for n in atlas.SELECTIONS[module])
                                      for s in w["steps"])):
            step["event"]["provenance"] = label
    elif case in ("evidence", "step_evidence", "applicability"):
        document_path = root / atlas.ATLAS
        document = document_path.read_text()
        region = document.split(atlas.begin(module))[1].split(atlas.END)[0]
        line = next(line for line in region.splitlines() if
                    (line == f"Evidence: generated witness projection — {name}." if case == "evidence" else
                     line == f"Evidence: generated witness projection — {name} steps." if case == "step_evidence" else
                     line.startswith("Applicability:") and f"View: {name}." in line))
        document_path.write_text(document.replace(line, "", 1))
        return
    else:
        raise ValueError(case)
    path.write_text(json.dumps(source))


def mutate(name, root):
    for module in ("allocation", "pins", "declaration"):
        if name.startswith(module + "_"):
            return mutate_module(name[len(module) + 1:], module, root)
    source_path = root / atlas.SOURCE
    source = json.loads(source_path.read_text())
    document_path = root / atlas.ATLAS
    document = document_path.read_text()
    witness = next(w for w in source["witnesses"] if atlas.NS + atlas.SELECTION[0] in w["declarations"])
    if name in ("case_absent", "case_ambiguous"):
        chosen = next(w for w in source["witnesses"] if atlas.NS + "receipt_operation_limit" in w["declarations"]
                      and any(s["event"].get("operation") == "create" for s in w["steps"]))
        if name == "case_absent":
            source["witnesses"].remove(chosen)
        else:
            source["witnesses"].append(chosen)
    elif name == "secondary_declaration":
        chosen = next(w for w in source["witnesses"] if atlas.NS + "quarantine_has_no_target" in w["declarations"])
        chosen["declarations"][1] = atlas.NS + "absent_atlas_declaration"
    elif name in ("quarantine_shape", "reboot_result_shape", "standing_shape"):
        field, decl = {"quarantine_shape": ("quarantined", "quarantine_has_no_target"),
                       "reboot_result_shape": ("reboot_results", "delivery_reboot_failed_append_holds"),
                       "standing_shape": ("standing", "destructive_choice_stops_delivery_reboot")}[name]
        chosen = next(w for w in source["witnesses"] if atlas.NS + decl in w["declarations"])
        step = next(s for s in chosen["steps"] if s["knowledge"][field])
        step["knowledge"][field][0]["unexpected"] = True
    elif name.startswith("marker_"):
        marker = atlas.begin("declaration")
        if name == "marker_unknown":
            document += "\n<!-- atlas-info: unknown-v99 -->\n<!-- /atlas-info -->\n"
        elif name == "marker_nested":
            document = document.replace(atlas.END, marker + "\n" + atlas.END, 1)
        elif name == "marker_duplicate":
            document += "\n" + marker + "\n" + atlas.END + "\n"
        elif name == "marker_inline":
            document = document.replace(marker, "prefix " + marker)
        elif name == "marker_reversed":
            document = document.replace(marker, atlas.END, 1)
        else:
            raise ValueError(name)
        document_path.write_text(document)
        return
    elif name in ("schema", "module", "namespace"):
        source[name] = 999 if name == "schema" else "unsupported"
    elif name == "missing":
        source["witnesses"].remove(witness)
    elif name == "ambiguous":
        source["witnesses"].append(witness)
    elif name == "unresolved":
        witness["declarations"].append(atlas.NS + "absent_atlas_declaration")
    elif name == "index":
        (root / atlas.INDEX).unlink()
        return
    elif name == "outcome":
        witness["steps"][1]["refusal"]["calls"] = [999]
    elif name == "shape":
        witness["start"]["unexpected"] = True
    elif name == "nested":
        witness["steps"][0]["event"]["approved"]["receipt_binding"] = {"operation": "restart"}
    elif name == "missing_data":
        del witness["steps"][0]["knowledge"]["unresolved"]
    elif name == "unknown_event":
        witness["steps"][0]["event"]["kind"] = "lost_response"
    elif name == "missing_outcome":
        del witness["steps"][1]["refusal"]
    elif name == "boolean_ordinal":
        witness["steps"][0]["event"]["call"] = True
    elif name == "unsupported_collection":
        witness["start"]["standing"] = [{}]
    elif name == "continuation_token":
        source["bound"]["alphabet"][4]["continuation"] = "continue_as_done"
    elif name == "false_tag":
        witness["steps"][0]["event"]["target"] = {"inference_cap": False}
    elif name == "duplicate_member":
        source_path.write_text(source_path.read_text().replace('"schema": 9', '"schema": 9, "schema": 9', 1))
        assert source_path.read_text().count('"schema": 9') == 2
        return
    elif name == "conformance_id":
        witness["steps"][0]["event"]["provenance"] = "CNF-999"
    elif name == "pair":
        del witness["pair"]
    elif name == "pair_side":
        witness["pair"]["side"] = "admitted"
    elif name == "partner":
        # Partner still exists in the source and resolves in the index, but is
        # no longer selected with this trace. No dangling-name incidental red.
        witness["pair"]["with"] = atlas.NS + "ceremony_trace"
    elif name == "safe_label":
        events = (s["event"] for w in source["witnesses"]
                  if any(atlas.NS + name in w["declarations"] for name in atlas.SELECTION)
                  for s in w["steps"])
        for label in LABELS:
            next(events)["provenance"] = label
    elif name in ("stale", "evidence", "step_evidence", "applicability", "markers"):
        if name == "stale":
            document = document.replace("| 1 | ", "| 999 | ", 1)
        elif name == "evidence":
            document = document.replace("Evidence: generated witness projection — same_action_new_call_id_refused.", "", 1)
        elif name == "step_evidence":
            document = document.replace("Evidence: generated witness projection — same_action_new_call_id_refused steps.", "", 1)
        elif name == "applicability":
            document = document.replace("Applicability: " + atlas.SCOPES[atlas.SELECTION[0]], "", 1)
        else:
            document = document.replace(atlas.END, "", 1)
        assert document != document_path.read_text()
        document_path.write_text(document)
        return
    else:
        raise ValueError(name)
    source_path.write_text(json.dumps(source))


if __name__ == "__main__":
    if sys.argv[1] == "--controls":
        for name, label in CASES.items():
            print(f"{name}|{label}|{TARGETS[name]}")
        sys.exit(0)
    mutate(sys.argv[1], atlas.ROOT)
    if sys.argv[1].endswith("safe_label"):
        # Acceptance also requires decoded values; stripping labels cannot pass.
        assert atlas.main(["--write"]) == 0
        document = (atlas.ROOT / atlas.ATLAS).read_text()
        module = sys.argv[1].removesuffix("_safe_label") if sys.argv[1] != "safe_label" else "dispatch"
        region = document.split(atlas.begin(module))[1].split(atlas.END)[0]
        values = rendered_cells(region)
        for label in LABELS:
            assert any(type(v) is dict and v.get("provenance") == label for v in values), repr(label)
        assert "<script>" not in document
