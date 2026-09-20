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

/-- One trace of the file's shape: its declarations, the module's assumptions, the pair if any,
the start and the steps. -/
def traceJson (decls : List String) (assumptions : Json) (pair : Option (Side × String))
    (start : Json) (steps : Array Json) : Json :=
  Json.mkObj <|
    [("declarations", toJson decls), ("assumptions", assumptions)] ++
    (match pair with
     | some (side, other) => [("pair", Json.mkObj [("side", side.name), ("with", other)])]
     | none => []) ++
    [("start", start), ("steps", Json.arr steps)]

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
  traceJson t.decls (Json.mkObj [("restoredAllocatesNone", toJson t.params.restoredAllocatesNone)])
    t.pair (journalJson t.start.journal) steps

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
def fileText (name : String) (ns : Name) (bound : Json) (witnesses enumeration : List Json) :
    String :=
  let lines (ts : List Json) := String.intercalate ",\n" (ts.map fun t => "    " ++ t.compress)
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
    text := fileText "allocation" `TauWeb.Allocation bound (allocationWitnesses.map (·.json))
      (allocationEnumeration.map (·.json)),
    named := traces.flatMap (·.decls),
    refs := boundDecl :: traces.filterMap fun t => t.pair.map (·.2) }

/-! ## Declaration, in `delivery-declaration-v1.md`'s vocabulary -/

namespace Declaration

open TauWeb.Declaration hiding Event Params current init

def verdictName : Verdict → String
  | .refused => "refused"
  | .blocked => "blocked"
  | .finding => "finding"
  | .pass => "pass"

def valueJson : Value → Json
  | .number n => toJson n
  | .flag b => toJson b
  | .list xs => toJson xs

/-- A field's presence as the document writes it: the value, or the marker; `missing` is the
member absent, so that a reader meets it as absent and not as `unspecified`. `"none"` for
`default_credentials` is the empty list, written as the table does. -/
def presenceJson (f : Field) : Presence Value → Option Json
  | .missing => none
  | .unspecified => some "unspecified"
  | .specified (.list []) => some (if f = .defaultCredentials then "none" else Json.arr #[])
  | .specified v => some (valueJson v)

/-- Keyed by the table's names. -/
def declarationJson (d : TauWeb.Declaration.Declaration) : Json :=
  Json.mkObj (fields.filterMap fun f => (presenceJson f (d f)).map ((row f).name, ·))

def machineJson (m : Machine) : Json :=
  Json.mkObj [("multi_tenant", toJson m.multiTenant),
              ("observed", Json.mkObj (fields.map fun f => ((row f).name, toJson (m.observed f))))]

/-- The projection of harness knowledge: each field's verdict as recorded, and whether
delivery was reached. -/
def recordJson (r : Record) : Json :=
  Json.mkObj [("verdicts", Json.mkObj (fields.filterMap fun f =>
                (r.verdict f).map fun v => ((row f).name, toJson (verdictName v)))),
              ("delivered", toJson r.delivered)]

def eventJson : TauWeb.Declaration.Event → Json
  | .check f => Json.mkObj [("kind", "check"), ("provenance", "adapter observation"),
                            ("field", toJson (row f).name)]
  | .deliver => Json.mkObj [("kind", "deliver"), ("provenance", "model request")]

/-- One step: the event, the verdict a check recorded or whether delivery was reached, and the
record after. -/
def stepJson (p : TauWeb.Declaration.Params) (m : Machine) (d : TauWeb.Declaration.Declaration)
    (r : Record) (e : TauWeb.Declaration.Event) : Json × Record :=
  let r' := TauWeb.Declaration.step p m d r e
  let outcome := match e with
    | .check f => [("verdict", toJson ((r'.verdict f).map verdictName))]
    | .deliver => [("delivered", toJson r'.delivered)]
  (Json.mkObj ([("event", eventJson e)] ++ outcome ++ [("record", recordJson r')]), r')

structure Trace where
  decls : List String
  declaration : TauWeb.Declaration.Declaration
  machine : Machine
  params : TauWeb.Declaration.Params := TauWeb.Declaration.current
  pair : Option (Side × String) := none

def Trace.json (t : Trace) : Json :=
  let steps := (walk.foldl
    (fun (acc, r) e => let (j, r') := stepJson t.params t.machine t.declaration r e; (acc.push j, r'))
    (#[], TauWeb.Declaration.init)).1
  traceJson t.decls (Json.mkObj [("emptyMeansPerField", toJson t.params.emptyMeansPerField)]) t.pair
    (Json.mkObj [("declaration", declarationJson t.declaration), ("machine", machineJson t.machine),
                 ("record", recordJson TauWeb.Declaration.init)])
    steps

def noRule : TauWeb.Declaration.Params := { TauWeb.Declaration.current with emptyMeansPerField := false }

def witnesses : List Trace := [
  { decls := ["TauWeb.Declaration.adhoc_delivered"], declaration := adhoc, machine := machine22 },
  { decls := ["TauWeb.Declaration.empty_inbound_refused"], declaration := emptyInbound,
    machine := machine22, pair := some (.refused, "TauWeb.Declaration.empty_inbound_admitted") },
  { decls := ["TauWeb.Declaration.empty_inbound_admitted"], declaration := emptyInbound,
    machine := machine22, params := noRule,
    pair := some (.admitted, "TauWeb.Declaration.empty_inbound_refused") },
  { decls := ["TauWeb.Declaration.undeclared_listener_finding"], declaration := adhoc,
    machine := machine22and80 },
  { decls := ["TauWeb.Declaration.empty_outbound_not_finding"], declaration := adhoc,
    machine := machineRestricted },
  { decls := ["TauWeb.Declaration.template_blocked"], declaration := template,
    machine := machineWithService },
  { decls := ["TauWeb.Declaration.absent_field_refused"], declaration := absentDriftChecks,
    machine := machine22 },
  { decls := ["TauWeb.Declaration.spendable_declared_refused"], declaration := spendableTrue,
    machine := machineMultiTenant } ]

def enumeration : List Trace :=
  cases.map fun c => { decls := ["TauWeb.Declaration.bounded"],
                       declaration := c.declaration, machine := c.machine }

def module : Module :=
  let boundDecl := "TauWeb.Declaration.bound"
  let bound := Json.mkObj [("declaration", boundDecl),
    ("base", Json.mkObj [("declaration", declarationJson bound.declaration),
                         ("machine", machineJson bound.machine)]),
    ("presences", Json.mkObj (fields.map fun f => ((row f).name,
      Json.arr ((bound.presences f).map fun v => (presenceJson f v).getD "missing").toArray))),
    ("observations", toJson bound.observations), ("tenancies", toJson bound.tenancies)]
  let traces := witnesses ++ enumeration
  { name := "declaration", ns := `TauWeb.Declaration,
    text := fileText "declaration" `TauWeb.Declaration bound (witnesses.map (·.json))
      (enumeration.map (·.json)),
    named := traces.flatMap (·.decls),
    refs := boundDecl :: traces.filterMap fun t => t.pair.map (·.2) }

end Declaration

/-! ## Relay admission, in `relay-protocol-v1.md`'s vocabulary -/

namespace Relay

-- The clashing names of TauWeb.Allocation, opened above, are qualified here on purpose.
open TauWeb.Relay hiding Family Event Params current step run bound alphabet tracesOf tracesUpTo

def phaseName : Phase → String
  | .opened => "opened"
  | .authAccepted => "auth_accepted"
  | .okSent => "ok_sent"
  | .closed => "closed"

def reasonName : Reason → String
  | .auth => "auth"
  | .pass => "pass"
  | .destination => "destination"
  | .address => "address"
  | .pace => "pace"
  | .dial => "dial"

def familyName : TauWeb.Relay.Family → String
  | .v4 => "v4"
  | .v6 => "v6"
  | .v4mapped => "v4_mapped"

/-- An address is its family and its opaque value, never wire bytes. -/
def addrJson (a : Addr) : Json :=
  Json.mkObj [("family", Json.str (familyName a.family)), ("value", toJson a.value)]

def hostJson : Host → Json
  | .dns n => Json.mkObj [("name", toJson n)]
  | .numeric a => Json.mkObj [("address", addrJson a)]

def destinationJson (d : Destination) : Json :=
  Json.mkObj [("host", hostJson d.host), ("port", toJson d.port)]

/-- The projection of harness knowledge: the connection as `relay-protocol-v1.md` names it — the
phase, whether the AUTH was accepted and whether OK went out, the addresses the dialer was
handed, the application bytes forwarded, and the refusal reason. Nothing of the companion's
`Connection` beyond it, and never a challenge, a signature or an address the relay did not dial. -/
def connectionJson (s : Connection) : Json :=
  Json.mkObj [
    ("phase", Json.str (phaseName s.phase)),
    ("auth_accepted", toJson s.accepted),
    ("ok_sent", toJson s.okSent),
    ("dialed", Json.arr (s.dialed.reverse.map addrJson).toArray),
    ("forwarded", toJson s.forwarded),
    ("refused", match s.refused with | some r => Json.str (reasonName r) | none => Json.null) ]

/-- The AUTH as the checks read it. Its provenance is `replay` exactly when the frame answers a
challenge that is not this connection's, and `operator act` otherwise, since the browser signs
with the operator's relay key. The challenge itself is not carried: what is compared is whether
the frame answered this connection's. -/
def authJson (s : Connection) (a : Auth) : Json :=
  Json.mkObj [
    ("kind", "auth"),
    ("provenance", Json.str (if a.challenge == s.challenge then "operator act" else "replay")),
    ("destination", destinationJson a.destinationTag),
    ("key", toJson a.key),
    ("event_kind", toJson a.kind),
    ("relay_tag", toJson a.relayTag),
    ("within_skew", toJson a.fresh),
    ("signature_verifies", toJson a.signature),
    ("answers_challenge", toJson (a.challenge == s.challenge)) ]

def eventJson (s : Connection) : TauWeb.Relay.Event → Json
  | .auth a => authJson s a
  | .dial up => Json.mkObj [("kind", "dial"), ("provenance", "adapter observation"),
                            ("connected", toJson up)]
  | .appFrame => Json.mkObj [("kind", "app_frame"), ("provenance", "operator act")]

/-- One step: the event, what the connection did with it, and the projection after. -/
def stepJson (p : TauWeb.Relay.Params) (r : TauWeb.Relay.Relay) (s : Connection)
    (e : TauWeb.Relay.Event) : Json × Connection :=
  let s' := TauWeb.Relay.step p r s e
  let outcome := match e with
    | .auth _ =>
      [("auth", Json.str (if s.phase != .opened then "ignored"
                          else if s'.accepted then "accepted" else "refused"))]
    | .dial _ =>
      [("dial", Json.str (if s.dialed.length < s'.dialed.length then "dialed" else "refused"))]
    | .appFrame => [("forwarded", toJson (decide (s.forwarded < s'.forwarded)))]
  (Json.mkObj ([("event", eventJson s e)] ++ outcome ++ [("connection", connectionJson s')]), s')

structure Trace where
  decls : List String
  events : List TauWeb.Relay.Event
  start : Connection
  relay : TauWeb.Relay.Relay := publisherRelay
  params : TauWeb.Relay.Params := TauWeb.Relay.current
  /-- A refused-and-admitted pair: this side, and the declaration of the other. -/
  pair : Option (Side × String) := none

/-- The pass the operator's key holds, as the checks read it: whether it is live, and one entry
per recorded host with whether pacing admits a dial to it now. An AUTH under another key finds
none. -/
def passJson (r : TauWeb.Relay.Relay) : Json :=
  match r.pass operatorKey with
  | none => Json.null
  | some p => Json.mkObj [
      ("live", toJson p.live),
      ("recorded", Json.arr (p.hosts.map fun h =>
        Json.mkObj [("host", hostJson h), ("paced", toJson (p.paced h))]).toArray) ]

/-- The assumptions: the guard parameter, and the classification tables and resolver answers the
trace ran under — `CHN-16a`'s pinned registries are the module's assumption, so a witness carries
the value it assumed rather than a table the companion owns. -/
def assumptionsJson (p : TauWeb.Relay.Params) : Json :=
  Json.mkObj [
    ("dialRequiresAuthAccepted", toJson p.dialRequiresAuthAccepted),
    ("special", Json.arr (facts.special.map addrJson).toArray),
    ("ownAddress", Json.arr (facts.own.map addrJson).toArray),
    ("resolve", Json.arr (facts.answers.map fun na =>
      Json.mkObj [("name", toJson na.1),
                  ("answers", Json.arr (na.2.map addrJson).toArray)]).toArray) ]

def startJson (t : Trace) : Json :=
  Json.mkObj [
    ("challenge", toJson t.start.challenge),
    ("destination", match t.start.destination with
                    | some d => destinationJson d | none => Json.null),
    ("classified", match t.start.classified with
                   | some x => addrJson x.addr | none => Json.null),
    ("pass", passJson t.relay),
    ("connection", connectionJson t.start) ]

def Trace.json (t : Trace) : Json :=
  let steps := (t.events.foldl
    (fun (acc, s) e => let (j, s') := stepJson t.params t.relay s e; (acc.push j, s'))
    (#[], t.start)).1
  traceJson t.decls (assumptionsJson t.params) t.pair (startJson t) steps

def noSeparation : TauWeb.Relay.Params :=
  { TauWeb.Relay.current with dialRequiresAuthAccepted := false }

def witnesses : List Trace := [
  { decls := ["TauWeb.Relay.handshake_ok"], events := handshakeEvents,
    start := recordedConnection },
  { decls := ["TauWeb.Relay.dial_before_auth_refused"], events := dialFirstEvents,
    start := recordedConnection,
    pair := some (.refused, "TauWeb.Relay.dial_before_auth_admitted") },
  { decls := ["TauWeb.Relay.dial_before_auth_admitted"], events := dialFirstEvents,
    start := recordedConnection, params := noSeparation,
    pair := some (.admitted, "TauWeb.Relay.dial_before_auth_refused") },
  { decls := ["TauWeb.Relay.replayed_signature_refused"], events := authEvents,
    start := nextConnection },
  { decls := ["TauWeb.Relay.mismatched_tag_refused"], events := strangerDestEvents,
    start := recordedConnection },
  { decls := ["TauWeb.Relay.unknown_key_refused"], events := strangerKeyEvents,
    start := recordedConnection },
  { decls := ["TauWeb.Relay.undeclared_destination_refused"], events := strangerDestEvents,
    start := strangerConnection },
  { decls := ["TauWeb.Relay.admitted_name_dialed"], events := cleanNameEvents,
    start := cleanConnection },
  { decls := ["TauWeb.Relay.forbidden_answer_refused"], events := mixedEvents,
    start := mixedConnection },
  { decls := ["TauWeb.Relay.mapped_loopback_refused"], events := mappedEvents,
    start := mappedConnection },
  { decls := ["TauWeb.Relay.paced_out_refused"], events := authEvents,
    start := recordedConnection, relay := pacedOutRelay },
  { decls := ["TauWeb.Relay.alternate_spelling_closed"], events := authEvents,
    start := alternateConnection },
  { decls := ["TauWeb.Relay.bad_port_closed"], events := authEvents,
    start := badPortConnection },
  { decls := ["TauWeb.Relay.bytes_before_ok_closed"], events := bytesBeforeOkEvents,
    start := recordedConnection },
  { decls := ["TauWeb.Relay.failed_dial_sends_no_ok"], events := failedDialEvents,
    start := recordedConnection } ]

def enumeration : List Trace :=
  (TauWeb.Relay.tracesUpTo TauWeb.Relay.bound).map fun es =>
    { decls := ["TauWeb.Relay.bounded"], events := es, start := recordedConnection }

def module : Module :=
  let boundDecl := "TauWeb.Relay.bound"
  let bound := Json.mkObj [
    ("declaration", boundDecl), ("events", toJson TauWeb.Relay.bound),
    ("alphabet", Json.arr (TauWeb.Relay.alphabet.map (eventJson recordedConnection)).toArray),
    ("start", startJson { decls := [], events := [], start := recordedConnection })]
  let traces := witnesses ++ enumeration
  { name := "relay", ns := `TauWeb.Relay,
    text := fileText "relay" `TauWeb.Relay bound (witnesses.map (·.json))
      (enumeration.map (·.json)),
    named := traces.flatMap (·.decls),
    refs := boundDecl :: traces.filterMap fun t => t.pair.map (·.2) }

end Relay

/-! ## Dispatch and the unresolved barrier, in `STA-24`'s vocabulary -/

namespace Dispatch

-- The clashing names of TauWeb.Allocation, opened above, are qualified here on purpose.
open TauWeb.Dispatch hiding Entry Event Journal Params World current init step run bound alphabet
  tracesOf tracesUpTo

def kindName : Kind → String
  | .create => "create"
  | .reset => "reset"
  | .destroy => "destroy"
  | .activate => "activate"
  | .registerKey => "register_key"
  | .exec => "exec"
  | .read => "read"
  | .inference => "inference"

def keyName : Key → String
  | .entry => "entry"
  | .index => "index"
  | .call => "call"

def standingName : Standing → String
  | .unknown => "unknown"
  | .ended => "ended"
  | .succeeded => "succeeded"

def provenanceName : Provenance → String
  | .adapterRead => "adapter_read"
  | .pinCheckedHandshake => "pin_checked_handshake"
  | .jobRecord => "job_record"
  | .notifyEvent => "notify_event"
  | .modelText => "model_text"

/-- The resource as `STA-24` names it, never an identifier the vendor would recognize: an entry
is the approved machine entry's ordinal in the setup batch and a scope is an ordinal too. -/
def resourceJson : Resource → Json
  | .machine e => Json.mkObj [("machine_entry", toJson e)]
  | .inference => Json.mkObj [("inference", toJson true)]

/-- What a model named, which is what the request-to-entry mapping is compared on (ADR-0032). -/
def targetJson : Target → Json
  | .entry e => Json.mkObj [("entry", toJson e)]
  | .index n => Json.mkObj [("allocation_index", toJson n)]
  | .vendor v => Json.mkObj [("vendor_machine_id", toJson v)]
  | .inferenceCap => Json.mkObj [("inference_cap", toJson true)]

def refusalJson : Refusal → Json
  | .unmapped => Json.mkObj [("reason", "unmapped")]
  | .binding => Json.mkObj [("reason", "binding")]
  | .facts => Json.mkObj [("reason", "facts")]
  | .append => Json.mkObj [("reason", "append")]
  | .barrier cs => Json.mkObj [("reason", "barrier"), ("calls", toJson cs)]
  | .continuation k => Json.mkObj [("reason", "continuation"), ("permits", kindName k)]

/-- The entries the journal names, so that `reset_offer` is read over the entries in play. -/
def entriesOf (j : TauWeb.Dispatch.Journal) : List TauWeb.Dispatch.Entry :=
  (j.filterMap fun rec => match rec with
    | .association _ e => some e
    | .resetPrereqs e => some e
    | .intent i => match i.resource with | .machine e => some e | .inference => none
    | _ => none).eraseDups

/-- One call as the journal holds it: the intent record, and whether it is still unresolved. A
read is never an unresolved call — it has no effect to be unresolved about. -/
def callJson (p : TauWeb.Dispatch.Params) (j : TauWeb.Dispatch.Journal) (i : Intent) : Json :=
  Json.mkObj [
    ("call", toJson i.call), ("target", targetJson i.target),
    ("resource", resourceJson i.resource), ("operation", kindName i.kind),
    ("session", toJson i.session),
    ("approved", Json.mkObj [("session", toJson i.approval.session),
                             ("facts", toJson i.approval.facts)]),
    ("state", Json.str (if !sideEffecting i.kind then "no_effect"
                        else if (unresolved p j i.resource).contains i.call then "unresolved"
                        else "terminal")) ]

/-- The projection of harness knowledge: the journal in `STA-24`'s vocabulary — the harness's own
mapping of what a model may name to the approved entry, the calls it holds, the barrier per
resource, what a standing disposition permits, the entries whose planned reset may be offered
(`STA-20b`), and what was dispatched. `durable` is whether in-memory state is also what was
appended, which `STA-3` makes always true. Nothing of the companion's `World` beyond that, and
never external state. -/
def knowledgeJson (p : TauWeb.Dispatch.Params) (w : TauWeb.Dispatch.World) : Json :=
  let j := w.memory
  Json.mkObj [
    ("durable", toJson (w.memory == w.journal)),
    ("associations", Json.arr ((j.filterMap fun rec => match rec with
      | .association t e => some (Json.mkObj [("target", targetJson t), ("entry", toJson e)])
      | _ => none).reverse).toArray),
    ("calls", Json.arr ((intentsOf j).reverse.map (callJson p j)).toArray),
    ("unresolved", Json.arr ((resourcesOf j).map fun r =>
      Json.mkObj [("resource", resourceJson r),
                  ("calls", toJson (unresolved p j r))]).toArray),
    ("continuation", Json.arr ((resourcesOf j).filterMap fun r =>
      (restriction p j r).map fun k =>
        Json.mkObj [("resource", resourceJson r), ("permits", kindName k)]).toArray),
    ("reset_offer", toJson ((entriesOf j).filter (offersReset j))),
    ("dispatched", toJson (w.dispatched.reverse.map Intent.call)) ]

/-- An event's provenance is ADR-0032's closed vocabulary; `appended` beside it is the storage
outcome of that event's own append, a driver instruction like a lost response. A read carries
what the far side reported, which is the adapter's answer and not the harness's decision. -/
def eventJson (x : External) : TauWeb.Dispatch.Event → Json
  | .request rq ap ok => Json.mkObj [
      ("kind", "request"), ("provenance", "model request"),
      ("call", toJson rq.call), ("target", targetJson rq.target),
      ("operation", kindName rq.kind), ("session", toJson rq.session),
      ("facts", toJson rq.facts),
      ("approved", Json.mkObj [("session", toJson ap.session), ("facts", toJson ap.facts)]),
      ("appended", toJson ok)]
  | .observe prov r k ok => Json.mkObj [
      ("kind", "read"), ("provenance", "adapter observation"),
      ("source", provenanceName prov), ("resource", resourceJson r),
      ("operation", kindName k), ("reports", standingName (x.reports r k)),
      ("appended", toJson ok)]
  | .dispose d ok => Json.mkObj [
      ("kind", "dispose"), ("provenance", "disposition"),
      ("resource", resourceJson d.resource), ("calls", toJson d.calls),
      ("continuation", kindName d.continuation), ("appended", toJson ok)]
  | .associate t e => Json.mkObj [
      ("kind", "associate"), ("provenance", "operator act"),
      ("target", targetJson t), ("entry", toJson e)]
  | .resetPrereqs e ok => Json.mkObj [
      ("kind", "reset_prereqs"), ("provenance", "adapter observation"),
      ("entry", toJson e), ("appended", toJson ok)]
  | .replay => Json.mkObj [("kind", "replay"), ("provenance", "replay")]

/-- One step: the event, what the harness did with it, and the projection after. -/
def stepJson (p : TauWeb.Dispatch.Params) (x : External) (w : TauWeb.Dispatch.World)
    (e : TauWeb.Dispatch.Event) : Json × TauWeb.Dispatch.World :=
  let w' := TauWeb.Dispatch.step p x w e
  let outcome := match e with
    | .request _ _ _ =>
      match w'.verdict with
      | some (.dispatched _) => [("dispatch", Json.str "dispatched")]
      | some (.refused r) => [("dispatch", Json.str "refused"), ("refusal", refusalJson r)]
      | none => []
    | .observe _ r _ _ =>
      [("settled", toJson ((unresolved p w.memory r).filter fun c =>
        !(unresolved p w'.memory r).contains c))]
    | .resetPrereqs e _ => [("offer", toJson (offersReset w'.memory e))]
    | _ => []
  (Json.mkObj ([("event", eventJson x e)] ++ outcome ++ [("knowledge", knowledgeJson p w')]), w')

structure Trace where
  decls : List String
  events : List TauWeb.Dispatch.Event
  params : TauWeb.Dispatch.Params := TauWeb.Dispatch.current
  /-- What the far side reports for this trace; never in the file, since a witness carries no
  claim about external state (ADR-0032). What a read reported is on the read's own event. -/
  far : Far := farDone
  pair : Option (Side × String) := none

def assumptionsJson (p : TauWeb.Dispatch.Params) : Json :=
  Json.mkObj [("resourceKey", Json.str (keyName p.resourceKey)),
              ("durableBeforeApply", toJson p.durableBeforeApply),
              ("endedBelowSucceeded", toJson p.endedBelowSucceeded),
              ("dispositionBindsContinuation", toJson p.dispositionBindsContinuation)]

def Trace.json (t : Trace) : Json :=
  let x := t.far.external
  let steps := (t.events.foldl
    (fun (acc, w) e => let (j, w') := stepJson t.params x w e; (acc.push j, w'))
    (#[], TauWeb.Dispatch.init)).1
  traceJson t.decls (assumptionsJson t.params) t.pair
    (knowledgeJson t.params TauWeb.Dispatch.init) steps

def witnesses : List Trace := [
  { decls := ["TauWeb.Dispatch.same_action_new_call_id_refused"], events := sameActionEvents,
    pair := some (.refused, "TauWeb.Dispatch.same_action_new_call_id_admitted") },
  { decls := ["TauWeb.Dispatch.same_action_new_call_id_admitted"], events := sameActionEvents,
    params := onCall,
    pair := some (.admitted, "TauWeb.Dispatch.same_action_new_call_id_refused") },
  { decls := ["TauWeb.Dispatch.second_index_same_entry_refused"], events := secondIndexEvents,
    pair := some (.refused, "TauWeb.Dispatch.second_index_same_entry_admitted") },
  { decls := ["TauWeb.Dispatch.second_index_same_entry_admitted"], events := secondIndexEvents,
    params := onIndex,
    pair := some (.admitted, "TauWeb.Dispatch.second_index_same_entry_refused") },
  { decls := ["TauWeb.Dispatch.reset_offered_after_failed_append_refused"],
    events := resetOfferEvents,
    pair := some (.refused, "TauWeb.Dispatch.reset_offered_after_failed_append_admitted") },
  { decls := ["TauWeb.Dispatch.reset_offered_after_failed_append_admitted"],
    events := resetOfferEvents, params := noDurability,
    pair := some (.admitted, "TauWeb.Dispatch.reset_offered_after_failed_append_refused") },
  { decls := ["TauWeb.Dispatch.boot_id_change_not_success_refused"], events := bootIdEvents,
    far := farEnded,
    pair := some (.refused, "TauWeb.Dispatch.boot_id_change_not_success_admitted") },
  { decls := ["TauWeb.Dispatch.boot_id_change_not_success_admitted"], events := bootIdEvents,
    params := flatLattice, far := farEnded,
    pair := some (.admitted, "TauWeb.Dispatch.boot_id_change_not_success_refused") },
  { decls := ["TauWeb.Dispatch.resolution_append_failed_refused"], events := appendFailedEvents,
    pair := some (.refused, "TauWeb.Dispatch.resolution_append_failed_admitted") },
  { decls := ["TauWeb.Dispatch.resolution_append_failed_admitted"], events := appendFailedEvents,
    params := noDurability,
    pair := some (.admitted, "TauWeb.Dispatch.resolution_append_failed_refused") },
  { decls := ["TauWeb.Dispatch.disposition_one_continuation_refused"], events := dispositionEvents,
    pair := some (.refused, "TauWeb.Dispatch.disposition_unrestricted_admitted") },
  { decls := ["TauWeb.Dispatch.disposition_unrestricted_admitted"], events := dispositionEvents,
    params := unboundDisposition,
    pair := some (.admitted, "TauWeb.Dispatch.disposition_one_continuation_refused") },
  { decls := ["TauWeb.Dispatch.ceremony_trace"], events := ceremonyEvents } ]

def enumeration : List Trace :=
  (TauWeb.Dispatch.tracesUpTo TauWeb.Dispatch.bound).map fun es =>
    { decls := ["TauWeb.Dispatch.bounded"], events := es }

def module : Module :=
  let boundDecl := "TauWeb.Dispatch.bound"
  let bound := Json.mkObj [
    ("declaration", boundDecl), ("events", toJson TauWeb.Dispatch.bound),
    ("alphabet", Json.arr
      (TauWeb.Dispatch.alphabet.map (eventJson farDone.external)).toArray),
    ("start", knowledgeJson TauWeb.Dispatch.current TauWeb.Dispatch.init)]
  let traces := witnesses ++ enumeration
  { name := "dispatch", ns := `TauWeb.Dispatch,
    text := fileText "dispatch" `TauWeb.Dispatch bound (witnesses.map (·.json))
      (enumeration.map (·.json)),
    named := traces.flatMap (·.decls),
    refs := boundDecl :: traces.filterMap fun t => t.pair.map (·.2) }

end Dispatch

/-! ## The host-pin lifecycle, in `SEC-11`'s and `CHN-R1`'s vocabulary -/

namespace Pins

-- The clashing names of TauWeb.Allocation, opened above, are qualified here on purpose.
open TauWeb.Pins hiding Entry Event Params current init start step run bound alphabet tracesOf
  tracesUpTo

def systemName : System → String
  | .rescue => "rescue"
  | .installed => "installed"

def sourceName : Source → String
  | .rescueLast => "rescue_last"
  | .readyToReset => "ready_to_reset"
  | .modelText => "model_text"

def haltName : Halt → String
  | .noPin => "no_pin"
  | .mismatch => "mismatch"
  | .confirmsReset => "confirms_reset"

/-- What a pin is held per, as `CHN-R1` words it: the rescue pin is "per boot, not per machine",
and the installed system's keys are "generated there, per machine". -/
def perJson : Per → List (String × Json)
  | .boot n => [("per", "boot"), ("boot", toJson n)]
  | .machine => [("per", "machine")]

/-- A host-key set is the ordinal of a fingerprint set and never key material. -/
def pinJson (pin : Pin) : Json :=
  Json.mkObj ([("entry", toJson pin.entry)] ++ perJson pin.per ++
              [("keys", toJson pin.keys), ("source", Json.str (sourceName pin.source))])

/-- A reset as the harness journals it: the entry, the system it resets into, and the pin the
intent named as its expected next pin, where it named one (`STA-20b`). -/
def awaitedJson (a : TauWeb.Pins.Awaited) : Json :=
  Json.mkObj [("entry", toJson a.entry), ("into", Json.str (systemName a.into)),
              ("expects", match a.expect with | some x => toJson x | none => Json.null)]

def confirmedJson (x : TauWeb.Pins.Entry × System) : Json :=
  Json.mkObj [("entry", toJson x.1), ("into", Json.str (systemName x.2))]

def sessionJson (s : Session) : Json :=
  Json.mkObj [("entry", toJson s.entry), ("system", Json.str (systemName s.system)),
              ("boot", toJson s.boot), ("keys", toJson s.keys), ("pin", pinJson s.pin)]

def haltedJson (h : Halted) : Json :=
  Json.mkObj [("entry", toJson h.entry), ("system", Json.str (systemName h.system)),
              ("presented", toJson h.keys), ("reason", Json.str (haltName h.reason))]

/-- The approved entries the harness knows anything about, oldest first, so that what is read
per entry — the snapshot, the boot — is read over those and not over an association list whose
older entries a lookup never reaches. -/
def entriesOf (k : Knowledge) : List TauWeb.Pins.Entry :=
  (k.pins.map (·.entry) ++ k.snapshot.map (·.1) ++ k.boot.map (·.1) ++ k.awaiting.map (·.entry) ++
    k.confirmed.map (·.1) ++ k.sessions.map (·.entry) ++
    k.halts.map (·.entry)).reverse.eraseDups

/-- The projection of harness knowledge: the pins and what they admitted, in `SEC-11`'s,
`CHN-R1`'s and `ARC-43`'s vocabulary. Nothing of the companion's `Knowledge` beyond it, and never
external state: `snapshot` is what the vendor's field showed when it was read, not what the
machine is running, and a session's `keys` is what the far sshd presented. -/
def knowledgeJson (k : Knowledge) : Json :=
  Json.mkObj [
    ("pins", Json.arr (k.pins.reverse.map pinJson).toArray),
    ("snapshot", Json.arr ((entriesOf k).filterMap fun m =>
      (k.snapshot.lookup m).map fun f =>
        Json.mkObj [("entry", toJson m),
                    ("keys", match f with | some x => toJson x | none => Json.null)]).toArray),
    ("boot", Json.arr ((entriesOf k).map fun m =>
      Json.mkObj [("entry", toJson m), ("boot", toJson (bootOf k m))]).toArray),
    ("awaiting", Json.arr (k.awaiting.reverse.map awaitedJson).toArray),
    ("confirmed", Json.arr (k.confirmed.reverse.map confirmedJson).toArray),
    ("sessions", Json.arr (k.sessions.reverse.map sessionJson).toArray),
    ("halts", Json.arr (k.halts.reverse.map haltedJson).toArray) ]

/-- An event's provenance is ADR-0032's closed vocabulary; `source` beside it, on the three
events that offer a pin, is `ARC-43`'s admission source, which is what `admits` reads. -/
def eventJson : TauWeb.Pins.Event → Json
  | .reset m into => Json.mkObj [
      ("kind", "reset"), ("provenance", "operator act"),
      ("entry", toJson m), ("into", Json.str (systemName into))]
  | .rescueLast m keys => Json.mkObj [
      ("kind", "rescue_last"), ("provenance", "adapter observation"), ("source", "rescue_last"),
      ("entry", toJson m),
      ("keys", match keys with | some f => toJson f | none => Json.null)]
  | .readyToReset m f => Json.mkObj [
      ("kind", "ready_to_reset"), ("provenance", "adapter observation"),
      ("source", "ready_to_reset"), ("entry", toJson m), ("keys", toJson f)]
  | .claim m pr f => Json.mkObj (
      [("kind", Json.str "claim"), ("provenance", Json.str "model request"),
       ("source", Json.str "model_text"), ("entry", toJson m)] ++ perJson pr ++
      [("keys", toJson f)])
  | .connect m sys keys => Json.mkObj [
      ("kind", "connect"), ("provenance", "adapter observation"), ("entry", toJson m),
      ("system", Json.str (systemName sys)), ("presents", toJson keys)]

/-- One step: the event, what the harness did with it, and the projection after. -/
def stepJson (p : TauWeb.Pins.Params) (k : Knowledge) (e : TauWeb.Pins.Event) :
    Json × Knowledge :=
  let k' := TauWeb.Pins.step p k e
  let outcome := match e with
    | .reset m _ => [("boot", toJson (bootOf k' m))]
    | .rescueLast _ _ | .readyToReset _ _ | .claim _ _ _ =>
      [("pinned", toJson (decide (k.pins.length < k'.pins.length)))]
    | .connect m sys keys =>
      match TauWeb.Pins.check k m sys keys with
      | .admitted _ => [("check", Json.str "admitted")]
      | .halted h => [("check", Json.str "halted"), ("halt", Json.str (haltName h))]
  (Json.mkObj ([("event", eventJson e)] ++ outcome ++ [("knowledge", knowledgeJson k')]), k')

structure Trace where
  decls : List String
  events : List TauWeb.Pins.Event
  params : TauWeb.Pins.Params := TauWeb.Pins.current
  /-- The witnesses run from nothing known; the enumeration from `TauWeb.Pins.start`. -/
  start : Knowledge := TauWeb.Pins.init
  /-- A refused-and-admitted pair: this side, and the declaration of the other. -/
  pair : Option (Side × String) := none

def assumptionsJson (p : TauWeb.Pins.Params) : Json :=
  Json.mkObj [("sourceAdmitsPin", toJson p.sourceAdmitsPin)]

def Trace.json (t : Trace) : Json :=
  let steps := (t.events.foldl
    (fun (acc, k) e => let (j, k') := stepJson t.params k e; (acc.push j, k'))
    (#[], t.start)).1
  traceJson t.decls (assumptionsJson t.params) t.pair (knowledgeJson t.start) steps

def witnesses : List Trace := [
  { decls := ["TauWeb.Pins.pin_ceremony_trace"], events := ceremonyEvents },
  { decls := ["TauWeb.Pins.rescue_pin_not_reused_across_boots"], events := reuseEvents },
  { decls := ["TauWeb.Pins.connection_before_fill_refused"], events := beforeFillEvents },
  { decls := ["TauWeb.Pins.installed_pin_from_model_text_refused"], events := modelTextEvents,
    pair := some (.refused, "TauWeb.Pins.installed_pin_from_model_text_admitted") },
  { decls := ["TauWeb.Pins.installed_pin_from_model_text_admitted"], events := modelTextEvents,
    params := anySource,
    pair := some (.admitted, "TauWeb.Pins.installed_pin_from_model_text_refused") },
  { decls := ["TauWeb.Pins.pin_halt_is_confirmation"], events := resumeProbeEvents },
  { decls := ["TauWeb.Pins.other_machine_pin_refused"], events := otherMachineEvents },
  { decls := ["TauWeb.Pins.mismatched_key_halts"], events := mismatchEvents } ]

def enumeration : List Trace :=
  (TauWeb.Pins.tracesUpTo TauWeb.Pins.bound).map fun es =>
    { decls := ["TauWeb.Pins.bounded"], events := es, start := TauWeb.Pins.start }

def module : Module :=
  let boundDecl := "TauWeb.Pins.bound"
  let bound := Json.mkObj [
    ("declaration", boundDecl), ("events", toJson TauWeb.Pins.bound),
    ("alphabet", Json.arr (TauWeb.Pins.alphabet.map eventJson).toArray),
    ("start", knowledgeJson TauWeb.Pins.start)]
  let traces := witnesses ++ enumeration
  { name := "pins", ns := `TauWeb.Pins,
    text := fileText "pins" `TauWeb.Pins bound (witnesses.map (·.json))
      (enumeration.map (·.json)),
    named := traces.flatMap (·.decls),
    refs := boundDecl :: traces.filterMap fun t => t.pair.map (·.2) }

end Pins

def modules : List Module :=
  [allocationModule, Declaration.module, Relay.module, Dispatch.module, Pins.module]

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
