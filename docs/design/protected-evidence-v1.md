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

The legacy terminal remains readable. A protected terminal has exactly `kind:"protected"`,
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

A withheld minted identifier cannot install a usable session key, name a completion or
name a revoke. It retains the originating mint association and the no-second-mint barrier.
The live session credential is cleared. End/sweep reports identifier unavailability and
that revocation is unconfirmed; the requested expiry remains visible as the remaining
limit. It never claims revocation, erases the outstanding mint or starts a substitute mint.
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
