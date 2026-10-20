# Jev Router for Codex

On `neo@mac`, Home Manager installs `jev-codex`, a persistent local proxy, and
`codex-direct` alongside Codex CLI. New Codex sessions use the registered Jev
provider at `http://127.0.0.1:37374`. Plain `codex` keeps its configured concrete
model; `jev-codex` selects `jev-auto` for automatic per-turn routing.
The package is `@flaviusapop/jev-router` 1.0.0, pinned to
[`0ada4f883127ea9e5cd0e00521b442ce804b17c9`](https://github.com/flaviusapop/jev-router/tree/0ada4f883127ea9e5cd0e00521b442ce804b17c9).
Node.js 24 satisfies the fork's Node.js >=22 requirement.

The shared-server integration lives in `jev-router.nix`,
`scripts/jev-codex-proxy.mjs`, and the small package patch beside
`packages/jev-router.nix`. It changes the macOS default provider, leaves model
and policy defaults in `codex.nix`, and preserves existing authentication,
MCP definitions, agent configuration, secrets, and lockfiles. Linux does not
import this integration.

## Packaging

The previous package used `stdenvNoCC.mkDerivation`, a commit-pinned
`builtins.fetchGit`, and a directly fetched SDK tarball, rather than
`buildNpmPackage`. Its version was 0.3.0 at commit
`38da6b84ea01241bfc41fbddc0928d0f40a703f0`; it had no explicit source hash or npm
dependency hash. The SDK was 0.6.0 with integrity
`sha512-IddX+Q0XM+VagOUZFeP7wZjaO4SHMdvnh2zEBdrZZnXedWI3BNK1lKhMx3ayrkFWvVLbVcUHJy6AVZlY+e6Jaw==`.

The fork's consistent package version and lockfile allow `buildNpmPackage` to
replace the hand-written dependency extraction, installation, and wrappers:

- Source hash: `sha256-+YE8nNmRoXCHdANLMPoR2fIQo/mx3bAxWQv5Y+OwMAE=`.
- npm dependency hash: `sha256-swwrAAD/9AyfzOgHRZuIPoOwXEXjg8K1YaVtCKMP+xc=`.
- Locked runtime dependency: `@typesafe-ai/sdk` 0.6.0, with the same integrity.
- npm package path: `lib/node_modules/@flaviusapop/jev-router`.
- The local patch adds a stable listen port, a local health endpoint, and clean
  rejection of bind errors. It does not change routing policy or upstream defaults.
- No global npm installation or second router package.

The replacement built successfully before the previous package definition was
replaced. The new Home Manager closure contains only the fork. Old generations
may retain the old package for rollback; they are not duplicate installations in
the new generation. To update, change the pinned commit and source hash, and
recompute `npmDepsHash` whenever the lockfile changes.

## API key

The proxy reads only `JEV_API_KEY` and `TYPESAFE_API_KEY` from the existing
`~/.config/home-manager/secrets/secrets.env` at runtime. Explicit service
environment values take precedence; the fork's native `~/.jev-router.env` and
legacy `~/.jev-claude.env` remain fallbacks. Nothing copies credentials into the
Nix store or launchd plist. The launcher strips both key variables before
starting Codex. Secret files and Agenix configuration are unchanged.

If the routing key is absent, `jev-codex` reports the problem before starting an
automatic-model session. The proxy can still forward concrete model requests.
Use `codex-direct` when the proxy itself is unavailable.

## Use and settings

```sh
jev-codex
jev-codex resume --last
jev-codex exec "example task"
codex-direct
codex-direct resume --last
```

The wrapper preserves Codex arguments and existing login, adding only
`--model jev-auto` when no explicit model was supplied. It does not inject
provider `--config` arguments or `--remote`: Codex 0.163 excludes most command-line
configuration overrides from its native local daemon, and only that native mode
enables Left Arrow for Agents navigation with an empty prompt.

The registered provider and persistent proxy let routed sessions use the native
shared server. The proxy remains available when the TUI disconnects or switches
chats. Plain `codex` also uses the proxy for sessions on the Jev provider, but a
concrete model passes through without a routing decision. `codex-direct` uses
OpenAI directly and bypasses the daemon; its recovery sessions do not offer the
shared Agents shortcut. Explicit `--config`, `--remote`, and `--no-daemon` flags
can still change Codex's navigation behavior.

Jev receives prompt text for classification; only use this integration for
prompts that may be shared with TypeSafe.

In a new routed session, `/model` shows `Jev Router` (`jev-auto`) as selected
before the first prompt. Choosing a concrete model pauses routing; selecting
Jev Router resumes it. If Codex only shows a concrete model, check `/model`,
the startup warning, and the proxy's local health endpoint. An explicit
`-m` or `--model` argument preserves that concrete selection.

The fork has no `jev-explain` executable, explanation skill, decision-history
format, or `JEV_CODEX_STATUS_ID` integration. The previous skill is incompatible
and its executable is no longer installed. Use the fork's native per-turn
commentary, which includes the selected model, effort, policy reason, and
confidence. An old skill copied into `~/.agents/skills/jev-router-explain` or
`~/.agents/skills/jev-explain` remains an unmanaged home file until you archive
that specific old skill directory. Do not invoke it after switching. This
migration does not delete any home-directory skills or historical decisions.

Model and effort defaults are configurable independently through
`programs.jevRouter.codexModels` and `programs.jevRouter.codexEfforts`:

| Tier | Internal ID | Model | Effort | Enabled |
| --- | --- | --- | --- | --- |
| FAST | `haiku` | `gpt-6-luna` | `low` | Yes |
| BALANCED | `sonnet` | `gpt-6.1-sol` | `medium` | Yes |
| STRONG | `opus` | `gpt-6.1-sol` | `high` | Yes |
| LONG | `fable` | `gpt-6.1-sol` | `xhigh` | No |

The existing model mappings are preserved. The local Codex model catalog lists
both IDs and supports all four configured effort levels. A single-tier override
preserves the other defaults:

```nix
programs.jevRouter.codexEfforts.strong = "high";
programs.jevRouter.disabledTiers = [ ]; # Enable LONG.
```

Each option supplies the corresponding `JEV_CODEX_{FAST,BALANCED,STRONG,LONG}`
`_MODEL` or `_EFFORT` variable to the launchd service. Set these options and
activate Home Manager to change the shared routing policy; temporary variables
in the launching terminal no longer configure the persistent proxy.
By default, `JEV_DISABLE_TIERS=fable` preserves the previous conservative long-tier
behavior. `programs.jevRouter.disabledTiers = [ ];` enables all four tiers.

The fork writes the selected effort into the outgoing `reasoning.effort`, even
when Codex initially requested another effort. Unsupported efforts fall back to
the target model's catalog default. Choosing a concrete model passes its model
and effort through; choosing `jev-auto` resumes automatic routing. Codex's own
effort picker does not override the tier effort while auto routing is active.

## Routing and security differences

| Behavior | Previous implementation | Pinned fork |
| --- | --- | --- |
| Fresh user turns | Per-turn classification | Per-turn classification; tool continuations retain the pair |
| Classification | Account's exact model candidates | Native four-tier classification mapped to configured model/effort pairs |
| Confidence floor | 0.3 | 0.6; no uncertain downgrade, upgrades capped at BALANCED or current tier |
| Large-context downgrades | Refused above 20,000 estimated tokens | Same guard, released after three confident cheaper recommendations |
| Effort | Incoming effort retained/clamped | Selected tier effort explicitly forwarded and catalog-clamped |
| Child isolation | Cache-key-based conversation identity | Thread ID, then window ID, then cache key; separate tier and streak maps |
| Child handback | Could resemble a fresh user turn | Explicitly excluded from rerouting |
| Manual model | Concrete selection pauses routing | Concrete selection pauses routing; `jev-auto` re-enables it |
| Model availability | Exact candidate selection and local catalog-filter patch | Native configured-ID checks against fetched catalog; patch removed |
| Long tier | Opt-in | All tiers native default; wrapper disables `fable` |
| Failure | Keep current model, or launch plain Codex without a key | Keep current pair; missing-key diagnostic and direct recovery command |

Child requests using `jev-auto` route independently even if their prompt cache
key is inherited from the parent. A child explicitly configured with a concrete
model retains that selection, matching native manual-override semantics.
Existing agent configuration files are untouched.

The proxy listens only on `127.0.0.1:37374`, forwards Codex bearer and account
headers to HTTPS OpenAI endpoints, and sends the router key only to the SDK's
fixed `https://api.typesafe.ai` endpoint. The launcher strips `JEV_API_KEY` and
`TYPESAFE_API_KEY` before starting Codex. The persistent service clears
`JEV_DEBUG` and `JEV_DUMP` after dotenv loading, preventing either inherited
values or upstream dotenv files from enabling request dumps.
The fork's Codex path does not write the previous prompt/decision temp history.
Upstream tests use temporary fixture directories; no real credentials enter
test fixtures or Nix derivations.

Classification failures have a 3-second deadline and retain the current pair.
OpenAI/network errors still surface normally; the proxy cannot recover an
unavailable or unauthorized configured model. Before a catalog arrives it trusts
the configured IDs. With no usable enabled catalog tier, its fallback can still
be unavailable: keep at least one accessible tier enabled. Unexpected proxy bind
or startup failures surface through the health check and private service logs. The fork does
not reproduce private enterprise workspace routing origins.

## Service operations

The launchd agent is `org.nix-community.home.jev-codex-proxy`. It starts at login
and restarts after failure. `jev-codex` checks readiness and asks launchd to start
the existing job if necessary. Logs are in `~/.local/state/jev-router`, whose
directory is restricted to the account owner. Logs contain startup diagnostics;
request and prompt dumps remain disabled.

```sh
curl --fail http://127.0.0.1:37374/_jev/health
launchctl print "gui/$(id -u)/org.nix-community.home.jev-codex-proxy"
codex-direct resume --last
```

Changing a key or routing settings requires restarting the proxy. A restart can
interrupt requests already using it; let active turns finish first. If the proxy
is stopped, `codex-direct` provides an independent recovery path using the
existing OpenAI login. Shared Agents navigation is available again after the
proxy is restored and a normal shared session is opened.

## Shared-server validation

The prototype uses Codex CLI and shared server 0.163.0. The patched Nix package
passes all 154 upstream tests. Eleven additional local-only checks cover health
identity, automatic model/effort routing, fixed-model passthrough, OpenAI header
forwarding, occupied ports, restart, runtime dotenv credentials, resume/exec
arguments, explicit model selections, missing keys, and direct recovery. Those
checks use fake credentials and a mock upstream; they send no prompts externally.

The reviewed Home Manager generation was activated on 2026-10-19, preserving
unrelated pending changes and the installed Raycast package. Live checks passed:

- Left Arrow opened the Agents command center before and after a routed turn.
- A harmless diagnostic turn selected FAST (`gpt-6-luna`, low effort) and returned
  `JEV_SHARED_OK`. The outgoing effort was checked offline; the live provider
  response does not independently attest effort.
- Resuming that diagnostic thread retained native Left Arrow navigation.
- `codex-direct` returned `JEV_DIRECT_OK` through the OpenAI provider. Reopening
  that synthetic historical chat through Jev used the Jev provider and retained
  Agents navigation.
- After graceful proxy shutdown, launchd restarted it with a new PID and healthy
  routing. The shared Codex server stayed running; other work was not restarted.

These live checks used only synthetic prompts in a temporary directory.
Interactive model-picker re-selection, login/reboot behavior, and interruption
of a long streaming turn were not exercised. The mock checks cover manual-model
passthrough, routing state, and unavailable-service recovery. Existing embedded
sessions cannot move into the daemon in place: reconnect with `jev-codex resume`
and choose the chat to gain native Agents navigation.

For rollback, run `home-manager generations` and execute the previous
generation's `/nix/store/...-home-manager-generation/activate` to remove the
new launchd agent and restore the old launcher. Codex uses mutable settings:
merging an old generation does not delete the new provider key. Also restore
the previous `model_provider` value in `~/.codex/config.toml` (normally remove
the key, or set it to `"openai"`). Preserve other settings changed since the
upgrade. The activation test keeps a pre-change configuration backup beside
that file. Keep the previous generation until the workflow is satisfactory.
Revert only these integration hunks in source; preserve unrelated worktree edits.

## Original fork migration validation (historical)

Validated on Apple Silicon macOS, 2026-10-19, using Node.js 24.16.0 and Codex CLI
0.161.0:

- Nix package evaluation and build: passed with pinned source and npm hashes.
- All 154 upstream automated tests: passed, zero failures or skips, inside the
  Nix build. This includes macOS launcher, security, and multi-agent fixtures.
- macOS Home Manager activation package: built successfully without activation.
- Evaluated defaults, single-model/effort overrides, and enabling LONG: passed.
- Inspected the new closure: one fork package; plain `codex` resolves to the
  existing Codex 0.161.0 derivation, and `jev-explain` is absent.
- Additional offline checks against the installed fork: all four outgoing
  model/effort pairs, SDK key delivery, auth-header forwarding, independent
  parent/child pairs with a shared cache key, continuation pinning, manual-model
  passthrough, auto re-selection, disabled/enabled LONG, failure fallback, and
  proxy shutdown passed.
- Built Nix wrapper with a stub Codex: resume/exec arguments and quoting,
  environment overrides, key stripping, missing-key fallback, dotenv-resistant
  debug/dump suppression, and shutdown after child exit passed.
- Real built launcher `resume --help`: passed. Existing `codex login status`
  reports ChatGPT login.
- Harmless live ephemeral Codex execution using the existing runtime key and
  login: passed. Jev chose FAST (`haiku`, confidence 1); the observed HTTPS
  request contained `model=gpt-6-luna` and `reasoning.effort=low`, and the parsed
  OpenAI response reported `model=gpt-6-luna`. The reply was `ROUTER_OK`. MCP
  startup was disabled only for this invocation; no global settings were changed.
  The provider does not independently attest the effort; effort is verified on
  the accepted outgoing request.

The temporary offline/live validation harnesses are under `/private/tmp`, not
installed as additional configuration. The upstream suite continues to run on
every package rebuild. Interactive picker use, resuming a real historical
session, live multi-agent work, and every model/effort combination were not
exercised against the live provider. Their routing paths were verified offline.
No real session or credential was rewritten. CodeGraph was unavailable for this
unindexed repository, so references and impact were checked against current
source using native search.

The original migration was built before activation. This historical switch
command applies every pending Home Manager change, so review those changes:

```sh
home-manager switch -b before-jev-router --flake 'git+file:///Users/admin/persona/nix-files?submodules=1#neo@mac'
```

The old explanation skill is unmanaged and incompatible with the pinned fork.
The migration did not delete home-directory skills or commit any changes.
