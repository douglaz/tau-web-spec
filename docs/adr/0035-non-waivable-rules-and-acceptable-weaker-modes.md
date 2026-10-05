# Non-waivable rules, and the few weaker modes an operator may accept by name

Every conformance item the tiering rule makes BLOCKING is a **non-waivable rule**: no operator
act sets it aside. Separately, and narrowly, there is a closed list of **acceptable weaker
modes** an operator may accept by their labels for one bound set. Accepting one moves no tier.
Decided 2026-10-05.

## Why

Acting on a goal at any vendor, on any distribution, meets things the bundle has no pin, no
adapter and no brief for. Two answers were available and both were wrong. Refusing all of it
keeps every rule and leaves the operator with a product that installs two distributions at one
vendor. Letting the operator accept whatever the harness cannot do leaves a non-technical
person approving the removal of controls they have no way to weigh — and a model that retries
on its own initiative will find the acceptance and use it.

What separates the two is not how bad a harm is but whose it is and whether anyone sees it.
Some harms stay on the operator's own machines, show when they happen, and cannot be
multiplied by a model asking again. An operator can take those on with a label. The rest —
harm that is irreversible and unseen, that an autonomous caller can repeat, or that falls on
somebody else — is nobody's to accept.

## The decision

**The tiering rule's three questions do not change, and no tier moved because of this record.**
`07-conformance.md`'s tiering section defines both terms beside the rule. The promotions and
moves made with it are of another kind and are recorded where they happened: the trust
display's listing of placed secrets became BLOCKING, and secret placement moved into the first
stage.

**The list, the best practice each mode stands in for, and the rule are `SEC-14`'s.** It names
five modes — an installation with no artifact pin, a first contact from a jump host, acting
with no brief, a bound set of more than one machine, an untyped scope at a vendor with no
adapter — and says of all of them: `SEC-14` says "every item `07-conformance.md`'s tiering rule
makes BLOCKING is a **non-waivable rule**, which no label, no answer and no operator act sets
aside".

**A weaker mode is chosen, never fallen into.** `SEC-14` says "A failed check halts", and the
requirement that owns each stronger check says the same of its own: `ARC-25` says "A failed
pinned check halts; it never degrades into a weaker mode".

**Acceptances do not compose silently.** A mode accepted an hour ago and a secret placed now
are one exposure, and nobody accepted the pair unless they were shown together. So every mode
standing on a set is restated at each later irreversible act on any of its machines, and
placing a secret is the first such act: `ARC-43` puts the restatement on `place_secret`'s card.

**Two things decided with it, because they are where the line was drawn.**

- *A finding is not something an operator accepts.* `ARC-17` says "A finding is never accepted
  in place of an amendment". A machine with a finding standing may be taken by its operator; it
  is handed over with findings, it is not delivered, and `ARC-43` says "No secret is placed
  while a finding stands".
- *A secret's delivery is non-waivable in every part.* `ARC-43` says "The value is the job's
  standard input and never an argument", and the rest of that list — no persistence by the
  wrapper, refusal of a value equal to a harness credential, refusal of an unsafe destination —
  is not offered to anyone for acceptance.

## Considered options

**A single test: a rule blocks only if its harm is irreversible and the operator could not
have seen and accepted it beforehand.** This was the first proposal, and it is recorded
because it is the natural one. Rejected: it drops the tiering rule's third question, the
autonomous retry, which matters more here than in most systems; it does not derive several
rules everybody agreed were not negotiable; and it treats approving an effect as the same act
as approving the removal of the control that keeps execution within that approval. The record
of what consent is worth was already in the corpus — the operator this product is for is the
one least equipped to judge a waiver.

**Demote BLOCKING items the operator accepts.** Rejected: a tier is a statement about a harm,
and an acceptance does not change the harm. Artifact pinning stays BLOCKING wherever a pin
exists; what the operator may choose, up front, is a distribution that has none.

**Call the non-waivable set "the floor".** Rejected on vocabulary alone: the word was already
taken several times over in this corpus, for unrelated things.

**Enter a weaker mode when the stronger check fails.** Rejected, and it is the option with the
most pull at three in the morning: a pin that will not match, an introduction that never
arrives. A check that degrades when it fails is a check an attacker fails on purpose.

**Accept a mode per machine.** This was the first form, and it was amended when sessions came
to hold more than one machine
([ADR-0037](./0037-bound-sets.md)): what the model reads on one machine steers what it runs on
another, so "its harm stays on that machine" is not true of one machine in a set. A mode is
accepted for a bound set, and a set of more than one is itself a mode.

**Refuse to place a secret on any machine whose installation was not pinned.** Rejected in
favour of the restatement: the combination is an exposure the operator can be shown and can
take, on their own machine. What is refused outright is placement while a finding stands.

**Let an operator accept a lockdown finding and call the machine delivered.** Rejected.
"Delivered" has one meaning, and a waiver that counts as delivery changes it for every later
reader of a trust display. The operator has two honest moves: fix the machine, or amend its
declaration by a journaled act and have it checked again.

**Mint a capped key for an installed application from the harness's inference account.**
Rejected: it would be a harness credential on a machine, which `ARC-1` forbids, and it would
outlive the session that `ARC-31a` ties such a key to. The operator mints a capped or revocable
key at the application's own service, and the card says that is the better key to place.

**Claim that a placed secret never appears in any record.** Rejected as an overstatement. The
harness can keep the value out of its own records and out of model context on the way in, and
can redact exact copies from later output. It cannot speak for the machine: a command that
prints the file has written the value to the machine-side output file before any browser scan
runs.

## Consequences

**Every new rule lands as an item with a tier, and a BLOCKING one names its family.** Labels
are not exempt: where the label is the only thing between the operator and a harm they would
not otherwise see, the item that tests the label is BLOCKING by the rule's second question.

**The harness will halt where a weaker product would continue.** A mismatched pin, a silent
first boot, a refused adapter call each end in a stop and a named remedy. That is the cost, and
it is the same cost `ARC-25` already paid for artifacts.

**The list is closed, and growing it is a decision of this weight.** A sixth mode is a record,
not a row somebody adds while implementing a vendor.

**What the decisions left open is in `TASKS.md`**, including whether an unpinned installation
is admissible under a declared independence bound, which nothing here settles.
