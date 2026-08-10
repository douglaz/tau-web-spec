# SPEC: Rust-First AI Harness PWA with an Async Bash Interpreter and WASI uutils

**Status:** Draft v0.1  
**Date:** 2026-08-07  
**Audience:** Rust, WebAssembly, browser-runtime, shell, and AI-agent implementers  
**Working name:** `tau-web` is used in examples only. A final project name is out of scope.

---

## 1. Executive decision

Build a local-first, installable PWA in which nearly all application logic is Rust compiled to WebAssembly. The application contains:

1. A **Tau-derived harness kernel** for agents, event ordering, provider turns, tools, policy, replay, and recovery.
2. An **end-to-end asynchronous Rust shell interpreter**, derived from the architecture of `rust-bash`, using `brush-parser` for Bash syntax.
3. A **WASI Preview 1 command runtime** that executes official uutils WebAssembly modules such as coreutils, grep, sed, findutils, and diffutils.
4. A **capability-controlled asynchronous tool system** for browser networking, cloud APIs, and later SSH through an optional relay.
5. A **dedicated browser worker** that owns all mutable harness state and persists canonical events and virtual filesystem state locally.

Do **not** attempt to compile all of Tau directly to `wasm32-unknown-unknown`. Current Tau intentionally uses POSIX processes, Unix sockets, native files, PTYs, process supervision, and native HTTP stacks. Instead, extract or adapt its portable protocol, event, tool-registry, policy, replay, prompt, and agent-state concepts into a browser kernel.

Do **not** port BusyBox/`ash` as the primary shell. Its process-oriented shell semantics are a poor fit for browser WASM. Use the Rust shell interpreter for language semantics and uutils WASI binaries for external commands.

The implementation is **Rust-first, not zero-JavaScript**. Hand-written JavaScript must be restricted to a small bootstrap/service-worker boundary plus generated `wasm-bindgen` glue. There must be no TypeScript application layer and no JavaScript AI harness.

---

## 2. Goals

### 2.1 Product goals

The PWA MUST:

- install on modern mobile and desktop browsers;
- run the harness, shell, virtual filesystem, and Unix-like commands locally;
- work as a useful shell/filesystem workspace while offline after assets are cached;
- connect to OpenAI-compatible LLM providers, initially OpenRouter;
- stream model output and execute model-requested tools;
- resume durable sessions after page reload, browser crash, worker restart, or mobile suspension;
- expose explicit user approval for sensitive or destructive operations;
- keep provider and cloud credentials outside model-visible prompts and the shell filesystem;
- support a useful Bash subset including variables, control flow, functions, pipelines, redirections, command substitution, globbing, and here-documents;
- execute real Rust implementations of familiar commands through uutils WASI modules;
- allow asynchronous host capabilities to participate in shell commands, for example:

```bash
agentctl call hetzner.server.list --json '{}' | jq '.servers[] | .name'
```

### 2.2 Engineering goals

The implementation SHOULD:

- share pure Rust crates between browser and native tests;
- preserve a clear path to compatibility with desktop Tau event/protocol formats;
- keep shell and tool execution deterministic where possible;
- use append-only canonical events and replayable state transitions;
- make browser-specific effects replaceable behind Rust traits;
- avoid npm and a JavaScript bundler in the core build;
- permit selected components to be upstreamed or maintained as independent crates.

---

## 3. Non-goals

The first production release does not promise:

- arbitrary native executable support;
- Linux syscall emulation;
- `fork`, `execve`, job control, process groups, or POSIX signals;
- background agent execution after the PWA is closed or suspended by the OS;
- raw TCP sockets from the browser;
- direct SSH without a browser-compatible relay or transport gateway;
- complete GNU Bash compatibility;
- complete GNU/Linux command coverage;
- arbitrary third-party WASM execution downloaded by the model;
- multi-user server-side orchestration;
- protection of browser-held credentials against a fully compromised application origin or successful XSS.

---

## 4. Architectural decisions

| ID | Decision |
|---|---|
| DEC-001 | The primary application and worker code is Rust targeting `wasm32-unknown-unknown`. |
| DEC-002 | The shell becomes asynchronous from public API through command dispatch and recursive execution. |
| DEC-003 | Shell syntax is interpreted; no Unix process model is emulated. |
| DEC-004 | uutils executes as `wasm32-wasip1` guest modules behind a browser WASI Preview 1 host. |
| DEC-005 | The browser harness is a selective Tau extraction/adaptation, not a direct Tau build. |
| DEC-006 | A dedicated worker is the single writer for session, agent, shell, and VFS state. |
| DEC-007 | Canonical events are appended before state transition and before externally visible side effects where possible. |
| DEC-008 | Shell scripts receive no ambient browser network, DOM, credential, or OPFS capability. |
| DEC-009 | Provider and host tools use explicit capability manifests and user policy. |
| DEC-010 | MVP pipelines are bounded and materialized between stages. True concurrent streaming pipelines are a later execution mode. |
| DEC-011 | WASI guests run in disposable command workers where hard cancellation is required. |
| DEC-012 | OPFS stores durable journals and VFS chunks; in-memory state remains authoritative while a worker is running. |
| DEC-013 | The service worker caches assets only. It is not the harness runtime. |
| DEC-014 | UI uses Rust DOM rendering, recommended with Leptos CSR, rather than a JS framework. |
| DEC-015 | The core build uses a Rust `xtask`; generated `wasm-bindgen` glue is accepted. |

---

## 5. System invariants

### INV-001: Single canonical writer

Only the harness worker may assign durable sequence numbers or mutate canonical session state. UI tabs, command workers, provider adapters, and tool adapters submit observations or requests.

### INV-002: Commit before derived state

A canonical event must be durably appended before it is applied to the in-memory canonical projection. If append fails, the transition does not occur.

### INV-003: Commit intent before side effect

A side-effecting tool call must have a durable call record, policy decision, and idempotency identity before execution begins.

### INV-004: No blind replay of uncertain side effects

After a crash, a call that may have produced an external effect but has no terminal event must enter `NeedsReconciliation`. It may only be replayed automatically when the tool declares the operation idempotent and supplies a safe idempotency key or status query.

### INV-005: Exactly one canonical terminal outcome

Every admitted provider attempt and tool call has at most one canonical terminal outcome: completed, failed, denied, or cancelled.

### INV-006: Secrets are not model context

Secret values may never be serialized into prompts, shell environment variables, VFS files, tool schemas, logs, traces, or UI event payloads. A trusted adapter resolves secret references only at effect execution time.

### INV-007: No ambient shell authority

A shell command can access only its virtual filesystem, non-secret environment, standard streams, limits, and explicitly registered commands. Browser fetch, storage, DOM, clipboard, cloud, and relay access require a registered host command/tool.

### INV-008: Durable recovery points

After every user prompt admission, tool approval, tool terminal outcome, assistant message commit, and VFS patch commit, enough state must be flushed to resume without duplicating admitted side effects.

### INV-009: Versioned protocol and storage

All durable records and worker messages carry an explicit schema version. Migrations must be deterministic and testable.

### INV-010: Bounded model loops

Each user turn has configurable limits for provider attempts, model-tool rounds, tool calls, shell invocations, output bytes, elapsed time, and estimated spend.

---

## 6. High-level architecture

```text
┌───────────────────────────────────────────────────────────────────────┐
│ Main browser thread                                                   │
│                                                                       │
│  Rust UI WASM (Leptos CSR)                                            │
│  ├── chat/transcript                                                  │
│  ├── approval cards                                                   │
│  ├── shell console                                                    │
│  ├── VFS browser/editor                                               │
│  ├── provider/settings                                                │
│  └── worker supervisor                                                │
│           │ CBOR messages over MessagePort                            │
└───────────┼───────────────────────────────────────────────────────────┘
            ▼
┌───────────────────────────────────────────────────────────────────────┐
│ Dedicated harness worker: Rust `wasm32-unknown-unknown`               │
│                                                                       │
│  Tau-derived kernel                                                   │
│  ├── event journal + projections                                      │
│  ├── agent/turn state machines                                        │
│  ├── prompt assembly + compaction                                     │
│  ├── provider routing                                                 │
│  ├── tool registry/policy                                             │
│  └── replay/reconciliation                                            │
│                                                                       │
│  Async shell                                                          │
│  ├── brush-parser                                                     │
│  ├── Bash interpreter/builtins                                        │
│  ├── native Rust commands (`jq`, `awk`, `agentctl`, etc.)             │
│  ├── WASI command dispatcher                                          │
│  └── async host-command dispatcher                                    │
│                                                                       │
│  Local services                                                       │
│  ├── in-memory VFS                                                    │
│  ├── OPFS journal/chunk store                                         │
│  ├── browser Fetch/SSE provider adapters                              │
│  └── encrypted secret store                                           │
│           │ command jobs                                               │
└───────────┼───────────────────────────────────────────────────────────┘
            ▼
┌───────────────────────────────────────────────────────────────────────┐
│ Disposable/pool command worker: Rust `wasm32-unknown-unknown`         │
│                                                                       │
│  Rust WASI Preview 1 host                                              │
│  ├── argv/env/fd table                                                 │
│  ├── command-local VFS replica/overlay                                 │
│  ├── stdin/stdout/stderr capture                                       │
│  └── limits/exit capture                                               │
│           │ nested WebAssembly instantiation                           │
│           ▼                                                            │
│  uutils `wasm32-wasip1` guests                                        │
│  ├── coreutils.wasm                                                    │
│  ├── grep.wasm                                                         │
│  ├── sed.wasm                                                          │
│  ├── findutils.wasm                                                    │
│  └── diffutils.wasm                                                    │
└───────────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────────┐
│ Service worker                                                        │
│  Static app shell and versioned WASM asset caching only               │
└───────────────────────────────────────────────────────────────────────┘

Optional same-origin Rust relay:
  CORS-restricted APIs, WebSocket/WebTransport-to-TCP, SSH, or server-held keys
```

---

## 7. Build artifacts and targets

| Artifact | Rust target | Purpose |
|---|---|---|
| `pwa_ui.wasm` | `wasm32-unknown-unknown` | DOM UI and worker supervision |
| `harness_worker.wasm` | `wasm32-unknown-unknown` | Harness kernel, shell, provider/tool effects, persistence |
| `command_worker.wasm` | `wasm32-unknown-unknown` | WASI host and isolated guest runner |
| `coreutils.wasm` | `wasm32-wasip1` | uutils multicall command module |
| `grep.wasm` | `wasm32-wasip1` | uutils grep |
| `sed.wasm` | `wasm32-wasip1` | uutils sed |
| `findutils.wasm` | `wasm32-wasip1` | find/locate family, subject to browser support |
| `diffutils.wasm` | `wasm32-wasip1` | diff/cmp family |
| `sw.js` | JavaScript | Small generated/static service worker |
| `bootstrap.js` | JavaScript | Small `wasm-bindgen` bootstrap and worker entry |
| optional `relay` | native Rust | CORS/SSH/TCP gateway, if deployed |

The uutils core multicall guest should be built using its official WASI feature set. Additional command families should be separate, content-hashed modules loaded on demand.

---

## 8. Rust workspace layout

```text
Cargo.toml
crates/
  app-proto/                 # Versioned UI/worker messages
  harness-proto/             # Canonical event and wire types
  harness-kernel/            # Pure state machines and effect decisions
  harness-policy/            # Tool/capability/approval policies
  harness-model/             # Agent, turn, transcript, usage projections
  harness-runtime/           # Async effect executor
  harness-storage/           # Storage traits, journal codec, migrations
  storage-opfs-web/          # OPFS implementation
  secret-store-web/          # WebCrypto-backed encrypted secrets
  provider-core/             # Provider traits and normalized events
  provider-openai-web/       # Browser fetch/SSE OpenAI-compatible adapter
  shell-core/                # Public async shell API/state
  shell-interpreter/         # brush AST execution, expansions, builtins
  shell-command-api/         # Async command traits and I/O types
  shell-native-commands/     # jq/jaq, awk, archive helpers, agentctl
  vfs-core/                  # In-memory inode/chunk VFS
  vfs-patch/                 # Snapshot, replica, and validated diff protocol
  wasi-p1-core/              # WASI Preview 1 types and fd/path semantics
  wasi-p1-web-host/          # js_sys WebAssembly instantiation and imports
  command-registry/          # Command→module resolution and metadata
  tool-core/                 # Async host tool traits/events
  tool-shell/                # shell.exec model tool
  tool-http/                 # Policy-controlled browser HTTP tool
  tau-compat/                # Tau import/export/schema compatibility
  pwa-ui/                    # Rust CSR UI
  pwa-worker/                # Dedicated harness worker entry
  pwa-command-worker/        # Isolated WASI worker entry
  web-platform/              # Small web-sys wrappers
  xtask/                     # Build, hash, package, test, release
web/
  index.html
  manifest.webmanifest
  icons/
  styles.css
  sw.js.in
assets/
  commands.lock.toml         # Pinned uutils commits and module hashes
```

Crates below `harness-kernel`, `shell-core`, `vfs-core`, and `tool-core` SHOULD compile natively for deterministic tests. Browser APIs belong only in `*-web` and PWA entry crates.

---

## 9. Tau port assessment

### 9.1 Finding

Tau is an excellent architectural source for this harness, but not a directly portable browser application. Its public architecture deliberately separates UI, harness, providers, and extensions into POSIX processes connected over stdio and Unix sockets. The inspected source also contains native process spawning, PTYs, Unix stream ownership, filesystem locks, native provider stacks, and supervisor behavior.

A direct `cargo build --target wasm32-unknown-unknown` would require replacing the defining boundaries of the current system. That would create a large compatibility fork while yielding little benefit.

### 9.2 Adopt from Tau

The browser project SHOULD adopt or extract:

- versioned protocol/event types from `tau-proto` where applicable;
- canonical event sequencing and replay principles;
- tool declarations, schema validation, routing ownership, and terminal outcomes;
- event selectors/subscriptions and in-memory connection patterns;
- agent, session, transcript-tree, and turn projections;
- provider streaming normalization and retry classification logic that is independent of transport;
- prompt fragments, roles, tool policy, model metadata, usage accounting, and compaction concepts;
- commit-before-validation/effects boundaries where they fit the browser model;
- trace/export formats where practical.

### 9.3 Refactor before reuse

The following should be extracted behind new browser-neutral traits:

- durable append/read/snapshot storage;
- clocks and timers;
- random/ID generation;
- provider transport;
- secrets;
- extension/tool delivery;
- cancellation;
- logging and diagnostic capture.

The ideal result is a pure reducer/effect kernel:

```rust
pub struct HarnessKernel {
    state: HarnessState,
}

impl HarnessKernel {
    pub fn decide(&self, input: KernelInput) -> Result<Vec<Decision>, KernelError>;
    pub fn apply(&mut self, event: &CanonicalEvent) -> Result<Vec<Effect>, KernelError>;
}
```

`decide` validates intent and proposes canonical events. The runtime appends them. `apply` mutates only deterministic projections and returns effects to execute outside the kernel.

### 9.4 Replace in the browser

Do not port these components directly:

- `tau-cli`, terminal/raw-terminal crates;
- `tau-socket` and Unix transport;
- `tau-supervisor` and process lifecycle;
- extension process launch/isolation;
- `tau-ext-shell` process/PTTY execution;
- native `reqwest`/Tokio provider transports;
- native directory/file-lock assumptions;
- integrations that depend on long-lived sockets or background daemons.

### 9.5 Compatibility strategy

The project SHOULD preserve a `tau-compat` boundary rather than tightly coupling every browser crate to Tau internals.

`tau-compat` may provide:

- translation between browser events and Tau CBOR events;
- import/export of transcripts and traces;
- mapping of Tau `ToolSpec`, model metadata, and message types;
- a future bridge that attaches the PWA UI to a native Tau harness;
- schema fixtures that detect divergence.

This allows the browser kernel to move independently while retaining interoperability.

### 9.6 Recommendation

Use Tau as the **harness semantics and protocol seed**, not as the browser runtime dependency graph. Begin with a constrained single-agent kernel and preserve event compatibility only where it does not compromise browser simplicity.

---

## 10. Async shell specification

### 10.1 Base architecture

The shell SHOULD begin as a fork or substantial refactor of `rust-bash`:

- retain `brush-parser` for tokenization and Bash AST generation;
- retain the interpreter/VFS-native model;
- replace synchronous command dispatch with asynchronous dispatch;
- separate shell builtins from external commands;
- make byte streams first-class;
- remove command implementations duplicated by uutils when the WASI version is mature enough;
- keep native Rust implementations for shell-specific commands and commands that need harness integration.

### 10.2 Public API

```rust
pub struct Shell {
    state: ShellState,
    commands: CommandRegistry,
}

impl Shell {
    pub async fn exec(
        &mut self,
        script: &str,
        options: ExecOptions,
    ) -> Result<ExecResult, ShellError>;
}

pub struct ExecOptions {
    pub cwd: Option<VirtualPath>,
    pub env_overlay: EnvOverlay,
    pub stdin: ByteInput,
    pub limits: ExecutionLimits,
    pub cancellation: CancellationToken,
    pub persistence: StatePersistence,
}

pub struct ExecResult {
    pub exit_code: i32,
    pub stdout: Vec<u8>,
    pub stderr: Vec<u8>,
    pub state_delta: ShellStateDelta,
    pub vfs_patch: VfsPatch,
    pub metrics: ExecutionMetrics,
}
```

Text decoding is a UI concern. Shell and pipeline internals must preserve arbitrary bytes.

### 10.3 Async command trait

Browser futures are local and need not be `Send`:

```rust
use futures::future::LocalBoxFuture;

pub trait AsyncCommand {
    fn metadata(&self) -> &CommandMetadata;

    fn execute<'a>(
        &'a self,
        invocation: CommandInvocation<'a>,
    ) -> LocalBoxFuture<'a, Result<CommandExit, CommandError>>;
}

pub struct CommandInvocation<'a> {
    pub argv: &'a [OsBytes],
    pub cwd: &'a VirtualPath,
    pub env: &'a EnvironmentSnapshot,
    pub io: CommandIo,
    pub fs: &'a dyn VirtualFs,
    pub limits: &'a ExecutionBudget,
    pub cancellation: CancellationToken,
    pub capabilities: &'a CommandCapabilities,
}
```

A native feature may provide a `Send` variant, but browser APIs must not be forced into `Send + Sync` abstractions.

### 10.4 Borrowing rule

The interpreter MUST NOT hold a mutable borrow of global `ShellState` across an `.await`.

Before dispatching an asynchronous command, it must construct an immutable command snapshot. After completion, it applies a validated `CommandExit`/`StateDelta`. Builtins that mutate cwd, aliases, options, variables, functions, and positional parameters run in the interpreter or return explicit state deltas.

### 10.5 Async propagation

The following paths must become asynchronous:

- public `exec`;
- program/compound-list execution;
- pipeline execution;
- simple-command dispatch;
- command substitution;
- process substitution emulation, if retained;
- `xargs` and `find -exec` callbacks;
- sourced scripts when a nested command may await;
- traps that execute commands;
- host command adapters.

Recursive async functions should use boxed local futures or an explicit interpreter machine rather than deeply nested generated future types.

### 10.6 Command resolution

Resolution order:

1. reserved words/parser constructs;
2. aliases during parse/expansion according to supported Bash semantics;
3. functions;
4. special and regular shell builtins;
5. registered native async commands;
6. registered WASI commands found through virtual `PATH`;
7. registered host-capability commands;
8. exit 127.

Absolute paths such as `/bin/sort` resolve through virtual command metadata, not an executable file loader. The VFS may contain command stub metadata for discovery, but scripts cannot install arbitrary executable bytes and run them.

### 10.7 Persistent shell state

Each agent owns a shell session with:

- cwd;
- non-secret environment;
- shell variables and arrays;
- options and `shopt` state;
- functions stored as source plus parsed cache;
- aliases;
- directory stack;
- VFS view.

The VFS may be shared by all agents in one workspace. cwd/env/functions are isolated per agent by default.

### 10.8 Execution limits

Retain and extend rust-bash-style limits:

- script bytes;
- command count;
- loop iterations;
- function/source depth;
- substitution depth;
- brace/glob expansion count;
- array elements;
- single string bytes;
- here-document bytes;
- stdout/stderr bytes;
- VFS writes and total workspace bytes;
- wall-clock deadline;
- nested host tool calls;
- WASI command invocations;
- pipeline stages.

All async waits must observe cancellation and deadline state.

### 10.9 MVP pipeline semantics

MVP pipelines are finite and bounded:

```text
stage 1 completes → bounded stdout buffer → stage 2 completes → ...
```

This supports the dominant agent workflows and allows async host commands to mix with uutils. It does not faithfully support infinite producer/finite consumer pipelines such as `yes | head`, `tail -f`, background jobs, or Unix signal behavior.

The shell MUST:

- cap each intermediate buffer;
- reject known indefinite modes such as `tail -f` unless an interactive streaming backend is enabled;
- terminate a WASI command worker on timeout;
- return a clear compatibility error rather than silently hanging;
- document the deviation.

### 10.10 Later streaming pipeline mode

A later mode MAY use one worker per WASI stage and SharedArrayBuffer ring pipes with `Atomics.wait/notify`. That mode requires cross-origin isolation headers and a shared/synchronized VFS design. It must remain optional because it complicates hosting and mobile compatibility.

The async shell interfaces must be designed so a `BufferedPipelineEngine` can later be replaced by a `StreamingPipelineEngine` without changing parser or command APIs.

---

## 11. Command implementation strategy

### 11.1 Three command classes

#### A. Shell builtins and native Rust commands

Run inside the harness worker and can be truly async/cooperative.

Examples:

- `cd`, `export`, `unset`, `set`, `read`, `source`, `eval`, `trap`;
- `echo` and `printf` when invoked as shell builtins;
- `jq` implemented with `jaq`;
- `awk` initially retained from rust-bash or replaced by a maintained Rust implementation;
- `xargs` and `find -exec` as shell-aware dispatchers;
- `tar`/gzip helpers where binary behavior is better controlled natively;
- `curl` as a policy-controlled async browser command;
- `agentctl` as a host-tool bridge.

#### B. WASI uutils commands

Run as actual `wasm32-wasip1` guest programs:

- coreutils multicall commands such as `cat`, `ls`, `cp`, `mv`, `rm`, `sort`, `uniq`, `head`, `tail`, `wc`, checksums, base encoders, and text utilities;
- uutils grep;
- uutils sed;
- uutils findutils where supported;
- uutils diffutils.

#### C. Host capability commands

Map shell invocations to harness tools:

- `agentctl call ...`;
- optional convenience wrappers such as `hcloud`;
- HTTP APIs;
- cloud provisioning;
- later SSH/remote command gateways.

Host commands are asynchronous and policy checked. They never receive raw credential values.

### 11.2 Why nested WASI first

Although individual uutils crates expose Rust entry points, many utilities use `std::env`, `std::io`, and `std::fs`. Directly linking them into a `wasm32-unknown-unknown` shell with a custom VFS would require broad I/O abstraction work across uutils.

The first implementation should therefore execute the upstream-supported `wasm32-wasip1` binaries. Direct linking may be reconsidered only after a focused upstream-compatible I/O adapter exists.

### 11.3 Module registry

```rust
pub struct WasiProgram {
    pub command_names: Vec<String>,
    pub asset_url: String,
    pub content_hash: [u8; 32],
    pub invocation: InvocationStyle,
    pub wasi_capabilities: WasiCapabilitySet,
}

pub enum InvocationStyle {
    Multicall { launcher: String },
    Standalone,
}
```

Example:

```toml
[[program]]
asset = "/commands/coreutils-b5d7bf4.wasm"
sha256 = "..."
commands = ["cat", "ls", "sort", "uniq", "wc", "cp", "mv", "rm"]
invocation = { multicall = "coreutils" }

[[program]]
asset = "/commands/grep-68caea0.wasm"
sha256 = "..."
commands = ["grep", "egrep", "fgrep"]
invocation = "standalone"
```

The model cannot modify this registry. Command modules are pinned at build time and integrity checked.

---

## 12. Rust WASI Preview 1 host

### 12.1 Scope

Implement only the WASI Preview 1 surface required by pinned command modules, but fail predictably for unsupported calls.

Initial imports include:

- args and environment sizes/read;
- clocks and random;
- fd read/write/seek/tell/close/stat;
- preopened directory discovery;
- path open/create/unlink/remove/rename/link/symlink/readlink/stat;
- directory enumeration;
- file times where practical;
- polling sufficient for finite commands;
- `proc_exit` capture.

### 12.2 Nested module execution

The command worker is a `wasm32-unknown-unknown` Rust module. It uses `js_sys::WebAssembly` to compile/cache/instantiate uutils modules and constructs the import object using `wasm-bindgen` closures backed by Rust `WasiContext` state.

A feasibility spike MUST validate:

- reentrant host callbacks from a guest module into the outer Rust WASM host;
- correct access to guest linear memory;
- `proc_exit` handling without corrupting the worker;
- repeated instantiation and cleanup;
- Safari/Chrome/Firefox mobile behavior;
- binary stdout/stderr;
- command module caching.

If a browser or binding limitation makes a fully Rust-authored import object impractical, a narrowly scoped generated or hand-written WASI import shim is permitted. No shell, harness, policy, provider, or state logic may move into JavaScript.

### 12.3 Command worker isolation

A synchronous guest can monopolize its worker. Therefore:

- the main-thread worker supervisor owns command worker lifecycle;
- the harness assigns a job ID and deadline;
- the worker receives a bounded VFS replica, stdin, argv, env, and module identity;
- on success it returns exit code, output, metrics, and a VFS patch;
- on deadline/cancel, the supervisor terminates and replaces the worker;
- the harness marks the command cancelled/failed and discards uncommitted patches.

Default pool size is one on mobile and configurable on desktop.

### 12.4 VFS replica protocol

Workers maintain a versioned replica:

```rust
pub struct VfsReplicaState {
    pub workspace_id: WorkspaceId,
    pub base_version: u64,
    pub manifest: VfsManifest,
    pub chunks: Vec<ContentChunk>,
}

pub struct VfsPatch {
    pub expected_base_version: u64,
    pub operations: Vec<VfsOperation>,
    pub new_chunks: Vec<ContentChunk>,
}
```

The harness validates:

- base version;
- path normalization;
- file/operation count;
- per-file and total byte limits;
- permissions and allowed prefixes;
- no writes outside the command workspace;
- no special metadata unsupported by the canonical VFS.

Only then does it commit the patch.

### 12.5 Cache policy

Compiled `WebAssembly.Module` objects should be cached per command worker. Asset responses are cached by the service worker. Content hashes and build commit IDs must be exposed in diagnostics.

---

## 13. Virtual filesystem

### 13.1 Model

The canonical VFS is an inode-like, path-normalized, byte-preserving filesystem implemented in Rust.

Minimum node types:

- regular file;
- directory;
- symbolic link;
- command stub/metadata entry, if useful for `PATH` discovery.

Metadata:

- stable file ID;
- mode bits sufficient for Unix tools;
- logical timestamps;
- content length/hash;
- link target;
- generation/version.

### 13.2 Default layout

```text
/
  bin/
  usr/bin/
  home/agent/
  workspace/
  tmp/
  run/
  dev/null
  dev/stdin
  dev/stdout
  dev/stderr
```

The default shell starts in `/workspace`. `/tmp` is ephemeral. `/workspace` and session metadata are durable.

### 13.3 Persistence

Use a content-addressed design:

- small metadata manifests and journals in OPFS;
- file contents chunked and addressed by BLAKE3;
- copy-on-write updates;
- periodic compact snapshots;
- garbage collection only after a committed snapshot proves chunks unreachable.

### 13.4 OPFS layout

```text
/tau-web/
  schema-version
  lock-owner
  sessions/<session-id>/events.log
  sessions/<session-id>/snapshot-<seq>.cbor
  workspaces/<workspace-id>/manifest.cbor
  chunks/<prefix>/<blake3>
  secrets/store.cbor.enc
  command-cache/metadata.cbor
```

Event records should be length-prefixed and include schema version, sequence, event ID, payload checksum, and previous-record hash. Recovery truncates only an incomplete/corrupt tail after validating the chain.

### 13.5 Browser persistence behavior

The main thread should request persistent storage after an explicit user gesture. Failure to obtain persistence is not fatal, but the UI must display that browser storage remains evictable and offer export.

A Web Lock named by workspace/session prevents multiple tabs from becoming canonical writers. A second tab may attach read-only through `BroadcastChannel`/`MessagePort` or ask the user to take over.

### 13.6 Import/export

Users must be able to export:

- a complete workspace archive;
- canonical session events;
- transcript and tool trace;
- shell state;
- configuration excluding secrets by default.

An encrypted export MAY include secrets after explicit confirmation.

---

## 14. Harness kernel and event model

### 14.1 State machine

Initial agent states:

```rust
pub enum AgentRunState {
    Idle,
    PreparingPrompt,
    ProviderRunning { attempt: AttemptId },
    AwaitingApproval { call: ToolCallId },
    ToolRunning { call: ToolCallId },
    Suspended,
    NeedsReconciliation { call: ToolCallId },
    Failed { reason: FailureClass },
}
```

### 14.2 Core canonical events

At minimum:

- `SessionCreated`;
- `WorkspaceAttached`;
- `AgentCreated`;
- `AgentRoleChanged`;
- `UserPromptCommitted`;
- `ProviderAttemptAdmitted`;
- `ProviderAttemptCompleted`/`Failed`/`Cancelled`;
- `AssistantMessageCommitted`;
- `ToolCallDeclared`;
- `ToolPolicyEvaluated`;
- `ToolApprovalGranted`/`Denied`;
- `ToolExecutionStarted`;
- `ToolExecutionCompleted`/`Failed`/`Cancelled`;
- `ToolExecutionUncertain`;
- `VfsPatchCommitted`;
- `ShellStateCommitted`;
- `CompactionCommitted`;
- `AgentSuspended`/`Resumed`;
- `SnapshotCommitted`.

Token deltas and high-frequency progress may be ephemeral observations. Final assistant text and terminal tool results are durable.

### 14.3 Effect model

```rust
pub enum Effect {
    RunProvider(ProviderEffect),
    RunTool(ToolEffect),
    RequestApproval(ApprovalEffect),
    PersistSnapshot(SnapshotEffect),
    ReconcileTool(ReconcileEffect),
    NotifyUi(UiNotification),
}
```

Effects are owned by the runtime, never executed by the pure kernel.

### 14.4 Turn loop

1. Commit user prompt.
2. Assemble prompt from canonical transcript, role, tool specs, context fragments, and budget.
3. Commit provider attempt admission.
4. Stream provider observations to UI.
5. Commit final assistant content and any declared tool calls.
6. Validate tool arguments and policy.
7. Request approval when needed.
8. Commit execution start and run the tool.
9. Commit terminal result.
10. Add tool result to the next provider turn.
11. Stop on final assistant response or a configured loop limit.

### 14.5 Crash recovery

On worker startup:

1. acquire workspace Web Lock;
2. open and validate the latest snapshot;
3. replay subsequent canonical events;
4. classify incomplete provider/tool calls;
5. cancel provider calls that cannot still exist;
6. reconcile or surface uncertain side effects;
7. resume only after user policy permits.

No model turn is silently resumed from an uncertain destructive operation.

---

## 15. Provider subsystem

### 15.1 Trait

```rust
pub trait Provider {
    fn metadata(&self) -> ProviderMetadata;

    fn run<'a>(
        &'a self,
        request: ProviderRequest,
        cancellation: CancellationToken,
    ) -> futures::stream::LocalBoxStream<
        'a,
        Result<ProviderEvent, ProviderError>,
    >;
}

pub enum ProviderEvent {
    ResponseStarted { upstream_id: Option<String> },
    TextDelta(String),
    ReasoningDelta(String),
    ToolCallDelta(ToolCallFragment),
    Usage(UsageRecord),
    RateLimit(QuotaSnapshot),
    Completed(ProviderCompletion),
}
```

### 15.2 OpenRouter/OpenAI-compatible adapter

Implement the adapter in Rust using `web-sys` Fetch, `ReadableStream`, `AbortController`, and a Rust SSE parser. Do not use a JavaScript SDK.

Features:

- OpenAI-compatible Chat Completions first;
- streaming and non-streaming;
- tool definitions/tool-call fragments;
- reasoning fields where provider/model supports them;
- usage and cost metadata;
- cancellation;
- provider/model selection;
- retry policy with bounded backoff;
- structured failure classification;
- optional Responses API later.

### 15.3 Authentication

OpenRouter integration SHOULD support OAuth PKCE and a manually pasted key.

Defaults:

- key remains in harness-worker memory for the session;
- “remember this key” is opt-in;
- persistent secrets are encrypted using WebCrypto with a user-unlock mechanism;
- the UI recommends a dedicated, spend-limited provider key;
- query parameters containing OAuth codes/verifiers are removed from browser history after exchange.

### 15.4 Provider CORS

A provider is browser-direct only if it explicitly permits the application origin and required headers. Otherwise the user must configure an optional same-origin relay. The relay API must preserve the same Rust provider trait so the kernel does not care which transport is used.

---

## 16. Tool and capability system

### 16.1 Tool trait

```rust
pub trait ToolHandler {
    fn spec(&self) -> &ToolSpec;
    fn capabilities(&self) -> CapabilityManifest;

    fn call<'a>(
        &'a self,
        context: ToolContext<'a>,
        arguments: CborValue,
    ) -> futures::stream::LocalBoxStream<
        'a,
        Result<ToolEvent, ToolError>,
    >;
}

pub enum ToolEvent {
    Progress(ToolProgress),
    OutputChunk(OutputChunk),
    Completed(ToolResult),
}
```

### 16.2 Capability manifest

```rust
pub enum Capability {
    VfsRead { prefixes: Vec<VirtualPath> },
    VfsWrite { prefixes: Vec<VirtualPath> },
    Network { origins: Vec<OriginPattern>, methods: MethodSet },
    CloudOperation { provider: String, operations: Vec<String> },
    SecretUse { secret_ids: Vec<SecretId> },
    Relay { services: Vec<String> },
    ClipboardRead,
    ClipboardWrite,
}
```

Capabilities are granted to trusted tool implementations, not to the model. Tool schemas describe arguments but never secret values.

### 16.3 Approval policy

Policy can be configured by tool, semantic tag, operation, resource, amount, and environment.

Examples:

- read-only VFS commands: allow;
- write inside `/workspace`: allow or summarize;
- delete workspace files: confirm;
- HTTP GET to allowlisted public APIs: allow;
- create cloud server: confirm with provider, type, location, and expected cost;
- delete server or revoke key: always confirm;
- shell invoking a host tool: same policy as a direct model tool call.

### 16.4 Idempotency and reconciliation

Tool metadata must declare:

```rust
pub enum ReplaySafety {
    Pure,
    Idempotent { key_strategy: KeyStrategy },
    ReconcileBeforeRetry,
    NeverAutomaticRetry,
}
```

Cloud adapters should use upstream idempotency mechanisms where available and implement a status/reconciliation query.

### 16.5 `agentctl`

`agentctl` is a native async shell command that invokes registered harness tools.

Examples:

```bash
agentctl tools list
agentctl tools schema hetzner.server.create
agentctl call hetzner.server.list --json '{}'
agentctl call http.fetch --json @/tmp/request.json
```

Rules:

- calls receive child call IDs linked to the parent `shell.exec` tool call;
- normal policy and approval still apply;
- JSON/CBOR result is written to stdout;
- diagnostics go to stderr;
- secret references are resolved by the tool adapter only;
- recursive calls to `shell.exec` are rejected by default to prevent cycles.

---

## 17. Model-visible shell tool

Initial model tool:

```json
{
  "name": "shell.exec",
  "description": "Execute a bounded Bash-compatible script in the local virtual workspace.",
  "input_schema": {
    "type": "object",
    "properties": {
      "script": { "type": "string" },
      "cwd": { "type": "string" },
      "timeout_ms": { "type": "integer" },
      "max_output_bytes": { "type": "integer" }
    },
    "required": ["script"]
  }
}
```

Result:

```json
{
  "exit_code": 0,
  "stdout": "...",
  "stderr": "...",
  "truncated": false,
  "cwd": "/workspace",
  "changed_paths": ["/workspace/plan.json"]
}
```

Binary output should be represented as a file reference or base64 only when explicitly requested. Large output should be stored in the VFS and returned as a bounded summary plus path.

---

## 18. PWA and UI specification

### 18.1 Rust UI

Recommended UI stack:

- Leptos CSR;
- `web-sys`/`js-sys` bindings;
- accessible semantic DOM;
- plain CSS or compile-time Rust-friendly styling;
- no JavaScript framework.

MVP should not embed a full terminal emulator. Use a mobile-friendly command console:

- multiline command editor;
- separate stdout/stderr blocks;
- ANSI parsing/rendering in Rust;
- command history;
- completion popover;
- interrupt/cancel button;
- file/result links.

A later xterm adapter may be optional, but it must not become a dependency of the harness.

### 18.2 Main screens

- session/agent list;
- chat transcript;
- provider/model picker;
- pending approval queue;
- tool execution timeline;
- shell console;
- VFS browser/editor;
- credentials and capabilities;
- storage/offline diagnostics;
- export/import.

### 18.3 Mobile behavior

- single-column layout by default;
- bottom composer respecting safe-area insets;
- tool cards collapse large output;
- full-screen file/shell views;
- explicit online/offline and “runtime suspended/resumed” indicators;
- touch-friendly cancellation and approvals;
- no dependence on hover.

### 18.4 UI/worker protocol

Use versioned CBOR payloads transferred as `ArrayBuffer`:

```rust
pub enum UiRequest {
    OpenSession(SessionId),
    CreateAgent(CreateAgentRequest),
    SubmitPrompt(SubmitPromptRequest),
    ApproveTool(ApprovalResponse),
    CancelOperation(OperationId),
    ShellExec(InteractiveShellRequest),
    ReadFile(VirtualPath),
    WriteFile(WriteFileRequest),
    UpdateSettings(SettingsPatch),
    Export(ExportRequest),
}

pub enum UiEvent {
    Ready(RuntimeSummary),
    Snapshot(AppProjection),
    Canonical(CanonicalEventEnvelope),
    ProviderDelta(ProviderDelta),
    ToolProgress(ToolProgress),
    ApprovalRequired(ApprovalRequest),
    ShellOutput(ShellOutputChunk),
    StorageWarning(StorageWarning),
    Fatal(RuntimeFatal),
}
```

UI state is a projection. The UI must be able to discard all local state and rebuild from a worker snapshot plus events.

### 18.5 Service worker

Responsibilities:

- precache versioned app shell;
- cache content-hashed WASM command modules on first use;
- serve a consistent version during an update;
- expose update-ready status;
- never own session or agent state;
- never be relied on for long-lived execution.

The browser may terminate the service worker whenever idle. The harness must live in a dedicated worker while the app is active.

---

## 19. Browser lifecycle and recovery

Mobile browsers may suspend or kill workers at any time.

The runtime must:

- flush critical canonical records immediately;
- checkpoint provider/tool state at safe boundaries;
- listen for visibility/page lifecycle signals and request a flush;
- assume an in-flight fetch may disappear without a terminal callback;
- mark externally uncertain calls for reconciliation;
- restore the shell/VFS/session from local storage on next launch;
- clearly state that execution does not continue while the PWA is closed.

Background Sync may be used only as an optional convenience for non-sensitive best-effort work. It is not a correctness mechanism.

---

## 20. Security model

### 20.1 Threats

- malicious or mistaken model-generated shell code;
- prompt injection through files, websites, or tool output;
- accidental destructive cloud actions;
- credential exfiltration;
- XSS or compromised third-party script;
- runaway loops, output, memory, or spending;
- malicious/corrupt WASI guest;
- replay after crash;
- cross-tab races;
- corrupted local storage.

### 20.2 Browser-origin hardening

Deployment MUST use:

- HTTPS;
- strict Content Security Policy with no `unsafe-eval` and preferably no `unsafe-inline`;
- no third-party runtime scripts;
- same-origin, content-hashed WASM assets;
- integrity verification of command modules;
- restrictive `connect-src` based on configured providers/relay;
- `frame-ancestors 'none'` unless embedding is an explicit feature;
- Referrer-Policy and Permissions-Policy;
- Trusted Types where supported;
- dependency and supply-chain locking.

COOP/COEP should be enabled only when the optional SharedArrayBuffer streaming backend is deployed and its hosting trade-offs are accepted.

### 20.3 Shell sandbox

- no host filesystem;
- no DOM;
- no arbitrary module loading;
- network disabled unless a registered command/tool grants it;
- output and resource limits;
- normalized paths;
- bounded VFS;
- WASI guest patch validation;
- disposable worker termination for uncooperative guests.

### 20.4 Secret handling

- secret values live only in the secret adapter and trusted call stack;
- use non-secret opaque `SecretId` references elsewhere;
- redact headers and structured fields before diagnostics;
- never persist plaintext by default;
- lock secret storage when the PWA is inactive for a configured period;
- provide one-click credential revoke/delete instructions;
- advise provider/cloud keys with minimum scope and spending limits.

### 20.5 Prompt injection

Tool output and external content must be typed as untrusted. The prompt assembler must distinguish:

- user instruction;
- system/role instruction;
- tool result;
- external untrusted content;
- local trusted policy facts.

Content cannot declare capabilities or override tool policy. Approval cards derive from structured tool arguments and adapter metadata, never from model-written explanatory text alone.

---

## 21. Optional Rust relay

The core PWA is client-side. A small optional Rust relay may provide:

- same-origin proxying for APIs without suitable CORS;
- WebSocket/WebTransport-to-TCP bridging;
- SSH transport;
- organization-managed secret custody;
- audit logging;
- larger downloads/uploads.

Recommended implementation: Axum or another small Rust HTTP stack.

The relay MUST:

- authenticate the PWA/user;
- enforce destination and operation policy;
- prevent generic open-proxy behavior;
- use short-lived scoped session tokens;
- support cancellation;
- preserve tool idempotency keys;
- avoid receiving full agent transcripts unless required.

The harness remains in the browser. The relay is a capability gateway, not a remote agent daemon.

---

## 22. Example end-to-end flow: launch a VPS

1. User asks the agent to launch an inexpensive server in a location.
2. Harness commits the user prompt and starts the provider.
3. Model calls `shell.exec` to inspect existing preferences/files or calls `hetzner.server.types` directly.
4. Shell may execute:

```bash
agentctl call hetzner.server.types --json '{}' \
  | jq '[.server_types[] | select(.architecture == "x86") | {name, cores, memory}]'
```

5. Hetzner adapter uses the stored credential by secret reference. The credential is absent from shell env and prompt.
6. Model proposes `hetzner.server.create` with structured parameters.
7. Harness commits the call and policy result.
8. UI displays provider, server type, image, location, estimated recurring cost, SSH key, and destructive implications.
9. User approves.
10. Harness commits approval and execution start with an idempotency identity.
11. Adapter calls the API and streams progress.
12. Terminal result is committed and returned to the model.
13. Model writes a deployment note into `/workspace/servers/<id>.json` and summarizes.
14. If the app crashes after the API request but before terminal commit, recovery performs a status lookup rather than blindly creating another server.

---

## 23. Testing strategy

### 23.1 Pure Rust tests

- kernel transition golden tests;
- event replay/property tests;
- tool-policy table tests;
- schema validation/fuzzing;
- VFS path and patch property tests;
- shell expansion/control-flow tests;
- provider SSE parser tests;
- crash/recovery fault injection;
- migration tests.

### 23.2 Shell conformance

- retain relevant rust-bash integration and Oils tests;
- differential tests against GNU Bash for supported semantics;
- explicit expected-failure manifest for unsupported process semantics;
- binary/NUL pipeline tests;
- async command substitution and nested host-call tests;
- cancellation tests at every interpreter recursion point.

### 23.3 WASI/uutils tests

For every pinned module and browser release:

- command smoke matrix;
- stdout/stderr/exit-code comparison against native uutils for fixtures;
- VFS mutation comparison;
- unsupported syscall behavior;
- non-UTF-8 bytes;
- timeout/termination;
- worker replacement;
- corrupted module/integrity failure.

### 23.4 Browser tests

Run on current Chromium, Firefox, and WebKit engines, including mobile emulation and real-device smoke tests:

- worker startup and nested WASM;
- OPFS journal recovery;
- storage eviction warning;
- PWA installation/update;
- offline shell;
- provider streaming/cancellation;
- OAuth callback cleanup;
- tab lock/takeover;
- suspension/reload recovery.

Use `wasm-bindgen-test` for Rust browser tests. A minimal WebDriver/Playwright-like external runner may be used for end-to-end browser automation, but application logic remains Rust.

### 23.5 Security tests

- model attempts to read secrets from env/VFS;
- host command origin bypass attempts;
- path traversal and symlink escape;
- malformed tool arguments;
- duplicate terminal outcomes;
- crash between intent and side effect;
- prompt-injected approval text;
- oversized outputs/files/scripts;
- malicious WASI guest loop;
- CSP validation.

---

## 24. Build and release

### 24.1 Rust `xtask`

`cargo xtask web-dist` should:

1. build UI, harness worker, and command worker;
2. run `wasm-bindgen` for each entry;
3. build pinned uutils modules for `wasm32-wasip1`;
4. run `wasm-opt` with size-oriented settings;
5. compute content hashes and generate `commands.lock.toml`/asset manifest;
6. generate service-worker precache data;
7. copy static files into `dist/`;
8. verify CSP-compatible output contains no dynamic eval;
9. produce a reproducible build manifest/SBOM.

No npm install should be required for a release build.

### 24.2 Versioning

Version independently:

- application protocol;
- canonical event schema;
- storage schema;
- shell compatibility profile;
- command module set;
- Tau compatibility schema.

A service-worker update must never open a newer storage schema until the new harness worker is ready to migrate it transactionally.

---

## 25. Implementation milestones

### M0 — Feasibility gates

Deliver isolated technical spikes:

- async rust-bash command that awaits browser `fetch` and participates in a pipeline;
- Rust-authored WASI host running `coreutils sort` as nested WASM;
- disposable command worker timeout/termination;
- VFS snapshot/patch round trip;
- OPFS append log and crash-tail recovery;
- extraction of a minimal Tau-compatible event/tool registry into `wasm32`-clean crates;
- OpenRouter streaming from Rust in a worker.

**Gate:** do not build the full UI before these spikes pass on Chromium, Firefox, and WebKit.

### M1 — Local shell PWA

- installable Rust UI;
- dedicated harness worker;
- in-memory/durable VFS;
- async shell with persistent cwd/env/functions;
- uutils core module;
- grep/sed/find/diff modules;
- shell console and file browser;
- offline operation;
- export/import.

### M2 — Single-agent Tau-derived harness

- canonical events and replay;
- one agent/session;
- provider streaming;
- `shell.exec` tool;
- tool schema validation;
- cancellation and turn limits;
- durable transcript and recovery.

### M3 — Capability tools and approvals

- generic async Rust tool API;
- `agentctl`;
- HTTP tool with origin policy;
- secret store;
- approval UI;
- idempotency/reconciliation framework;
- one cloud-provider PoC.

### M4 — Hardening

- strict CSP/deployment headers;
- fault-injection recovery suite;
- command-worker isolation by default;
- storage diagnostics and persistence request;
- cost/spend budgets;
- model/tool loop safeguards;
- browser compatibility matrix.

### M5 — Tau interoperability and multi-agent subset

- Tau trace/event import/export;
- roles and prompt fragments;
- transcript branching/compaction;
- optional sub-agent delegation;
- native Tau bridge experiment.

### M6 — Advanced execution

- optional streaming pipelines with SharedArrayBuffer;
- richer command packages;
- optional relay and SSH;
- user-installable signed command packs, only after a separate security design.

---

## 26. MVP acceptance criteria

The MVP is accepted when all of the following hold:

1. The PWA installs and boots offline after first load.
2. Reloading reconstructs the same session, shell cwd/env, transcript, and VFS.
3. This script works locally:

```bash
printf '%s\n' orange apple orange banana \
  | sort \
  | uniq -c \
  | sort -rn > /workspace/counts.txt
cat /workspace/counts.txt
```

4. Bash variables, loops, functions, command substitution, redirection, and globbing pass the defined compatibility suite.
5. At least the documented uutils command set runs as actual WASI guest binaries.
6. An async Rust host command can feed a pipeline and be cancelled.
7. OpenRouter streams a response, invokes `shell.exec`, receives the result, and completes a turn.
8. A secret used by a tool cannot be found in model requests, shell env, VFS, logs, or exported traces.
9. A destructive mock tool requires approval and does not execute after denial.
10. Crash injection after side-effect intent but before terminal commit produces `NeedsReconciliation`, not duplicate execution.
11. A looping WASI guest is terminated without losing committed harness/VFS state.
12. A second tab cannot become a concurrent canonical writer.
13. Browser storage uncertainty is visible and session export works.
14. The release contains no TypeScript application code or JavaScript AI harness.

---

## 27. Principal risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Rust-authored WASI imports are awkward or browser-specific | High | M0 nested-WASM gate; permit a tiny isolated JS import shim as fallback |
| uutils guest blocks forever | High | disposable worker, deadline, terminate/recreate, discard patch |
| Buffered pipelines differ from Unix | Medium | explicit profile, bounded errors, native commands for common streaming cases, later streaming backend |
| VFS replica transfer is expensive | Medium | versioned worker replicas, content-addressed chunks, deltas, pool size 1 on mobile |
| Tau internals change rapidly | Medium | `tau-compat` boundary, copied/extracted stable concepts, pinned fixtures |
| Tau native assumptions leak into kernel | High | pure kernel crates with compile-time browser checks and forbidden-dependency CI |
| Browser kills worker during side effect | High | durable intent, idempotency, reconciliation, immediate terminal flush |
| API lacks CORS | Medium | optional same-origin Rust relay |
| Browser credential theft through XSS | High | no third-party scripts, strict CSP, encrypted opt-in persistence, scoped/spend-limited keys |
| OPFS data eviction | Medium | request persistence, warning, export, snapshots |
| WASM bundle size/startup | Medium | split UI/worker/commands, lazy command modules, wasm-opt, hashed cache |
| Mobile memory pressure | High | bounded outputs/VFS/context, one command worker, compaction, lazy modules |
| Shell compatibility creates endless scope | Medium | explicit compatibility profile and xfail manifest |
| Mixed licenses | Medium | clear file boundaries and SPDX headers; legal review before distribution |

---

## 28. Licensing

Current relevant licenses:

- Tau: MPL-2.0;
- rust-bash: MIT;
- uutils coreutils: MIT;
- several other uutils families: MIT or MIT/Apache-2.0.

Recommended approach:

- either license the whole new project MPL-2.0 for simplicity; or
- preserve Tau-derived files under MPL-2.0 and place clean-room/new crates under MIT OR Apache-2.0, with explicit SPDX identifiers and a third-party notice.

MPL is file-level copyleft. Modifications to Tau-derived MPL files remain subject to MPL obligations, while separately authored files can be combined under compatible licenses. This section is an engineering recommendation, not legal advice.

---

## 29. Open decisions

These decisions should be resolved by M0/M1:

1. **Fully Rust WASI import object:** validate whether all required guest-memory callbacks can remain ergonomic and stable through `wasm-bindgen`.
2. **Command worker topology:** nested workers versus main-thread-supervised workers on target mobile browsers.
3. **VFS replica granularity:** whole manifest, directory-scoped snapshot, or versioned chunk delta.
4. **Shell baseline:** fork rust-bash directly versus extract parser/interpreter concepts into new crates with compatibility tests.
5. **Tau compatibility level:** exact event wire compatibility or semantic translation only.
6. **Secret unlock UX:** session-only default, passphrase, platform credential API where available, or optional relay custody.
7. **UI framework:** Leptos CSR is recommended, but a direct `web-sys` UI remains viable.
8. **Provider API:** Chat Completions first versus a normalized Responses API first.
9. **COOP/COEP deployment:** required only if advanced SharedArrayBuffer pipelines become a core feature.

---

## 30. Final recommendation

Proceed with four independent M0 prototypes before merging architecture:

1. **`async-shell-spike`** — make rust-bash command dispatch and command substitution async and demonstrate `fetch-json | jq`.
2. **`rust-wasi-web-spike`** — execute pinned uutils coreutils from a Rust browser worker with a Rust VFS.
3. **`tau-kernel-spike`** — extract a single-agent event/tool/provider state machine from Tau concepts with no filesystem, Unix, Tokio, or process dependencies.
4. **`opfs-recovery-spike`** — append canonical events, kill/reload the worker, and recover deterministically.

If these pass, combine them behind the crate boundaries in this specification. The resulting system will not be a Linux machine in a browser. It will be a purpose-built Rust agent computer: Bash-compatible language semantics, real Rust Unix commands, an explicit virtual OS, durable local agent state, and narrowly granted browser/cloud capabilities.

---

## Source basis

This specification was prepared after inspecting the uploaded Tau source archive and the current public repositories/documentation for:

- dpc's Tau coding agent and its architecture/feature documents;
- rust-bash and its WASM, command, VFS, and synchronous callback implementation;
- uutils coreutils and its official browser/WASI playground architecture;
- wasm-bindgen/js-sys Promise/Future and nested WebAssembly APIs;
- browser OPFS, Web Workers, Web Locks, storage persistence, and service-worker lifecycle;
- OpenRouter OAuth PKCE and streaming APIs;
- Mozilla's MPL 2.0 FAQ.
