import TauWeb.Req
/-! Module 1, allocation (ADR-0032's inventory). The first clause carried is the credential
format's role table (`STA-22a`, `credential-format-v1.md`): role number to index family,
which decides index sharing, and child-secret interpretation. The table is closed — `row` is
`none` outside the five roles — and its totality over those roles is decided, not argued. -/

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

/-- One row of the table: the two columns that decide index sharing and secret handling. The
public-key encoding column stays in the Markdown. -/
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

end TauWeb.Allocation
