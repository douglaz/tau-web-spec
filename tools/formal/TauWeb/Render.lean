import TauWeb.Declaration
import TauWeb.Allocation
/-! The marked regions (ADR-0032): what the lines between `<!-- formal: <decl> -->` and
`<!-- /formal -->` in a document must contain, computed from the declaration named. `lake exe
render` prints them and `tools/check_regions.py` holds each document to them.

Both regions here are `match` regions — tables whose cells carry prose and conformance
citations the companion does not emit and never may (ADR-0032, "What it never carries", which
is path-independent). The gate keeps only the tokens these declarations determine and diffs
those, so a cell's rationale stays the document's, where the citation gates read it, and its
outcome does not. A `render` region, compared line for line, has no instance yet; `Kind` carries
the constructor so the first one needs no new vocabulary.

The first column of each table is the row's key. The body rows are emitted; the header is never
compared, so a column's title stays the document's.

What a token can and cannot hold is the gate's docstring. Here: every token is computed from the
declaration's own constructors, never from a second table keyed by name, so a field or role
whose meaning moves in Lean moves the emitted token with it. -/

namespace TauWeb.Render

/-- `render` is pure computation, compared line for line; `match` keeps only the tokens the
declaration determines. An inductive, so the emitter cannot mint a third. -/
inductive Kind
  | render
  | «match»
  deriving DecidableEq, Repr

def Kind.name : Kind → String
  | .render => "render"
  | .«match» => "match"

/-- One marked region: the declaration it renders, its kind, and its text. -/
structure Region where
  decl : String
  kind : Kind
  text : String

/-! ## `ARC-39`'s field table -/

open TauWeb.Declaration in
/-- A field's shape and, for a list, which reading of `[]` its row takes — the one column of
`delivery-declaration-v1.md`'s table this declaration decides. Exhaustive over `Shape`: a new
shape without a token is a red build. -/
def shapeToken (f : Field) : String :=
  match (row f).shape with
  | .number => "**number**"
  | .flag => "**flag**"
  | .list .nothingMay => "**nothing may**"
  | .list .nothingToCheck => "**none is declared**"
  | .listOnReentry => "**on re-entry**"

open TauWeb.Declaration in
/-- One row: the field name as the key, the two prose columns left to the document, the shape. -/
def declarationRow (f : Field) : String :=
  s!"| `{(row f).name}` | | | {shapeToken f} |"

open TauWeb.Declaration in
/-- The field table of `delivery-declaration-v1.md`, body rows only, in `fields`' order. -/
@[req "ARC-39"] def declarationTable : Region :=
  { decl := "TauWeb.Render.declarationTable", kind := .«match»,
    text := "\n".intercalate (fields.map declarationRow) }

/-! ## `STA-22a`'s role table -/

open TauWeb.Allocation in
def familyToken : Family → String
  | .machine => "**machine**"
  | .pass => "**pass**"
  | .handoff => "**handoff**"

open TauWeb.Allocation in
def credentialToken : Credential → String
  | .sshClient => "**SSH client**"
  | .attestSender => "**Attest sender**"
  | .attestRecipient => "**Attest recipient**"
  | .relay => "**Relay**"
  | .postHarness => "**Post-harness credential**"

open TauWeb.Allocation in
def secretToken : Secret → String
  | .ed25519Seed => "**Ed25519 seed**"
  | .secp256k1 => "**secp256k1**"

open TauWeb.Allocation in
/-- One row: the role number as the key, then the three columns `TauWeb.Allocation.row` carries.
The public-key encoding shares the last cell as prose and stays the document's. -/
def roleRow (n : Nat) : Option String :=
  (row n).map fun r =>
    s!"| `{n}` | {familyToken r.family} | {credentialToken r.credential} | {secretToken r.secret} |"

open TauWeb.Allocation in
/-- The role table of `credential-format-v1.md`, body rows only. `count` is the table's length
and `TauWeb.Allocation.total` decides that every role below it has a row. -/
@[req "STA-22a"] def roleTable : Region :=
  { decl := "TauWeb.Render.roleTable", kind := .«match»,
    text := "\n".intercalate ((List.range count).filterMap roleRow) }

/-- Every region a document may carry. One the documents do not render is a red gate. -/
def regions : List Region := [declarationTable, roleTable]

end TauWeb.Render
