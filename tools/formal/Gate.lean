import Lean
import TauWeb
/-! `lake exe gate` — the formal companion's own gate (ADR-0032, "Trust policy, enforced by
the gate").

For every declaration tagged `@[req "..."]` it collects the axioms the proof depends on and
refuses anything outside `propext`, `Classical.choice`, `Quot.sound`: that refuses `sorryAx`
transitively, any project `axiom`, and the per-declaration axiom `native_decide` mints in Lean
4.30.0. For every other project constant it refuses a declared `axiom` anywhere and the
`native_decide` axiom by its shape outside `TauWeb.Explore`, the one namespace that may hold
untagged scratch; nothing tagged may sit there. It refuses an empty index, because a gate over
nothing is not a gate, and prints the requirement index — one JSON object per tagged
declaration — for the documents' gates.

Exit 0 = every tagged declaration is within policy. -/

open Lean

def allowed : List Name := [``propext, ``Classical.choice, ``Quot.sound]

def axiomsOf (env : Environment) (n : Name) : IO (Array Name) := do
  let ctx : Core.Context := { fileName := "<gate>", fileMap := default }
  let (axioms, _) ← (collectAxioms n : CoreM (Array Name)).toIO ctx { env := env }
  pure axioms

/-- Lean 4.30.0 names the axiom it mints for `native_decide` `<decl>._native.native_decide.ax_…`. -/
def isNativeDecideAxiom (a : Name) : Bool :=
  match a with
  | .str (.str (.str _ "_native") "native_decide") ax => ax.startsWith "ax_"
  | _ => false

/-- A constant is the project's when the module declaring it is `TauWeb` or under it. -/
def inProject (env : Environment) (n : Name) : Bool :=
  match env.getModuleIdxFor? n with
  | some idx => (`TauWeb).isPrefixOf env.header.moduleNames[idx.toNat]!
  | none => false

unsafe def main : IO UInt32 := do
  enableInitializersExecution
  -- `lake exe` sets no LEAN_PATH for the program it runs; run from `tools/formal`.
  initSearchPath (← findSysroot) [".lake/build/lib/lean"]
  withImportModules #[{ module := `TauWeb }] {} (trustLevel := 0) fun env => do
    let mut found : Array (Name × String) := #[]
    let mut failures := 0
    for (n, info) in env.constants.toList do
      if let some req := TauWeb.reqAttr.getParam? env n then
        found := found.push (n, req)
        if (`TauWeb.Explore).isPrefixOf n then
          IO.eprintln s!"FAIL  {n} is tagged @[req \"{req}\"] inside TauWeb.Explore"
          failures := failures + 1
      if inProject env n then
        let inExplore := (`TauWeb.Explore).isPrefixOf n
        -- The axiom `native_decide` mints is a project constant under the declaring name, so
        -- inside Explore it is the one axiom admitted; anywhere else it is refused twice over.
        if (match info with | .axiomInfo _ => true | _ => false) && !(inExplore && isNativeDecideAxiom n) then
          IO.eprintln s!"FAIL  {n} is an axiom; the project declares none"
          failures := failures + 1
        if !inExplore then
          let ax ← axiomsOf env n
          if ax.any isNativeDecideAxiom then
            IO.eprintln s!"FAIL  {n} uses native_decide outside TauWeb.Explore"
            failures := failures + 1
    let tagged := found.qsort (fun a b => a.1.toString < b.1.toString)
    if tagged.isEmpty then
      IO.eprintln "FAIL: no @[req] declarations found; a gate over nothing is not a gate"
      return 1
    for (n, req) in tagged do
      let axioms ← axiomsOf env n
      let bad := axioms.filter (fun a => !(allowed.contains a))
      let kind := if (env.find? n).any (·.isTheorem) then "theorem" else "def"
      let row := Json.mkObj [
        ("req", req), ("decl", n.toString), ("kind", kind),
        ("axioms", Json.arr (axioms.map (Json.str ·.toString))) ]
      IO.println row.compress
      if !bad.isEmpty then
        failures := failures + 1
        IO.eprintln s!"FAIL  {n} ({req}) depends on {bad.toList}"
    IO.eprintln s!"{tagged.size} tagged declarations, {failures} outside the axiom policy"
    return (if failures == 0 then 0 else 1)
