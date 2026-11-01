#!/usr/bin/env python3
"""Informational Dispatch projection, never an evaluator of protocol guards.

Only the selected schema-8 slice and its bound context are supported. Unused
knowledge collections must stay empty until their shapes are explicitly supported.
Unselected witnesses/enumeration are not validated here (the witness gate owns
emission equality; corpus-wide pair validation belongs to tw-316).
"""

import argparse
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
SOURCE = Path("docs/design/dispatch-witnesses-v8.json")
ATLAS = Path("docs/state-machine-atlas.md")
INDEX = Path("tools/formal/.lake/index.jsonl")
BEGIN = "<!-- atlas-info: dispatch-v8 -->"
END = "<!-- /atlas-info -->"
NS = "TauWeb.Dispatch."
# Presentation selection, not a declaration registry: every name must resolve
# against this run's formal-gate index.
SELECTION = (
    "same_action_new_call_id_refused",
    "same_action_new_call_id_admitted",
    "lnvps_receipt_confirms",
    "second_command_held",
    "second_command_without_hold",
    "hold_reads_and_other_machines",
)
PAIRS = {
    NS + "same_action_new_call_id_refused": NS + "same_action_new_call_id_admitted",
    NS + "second_command_held": NS + "second_command_without_hold",
}
SCOPES = {
    "same_action_new_call_id_refused": "Typed resource barrier; reset requests, absent terminal evidence.",
    "same_action_new_call_id_admitted": "Withdrawn-guard counterexample; resourceKey = call. Not a permissible continuation.",
    "lnvps_receipt_confirms": "Stage-1 typed LNVPS restart receipt; vendor confirmation only, no guest/service/delivery evidence.",
    "second_command_held": "Installed-system command hold; actual refusal reason is barrier.",
    "second_command_without_hold": "Withdrawn-guard counterexample; commandHold = false. Not a permissible continuation.",
    "hold_reads_and_other_machines": "Command collection and successor session; other-machine steps are stage-1 fixtures, not multi-machine admission. Named trace exceeds the enumeration bound.",
}


class Invalid(ValueError):
    def __init__(self, label, target, message):
        super().__init__(f"{target}: {message}")
        self.label = label


def require(ok, label, target, message):
    if not ok:
        raise Invalid(label, target, message)


def no_duplicates(pairs):
    out = {}
    for key, value in pairs:
        require(key not in out, "ATLAS INPUT", key, "duplicate JSON member")
        out[key] = value
    return out


def read_json(path):
    try:
        return json.loads(path.read_text(), object_pairs_hook=no_duplicates)
    except (OSError, ValueError) as exc:
        if isinstance(exc, Invalid):
            raise
        raise Invalid("ATLAS INPUT", path, str(exc)) from exc


# Small closed shape vocabulary. These validate data, never outcomes/settlement.
def enum(*values):
    return ("enum", values)


def optional(shape):
    return ("nullable", shape)


def tagged(**arms):
    return ("tagged", arms)


def shape(value, spec, at):
    if isinstance(spec, dict):
        require(type(value) is dict and value.keys() == spec.keys(),
                "ATLAS INPUT", at, f"expected exactly members {sorted(spec)}")
        for key, child in spec.items():
            shape(value[key], child, f"{at}.{key}")
    elif isinstance(spec, list):
        require(type(value) is list, "ATLAS INPUT", at, "expected array")
        if not spec:
            require(not value, "ATLAS INPUT", at, "nonempty collection unsupported by this slice")
        else:
            for i, child in enumerate(value):
                shape(child, spec[0], f"{at}[{i}]")
    elif isinstance(spec, tuple):
        kind, arg = spec
        if kind == "enum":
            require(type(value) is str and value in arg, "ATLAS INPUT", at, f"expected one of {arg}")
        elif kind == "nullable":
            if value is not None:
                shape(value, arg, at)
        elif kind == "tagged":
            require(type(value) is dict and len(value) == 1 and next(iter(value)) in arg,
                    "ATLAS INPUT", at, "unsupported tagged object")
            key = next(iter(value))
            shape(value[key], arg[key], f"{at}.{key}")
        elif kind == "literal":
            require(type(value) is type(arg) and value == arg, "ATLAS INPUT", at, f"expected {arg!r}")
    else:
        require(type(value) is spec, "ATLAS INPUT", at, f"expected {spec.__name__}")
        if spec is int:
            require(value >= 0, "ATLAS INPUT", at, "expected nonnegative ordinal")
        if spec is str:
            require(bool(value.strip()), "ATLAS INPUT", at, "empty text")


OPERATION = enum("create", "reset", "reinstall", "destroy", "activate", "register_key",
                 "exec", "delivery_reboot", "read", "inference")
TARGET = tagged(entry=int, allocation_index=int, vendor_machine_id=int, inference_cap=("literal", True))
RESOURCE = tagged(machine_entry=int, inference=("literal", True))
BINDING = {"account": int, "operation": enum("order", "stop", "restart"), "signed_request": int}
APPROVAL = {"facts": int, "session": int, "receipt_binding": optional(BINDING)}
RECEIPT = {"binding": BINDING, "call": int, "resource": RESOURCE,
           "returned_vendor": optional(int), "returned_withheld": bool,
           "source": enum("browser_vendor_tls", "arbitrary_response", "job_output", "notify_event", "proposed_text"),
           "target": TARGET, "validated": bool}
KNOWLEDGE = {
    "associations": [{"entry": int, "target": TARGET}],
    "calls": [{"approved": APPROVAL, "call": int, "operation": OPERATION,
               "resource": RESOURCE, "session": int,
               "state": enum("unresolved", "terminal", "no_effect"), "target": TARGET}],
    "current_installations": [{"entry": int, "installation": int}],
    "dispatched": [int], "dispositions": [], "durable": bool,
    "identity_exclusions": [{"entry": int, "records": [int]}],
    "prerequisite_records": [], "quarantined": [], "reboot_results": [],
    "receipts": [RECEIPT], "reinstall_approvals": [], "reinstall_withdrawals": [],
    "reset_offer": [int], "standing": [],
    "unresolved": [{"calls": [int], "resource": RESOURCE}],
}
ASSUMPTIONS = dict.fromkeys((
    "approvalResetRequiresRescue", "approvedReinstallBoundary", "commandHold", "destructiveStops",
    "dispositionBindsContinuation", "dispositionOwnResource", "durableBeforeApply", "endedBelowSucceeded",
    "failedPrerequisiteWithdraws", "identityExclusion", "newestActivationRead", "orderAssociation",
    "rebootBootChange", "reinstallWithdrawalEffective", "resetIntoRescueOnly",
    "resetOfferCurrentInstallation", "resetOfferFreshKeys", "sessionDestroyRefused"), bool)
ASSUMPTIONS.update(lapse=enum("continuation", "any_intent", "first_operation"),
                   reach=enum("disposed", "resource", "every_dispatch", "still_unresolved"),
                   resourceKey=enum("entry", "index", "call"))
EVENTS = {
    "request": {"appended": bool, "approved": APPROVAL, "call": int, "facts": int,
                "operation": OPERATION, "session": int, "target": TARGET},
    "read": {"appended": bool, "operation": OPERATION,
             "reports": enum("unknown", "ended", "succeeded"), "resource": RESOURCE,
             "source": enum("adapter_read", "pin_checked_handshake", "job_record", "notify_event", "model_text")},
    "receive": {"appended": bool, "receipt": RECEIPT},
    "dispose": {"appended": bool, "calls": [int], "continuation": enum(
        "destructive_reinstall", "abandonment", "as_if_done", "as_if_not_done"), "resource": RESOURCE},
    "replay": {},
}


def event_shape(event, at):
    require(type(event) is dict and type(event.get("kind")) is str and event["kind"] in EVENTS,
            "ATLAS INPUT", at, "unsupported event kind")
    shape(event, dict(EVENTS[event["kind"]], kind=str, provenance=str), at)


def trace_shape(trace, at):
    expected = {"declarations", "assumptions", "start", "steps"}
    require(type(trace) is dict and set(trace) in (expected, expected | {"pair"}),
            "ATLAS INPUT", at, "unsupported trace members")
    shape(trace["declarations"], [str], at + ".declarations")
    require(bool(trace["declarations"]) and len(set(trace["declarations"])) == len(trace["declarations"]),
            "ATLAS SELECTION", at, "empty or repeated declarations")
    shape(trace["assumptions"], ASSUMPTIONS, at + ".assumptions")
    shape(trace["start"], KNOWLEDGE, at + ".start")
    require(type(trace["steps"]) is list and bool(trace["steps"]), "ATLAS INPUT", at + ".steps", "expected nonempty array")
    if "pair" in trace:
        try:
            shape(trace["pair"], {"side": enum("refused", "admitted"), "with": str}, at + ".pair")
        except Invalid as exc:
            raise Invalid("ATLAS PAIRS", at + ".pair", str(exc)) from exc
    for i, step in enumerate(trace["steps"], 1):
        loc = f"{at}.steps[{i}]"
        require(type(step) is dict and "event" in step and "knowledge" in step,
                "ATLAS INPUT", loc, "missing event/knowledge")
        event_shape(step["event"], loc + ".event")
        shape(step["knowledge"], KNOWLEDGE, loc + ".knowledge")
        kind = step["event"]["kind"]
        fields = {"event", "knowledge"}
        if kind == "request":
            shape(step.get("dispatch"), enum("dispatched", "refused"), loc + ".dispatch")
            fields.add("dispatch")
            if step["dispatch"] == "refused":
                fields.add("refusal")
                # Only barrier refusals occur in this projection. Other refusal
                # shapes require deliberate support rather than silent omission.
                shape(step.get("refusal"), {"reason": enum("barrier"), "calls": [int]}, loc + ".refusal")
        elif kind in ("read", "receive"):
            fields.add("settled")
            shape(step.get("settled"), [int], loc + ".settled")
        elif kind == "dispose":
            fields.add("disposition")
            shape(step.get("disposition"), enum("recorded", "refused"), loc + ".disposition")
        require(set(step) == fields, "ATLAS INPUT", loc, f"expected exactly {sorted(fields)}")


def declarations(path):
    try:
        rows = [json.loads(line, object_pairs_hook=no_duplicates) for line in path.read_text().splitlines() if line.strip()]
        require(all(type(row) is dict and type(row.get("decl")) is str for row in rows),
                "ATLAS DECLARATIONS", path, "malformed formal index")
        return {row["decl"] for row in rows}
    except (OSError, ValueError) as exc:
        raise Invalid("ATLAS DECLARATIONS", path, f"formal index required: {exc}") from exc


def project(source, names, selection=SELECTION):
    require(type(source) is dict, "ATLAS INPUT", SOURCE, "expected object")
    require(type(source.get("schema")) is int and source["schema"] == 8
            and source.get("module") == "dispatch" and source.get("namespace") == "TauWeb.Dispatch",
            "ATLAS HEADER", SOURCE, "requires schema 8, module dispatch, namespace TauWeb.Dispatch")
    require(set(source) == {"schema", "module", "namespace", "bound", "witnesses", "enumeration"}
            and type(source["witnesses"]) is list and type(source["enumeration"]) is list,
            "ATLAS INPUT", SOURCE, "unsupported file structure")
    bound = source["bound"]
    require(type(bound) is dict and set(bound) == {"declaration", "events", "alphabet", "start"},
            "ATLAS INPUT", "bound", "unsupported bound structure")
    shape(bound["declaration"], str, "bound.declaration")
    shape(bound["events"], int, "bound.events")
    shape(bound["start"], KNOWLEDGE, "bound.start")
    require(type(bound["alphabet"]) is list and bool(bound["alphabet"]), "ATLAS INPUT", "bound.alphabet", "expected nonempty array")
    for i, event in enumerate(bound["alphabet"]):
        event_shape(event, f"bound.alphabet[{i}]")
    require(len(set(selection)) == len(selection), "ATLAS SELECTION", SOURCE, "duplicate selection")
    selected = []
    for name in selection:
        decl = NS + name
        matches = [w for w in source["witnesses"] if type(w) is dict
                   and type(w.get("declarations")) is list and decl in w["declarations"]]
        require(len(matches) == 1, "ATLAS SELECTION", decl, f"expected one selected witness, found {len(matches)}")
        trace_shape(matches[0], decl)
        require(not any(matches[0] is old for old in selected), "ATLAS SELECTION", decl, "trace selected twice")
        selected.append(matches[0])
    refs = [bound["declaration"]]
    for trace in selected:
        refs.extend(trace["declarations"])
        if "pair" in trace:
            refs.append(trace["pair"]["with"])
    for ref in refs:
        require(ref in names, "ATLAS DECLARATIONS", ref, "not in current formal index")
    by_decl = {decl: trace for trace in selected for decl in trace["declarations"]}
    for left, right in PAIRS.items():
        for decl, partner, side in ((left, right, "refused"), (right, left, "admitted")):
            require(decl in by_decl and by_decl[decl].get("pair") == {"side": side, "with": partner},
                    "ATLAS PAIRS", decl, "required pair metadata/partner missing or changed")
    for trace in selected:
        if "pair" in trace:
            pair = trace["pair"]
            partner = by_decl.get(pair["with"])
            require(partner is not None and partner.get("pair", {}).get("with") in trace["declarations"]
                    and partner["pair"]["side"] != pair["side"],
                    "ATLAS PAIRS", trace["declarations"][0], "selected pair must be reciprocal and whole")
    projection = {k: source[k] for k in ("schema", "module", "namespace", "bound")}
    projection["witnesses"] = selected
    require(not re.search(r"\bCNF-\d+", json.dumps(projection)), "ATLAS INPUT", SOURCE, "conformance identifier in projection")
    return projection


def cell(value):
    # JSON gives newlines/control bytes a visible, reversible representation.
    # Escape '<' as JSON too, so data cannot spell an informational marker.
    text = json.dumps(value, ensure_ascii=True, sort_keys=True).replace("<", r"\u003c")
    # A real code span prevents GFM inline parsing, including late autolinking.
    # The table extension removes the extra backslash before each literal pipe.
    fence = "`" * (1 + max((len(run) for run in re.findall(r"`+", text)), default=0))
    return fence + text.replace("|", r"\|") + fence


def render(projection):
    out = ["Evidence: generated witness projection; informational, source-attributed harness knowledge.",
           "Applicability: Dispatch selected typed traces; stage-1 fixtures where another machine appears.",
           "External possibilities: not recorded here. Permitted next actions: consult the owner matrix; source dispatch results alone supply no authority.",
           "", "| Source header and bound context (complete) |", "|---|",
           "| " + cell({k: v for k, v in projection.items() if k != "witnesses"}) + " |", ""]
    for name, trace in zip(SELECTION, projection["witnesses"]):
        out += ["### " + name.replace("_", " "), "",
                f"Evidence: generated witness projection — {name}.",
                "Applicability: " + SCOPES[name], "",
                "| Source metadata | Value |", "|---|---|",
                "| Declarations, assumptions, pair (when present) | " + cell({k: v for k, v in trace.items() if k not in ("start", "steps")}) + " |",
                "| Starting knowledge (complete) | " + cell(trace["start"]) + " |", "",
                f"Evidence: generated witness projection — {name} steps.",
                "Applicability: " + SCOPES[name] + " Source steps.",
                "External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies to every source dispatch result.", "",
                "| Step | Source event | Source outcome members (empty means none) | Source knowledge after step (complete) |",
                "|---|---|---|---|"]
        for i, step in enumerate(trace["steps"], 1):
            outcome = {k: v for k, v in step.items() if k not in ("event", "knowledge")}
            out.append(f"| {i} | {cell(step['event'])} | {cell(outcome)} | {cell(step['knowledge'])} |")
        out.append("")
    return "\n".join(out)


def replace_region(document, rendered, check=True):
    lines = document.splitlines(keepends=True)
    require(document.count(BEGIN) == document.count(END) == 1
            and sum(line.rstrip("\n") == BEGIN for line in lines) == 1
            and sum(line.rstrip("\n") == END for line in lines) == 1,
            "ATLAS REGIONS", ATLAS, "expected exactly one standalone informational marker pair")
    start = document.index(BEGIN) + len(BEGIN)
    end = document.index(END)
    require(start < end, "ATLAS REGIONS", ATLAS, "reversed informational markers")
    old = document[start:end]
    if check:
        for line in rendered.splitlines():
            if line.startswith(("Evidence:", "Applicability:")):
                require(old.splitlines().count(line) == 1, "ATLAS LABELS", ATLAS, f"missing/changed local label: {line}")
    return document[:start] + "\n" + rendered + document[end:]


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--write", action="store_true", help="regenerate informational region, preserving prose")
    mode.add_argument("--check", action="store_true", help="check for drift (default)")
    parser.add_argument("--root", type=Path, default=ROOT, help="tree containing source, atlas and current formal index")
    args = parser.parse_args(argv)
    try:
        projection = project(read_json(args.root / SOURCE), declarations(args.root / INDEX))
        path = args.root / ATLAS
        document = path.read_text()
        expected = replace_region(document, render(projection), check=not args.write)
        if args.write:
            path.write_text(expected)
        else:
            require(document == expected, "ATLAS DRIFT", ATLAS,
                    f"informational projection differs from {SOURCE}; regenerate with --write")
        print(f"atlas: {len(projection['witnesses'])} selected witnesses, "
              f"{sum(len(w['steps']) for w in projection['witnesses'])} source steps; presentation evidence only")
        print("ATLAS DRIFT: none")
        return 0
    except (Invalid, OSError) as exc:
        label = exc.label if isinstance(exc, Invalid) else "ATLAS INPUT"
        # One physical finding line even for adversarial labels or parser errors.
        print(f"{label}: {str(exc)!r}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
