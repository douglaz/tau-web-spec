import Lean
import TauWeb
/-! `lake exe render` — prints `TauWeb.Render.regions`, one JSON object per marked region, for
`tools/check_regions.py` (ADR-0032). -/

open Lean

def main : IO UInt32 := do
  for r in TauWeb.Render.regions do
    IO.println (Json.mkObj [("decl", r.decl), ("kind", r.kind.name), ("text", r.text)]).compress
  return 0
