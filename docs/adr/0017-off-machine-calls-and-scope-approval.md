# Off-machine calls generalize the cloud plane; untyped ones are approved by scope

The cloud plane covers **any action taken off the operator's machines with a credential they
supplied** — not only infrastructure operations at a cloud vendor. It carries two approval
modes:

- **Typed operations** — an adapter exists, so the action is expressed as structured facts
  and approved individually. This is the cloud plane as
  [ADR-0002](./0002-cloud-plane-and-box-plane.md) defined it, unchanged.
- **Untyped calls** — no adapter exists. The operator approves a **scope**: this credential,
  this origin — scheme, host, and port, exactly as the consequences below require. The
  harness shows what it knows, records every call before sending it, and
  **claims nothing about what the credential can do.**

We chose this because the harness makes authenticated calls on the operator's behalf and the
old taxonomy had nowhere to put them. A call to a third-party API is not an infrastructure
operation at a vendor, and it is not shell on a machine the operator owns — and each plane's
safety argument turned out to cover only its own half.

The real axis was never cloud-vendor-versus-machine. It is **off-machine versus on-machine**:
off-machine acts at a third party and can spend or publish, on-machine can ruin one server
the operator already bought. That is the distinction
[ADR-0002](./0002-cloud-plane-and-box-plane.md) was reaching for, and stating it this way is
what lets the plane generalize without the blast-radius reasoning collapsing.

## What the operator is actually agreeing to

Not a set of actions. **A credential's authority.** A full-access key approved for one host
has authorized everything that key can do at that host, for as long as it is valid, whatever
the brief intended at the time. A read-only or spend-capped key bounds the damage by
construction.

So the boundary is the credential, and the harness does not control it. It could ask for the
narrowest key that works and describe what that key authorizes — but for most services it
cannot determine the answer, and a bound stated on a guess is worse than none. It therefore
**states what it knows and asserts nothing further**, in the same discipline as the rest of
this design: no verification layer, no implied guarantees, no number that looks like a bound
and is not one.

## Considered options

**Typed adapters only**, with a service callable solely where an adapter exists and adapters
shipping signed like briefs ([ADR-0005](./0005-briefs-ship-in-the-signed-bundle.md)). This
keeps "enumerable, therefore approvable" true everywhere and was the tempting answer.
Rejected because it narrows the platform to services someone has already adapted, which
forecloses the ad hoc and unforeseen use cases that are the point of a platform, and puts a
release between an operator and any new service.

**Refuse credentials the harness cannot bound.** The only option under which the approval
means exactly what it appears to mean. Rejected as unimplementable: most services publish no
machine-readable statement of what a credential authorizes, so this refuses nearly
everything.

**Per-call confirmation for untyped calls.** Rejected because it abandons scope approval for
the case it was chosen for, reintroduces the interleaved-popup fatigue
[ADR-0009](./0009-one-device-concurrent-sessions-batched-approval.md) rejected, and still
shows a non-technical operator a raw request they cannot evaluate.

**Run arbitrary calls from a machine instead**, as box-plane work, so the blast radius stays
bounded to hardware the operator owns. Rejected because the credential would have to reach
the machine, breaking the invariant that credentials never leave browser memory and making
the machine a party that can act — the precise thing
[ADR-0003](./0003-the-ai-runs-only-in-the-browser.md) exists to prevent.

## Consequences

**Recording is now a safeguard rather than a convenience**, and it is the only one standing
behind an untyped call. Every off-machine call made with an operator credential is recorded
before it is sent, which is why this is an invariant rather than a described behaviour.

**The interface must not present a scope as a bound.** "This host, this credential" describes
where the key goes, not what it can do. An approval screen that reads like a limit while the
operator is authorizing a key's full authority is the same overstatement this design refuses
everywhere else — and it is easier to commit here, because the honest wording is less
reassuring.

**The box plane's blast-radius argument no longer covers everything.** "Free-form is
acceptable because the worst case is one machine you already paid for" is still true of
box-plane work and was never true of off-machine calls. Both planes now carry their own
reasoning rather than sharing one.

**Narrow credentials are the operator's lever and nobody else's.** The harness can neither
create nor verify them. Where a service offers scoped keys, using one is the only thing that
actually reduces the exposure — and the product should say so, without implying it has
checked.

**A scope never names a vendor the harness knows, and typed operations are bound to the
session's machine.** The
new-service case this record exists for is a *third-party* service. A cloud vendor's
control API is different in kind: its credential reaches every machine on the account,
including machines other sessions are bound to, and with no adapter the harness cannot
see which resource a given call touches — so an untyped scope there would hand one
session a path around the access invariant that nothing records at the machine level.
Vendor APIs are typed operations or nothing; a vendor with no adapter is not yet usable,
which is the cost of keeping the isolation claim true. Typing alone is not enough — an
adapter MUST refuse a typed operation naming a machine the calling session is not bound
to, because a displayed-and-approved delete of the wrong machine is still the wrong
machine. And the refusal has an honest boundary: only *known vendors* can be classified
by hostname. A third-party deployment or networking service — a CI runner, a mesh VPN —
may well administer machines, the harness cannot know, and that unknown authority is
precisely what the blast-radius statement counts an active scope as. The ban is
enforceable where classification is; everywhere else the claim narrows instead of
pretending.

**An untyped response can carry a secret the harness cannot see.** A call that mints or
rotates a credential returns it in a response whose schema no adapter understands, so
nothing can reliably redact it before the response reaches the model and the record. The
harness does not pretend otherwise: minting credentials through an untyped call moves the
new secret into model context and into the transcript, the interface must not imply the
response was scrubbed, and a brief that needs a fresh credential should say the operator
mints it at the service and supplies it — the path every other credential already takes.

**One redaction is enforceable, and it is mandatory: the harness's own held credentials.**
A service can echo the key it was sent — account endpoints do — and that key is a string
the harness holds and can recognize. Every untyped response is scanned for the harness's
held credentials before it reaches the model or the record, and any occurrence is
redacted; without this, one echoing endpoint forwards a harness-held credential into
model context against the credential invariant. The scan sees exact values only — an
encoded or transformed reflection is beyond it, which belongs to the honest limit above,
not to a claim of scrubbing.

**An approved scope adds a trusted party for the life of the credential, not of the
approval.** The service behind an untyped
call holds a credential the harness cannot bound, which puts it in the elective trust tier
as a class — unenumerable in advance, so it is the one entry the trusted-party list names
as a class rather than by name. Each scope has to appear in the trust display **until its
credential is revoked or rotated**: closing the approval stops new calls, but it does not
invalidate a bearer key the service has seen, erase copies the endpoint kept, or undo
anything set in motion while the scope was open — so removing the entry at mere closure
would understate a live exposure.

**A scope is an exact origin, and cross-origin redirects are not followed.** "This host"
must mean one origin, because browsers follow redirects automatically, and a credential in
a custom header is carried to the new origin — a body too, under 307/308. (A query-string
credential is not replayed by the browser; only a server echoing it into the redirect
target forwards it.) An approved host with an open redirect would otherwise forward the
credential to
an origin nobody approved, in a request sent without being recorded — breaking both the
scope's meaning and the recording invariant at once. The mechanics leave exactly one safe
setting: under browser fetch, following is automatic unless disabled and the redirected
request is transmitted before application code can compare origins, while a disabled
redirect comes back opaque with its destination hidden. So scoped calls are sent with
redirect following disabled, a redirect response ends the call, and the new endpoint — if
it is wanted — is a new scope the operator approves from what the service documents, not
from a response the browser will not show.

**Calls are direct-first, and CORS decides only the path, not the reach.** The browser
reaches a service itself wherever the service permits a browser (CORS); where it refuses,
the call may ride the relay as a **tunneled fallback** — TLS terminating in the browser,
the relay carrying ciphertext to a destination its policy allows — so a CORS-refusing
service is a routing fact, not a dead end
([ADR-0019](./0019-the-publisher-operates-the-default-relay.md)'s amendment: the relay is
never in a path the browser can take alone). **On the direct path, a CORS failure is an
unknown outcome, not a failed call**: for a simple
request — a query-keyed GET, a form-encoded POST — the browser sends the request and only
then refuses to disclose the response, so the service may have acted. Every unreadable
response is recorded as unresolved under the recording invariant's unknown-outcome rule,
never reported as "the call failed," and never retried automatically.

**Content-Security-Policy is not the boundary; approval and recording are.** The
collision an earlier version of this paragraph recorded — exact `connect-src` versus
hosts no release enumerated — is resolved by deciding which side gives: the design does
not restrict what the harness can *reach*, it restricts what runs without the operator's
say. The policy stays exact where exactness is free (the relay's `wss://` origin) and
permissive for `https:`, stated plainly. What contains a subverted session is not a
frozen list but the scope model itself: no credential moves without an approved scope,
every call is recorded before it is sent, and the destination rules above still bind.
