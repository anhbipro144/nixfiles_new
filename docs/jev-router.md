# Jev Router for Codex

On `neo@mac`, Home Manager installs `jev-codex` alongside the existing Codex
CLI. Plain `codex` and its managed settings remain unchanged.
The package is `@flaviusapop/jev-router` 1.0.0, pinned to
[`0ada4f883127ea9e5cd0e00521b442ce804b17c9`](https://github.com/flaviusapop/jev-router/tree/0ada4f883127ea9e5cd0e00521b442ce804b17c9).
Node.js 24 satisfies the fork's Node.js >=22 requirement.

The migration changes only `packages/jev-router.nix`, `jev-router.nix`, and this
document. Existing unrelated staged and unstaged changes were preserved. No
Linux configuration, Codex settings, MCP definitions, agent configurations,
authentication files, secrets, or flake lockfiles were changed.

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
- No routing patches, global npm installation, services, or extra installed router.

The replacement built successfully before the previous package definition was
replaced. The new Home Manager closure contains only the fork. Old generations
may retain the old package for rollback; they are not duplicate installations in
the new generation. To update, change the pinned commit and source hash, and
recompute `npmDepsHash` whenever the lockfile changes.

## API key

The repository's Agenix secrets are Linux-only and have no configured macOS
recipient. The existing Zsh configuration loads
`~/.config/home-manager/secrets/secrets.env` at runtime. Keep using that existing
mechanism to export `JEV_API_KEY`; the Nix wrapper does not create or read a
secrets file. Agenix configuration and secret paths are unchanged.
Home Manager does not configure a global API key,
and the private PATH shim removes it before launching Codex. The upstream
launcher also supports its native optional dotenv files. If no key is found,
Jev Router prints a warning and starts ordinary Codex without routing. Keep the
tracked `secrets/secrets.env.example` blank so a key cannot enter Git or the
Nix store. The existing macOS runtime file was observed with mode 0644; it was
not rewritten or copied. Restrict it to owner access (`chmod 600` on the existing
file) if it contains credentials. No key values were printed during validation.

## Use and settings

```sh
jev-codex
jev-codex resume --last
jev-codex exec "example task"
```

The wrapper preserves Codex arguments and uses Codex's existing login. The
upstream launcher adds temporary provider settings on the command line and
removes its loopback proxy when Codex exits. It does not rewrite global Codex
configuration. Jev receives prompt text for classification; only use this
integration for prompts that may be shared with TypeSafe.

In a new routed session, `/model` shows `Jev Router` (`jev-auto`) as selected
before the first prompt. Choosing a concrete model pauses routing; selecting
Jev Router resumes it. If Codex only shows a concrete model, check `/model`,
the startup warning, and whether `JEV_API_KEY` reached `jev-codex`. An explicit
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
`_MODEL` or `_EFFORT` variable. Existing environment overrides take precedence.
By default, `JEV_DISABLE_TIERS=fable` preserves the previous conservative long-tier
behavior. `programs.jevRouter.disabledTiers = [ ];` enables all four tiers unless
the invoking environment overrides it. The obsolete long-tier opt-in setting is
removed. Ensure an existing environment override does not unintentionally enable
LONG.

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
| Failure | Keep current model, or launch plain Codex without a key | Keep current pair; same missing-key fallback |

Child requests using `jev-auto` route independently even if their prompt cache
key is inherited from the parent. A child explicitly configured with a concrete
model retains that selection, matching native manual-override semantics.
Existing agent configuration files are untouched.

The proxy listens on `127.0.0.1` on an ephemeral port, forwards Codex bearer and
account headers to HTTPS OpenAI endpoints, and sends the router key only to the
SDK's fixed `https://api.typesafe.ai` endpoint. The private Codex shim strips
`JEV_API_KEY` and `TYPESAFE_API_KEY` before starting Codex. There is no background
service. The wrapper exports empty `JEV_DEBUG` and `JEV_DUMP` values, preventing
either inherited values or upstream dotenv files from enabling request dumps.
The fork's Codex path does not write the previous prompt/decision temp history.
Upstream tests use temporary fixture directories; no real credentials enter
test fixtures or Nix derivations.

Classification failures have a 3-second deadline and retain the current pair.
OpenAI/network errors still surface normally; the proxy cannot recover an
unavailable or unauthorized configured model. Before a catalog arrives it trusts
the configured IDs. With no usable enabled catalog tier, its fallback can still
be unavailable: keep at least one accessible tier enabled. Unexpected proxy bind
or startup failures are not covered by the missing-key fallback. The fork does
not reproduce private enterprise workspace routing origins.

## Validation and activation

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

The new generation has **not been activated**: switching also applies the
unrelated Home Manager changes already present in this worktree. Review those
changes before switching:

```sh
home-manager switch -b before-jev-router --flake 'git+file:///Users/admin/persona/nix-files?submodules=1#neo@mac'
```

Until switching, the installed `jev-codex` and old explanation skill remain from
the current generation. Git flakes exclude untracked files: this documentation
was already untracked on entry and should be included in a future reviewed
commit. No files were staged or committed by this migration.

For rollback, run `home-manager generations` and execute the previous
generation's `/nix/store/...-home-manager-generation/activate`. Keep that
generation until the migrated workflow is satisfactory. For source rollback,
undo only the migration hunks in the three files above, preserving the existing
unrelated staged and unstaged changes. Do not use a blanket `git restore` here.
