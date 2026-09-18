import Lean
import TauWeb
/-! `lake exe witnesses DIR` — the witness files (ADR-0032, "How the implementation is
compared"), one JSON file per module under `DIR`; `tools/check_witnesses.py` holds the
committed copy under `docs/design/` equal to it. The schema is `docs/design/witness-file-v1.md`.

Every trace is run through the module's own `step`, and each step's outcome is read off the
world the step returned; the file's bound is the module's `bound` declaration, rendered. The
emitter refuses a module whose tagged witnesses it did not reach: a witness is a tagged theorem
in the module's namespace whose statement binds no variable — a decided proposition about a
concrete trace — and every one must be named by a trace here, every name here must be one, and
every other declaration the file names must be tagged. No hand-kept list survives a renamed
theorem either way.

ponytail: the tie between a trace and its theorem is by name, and the events they share are
the module's named `*Events` definitions; a trace-level tie (evaluating the constant the
theorem's statement names) when a witness is ever found to have drifted from its theorem. -/

open Lean

namespace TauWeb.Witnesses

open TauWeb.Allocation

/-! ## Allocation, in `STA-22b`'s vocabulary -/

def familyName : Family → String
  | .machine => "machines"
  | .pass => "passes"
  | .handoff => "handoffs"

def statusName : Status → String
  | .reserved => "reserved"
  | .created => "created"
  | .failed => "failed"
  | .destroyed => "destroyed"

/-- `seed` is the ordinal of the seed in the trace — 0 the initial one, each Replace the next —
never a seed identifier or key material. -/
def identityFields (i : Identity) : List (String × Json) :=
  [("seed", toJson i.epoch), ("derivation_version", toJson i.version),
   ("family", toJson (familyName i.family)), ("index", toJson i.index)]

/-- The projection of harness knowledge: the journal as `STA-22b` names its parts, entries
oldest first. Nothing of the companion's `World` beyond the journal. -/
def journalJson (j : Journal) : Json :=
  Json.mkObj [
    ("seed", toJson j.epoch), ("derivation_version", toJson j.version),
    ("next_unused", Json.mkObj [("machines", toJson j.next.machine),
                                ("passes", toJson j.next.pass),
                                ("handoffs", toJson j.next.handoff)]),
    ("entries", Json.arr (j.entries.reverse.map fun e =>
      Json.mkObj (identityFields e.id ++ [("status", toJson (statusName e.status))])).toArray),
    ("restored_from_import", toJson j.restored) ]

def observed (kind : String) (i : Identity) : Json :=
  Json.mkObj [("kind", kind), ("provenance", "adapter observation"),
              ("identity", Json.mkObj (identityFields i))]

def eventJson : Event → Json
  | .allocate f => Json.mkObj [("kind", "allocate"), ("provenance", "model request"),
                               ("family", toJson (familyName f))]
  | .created i => observed "created" i
  | .failed i => observed "failed" i
  | .destroy i => observed "destroyed" i
  | .exportSheet => Json.mkObj [("kind", "export_sheet"), ("provenance", "operator act")]
  | .restore => Json.mkObj [("kind", "restore"), ("provenance", "import or restore")]
  | .replace => Json.mkObj [("kind", "replace"), ("provenance", "operator act")]

/-- One step: the event, whether an allocation was admitted and at which identity — read off
what the step issued — and the journal after. -/
def stepJson (p : Params) (w : World) (e : Event) : Json × World :=
  let w' := step p w e
  let outcome := match e, w'.issued with
    | .allocate _, i :: rest =>
      if rest == w.issued then
        [("allocation", "admitted"), ("identity", Json.mkObj (identityFields i))]
      else [("allocation", "refused")]
    | .allocate _, [] => [("allocation", "refused")]
    | _, _ => []
  (Json.mkObj ([("event", eventJson e)] ++ outcome ++ [("journal", journalJson w'.journal)]), w')

inductive Side
  | refused
  | admitted

def Side.name : Side → String
  | .refused => "refused"
  | .admitted => "admitted"

structure Trace where
  decls : List String
  events : List Event
  params : Params := current
  start : World := init
  /-- A refused-and-admitted pair: this side, and the declaration of the other. -/
  pair : Option (Side × String) := none

def Trace.json (t : Trace) : Json :=
  let steps := (t.events.foldl
    (fun (acc, w) e => let (j, w') := stepJson t.params w e; (acc.push j, w'))
    (#[], t.start)).1
  Json.mkObj <|
    [("declarations", toJson t.decls),
     ("assumptions", Json.mkObj [("restoredAllocatesNone", toJson t.params.restoredAllocatesNone)])] ++
    (match t.pair with
     | some (side, other) => [("pair", Json.mkObj [("side", side.name), ("with", other)])]
     | none => []) ++
    [("start", journalJson t.start.journal), ("steps", Json.arr steps)]

def noGuard : Params := { current with restoredAllocatesNone := false }

def allocationWitnesses : List Trace := [
  { decls := ["TauWeb.Allocation.stale_sheet_refused"], events := staleSheetEvents,
    pair := some (.refused, "TauWeb.Allocation.stale_sheet_admitted") },
  { decls := ["TauWeb.Allocation.stale_sheet_admitted"], events := staleSheetEvents,
    params := noGuard, pair := some (.admitted, "TauWeb.Allocation.stale_sheet_refused") },
  { decls := ["TauWeb.Allocation.replace_allocates_again"], events := replaceAgainEvents },
  { decls := ["TauWeb.Allocation.failed_create_keeps_index"], events := failedCreateEvents },
  { decls := ["TauWeb.Allocation.successful_trace"], events := successfulEvents },
  { decls := ["TauWeb.Allocation.exhaustion_refuses"], events := exhaustionEvents,
    start := exhaustionStart } ]

def allocationEnumeration : List Trace :=
  (tracesUpTo bound).map fun es => { decls := ["TauWeb.Allocation.bounded_nodup"], events := es }

/-- One module's file: its text, the witnesses its traces name, and the other declarations the
file names — the bound's, each pair's other side — which must be tagged. -/
structure Module where
  name : String
  ns : Name
  text : String
  named : List String
  refs : List String

/-- The header pretty, one trace per line: a diff names the trace that moved. -/
def fileText (name : String) (ns : Name) (bound : Json) (witnesses enumeration : List Trace) :
    String :=
  let lines (ts : List Trace) := String.intercalate ",\n" (ts.map fun t => "    " ++ t.json.compress)
  "{\n  \"schema\": 1,\n" ++
  s!"  \"module\": \"{name}\",\n  \"namespace\": \"{ns}\",\n  \"bound\": {bound.compress},\n" ++
  s!"  \"witnesses\": [\n{lines witnesses}\n  ],\n" ++
  s!"  \"enumeration\": [\n{lines enumeration}\n  ]\n}\n"

def allocationModule : Module :=
  let boundDecl := "TauWeb.Allocation.bound"
  let bound := Json.mkObj [("declaration", boundDecl), ("events", toJson bound),
                           ("alphabet", Json.arr (alphabet.map eventJson).toArray)]
  let traces := allocationWitnesses ++ allocationEnumeration
  { name := "allocation", ns := `TauWeb.Allocation,
    text := fileText "allocation" `TauWeb.Allocation bound allocationWitnesses allocationEnumeration,
    named := traces.flatMap (·.decls),
    refs := boundDecl :: traces.filterMap fun t => t.pair.map (·.2) }

def modules : List Module := [allocationModule]

/-- A statement that binds no variable: a decided proposition about a concrete trace, `let`s
and non-dependent arrows (`¬P`, `A → B`) included. -/
partial def bindsNothing : Expr → Bool
  | .forallE _ _ body _ => !body.hasLooseBVars && bindsNothing body
  | .letE _ _ _ body _ => bindsNothing body
  | .mdata _ e => bindsNothing e
  | _ => true

def tagged (env : Environment) (n : Name) : Bool := (TauWeb.reqAttr.getParam? env n).isSome

/-- The tagged theorems under `ns` whose statement binds nothing: the decided witnesses. -/
def taggedWitnesses (env : Environment) (ns : Name) : List Name :=
  env.constants.toList.filterMap fun (n, info) =>
    if ns.isPrefixOf n && tagged env n && info.isTheorem && bindsNothing info.type then some n
    else none

end TauWeb.Witnesses

open TauWeb.Witnesses in
unsafe def main (args : List String) : IO UInt32 := do
  let some dir := args.head? | IO.eprintln "usage: lake exe witnesses DIR"; return 2
  enableInitializersExecution
  initSearchPath (← findSysroot) [".lake/build/lib/lean"]
  withImportModules #[{ module := `TauWeb }] {} (trustLevel := 0) fun env => do
    let mut failures := 0
    for m in modules do
      let witnesses := (taggedWitnesses env m.ns).map (·.toString)
      for t in witnesses do
        if !m.named.contains t then
          IO.eprintln s!"FAIL  witness {t} is tagged but no trace in the emitter reaches it (module {m.name})"
          failures := failures + 1
      for n in m.named.eraseDups do
        if !witnesses.contains n then
          IO.eprintln s!"FAIL  {n} is named by a trace but is not a tagged witness under {m.ns} (module {m.name})"
          failures := failures + 1
      for n in m.refs.eraseDups do
        if !tagged env n.toName then
          IO.eprintln s!"FAIL  {n} is named by the file but is not a tagged declaration (module {m.name})"
          failures := failures + 1
      if failures == 0 then
        let path := System.FilePath.mk dir / s!"{m.name}-witnesses-v1.json"
        IO.FS.writeFile path m.text
        IO.println s!"witnesses: {m.name}: {m.named.eraseDups.length} witnesses reached -> {path}"
    return (if failures == 0 then 0 else 1)
