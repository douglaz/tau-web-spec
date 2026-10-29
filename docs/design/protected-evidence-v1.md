# Protected browser evidence v1

Dated representation addendum, 2026-10-28. This companion records the browser payload,
substitution and page-transition representation used with SEC-5. It changes neither the
machine job record nor the vendor response grammar. RecordJson, record AAD, content-address chain and nonce generation remain v1.
Fresh local stores use the authenticated fenced-key envelope extension defined in
credential format v1; legacy local envelopes and recovery-sheet envelopes remain readable
under their existing definitions. No legacy record is
rewritten. This document is a specification of a construction, not a conformance result.

## 1. Decoder boundary and facts

The machine decoder remains the existing raw `missing | incomplete | present` job-record
decoder. The browser-storage decoder additionally accepts the protected alternative below.
The two types and their constructors are distinct. Only the private browser constructor
can convert validated raw evidence to protected evidence. Raw vendor objects do not confer
custody, withholding or outcome authority. A protected job object is rejected by the raw
job decoder; unknown vendor members resembling this metadata are ignored as ordinary
unknown vendor members and never consumed as browser metadata. A protected object in place
of an expected vendor scalar or response envelope is rejected as that raw input.

A required source fact is retained or withheld. An optional source fact has three states:
received absent; received present and retained; received present and withheld. Inapplicable
fields are forbidden. A withheld field is omitted from `facts` and appears exactly once in
`withheld`. An absent optional field is omitted from both. Null never means withholding.
Retained values keep their original type and producer origin. There is no numeric or
boolean sentinel, raw-value hash, concealed original or marker-as-received-value.

Every withholding entry has exactly `slot`, `marker` and `associations`. Entries are sorted
lexicographically by slot. `associations` is a nonempty creation-ordered array of the
association forms in section 4, with no duplicate identity. `marker` is the exact section 4
construction for that array. Unknown fields, versions, duplicate slots, retained/withheld
overlap, inapplicable slots and contradictory available relations are rejected.

## 2. Job schema and replay

Legacy Evidence remains `{call,job,record}` with optional `custody` as in section 4.
`call` is the genuine journal call number; `job` is its genuine tracked identity. A protected
`record` has exactly these members:

```
kind: "protected"
version: 1
source_kind: "incomplete" | "present"
state: "incomplete" | "other_machine" | "finished" | "running" | "ended"
agreement: "no_record" | "advisory_match" | "finding"
relations: the applicable closed relation object below
facts: the applicable source fields below
withheld: the withholding entries for applicable received-present fields
```

`missing` remains legacy and has no protected variant. For `incomplete`, `facts` may contain
`machine` and `command`, both lowercase-hex strings; either can genuinely be absent.
`relations` has `machine: absent|same|different` and `command: absent|same|different`.
Machine absence means absent from both fact and withholding sets. Command absence gives
`agreement:no_record`; otherwise same gives `advisory_match` and different gives `finding`.
The state is always `incomplete`, irrespective of machine agreement.

For `present`, required source fields are `machine`, `command`, `boot`, `current_boot`,
`pid`, `alive`, `stdout`, `stderr`; optional `exit_status` records genuine absence or a
validated received code. String/hex, u32 and bool types remain those of the raw decoder.
`relations` has exactly `machine:same|different`, `command:same|different`,
`boot:equal|different`, `pid:zero|nonzero`, `liveness:alive|dead`, and
`exit:absent|present`. The private constructor runs the original lowercase-hex, nonempty
boot and exit-code-at-most-128 checks before computing these relations or removing facts.
Machine and command relations compare against the causal intent's actual operands.

Classification order is exact: different machine gives `other_machine`; otherwise present
exit gives `finished`; otherwise zero PID gives `incomplete`; otherwise equal boot and
alive and nonzero PID gives `running`; otherwise `ended`. Command agreement is independent
of state. Replay derives and compares state/agreement using this order. `running` remains
inadmissible as a journal observation. Terminal-kind agreement, call/job association,
cancellation, already-settled and disposition checks remain in the ordinary dispatch path.

A retained machine/command must agree with its relation to the intent. When both boot
operands survive, their equality must agree. A retained PID, alive or exit value must agree
with the corresponding relation. The existence of a withheld entry also proves original
presence; it cannot satisfy `exit:absent`. When one operand has been withheld, replay uses
the authenticated relation rather than a fabricated operand. Outer authentication
establishes the harness's statement, not independent truth of a machine report.

In a present protected job record, stdout and stderr remain logical byte buffers, possibly
containing constructor-recorded substitutions; they are never whole-fact-withheld. The
present-record withholding allowlist is exactly `machine`, `command`, `boot`, `current_boot`,
`pid`, `alive`, `exit_status`. The incomplete-record allowlist is exactly `machine`, `command`.
The protected variant is used only when one of these identity or scalar facts is withheld. Output-only byte replacement can retain the legacy record layout and use
Evidence's `custody`. Legacy and protected output slot paths differ as listed in section 4.
Raw `Record::classify` is never called on a protected record.

Every projection uses one rule: omit a withheld raw field and put its named entry in that
object's single `withheld` array. In-memory finished exits are `Code(u32)` or
`Withheld(entry)`; genuine exit absence is a third state in observations. A finished exit
is never recovered with `expect`, `unwrap_or(0)` or null. Terminal, Finished, Done, run
report, job Report, delivery/inspect, unresolved/uncommitted evidence, tool result and
history propagate that same distinction. The explicit Terminal event accepts either the
unchanged legacy `{call,exit_status}` payload, or a protected payload with exactly
`kind:"protected"`, `version:1`, `call`, `relations:{exit:"present"}`, `withheld`, and optional
`custody`. Its withholding array contains exactly one entry for `exit_status`; no raw exit
field is present. Custody/table requirements follow section 4. Only the private browser
constructor creates this arm. Existing call admission and source-specific raw validation
remain unchanged. No raw machine wire accepts that extension.

A flattened Report merges projection-level entries into one array; its slot allowlist is
`journal`, `received` and `exit_status`. A Finding retains the genuine `command:different`
relation; its `journal` and `received` display copies may each be omitted with their slot
entry because they first appear in a representation composed after the machine's reply.
The journal's intent record is unchanged and execution never uses an altered command; a
marker is not a received or recorded command. The run report's withholding slot allowlist is exactly `sent`, `recorded`,
`recorded_machine`, `exit_status`; those copies use the same rule with those slot names. Nested Evidence retains
its own entries for its own fields. Report stdout/stderr derive from retained protected
logical buffers through the actual attributed lossy decoder. No duplicate raw scalar
escapes through another report. Section 4 scopes all their index markers to one final
projection table.

Failed/malformed reads stay failed/malformed, rather than Missing. Failed appends retain
protected uncommitted evidence without a journal number. Disposed evidence remains visible
without reopening, arming or granting approval. Late/cancelled/settled observations retain
their existing admission refusal and truthful visibility.

## 3. Protected inference terminals

The legacy terminal remains readable. A version-1 protected terminal has exactly `kind:"protected"`,
`version:1`, `call`, `intent_kind`, `outcomes`, `facts`, `withheld`, and optional `custody`.
`intent_kind` is `account_read | mint | completion | revoke` and must equal the causal
intent. `call` must identify that intent and have no previous terminal. Field presence
uses section 1; these are the complete per-kind inventories:

| Kind | Required facts | Optional facts | Outcomes |
|---|---|---|---|
| All | `status:u16`, unless withheld | none | `http:success\|non_success`; `valid_status:true` |
| account_read | common | `automatic_top_up:bool` | `top_up:absent\|enabled\|disabled`; `account_gate:accepted\|refused` |
| mint | common | `key_id:string`, `cap:string`, `expires:u64` | `identifier:absent\|available\|withheld`; `bounds:absent\|intent_equal` |
| completion | common, `model:string`, `requested_provider:string` | `reported_provider:string`, `request_id:string`, `prompt_tokens:u64`, `completion_tokens:u64`, `total_tokens:u64`, `spend:string` | `selection:intent_equal`; `spend_number:absent\|valid` |
| revoke | common | none | no additional fields |

The common source status is validated in 100..599 before conversion; success means
200..299. `valid_status` is a constructor truth assertion, not a replacement raw check.
A retained status must satisfy both range and class. No received absence of status is
valid. Withholding status 200 preserves success; withholding 500 preserves non-success.
The account gate accepts exactly success plus received `Some(false)`. Top-up absence,
true and false stay distinguishable even if that raw boolean is withheld. Both immediate
account admission and replay use that genuine gate.

A mint identifier is received only after the existing nonempty, HTTP-success and
credential-containment checks. `cap` and `expires` are copied from its intent when an
identifier survives those checks. They are pre-effect required facts and are never
post-effect-withheld. The protected record keeps the copied bounds when an otherwise
valid identifier is withheld; `bounds:intent_equal` then checks them against that intent.
If no identifier was admitted, key_id/cap/expires are absent and bounds is absent. Empty
identifier is invalid. The existing credential boundary can reject an identifier before
application-secret conversion; that remains received-absence for this terminal. A new
application-secret withholding instead records `identifier:withheld` and its named entry.

### Mint acceptance extension

New mint terminals use `kind:"protected"`, `version:2`. Other terminal kinds remain version 1. A version-2 mint terminal has exactly `kind`, `version`, `call`, `intent_kind:"mint"`, `requested`, `outcomes`, `facts`, `provenance`, `withheld`, and optional `custody`. Its causal-call and common HTTP checks remain those above. `requested` has exactly `cap:string`, `unit:string`, `expires:u64`, copied from and checked against the immutable mint intent; these are request facts, never observations. They retain the intent's exact canonical values and have no whole-fact withholding slot in stored evidence.

The closed `facts` inventory is `status:u16`, unless withheld, and optional `key_id:string`, `accepted_cap:string`, `accepted_unit:string`, `accepted_expires:u64`. The identifier retains the existing nonempty, HTTP-success and credential-containment checks. Each accepted field is an independently obtained, profile-decoded issuer fact, never a copy of `requested`; cap preserves its exact decimal text, unit its exact text and expiry its exact whole Unix UTC second. Broader or different parseable values remain representable even when outside the application's supported envelope. A missing or malformed acceptance value supplies no invented accepted fact. `provenance` is a closed object with exactly one entry for each received accepted field, including a withheld one, and no others. Its keys are `accepted_cap`, `accepted_unit`, `accepted_expires`; values are `response | readback`, with `profile` additionally permitted for `accepted_unit` only when the pinned profile evidences that fixed unit. Response and authenticated readback facts must concern the same minted identifier and the causal intent's pinned profile. Provenance identifies that source under that exact profile; it asserts neither independent enforcement nor a request value's observation.

`outcomes` has exactly `http:success|non_success`, `valid_status:true`, `identifier:absent|available|withheld`, and `acceptance:absent|exact|different|unverifiable`. The private constructor computes acceptance before withholding: a genuine comparable mismatch gives `different`; otherwise all three accepted facts with evidenced semantics equal to the immutable requested tuple give `exact`; genuine absence of all acceptance fields gives `absent`; missing, malformed or unverifiable acceptance gives `unverifiable`. A malformed received value is not genuine absence. Retained accepted fields must agree with that assessment and their provenance; a withheld field retains its genuine presence and assessment, not a fabricated value. Copied request bounds cannot satisfy `exact`.

The version-2 whole-fact withholding allowlist is exactly `status`, `key_id`, `accepted_cap`, `accepted_unit`, `accepted_expires`; entries use §1's form and slots, with complete §4 custody names and empty substitutions. No accepted field is byte-substituted. Canonical stored decoding checks closed members, types, field/provenance presence, retained comparisons, source applicability and the exact version-2 round trip. All reports, exports and later display copies preserve the requested/accepted distinction, provenance and unavailable presence. A later display omission changes no historical admission. An original withheld acceptance field supplies no usable session authority, even with an authenticated `exact` assessment. The requested tuple, old copied bounds, HTTP success or a marker alone supplies none either. A retained identifier remains available for the existing revocation path when acceptance fails; its withholding keeps the unavailable-identifier behavior below.

Version-1 mint records remain readable in their original canonical shape; their copied bounds are labeled requested and establish no independent issuer acceptance or new session authority. No old record is rewritten or silently promoted to version 2. Both versions retain their causal mint attempt and one-attempt barrier. The procured session-limit policy remains in ARC-31a.

### Shared terminal behavior

A withheld minted identifier cannot install a usable session key, name a completion or
name a revoke. It retains the originating mint association and the no-second-mint barrier.
The live session credential is cleared. End/sweep reports identifier unavailability and
that revocation is unconfirmed. The requested expiry remains visible, labeled requested,
and is never evidence of issuer acceptance or enforcement. For version 2, also show retained
`accepted_expires` with its provenance, or explicitly show that the issuer expiry is withheld,
absent or unverifiable; preserve any discrepancy and uncertainty. It never claims revocation,
erases the outstanding mint or starts a substitute mint.
Later operations needing the literal refuse before send. This is the same operational
unavailability boundary as a lost identifier, with truthful received-present evidence.

Completion model/provider selection is copied from the intent and checked against it;
neither is a received vendor attestation or withholdable after effects. Reported provider
is advisory received metadata. There is no reported-provider-equals-requested-provider gate
and no token-sum equation. Counts retain the accepted unsigned-integer type. A retained
spend string parses as a JSON number. `spend_number:valid` requires retained or withheld
spend; `absent` requires absence from both. A withheld spend carries that genuine prior
accepted-number outcome without reconstructing the number. Field
applicability is checked against the table, including when the raw field is withheld.

The constructor preserves the existing tool credential refusal and body redaction rules.
Completion bodies and transient completion/tool history retain live attributed payloads
and are re-finalized at each release; this construction adds no durable event or custody
slot for them. Persisted reported-provider and request-ID substitutions use the
InferenceTerminal slots in section 4. The schema adds no funding, account, model selection
or request authority.

`Store::decode` validates this distinct terminal arm and its exact round-trip shape before
applying it; it does not round-trip the omitted status through the legacy terminal type.
Replay, live account gates, `top_up_off`, mint acceptance, goal-loop HTTP decisions,
report/history/tool results and cached outcomes all consume genuine outcomes. A protected
finished goal outcome has `finished:true`, `http`, and a status withholding entry instead
of numeric `status`. Its sentence is exactly `Goal loop ended: inference request finished with status `,
then the marker, then `.`. The ordinary numeric sentence remains
`Goal loop ended: inference request finished with status ${status}.`

The account-read report consumed by `inference::run`, the report consumed by `goals.rs`,
`Store::top_up_off`, and replay carry `http` and `top_up` when `status` or
`automatic_top_up` is withheld. `http` is `success` exactly when the genuine status is in
200..299 after the existing 100..=599 check, and `non_success` otherwise. `top_up` is
`absent`, `enabled`, or `disabled`. Those readers use the genuine value on the live path
and the authenticated typed class on replay. A withheld genuine 200 with top-up disabled
still admits the mint; a withheld 500, or top-up enabled or absent, still refuses. Raw
absence is not success. `finish` emits no raw status or raw automatic_top_up whose fact
is withheld. These fields convey no new provider-equality or token-sum gate.

## 3a. Protected operation evidence

### Identity and confirmation boundary

A received-present vendor identity withheld in canonical evidence confirms and settles no order, including when a genuine equality was observed before withholding. Preserve truthful received-present evidence, named withholding and the approved-entry barrier. Absence, unavailable presence and a retained identity are distinct. Neither an authenticated relation, a marker, a generated handle, an operator disposition nor a later association reconstructs an erased identity. Disposition records an unknown outcome and supplies no successful confirmation, usable identity or cross-entry uniqueness.

The namespace is the global VendorMachine literal namespace. No account namespace or vendor-ID format assumption narrows it. An unavailable-identity risk is derived only from canonical committed evidence satisfying the following predicate. Withholding introduced solely in a later projection creates no risk record and changes no historical admission. Receipt qualification does not require its call still to be unresolved.

Qualifying identity evidence is an earlier durable BrowserVendorTls validated order receipt whose genuine call names an earlier typed intent for an approved entry, whose call/resource/target/operation/account/signed-request comparisons all pass, or an earlier otherwise-valid VendorMachine association for an approved entry. Every such receipt with durably withheld returned_vendor and every such association with durably withheld VendorMachine target is an unavailable-identity risk record attributed to that approved entry. Arbitrary, unvalidated, uncorrelated or mismatched receipts create no ownership exclusion.

A risk attributed to an entry excludes every different entry. Every applicable earlier risk remains relevant after disposition, reference termination, restart, operator inspection and same-entry independent adoption. No current predicate discharges it. The exclusion applies to new mappings: it neither revokes an existing mapping nor grants that mapping authority over another entry. An idempotent repetition of an already admitted mapping introduces no new mapping.

Before admitting a new retained literal Y for entry B, perform the ordinary genuine-input target-kind, approved-entry, allocation-reservation and retained admitted-map checks. Unknown entry, invalid target or equality to another entry's admitted mapping refuses association admission before append, without preventing separately required receipt evidence. Equality to this entry's admitted mapping is an idempotent duplicate: no second append, operational mapping or AssociationRecord. A duplicate legacy journal event remains readable and replays as an idempotent mapping no-op.

For a withheld vendor target, first compare the genuine literal with every retained admitted mapping before omission. Equality with another entry's mapping is the ordinary conflict refusal before append; equality with this entry's mapping is the ordinary idempotent duplicate with no record. Otherwise the association is recorded quarantined/identity_withheld. For a new retained target facing an applicable earlier unavailable-identity risk, record quarantined/alias_unavailable. Then apply the retained-evidence identity-conflict rule below before recording the new outcome.

Before admitting literal Y for entry B, check retained qualifying identity evidence as well as admitted mappings. Equality to retained qualifying evidence attributed to another entry is a known identity conflict, including when that evidence's association was quarantined. It grants no mapping; refuse admission with fixed reason `identity_conflict`, preserving every separately required receipt append. Existing conflicts against admitted mappings retain their existing refusal. Only mapped or admissible legacy associations supply operational resolution or receipt-association constituents. A retained identity recorded for another entry cannot be classified as an unassociated listing candidate. A repeated same-entry quarantine is additional evidence, not cumulative identity proof or an admitted duplicate.

Only a mapped or legacy association record can be an order's settlement constituent or the association member of a Receipt settling record; a quarantined record never enters either lookup, even when its retained literal equals a receipt's. Resolve and the ordinary duplicate/conflict check read only the operational map; admission additionally applies the retained-evidence identity-conflict rule above. Quarantined evidence remains in association_records for inspection and grants no confirmation or target. Recording a receipt and an association from one response adds no independent-source authority.

Association first with a durably withheld target: append quarantine; a later receipt, before or after restart, cannot match the unknown target. Receipt first with a durably withheld ID: append it with a historical settled vector permanently empty for that order; a later association cannot settle it by reconstructed equality. Both retained admissible literals preserve exact equality and approved-entry correspondence in either arrival order, including across restart. A receipt protected only in a display operand may settle if all original eligibility relations hold and required vendor identities remain retained and durably mapped. A later association never rewrites an earlier receipt's historical settled vector.

Wrong source, validation, call, resource, target, entry, operation, account or signed request never gains authority through protection. A receipt preceding its claimed intent cannot settle it. Missing identity remains absent and unresolved. Known conflict supplies no map; unknown alias remains quarantined. Replay derives historical outcomes from the authenticated prefix in journal order and never promotes quarantine because references end or other evidence arrives. New independently admissible evidence appends its own durable outcome before changing operational state; no in-place rewrite or new quarantine-clear event is introduced.

Preview before commit, and replace live dispatch only after successful append. Failed append changes no live map or settlement. Landed-then-error latches the old writer; fresh authenticated replay applies the landed evidence once without resend. Operational append errors are distinct from custody-driven refusal of required evidence. Protected uncommitted evidence is diagnostic only, with no committed journal number, no null number and no operational state change.

Protected uncommitted evidence has exactly `{committed:false,receipt:<payload>}` or `{committed:false,association:<payload>}`: no number, no historical `settled`, no operational admission. These are diagnostic types, never journal events or replay inputs.

Late receipts remain visible without reopening disposed calls, removing standing dispositions or restoring session authority. Unavailable or quarantined evidence creates no target. Separately admissible retained association evidence must pass every ordinary and §3a check; any resulting future mapping does not turn a disposed call into success, remove its standing restrictions or erase risk records. No automatic reorder, retry, session restoration or ending of reference duties follows.

### Closed raw and stored grammars

Raw Receipt remains exactly `{source,call,resource,target,binding,validated,returned_vendor}`. Raw Association remains exactly `{target,entry}`. These are closed internal abstractions; their types alone do not perform TLS or vendor validation, and browser metadata is not a vendor response extension. Raw decoding rejects nonobjects, duplicate or unknown members and protected objects where raw scalars or envelopes are required. Vendor data supplies no custody, withholding or browser relation authority.

The exact existing spellings and types are:

- Receipt source: `browser_vendor_tls`, `arbitrary_response`, `job_output`, `notify_event`, `proposed_text`.
- Receipt binding: exactly `{operation,account,signed_request}`, with operation `order`, `stop` or `restart` and two u64 values; these operations map respectively to create, destroy and reset.
- Resource: `{"entry":string}` or `"inference"`.
- Target: `{"entry":string}`, `{"allocation_index":u32}`, `{"vendor_machine":string}` or `"inference"`.
- Receipt call is u64; validated is bool; legacy returned_vendor is a string or canonical null absence. Association entry is string.

Outer journal event kinds remain `operation_receipt` and `association`. Each accepts its exact legacy payload or a distinct browser-produced protected payload with exactly `kind:"protected"`, `version:1`, `facts`, `relations`, `withheld` and optional `custody`. No other member or version, raw duplicate, sentinel, concealed original, raw hash, `settles`, forward equality or positional binding array is valid. Bounded unsigned types are unchanged.

Protected Receipt facts preserve raw member names and types. Source, validated, binding and binding/operation remain truthful and present. Call, resource, target, binding/account and binding/signed_request are retained or represented exactly once in withheld. The whole-fact withholding allowlist is exactly `call`, `resource`, `target`, `binding/account`, `binding/signed_request`, `returned_vendor`. Returned_vendor has exactly three states: absent from facts and withholding, retained string, or withheld-present with no raw member. Null never means withholding in a protected payload. Its optional presence is representable for all three receipt operations; only order uses it as a settlement requirement. Stop/restart acquire no returned-ID requirement. Mismatched received claims and copied post-effect display operands are covered; canonical intent, setup and approval records retain their authority unchanged.

Receipt relations are exactly:

```text
intent: {kind:"none"} | {kind:"earlier",call:u64}
call: no_intent | same | different
resource: no_intent | same | different
target: no_intent | same | different
operation: no_intent | same | different
account: no_intent | same | different
signed_request: no_intent | same | different
returned_vendor: absent | retained | withheld
```

Enum words are JSON strings. None is valid only when the genuine call had no earlier typed intent, and requires all comparison relations to be no_intent. An earlier reference identifies the genuine received call's actual preceding typed intent; the call relation is same, and different is rejected there. Resource and target compare genuine typed operands before omission.

Operation is same exactly when the intent's receipt_binding is present with the receipt's binding operation and that operation maps to the intent's operation by STA-24's receipt table. Account and signed_request are each same exactly when that receipt_binding is present with the equal value. A missing receipt_binding gives different for all three; any other mismatch gives different. Failed comparisons remain failed evidence. Eligibility independently requires BrowserVendorTls and validated=true. Retained operands must agree with the genuine comparison outcomes; outer authentication authenticates the browser's statement, not vendor truth.

An order additionally requires a retained returned_vendor and an admitted durable VendorMachine association with that exact literal and the intent's approved entry. A withheld operand equals nothing in later comparisons. No pair-comparison array or forward equality is introduced; no browser relation reconstructs a withheld identity. A source-withheld order identity prevents receipt settlement even when a comparison had completed before conversion.

Protected Association facts are required target and entry, retained or exactly once withheld. The whole-fact slots are exactly `target` and `entry`. Relations are exactly:

```text
approved_entry: {setup:u64,index:u32}
target_kind: allocation_index | vendor_machine
admission: mapped | quarantined
reason: none | identity_withheld | alias_unavailable
alias_checks: [{record:u64,result:"unavailable"}, ...]
```

The setup reference names the earlier SetupRecord::Approval journal number and the actual reserved u32 machine-family index, never an array position. Its canonical approved entry must equal the genuine raw entry before omission. Retained target kind must agree. Copied entry display withholding preserves that checked canonical reference. Unknown entry, invalid target kind or invalid allocation reservation acquires no protected authority.

For new VendorMachine evidence, the only valid combinations are mapped/none with retained target and empty alias_checks, quarantined/identity_withheld with withheld target, and quarantined/alias_unavailable with retained target and nonempty alias_checks. Every quarantine carries exactly all applicable earlier risk records once in ascending journal-number order, including for identity_withheld; no future, duplicate, irrelevant or missing record is accepted. Apply the risk predicate and retained-evidence identity-conflict rule above. No active-reference shortcut proves equality or distinctness.

From the first risk record onward every VendorMachine association is appended in the protected arm with explicit admission; a raw VendorMachine association appended or replayed after a risk record is rejected as noncanonical and replay stops there. Earlier legacy mappings retain their prior meaning. All arms obey the same historical admission guard; selecting the legacy arm cannot bypass quarantine. No admission field is retrofitted into legacy journal records.

AllocationIndex associations keep the legacy arm. `STA-22b` says "Machine roles share one machine index." `STA-22b` says "Reserve it durably before any external effect, including registering a key for an already-rented server." The genuine target must pass the existing allocation-reservation check, a machine-family index the allocation core holds. It may differ from approved_entry's setup index, since a later attempt for the same entry may reserve another index. A read-only protected projection may omit an obligated copied target or entry, preserving the canonical setup reference and checked mapping; that projection is never new stored evidence.

A stored protected Association whose target_kind is allocation_index is rejected as noncanonical. Projected through the protected fact shell, a legacy AllocationIndex association carries admission mapped, reason none and empty alias_checks.

Required facts occur retained or exactly once withheld; slots are applicable, unique and disjoint from retained fields. Whole-fact entries use §1's exact `{slot,marker,associations}` form and ordering. These owners have no byte-substitution slots. A stored payload with nonempty withheld requires custody with empty substitutions and §4's complete names table. A protected quarantine payload with empty withheld may omit custody; if present, empty substitutions and complete names are validated. Secret-marker associations are distinct from vendor-resource mappings.

Committed record wrappers remain exactly `{number:u64,receipt,settled:Vec<u64>}` and `{number:u64,association}`. Stored decoding selects one arm, validates closed objects, member uniqueness, applicability, original bounded types, presence, complete custody coverage, causal references, historical admission and all retained comparisons, then reproduces that same canonical event. Reject duplicate/unknown members, invalid versions/types/slots, overlap, missing presence, contradictory retained facts, invalid references and noncanonical round trips. Historical proofs use the authenticated earlier prefix, never today's armed set. Raw constructors and stored constructors remain separate.

### Independent recovery and exact targeting

The recovery predicate has its sole operative home in [STG-21a](../../06-first-stage.md). Applying it afresh establishes its own durable identity and approved-entry association; it asserts no equality to an erased returned ID. Same-entry recovery may succeed only when the selected retained identity passes all admission checks. It never erases the old cross-entry risk. While a different-entry risk applies, no recovery predicate in this construction can satisfy that exclusion.

Resolve(VendorMachine(id)) succeeds only through an admitted durable exact-literal mapping. A withheld ID, quarantine, marker, receipt or association number, or independently generated handle resolves nothing. Entry and reserved allocation index still identify the resource and barrier but cannot synthesize a vendor literal. An operation requiring an unavailable literal refuses before send, including stop, restart, renewal-off, deletion and reads whose wire path needs it. Bare Association input, ordinary by-ID read, operator claim, disposition, new handle or same-account guess supplies no independent recovery predicate. Existing retained exact-call receipt/association confirmation remains available.

End or abandonment reports possible continued existence and billing, unavailable identity and unconfirmed stop/deletion. It claims neither successful cleanup nor ended billing or duties.

### Originating input lifetime

A newly received genuine literal may remain in the originating private input/conversion scope only through raw validation, genuine comparisons and protected construction. When that construction withholds it, clear its recoverable input buffers and aliases before returning the protected object, awaiting its append or scheduling a continuation. Neither Dispatch nor a side cache retains the withheld received original. Failure/cancellation clears that scope too; subsequent diagnostics use protected evidence.

This rule concerns initial received-evidence conversion. Withholding a later display copy does not erase independently retained canonical facts or authorize reconstructing an originally withheld identity. Existing canonical facts retain their own custody and pre-send checks. No retention until worker termination, pending map, error-value copy, retry copy, callback handoff, alternate encoding, concealed encryption/hash or release/send authority is added. A completed historical comparison cannot reconstruct a withheld identity. Prescribed K/R/L storage and adopted lifecycle duties remain unchanged. No separate physical-memory zeroization guarantee is asserted.

## 4. Intrinsic substitution facts and names

Each payload has at most one `custody` object with exactly `version:1`, `substitutions`
and `names`. `names` is the complete association table specified below; it is empty
only when that owner uses no association (for example credential-only substitutions). Scalar-only
withholding can therefore need custody with an empty substitution array.
Each substitution has exactly `slot`, `start`, `end`, `constructor`, `associations`.
`constructor` is `credential`, `named` or `index`. Offsets are nonnegative integer byte
indices into the final substituted logical slot, half open and sorted by slot then start;
ranges do not overlap and obey `start < end <= logical_length`, without integer overflow.
They describe inserted output length, never removed length, raw bytes or raw digest.
`credential` emits exactly `<redacted>` and has no associations. Other constructors use
the names and deterministic fallback below. Scalar/whole-fact withholding is owned only
by `withheld`; its slot cannot also have substitution facts.

| Custody owner | Allowlisted logical slots |
|---|---|
| Job Evidence, legacy | `/record/stdout`, `/record/stderr` |
| Job Evidence, protected | `/record/facts/stdout`, `/record/facts/stderr` |
| OperationResponse | `/body` (decoded from its lowercase hex) |
| InferenceTerminal, legacy | `/reported_provider`, `/request_id` |
| InferenceTerminal, protected | `/facts/reported_provider`, `/facts/request_id` |
| OperationReceipt, protected | none; whole-fact slots defined in §3a only |
| Association, protected | none; whole-fact slots defined in §3a only |

Receipt whole-fact slot locations are `/facts/call`, `/facts/resource`, `/facts/target`, `/facts/binding/account`, `/facts/binding/signed_request`, `/facts/returned_vendor`. Association locations are `/facts/target`, `/facts/entry`. Each omission has exactly one owner-relative named withholding entry and no substitution span.

Stored-evidence validation and read-only projection validation are distinct contexts. A projection may withhold an additional display field of an already committed record while preserving historical relations, admission, reason, alias_checks, number and settled vector. A source-retained returned_vendor relation may accompany a newly withheld display token, and a source-mapped VendorMachine association may have its target display withheld. These combinations are permitted only in projections, never new stored evidence. AllocationIndex storage and read-only projections follow §3a’s AllocationIndex rule.

Projection-only omissions use the same member names, allowlists and single withheld array. Existing withholding remains withholding; retained neighbors remain equal; original absence remains absent. Legacy records needing protection are projected through the protected fact shell, with historical relations derived from their genuine facts and actual earlier prefix, never a future intent. Projection objects are never submitted to settlement, resolution, association admission or journal constructors.

An order receipt whose canonical identity was withheld cannot settle that order or be its settling constituent. Later display withholding cannot undo an already recorded settlement or create an unavailable-identity risk. Historically settling retained-identity receipts and mapped associations may therefore have protected displays. Stop/restart keep their own exact-call predicates.

Apply the payload locations under these exact source-bound prefixes:

| Representation | Payload prefix |
|---|---|
| Journal event | `/operation_receipt`, `/association` |
| Inspect/direct export | `/receipts/{i}/receipt`, `/association_records/{i}/association` |
| Disposition receipt constituent | `/issues/{i}/settling_record/record/receipt/receipt` |
| Optional disposition association constituent | `/issues/{i}/settling_record/record/association/association`, only when present |
| Nested inspect disposition report | prepend `/dispositions/{j}/report`, only when its report carries issues |

Live committed wrappers preserve their numbers and receipt historical settled vectors. Uncommitted diagnostic payloads use the §3a `{committed:false,…}` wrapper and never acquire an invented number. Flattened `/typed_calls/{i}/receipt` and `/typed_calls/{i}/association` references are generated record numbers, not vendor identities.

In `/typed_calls/{i}`, and in each OperationIntent at `/calls/{i}` of a typed-barrier result, the additional display-withholding allowlist is exactly resource, target, receipt_binding/account, receipt_binding/signed_request, approved/resource, approved/target, approved/receipt_binding/account and approved/receipt_binding/signed_request. Each omitted field has its owner-relative slot in that object's single optional withheld array. The resource, target, approved/resource and approved/target slots apply independently of receipt-binding presence. The receipt_binding/account and receipt_binding/signed_request slots apply only when the intent's original receipt_binding exists; the approved/receipt_binding/account and approved/receipt_binding/signed_request slots apply only when the original approved.receipt_binding exists. Existing binding objects and all operation discriminants remain present; absent bindings remain absent.

These read-only copies are identified by the unchanged generated call number; nested approved fields belong to that call's recorded approval. They do not modify canonical intents or approvals, introduce a binding, change state or authorize dispatch. The projection receiver accepts precisely these omissions and rejects contradictory retained fields. The final name table owns their marker associations. This inventory covers these copied resource, target and binding fields; it does not replace other protected-object inventories.

Every actual enclosing report, direct store_state export, tool result, model history, transcript, worker post, page cache or DOM representation containing these objects preserves useful structured records, entry identity, calls, controls and the live attributed tree, then re-finalizes at the actual release after wrapping. Direct store_state export is an independent sink. Propagation through enclosing publishers is conditional on their existence; no receipt-specific production adapter or page publisher is asserted.

Each final object emits one complete creation-ordered/reindexed top-level withheld_names union and omits nested serialized custody while retaining live origin trees. Apply the existing logical/hex/JSON/lossy/rendered-join construction, actual serialized and DOM joins, nested JSON strings and page-cache repair. Re-finalization never restores a withheld token. External marker spellings remain Carried; equal strings or matching markers create no identity authority. Safe neighbors and useful records stay visible. Canonical intent/setup/approval records remain unchanged by display conversion.

Goal tool-result history in this construction is transient context, not a new durable
event. It retains the same live origin tree through its untrusted-content wrapper and is
re-finalized at each actual release. No Goal tool-result custody event is invented. All
output-only durable redactions have custody even if no protected scalar variant is needed. Other persisted mutable text is Carried; a newly added site must
extend this closed table upstream, never guess by marker spelling.

A registered association is exactly `{kind:"registered",placement:N}`: replay resolves
the unchanged canonical name and creation order from that earlier placement. A transient
association is exactly `{kind:"transient",id:H}`, where H is the independently generated
24-byte lease identity in lowercase hex. Its accepted card name resides in the owner's
`names` table, never in an association field. Before schema validation supplies
a name, use `{kind:"unregistered",id:H}` and the fixed display label `unregistered input`.
Transient creation order is actual receipt order after registered references. These forms
assert no placement, arming, approval or persistent key. The private constructor binds them
to the actual still-live lease, including refused/stale input; authenticated storage asserts
that historical binding. Replay validates shapes, unique identities, registered causal names,
complete table coverage and canonical ordering. Transient names/order are authenticated
historical constructor assertions, not reconstructed machine claims. No association carries
K, R, L or a raw value.

The `names` array has one row per association used by that sealed owner plus every armed
and entering association the finalization union can obligate. Initialize this complete
superset before repair; membership never grows during repair. Rows are in actual creation order. A registered stored row
has exactly `association`, `ordinal`; its canonical name is resolved from the earlier
placement and is not duplicated. A transient or unregistered stored row has exactly
`association`, `ordinal`, `name`, in that order. Its name is the accepted card name or the
fixed label `unregistered input`. `ordinal` is the one-based array position, immutable in
that sealed payload. Duplicate associations or ordinals are invalid. Every stored transient
name and the actual full encoded table pass custody before the introducing write; schema
validation alone supplies no admission or raw-name-emission authority.
A transient stored row whose name fails custody instead has exactly `association`,
`ordinal`, `name_withheld`, in the projected-row shape below; its marker is emitted in
index form. It is an authenticated historical constructor assertion; every later
projection renders it unavailable and never restores it. P counts stored transient
names as non-span mutable contributions.

A canonical placement name remains unchanged in its journal record. Every name copied
into a newly composed report, listing, control, table or rendered text is a mutable display
fact, including names resolved from older sealed transient rows. A projected raw row has
exactly `association`, `ordinal`, `name`. An obligated row instead has exactly
`association`, `ordinal`, `name_withheld`. `name_withheld` has exactly
`slot:"name"`, `marker`, `associations`; it contains no original name, name hash or length.
Its marker is emitted directly in index form. This row retains the association, listing
entry, ordinal and existing generated control identity; its explicit unavailable-name
display is exactly its index-form marker. It never recursively expands a marker to a raw name. Raw projected
rows are emitted only after the entire logical/encoded/rendered projection passes against
the full armed-and-entering union. A later independent safe projection may show the
canonical name again; a retained repaired entry never restores a withheld raw name.

No guard, padding or table/marker field whose length or contents are selected by the value,
reference length, digest or other scan material is emitted. K, R and L remain private to
the worker and their prescribed encrypted local storage. In textContent each row is `#`,
its decimal ordinal, `=`, its protected name display, then `;`, with those actual joins
checked. For a `name_withheld` row the display is exactly its index-form marker, so its
textContent is `#k=[withheld:#k1,#k2,…];` (singleton `#k=[withheld:#j];`). Generated control identities grant no new operation authority.

Ordinals are scoped to one final projection object. A report, tool reply, delivery or
inspect view, unresolved job_record or page store report containing or flattening one or
more owners emits exactly one top-level `withheld_names` table: the creation-ordered union
of every association used anywhere inside it plus every armed and entering association
the finalization union can obligate. Initialize that complete superset before repair. It omits nested `custody` objects. Every index marker within it, including
nested hex and lossy-text copies, is re-emitted from its association array with this
projection's ordinals before re-finalization. Transient in-memory origin trees retain
constructor facts across that projection; removing serialized custody does not erase them.
The durable owner keeps its own unchanged custody. Within one final object one ordinal
never names two associations. A model tool result or transcript release carries its own
table whenever it contains an index marker; a table in a different message is insufficient.
Names have the same protection in that table as in the ordinary report.

Both credential-substitution mechanisms emit facts: declared JSON-pointer replacement at
its actual attributed serializer, then merged byte-needle replacement. Stage-two ranges
absorb intersecting stage-one ranges and shift all remaining spans by actual length changes.
The final facts name exactly the inserted ranges. Application-output matches are unioned
across overlaps and record every matched reference in creation order. Separate output
streams never share a tail.

Names remain Carried. Literal marker segments are Fixed, and ordinal indices are Generated.
Neither a name's shape nor successful authentication changes that attribution. The normal
application marker is `[withheld:` plus actual names joined by `,` in creation order plus
`]`. Replay never parses names out of that text; it validates it using the association array.
Commas, brackets and escapes inside a name therefore cannot change association.

For a name-conflicting marker, the index form lists every matched association's
payload-local ordinal, in creation order: `[withheld:#k1,#k2,…]`; the singleton is
`[withheld:#k]`. Replay validates exact agreement with the association array. All literal
parts are Fixed; ordinals are Generated. Canonical journal names are never rewritten.

Actual-history admission checks canonical records and sealed tables unchanged against the
entering reference and may refuse before effects. Refusal does not discharge custody of
its callback: the entering lease still covers that callback's projected names, including
an existing canonical name equal to the refused value. Those display copies use the
protected rows above. The impossible promise that the unchanged literal name always stays
visible in the same callback is withdrawn. This changes display copies only, never the
canonical placement, source truth, distinct association or control identity.

Finalization unions obligations and rechecks every logical, encoded, metadata and rendered
join. Inside a span-bearing slot the repair unit is the preserved carried byte. A forbidden
window touching preserved carried bytes absorbs exactly those covered bytes into one
substitution, merging substitutions it touches or abuts. The merged marker's association
array is the creation-ordered union of all new and merged obligations; it stays in index
form if any merged occurrence was already indexed. A non-span mutable contribution,
including every projected or stored transient name and post-effect display operand,
is replaced whole once.
A forbidden join touching an inserted normal marker's carried name and no preserved
carried byte converts that occurrence once to index form. Index bytes and the index marker
used for an unavailable name contain no carried name. Complete tables are initialized before this
algorithm; a repair neither adds a new mutable name fact nor exposes a raw name again.

The strict measure is (P,N): P counts carried bytes in unreplaced mutable contributions,
including preserved output bytes and every projected or stored transient name; N counts normal-marker
occurrences carrying names. Absorption or whole replacement decreases P; index conversion
keeps P and decreases N. Repairs never increase P, revert an index marker or recursively
expand a withheld name. At P=N=0 all remaining carried bytes belong to immutable required
facts checked at their introducing pre-effect act; their later display copies are mutable.
The actual final scan proves no forbidden window survives. No post-effect refusal,
omitted callback, early lease clearing, random spelling or marker-search heuristic is a
completion. A failed constructor assertion is a design failure, never accepted evidence.

Origin maps propagate through the actual encoder: hex doubles byte coordinates; JSON
escapes retain the source segment's origin; lossy UTF-8 propagates the union of origins of
bytes consumed for each output scalar, including the three UTF-8 bytes of U+FFFD. It never
copies raw offsets to lossy text. Rebuilding any slot invalidates old offsets. Replay
verifies exact constructor bytes after decoding the logical slot. All unlisted external
bytes remain Carried. New inserted and external identical markers consequently differ;
legacy records without facts conservatively treat both as Carried and remain byte-identical.
This is forward reading of old stores; old binaries may reject new fields or variants.

## 5. Scan reservations and attempt fences

Encrypted detachable scan plaintext is the exact JSON object `key,reference,length`, in
that field order. key and reference are arrays of exactly 32 unsigned byte integers (K and
R); length is the exact unsigned byte count L, at least the existing minimum. No other
field or duplicate identity is accepted. It is encrypted under the existing data key. Its file is `scan-` plus an
independent 24-byte lowercase-hex identity. Its JSON is exactly `nonce,ciphertext`, using
unpadded base64url, a fresh 12-byte nonce and AES-256-GCM. AAD is
`tau-web/local/v1/<store-id>/scan/<scan-id>`. This is the prescribed encrypted scan-reference
storage, not raw-value encryption or an additional source of authority. K, R, L and the scan blob never enter the page, journal name table, model context,
transcript or recovery sheet. No delimiter or padding exports their length indirectly. Replaced/retired material is removed only
after its authoritative successor/lifetime event commits; its reservation stays consumed.

`scan_reservation` records only the unique scan identity. `placement` records that identity
and the approved placement facts; `reference` links an existing placement to its new scan
and true pasted/cross-check facts; `digest_candidate` links its scan, placement and genuine
digest call; `digest` and `digest_not_sent` retain genuine call/status; `reference_required`
removes working arming without retiring inventory; `lifetime_ended` uses only the existing
authoritative rotation/destruction transition. A candidate never replaces an intact/pasted
reference merely because it arrived. Disposed evidence arms nothing; late evidence is a
cross-check. Every link must resolve an earlier unique reservation and the correct causal
placement/call before replay applies it. An orphan reservation is spent, not armed.

Let B be 2^32. Accounting applies only to data keys authenticated as born under the fenced
protocol by the local-envelope extension in credential format v1. J is the committed
numbered-record count, including seed record 0 and any snapshot; S counts all committed
scan reservations, even unused or removed ones; F counts permanent `attempt-<n>` files.
The durable upper charge is J+S+F. Checked arithmetic rejects a charge reaching B. An
ordinary journal attempt requires J+S+F+1 < B. A reservation requires J+S+F+2 < B, covering
its record and its one scan AEAD. No attempt, reservation or removed blob refunds a charge.
No reservation resumes after restart. At most one scan AEAD occurs per reservation.

A clean legacy directory cannot prove remaining lifetime budget: the old writer encrypts
before creating staging, so identical files can hide any number of failed no-file attempts
across restarts. Legacy replay does not certify that history. A v1 local envelope is never
upgraded or rewrapped as a fenced envelope under its old data key. A nonempty valid legacy
prefix remains readable for protected read-only reports; every data-key encryption and
remote effect requiring a durable intent is refused with `legacy encryption budget
unprovable`. A seedless legacy envelope produces a structured operational refusal with
exact reason `legacy encryption budget unprovable`, not a seedless unlocked Store. It does not call allocation(), generate a replacement seed,
start a session, reseal records or silently migrate keys. Legacy-shaped payloads can still
precede protected payloads in a store whose key was born fenced. Read-only reports label
this eligibility state with exactly `encryption_eligibility:"legacy_read_only"`; legacy
payload readability is not legacy append credit.

For a fenced key, before every data-key journal encryption including seed record 0, first
check the exact proposed sentinel's custody and the charge; then durably write and close
`staging` as exactly the fixed ASCII bytes `tau-web append attempt v1`; read it back and
require byte equality. Only after that readback generate a nonce and perform one AEAD.
Replace staging with the checked exact RecordJson and atomically rename to its number.
Successful rename removes staging and accounts for this attempt in J. Any error latches
this worker failed before another attempt; no retry or overwrite follows an uncertain
operation. The existing one-writer discipline covers accounting, recovery and appends.

On opening a fenced envelope, replay/validate the complete numbered prefix, then recover
staging before any encryption or ordinary report of initialized state. If staging is the
complete authentic canonical next RecordJson, including record 0 with the all-zero
predecessor when the prefix is empty, validate the event and causal chain, rename those
exact bytes to that next number and replay. This completes the begun append with no AEAD;
if the event is a reservation, its scan attempt remains spent and is never resumed.
A semantic or chain conflict with an authentic complete record fails closed.
Otherwise staging of any content (including empty, sentinel or torn bytes) is one unresolved
attempt. Without overwriting or deleting it, atomically move it to `attempt-<n>`, with n
one greater than the largest existing canonical decimal attempt suffix (0 if none).
Require the destination not to exist. Never overwrite, delete, decrypt, replay, modify or
reuse an attempt file. F counts each such file once. A crash during the atomic move leaves
staging or the attempt file, never both or neither; restart relists and accounts that
state before proceeding. An uncertain/failed move stops this worker's appends. No AEAD
is performed during recovery. New attempts use J+S+F, so interrupted-before-AEAD attempts
are conservatively charged and interrupted-after-AEAD attempts are never forgotten.

After recovery, a fenced envelope with no seed record generates and commits the seed
through the same counted journal procedure, only then constructs the initialized Store
and its allocation state and owes the ordinary seed ceremony. An existing authentic staged
seed is always completed/replayed first rather than replaced. A torn/uncommitted seed
attempt can be abandoned as a counted attempt because no canonical seed was committed.
With no committed envelope, staging is only envelope-creation debris: create may overwrite
it as today, because this protocol performs no data-key AEAD before envelope commit.
Wrapping-key operations do not consume the data-key bound. Passphrase rewrapping preserves
the authenticated birth protocol and never shares a live journal-attempt staging slot.
This is a counted restart, not permanent read-only operation for fresh fenced stores.
No new key migration or legacy history reconstruction is implied.

The reservation already durably covers a scan attempt even if encryption/write never
happens. Scan blobs write once to `scan-id` after their committed reservation, rather than
reusing journal staging. An uncertain blob write stops the worker; restart authenticates
only blobs referenced by committed live events and never resumes that reservation. Missing
or invalid required live material keeps the corresponding reference unarmed and its
existing release/command barrier; it cannot be certified by an orphan blob. Read-only
reporting remains protected by available references and the ordinary unarmed barrier.

| Transition | Durable state / charge | Applied state and permitted next action |
|---|---|---|
| No envelope, at most envelope staging | No data-key AEAD | Create fresh key/envelope; overwrite only envelope debris. |
| Fenced envelope, no record/no staging | J=S=0; F counts all existing attempt-<n> files | After accounting/recovery, finish creation through the counted seed procedure only if J+S+F+1 < B; never report seedless initialized state. |
| Fenced envelope, no record and seed staging | Complete authentic next seed or unresolved attempt | Rename/replay exact complete seed, or archive/count F then perform new fenced seed append. |
| Seed committed, staging absent | Seed included in J | Ordinary initialized reporting and seed ceremony remain owed. |
| Legacy nonempty/seedless envelope | Historical AEAD count unprovable | Nonempty protected read-only report / seedless structured refusal; no data-key AEAD or remote intent. |
| Create entering lease / derive scan | No write; charge unchanged | Pending protection only; validate actual history/names/facts. |
| RNG/preparation failure before fence | No AEAD; charge unchanged | Final protected reply; no contact or scan file. |
| Closed/readback journal fence | One unresolved attempt may be spent | Only this worker may finish that attempt. |
| Reservation commit | J+1,S+1 | Unique reservation applied once; at most one scan AEAD in this worker. |
| Scan RNG/AEAD/write failure | S remains charged, even with no AEAD | Never retry/resume identity; no placement/reference apply. |
| Scan blob success | Precharged authenticated blob | Pending only until causal placement/reference/candidate commits. |
| Blob landed then error | S charged; blob may exist | Stop worker appends; replay never resumes reservation. |
| Placement/reference/candidate append | New counted journal attempt | Commit before causal apply; old authority retained until success. |
| Journal fail/torn write/uncertain rename | Prefix plus staging or numbered file | Stop worker; recover exact valid staged record or archive/count unresolved attempt before next AEAD. |
| Rename landed then error, no staging | Numbered file accounts in J; reservation in S | Old worker applies nothing; fresh replay applies once, never resends. |
| Restart with authentic next staged record | No additional AEAD | Validate/rename/replay exact bytes; scan reservation never resumed. |
| Restart with other staging | Atomic move to unused attempt-n; F+1 | Prefix unchanged; counted appends/creation resume under J+S+F. |
| Clean fenced restart | Replay J,S; count F and only committed live blobs | No charge refund/resumed scan; new act requires new reservation/authority. |
| Exhaustion or failed recovery | No nonce, AEAD or remote act | Honest operational failure; preserve inventory/uncertainty. |
| Cleanup | Only obsolete scan blobs removable | J,S,F never decrease; attempt files immutable. |

The entering lease protects the reservation, scan plaintext/envelope, actual typed event,
RecordJson and first storage write. All payload plaintext is checked before encryption;
all actual output bytes are checked before write. Prescribed nonce/ciphertext/AAD/chain
coincidences do not cause retries. Appends remain commit-before-apply. Deliberate failures
must cover every row, including a killed worker between the fence, AEAD and write.

## 6. Atomic page reporting and build coherence

The chosen page construction is one production part-descriptor sink extracted from the
existing reporting functions, with one reducer. Part descriptors are transient internal
values, not a wire render plan or a second templating language. Existing DOM controls,
attributes, IDs, formulae, order, overwrite and append behavior are retained. Worker and
page import that same module. The worker evaluates text and aggregate sinks with origins;
the page applies them to the DOM without scan material. Actual final DOM order comes from
the shipped skeleton, including whitespace and hidden nodes, rather than function-call
order. Attribute values and per-node text are checked as well as each containing reporting
root and the full ordered body text.

The worker-global final publisher and goal-outcome mirror live in Wasm and are reachable
by both JS reportStore paths and the independent inference and requirements publishers.
It preserves each publisher's real rename/spread behavior and the nested requirements_store
JSON string. It finalizes the actual object and actual JSON.stringify order after wrapping;
no await, rename or new carried interpolation follows its synchronous final check/post.
Direct exports are independent checked sinks.

A store report may carry optional `goal_outcome_repairs`, an ordered array of existing
`{session,outcome}` tuples. In requirements_store it is inside the existing report string.
No other new page message kind or durable cache is introduced. The worker tentatively
normalizes the real report, applies its ordinary outcome to its mirror, repairs every
obligated existing entry, and emits repairs in existing cache order. The ordinary outcome
and a repair for that same session must agree exactly. Genuine done/unresolved/refused,
HTTP class, call/session association and retained ordering cannot change.

Projection equivalence is checked field by field: retained fields equal the old candidate;
a raw received field may become its explicit named withholding, preserving source presence;
a retained/withheld status keeps the genuine HTTP class; done/unresolved/refused and call/
session identity are unchanged. Refusal text may become its marker while retaining the
refused outcome. Protection metadata may be rebuilt by section 4: an existing normal marker
may become its index form, projected names may become name_withheld, association tables and
ordinals are rebuilt together, and coordinates follow the resulting logical bytes. The
table retains the same or a superset of associations. It never removes an association,
restores a withheld raw token/name or reverts an index marker. These changes preserve source
presence, genuine outcomes and association identity; every index resolves in the rebuilt
final projection table. No unrelated semantic field may be inserted, deleted or changed.

The page validates on a temporary cache before mutating its live cache. It checks array
shape, existing targets, unique sessions, typed semantic outcome equality, unchanged entry
set/order after the ordinary update, and exact ordinary/repair duplicate equality. It
commits the whole cache and renders once. It never renders or commits a partial batch.
An unknown target, conflicting duplicate, invalid protected fact, changed outcome or deleted
entry leaves the cache unchanged and replaces all reporting roots with only
`Harness failed: inconsistent report.`; stale reporting text is unmounted. No scalar fallback
or unrepaired report is rendered. The worker runs the same temporary-cache validator as
the page on the same previous cache and ordered ordinary update and posts only accepted
objects. A rejection posts no repaired report and commits no mirror. The synchronous post
success then commits the matching worker mirror. Current-worker/epoch checks reject stale
messages; receiver mismatch remains a failed construction assertion, not normal progress.

For uncommunicated page-local state, the shared construction checks the finite actual
alternatives: persistent-storage text initially empty/granted/refused; redisplay suffix
off/on when applicable; starting/working/passphrase mismatch; status ready/failure; and
seed words shown/cleared. Legal transitions use the same construction. It does not claim
to mirror an asynchronous persistence result. Cache clears remain only at the existing
start/Lock reset; ordinary hidden/return behavior follows the separately adopted lifetime
rule without a new reset. Worker loss and initialization use exactly
`Harness failed: the worker did not load.` and never echo external exception text.

The seed ceremony keeps the existing sequence: publish the store report (whose render
clears word nodes), then obtain and separately publish seed_backup_display if present.
The worker checks (1) the complete aggregate after the store post with words cleared and
(2) the complete aggregate after the display post with the actual twelve word nodes in
order, without inter-word separators added by the list. Text at this prescribed display
sink is Authorized mnemonic material, never a carried application-input slot. The seed
bytes remain worker-private except for this existing authorized display. A match wholly
within those authorized words and fixed text is permitted. A mixed match touching mutable
store error/refusal/cache content repairs that contribution before its post; no word is
redacted, reordered or dropped. Word removal, answer/skip, local lock, worker error and a
concurrent publisher's clear-on-render are checked intermediate states. Placement dispatch
still refuses during the ceremony, but entering refused transfers remain protected through
their callbacks. Existing live references, persistent restored references and current
entering leases all participate. Display finalization happens synchronously against the
then-current report/mirror before its actual post; no stale aggregate certificate is reused.

The build writes the complete runtime closure (index, boot, worker, shared reporting module,
glue, Wasm and other runtime imports) under one immutable `releases/<sha256>/` directory.
The digest is over a sorted length-delimited manifest of relative paths and exact bytes
built in a temporary directory; URLs inside the closure are relative, so no self-hash cycle
exists. The root entrypoint only navigates to that release's index and is not a runtime
script supplier. Publish the complete addressed directory before changing the entrypoint;
never overwrite it or redirect a missing dependency to a different release. Missing imports
fail before accepting transfers. A same-release old page cannot load a new worker.
Retain old mutable dependency URLs unchanged during transition; do not place a batch worker
at an old unversioned URL. Old pages that ignore batches are unsupported receivers, and
this addressing construction prevents that receiver pairing without a runtime handshake.
The served-file/CSP/absence checks and tracer discover and validate the addressed closure;
no service worker or weakened CSP is added.

## 7. Required demonstrations

For required demonstrations, see CNF-95(g) in [the conformance checklist](../../07-conformance.md).
