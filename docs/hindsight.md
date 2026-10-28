# Hindsight Coding Agents

Home Manager installs the official Coding Agents runtime and registers its Codex
hooks, MCP server and companion skill. The implementation is built and activated
on this Apple Silicon Mac. **Live automatic memory across real Codex sessions is
not yet verified:** this Mac has no existing Hindsight backend configuration or
credentials, the new hooks require Codex trust, and no Linux host is available.

## Package and integration

- `packages/hindsight-coding-agents.nix` pins npm
  `@vectorize-io/hindsight-coding-agents` **0.8.1**, the stable release verified
  during implementation. SHA-256:
  `sha256-QHq9ZrpdRgOkYOz+Z5XUeg4Gh0OagA1Lx5MF8u4vXhs=`.
- The inspected official tarball contains the compiled JavaScript, bundled
  dependencies and skill. It needs no npm dependency installation or monorepo
  build. The complete distribution is copied to
  `$out/lib/hindsight-coding-agents`; wrappers use Nix `nodejs_24`, Git and coreutils.
  Node's exact version and dependencies follow the existing `flake.lock`.
- `hindsight.nix`, imported by `codex.nix`, adds the package to `home.packages`
  and uses `programs.codex.hooks`, `.settings.mcp_servers` and `.skills`.
  No overlays, installer, separate flake or marketplace registration is needed.
- The release's plugin manifest targets dcode, not Codex. An attempted minimal
  Codex wrapper was created by Home Manager but was absent from fresh Codex
  0.161.0 hook, MCP and skill discovery. Native registrations were verified instead;
  only the attempted Hindsight plugin entry was removed. Other plugins were retained.

| Codex component | Official runtime file | Timeout |
| --- | --- | --- |
| SessionStart | `dist/codex-sessionstart-hook.js` | 30 s |
| UserPromptSubmit | `dist/codex-hook.js` | 30 s |
| Stop | `dist/codex-stop-hook.js` | 60 s |
| MCP `hindsight` | `dist/mcp-server.js` | startup 60 s, tool 120 s |
| Skill `hindsight-coding-agent` | `skill/SKILL.md` | — |

Hooks call stable package wrappers; MCP calls the Nix Node executable and packaged
JavaScript directly with `HINDSIGHT_MCP_HARNESS=codex`. A declared PATH supplies Node,
Git, coreutils and the user's Nix profile to GUI-launched processes as well.
`CODEX_HOME` and Hindsight connection/config environment variables can pass through
to MCP; no home or repository path is embedded in the runtime. Hook transcript
handling was tested with a custom `CODEX_HOME`.

The official lifecycle is retained: SessionStart initializes project context and
background ingestion, UserPromptSubmit injects relevant memory context, and Stop
retains the Codex transcript with upstream session/document tracking. No custom
memory algorithm or manual MCP recall replaces the hooks.

The current official MCP advertises eight tools:
`hindsight_sync_status`, `hindsight_diagnose`,
`hindsight_search_knowledge_pages`, `hindsight_list_knowledge_pages`,
`hindsight_read_knowledge_page`, `hindsight_reflect`,
`hindsight_capture_initiative`, and `hindsight_ingest_document`.
This release does not advertise generic `hindsight_recall` or `hindsight_retain`
aliases. Knowledge-page search/reflection and document/initiative ingestion are its
supported explicit interfaces; the hooks provide automatic context and retention.

## Configuration, credentials and state

The official loader still reads `~/.hindsight/coding-agent.json`, or the file named
by `HINDSIGHT_CONFIG`. Existing connection settings, authentication, per-harness,
per-directory and per-bank overrides remain outside the Nix store. No file,
credentials, memories, banks, history or backend were replaced or migrated.

The package makes four narrow runtime-policy changes:

1. Effective `autoUpdate` is always `false`, even when an existing private file
   sets it to `true`: upstream file/per-bank settings override environment defaults.
   Wrappers and MCP also set `HINDSIGHT_AUTO_UPDATE=false`. No automatic npm updater
   runs, and the exposed CLI rejects installer/update commands.
2. An absent configuration with no explicit connection environment stays disabled
   instead of falling through to upstream's Cloud default. No example credentials
   or default backend configuration are installed.
3. Daemon mode may reuse an already healthy backend, but cannot bootstrap one with
   uvx/Python downloads. An unavailable local backend must be managed separately
   through Nix or an existing service; this module does not change backend mode.
4. Codex SessionStart does not rewrite the legacy shared companion skill. Home
   Manager owns Codex's skill; another agent's shared skill is left alone.

Upstream environment/file layering, memory retrieval, retention and ingestion logic
otherwise remain unchanged. Background survey and Git ingestion follow the existing
private configuration; activation does not launch them or import history.

On this Mac, inspection found no `~/.hindsight/coding-agent.json`, staged runtime,
Hindsight process/service or credentials. The older Hindsight MCP block was only a
comment in `codex.nix`. The Linux installation at `/home/neo` has not been accessible,
so its version, backend, banks, hooks and credential source remain unverified.
Existing `HINDSIGHT_API_LLM_*` session settings were not changed.

Reuse the existing private configuration and credential mechanism on the machine
that has them. Do not copy tokens into Nix attributes, build arguments, Git or chat.
A private config file works for both terminal and GUI processes without relying on
shell startup files. Protect it with owner-only permissions. A custom
`HINDSIGHT_CONFIG` or environment-only credentials must also be present in the
environment that launches Codex Desktop. No new agenix secret was needed or created.

Default bank IDs remain `coding-agent::{gitProject}`. Upstream resolves linked
worktrees through the Git common directory, so they share the main repository's
bank. Existing `bankId`, templates, `mapPathToBank`, `paths`, `banks` and harness
overrides take precedence as before. No global bank is hardcoded, and no Copilot
integration is installed or changed. Existing shared backend/bank schemes can still
share memories between agents.

Before activating on Linux, inspect its existing `hooks.json`, MCP and skill
registrations and merge unrelated global hooks into the declarative configuration.
Home Manager owns the generated hooks file; do not force-overwrite a conflicting
unmanaged file. Remove or replace only obsolete Hindsight registrations after
backup, keeping one registration per event/server/skill. Plugin-owned Context Mode
and Ponytail hooks coexist with native global hooks on the tested Mac.

## Validation performed

| Check | Result |
| --- | --- |
| Package build and install checks on `aarch64-darwin` | Passed; CLI version 0.8.1, JavaScript syntax checked, imperative update rejected |
| Full `neo@mac` build and normal Home Manager switch | Passed |
| Repeat activation of final integration | Passed |
| `neo@main` full activation graph evaluation | Passed |
| Linux build on this Mac | Blocked: required `x86_64-linux`, current `aarch64-darwin`; no compatible builder |
| Fresh Codex app-server `hooks/list` | All three native Hindsight hooks discovered; **untrusted**, so not yet executed by Codex |
| Fresh Codex app-server `skills/list` | Official skill discovered and enabled at its Nix store path |
| `codex mcp get hindsight --json` | Correct direct Nix Node/runtime registration, harness `codex` |
| Official MCP stdio handshake and tools/list | Passed; all eight tools advertised |
| Official MCP reflection and document ingestion | Passed against the local HTTP fixture; correct bank and Codex attribution |
| Official lifecycle against isolated local HTTP fixture | Passed; context injection after retained transcript, stable document identity on repeated Stop |
| Fixture repository and linked-worktree routing | Passed; separate repositories isolated, worktree reuses main bank |
| Fixture private config and shared legacy skill preservation | Passed |
| Missing config | Hooks stay inactive and make no backend requests |
| CodeGraph MCP regression | Passed handshake, two-project explore, index/schema preservation fixture; CodeGraph source/config unchanged |
| Context Mode and Ponytail | Existing hooks still discovered as trusted; Context Mode tools used during this work |
| Open Code Review, Chrome DevTools, MCPJungle | Plugin enablement/MCP settings preserved; no live review/browser/gateway tool invocation tested |

The package test is reproducible without a Hindsight backend:

```sh
python3 tests/test_hindsight_coding_agents.py \
  "$(dirname "$(dirname "$(readlink -f "$(command -v hindsight-coding-agents)")")")"
```

It uses a loopback HTTP fixture, temporary Git repositories, HOME, CODEX_HOME and
temporary session state. It sends no real conversation to a backend. It tests
official hook code directly, **not a model-driven Codex session or real backend
extraction/persistence**. Successful manual MCP discovery alone is insufficient.

Existing Codex settings, MCP definitions and plugin enablement were compared with
the private pre-activation backup. The declarative model remains `gpt-6-luna` with
high reasoning; no model setting was changed in the source. With mutable settings,
the running Codex app can also persist its current model selection.

## Remaining live acceptance steps

1. Inspect/reuse the actual existing backend configuration and secure credential
   source; confirm its existing banks are readable. Do not choose a new backend
   or create a default global bank to make a test pass.
2. In Codex, run `/hooks` and review/trust the three exact Hindsight hook definitions.
   Codex 0.161.0 requires trust for non-managed command hooks. Declarative enablement
   alone does not grant trust. Changed store paths after an upgrade can require
   review again. No trust bypass or trust-database edit is part of this setup.
3. Restart Codex in an existing repository. Confirm the banner's bank and healthy
   ingestion. Provide a harmless project test fact, finish the turn and session.
4. Start a new session in the same repository and ask a relevant question without
   requesting an MCP tool. Confirm automatic injected memory and backend retention,
   check diagnostics, then verify another repository and a linked worktree.
5. Build and activate `neo@main` twice on a Linux host, after inspecting and merging
   its existing registrations. Confirm existing memories and integrations there.

Until these steps run, automatic recall/retention in a real Codex session and Linux
activation are outstanding. CLI hook execution and native discovery were tested
on the MacBook; a separate Codex Desktop session was not tested.

## Upgrade, rollback and cleanup

Update the version and verified npm tarball hash in
`packages/hindsight-coding-agents.nix`; inspect the new distribution and exact patch
sites before rebuilding. Build and switch through the existing workflow:

```sh
# Use neo@main on Linux; substitute the actual checkout path.
home-manager build --flake "git+file://$HOME/.config/home-manager?submodules=1#neo@mac"
home-manager switch --flake "git+file://$HOME/.config/home-manager?submodules=1#neo@mac"
hindsight-coding-agents --version
```

Restart Codex, review changed hooks with `/hooks`, verify MCP/skill discovery and
repeat the real automatic memory test. Do not use the npm installer/update commands
shown in the unmodified official companion skill; this machine uses Nix upgrades.

Keep the previous Home Manager generation until validation passes. Use
`home-manager generations` to identify it, then execute that generation's
`activate` script to restore its runtime and managed files. With
`mutableSettings=true`, Codex's merge can retain keys that disappeared from the
older declaration: when rolling back to a generation **before** this integration,
remove only `mcp_servers.hindsight` with `codex mcp remove hindsight`, and verify the
hook/skill links. Do not restore an entire config over unrelated new settings.
Private backend data and configuration are outside the store and survive rollback.

No old Hindsight runtime was deleted. On Linux, inventory
`~/.hindsight/coding-agents/` and registrations first. After successful live
validation and confirming no other agent uses the staged runtime, archive only
obsolete runtime binaries and remove only superseded Hindsight registrations.
Never run a general uninstall, delete banks/databases/configuration/credentials,
or remove session history and recovery backups as part of this migration.

Sources: [official distribution](https://www.npmjs.com/package/@vectorize-io/hindsight-coding-agents/v/0.8.1),
[release source at the published gitHead](https://github.com/vectorize-io/hindsight/tree/23c7d701c46e793361a4853fc5e190d0e195db7c/hindsight-integrations/coding-agents),
[Codex hook lifecycle and trust](https://learn.chatgpt.com/docs/hooks).

## Linux backend lifecycle

`linux.nix` owns `hindsight.service`, enabled at user login and restarted on
failure or process exit. It runs the pinned `hindsight-api==1.1.0` through Nix's
uv, rather than the disabled plugin daemon installer. Home Manager switches keep
this service registered. The existing profile at
`~/.hindsight/profiles/coding-agent.env` supplies provider settings; credentials
stay outside the Nix store. The database remains
`pg0://hindsight-embed-coding-agent` under `~/.pg0`.

`HF_HUB_OFFLINE=1` uses the existing cached embedding/reranking models and avoids
this machine's HuggingFace certificate failure. The first installation requires
those model caches and the profile; uv can download the pinned Python backend
when its cache is absent. No legacy runtime under `~/.hindsight/coding-agents`
is needed by the service.

Check `systemctl --user status hindsight` and
`journalctl --user -u hindsight` for backend failures. Restart with
`systemctl --user restart hindsight`. The service applies only to Linux;
macOS uses the launch agent described below.

## macOS backend lifecycle

`macos.nix` declares `org.nix-community.home.hindsight`, a launch agent with
RunAtLoad and KeepAlive. Apply on the Mac with
`home-manager switch --flake .#neo@mac` from this repository. It survives future
switches and starts again at login. The API binds only to `127.0.0.1:9077`.

The agent runs `hindsight-api==1.1.0` with Python 3.13 through Nix uv. Its PATH
includes Node, Rust and build tools for dependencies that lack macOS wheels.
First launch downloads the Python runtime, backend and embedding/reranking
models and needs internet access. Unlike the Linux host, it does not force
HuggingFace offline mode before models have been downloaded.

Provider/model defaults come from `main.nix`. Authenticate GitHub Copilot on the
Mac with `copilot login` if its existing login is unavailable. Credentials are
read from the user's Copilot authentication, never placed in the Nix store.
The local database is `~/.pg0/instances/hindsight-embed-coding-agent`.
Activation creates a local daemon-mode `~/.hindsight/coding-agent.json` only
when absent; existing configuration is preserved and must point to the local
backend if it previously selected a different server.

Inspect `launchctl print gui/$(id -u)/org.nix-community.home.hindsight` and
`~/.local/state/hindsight/stderr.log`. Check
`curl --fail http://127.0.0.1:9077/health` and run a Hindsight knowledge search
in Codex after the first startup completes.
