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
- `Brewfile`: native Mac apps without a suitable Nix package; Home Manager installs supported apps.

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
target for the machine. Home Manager installs ChatGPT, Kitty, Chrome, Discord,
Anki, Zotero and Fira Code Nerd Font from the Nix package set pinned in
`flake.lock`. Use `brew bundle` for the remaining native apps listed in the
Brewfile.

## Platform behavior

- Kitty has shared settings and scrollback mappings. Home Manager installs its
  Mac app bundle and it uses a filesystem socket instead of Linux's abstract socket.
  The native macOS title bar is hidden with `hide_window_decorations titlebar-only`.
  Config reload was applied; open a new OS window if an existing window retains
  its title bar, since decoration changes on reload are platform-dependent.
  On macOS, its repaint interval is 2 ms with monitor synchronization enabled.
  The interval controls scheduling, not measured FPS: it does not establish
  90 FPS or change the display refresh rate. It leaves room for rendering at
  the built-in display's reported 120 Hz; actual presentation needs measurement.
- qutebrowser retains its settings, password filling, translations and userscripts.
  `~/.qutebrowser` links to the shared config on macOS. AppleScript dialogs replace
  rofi. Nix installs its ARM64 CLI and copies its app bundle under
  `~/Applications/Home Manager Apps`; Homebrew apps are installed under `/Applications`.
  The built-in Home Manager `copyApps` mode creates real app bundles for Spotlight
  discovery; the older symlink mode is explicitly disabled without changing
  `home.stateVersion`. Launcher indexing may take a little time after activation.
  Verified on this Mac: qutebrowser opens, and Spotlight finds its bundle by
  `org.nixos.qutebrowser`. Launch it with Option+Space and search `qutebrowser`,
  or open `~/Applications/Home Manager Apps/qutebrowser.app` in Finder.
  A macOS-only package patch ignores Cocoa's startup file-open event for Nix's
  own `.qutebrowser-wrapped` Python entry script. An isolated app launch was
  verified to open the normal homepage without that extra script tab. Quit and
  reopen an already-running older instance to use the patched package.
  Home Manager sets the native Spotlight shortcut to Option+Space, updating
  only symbolic hotkey 64. The original shortcut preferences are backed up once
  at `~/.local/state/macos-shortcuts/before-option-space.plist`. To revert, remove
  the `spotlightShortcut` activation from `macos.nix` and set **Keyboard → Keyboard
  Shortcuts → Spotlight → Show Spotlight search** back to Command+Space.
  Its Homebrew cask is disabled, so it is intentionally omitted from the Brewfile.
- MCPJungle listens on `127.0.0.1:37373`: systemd on Linux, launchd on Mac.
  Mac logs are in `~/.local/share/mcpjungle/`.
- MPD keeps the same music directory and client workflow, using PulseAudio on
  Linux and CoreAudio on Mac. Home Manager manages its platform service.
- Codex CLI and Codex ACP keep the same pinned versions with architecture-specific
  packages. Their authentication/session data is not migrated automatically.
- Fcitx5 stays Linux-only. Enable Vietnamese input in macOS Keyboard settings.
- On the built-in keyboard, Globe acts as Command and Control stays Control.
  Home Manager writes the same table as System Settings > Keyboard > Modifier
  Keys (`com.apple.keyboard.modifiermapping.0-0-0` in the current-host global
  domain), together with Caps Lock → Escape. Inside Raycast, a Hammerspoon rule
  (`~/.hammerspoon/init.lua`, generated by `macos.nix`) turns Command+N/P into
  Down/Up, so Globe+N/P moves the list. Hammerspoon comes from the Brewfile and
  needs Accessibility permission. To undo, remove `keyboardModifiers` and
  `hammerspoonConfig` from `macos.nix` and reset the keys in System Settings >
  Keyboard > Keyboard Shortcuts > Modifier Keys.

  This keyboard had no `UserKeyMapping` before the swap. Its native modifier
  preferences are separate and are not overwritten by the commands above.
- Figma Linux Next becomes native Figma; WebCord becomes Discord; screenshots
  use Nix-provided Flameshot through Option+Shift+S. Wine and qBittorrent are retained on Linux and omitted
  from the Mac setup, as requested; no Mac torrent client or Windows runtime is installed.
- Home Manager installs the Tailscale CLI and daemon from Nixpkgs. The native
  menu bar app and its managed VPN service are not included.

## Docker on macOS

For the Apple Silicon Docker runtime and `tiemdosime-bot` workflow, see
[Docker with Colima](docs/docker-colima.md). Home Manager installs the CLI and
plugins and starts Colima at login; no Docker Desktop or Homebrew service is needed.

## CodeGraph

[CodeGraph setup and validation](docs/codegraph.md) covers the pinned standalone
runtime, Codex MCP integration, index backups, upgrades and rollback on both targets.

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
Mise uses Node 24 globally, currently 24.16.0. Older Node releases should be
declared in the projects that need them; the Context Mode activation uses Nix's
Node 24 package to match mise's global Node major version.

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
