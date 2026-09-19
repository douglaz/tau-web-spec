import TauWeb.Req
/-! Module 2, declaration presence and meaning (ADR-0032's inventory): `ARC-39` and
`delivery-declaration-v1.md`.

Presence is one type for every field — `missing`, `unspecified`, `specified` — and meaning is
read per field from the table: only a specified value is evaluated, under its row's semantics.
The table is `row`, a function over the fields of version 1 whose totality the elaborator
decides: a field added to `Field` without its row is a missing case and a red build. What an
explicit empty list means is a column of that table, so "empty means nothing to check" cannot
be written for a field whose row says nothing may.

The delivery check is a trace: one `check` per field, which records the field's verdict, and
`deliver`, which is reached only when every field of the table has a recorded pass. The
theorems are over every trace, every declaration and every machine; the witnesses are the
declaration document's own declarations and the inventory's retained trap, decided.

`Params` lists the rule the 2026-09-16 fix made per field, a field so that removing it is a
one-token change; `empty_inbound_refused` and `empty_inbound_admitted` are its pair.

What the module omits: the values themselves. A declared listener, service, key, drift check,
required check or default credential is an opaque item, and what the machine shows for a
field is a list of the same items — the sockets answering, the services demonstrated, the
tenant material found, the checks that hold, the credentials changed — so that the finding is
the set difference the row names and nothing about ports, lifecycles or commands. `"none"`
for `default_credentials` is the empty list of what must have been changed. `drift_checks` is
"Run by the machine's own session on re-entry (`ARC-26`)", so at delivery a specified list
passes on presence alone. The lightweight pentest (`ARC-17`), the scanner (`ARC-26`) and the
profile's prose are not here. -/

namespace TauWeb.Declaration

/-- The fields of version 1, in the table's order. -/
@[req "ARC-39"] inductive Field
  | version
  | listenersInbound
  | listenersOutbound
  | services
  | keyMaterialSpendable
  | keyMaterialPermitted
  | driftChecks
  | required
  | defaultCredentials
  deriving DecidableEq, Repr

/-- Presence, one type for every field: "a field is *missing*, *unspecified*, or *specified
with a value*, and only the third is evaluated". -/
inductive Presence (α : Type)
  | missing
  | unspecified
  | specified (v : α)
  deriving DecidableEq, Repr

/-- What an explicit empty list means, "the field's own": for a field that declares what must
exist, "an empty list means *nothing may*, and anything found is a finding"; for a field that
declares a restriction or an obligation, "it means *none is declared* and there is nothing to
check". -/
inductive EmptyMeans
  | nothingMay
  | nothingToCheck
  deriving DecidableEq, Repr

/-- The shape of a field's value: the version number, the spendable flag, a list checked at
delivery with what its empty means, or a list the maintained re-check runs (`ARC-26`) and
delivery only requires present. -/
inductive Shape
  | number
  | flag
  | list (empty : EmptyMeans)
  | listOnReentry
  deriving DecidableEq, Repr

/-- One row of the table: the field's name as the document writes it and its shape. -/
structure Row where
  name : String
  shape : Shape
  deriving DecidableEq, Repr

/-- The field table of `delivery-declaration-v1.md`. No wildcard: a field without a row does
not build. -/
@[req "ARC-39"] def row : Field → Row
  | .version => ⟨"version", .number⟩
  | .listenersInbound => ⟨"listeners.inbound", .list .nothingMay⟩
  | .listenersOutbound => ⟨"listeners.outbound", .list .nothingToCheck⟩
  | .services => ⟨"services", .list .nothingToCheck⟩
  | .keyMaterialSpendable => ⟨"key_material.spendable", .flag⟩
  | .keyMaterialPermitted => ⟨"key_material.permitted", .list .nothingMay⟩
  | .driftChecks => ⟨"drift_checks", .listOnReentry⟩
  | .required => ⟨"required", .list .nothingToCheck⟩
  | .defaultCredentials => ⟨"default_credentials", .list .nothingToCheck⟩

/-- The fields in the table's order: what the check walks and what `deliver` requires. -/
def fields : List Field :=
  [.version, .listenersInbound, .listenersOutbound, .services, .keyMaterialSpendable,
   .keyMaterialPermitted, .driftChecks, .required, .defaultCredentials]

/-- Every field is in the walk: a field with a row but outside `fields` would have a meaning
the check never applies. -/
@[req "ARC-39"] theorem total : ∀ f, f ∈ fields := by intro f; cases f <;> decide

/-- A specified value. Items are opaque; a value of the wrong shape for its field is refused
like an absent one. -/
inductive Value
  | number (n : Nat)
  | flag (b : Bool)
  | list (items : List Nat)
  deriving DecidableEq, Repr

/-- A declaration: a presence for every field. Absent is `missing`, never a default — "The
harness invents no default for any field". -/
def Declaration := Field → Presence Value

/-- The machine as the check observes it: whether it is multi-tenant (`ARC-36`), and what it
shows for each field — for `key_material.spendable`, the spendable material found, so that an
empty list is none. -/
structure Machine where
  multiTenant : Bool
  observed : Field → List Nat

/-- A field's verdict. `refused` is the declaration's own fault — an absent field, a value of
the wrong shape, a version other than 1, spendable material declared on a multi-tenant
machine; `blocked` is `unspecified`, "the tenant has not said; **delivery is blocked**";
`finding` is "a difference from the declaration" (`ARC-39`). -/
inductive Verdict
  | refused
  | blocked
  | finding
  | pass
  deriving DecidableEq, Repr

/-- The rule the 2026-09-16 fix made: what an empty list means is the field's own. Without it,
"Until 2026-09-16 this bullet read 'nothing to check, delivery may pass' for every field".
One field, so that removing it is a one-token change. -/
@[req "ARC-39"] structure Params where
  emptyMeansPerField : Bool
  deriving DecidableEq, Repr

/-- The rule as it stands. -/
@[req "ARC-39"] def current : Params := { emptyMeansPerField := true }

/-- A list-shaped field: everything found must be declared where the row says nothing may;
everything declared must hold where it says nothing to check. Under the old rule an empty
declared list passes either way. -/
def listMeaning (p : Params) (e : EmptyMeans) (declared observed : List Nat) : Verdict :=
  if declared.isEmpty && !p.emptyMeansPerField then .pass
  else
    let ok := match e with
      | .nothingMay => observed.all declared.contains
      | .nothingToCheck => declared.all observed.contains
    if ok then .pass else .finding

/-- The meaning of a specified value, read from the field's row: `version` "Refuse any
other"; `key_material.spendable` "`false` on a multi-tenant machine (`ARC-37`, harness rule;
a profile cannot set `true` there)", and declared `false` it is "Searched for after install";
a list the maintained re-check runs passes on presence; every other list under `listMeaning`.
-/
@[req "ARC-39"] def meaning (p : Params) (m : Machine) (f : Field) (v : Value) : Verdict :=
  match (row f).shape, v with
  | .number, .number 1 => .pass
  | .flag, .flag true => if m.multiTenant then .refused else .pass
  | .flag, .flag false => if (m.observed f).isEmpty then .pass else .finding
  | .list e, .list declared => listMeaning p e declared (m.observed f)
  | .listOnReentry, .list _ => .pass
  | _, _ => .refused

/-- One field's verdict: presence first, and only a specified value reaches its meaning. -/
@[req "ARC-39"] def check (p : Params) (m : Machine) (d : Declaration) (f : Field) : Verdict :=
  match d f with
  | .missing => .refused
  | .unspecified => .blocked
  | .specified v => meaning p m f v

/-- What the check has recorded: each field's verdict as it was reached, newest first, and
whether delivery was reached. -/
structure Record where
  verdicts : List (Field × Verdict)
  delivered : Bool
  deriving DecidableEq, Repr

inductive Event
  /-- The harness measures the machine against one field. -/
  | check (f : Field)
  /-- The session asks for delivery; the harness decides. -/
  | deliver
  deriving DecidableEq, Repr

def Record.passed (r : Record) (f : Field) : Bool :=
  r.verdicts.any fun fv => fv.1 == f && fv.2 == .pass

/-- `check` records the field's verdict; `deliver` reaches delivery only when every field of
the table has a recorded pass, and a delivery reached stays reached. -/
@[req "ARC-39"] def step (p : Params) (m : Machine) (d : Declaration) (r : Record) : Event → Record
  | .check f => { r with verdicts := (f, check p m d f) :: r.verdicts }
  | .deliver => { r with delivered := r.delivered || fields.all r.passed }

def run (p : Params) (m : Machine) (d : Declaration) (r : Record) : List Event → Record
  | [] => r
  | e :: es => run p m d (step p m d r e) es

def init : Record := { verdicts := [], delivered := false }

/-- The check in the table's order, then delivery. -/
def walk : List Event := fields.map Event.check ++ [.deliver]

/-! ## Over every trace -/

/-- Every recorded verdict is the field's, and delivery reached means every field passed. -/
def Inv (p : Params) (m : Machine) (d : Declaration) (r : Record) : Prop :=
  (∀ fv ∈ r.verdicts, fv.2 = check p m d fv.1) ∧
  (r.delivered = true → ∀ f, check p m d f = .pass)

theorem passed_check (p : Params) (m : Machine) (d : Declaration) (r : Record)
    (hv : ∀ fv ∈ r.verdicts, fv.2 = check p m d fv.1) (f : Field) (h : r.passed f = true) :
    check p m d f = .pass := by
  unfold Record.passed at h
  rw [List.any_eq_true] at h
  obtain ⟨⟨g, v⟩, hmem, hgv⟩ := h
  simp only [Bool.and_eq_true, beq_iff_eq] at hgv
  obtain ⟨rfl, rfl⟩ := hgv
  exact (hv _ hmem).symm

theorem inv_step (p : Params) (m : Machine) (d : Declaration) (r : Record)
    (hr : Inv p m d r) (e : Event) : Inv p m d (step p m d r e) := by
  obtain ⟨hv, hd⟩ := hr
  cases e with
  | check f =>
    refine ⟨?_, hd⟩
    intro fv hfv
    simp only [step] at hfv
    rw [List.mem_cons] at hfv
    rcases hfv with rfl | hfv
    · rfl
    · exact hv fv hfv
  | deliver =>
    refine ⟨hv, ?_⟩
    intro h f
    simp only [step, Bool.or_eq_true] at h
    rcases h with h | h
    · exact hd h f
    · exact passed_check p m d r hv f (List.all_eq_true.mp h f (total f))

theorem inv_run (p : Params) (m : Machine) (d : Declaration) (r : Record) (hr : Inv p m d r)
    (es : List Event) : Inv p m d (run p m d r es) := by
  induction es generalizing r with
  | nil => exact hr
  | cons e es ih => exact ih (step p m d r e) (inv_step p m d r hr e)

theorem inv_init (p : Params) (m : Machine) (d : Declaration) : Inv p m d init :=
  ⟨fun _ h => (nomatch h), fun h => (nomatch h)⟩

/-- A passing field is specified: presence is decided before meaning, and neither `missing`
nor `unspecified` reaches it. -/
theorem pass_specified (p : Params) (m : Machine) (d : Declaration) (f : Field)
    (h : check p m d f = .pass) : ∃ v, d f = .specified v := by
  unfold check at h
  split at h
  · exact nomatch h
  · exact nomatch h
  · exact ⟨_, ‹_›⟩

/-- No path reaches delivered while any field is missing or unspecified: over every trace from
`init`, for every declaration and every machine, delivery reached means every field of the
table is specified — "An absent field is a schema error, not `unspecified`", and
`unspecified` means "**delivery is blocked**". -/
@[req "ARC-39"] theorem delivered_specified (p : Params) (m : Machine) (d : Declaration)
    (es : List Event) (h : (run p m d init es).delivered = true) :
    ∀ f, ∃ v, d f = .specified v :=
  fun f => pass_specified p m d f ((inv_run p m d init (inv_init p m d) es).2 h f)

/-- An empty inbound list with any answering socket is a finding: `listeners.inbound` declares
what must exist, so "an empty list means *nothing may*, and anything found is a finding". -/
@[req "ARC-39"] theorem empty_inbound_finding (p : Params) (hp : p.emptyMeansPerField = true)
    (m : Machine) (d : Declaration) (hd : d .listenersInbound = .specified (.list []))
    (hm : m.observed .listenersInbound ≠ []) :
    check p m d .listenersInbound = .finding := by
  generalize hx : m.observed .listenersInbound = l at hm
  cases l with
  | nil => exact absurd rfl hm
  | cons x xs => simp [check, hd, meaning, row, listMeaning, hp, hx]

/-- Without the rule — as it read until 2026-09-16 — the same empty list passes whatever
answers. -/
@[req "ARC-39"] theorem empty_inbound_passed (p : Params) (hp : p.emptyMeansPerField = false)
    (m : Machine) (d : Declaration) (hd : d .listenersInbound = .specified (.list [])) :
    check p m d .listenersInbound = .pass := by
  simp [check, hd, meaning, row, listMeaning, hp]

/-- An empty outbound-restriction list is not: `listeners.outbound` declares a restriction, and
"`[]` means no outbound restriction is declared, explicitly", whatever the machine shows. -/
@[req "ARC-39"] theorem empty_outbound_passes (m : Machine) (d : Declaration)
    (hd : d .listenersOutbound = .specified (.list [])) :
    check current m d .listenersOutbound = .pass := by
  simp [check, hd, meaning, row, listMeaning]

/-- A multi-tenant machine cannot declare spendable key material: `ARC-37` says "A multi-tenant
machine MUST NOT hold **spendable** key material", and the table makes `key_material.spendable`
"`false` on a multi-tenant machine (`ARC-37`, harness rule; a profile cannot set `true`
there)", so `true` there is refused and no trace reaches delivery. -/
@[req "ARC-37"] theorem spendable_multi_tenant_refused (p : Params) (m : Machine)
    (d : Declaration) (hm : m.multiTenant = true)
    (hd : d .keyMaterialSpendable = .specified (.flag true)) :
    check p m d .keyMaterialSpendable = .refused ∧
    ∀ es, (run p m d init es).delivered = false := by
  have hc : check p m d .keyMaterialSpendable = .refused := by
    simp [check, hd, meaning, row, hm]
  refine ⟨hc, fun es => ?_⟩
  match hdel : (run p m d init es).delivered with
  | false => rfl
  | true =>
    have := (inv_run p m d init (inv_init p m d) es).2 hdel .keyMaterialSpendable
    rw [hc] at this
    exact nomatch this

/-! ## The witnesses, decided -/

/-! Each witness's declaration and machine are named here, so that the theorem and the emitter
(`Witnesses.lean`) run the same check. -/

/-- The document's "ad-hoc, v1 (complete)" declaration: one inbound listener, item 22, nothing
else declared, spendable `false`. -/
def adhoc : Declaration
  | .version => .specified (.number 1)
  | .listenersInbound => .specified (.list [22])
  | .listenersOutbound => .specified (.list [])
  | .services => .specified (.list [])
  | .keyMaterialSpendable => .specified (.flag false)
  | .keyMaterialPermitted => .specified (.list [])
  | .driftChecks => .specified (.list [])
  | .required => .specified (.list [])
  | .defaultCredentials => .specified (.list [])

/-- A declaration with one field replaced. -/
def Declaration.set (d : Declaration) (f : Field) (v : Presence Value) : Declaration :=
  fun g => if g = f then v else d g

/-- The document's "lnrent, v1 (template, every field unspecified)": the two values the corpus
states, the service as item 1, and everything else `unspecified`. -/
def template : Declaration
  | .version => .specified (.number 1)
  | .listenersInbound => .unspecified
  | .listenersOutbound => .unspecified
  | .services => .specified (.list [1])
  | .keyMaterialSpendable => .specified (.flag false)
  | .keyMaterialPermitted => .unspecified
  | .driftChecks => .unspecified
  | .required => .unspecified
  | .defaultCredentials => .unspecified

/-- A single-purpose machine answering on item 22 and showing nothing else. -/
def machine22 : Machine :=
  { multiTenant := false, observed := fun f => match f with | .listenersInbound => [22] | _ => [] }

/-- The machine with what it shows for one field replaced. -/
def Machine.showing (m : Machine) (f : Field) (xs : List Nat) : Machine :=
  { m with observed := fun g => if g = f then xs else m.observed g }

def Record.verdict (r : Record) (f : Field) : Option Verdict := r.verdicts.lookup f

/-- `adhoc` with `listeners.inbound` `[]`: the inventory's trap. -/
def emptyInbound : Declaration := adhoc.set .listenersInbound (.specified (.list []))
/-- `adhoc` without `drift_checks`. -/
def absentDriftChecks : Declaration := adhoc.set .driftChecks .missing
/-- `adhoc` with `key_material.spendable` `true`. -/
def spendableTrue : Declaration := adhoc.set .keyMaterialSpendable (.specified (.flag true))
/-- `machine22` also answering on item 80. -/
def machine22and80 : Machine := machine22.showing .listenersInbound [22, 80]
/-- `machine22` with an outbound restriction in place. -/
def machineRestricted : Machine := machine22.showing .listenersOutbound [1]
/-- `machine22` showing the template's service. -/
def machineWithService : Machine := machine22.showing .services [1]
/-- `machine22` hosting strangers. -/
def machineMultiTenant : Machine := { machine22 with multiTenant := true }

/-- The complete declaration on the machine it describes: every field passes and delivery is
reached. The check is not safe by refusing everything. -/
@[req "ARC-39"] theorem adhoc_delivered :
    let r := run current machine22 adhoc init walk
    r.delivered = true ∧ fields.all r.passed = true := by decide +kernel

/-- The inventory's trap, refused: the empty inbound list on the machine answering on 22 — the
empty list means nothing may, the socket is a finding, delivery is not reached. -/
@[req "ARC-39"] theorem empty_inbound_refused :
    let r := run current machine22 emptyInbound init walk
    r.verdict .listenersInbound = some .finding ∧ r.delivered = false := by decide +kernel

/-- The same trace under the rule as it read until 2026-09-16: the empty list is "nothing to
check, delivery may pass", the socket passes, and "an implementation reading the rule and not
the rows would have passed a machine with any listener at all". -/
@[req "ARC-39"] theorem empty_inbound_admitted :
    let r := run { current with emptyMeansPerField := false } machine22 emptyInbound init walk
    r.verdict .listenersInbound = some .pass ∧ r.delivered = true := by decide +kernel

/-- An undeclared listener: `adhoc` on the machine also answering on item 80 — "an undeclared
one is the finding". -/
@[req "ARC-39"] theorem undeclared_listener_finding :
    let r := run current machine22and80 adhoc init walk
    r.verdict .listenersInbound = some .finding ∧ r.delivered = false := by decide +kernel

/-- An empty outbound list on a machine showing a restriction in place: still a pass, since
none is declared. -/
@[req "ARC-39"] theorem empty_outbound_not_finding :
    let r := run current machineRestricted adhoc init walk
    r.verdict .listenersOutbound = some .pass ∧ r.delivered = true := by decide +kernel

/-- The template on the machine showing its service: the specified fields pass and the
unspecified ones block, so delivery is not reached. -/
@[req "ARC-39"] theorem template_blocked :
    let r := run current machineWithService template init walk
    r.verdict .services = some .pass ∧ r.verdict .listenersInbound = some .blocked ∧
    r.delivered = false := by decide +kernel

/-- A field absent: `adhoc` without `drift_checks` is refused, not read as empty. -/
@[req "ARC-39"] theorem absent_field_refused :
    let r := run current machine22 absentDriftChecks init walk
    r.verdict .driftChecks = some .refused ∧ r.delivered = false := by decide +kernel

/-- Spendable material declared on a multi-tenant machine: refused, and delivery not reached. -/
@[req "ARC-37"] theorem spendable_declared_refused :
    let r := run current machineMultiTenant spendableTrue init walk
    r.verdict .keyMaterialSpendable = some .refused ∧ r.delivered = false := by decide +kernel

/-! ## The bound -/

/-- The bound (`CONTEXT.md`): every field of the table varied one at a time through its
presences — missing, unspecified, and two specified values of its shape, for a list the
explicit empty and one item — with the machine showing nothing or item 1 for it, single-purpose
and multi-tenant, over a base declaration and machine; each case is the full `walk`. Stated
once, here, for `bounded` and for the witness file. -/
@[req "ARC-39"] structure Sweep where
  declaration : Declaration
  machine : Machine
  presences : Field → List (Presence Value)
  observations : List (List Nat)
  tenancies : List Bool

@[req "ARC-39"] def bound : Sweep :=
  { declaration := adhoc, machine := machine22,
    presences := fun f => [.missing, .unspecified] ++ (match (row f).shape with
      | .number => [.specified (.number 1), .specified (.number 2)]
      | .flag => [.specified (.flag false), .specified (.flag true)]
      | .list _ | .listOnReentry => [.specified (.list []), .specified (.list [1])]),
    observations := [[], [1]], tenancies := [false, true] }

structure Case where
  field : Field
  presence : Presence Value
  observed : List Nat
  multiTenant : Bool
  deriving DecidableEq, Repr

def Case.machine (c : Case) : Machine :=
  { (bound.machine.showing c.field c.observed) with multiTenant := c.multiTenant }

def Case.declaration (c : Case) : Declaration := bound.declaration.set c.field c.presence

def Case.run (c : Case) : Record := Declaration.run current c.machine c.declaration init walk

/-- Every case of the sweep, fields in the table's order. -/
def cases : List Case :=
  fields.flatMap fun f => (bound.presences f).flatMap fun v =>
    bound.observations.flatMap fun xs => bound.tenancies.map fun t => ⟨f, v, xs, t⟩

/-- The three theorems, decided within the bound: delivery reached only with every field
specified; the varied field's empty list a finding for a nothing-may row exactly when
something is shown, never for a nothing-to-check row or one the re-check runs; `true` for
spendable refused on a multi-tenant machine. -/
@[req "ARC-39"] theorem bounded :
    cases.all (fun c =>
      let r := c.run
      (!r.delivered || fields.all fun f => c.declaration f matches .specified _) &&
      (!(c.presence == .specified (.list [])) ||
        match (row c.field).shape with
        | .list .nothingMay => r.verdict c.field == some (if c.observed.isEmpty then .pass else .finding)
        | .list .nothingToCheck | .listOnReentry => r.verdict c.field == some .pass
        | _ => true) &&
      (!(c.presence == .specified (.flag true) && c.multiTenant) ||
        r.verdict c.field == some .refused)) = true := by
  decide +kernel

end TauWeb.Declaration
