# Handoff: Linux and M5 Mac Home Manager configuration

Updated: 2026-10-14

## Goal and user preferences

Maintain one configuration repository for Linux and macOS. Preserve capabilities
and familiar workflows, using suitable native replacements where tools differ.
The user explicitly does **not** need Wine or qBittorrent on macOS; do not add
Transmission, Porting Kit or other replacements for those capabilities.

Mac hardware: 14.2-inch MacBook Pro, M5, 10-core CPU / 10-core GPU, 32GB RAM,
1TB SSD. The user called it “M5 Pro,” but Apple's specification page lists that
10/10 combination under the M5 chip. Both chip families use `aarch64-darwin`.
Reference: https://www.apple.com/vn/macbook-pro/specs/

## Repository and state

- Home Manager root: `/home/neo/.config/home-manager`.
- Neovim is a separate Git submodule at `nvim/`; current agent workspace is there.
- Implementation is present as uncommitted changes. No commit or push was made.
- The new config files were registered with `git add --intent-to-add` so Git flakes
  can see them. The Zotero fix adds a compatibility input to `flake.lock`;
  the existing input pins were preserved.
- Home Manager has not been activated. Full Linux and native Mac builds have not run.
- Read `README.md` at the Home Manager root for installation details.

## Implemented structure

| Target | System | Default home |
| --- | --- | --- |
| `neo@main` | `x86_64-linux` | `/home/neo` |
| `neo@mac` | `aarch64-darwin` | `/Users/neo` |

The actual Mac username remains unknown. Set `username = "actual-name";` in the
Mac target in `flake.nix` if it differs from `neo`. The target name can stay unchanged.
There is no Intel Mac target; the current unstable package pin needs a separate
compatible pin to support Intel Darwin.

- `flake.nix`: constructs each target with its architecture, username, home,
  Neovim package set and platform modules. Linux-only inputs are selected lazily.
- `base.nix`: retains the existing Home Manager state version, `25.05`.
- `common.nix`, `main.nix`, `packages.nix`, `files.nix`: shared shell, editor,
  development tools, application settings and userscripts.
- `linux.nix`: NixGL, Fcitx5, Linux GUI packages and MCPJungle systemd service;
  imports the existing `desktop.nix` MIME/desktop integrations.
- `macos.nix`: MCPJungle launchd service, service directories, native app paths
  and qutebrowser integration. MPD's shared module uses CoreAudio on Mac and
  PulseAudio on Linux, with socket activation confined to Linux.
- `platform-tools.nix`: real script commands `clipboard-copy`, `clipboard-paste`,
  `desktop-open` and `qute-menu`. Linux uses xclip/wl-clipboard, xdg-open and rofi;
  Mac uses pbcopy/pbpaste, open and AppleScript dialogs.
- `scripts/macos-menu.py`: native prompts/list selection; passes user values as
  osascript arguments rather than interpolating them into executable code.
- `scripts/test_macos_menu.py`: three mocked tests for selection, cancellation
  and error handling.
- `codex-acp/flake.nix` and `mcpjungle.nix`: pinned Linux and Apple Silicon
  packages with architecture-specific upstream archives and hashes.

## macOS applications

The Brewfile contains 14 enabled casks: Kitty, Chrome, Zen, Discord, LibreOffice,
Anki, Zotero, Kid3, VLC, Postman, Figma, Tailscale, UniClipboard and Fira Code Nerd Font.

Homebrew has disabled its qutebrowser, qBittorrent and Wine casks. qutebrowser is
installed through the supported ARM64 Nix package instead; it provides both the
CLI and a Mac app bundle linked under `~/Applications/Home Manager Apps`.
Wine/qBittorrent and their suggested Mac replacements are omitted by user request.
Linux keeps its original Wine and enhanced qBittorrent packages.

Kitty settings stay shared, but its Mac remote-control listener uses a filesystem
socket. qutebrowser keeps password filling and translation userscripts with native
Mac dialogs and config-directory links. UniClipboard has a native Mac app, so
clipboard history/sync is retained separately from the terminal clipboard helpers.

## Linux Zotero restored

Zotero 10.0.4 requires Firefox ESR 140.15.0 in its `app/config.sh`, but the
main Nixpkgs pin supplies ESR 153, causing its runtime patching step to fail.
`flake.nix` now has a separate `nixpkgs-zotero` input pinned to
`eaad089433ca2bb662274377d33df3d0e51ef28b`, providing the matching ESR 140.15.0.
`linux.nix` overrides only Zotero's Firefox runtime and restores the NixGL-wrapped
package. This compatibility pin is independent of the Neovim pin; revisit it when
upstream Nixpkgs fixes Zotero's runtime dependency. macOS retains its Brewfile cask.

The targeted Zotero build, including its NixGL wrapper, passed. Its executable
responds to `--version`. Full graphical startup and Home Manager activation have
not been performed. Run `hms` to activate the Linux configuration.

## Neovim and portable paths

Changed these Neovim files:

- `lua/kickstart/agents.lua`
- `lua/kickstart/plugins/lsp.lua`
- `lua/kickstart/plugins/overseer.lua`
- `lua/kickstart/plugins/jillra.lua`
- `lua/kickstart/plugins/dap.lua`

Active home paths now derive from the user's home directory. Tools such as mise,
clangd and database proxies use executable lookup. Chrome debugging selects the
native Mac Chrome executable and avoids Linux Wayland flags on Mac. Kitty's
active scrollback command uses `~`; qutebrowser URL rules use its data directory.
An obsolete commented Kitty example still contains `/home/neo` and is inactive.

## Validation completed

- Both targets evaluate successfully through the existing Git flake URL with
  `submodules=1`.
- The full Mac derivation graph has **5,851 recipes**: 5,849 `aarch64-darwin` and
  two builtin fetchers. No Linux or Intel build recipes were found.
- All explicitly installed Mac Nix packages advertise support for the platform;
  none was marked broken at review time.
- All 14 remaining Homebrew casks were checked for disabled/deprecated status and
  declared ARM restrictions; none failed those checks.
- Node 22.14.0, Node 24 and Node 18.16.0 upstream releases provide native
  `darwin-arm64` binaries. Node 18 is retained for existing projects, with runtime
  behavior on current macOS still unverified.
- Four Linux helper derivations built successfully.
- Three native-menu tests passed; changed Lua files parsed in headless Neovim;
  changed Python files compiled; Nix formatting and scoped diff checks passed.
- Final Git source snapshots were confirmed to exclude `secrets/secrets.env`.

These checks do not prove native Mac builds or runtime behavior. The graph audit
finished successfully; its combined command timed out during subsequent checks,
which were then completed separately.

## Existing unrelated work to preserve

Before this migration, Neovim already had modifications in
`lua/kickstart/plugins/codecompanion.lua` and `patches/codecompanion.nvim.patch`.
The parent also had an untracked `mcpjungle/` directory. Do not discard, stage or
rewrite those as part of this task. The full Neovim diff check reports trailing
whitespace in the pre-existing CodeCompanion patch; checks scoped to this task pass.

## Next steps on the actual Mac

1. Confirm the Mac username and macOS version. Use a native terminal where
   `uname -m` returns `arm64`; Homebrew should use `/opt/homebrew`.
2. Install Apple Command Line Tools, Nix with flakes, Home Manager and Homebrew.
3. Transfer/clone the reviewed repository and its submodules into
   `~/.config/home-manager`. Include the new files and Neovim changes when publishing
   the work; intent-to-add alone is not a commit.
4. Run `brew bundle --file "$HOME/.config/home-manager/Brewfile"`.
5. Build the Mac target before switching:

   ```sh
   home-manager build --flake "git+file://$HOME/.config/home-manager?submodules=1#neo@mac"
   ```

6. Follow the README's backup-enabled activation command when ready. Verify
   clipboard copy/paste, Kitty scrollback, Neovim LSP/debugging, qutebrowser password
   filling and translations, MPD audio, MCPJungle, and UniClipboard pairing.

Citrix Secure Access requires the company's approved Mac installer. Citrix
Workspace is a different product and was not substituted. The Linux LibreOffice
MCP runtime/profile is not portable; install and verify the extension with native
LibreOffice. Transfer secrets, GPG/pass data and authentication separately. Clone
personal work repositories and the local jillra plugin, and recreate virtualenvs.

## Secret handling during future validation

Use **Git flake URLs**, not `path:` URLs to the live repository. Early path-based
validation copied the ignored secrets file into six temporary Nix source snapshots;
those unrooted, unreferenced snapshots were deleted. Later validation used a clean
temporary copy and Git sources, which excluded the local secrets file. Do not
print secrets, commit them or reintroduce them into source snapshots.
