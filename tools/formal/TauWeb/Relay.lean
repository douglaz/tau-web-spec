import TauWeb.Req
/-! Module 3, relay admission (ADR-0032's inventory): `CHN-15`, `CHN-16`, `CHN-16a` and
`relay-protocol-v1.md`.

The handshake is a state machine in which `authAccepted` — step 3's checks all passed — is a
different phase from `okSent`, which the relay reaches only once the dial has returned. The two
orderings `relay-protocol-v1.md` separated on 2026-09-16 are therefore two theorems over every
trace: nothing is dialed before the AUTH is accepted, and no application byte is forwarded
before OK. `Params` lists the rule that fix made, a field so that removing it is a one-token
change; `dial_before_auth_refused` and `dial_before_auth_admitted` are its pair.

Step 3 is `admit`, a total function returning the protocol's own refusal reasons in the
protocol's order, so a relay cannot answer `pass` for what the shape refused, nor reach the
pacing cap on a destination the record does not carry.

The destination is a pipeline — parse, normalize, classify, dial — and each stage's output is
the next one's argument type. The dialer's argument is `Admitted`, the classified numeric
address: `Host` has a case for a name and `Admitted` has none, so a hostname cannot be passed to
it, and the connection classifies once, so there is no second resolution inside it.

`CHN-16a`'s classification tables are an assumption parameter (`Tables`) and never data this
module owns, because "The implementation pins the IANA special-purpose address tables used for
classification and treats their updates as reviewed policy updates" is not Lean's to carry. The
relay's resolver is an assumption for the same reason.

What the module omits: the bytes. A challenge is an ordinal and never 32 random ones; a
signature is the verifier's answer and never a BIP-340 tuple; a key is an ordinal and never key
material; `created_at` within `relay.auth_skew` is a flag, because a timer value never enters a
witness file (ADR-0032, "What it never carries"). Text is read as shapes rather than as bytes,
so the lexical rules — IDNA A-labels, RFC 5952 spelling, a port's leading zeros — are cases of
`Text` and not a grammar here, and an AUTH's destination tag arrives already parsed, so a tag
that does not parse is one the grammar refuses rather than one the checks see. The purchase and
revocation messages of `CHN-15` and `CHN-16` arrive with the paid relay and are not in v1: a pass
is what the checks read, and how it came to exist — including `CHN-16a` at registration — is
another module's. One connection resolves once, so `CHN-16a`'s retries and refreshed DNS results
have nothing here to re-check; a later connection runs `start` again.

The inventory's second trap for this module, a hostname re-entering the dialer after validation,
is retained as a type and a control rather than as a trace: `dial` takes `Admitted`, so no trace
in which the dialer receives a name can be written at all, and `tools/check-controls.sh` passes
one to it and requires the red. What the witness file carries of it is the positive side —
`admitted_name_dialed`, where the dialer is handed the resolver's answer and never the name. -/

namespace TauWeb.Relay

/-! ## The destination -/

/-- A DNS name, opaque: what a name spells is the resolver's business, and the checks read only
which answers it has. -/
abbrev DnsName := Nat

/-- The numeric families the grammar admits — "dotted decimal IPv4, or RFC 5952 IPv6 without
brackets" — and the IPv4-mapped IPv6 spelling `CHN-16a` names, which parses and normalizes onto
the IPv4 address it carries. -/
inductive Family
  | v4
  | v6
  | v4mapped
  deriving DecidableEq, Repr

/-- A numeric address: its family and an opaque value. The module owns no address arithmetic —
which addresses are outside public unicast is the pinned tables' answer, not data here. -/
structure Addr where
  family : Family
  value : Nat
  deriving DecidableEq, Repr

/-- Normalization, stage two, before any classification: the IPv4-mapped spelling becomes the
IPv4 address it carries, so that one address meets the tables under one spelling. `CHN-16a`
refuses its list "including metadata endpoints, IPv4-mapped IPv6 and alternate numeric spellings
after normalization". -/
def Addr.normalize (a : Addr) : Addr :=
  match a.family with
  | .v4mapped => { a with family := .v4 }
  | _ => a

/-- What the host field of the path parses to. Nothing else: a name, or a numeric address. -/
inductive Host
  | dns (n : DnsName)
  | numeric (a : Addr)
  deriving DecidableEq, Repr

def Host.normalize : Host → Host
  | .dns n => .dns n
  | .numeric a => .numeric a.normalize

/-- The host field as it arrives, in the shapes the grammar meets rather than as bytes: a
lowercase A-label name with no trailing dot, a numeric address in its family's canonical text
form, or one of the forms "Nothing else: no percent-decoding, no scope identifiers, no alternate
numeric spellings" names. An alternate spelling carries the address it spells, so refusing it is
a statement about an address the tables would otherwise admit. -/
inductive Text
  | name (n : DnsName)
  | canonical (a : Addr)
  | percentEncoded
  | scoped
  | alternateSpelling (a : Addr)
  | nonCanonicalName (n : DnsName)
  deriving DecidableEq, Repr

/-- The destination the path names: `wss://<relay>/v1/tcp/<host>/<port>`. -/
structure Destination where
  host : Host
  port : Nat
  deriving DecidableEq, Repr

def Destination.normalize (d : Destination) : Destination := { d with host := d.host.normalize }

/-- The path as it arrives. -/
structure Path where
  host : Text
  port : Nat
  deriving DecidableEq, Repr

/-- The host field's parse. Only the two admitted shapes yield a host; every other form is
refused here, which is what "Unknown address forms fail closed" (`CHN-16a`) means at this stage.
No wildcard: a shape the note adds without a case here does not build. -/
@[req "CHN-16a"] def parseHost : Text → Option Host
  | .name n => some (.dns n)
  | .canonical a => some (.numeric a)
  | .percentEncoded => none
  | .scoped => none
  | .alternateSpelling _ => none
  | .nonCanonicalName _ => none

/-- Stage one: "One grammar, so the authorization check and the dialer cannot parse the same
string differently." A host outside the two shapes and a port outside 1–65535 are both
"Anything that does not parse", refused before any other check. -/
@[req "CHN-16a"] def parse (p : Path) : Option Destination :=
  match parseHost p.host with
  | some h => if 0 < p.port && p.port < 65536 then some ⟨h, p.port⟩ else none
  | none => none

/-- Every form outside the two the grammar admits is refused, whatever address it spells: a
percent-encoded byte, a scope identifier, a name the A-label rules refuse, and an alternate
numeric spelling of an address whose canonical form the tables would admit. -/
@[req "CHN-16a"] theorem unknown_form_refused (a : Addr) (n : DnsName) :
    parseHost .percentEncoded = none ∧ parseHost .scoped = none ∧
    parseHost (.alternateSpelling a) = none ∧ parseHost (.nonCanonicalName n) = none :=
  ⟨rfl, rfl, rfl, rfl⟩

/-- A host that does not parse is refused before any other check: there is no destination for a
check to read, whatever the port. -/
@[req "CHN-16a"] theorem parse_fails_closed (t : Text) (h : parseHost t = none) (port : Nat) :
    parse ⟨t, port⟩ = none := by cases t <;> simp_all [parse, parseHost]

/-- What the module takes as given rather than owning (ADR-0032, "What is not Lean's to carry
enters as a hypothesis, never an axiom"). `special` is `CHN-16a`'s pinned classification —
"The implementation pins the IANA special-purpose address tables used for classification and
treats their updates as reviewed policy updates" — answering whether a normalized address is
outside public unicast; `ownAddress` is "every address belonging to the relay host itself,
including its public IPs"; `resolve` is the relay's resolver, whose answers are the network's.
Every theorem here quantifies over all three, so none of them is a table this module decides. -/
structure Tables where
  special : Addr → Bool
  ownAddress : Addr → Bool
  resolve : DnsName → List Addr

/-- `CHN-16a` on one address: the relay "accepts only public unicast destinations", so an
address the tables name is refused and so is one of the relay host's own. The normal form is
required rather than computed here, so an address that has not been through stage two never
reaches a table and cannot be classified under a second spelling. -/
@[req "CHN-16a"] def admitsAddr (t : Tables) (a : Addr) : Bool :=
  a.normalize == a && !t.special a && !t.ownAddress a

/-- The classified numeric address: what stage three returns and the only thing the dialer
takes. A structure with one member of type `Addr` and never an alias for it, so the dialer's
argument is by type the classified address — `Host` has a case for a name, this has none. -/
structure Admitted where
  addr : Addr
  deriving DecidableEq, Repr

/-- A name's answers, classified as a set: "reject the request if **any** answer is forbidden",
so one forbidden answer refuses the whole request, and otherwise the first is carried forward —
"v1 dials the first admitted answer and refuses if any answer is forbidden". A name with no
answer has nothing to dial and is refused like a forbidden one. -/
@[req "CHN-16a"] def admitAnswers (t : Tables) : List Addr → Option Admitted
  | [] => none
  | a :: rest => if admitsAddr t a && rest.all (admitsAddr t) then some ⟨a⟩ else none

/-- Stage three. For a numeric destination the address itself; for a DNS destination, "resolve
through the relay's resolver, reject the request if **any** answer is forbidden, and connect to
the checked numeric address without a second resolution inside the dialer" — so the resolver is
read once, here, and its result is what the connection carries from then on. -/
@[req "CHN-16a"] def classify (t : Tables) : Host → Option Admitted
  | .numeric a => if admitsAddr t a then some ⟨a⟩ else none
  | .dns n => admitAnswers t (t.resolve n)

/-- Stage four. The dialer's argument is the classified address and nothing else — no case for a
name, no member one could ride in on — so "without a second resolution inside the dialer" is a
type rather than a discipline. What a dial does on the wire is the network's; the module records
which address the dialer was handed. -/
@[req "CHN-16a"] def dial (x : Admitted) : Addr := x.addr

theorem admitAnswers_admits (t : Tables) (l : List Addr) (x : Admitted)
    (h : admitAnswers t l = some x) : admitsAddr t x.addr = true := by
  cases l with
  | nil => exact nomatch h
  | cons a rest =>
    simp only [admitAnswers] at h
    split at h
    · rename_i hok
      simp only [Bool.and_eq_true] at hok
      injection h with h
      subst h
      exact hok.1
    · exact nomatch h

/-- Whatever the dialer is handed, `CHN-16a` admitted: stage three is the only source of an
`Admitted`, for a numeric destination and for a name alike. -/
@[req "CHN-16a"] theorem classify_admits (t : Tables) (h : Host) (x : Admitted)
    (hc : classify t h = some x) : admitsAddr t (dial x) = true := by
  cases h with
  | numeric a =>
    simp only [classify] at hc
    split at hc
    · rename_i hadm
      injection hc with hc
      subst hc
      exact hadm
    · exact nomatch hc
  | dns n => exact admitAnswers_admits t (t.resolve n) x hc

/-- For a DNS destination, one forbidden answer refuses the whole request: nothing is classified,
so nothing reaches the dialer — never the admitted answers beside it. -/
@[req "CHN-16a"] theorem forbidden_answer_refuses (t : Tables) (n : DnsName) (a : Addr)
    (hmem : a ∈ t.resolve n) (hbad : admitsAddr t a = false) : classify t (.dns n) = none := by
  show admitAnswers t (t.resolve n) = none
  generalize hl : t.resolve n = l
  rw [hl] at hmem
  cases l with
  | nil => rfl
  | cons b rest =>
    simp only [admitAnswers]
    split
    · rename_i hok
      exfalso
      simp only [Bool.and_eq_true, List.all_eq_true] at hok
      rcases List.mem_cons.mp hmem with rfl | hmem'
      · rw [hok.1] at hbad; exact Bool.noConfusion hbad
      · rw [hok.2 a hmem'] at hbad; exact Bool.noConfusion hbad
    · rfl

/-- An admitted address is its own normal form: the classification runs after stage two, so an
address cannot be admitted under a spelling the tables never saw. -/
@[req "CHN-16a"] theorem admitted_normalized (t : Tables) (a : Addr)
    (h : admitsAddr t a = true) : a.normalize = a := by
  simp only [admitsAddr, Bool.and_eq_true, beq_iff_eq] at h
  exact h.1.1

/-- The IPv4-mapped bypass, closed: a mapped spelling of an address the tables name is
normalized onto that address and refused with it. -/
@[req "CHN-16a"] theorem mapped_forbidden_refused (t : Tables) (v : Nat)
    (h : t.special ⟨.v4, v⟩ = true) :
    classify t (Host.numeric ⟨.v4mapped, v⟩).normalize = none := by
  simp [Host.normalize, Addr.normalize, classify, admitsAddr, h]

/-! ## The pass -/

/-- The relay key a pass is bound to: `CHN-15`'s "a **relay key** the browser derives from the
seed (`STA-22`), one per purchase". An ordinal here and never key material — the checks read
which key signed, never its bytes. -/
abbrev Key := Nat

/-- A pass as the checks read it. `CHN-16` makes the recorded set a member and not a second
store: "A pass's **destination record is the authorization**, not a separate system." It is a
list of hosts and not of host-and-port pairs, because "A recorded destination is reachable on
any port, not on the SSH port alone". `live` is "unexpired and not revoked" — the expiry is a
timer, so what the checks read is the flag. `paced` is "the pass's pacing and window cap", keyed
at the host like the record: `CHN-16` makes pacing "the same per-target limit" and "what makes a
wide port range useless as a scanning service", which a budget per host and port would hand back
one port at a time. -/
structure Pass where
  hosts : List Host
  live : Bool
  paced : Host → Bool

/-- `CHN-16`'s check: the record is read at the host. -/
@[req "CHN-16"] def recorded (p : Pass) (d : Destination) : Bool := p.hosts.contains d.host

/-- "A recorded destination is reachable on any port, not on the SSH port alone" (`CHN-16`): two
destinations differing only in their port are recorded or unrecorded together, so a relay cannot
forward one port of a recorded host and refuse the rest — the check that cannot fail `ARC-41`
prices. -/
@[req "CHN-16"] theorem recorded_any_port (p : Pass) (h : Host) (m n : Nat) :
    recorded p ⟨h, m⟩ = recorded p ⟨h, n⟩ := rfl

/-- The relay as step 3 reads it: which relay this is, since the AUTH's relay tag must name it,
and the pass bound to a key, if the key has one. -/
structure Relay where
  url : Nat
  pass : Key → Option Pass

/-- The AUTH frame of step 2, in what the checks read of it. `destinationTag` is the tag parsed
and normalized by the same two stages as the path, so that comparing it against the destination
is "The destination tag must equal the URL path" and not a second grammar. `fresh` is
`created_at` within `relay.auth_skew` and `signature` is whether BIP-340 over the NIP-01 event id
verifies: a timer and bytes, so both enter as the verifier's answer rather than as values. -/
structure Auth where
  kind : Nat
  relayTag : Nat
  destinationTag : Destination
  fresh : Bool
  key : Key
  challenge : Nat
  signature : Bool
  deriving DecidableEq, Repr

/-- The reasons `{"ok": false, "reason": "<auth|pass|destination|address|pace>"}` carries, and
`dial`, the one "A dial that fails after the checks passed" sends. -/
inductive Reason
  | auth
  | pass
  | destination
  | address
  | pace
  | dial
  deriving DecidableEq, Repr

/-- Step 3's verdict: the checks passed, or the reason the relay answers with before closing. -/
inductive Verdict
  | accepted
  | refused (r : Reason)
  deriving DecidableEq, Repr

/-- Step 3, in the protocol's order: "the event shape — kind 22242, the relay tag naming this
relay, `created_at` within skew, one destination tag equal to the path — then signature and
challenge match; the key has a pass that is unexpired and not revoked; the destination is in
that pass's recorded set (`CHN-16`: the record *is* the authorization); `CHN-16a` admits the
address; the pass's pacing and window cap allow a dial now". Total, and the order is the
function's, so no reason can be answered out of its place. The classification is the one the
connection made when it opened, read here and never re-run. -/
@[req "CHN-15"] def admit (r : Relay) (challenge : Nat) (cls : Option Admitted)
    (d : Destination) (a : Auth) : Verdict :=
  if !(a.kind == 22242 && a.relayTag == r.url && a.fresh && a.destinationTag == d) then
    .refused .auth
  else if !(a.signature && a.challenge == challenge) then .refused .auth
  else match r.pass a.key with
    | none => .refused .pass
    | some p =>
      if !p.live then .refused .pass
      else if !recorded p d then .refused .destination
      else if cls.isNone then .refused .address
      else if !p.paced d.host then .refused .pace
      else .accepted

/-- A replayed AUTH fails on its challenge: "A replayed AUTH fails at step 3 because its
challenge is not this connection's". Whatever else is true of the frame — a signature that
verifies, a pass that is live, a destination the record carries — a challenge that is not this
connection's is refused with `auth`, before the pass is read. -/
@[req "CHN-15"] theorem replay_refused (r : Relay) (challenge : Nat) (cls : Option Admitted)
    (d : Destination) (a : Auth) (h : a.challenge ≠ challenge) :
    admit r challenge cls d a = .refused .auth := by
  have hb : (a.challenge == challenge) = false := by
    simp only [beq_eq_false_iff_ne]; exact h
  unfold admit
  simp [hb]

/-- `CHN-16`: "A pass's **destination record is the authorization**, not a separate system." A
destination the pass does not record is refused with `destination`, whatever the address
classification says and whatever the pacing cap has left. -/
@[req "CHN-16"] theorem unrecorded_destination_refused (r : Relay) (challenge : Nat)
    (cls : Option Admitted) (d : Destination) (a : Auth) (p : Pass)
    (hshape : (a.kind == 22242 && a.relayTag == r.url && a.fresh && a.destinationTag == d) = true)
    (hsig : (a.signature && a.challenge == challenge) = true)
    (hp : r.pass a.key = some p) (hlive : p.live = true) (hrec : recorded p d = false) :
    admit r challenge cls d a = .refused .destination := by
  simp [admit, hshape, hsig, hp, hlive, hrec]

/-! ## The handshake -/

/-- The connection's phase. `authAccepted` and `okSent` are two phases with the dial between
them: "OK is sent *after* the dial succeeds", so "OK means 'authorized and connected'", and the
two orderings `relay-protocol-v1.md` separated are two properties of this machine. -/
inductive Phase
  | opened
  | authAccepted
  | okSent
  | closed
  deriving DecidableEq, Repr

/-- The connection. `classified` is the destination pipeline's output for the path, computed
once when the connection opens: the only address the dialer is ever handed. `accepted` and
`okSent` are whether this connection's AUTH was accepted and whether OK went out, kept past the
close, since the two ordering properties are about the trace and not about the phase a dial or a
frame happens to find. -/
structure Connection where
  challenge : Nat
  destination : Option Destination
  classified : Option Admitted
  phase : Phase
  accepted : Bool
  okSent : Bool
  /-- The addresses the dialer was handed, newest first. -/
  dialed : List Addr
  /-- Application bytes forwarded. -/
  forwarded : Nat
  refused : Option Reason
  deriving DecidableEq, Repr

/-- The connection as the relay opens it: a challenge "fresh per connection and never reused",
an ordinal here and never bytes; the path parsed and normalized; and its address classified.
"Anything that does not parse is refused before any other check, with close code 1008" — such a
connection opens closed and carries no reason, since the reasons are step 3's. -/
@[req "CHN-15"] def start (t : Tables) (challenge : Nat) (p : Path) : Connection :=
  match parse p with
  | none =>
    { challenge, destination := none, classified := none, phase := .closed,
      accepted := false, okSent := false, dialed := [], forwarded := 0, refused := none }
  | some d =>
    let d := d.normalize
    { challenge, destination := some d, classified := classify t d.host, phase := .opened,
      accepted := false, okSent := false, dialed := [], forwarded := 0, refused := none }

inductive Event
  /-- The browser's AUTH frame, step 2. -/
  | auth (a : Auth)
  /-- The relay dials; `up` is whether the TCP connection came up. -/
  | dial (up : Bool)
  /-- A binary frame carrying raw TCP. -/
  | appFrame
  deriving DecidableEq, Repr

/-- The rule the 2026-09-16 fix made two invariants out of one. `relay-protocol-v1.md`: "They
are two invariants, not one: OK is sent *after* the dial succeeds, so 'no dial before OK' — the
shorthand this section carried until 2026-09-16 — named an order the protocol does not have, and
a relay and a test could each satisfy it while enforcing different things." With the field a
dial requires the AUTH accepted. Without it the only order named is against OK, which the relay
sends after the dial: the two phases collapse into one gate, and a relay may dial before it has
authorized anything. One field, so that removing it is a one-token change;
`dial_before_auth_refused` and `dial_before_auth_admitted` are its pair. -/
@[req "CHN-15"] structure Params where
  dialRequiresAuthAccepted : Bool
  deriving DecidableEq, Repr

/-- The rule as it stands. -/
@[req "CHN-15"] def current : Params := { dialRequiresAuthAccepted := true }

/-- Whether a dial is admitted now. Under the rule, from `authAccepted` alone. Under the
shorthand, the guard is the shorthand's own words — OK has not gone out — on a connection still
open; every dial satisfies it, because the relay sends OK after the dial, which is why "no dial
before OK" names an order the protocol does not have. -/
@[req "CHN-15"] def dialAdmitted (p : Params) (s : Connection) : Bool :=
  if p.dialRequiresAuthAccepted then s.phase == .authAccepted
  else !s.okSent && s.phase != .closed

/-- One event. `auth` is step 3, run once from the opened connection: the checks run in `admit`'s
order and the connection either accepts the AUTH or closes with the reason. `dial` hands the
dialer the classified address, and "once the TCP connection is up sends one text frame
`{"ok": true}`", while "A dial that fails after the checks passed" closes with `dial` and no OK.
A binary frame is the TCP stream only after OK; before it, "a binary frame before it, closes the
connection with 1002" and nothing is forwarded. -/
@[req "CHN-15"] def step (p : Params) (r : Relay) (s : Connection) : Event → Connection
  | .auth a =>
    if s.phase == .opened then
      match s.destination with
      | some d =>
        match admit r s.challenge s.classified d a with
        | .accepted => { s with phase := .authAccepted, accepted := true }
        | .refused reason => { s with phase := .closed, refused := some reason }
      | none => s
    else s
  | .dial up =>
    if dialAdmitted p s then
      match s.classified with
      | some x =>
        if up then { s with dialed := dial x :: s.dialed, phase := .okSent, okSent := true }
        else { s with dialed := dial x :: s.dialed, phase := .closed, refused := some .dial }
      | none => s
    else s
  | .appFrame =>
    if s.phase == .okSent then { s with forwarded := s.forwarded + 1 }
    else { s with phase := .closed }

def run (p : Params) (r : Relay) (s : Connection) : List Event → Connection
  | [] => s
  | e :: es => run p r (step p r s e) es

/-! ## Over every trace -/

/-- The classification is made once, when the connection opens: no step re-reads the resolver or
the tables, which is "without a second resolution inside the dialer" as a property of the machine
and not only of the dialer's type. -/
theorem step_classified (p : Params) (r : Relay) (s : Connection) (e : Event) :
    (step p r s e).classified = s.classified := by
  cases e with
  | auth a =>
    simp only [step]; split
    · split
      · split <;> rfl
      · rfl
    · rfl
  | dial up =>
    simp only [step]; split
    · split
      · split <;> rfl
      · rfl
    · rfl
  | appFrame => simp only [step]; split <;> rfl

theorem run_classified (p : Params) (r : Relay) (s : Connection) (es : List Event) :
    (run p r s es).classified = s.classified := by
  induction es generalizing s with
  | nil => rfl
  | cons e es ih => simp only [run]; rw [ih, step_classified]

theorem start_classified (t : Tables) (challenge : Nat) (path : Path) (x : Admitted)
    (h : (start t challenge path).classified = some x) : ∃ hst, classify t hst = some x := by
  unfold start at h
  split at h
  · exact nomatch h
  · exact ⟨_, h⟩

/-- What one step preserves: the phases agree with what the connection has done — `authAccepted`
means the AUTH was accepted, `okSent` means OK went out; nothing was dialed unless the AUTH was
accepted, under the rule; nothing was forwarded unless OK went out; and every address the dialer
was handed is the one the connection classified when it opened. -/
def Inv (p : Params) (s : Connection) : Prop :=
  (s.phase = .authAccepted → s.accepted = true) ∧
  (s.phase = .okSent → s.okSent = true) ∧
  (p.dialRequiresAuthAccepted = true → s.dialed ≠ [] → s.accepted = true) ∧
  (s.forwarded ≠ 0 → s.okSent = true) ∧
  (∀ a ∈ s.dialed, s.classified = some ⟨a⟩)

/-- Under the rule, a dial admitted now found the AUTH already accepted. -/
theorem accepted_of_dialAdmitted (p : Params) (hp : p.dialRequiresAuthAccepted = true)
    (s : Connection) (hpa : s.phase = .authAccepted → s.accepted = true)
    (hadm : dialAdmitted p s = true) : s.accepted = true := by
  unfold dialAdmitted at hadm
  rw [if_pos hp] at hadm
  exact hpa (by simpa only [beq_iff_eq] using hadm)

theorem inv_step (p : Params) (r : Relay) (s : Connection) (hs : Inv p s) (e : Event) :
    Inv p (step p r s e) := by
  obtain ⟨hpa, hpo, hd, hf, hc⟩ := hs
  cases e with
  | auth a =>
    simp only [step]
    split
    · split
      · split
        · exact ⟨fun _ => rfl, fun h => by simp at h, fun _ _ => rfl, hf, hc⟩
        · exact ⟨fun h => by simp at h, fun h => by simp at h, hd, hf, hc⟩
      · exact ⟨hpa, hpo, hd, hf, hc⟩
    · exact ⟨hpa, hpo, hd, hf, hc⟩
  | dial up =>
    simp only [step]
    split
    · rename_i hadm
      split
      · rename_i x hx
        have hdial : ∀ b ∈ dial x :: s.dialed, s.classified = some ⟨b⟩ := by
          intro b hb
          rcases List.mem_cons.mp hb with rfl | hb
          · exact hx
          · exact hc b hb
        split
        · exact ⟨fun h => by simp at h, fun _ => rfl,
                 fun hp _ => accepted_of_dialAdmitted p hp s hpa hadm, fun _ => rfl, hdial⟩
        · exact ⟨fun h => by simp at h, fun h => by simp at h,
                 fun hp _ => accepted_of_dialAdmitted p hp s hpa hadm, hf, hdial⟩
      · exact ⟨hpa, hpo, hd, hf, hc⟩
    · exact ⟨hpa, hpo, hd, hf, hc⟩
  | appFrame =>
    simp only [step]
    split
    · rename_i hok
      simp only [beq_iff_eq] at hok
      exact ⟨hpa, hpo, hd, fun _ => hpo hok, hc⟩
    · exact ⟨fun h => by simp at h, fun h => by simp at h, hd, hf, hc⟩

theorem inv_run (p : Params) (r : Relay) (s : Connection) (hs : Inv p s) (es : List Event) :
    Inv p (run p r s es) := by
  induction es generalizing s with
  | nil => exact hs
  | cons e es ih => exact ih (step p r s e) (inv_step p r s hs e)

theorem inv_start (p : Params) (t : Tables) (challenge : Nat) (path : Path) :
    Inv p (start t challenge path) := by
  unfold start
  split <;>
    exact ⟨fun h => by simp at h, fun h => by simp at h, fun _ h => absurd rfl h,
           fun h => absurd rfl h, fun _ h => nomatch h⟩

/-- **Nothing is dialed before the AUTH is accepted** — the first of the two orderings
`relay-protocol-v1.md` separated. Over every trace, every path, every relay and every table: a
connection whose AUTH was never accepted handed the dialer nothing. -/
@[req "CHN-15"] theorem no_dial_before_auth (p : Params) (hp : p.dialRequiresAuthAccepted = true)
    (t : Tables) (r : Relay) (challenge : Nat) (path : Path) (es : List Event)
    (h : (run p r (start t challenge path) es).accepted = false) :
    (run p r (start t challenge path) es).dialed = [] := by
  have hinv := (inv_run p r _ (inv_start p t challenge path) es).2.2.1 hp
  match hdl : (run p r (start t challenge path) es).dialed with
  | [] => rfl
  | x :: xs =>
    rw [hinv (by rw [hdl]; simp)] at h
    exact Bool.noConfusion h

/-- **No application byte is forwarded before OK** — the second ordering. Over every trace, every
path, every relay and every table: a connection that never sent OK forwarded nothing. The two are
two theorems because "OK is sent *after* the dial succeeds": the first names an order against the
AUTH, which the shorthand did not, and it needs no guard to hold. -/
@[req "CHN-15"] theorem no_bytes_before_ok (p : Params) (t : Tables) (r : Relay)
    (challenge : Nat) (path : Path) (es : List Event)
    (h : (run p r (start t challenge path) es).okSent = false) :
    (run p r (start t challenge path) es).forwarded = 0 := by
  have hinv := (inv_run p r _ (inv_start p t challenge path) es).2.2.2.1
  match hfw : (run p r (start t challenge path) es).forwarded with
  | 0 => rfl
  | n + 1 =>
    rw [hinv (by rw [hfw]; simp)] at h
    exact Bool.noConfusion h

/-- The pipeline, over every trace: every address the dialer was handed is one `CHN-16a`
admitted. With `forbidden_answer_refuses` this is the DNS rule whole — for a name, any forbidden
answer refuses the request, and the dialer receives only an admitted address. -/
@[req "CHN-16a"] theorem dialed_admitted (p : Params) (t : Tables) (r : Relay) (challenge : Nat)
    (path : Path) (es : List Event) :
    ∀ a ∈ (run p r (start t challenge path) es).dialed, admitsAddr t a = true := by
  intro a ha
  have hcl := (inv_run p r _ (inv_start p t challenge path) es).2.2.2.2 a ha
  rw [run_classified] at hcl
  obtain ⟨hst, hcx⟩ := start_classified t challenge path ⟨a⟩ hcl
  exact classify_admits t hst ⟨a⟩ hcx

/-! ## The witnesses, decided -/

/-- The classification tables the witnesses run under, as data, so that the witness file can
carry what each trace assumed. The module's functions take `Tables`, of which this is one value:
the pinned registries stay an assumption and never become a table this module owns. -/
structure Facts where
  special : List Addr
  own : List Addr
  answers : List (DnsName × List Addr)
  deriving DecidableEq, Repr

def Facts.tables (f : Facts) : Tables :=
  { special := f.special.contains, ownAddress := f.own.contains,
    resolve := fun n => (f.answers.lookup n).getD [] }

/-! Each witness's events are one named list and each its own named connection, so that the theorem
and the emitter (`Witnesses.lean`) run the same trace. -/

/-- Four addresses the tables classify: one the operator recorded, a second the pass does not
carry, the relay host's own, and one the special-purpose registries name. The values are
opaque. -/
def recordedAddr : Addr := ⟨.v4, 1⟩
def strangerAddr : Addr := ⟨.v4, 2⟩
def relayOwnAddr : Addr := ⟨.v4, 3⟩
def loopbackAddr : Addr := ⟨.v4, 4⟩

/-- A name whose only answer is admitted, and one that also answers with the loopback address. -/
def cleanName : DnsName := 1
def mixedName : DnsName := 2

def facts : Facts :=
  { special := [loopbackAddr], own := [relayOwnAddr],
    answers := [(cleanName, [recordedAddr]), (mixedName, [recordedAddr, loopbackAddr])] }

def tables : Tables := facts.tables

def sshPort : Nat := 22

def recordedPath : Path := ⟨.canonical recordedAddr, sshPort⟩
def recordedDest : Destination := ⟨.numeric recordedAddr, sshPort⟩
def strangerPath : Path := ⟨.canonical strangerAddr, sshPort⟩
def strangerDest : Destination := ⟨.numeric strangerAddr, sshPort⟩
def cleanPath : Path := ⟨.name cleanName, sshPort⟩
def cleanDest : Destination := ⟨.dns cleanName, sshPort⟩
def mixedPath : Path := ⟨.name mixedName, sshPort⟩
def mixedDest : Destination := ⟨.dns mixedName, sshPort⟩
/-- The loopback address in its IPv4-mapped spelling. -/
def mappedPath : Path := ⟨.canonical ⟨.v4mapped, loopbackAddr.value⟩, sshPort⟩
def mappedDest : Destination := ⟨.numeric loopbackAddr, sshPort⟩
/-- An alternate numeric spelling of the recorded address. -/
def alternatePath : Path := ⟨.alternateSpelling recordedAddr, sshPort⟩
/-- The recorded address on a port outside 1-65535. -/
def badPortPath : Path := ⟨.canonical recordedAddr, 0⟩

def relayUrl : Nat := 1
def operatorKey : Key := 1
def strangerKey : Key := 2

/-- The destinations the publisher recorded by hand — there is no purchase flow in the first
stage (`STG-18`) — including, wrongly, the loopback address: "Private proxying is not a
first-stage exception: the hand-recorded relay key obeys the same rule." -/
def recordedHosts : List Host :=
  [.numeric recordedAddr, .dns cleanName, .dns mixedName, .numeric loopbackAddr]

def pass : Pass := { hosts := recordedHosts, live := true, paced := fun _ => true }
def pacedOutPass : Pass := { pass with paced := fun _ => false }

def publisherRelay : Relay :=
  { url := relayUrl, pass := fun k => if k == operatorKey then some pass else none }

/-- The same relay with the pass's window cap spent. -/
def pacedOutRelay : Relay :=
  { publisherRelay with pass := fun k => if k == operatorKey then some pacedOutPass else none }

def challenge0 : Nat := 0
def challenge1 : Nat := 1

/-- The AUTH the browser signs for the connection carrying the first challenge. -/
def recordedAuth : Auth :=
  { kind := 22242, relayTag := relayUrl, destinationTag := recordedDest, fresh := true,
    key := operatorKey, challenge := challenge0, signature := true }

def strangerKeyAuth : Auth := { recordedAuth with key := strangerKey }
def strangerDestAuth : Auth := { recordedAuth with destinationTag := strangerDest }
def cleanAuth : Auth := { recordedAuth with destinationTag := cleanDest }
def mixedAuth : Auth := { recordedAuth with destinationTag := mixedDest }
def mappedAuth : Auth := { recordedAuth with destinationTag := mappedDest }

/-- The connection to the recorded destination, its challenge fresh. -/
def recordedConnection : Connection := start tables challenge0 recordedPath
/-- The next connection, with the next challenge: where a replayed frame arrives. -/
def nextConnection : Connection := start tables challenge1 recordedPath
def strangerConnection : Connection := start tables challenge0 strangerPath
def cleanConnection : Connection := start tables challenge0 cleanPath
def mixedConnection : Connection := start tables challenge0 mixedPath
def mappedConnection : Connection := start tables challenge0 mappedPath
def alternateConnection : Connection := start tables challenge0 alternatePath
def badPortConnection : Connection := start tables challenge0 badPortPath

def authEvents : List Event := [.auth recordedAuth]
def handshakeEvents : List Event := [.auth recordedAuth, .dial true, .appFrame]
def dialFirstEvents : List Event := [.dial true, .auth recordedAuth]
def strangerKeyEvents : List Event := [.auth strangerKeyAuth]
def strangerDestEvents : List Event := [.auth strangerDestAuth]
def cleanNameEvents : List Event := [.auth cleanAuth, .dial true]
def mixedEvents : List Event := [.auth mixedAuth]
def mappedEvents : List Event := [.auth mappedAuth]
def bytesBeforeOkEvents : List Event := [.auth recordedAuth, .appFrame]
def failedDialEvents : List Event := [.auth recordedAuth, .dial false]

/-- The handshake, whole: the AUTH accepted, the dial made to the recorded address, OK sent, one
application byte forwarded. The admission is not safe by refusing everything. -/
@[req "CHN-15"] theorem handshake_ok :
    let s := run current publisherRelay recordedConnection handshakeEvents
    s.phase = .okSent ∧ s.accepted = true ∧ s.okSent = true ∧ s.dialed = [recordedAddr] ∧
    s.forwarded = 1 ∧ s.refused = none := by decide +kernel

/-- The first ordering, kept: a dial attempted before the AUTH hands the dialer nothing, and the
AUTH that follows is accepted on the connection the refused dial did not disturb. -/
@[req "CHN-15"] theorem dial_before_auth_refused :
    let s := run current publisherRelay recordedConnection dialFirstEvents
    s.dialed = [] ∧ s.okSent = false ∧ s.phase = .authAccepted ∧ s.accepted = true := by
  decide +kernel

/-- The shorthand, as the section read until 2026-09-16: with "no dial before OK" the only order
named, the relay dials the address and sends OK without ever having accepted an AUTH — the trap
the inventory retains, since a relay and a test could each satisfy the shorthand while enforcing
different things. -/
@[req "CHN-15"] theorem dial_before_auth_admitted :
    let s := run { current with dialRequiresAuthAccepted := false } publisherRelay
      recordedConnection dialFirstEvents
    s.dialed = [recordedAddr] ∧ s.okSent = true ∧ s.accepted = false := by decide +kernel

/-- A replayed signature: the frame is genuinely signed and every other check would pass, and on
the next connection its challenge is not this one's. Refused with `auth`, nothing dialed. -/
@[req "CHN-15"] theorem replayed_signature_refused :
    let s := run current publisherRelay nextConnection authEvents
    s.refused = some .auth ∧ s.dialed = [] ∧ s.accepted = false := by decide +kernel

/-- A destination tag that is not the path's: "The destination tag must equal the URL path; a
mismatch is refused", with `auth`, before the pass is read. The frame is the one the operator
signs for its own destination, arriving on the connection to another. -/
@[req "CHN-15"] theorem mismatched_tag_refused :
    let s := run current publisherRelay recordedConnection strangerDestEvents
    s.refused = some .auth ∧ s.dialed = [] := by decide +kernel

/-- An unknown key: no pass, so `pass`, and nothing dialed. -/
@[req "CHN-15"] theorem unknown_key_refused :
    let s := run current publisherRelay recordedConnection strangerKeyEvents
    s.refused = some .pass ∧ s.dialed = [] := by decide +kernel

/-- An undeclared destination: a public unicast address `CHN-16a` admits and the pass does not
record. Refused with `destination` — the record is the authorization — and nothing dialed. -/
@[req "CHN-16"] theorem undeclared_destination_refused :
    let s := run current publisherRelay strangerConnection strangerDestEvents
    s.refused = some .destination ∧ s.dialed = [] := by decide +kernel

/-- A name every answer of which is admitted: "v1 dials the first admitted answer", and what the
dialer is handed is that answer and never the name. -/
@[req "CHN-16a"] theorem admitted_name_dialed :
    let s := run current publisherRelay cleanConnection cleanNameEvents
    s.classified = some ⟨recordedAddr⟩ ∧ s.dialed = [recordedAddr] ∧ s.okSent = true := by
  decide +kernel

/-- A name one of whose answers is forbidden: the whole request is refused with `address`, and
the admitted answer beside it is not dialed either. -/
@[req "CHN-16a"] theorem forbidden_answer_refused :
    let s := run current publisherRelay mixedConnection mixedEvents
    s.classified = none ∧ s.refused = some .address ∧ s.dialed = [] := by decide +kernel

/-- The address the publisher recorded by hand, in its IPv4-mapped spelling: normalized onto the
loopback address and refused with `address` on the outbound connection, though the record carries
it. -/
@[req "CHN-16a"] theorem mapped_loopback_refused :
    let s := run current publisherRelay mappedConnection mappedEvents
    s.destination = some mappedDest ∧ s.classified = none ∧ s.refused = some .address ∧
    s.dialed = [] := by decide +kernel

/-- The limits, applied: a pass whose pacing and window cap allow no dial now is refused with
`pace`, after the record has admitted the destination. -/
@[req "CHN-15"] theorem paced_out_refused :
    let s := run current pacedOutRelay recordedConnection authEvents
    s.refused = some .pace ∧ s.dialed = [] := by decide +kernel

/-- An alternate numeric spelling of the recorded address: it does not parse, so the connection
opens closed with no destination, before any other check and with no reason to send. -/
@[req "CHN-16a"] theorem alternate_spelling_closed :
    let s := run current publisherRelay alternateConnection authEvents
    s.destination = none ∧ s.phase = .closed ∧ s.refused = none ∧ s.dialed = [] := by
  decide +kernel

/-- A port outside 1-65535: the path does not parse either, so the connection opens closed in
the same way, before any other check. -/
@[req "CHN-16a"] theorem bad_port_closed :
    let s := run current publisherRelay badPortConnection authEvents
    s.destination = none ∧ s.phase = .closed ∧ s.dialed = [] := by decide +kernel

/-- The second ordering, kept: a binary frame after the AUTH is accepted and before OK closes the
connection and forwards nothing. -/
@[req "CHN-15"] theorem bytes_before_ok_closed :
    let s := run current publisherRelay recordedConnection bytesBeforeOkEvents
    s.forwarded = 0 ∧ s.okSent = false ∧ s.phase = .closed := by decide +kernel

/-- A dial that fails after the checks passed: the address was dialed, no OK went out, and the
connection closes with `dial`. OK is not the dial's permission but its result. -/
@[req "CHN-15"] theorem failed_dial_sends_no_ok :
    let s := run current publisherRelay recordedConnection failedDialEvents
    s.dialed = [recordedAddr] ∧ s.okSent = false ∧ s.refused = some .dial := by decide +kernel

/-! ## The bound -/

/-- The bound (`CONTEXT.md`): every trace of at most this many events over `alphabet`, from the
opened connection to the recorded destination. Stated once, here, for `bounded` and for the
witness file; beyond it is the theorems' statements, not the file's. -/
@[req "CHN-15"] def bound : Nat := 3

/-- The events the bounded enumeration draws from: the AUTH the browser signs, an AUTH under a
key with no pass, the dial's two outcomes, and a binary frame. -/
def alphabet : List Event :=
  [.auth recordedAuth, .auth strangerKeyAuth, .dial true, .dial false, .appFrame]

/-- Every trace of exactly `n` events over `alphabet`. -/
def tracesOf : Nat → List (List Event)
  | 0 => [[]]
  | n + 1 => (tracesOf n).flatMap fun es => alphabet.map (es ++ [·])

/-- Every trace of at most `n` events over `alphabet`, shortest first. -/
def tracesUpTo (n : Nat) : List (List Event) := (List.range (n + 1)).flatMap tracesOf

/-- The two orderings and the pipeline, decided within the bound: nothing dialed without the AUTH
accepted, nothing forwarded without OK sent, and every address the dialer was handed the one the
connection classified. -/
@[req "CHN-15"] theorem bounded :
    (tracesUpTo bound).all (fun es =>
      let s := run current publisherRelay recordedConnection es
      (s.dialed.isEmpty || s.accepted) && (s.forwarded == 0 || s.okSent) &&
      s.dialed.all (fun a => s.classified == some ⟨a⟩)) = true := by
  decide +kernel

end TauWeb.Relay
