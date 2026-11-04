#!/usr/bin/env python3
"""Informational witness projections, never an evaluator of protocol guards.

Only selected exact-schema slices and their complete bound contexts are supported.
Unused collections stay empty until their shapes are explicitly supported.
Unselected witnesses/enumeration are not validated here (the witness gate owns
emission equality and corpus-wide marked pair validation).
"""

import argparse
import json
import os
from pathlib import Path
import re
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
SOURCE = Path("docs/design/dispatch-witnesses-v9.json")
ATLAS = Path("docs/state-machine-atlas.md")
INDEX = Path("tools/formal/.lake/index.jsonl")
BEGIN = "<!-- atlas-info: dispatch-v9 -->"
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
    "resolution_append_failed_refused",
    "resolution_append_failed_admitted",
    "command_holds_delivery_reboot",
    "delivery_reboot_without_hold",
    "delivery_reboot_failed_append_holds",
    "delivery_reboot_exec_approval_refused",
    "destructive_choice_stops_delivery_reboot",
    "delivery_reboot_dispatched_without_destructive_stop",
    "destructive_choice_stops_commands",
    "command_preempts_reinstall_without_guard",
    "excluded_order_refused",
    "excluded_order_sent_without_guard",
    "quarantine_has_no_target",
    "withheld_association_excludes",
    "unavailable_receipt_never_settles",
    "receipt_operation_limit",
)
# Presentation choices resolve through the current formal index, not this list.
PAIR_NAMES = {
    "dispatch": (
        ("same_action_new_call_id_refused", "same_action_new_call_id_admitted"),
        ("second_command_held", "second_command_without_hold"),
        ("resolution_append_failed_refused", "resolution_append_failed_admitted"),
        ("command_holds_delivery_reboot", "delivery_reboot_without_hold"),
        ("destructive_choice_stops_delivery_reboot", "delivery_reboot_dispatched_without_destructive_stop"),
        ("destructive_choice_stops_commands", "command_preempts_reinstall_without_guard"),
        ("excluded_order_refused", "excluded_order_sent_without_guard")),
    "allocation": (("stale_sheet_refused", "stale_sheet_admitted"),),
    "pins": (("old_pin_refused_pending_reinstall", "old_pin_admitted_without_reinstall_guard"),
             ("overlapping_publication_refused", "overlapping_publication_admitted_without_guard")),
    "declaration": (("empty_inbound_refused", "empty_inbound_admitted"),),
}
SELECTIONS = {
    "dispatch": SELECTION,
    "allocation": ("stale_sheet_refused", "stale_sheet_admitted", "replace_allocates_again"),
    "pins": ("old_pin_refused_pending_reinstall", "old_pin_admitted_without_reinstall_guard",
             "overlapping_publication_refused", "overlapping_publication_admitted_without_guard",
             "older_publication_still_refused_after_restart", "pending_restart_then_fresh_admitted"),
    "declaration": ("undeclared_listener_finding", "template_blocked", "absent_field_refused",
                    "empty_inbound_refused", "empty_inbound_admitted", "adhoc_delivered"),
}
VERSIONS = {"dispatch": 9, "allocation": 3, "pins": 5, "declaration": 1}
PROJECTIONS = {"dispatch": "knowledge", "allocation": "journal", "pins": "knowledge", "declaration": "record"}
APPLICABILITY = {
    "dispatch": "Typed Dispatch; session termination and single writer assumed. No pending-check, lifecycle, untyped, protected encoding/listing or inference-clock coverage.",
    "allocation": "Restore/Replace allocation identities only; no key migration, discovery merge or pre-loss command handling. Fresh entropy and imported-sheet construction assumed.",
    "pins": "LNVPS installed publication history; symbolic fingerprints. Atomic durable append/restart assumed; no TLS, scan honesty, timing, no-contact or dispatch proof.",
    "declaration": "Field presence and opaque-item set difference only; no service lifecycle, secret placement, scan readiness or post-placement re-check semantics.",
}
SCOPES = {
    "same_action_new_call_id_refused": "Typed resource barrier; reset requests, absent terminal evidence. Evidence/operator dependency: see the separate receipt view; no replay event here.",
    "same_action_new_call_id_admitted": "Withdrawn-guard trap; resourceKey = call. Never a production-success target.",
    "lnvps_receipt_confirms": "Stage-1 typed LNVPS restart receipt only; no guest/service/delivery verdict. Replay is last, with no post-replay request.",
    "second_command_held": "Installed command hold; source refusal reason is barrier. Separate collection/successor continuation follows.",
    "second_command_without_hold": "Withdrawn-guard trap; commandHold = false. Never a production-success target.",
    "hold_reads_and_other_machines": "Command replay, successor refusal, collection and new command. Other-machine and inference steps are fixtures, not admission evidence; no waiter/flow-resumption proof.",
    "resolution_append_failed_refused": "Robot read-confirmed reset, not LNVPS restart. Failed observation append retains barrier; further qualifying durable evidence or operator action needed.",
    "resolution_append_failed_admitted": "Withdrawn durableBeforeApply trap; in-memory settlement despite failed append. Never a production-success target.",
    "command_holds_delivery_reboot": "Dedicated reboot held behind exec; not stage-1 typed-restart evidence. Collection progress is a separate history below.",
    "delivery_reboot_without_hold": "Withdrawn commandHold trap for a dedicated harness reboot. Never a production-success target.",
    "delivery_reboot_failed_append_holds": "Dedicated boot-change result: failed append, replay/successor refusal, durable collection and later exec. That exec assumes the omitted delivery verdict; no pending-check proof.",
    "delivery_reboot_exec_approval_refused": "Dedicated harness reboot refuses same-session ordinary exec approval facts at the request, with no intent or journal change. Unpaired: valid reboot approval is a different input under the same assumptions; the separate failed-append history carries admitted progress. Symbolic facts do not prove fresh consent or re-asking after a held first issue.",
    "destructive_choice_stops_delivery_reboot": "Dedicated harness reboot under standing destructive reinstall; outcome unknown. Reinstall/evidence progress is a separate command history below.",
    "delivery_reboot_dispatched_without_destructive_stop": "Withdrawn destructiveStops trap; requester cannot make this production success.",
    "destructive_choice_stops_commands": "Separate destructive-command history: reinstall dispatch then confirmation then exec; no waiter or automatic harness-flow resumption evidence.",
    "command_preempts_reinstall_without_guard": "Withdrawn destructiveStops partner; retain uncertainty and standing continuation. Never a production-success target.",
    "excluded_order_refused": "Received-present withheld identity; identity_exclusion.records retained through replay. Identity exclusion is an exception to resource independence; a new entry supplies no reorder authority.",
    "excluded_order_sent_without_guard": "Withdrawn identityExclusion trap. Never a production-success target.",
    "quarantine_has_no_target": "Both source declarations retained: quarantine grants no target; retained quarantine conflicts remain. Progress needs independently admissible evidence/operator action; no risk-clearing event exists.",
    "withheld_association_excludes": "Withheld association and replay retain cross-entry exclusion. Reads, dispositions and already admitted maps have separate authority; no invented clearing.",
    "unavailable_receipt_never_settles": "Later independently admissible same-entry mapping supplies a target, never reconstructed receipt equality or risk discharge. Earlier receipt remains unsettled.",
    "receipt_operation_limit": "Separate retained-ID order/association/receipt success; no unavailable identity in this history and no repair of quarantine. Explicit source-event discriminator below.",
}
for module in ("allocation", "pins", "declaration"):
    for name in SELECTIONS[module]:
        SCOPES[name] = APPLICABILITY[module]
        if any(name == right for _, right in PAIR_NAMES[module]):
            SCOPES[name] += " Withdrawn-guard historical trap, never a production-success target."
# Reused declarations need a stable event-argument discriminator. No positional
# witness index, first-match selection, outcome inference or provenance restriction.
CASES = {
    ("dispatch", "receipt_operation_limit"): (
        {"kind": "request", "operation": "create"},
        {"kind": "associate", "entry": 1, "target": {"vendor_machine_id": 307}}),
}


def source_path(module):
    return Path(f"docs/design/{module}-witnesses-v{VERSIONS[module]}.json")


def begin(module):
    return f"<!-- atlas-info: {module}-v{VERSIONS[module]} -->"


def matches_case(trace, predicates):
    steps = trace.get("steps")
    return type(steps) is list and all(any(
        type(step) is dict and type(step.get("event")) is dict
        and all(step["event"].get(k) == v for k, v in predicate.items())
        for step in steps) for predicate in predicates)


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
        elif kind == "oneof":
            for candidate in arg:
                try:
                    shape(value, candidate, at)
                    break
                except Invalid:
                    pass
            else:
                raise Invalid("ATLAS INPUT", at, "unsupported value shape")
        elif kind == "members":
            require(type(value) is dict and value.keys() <= arg.keys(),
                    "ATLAS INPUT", at, "unsupported members")
            for key, child in value.items():
                shape(child, arg[key], at + "." + key)
        elif kind == "nonempty":
            shape(value, [arg], at)
            require(bool(value), "ATLAS INPUT", at, "expected nonempty array")
        elif kind == "event":
            event_shape(value, at, arg)
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
    "dispatched": [int], "dispositions": [{"calls": [int], "continuation": enum(
        "destructive_reinstall", "abandonment", "as_if_done", "as_if_not_done"),
        "resource": RESOURCE, "valid": bool}], "durable": bool,
    "contact_mappings": [{"target": TARGET, "vendor": int}],
    "deleted_machines": [int], "waiting_connections": [{"call": int, "connection": optional(int)}],
    "identity_exclusions": [{"entry": int, "records": [int]}],
    "prerequisite_records": [], "quarantined": [{"entry": int, "vendor": optional(int)}],
    "reboot_results": [{"call": int, "observed_boot": int, "record_boot": int, "resource": RESOURCE}],
    "receipts": [RECEIPT], "reinstall_approvals": [], "reinstall_withdrawals": [],
    "reset_offer": [int], "standing": [{"calls": [int], "continuation": enum(
        "destructive_reinstall", "abandonment", "as_if_done", "as_if_not_done"), "resource": RESOURCE}],
    "unresolved": [{"calls": [int], "resource": RESOURCE}],
}
ASSUMPTIONS = dict.fromkeys((
    "approvalResetRequiresRescue", "approvedReinstallBoundary", "commandHold", "destructiveStops",
    "dispositionBindsContinuation", "dispositionOwnResource", "durableBeforeApply", "endedBelowSucceeded",
    "failedPrerequisiteWithdraws", "identityExclusion", "newestActivationRead", "orderAssociation",
    "rebootBootChange", "reinstallWithdrawalEffective", "resetIntoRescueOnly",
    "resetOfferCurrentInstallation", "resetOfferFreshKeys", "sessionDestroyRefused", "deletionContact", "pendingCleared"), bool)
ASSUMPTIONS.update(lapse=enum("continuation", "any_intent", "first_operation"),
                   reach=enum("disposed", "resource", "every_dispatch", "still_unresolved"),
                   resourceKey=enum("entry", "index", "call"))
EVENTS = {
    "request": {"appended": bool, "approved": APPROVAL, "call": int, "facts": int,
                "operation": OPERATION, "session": int, "target": TARGET,
                "read_route": optional(enum("machine", "vendor_evidence")), "connection": optional(int)},
    "read": {"appended": bool, "operation": OPERATION,
             "reports": enum("unknown", "ended", "succeeded"), "resource": RESOURCE,
             "source": enum("adapter_read", "pin_checked_handshake", "job_record", "notify_event", "model_text")},
    "receive": {"appended": bool, "receipt": RECEIPT},
    "dispose": {"appended": bool, "calls": [int], "continuation": enum(
        "destructive_reinstall", "abandonment", "as_if_done", "as_if_not_done"), "resource": RESOURCE},
    "replay": {},
    "collect_reboot": {"appended": bool, "call": int, "observed_boot": int,
                       "record_boot": optional(int), "resource": RESOURCE},
    "associate": {"entry": int, "target": TARGET},
    "associate_evidence": {"appended": bool, "entry": int, "vendor": optional(int), "withheld": bool},
}


# Closed presentation shapes, discovered from the committed schemas. These do not
# calculate protocol outcomes or require an outcome to be a particular value.
CONTINUATION = enum("destructive_reinstall", "abandonment", "as_if_done", "as_if_not_done")
FAMILY = enum("machines", "passes", "handoffs")
IDENTITY = {"derivation_version": int, "family": FAMILY, "index": int, "seed": int}
JOURNAL = {"derivation_version": int, "entries": [dict(IDENTITY, status=enum("reserved", "created", "failed", "destroyed"))],
           "next_unused": dict.fromkeys(("machines", "passes", "handoffs"), int),
           "restored_from_import": bool, "seed": int, "seed_backup": enum("none", "full_reentry", "skipped"),
           "sequence": int, "create_intents": [IDENTITY],
           "failures": [{"identity": IDENTITY, "checked_sequence": int}],
           "mappings": [{"identity": IDENTITY, "entry": int, "predecessor": optional(IDENTITY), "machine": optional(int)}]}
APPEND = {"durable": bool, "provenance": str}
ALLOCATION_EVENTS = {
    "allocate": {"family": FAMILY},
    **dict.fromkeys(("created", "destroyed"), {"identity": IDENTITY}),
    "failed": {"identity": IDENTITY, "checked_sequence": int, "append": APPEND},
    **dict.fromkeys(("export_sheet", "restore", "replace"), {}),
    "seed_backup": {"append": APPEND, "completion": enum("full_reentry", "skipped")},
}
PIN_SOURCE = enum("rescue_last", "ready_to_reset", "attest", "published", "model_text")
SYSTEM = enum("installed", "rescue")
HALT = enum("no_pin", "mismatch", "confirms_reset")
# Only the selected installed publication pin shapes; unused rescue/attest
# knowledge must remain empty. Bound alphabet events retain their own shapes.
PIN = {"entry": int, "installation": int, "keys": [int], "per": enum("machine"), "source": enum("published")}
PIN_KNOWLEDGE = {
    "awaiting": [], "boot": [{"entry": int, "boot": int}], "confirmed": [],
    "consumed_introductions": [], "current_installations": [{"entry": int, "installation": int}],
    "halts": [{"entry": int, "presented": int, "reason": HALT, "system": SYSTEM}],
    "pending_reinstall": [int], "pins": [PIN], "planted_senders": [{"entry": int, "sender": int}],
    "publication_groups": [{"entry": int, "installation": int, "observations": [[int]]}],
    "sessions": [{"boot": int, "entry": int, "installation": int, "pin": PIN, "presented": int, "system": SYSTEM}],
    "snapshot": [{"entry": int, "keys": optional([int])}],
}
PIN_EVENTS = {
    "published": {"entry": int, "keys": [int], "per": enum("machine"), "source": PIN_SOURCE},
    "reinstall": {"entry": int}, "restart": {},
    "connect": {"entry": int, "presents": int, "system": SYSTEM},
    "reset": {"entry": int, "into": SYSTEM},
    "rescue_last": {"entry": int, "keys": optional([int]), "source": PIN_SOURCE},
    "ready_to_reset": {"entry": int, "keys": [int], "source": PIN_SOURCE},
    "attest": {"append": APPEND, "author": int, "entry": int, "keys": [int],
               "per": enum("machine"), "source": PIN_SOURCE},
    "claim": {"entry": int, "keys": [int], "per": enum("machine"), "source": PIN_SOURCE},
}
FIELDS = ("version", "listeners.inbound", "listeners.outbound", "services", "key_material.spendable",
          "key_material.permitted", "drift_checks", "required", "default_credentials")
VERDICT = enum("refused", "blocked", "finding", "pass")
FIELD_VALUES = {field: [int] for field in FIELDS}
FIELD_VALUES.update({"version": int, "key_material.spendable": bool,
                     "default_credentials": ("oneof", (enum("none"), [int]))})
PRESENCE = {field: ("oneof", (enum("unspecified"), value)) for field, value in FIELD_VALUES.items()}
DECLARATION = ("members", PRESENCE)  # Absent fields are represented by absent members.
MACHINE = {"multi_tenant": bool, "observed": dict.fromkeys(FIELDS, [int])}
RECORD = {"delivered": bool, "verdicts": ("members", dict.fromkeys(FIELDS, VERDICT))}
DECLARATION_EVENTS = {"check": {"field": enum(*FIELDS)}, "deliver": {}}
EVENT_SHAPES = {"dispatch": EVENTS, "allocation": ALLOCATION_EVENTS,
                "pins": PIN_EVENTS, "declaration": DECLARATION_EVENTS}
STATE_SHAPES = {"dispatch": KNOWLEDGE, "allocation": JOURNAL, "pins": PIN_KNOWLEDGE, "declaration": RECORD}
START_SHAPES = dict(STATE_SHAPES, declaration={"declaration": DECLARATION, "machine": MACHINE, "record": RECORD})
ASSUMPTION_SHAPES = {
    "dispatch": ASSUMPTIONS,
    "allocation": dict.fromkeys(("backupRecorded", "restoredAllocatesNone", "unsentFailure", "failureDurable", "senderFence"), bool),
    "pins": {**dict.fromkeys(("sourceAdmitsPin", "attestAuthorMatches", "attestSingleUse", "attestDurable",
                             "attestFirstContact", "publishedComplete", "publishedFresh", "publishedWithin",
                             "reinstallRetiresPin", "installedFirstContact", "readyAfterReinstallFresh"), bool),
             **dict.fromkeys(("journalAppend", "publication", "sealAuthor", "senderAssociation", "window"), str)},
    "declaration": {"emptyMeansPerField": bool},
}
BOUND_SHAPES = {
    "allocation": {"declaration": str, "events": int, "alphabet": [("event", "allocation")]},
    "dispatch": {"declaration": str, "events": int, "alphabet": [("event", "dispatch")], "start": KNOWLEDGE},
    "pins": {"declaration": str, "events": int, "alphabet": [("event", "pins")], "start": PIN_KNOWLEDGE},
    "declaration": {"declaration": str, "base": {"declaration": DECLARATION, "machine": MACHINE},
                    "observations": ("nonempty", [int]), "tenancies": ("nonempty", bool),
                    "presences": {field: ("nonempty", ("oneof", (enum("missing"), presence)))
                                  for field, presence in PRESENCE.items()}},
}

def event_shape(event, at, module="dispatch"):
    require(type(event) is dict and type(event.get("kind")) is str and event["kind"] in EVENT_SHAPES[module],
            "ATLAS INPUT", at, "unsupported event kind")
    spec = EVENT_SHAPES[module][event["kind"]]
    if module == "pins" and event["kind"] in ("published", "claim", "attest") and event.get("per") == "boot":
        spec = dict(spec, per=enum("boot"), boot=int)
    shape(event, dict(spec, kind=str, provenance=str), at)


def trace_shape(trace, at, module="dispatch"):
    expected = {"declarations", "assumptions", "start", "steps"}
    require(type(trace) is dict and set(trace) in (expected, expected | {"pair"}),
            "ATLAS INPUT", at, "unsupported trace members")
    shape(trace["declarations"], [str], at + ".declarations")
    require(bool(trace["declarations"]) and len(set(trace["declarations"])) == len(trace["declarations"]),
            "ATLAS SELECTION", at, "empty or repeated declarations")
    shape(trace["assumptions"], ASSUMPTION_SHAPES[module], at + ".assumptions")
    shape(trace["start"], START_SHAPES[module], at + ".start")
    require(type(trace["steps"]) is list and bool(trace["steps"]), "ATLAS INPUT", at + ".steps", "expected nonempty array")
    if "pair" in trace:
        try:
            shape(trace["pair"], {"side": enum("refused", "admitted"), "with": str}, at + ".pair")
        except Invalid as exc:
            raise Invalid("ATLAS PAIRS", at + ".pair", str(exc)) from exc
    for i, step in enumerate(trace["steps"], 1):
        loc = f"{at}.steps[{i}]"
        projection = PROJECTIONS[module]
        require(type(step) is dict and "event" in step and projection in step,
                "ATLAS INPUT", loc, "missing event/projection")
        event_shape(step["event"], loc + ".event", module)
        shape(step[projection], STATE_SHAPES[module], loc + "." + projection)
        kind = step["event"]["kind"]
        outcomes = {}
        if module == "dispatch":
            if kind == "request":
                shape(step.get("dispatch"), enum("dispatched", "refused"), loc + ".dispatch")
                outcomes["dispatch"] = str
                if step["dispatch"] == "refused":
                    reason = step.get("refusal", {}).get("reason") if type(step.get("refusal")) is dict else None
                    refusals = {
                        "facts": {"reason": enum("facts")},
                        "barrier": {"reason": enum("barrier"), "calls": [int]},
                        "continuation": {"reason": enum("continuation"), "in_force": CONTINUATION},
                        "identity_exclusion": {"reason": enum("identity_exclusion"), "records": [int]},
                    }
                    require(type(reason) is str and reason in refusals,
                            "ATLAS INPUT", loc + ".refusal", "unsupported refusal")
                    outcomes["refusal"] = refusals[reason]
            elif kind in ("read", "receive", "collect_reboot"):
                outcomes["settled"] = [int]
            elif kind == "dispose":
                outcomes["disposition"] = enum("recorded", "refused", "not_appended")
        elif module == "allocation":
            if kind == "allocate":
                shape(step.get("allocation"), enum("admitted", "refused"), loc + ".allocation")
                outcomes["allocation"] = str
                if step["allocation"] == "admitted":
                    outcomes["identity"] = IDENTITY
            elif kind == "seed_backup":
                outcomes["recorded"] = bool
        elif module == "pins":
            # Selected traces only; other event kinds are supported in bound.alphabet.
            require(kind in ("published", "reinstall", "restart", "connect"),
                    "ATLAS INPUT", loc, "unsupported selected pins step")
            if kind == "published":
                outcomes["pinned"] = bool
            elif kind == "reinstall":
                outcomes["pending"] = bool
            elif kind == "restart":
                outcomes["replayed"] = bool
            else:
                shape(step.get("check"), enum("admitted", "halted"), loc + ".check")
                outcomes["check"] = str
                if step["check"] == "halted":
                    outcomes["halt"] = HALT
        elif module == "declaration":
            outcomes = {"verdict": VERDICT} if kind == "check" else {"delivered": bool}
        shape(step, dict(outcomes, event=("event", module),
                         **{projection: STATE_SHAPES[module]}), loc)


def declarations(path):
    try:
        rows = [json.loads(line, object_pairs_hook=no_duplicates) for line in path.read_text().splitlines() if line.strip()]
        require(all(type(row) is dict and type(row.get("decl")) is str for row in rows),
                "ATLAS DECLARATIONS", path, "malformed formal index")
        return {row["decl"] for row in rows}
    except (OSError, ValueError) as exc:
        raise Invalid("ATLAS DECLARATIONS", path, f"formal index required: {exc}") from exc


def project(source, names, selection=None, module="dispatch"):
    path = source_path(module)
    namespace = "TauWeb." + module.title()
    require(type(source) is dict, "ATLAS INPUT", path, "expected object")
    require(type(source.get("schema")) is int and source["schema"] == VERSIONS[module]
            and source.get("module") == module and source.get("namespace") == namespace,
            "ATLAS HEADER", path, f"requires schema {VERSIONS[module]}, module {module}, namespace {namespace}")
    require(set(source) == {"schema", "module", "namespace", "bound", "witnesses", "enumeration"}
            and type(source["witnesses"]) is list and type(source["enumeration"]) is list,
            "ATLAS INPUT", path, "unsupported file structure")
    bound = source["bound"]
    shape(bound, BOUND_SHAPES[module], "bound")
    require(bound["declaration"] == namespace + ".bound", "ATLAS DECLARATIONS", path, "unexpected bound declaration")
    if module != "declaration":
        require(bool(bound["alphabet"]), "ATLAS INPUT", "bound.alphabet", "expected nonempty array")
        for i, event in enumerate(bound["alphabet"]):
            event_shape(event, f"bound.alphabet[{i}]", module)
    selection = SELECTIONS[module] if selection is None else selection
    require(len(set(selection)) == len(selection), "ATLAS SELECTION", path, "duplicate selection")
    selected = []
    for name in selection:
        decl = namespace + "." + name
        candidates = [w for w in source["witnesses"] if type(w) is dict
                      and type(w.get("declarations")) is list and decl in w["declarations"]]
        discriminator = CASES.get((module, name))
        if discriminator is not None:
            candidates = [w for w in candidates if matches_case(w, discriminator)]
        require(len(candidates) == 1, "ATLAS SELECTION", decl, f"expected one selected witness, found {len(candidates)}")
        trace = candidates[0]
        trace_shape(trace, decl, module)
        require(not any(trace is old for old in selected), "ATLAS SELECTION", decl, "trace selected twice")
        selected.append(trace)
    refs = [bound["declaration"]]
    for trace in selected:
        refs.extend(trace["declarations"])
        if "pair" in trace:
            refs.append(trace["pair"]["with"])
    for ref in refs:
        require(ref.startswith(namespace + ".") and ref in names,
                "ATLAS DECLARATIONS", ref, "not in current module/formal index")
    # The source corpus reuses declaration names. Selection above establishes a
    # unique case; pair lookup here must not collapse distinct cases by name.
    for left, right in PAIR_NAMES[module]:
        for name, partner, side in ((left, right, "refused"), (right, left, "admitted")):
            decl = namespace + "." + name
            found = [w for w in selected if decl in w["declarations"]]
            require(len(found) == 1 and found[0].get("pair") == {"side": side, "with": namespace + "." + partner},
                    "ATLAS PAIRS", decl, "required pair metadata/partner missing or changed")
    for trace in selected:
        if "pair" in trace:
            pair = trace["pair"]
            partners = [w for w in selected if pair["with"] in w["declarations"]
                        and w.get("pair", {}).get("with") in trace["declarations"]
                        and w["pair"]["side"] != pair["side"]]
            require(len(partners) == 1, "ATLAS PAIRS", trace["declarations"][0], "selected pair must be reciprocal and whole")
    projection = {k: source[k] for k in ("schema", "module", "namespace", "bound")}
    projection["witnesses"] = selected
    require(not re.search(r"\bCNF-\d+", json.dumps(projection)), "ATLAS INPUT", path, "conformance identifier in projection")
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
    module = projection["module"]
    state = PROJECTIONS[module]
    path = source_path(module)
    out = [f"Evidence: generated witness projection; {module} source header and complete bound context.",
           "Applicability: " + APPLICABILITY[module],
           "External possibilities: not recorded here. Permitted next actions: consult the owning rules; no source outcome supplies extra authority.",
           "Bound: finite source context only, neither completeness nor implementation evidence. Named traces are not claims about the enumeration.",
           "", "| Source header and bound context (complete) |", "|---|",
           "| " + cell({"source": str(path), **{k: v for k, v in projection.items() if k != "witnesses"}}) + " |", ""]
    for name, trace in zip(SELECTIONS[module], projection["witnesses"]):
        scope = SCOPES[name] + f" View: {name}."
        bound_note = ("Declaration field/presence/observation/tenancy sweep, not an event-count bound."
                      if module == "declaration" else
                      ("Named trace outside event-count bound." if len(trace["steps"]) > projection["bound"]["events"]
                       else "Named trace; bound alphabet membership and exhaustive coverage are not implied."))
        out += ["### " + name.replace("_", " "), "",
                f"Evidence: generated witness projection — {name}.",
                "Applicability: " + scope + " " + APPLICABILITY[module],
                bound_note, "",
                "| Source metadata | Value |", "|---|---|",
                "| Selection provenance | " + cell({"source": str(path), "declaration": projection["namespace"] + "." + name,
                                                      "case": CASES.get((module, name)),
                                                      "order": "curated across traces; source order within each trace"}) + " |",
                "| Declarations, assumptions, pair (when present) | " + cell({k: v for k, v in trace.items() if k not in ("start", "steps")}) + " |",
                "| Starting projection (complete) | " + cell(trace["start"]) + " |", "",
                f"Evidence: generated witness projection — {name} steps.",
                "Applicability: " + scope + " Source steps. " + APPLICABILITY[module],
                "External possibilities: unknown beyond recorded observations. Permitted next actions: the owner matrix still applies; no checked composition with another trace.", "",
                f"| Step | Source event | Source outcome members (empty means none) | Source {state} after step (complete) |",
                "|---|---|---|---|"]
        for i, step in enumerate(trace["steps"], 1):
            outcome = {k: v for k, v in step.items() if k not in ("event", state)}
            out.append(f"| {i} | {cell(step['event'])} | {cell(outcome)} | {cell(step[state])} |")
        out.append("")
    return "\n".join(out)


def validate_regions(document):
    # Parse all marker-like lines, including unknown/malformed/nested regions.
    # Validate before rendering or mutating any region.
    expected = {begin(module) for module in VERSIONS}
    seen = set()
    active = None
    for line in document.splitlines():
        if not re.search(r"<[^\n]*atlas-info", line):
            continue
        if line in expected:
            require(active is None and line not in seen, "ATLAS REGIONS", ATLAS, "nested or duplicate informational region")
            active = line
            seen.add(line)
        elif line == END:
            require(active is not None, "ATLAS REGIONS", ATLAS, "unmatched informational end marker")
            active = None
        else:
            raise Invalid("ATLAS REGIONS", ATLAS, "unknown or malformed informational marker")
    require(active is None and seen == expected, "ATLAS REGIONS", ATLAS, "missing informational marker pair")


def replace_region(document, rendered, check=True, module="dispatch"):
    marker = begin(module)
    start = document.index(marker) + len(marker)
    end = document.index(END, start)
    old = document[start:end]
    if check:
        for line in rendered.splitlines():
            if line.startswith(("Evidence:", "Applicability:")):
                require(old.splitlines().count(line) == 1, "ATLAS LABELS", ATLAS, f"missing/changed local label: {line}")
    return document[:start] + "\n" + rendered + document[end:]


def write_document(path, document):
    # All inputs/regions are validated first. Replace the document atomically so
    # a later invalid module or interrupted write cannot leave partial regions.
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, prefix=".atlas-", delete=False) as out:
        temporary = Path(out.name)
        try:
            out.write(document)
            out.flush()
            os.fchmod(out.fileno(), path.stat().st_mode & 0o777)
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--write", action="store_true", help="regenerate informational region, preserving prose")
    mode.add_argument("--check", action="store_true", help="check for drift (default)")
    parser.add_argument("--root", type=Path, default=ROOT, help="tree containing source, atlas and current formal index")
    args = parser.parse_args(argv)
    try:
        names = declarations(args.root / INDEX)
        projections = [project(read_json(args.root / source_path(module)), names, module=module)
                       for module in VERSIONS]
        path = args.root / ATLAS
        document = path.read_text()
        validate_regions(document)
        expected = document
        for projection in projections:
            expected = replace_region(expected, render(projection), check=not args.write, module=projection["module"])
        if args.write:
            write_document(path, expected)
        else:
            require(document == expected, "ATLAS DRIFT", ATLAS,
                    "informational projection differs from selected sources; regenerate with --write: "
                    + ", ".join(str(source_path(module)) for module in VERSIONS))
        print(f"atlas: {sum(len(p['witnesses']) for p in projections)} selected witnesses, "
              f"{sum(len(w['steps']) for p in projections for w in p['witnesses'])} source steps; presentation evidence only")
        print("ATLAS DRIFT: none")
        return 0
    except (Invalid, OSError) as exc:
        label = exc.label if isinstance(exc, Invalid) else "ATLAS INPUT"
        # One physical finding line even for adversarial labels or parser errors.
        print(f"{label}: {str(exc)!r}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
