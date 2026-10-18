# Home Manager on Linux and macOS

One repository supplies the same editor, shell and development workflow on both
systems. OS-specific tools and native applications implement the desktop features.

| Target | Architecture | Home directory |
| --- | --- | --- |
| `neo@main` | `x86_64-linux` | `/home/neo` |
| `neo@mac` | `aarch64-darwin` (Apple Silicon) | `/Users/neo` |

For a different Mac username, add `username = "your-name";` to the `neo@mac`
definition in `flake.nix`. The target name can stay `neo@mac`. The current unstable
Nixpkgs pin no longer supports Intel Macs; those require a separate compatible
package pin. macOS 14 or newer is required by this package set.

The owner's 14.2-inch MacBook Pro with M5, 10-core CPU, 10-core GPU, 32GB RAM
and 1TB SSD uses `neo@mac`. Apple's [specification page](https://www.apple.com/vn/macbook-pro/specs/)
lists this CPU/GPU combination under the M5 chip; M5 Pro chips have different
core counts. Both use the same Apple Silicon `aarch64-darwin` target. No custom
CPU, GPU, memory or display tuning is required for this Home Manager configuration.

## Modules

- `common.nix`, `main.nix`, `files.nix`, `packages.nix`: shared settings and CLI tools.
- `linux.nix`, `desktop.nix`: NixGL, Fcitx5, Linux GUI packages, systemd and MIME defaults.
- `macos.nix`: native app integration, launchd and Mac paths.
- `platform-tools.nix`: `clipboard-copy`, `clipboard-paste`, `desktop-open`, `qute-menu`.
- `Brewfile`: native Mac apps; Nix owns shared CLI packages and qutebrowser.

Clipboard helpers take input from stdin and write pasted text to stdout:

```sh
printf 'hello' | clipboard-copy
clipboard-paste
desktop-open .
```

Linux uses xclip on X11 and wl-clipboard on Wayland. macOS uses pbcopy/pbpaste,
open and AppleScript dialogs. Neovim uses its existing clipboard provider support.

## First setup

Install Nix with flakes enabled and Home Manager. On the Mac, also install Apple's
Command Line Tools (`xcode-select --install`) and Homebrew.

Use a native Apple Silicon terminal: `uname -m` should print `arm64`, and
`brew --prefix` should print `/opt/homebrew`. Install Nix in this native terminal
so it selects `aarch64-darwin`, and use `sw_vers -productVersion` to check the
installed macOS version. Do not run the main setup terminal under Rosetta.

Clone the repository **with its submodules** into `~/.config/home-manager`. When
moving this working copy to Git, include the new modules, Brewfile and scripts in
the reviewed commit: Git flake sources omit files that Git has not added.
Do not add `secrets/secrets.env`; it stays outside the Nix store and is loaded by Zsh.
Use the Git flake URL below, rather than a `path:` URL to this working directory,
to avoid copying ignored secrets and runtime databases into the Nix store.

On macOS, install the native applications:

```sh
brew bundle --file "$HOME/.config/home-manager/Brewfile"
```

Build the appropriate target before activating it:

```sh
# Linux
home-manager build --flake "git+file://$HOME/.config/home-manager?submodules=1#neo@main"
home-manager switch -b before-dual-platform --flake "git+file://$HOME/.config/home-manager?submodules=1#neo@main"

# Apple Silicon Mac
home-manager build --flake "git+file://$HOME/.config/home-manager?submodules=1#neo@mac"
home-manager switch -b before-dual-platform --flake "git+file://$HOME/.config/home-manager?submodules=1#neo@mac"
```

Restart your terminal after activation. The shared `hms` alias selects the right
target for the machine. Use `brew bundle` again when the Brewfile changes; Home
Manager does not automatically install or upgrade Homebrew apps. Cask versions
are managed by Homebrew and are not pinned by `flake.lock`.

## Platform behavior

- Kitty has shared settings and scrollback mappings. Its Mac app comes from
  Homebrew and uses a filesystem socket instead of Linux's abstract socket.
- qutebrowser retains its settings, password filling, translations and userscripts.
  `~/.qutebrowser` links to the shared config on macOS. AppleScript dialogs replace
  rofi. Nix installs its ARM64 CLI and links its app bundle under
  `~/Applications/Home Manager Apps`; Homebrew apps are installed under `/Applications`.
  Its Homebrew cask is disabled, so it is intentionally omitted from the Brewfile.
- MCPJungle listens on `127.0.0.1:37373`: systemd on Linux, launchd on Mac.
  Mac logs are in `~/.local/share/mcpjungle/`.
- MPD keeps the same music directory and client workflow, using PulseAudio on
  Linux and CoreAudio on Mac. Home Manager manages its platform service.
- Codex CLI and Codex ACP keep the same pinned versions with architecture-specific
  packages. Their authentication/session data is not migrated automatically.
- Fcitx5 stays Linux-only. Enable Vietnamese input in macOS Keyboard settings.
- Figma Linux Next becomes native Figma; WebCord becomes Discord; screenshots
  use macOS Screenshot. Wine and qBittorrent are retained on Linux and omitted
  from the Mac setup, as requested; no Mac torrent client or Windows runtime is installed.
- Tailscale uses its native Mac app. Sign in and enable it after installation.

## MCPJungle server configuration

Home Manager writes GitHub Copilot CLI's user MCP configuration to
`~/.copilot/mcp-config.json`, retaining the existing MCPJungle and CodeGraph
servers. Their JSON lives in `copilot/mcp-config.json`; `copilot.nix` installs it.
The user settings, including the existing default model and reasoning effort,
live in `copilot/settings.json`. Add plugin enablement under `enabledPlugins`;
installed plugin state remains managed by Copilot CLI.

Home Manager owns both files, so edit their source files instead of changing
settings with Copilot CLI commands that write back to disk.

`mcpjungle-config.nix` defines the six managed servers for both platforms. Home
Manager generates their JSON files under `~/.config/mcpjungle/servers/`, including
native Nix Node paths and the configured home directory. Existing standalone JSON
files are left in place; the sync command only reads the `servers/` directory.

For the initial activation, make the two new files visible to the Git-backed
flake with `git add mcpjungle-config.nix scripts/mcpjungle-sync.py` (no commit is
required). After your usual `hms` activation, start the gateway if necessary and run
`mcpjungle-sync`. To update only selected servers, pass their names, for example
`mcpjungle-sync anki filesystem`. This is an explicit operation: activation and
gateway restarts do not automatically replace registrations.

For Figma, supply `FIGMA_API_KEY` in the sync command's environment, or put the raw
key in `~/.config/mcpjungle/figma-api-key` and set its permissions to `600`. Keep
this file outside the repository. Use a newly rotated key; the previous setup
embedded it in command arguments. The generated JSON contains no key; syncing
passes it to Figma through its server environment. MCPJungle still stores the
resolved credential in its runtime SQLite database.

Sync checks all selected configurations and required credentials before making
changes, then backs up the existing SQLite database under
`~/.local/share/mcpjungle/backups/` with private file permissions. It uses
`register --force`, which removes and recreates each selected registration and
can interrupt active sessions or reset per-tool enable/disable settings. It stops
on the first failure, so earlier servers may already have changed. Keep backups
private; they contain credentials. To restore one, stop the gateway before
replacing its database with the backup, then restart it.

Servers removed from the definitions are not automatically deregistered. Remove
them deliberately with `mcpjungle --registry http://127.0.0.1:37373 deregister NAME`.
Atlassian OAuth login state stays in its existing runtime location. On a new Mac,
authenticate there and provide local Anki/Chrome services separately.

## Setup that needs the actual Mac

Citrix Secure Access must be installed from your company's approved Mac installer;
Citrix Workspace is a different product and is not substituted automatically.
The Linux LibreOffice MCP runtime/profile cannot be copied to macOS: install and
verify the MCP extension with native LibreOffice before relying on that workflow.
UniClipboard uses its native Mac app, retaining clipboard history and sync;
pair devices and grant its requested permissions after installation. The clipboard
commands also work independently of UniClipboard.

Copy personal credentials and GPG/pass data separately using your normal secure
process. Clone the local `~/personal/learn/plugins/jillra` development plugin and
the work repositories if you use their Neovim tasks. Neovim paths derive from
the user's home directory; local virtual environments still need recreation.
The configured Node 22.14.0, 24 and 18.16.0 releases provide native
`darwin-arm64` binaries, so these toolchains do not inherently require Rosetta.
Node 18.16.0 is retained for existing projects; its runtime on current macOS
still needs verification.

## Checks

```sh
python3 scripts/test_macos_menu.py
git diff --check
```

Build and test each target on its own OS. Linux evaluation of a Darwin derivation
checks the configuration graph, not whether native apps, audio, clipboard,
authentication or macOS permissions work on a real Mac.

References: [Home Manager installation](https://nix-community.github.io/home-manager/installation.html),
[qutebrowser configuration paths](https://qutebrowser.org/doc/help/configuring.html),
[Nixpkgs Darwin requirements](https://nixos.org/manual/nixpkgs/stable/release-notes.html).

The Brewfile was checked against Homebrew's current cask metadata for disabled
packages and architecture/macOS restrictions. All remaining entries were enabled
and compatible with Apple Silicon at review time. Installation and native runtime
checks still need to run on the actual Mac.
