"""Scratch-only mutations shared by atlas tests and discriminating gate controls."""

import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import render_state_machine_atlas as atlas

ADVERSARIAL = 'label | `tick` **bold** _word_ [link](javascript:bad) <script>x</script> & &#124;\n<!-- /atlas-info -->\n```json\n{}'
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


def mutate(name, root):
    source_path = root / atlas.SOURCE
    source = json.loads(source_path.read_text())
    document_path = root / atlas.ATLAS
    document = document_path.read_text()
    witness = next(w for w in source["witnesses"] if atlas.NS + atlas.SELECTION[0] in w["declarations"])
    if name in ("schema", "module", "namespace"):
        source[name] = 9 if name == "schema" else "unsupported"
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
        source_path.write_text(source_path.read_text().replace('"schema": 8', '"schema": 8, "schema": 8', 1))
        assert source_path.read_text().count('"schema": 8') == 2
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
        witness["steps"][0]["event"]["provenance"] = ADVERSARIAL
    elif name in ("stale", "evidence", "step_evidence", "applicability", "markers"):
        if name == "stale":
            document = document.replace("| 1 | <code>", "| 999 | <code>", 1)
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
    mutate(sys.argv[1], atlas.ROOT)
    if sys.argv[1] == "safe_label":
        # The control requires positive acceptance and data preservation, not
        # just that the malicious syntax was absent because everything vanished.
        assert atlas.main(["--write"]) == 0
        import html
        import re
        cells = re.findall(r"<code>(.*?)</code>", (atlas.ROOT / atlas.ATLAS).read_text())
        values = [json.loads(html.unescape(cell)) for cell in cells]
        assert any(type(v) is dict and v.get("provenance") == ADVERSARIAL for v in values)
        assert "<script>" not in (atlas.ROOT / atlas.ATLAS).read_text()
