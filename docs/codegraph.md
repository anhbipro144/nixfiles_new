# CodeGraph with Home Manager

CodeGraph **1.6.2** is installed through `home.packages` on `neo@main`
(`x86_64-linux`) and `neo@mac` (`aarch64-darwin`). The existing flake lock pins its
Nix dependencies. No flake inputs or lockfiles were changed.

The implementation is activated and verified on macOS. Both targets evaluate;
Linux build/activation remains unverified because this session has no Linux
host or compatible Nix builder. See the exact blocker below before treating the
Linux migration as complete.

## Files and package

- `packages/codegraph.nix`: exact release URLs/hashes, complete upstream bundle,
  Linux ELF fixup, runtime wrapper and install checks.
- `packages.nix`: shared CLI installation, CodeGraph-only PATH precedence and
  persisted telemetry opt-out during activation.
- `codex.nix`: direct MCP server and two supplemental global instruction lines.
- `tests/test_codegraph_mcp.py`: live CLI/MCP checks using disposable repositories.
- `README.md`: links to this runbook. Platform modules and `flake.lock` are unchanged.

The [latest stable release](https://github.com/colbymchenry/codegraph/releases/tag/v1.6.2)
was verified as 1.6.2 on 2026-10-18. Both archives were downloaded and inspected
before implementation. Their computed hashes matched the release's
[`SHA256SUMS`](https://github.com/colbymchenry/codegraph/releases/download/v1.6.2/SHA256SUMS)
and GitHub asset digests:

| System | Official asset | Fixed-output SHA-256 |
| --- | --- | --- |
| `x86_64-linux` | `codegraph-linux-x64.tar.gz` | `sha256-7wr0FgkhKPsczHI3hgALft9KaXH+YErNCL+Wbk83uCg=` |
| `aarch64-darwin` | `codegraph-darwin-arm64.tar.gz` | `sha256-100b+0Bg22PsPCtyxOF/dsMZeK87rWrOQ3DRUBrAZi4=` |

Each archive contains 1,380 entries: bundled Node, the executable launcher,
compiled application, production dependencies, grammars, schema and UI assets.
The derivation copies the complete layout to `$out`, wraps `$out/bin/codegraph`,
and preserves executable permissions. It does not replace the bundled Node,
run npm/npx, install agent integrations, or download dependencies at runtime.
The macOS Node binary was verified byte-for-byte against the release archive.

Linux's Node ELF dependencies were inspected: glibc and GCC's `libstdc++` and
`libgcc_s` cover its dynamic imports. `autoPatchelfHook` fixes its interpreter
and library paths on Linux. Coreutils supplies the launcher's `readlink` and
`dirname`; Git supports repository operations. All are referenced through Nix.
The Linux fixup is evaluated but still requires execution on a Linux builder.

## Codex integration and workspace selection

`programs.codex.settings.mcp_servers.codegraph` uses the package's absolute
`bin/codegraph` path, `args = [ "serve" "--mcp" ]`, a 60-second startup timeout
and a 120-second tool timeout. Its environment explicitly sets:

```nix
CODEGRAPH_TELEMETRY = "0";
CODEGRAPH_NO_UPDATE_CHECK = "1";
```

The model remains `gpt-6-luna`, and `mutableSettings = true` remains enabled.
The existing mutable Codex configuration was privately backed up before
activation. A parsed comparison after activation found the existing configuration
identical after removing the newly added CodeGraph entry from the comparison.
Context Mode, Ponytail, Open Code Review, Chrome DevTools and MCPJungle settings
are preserved. Hindsight's existing configuration is unchanged.

There is one direct CodeGraph registration in Codex. Copilot's existing
`codegraph serve --mcp` registration remains in `copilot/mcp-config.json`; a
separate agent using the same executable is not a duplicate in Codex. The live
Mac MCPJungle registry has no CodeGraph server. No CodeGraph marketplace/plugin
registration was added, and `codegraph install` was never run. Inspect the Linux
machine's live registrations separately before switching there.

No `cwd`, repository path or `--path` is hardcoded in the MCP configuration.
[Upstream's session implementation](https://github.com/colbymchenry/codegraph/blob/v1.6.2/src/mcp/session.ts)
accepts initialize `rootUri`/`workspaceFolders`, then MCP `roots/list`, with the
server's inherited working directory as fallback. Its bounded root resolver can
find an indexed ancestor or subproject. A tool's explicit `projectPath` selects
another indexed repository. When no default index exists, the exposed tool
requires `projectPath`; it does not initialize the directory automatically.

[Codex's documented MCP configuration](https://developers.openai.com/codex/mcp/)
supports these settings and is shared by local CLI and desktop clients. Restart
Codex/Desktop to load the new server into an existing session's tool catalog.
This session verified registration through `codex mcp get/list` and the actual
stdio protocol separately; it did not claim that an already-running desktop
conversation refreshed its tools.

CodeGraph supplies exploration, call-flow, language-support and no-auto-indexing
instructions in its MCP initialize response. Rather than duplicating that
playbook, Home Manager adds only guidance to use impact analysis before major
refactors and verify consequential findings against current source, falling back
to native search for missing, stale or incomplete indexes. These lines live in
`programs.codex.context`, which manages `~/.codex/AGENTS.md`; no existing global
instruction file was present on this Mac.

## Telemetry, updates and mutable state

The package wrapper forces the two official environment variables for every
invocation, including CLI commands, MCP sessions and inherited child processes.
Activation also runs the official `codegraph telemetry off` command. The live
persisted preference is `enabled: false`, `machine_id: null`, with consent source
`cli`. Opt-out also removes upstream's queued telemetry, as requested.

Upstream documents these mechanisms in
[`TELEMETRY.md`](https://github.com/colbymchenry/codegraph/blob/v1.6.2/TELEMETRY.md)
and implements update suppression in
[`update-check.ts`](https://github.com/colbymchenry/codegraph/blob/v1.6.2/src/upgrade/update-check.ts).
The opt-out disables background update checks; upstream otherwise only reports
new versions. Because the separate `upgrade` command can run an installer, the
Nix wrapper rejects it, including after `--color`/`--no-color`, with instructions
to update this derivation. No self-update or imperative installer is needed.

Only runtime binaries live in the Nix store. Global preferences remain under
`~/.codegraph`; per-project indexes remain in `<repo>/.codegraph`. No home
directory is indexed, and activation never initializes or rebuilds any index.
The Nix repository already ignores `.codegraph`; keep that exclusion in every
indexed project's `.gitignore`.

## Before migrating existing Linux indexes

On this Mac, `~/.local/bin/codegraph`, `~/.codegraph/current` and
`~/.codegraph/versions` were absent. No project indexes were found under
`~/persona` before activation. Consequently, no real index was migrated here.
The Linux installation and its indexes are inaccessible from this session.

The old 1.5.0 release uses schema **8**; 1.6.2 uses schema **11**. Upstream applies
transactional migrations when opening an index. A disposable 1.5.0 index was
backed up with SQLite's backup API, then opened through 1.6.2 and exercised over
MCP: schema reached 11, indexed file rows were preserved, and both databases
passed `PRAGMA integrity_check`. The pre-upgrade backup retained schema 8.
See [upstream migrations](https://github.com/colbymchenry/codegraph/blob/v1.6.2/src/db/migrations.ts).
This verifies the migration mechanism, not the contents of unseen Linux indexes.

Before starting the newer CLI/MCP against each existing Linux project, close
agents using it and back up its database. Use a Python with a current SQLite
runtime (the pinned Nix Python was used for the live test). For example:

```sh
python3 - /absolute/path/to/project <<'PY'
from datetime import datetime, timezone
from pathlib import Path
import os, sqlite3, sys
repo = Path(sys.argv[1]).resolve()
database = repo / '.codegraph/codegraph.db'
assert database.is_file(), database
directory = Path.home() / '.local/state/codegraph/backups'
directory.mkdir(parents=True, exist_ok=True, mode=0o700)
stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
backup = directory / f'{repo.name}-{stamp}.sqlite3'
os.umask(0o077)
with sqlite3.connect(database) as source, sqlite3.connect(backup) as target:
    source.backup(target)
    assert target.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
print(backup)
PY
```

SQLite's backup API includes committed WAL content; copying only `codegraph.db`
while a writer is active can lose data. Keep existing project configuration,
`.gitignore` and CodeGraph global preferences. Do not run `init`, `index`,
`uninit`, or the general `uninstall` command as a migration shortcut. A full
re-index is optional for newer extraction behavior, not required merely to
preserve/open an old index.

## Apply and validate

Make the new package visible to the Git-backed flake without committing:

```sh
cd "$HOME/.config/home-manager"
git add -N packages/codegraph.nix
# Choose neo@main on Linux or neo@mac on Apple Silicon.
home-manager build --flake "git+file://$PWD?submodules=1#neo@main"
home-manager switch --flake "git+file://$PWD?submodules=1#neo@main"
home-manager switch --flake "git+file://$PWD?submodules=1#neo@main"
```

Restart the terminal so its PATH is refreshed. The package's bin directory is
prepended ahead of old `~/.local/bin` launchers without changing other packages'
precedence. Direct Codex MCP commands never depend on the shell PATH.

```sh
type -a codegraph
codegraph --version
codegraph --help
codegraph status                 # reports not initialized in an unindexed repo
codegraph telemetry status
codex mcp get codegraph --json
codex mcp list --json
```

The live test accepts a Nix-managed executable and optionally an older official
binary. It uses fresh temporary repositories, a private temporary HOME, real
MCP JSON-RPC, SQLite backups, and cleanup; it never indexes user projects:

```sh
python3 tests/test_codegraph_mcp.py "$(command -v codegraph)"
# Optional migration exercise: append the old release's bin/codegraph path.
```

## Verified results and limitations

Verified on macOS 26.6, ARM64, 2026-10-18:

| Check | Result |
| --- | --- |
| Official release assets, archive layout and both SHA-256 hashes | Passed |
| macOS package build and install checks | Passed: version, enforced telemetry opt-out and blocked self-upgrade |
| Both Home Manager target evaluations | Passed, including complete activation derivations |
| macOS Home Manager build and two activations | Passed |
| Fresh login shell | Nix store executable first, then Nix profile; version 1.6.2 |
| CLI help and status | Passed; unindexed Nix repo remained unindexed |
| Telemetry | CLI reports disabled; persisted choice off with no machine identity |
| Codex recognition | Enabled direct server, exact store command, expected args/env/timeouts |
| Actual stdio MCP | Initialize response plus instructions; `codegraph_explore` discovered and called successfully |
| Multiple projects | One MCP connection used client roots for project A and `projectPath` for project B |
| Index migration and backup | Disposable schema 8 -> 11, file rows retained, backup retained schema 8, both integrity checks passed |
| Existing Codex integrations | Parsed configuration preserved; Context Mode tools continued executing live; Ponytail/Open Code Review enabled |
| Chrome DevTools and MCPJungle | Existing entries unchanged; gateway responded and retained its six server registrations |
| Home/project index safety | No home index or real project index created; all fixtures were temporary |

The Linux Home Manager build was attempted. Its dependency downloads were stopped
after confirming there was no compatible builder; a separate no-substitute
Linux package build returned the exact error:

```text
Reason: platform mismatch
Required system: 'x86_64-linux'
Current system: 'aarch64-darwin'
```

The safest next step is to run the documented build and two activations on the
actual Linux machine after backing up its indexes, or supply an existing Linux
SSH/builder host. No Linux activation, old Linux launcher precedence, real Linux
index preservation or Linux runtime success is claimed. Desktop tool use in a
new conversation also remains to be confirmed after restarting that client.

## Manual installation cleanup

Nothing was removed on this Mac: there was no old launcher/runtime. On Linux,
after successful CLI/MCP validation and backups, inspect `type -a codegraph`,
`readlink ~/.local/bin/codegraph` and `readlink ~/.codegraph/current`. Verify the
first executable resolves to this Nix package in a fresh terminal.

Keep the manual launcher and version directories until no old CodeGraph process
or other agent references them. You can move the confirmed manual launcher to
`~/.local/bin/codegraph.manual-before-nix` as a reversible cleanup, then remove
obsolete version directories only after checking those references. Keep
`~/.codegraph` preferences, all project `.codegraph` directories and backups.
Do not run CodeGraph's general uninstall command; it also removes integrations.

## Upgrade and rollback

1. Check the stable GitHub release and inspect both actual archives.
2. Update `version` and the two verified hashes in `packages/codegraph.nix`.
3. Review schema changes; back up existing indexes before a newer runtime opens them.
4. Build and activate the appropriate Home Manager target using the existing workflow.
5. Restart the terminal and Codex/Desktop; repeat CLI and live MCP checks.
6. Migrate indexes only when required; never automatically reinitialize them.

`codegraph upgrade` is deliberately blocked. Nix/Home Manager owns package updates.

Use `home-manager generations` and activate a retained previous generation's
`/nix/store/...-home-manager-generation/activate` to roll back. Keep the previous
generation and database backups until validation is complete. **Mutable Codex
settings are merged, not reverted:** a rollback to a generation predating this
integration can retain `mcp_servers.codegraph`. Use `codex mcp remove codegraph`
to remove only that added mutable entry if fully rolling this integration back;
do not replace the entire Codex config. Restart the terminal/client afterwards.

If an index has migrated, do not assume an older CLI can safely use the newer
schema. Stop clients/daemons for that project, retain the migrated database as
another backup, and restore the pre-upgrade SQLite snapshot before using the old
runtime. Do not delete a live database or its WAL/SHM files while it is in use.
