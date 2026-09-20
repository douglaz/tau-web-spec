import TauWeb.Req
/-! Module 1, allocation (ADR-0032's inventory): `STA-22`, `STA-22a`, `STA-22b` and the index
rules of `credential-format-v1.md`.

The first clause carried is the credential format's role table (`STA-22a`): role number to
index family, which decides index sharing, and child-secret interpretation. The table is closed
— `row` is `none` outside the five roles — and its totality over those roles is decided.

The rest is the allocator as a trace. A `World` is the journal — harness knowledge: the seed
epoch, the derivation version, next-unused per family, the allocated entries with their
tombstones, and whether the seed was restored from a sheet or store — beside three things no
loss of the journal rewinds: the last sheet the operator exported, the fresh seeds generated
(entropy), and `issued`, every identity the trace has ever reserved, since a key derived from it
may be on a machine. The theorems are over every trace from `init`; the witnesses are the
inventory's retained traps, decided.

`Params` lists the guard the dated amendment added, a field so that removing it is a one-token
change (`tools/check-controls.sh` flips it and expects exactly one witness red).

What the module omits: Replace's re-entry to remove the old keys from every maintained machine
(`STA-17`); the sheet's import checks — seed identifier, derived public keys, unique indices,
vendor inventory — beyond the counter rule the guard is, since a sheet here is always a copy of
an earlier journal and passes them by construction; derivation-version upgrades, so `version`
is `1` throughout; the vendor resource each entry maps to, since only the index rules are at
stake. A fresh seed is 128 bits of CSPRNG entropy; its freshness is taken as given, as
`nextSeed`, a counter outside the journal, rather than as a hypothesis on each theorem. -/

namespace TauWeb.Allocation

/-- The index families of `STA-22b`: machines, passes, handoffs. Roles in one family share
that family's index. -/
inductive Family
  | machine
  | pass
  | handoff
  deriving DecidableEq, Repr

/-- The credential a role derives. -/
inductive Credential
  | sshClient
  | attestSender
  | attestRecipient
  | relay
  | postHarness
  deriving DecidableEq, Repr

/-- How the 32-byte child secret is read: as an RFC 8032 Ed25519 seed, or as a secp256k1
secret with a BIP-340 x-only public key. -/
inductive Secret
  | ed25519Seed
  | secp256k1
  deriving DecidableEq, Repr

/-- One row of the table: the three columns that decide index sharing, the credential derived,
and secret handling. The public-key encoding stays in the Markdown, as prose in the last
column. -/
structure Row where
  family : Family
  credential : Credential
  secret : Secret
  deriving DecidableEq, Repr

/-- The number of roles the table defines; `total` decides that every number below it has a
row and `closed` proves nothing above it does. -/
def count : Nat := 5

/-- The role table of `credential-format-v1.md`, keyed by role number. -/
@[req "STA-22a"] def row : Nat → Option Row
  | 0 => some ⟨.machine, .sshClient, .ed25519Seed⟩
  | 1 => some ⟨.machine, .attestSender, .secp256k1⟩
  | 2 => some ⟨.machine, .attestRecipient, .secp256k1⟩
  | 3 => some ⟨.pass, .relay, .secp256k1⟩
  | 4 => some ⟨.handoff, .postHarness, .ed25519Seed⟩
  | _ => none

/-- Every role number below `count` has a row. -/
@[req "STA-22a"] theorem total : ∀ n, n < count → (row n).isSome := by decide

/-- No role number at or above `count` has one: a new algorithm needs a new role, never a
reinterpretation. -/
@[req "STA-22a"] theorem closed : ∀ n, count ≤ n → row n = none := by
  intro n h
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le' h
  rfl

/-- Roles 0, 1 and 2 share the machine index; roles 3 and 4 do not. -/
@[req "STA-22a"] theorem machine_index_shared :
    ∀ n, n < count → ((row n).map Row.family = some .machine ↔ n ≤ 2) := by decide

/-! ## The allocator -/

/-- "Indices are integers from 0 through 2^31−1" (`credential-format-v1.md`): every index is
below this, and `admits` refuses at it rather than wraps. -/
@[req "STA-22a"] def indexLimit : Nat := 2 ^ 31

/-- The allocation identity: seed epoch, derivation version, role family, index. A structure,
never an alias, so two allocations cannot share one by a type error. The epoch is `STA-22b`'s
"seed identifier", numbered here: Replace is "a **new seed**" (`STA-22`), so a fresh epoch. -/
@[req "STA-22b"] structure Identity where
  epoch   : Nat
  version : Nat
  family  : Family
  index   : Nat
  deriving DecidableEq, Repr

/-- What the journal knows of an allocation: reserved, with no external effect yet; created; or
a tombstone — failed or destroyed — that keeps its index. -/
inductive Status
  | reserved | created | failed | destroyed
  deriving DecidableEq, Repr

structure Entry where
  id     : Identity
  status : Status
  deriving DecidableEq, Repr

/-- `STA-22b`'s "next unused index for each role family (machines, passes, handoffs)". -/
structure Next where
  machine : Nat
  pass    : Nat
  handoff : Nat
  deriving DecidableEq, Repr

def Next.get (n : Next) : Family → Nat
  | .machine => n.machine
  | .pass    => n.pass
  | .handoff => n.handoff

def Next.set (n : Next) : Family → Nat → Next
  | .machine, k => { n with machine := k }
  | .pass,    k => { n with pass := k }
  | .handoff, k => { n with handoff := k }

/-- The journal's allocation state — `STA-22b`: "The journal owns a seed identifier, derivation
version, next unused index for each role family (machines, passes, handoffs), and allocated
entries, including tombstones for failed or destroyed allocations". `restored`: the seed was
"imported after loss of the canonical journal" and no Replace has happened since. The sheet
is the one import here; it stands for the local-store backup too, since "This restriction also
applies to an imported local-store backup". Entries newest first. -/
@[req "STA-22b"] structure Journal where
  epoch    : Nat
  version  : Nat
  next     : Next
  entries  : List Entry
  restored : Bool
  deriving DecidableEq, Repr

structure World where
  journal  : Journal
  /-- The last sheet exported (`STA-16`), as the operator holds it: the journal as it then was. -/
  sheet    : Option Journal
  /-- The epoch the next Replace mints. Entropy, so a lost journal does not rewind it. -/
  nextSeed : Nat
  /-- Every identity the trace has ever reserved, newest first. A key derived from it may be on
  a machine, so no loss of the journal rewinds this list either. -/
  issued   : List Identity
  deriving DecidableEq, Repr

/-- The guard `STA-22b` gained on 2026-09-09: "a seed imported after loss of the canonical journal
may restore listed identities but MUST NOT allocate new ones, even when the sheet claims to be
current", because "A stale sheet cannot prove the latest counter". One field, so that removing it
is a one-token change; `stale_sheet_refused` and `stale_sheet_admitted` are its pair. -/
@[req "STA-22b"] structure Params where
  restoredAllocatesNone : Bool
  deriving DecidableEq, Repr

/-- The allocator as it stands, the guard present. -/
@[req "STA-22b"] def current : Params := { restoredAllocatesNone := true }

/-- Whether a reservation in family `f` is admitted: not under the restored-seed guard, and the
family's counter below `indexLimit` — "No wraparound is allowed" (`credential-format-v1.md`),
so exhaustion refuses. -/
@[req "STA-22b"] def admits (p : Params) (j : Journal) (f : Family) : Bool :=
  !(p.restoredAllocatesNone && j.restored) && j.next.get f < indexLimit

/-- The identity a reservation in family `f` would take: this seed, this version, the family's
next-unused index. -/
def Journal.fresh (j : Journal) (f : Family) : Identity :=
  { epoch := j.epoch, version := j.version, family := f, index := j.next.get f }

/-- The reservation, "durably before any external effect" (`STA-22b`): the entry is journaled
reserved at the family's next-unused index and the counter advances, and the identity counts as
issued from this step — `STA-22`: "A machine's index is journaled before the create call and
never reused". Refused, the world is unchanged. -/
@[req "STA-22b"] def allocate (p : Params) (w : World) (f : Family) : World :=
  if admits p w.journal f then
    let id := w.journal.fresh f
    { w with journal := { w.journal with entries := ⟨id, .reserved⟩ :: w.journal.entries,
                                         next := w.journal.next.set f (id.index + 1) },
             issued := id :: w.issued }
  else w

/-- An entry's status moved from `from` to `to`, and nothing else: the one shape of every
outcome after the reservation. The counters never move here. -/
def mark (w : World) (i : Identity) (from_ to : Status) : World :=
  { w with journal := { w.journal with entries := w.journal.entries.map fun e =>
      if e.id = i ∧ e.status = from_ then { e with status := to } else e } }

/-- The external effect's outcome on a reserved entry: created, or failed — a tombstone, since
"a failed reserved allocation remains consumed" (`credential-format-v1.md`). -/
@[req "STA-22b"] def settle (w : World) (i : Identity) (ok : Bool) : World :=
  mark w i .reserved (if ok then .created else .failed)

/-- A created machine destroyed: its entry becomes a tombstone and keeps its index. -/
@[req "STA-22b"] def destroy (w : World) (i : Identity) : World := mark w i .created .destroyed

/-- The export: "All this metadata is included in `STA-16` exports" (`STA-22b`), so the sheet is
the journal as of now. -/
@[req "STA-22b"] def exportSheet (w : World) : World := { w with sheet := some w.journal }

/-- The seed imported after loss of the canonical journal, from the sheet the operator holds:
the journal is the sheet's copy, marked restored, so that "Existing identities remain usable
during non-revoking Restore" (`STA-22b`) and the guard applies. With no sheet there is nothing
to restore. -/
@[req "STA-22b"] def restore (w : World) : World :=
  match w.sheet with
  | some s => { w with journal := { s with restored := true } }
  | none => w

/-- Replace (`STA-22`, `STA-17`): "a **new seed**", so a fresh epoch with every counter at zero;
"old records are retained until migration is complete" (`STA-22b`), so the entries stay under
their old epoch; and the guard lifts — "To allocate again, use Replace with a freshly generated
seed". -/
@[req "STA-22"] def replace (w : World) : World :=
  { w with journal := { w.journal with epoch := w.nextSeed, next := ⟨0, 0, 0⟩, restored := false },
           nextSeed := w.nextSeed + 1 }

inductive Event
  | allocate (f : Family)
  | created (i : Identity)
  | failed (i : Identity)
  | destroy (i : Identity)
  | exportSheet
  | restore
  | replace
  deriving DecidableEq, Repr

def step (p : Params) (w : World) : Event → World
  | .allocate f => allocate p w f
  | .created i  => settle w i true
  | .failed i   => settle w i false
  | .destroy i  => destroy w i
  | .exportSheet => exportSheet w
  | .restore    => restore w
  | .replace    => replace w

def run (p : Params) (w : World) : List Event → World
  | [] => w
  | e :: es => run p (step p w e) es

/-- A fresh seed at epoch 0, derivation version 1, nothing issued, no sheet. -/
def init : World :=
  { journal := { epoch := 0, version := 1, next := ⟨0, 0, 0⟩, entries := [], restored := false },
    sheet := none, nextSeed := 1, issued := [] }

/-! ## Over every trace -/

/-- What one step preserves: no identity issued twice; every issued epoch below the fresh
counter and every issued index below the limit; the journal's and the sheet's epoch below the
fresh counter; and, on a seed that was not restored, every identity issued under the journal's
epoch below its family's counter — which is what the guard protects, since a stale sheet's
counter has no such bound. -/
def Inv (w : World) : Prop :=
  w.issued.Nodup ∧
  (∀ i ∈ w.issued, i.epoch < w.nextSeed ∧ i.index < indexLimit) ∧
  w.journal.epoch < w.nextSeed ∧
  (∀ s, w.sheet = some s → s.epoch < w.nextSeed) ∧
  (w.journal.restored = false →
    ∀ i ∈ w.issued, i.epoch = w.journal.epoch → i.index < w.journal.next.get i.family)

theorem Next.get_set (n : Next) (f g : Family) (k : Nat) :
    (n.set f k).get g = if g = f then k else n.get g := by
  cases f <;> cases g <;> simp [Next.set, Next.get]

theorem allocate_inv (p : Params) (hp : p.restoredAllocatesNone = true) (w : World)
    (f : Family) (hw : Inv w) : Inv (allocate p w f) := by
  obtain ⟨hnd, hiss, hep, hsh, hnext⟩ := hw
  unfold allocate
  split
  · rename_i hadm
    unfold admits at hadm
    simp only [hp, Bool.true_and, Bool.and_eq_true, Bool.not_eq_eq_eq_not, Bool.not_true,
      decide_eq_true_eq] at hadm
    obtain ⟨hres, hlim⟩ := hadm
    have hbound := hnext hres
    refine ⟨?_, ?_, hep, hsh, ?_⟩
    · rw [List.nodup_cons]
      refine ⟨fun hmem => ?_, hnd⟩
      have := hbound _ hmem rfl
      simp [Journal.fresh] at this
    · intro i hi
      rw [List.mem_cons] at hi
      rcases hi with rfl | hi
      · exact ⟨hep, hlim⟩
      · exact hiss i hi
    · intro _ i hi hie
      simp only at hie
      rw [List.mem_cons] at hi
      rw [Next.get_set]
      rcases hi with rfl | hi
      · simp [Journal.fresh]
      · have := hbound i hi hie
        split
        · rename_i hf; subst hf; simp [Journal.fresh]; omega
        · exact this
  · exact ⟨hnd, hiss, hep, hsh, hnext⟩

theorem entries_only_inv (w : World) (es : List Entry) (hw : Inv w) :
    Inv { w with journal := { w.journal with entries := es } } := by
  obtain ⟨hnd, hiss, hep, hsh, hnext⟩ := hw
  exact ⟨hnd, hiss, hep, hsh, hnext⟩

theorem inv_step (p : Params) (hp : p.restoredAllocatesNone = true) (w : World) (hw : Inv w)
    (e : Event) : Inv (step p w e) := by
  cases e with
  | allocate f => exact allocate_inv p hp w f hw
  | created i => exact entries_only_inv w _ hw
  | failed i => exact entries_only_inv w _ hw
  | destroy i => exact entries_only_inv w _ hw
  | exportSheet =>
    obtain ⟨hnd, hiss, hep, hsh, hnext⟩ := hw
    refine ⟨hnd, hiss, hep, ?_, hnext⟩
    intro s hs
    simp only [step, exportSheet, Option.some.injEq] at hs
    rw [← hs]; exact hep
  | restore =>
    obtain ⟨hnd, hiss, hep, hsh, hnext⟩ := hw
    simp only [step, restore]
    split
    · rename_i s hs
      exact ⟨hnd, hiss, hsh s hs, hsh, by simp⟩
    · exact ⟨hnd, hiss, hep, hsh, hnext⟩
  | replace =>
    obtain ⟨hnd, hiss, hep, hsh, hnext⟩ := hw
    refine ⟨hnd, ?_, ?_, ?_, ?_⟩
    · intro i hi; exact ⟨Nat.lt_succ_of_lt (hiss i hi).1, (hiss i hi).2⟩
    · simp [step, replace]
    · intro s hs; exact Nat.lt_succ_of_lt (hsh s hs)
    · intro _ i hi hie
      simp only [step, replace] at hie
      have := (hiss i hi).1
      omega

theorem inv_run (p : Params) (hp : p.restoredAllocatesNone = true) (w : World) (hw : Inv w)
    (es : List Event) : Inv (run p w es) := by
  induction es generalizing w with
  | nil => exact hw
  | cons e es ih => exact ih (step p w e) (inv_step p hp w hw e)

theorem inv_init : Inv init := by
  refine ⟨List.nodup_nil, ?_, by decide, ?_, ?_⟩ <;> simp [init]

/-- `STA-22`: "A machine's index is journaled before the create call and never reused. The same
index on two machines is the same client key on two machines". Over every trace from `init`,
under the guard, no two reservations share an identity — whatever was created, failed, destroyed,
exported, restored or replaced in between. -/
@[req "STA-22"] theorem issued_nodup (p : Params) (hp : p.restoredAllocatesNone = true)
    (es : List Event) : (run p init es).issued.Nodup :=
  (inv_run p hp init inv_init es).1

/-- Every index ever issued is below `indexLimit`: "Indices are integers from 0 through 2^31−1"
and "No wraparound is allowed" (`credential-format-v1.md`). Needs no guard. -/
@[req "STA-22a"] theorem issued_index_lt_limit (p : Params) (es : List Event) :
    ∀ i ∈ (run p init es).issued, i.index < indexLimit := by
  suffices h : ∀ w : World, (∀ i ∈ w.issued, i.index < indexLimit) →
      ∀ i ∈ (run p w es).issued, i.index < indexLimit from
    h init (by simp [init])
  induction es with
  | nil => intro w hw; exact hw
  | cons e es ih =>
    intro w hw
    apply ih
    cases e with
    | allocate f =>
      simp only [step, allocate]
      split
      · rename_i hadm
        intro i hi
        rw [List.mem_cons] at hi
        rcases hi with rfl | hi
        · simp only [admits, Bool.and_eq_true, decide_eq_true_eq] at hadm
          simpa [Journal.fresh] using hadm.2
        · exact hw i hi
      · exact hw
    | created i => exact hw
    | failed i => exact hw
    | destroy i => exact hw
    | exportSheet => exact hw
    | restore => simp only [step, restore]; split <;> exact hw
    | replace => exact hw

/-- On a seed that was not restored, every identity issued under the journal's epoch is below its
family's counter, over every trace: a failed or destroyed allocation keeps its index, and the
counter never comes back down to it. -/
@[req "STA-22b"] theorem issued_below_next (p : Params) (hp : p.restoredAllocatesNone = true)
    (es : List Event) (hres : (run p init es).journal.restored = false) :
    ∀ i ∈ (run p init es).issued, i.epoch = (run p init es).journal.epoch →
      i.index < (run p init es).journal.next.get i.family :=
  (inv_run p hp init inv_init es).2.2.2.2 hres

/-- A tombstone frees nothing — a failed create's index "remains consumed", a destroyed machine's
likewise: the counters and the issued list are what they were, and the entry stays under its
new status. Every outcome after the reservation is a `mark`, so this is every one of them. -/
@[req "STA-22b"] theorem mark_keeps_index (w : World) (i : Identity) (from_ to : Status) :
    (mark w i from_ to).journal.next = w.journal.next ∧ (mark w i from_ to).issued = w.issued ∧
    (⟨i, from_⟩ ∈ w.journal.entries → ⟨i, to⟩ ∈ (mark w i from_ to).journal.entries) := by
  refine ⟨rfl, rfl, fun h => ?_⟩
  simp only [mark, List.mem_map]
  exact ⟨⟨i, from_⟩, h, by simp⟩

/-- Under the guard, a restored seed allocates nothing: the world is unchanged. -/
@[req "STA-22b"] theorem restored_refused (p : Params) (hp : p.restoredAllocatesNone = true)
    (w : World) (hres : w.journal.restored = true) (f : Family) : allocate p w f = w := by
  simp [allocate, admits, hp, hres]

/-- Without it — the rule as it stood before 2026-09-09 — a restored seed allocates whenever its
family's counter is not exhausted, at the index the sheet's counter names. -/
@[req "STA-22b"] theorem restored_admitted (p : Params) (hp : p.restoredAllocatesNone = false)
    (w : World) (f : Family) (hlim : w.journal.next.get f < indexLimit) :
    (allocate p w f).issued = w.journal.fresh f :: w.issued := by
  simp [allocate, admits, hp, hlim]

/-- Exhaustion refuses: at the limit the world is unchanged, and the counter does not wrap. -/
@[req "STA-22a"] theorem exhausted_refused (p : Params) (w : World) (f : Family)
    (h : indexLimit ≤ w.journal.next.get f) : allocate p w f = w := by
  simp [allocate, admits, Nat.not_lt.mpr h]

/-! ## The witnesses, decided -/

def m0 : Identity := ⟨0, 1, .machine, 0⟩
def m1 : Identity := ⟨0, 1, .machine, 1⟩

/-! Each witness's events are one named list, so that the theorem and the emitter
(`Witnesses.lean`) run the same trace: the file's steps come from the list the proof decided. -/

/-- The stale sheet: machine 0 allocated and created, the sheet exported, machine 1 allocated and
created, the phone's journal lost, the sheet restored — its counter says 1 — and an allocation
attempted. -/
def staleSheetEvents : List Event :=
  [.allocate .machine, .created m0, .exportSheet, .allocate .machine, .created m1,
   .restore, .allocate .machine]

def staleSheetTrace (p : Params) : World := run p init staleSheetEvents

/-- With the guard, the restored seed's allocation is refused: the two identities issued are the
two the machines hold, the journal is marked restored, and it holds the listed identity the
sheet carried — machine 0, created — usable as `STA-22b` says. -/
@[req "STA-22b"] theorem stale_sheet_refused :
    (staleSheetTrace current).issued = [m1, m0] ∧
    (staleSheetTrace current).journal.restored = true ∧
    (staleSheetTrace current).journal.entries = [⟨m0, .created⟩] := by decide +kernel

/-- Without it, the sheet's counter is believed and index 1 is issued again: `STA-22`'s own trap,
"the same client key on two machines", as the duplicate in what was issued. The inventory lists
that trap and the stale sheet separately; in this allocator the stale sheet is the one road to
it, so the two are one trace. -/
@[req "STA-22"] theorem stale_sheet_admitted :
    (staleSheetTrace { current with restoredAllocatesNone := false }).issued = [m1, m1, m0] ∧
    ¬ (staleSheetTrace { current with restoredAllocatesNone := false }).issued.Nodup := by decide +kernel

/-- Replace after the restore lifts the guard: the next allocation is admitted, under the fresh
epoch, at index 0. Stated on what Replace decides and not on what the guard did before it, so
that the flipped guard reddens `stale_sheet_refused` alone. -/
def replaceAgainEvents : List Event := staleSheetEvents ++ [.replace, .allocate .machine]

@[req "STA-22"] theorem replace_allocates_again :
    let w := run current init replaceAgainEvents
    w.issued.head? = some ⟨1, 1, .machine, 0⟩ ∧ w.journal.epoch = 1 ∧
    w.journal.restored = false := by
  decide +kernel

def failedCreateEvents : List Event := [.allocate .machine, .failed m0, .allocate .machine]

/-- A failed create keeps its index: the next allocation takes index 1, and the tombstone stays. -/
@[req "STA-22b"] theorem failed_create_keeps_index :
    let w := run current init failedCreateEvents
    w.journal.entries = [⟨m1, .reserved⟩, ⟨m0, .failed⟩] ∧ w.journal.next.machine = 2 := by
  decide +kernel

def successfulEvents : List Event :=
  [.allocate .machine, .created m0, .destroy m0, .allocate .machine, .created m1]

/-- The allocator is not safe by refusing everything: allocate, create, destroy, allocate again,
create again — two machines, two identities, one tombstone, the counter at 2. -/
@[req "STA-22b"] theorem successful_trace :
    let w := run current init successfulEvents
    w.journal.entries = [⟨m1, .created⟩, ⟨m0, .destroyed⟩] ∧ w.issued = [m1, m0] ∧
    w.journal.next.machine = 2 ∧ w.journal.next.pass = 0 := by
  decide +kernel

/-- The fresh seed with the machine counter one below the limit. -/
def exhaustionStart : World :=
  { init with journal := { init.journal with next := ⟨indexLimit - 1, 0, 0⟩ } }

def exhaustionEvents : List Event := [.allocate .machine, .allocate .machine]

/-- Exhaustion, at the limit: the last index 2^31−1 is issued, and the allocation after it is
refused with the counter at the limit and not wrapped. -/
@[req "STA-22a"] theorem exhaustion_refuses :
    let w := run current exhaustionStart exhaustionEvents
    w.issued = [⟨0, 1, .machine, 2147483647⟩] ∧ w.journal.next.machine = indexLimit := by
  decide +kernel

/-! ## The bound -/

/-- The bound (`CONTEXT.md`): every trace of at most this many events over `alphabet`, from
`init`, is what `bounded_nodup` decides and what the witness file enumerates. Stated once, here,
for both; beyond it is `issued_nodup`'s statement, not the file's. -/
@[req "STA-22"] def bound : Nat := 3

/-- The events the bounded enumeration draws from: the machine family, the first machine's
three outcomes, and the three journal-level acts. -/
def alphabet : List Event :=
  [.allocate .machine, .created m0, .failed m0, .destroy m0, .exportSheet, .restore, .replace]

/-- Every trace of exactly `n` events over `alphabet`. -/
def tracesOf : Nat → List (List Event)
  | 0 => [[]]
  | n + 1 => (tracesOf n).flatMap fun es => alphabet.map (es ++ [·])

/-- Every trace of at most `n` events over `alphabet`, shortest first. -/
def tracesUpTo (n : Nat) : List (List Event) := (List.range (n + 1)).flatMap tracesOf

/-- `issued_nodup`, decided within the bound: the enumeration the witness file carries is one
the companion itself closed over. -/
@[req "STA-22"] theorem bounded_nodup :
    (tracesUpTo bound).all (fun es => decide (run current init es).issued.Nodup) = true := by
  decide +kernel

end TauWeb.Allocation
