# Codex handoff: Regolith-like tiling on an M5 Pro MacBook

## Task

Implement an AeroSpace desktop setup on my MacBook M5 Pro, managed by my existing Nix Home Manager flake. Reproduce my Regolith/i3 keyboard workflow as closely as practical. Finish the configuration, build and apply it, and verify what you can on the Mac. This document is the implementation brief; do not stop after proposing a plan.

Use the smallest complete change. Keep all Linux configuration working. Do not install another window manager or build a custom window-management framework.

## Existing configuration and verified Linux baseline

The source inspected when writing this brief was `~/.config/home-manager` on Linux. Its current `flake.nix` already defines:

- `homeConfigurations."neo@main"`: `x86_64-linux`.
- `homeConfigurations."neo@mac"`: `aarch64-darwin`.
- A shared `mkHome` function and a platform-selected `macos.nix` module.
- Platform-dependent home directories; do not copy `/home/neo` paths to macOS.

The current `macos.nix` already contains macOS package choices and a Home Manager launchd agent for MCPJungle. Preserve these. Discover the actual checkout, username, flake target and activation command on the Mac rather than assuming this snapshot is still exact.

The inspected Linux desktop runs Regolith with i3 4.22. Its baseline is:

- Super modifier; Vim directions H/J/K/L and arrow alternatives.
- Shift plus directions moves windows.
- Workspaces 1–10, with 0 selecting 10; Ctrl plus digits 1–9 selects 11–19.
- Shift plus the workspace combination sends a window without following.
- Super+Tab / Super+Shift+Tab selects the next / previous workspace.
- Super+G / Super+V selects horizontal / vertical split.
- Super+Backspace toggles split orientation.
- Super+D toggles fullscreen; Super+Shift+F toggles floating.
- Super+T cycles tabbed, horizontal split and vertical split.
- Super+R enters resize mode, Escape or Return exits.
- Super+W closes a window; Super+Shift+C reloads configuration.
- Super+Ctrl+Shift plus directions moves a workspace between monitors.
- Parent/child focus and scratchpad bindings exist; these may have no direct equivalent.
- Inner gaps 6, outer gaps 0, keyboard-driven focus, Gruvbox theme.
- Laptop display 1920×1200 and a right-hand portrait display 1200×1920; workspaces 1 and 2 were on the laptop and 3 on the external monitor.
- Local overrides add Flameshot and GNOME Night Light shortcuts. These are Linux-specific and are outside this implementation.

This is a reference workflow, not a requirement to replicate Linux screen resolutions or assume the same monitor is attached to the Mac.

## Nix ownership and integration

1. Read the checkout's instructions, dirty status, flake, macOS module and pinned Home Manager/AeroSpace implementations before editing. Use existing structure and preserve unrelated changes.
2. Extend the existing macOS module. If its size warrants separation, add one focused `aerospace.nix` imported only by the macOS module. No new flake or nix-darwin migration.
3. Use the pinned Home Manager `programs.aerospace` module with its Nix package, declarative settings and launchd support. Current upstream names are `enable`, `package`, `settings`, and `launchd.enable`; verify these against the locked revision.
4. Home Manager must own package installation, TOML generation and exactly one user login service. Do not install AeroSpace using Homebrew, manually edit generated TOML, or also enable a nix-darwin AeroSpace service.
5. Enable the Home Manager launchd service. Leave AeroSpace's own `start-at-login` disabled; do not create a second login item. Prefer the built-in module over a custom LaunchAgent.
6. Ensure the Nix-provided app and CLI are accessible through the existing macOS app-link/profile conventions. Verify the app executable actually used by launchd, not just a convenient copy in `/Applications`.
7. Choose one config location according to the Home Manager module and existing XDG settings. Check both `~/.aerospace.toml` and the XDG AeroSpace config for conflicts. Back up existing unmanaged files before migrating them; do not overwrite blindly.
8. Do not change `home.stateVersion`, update all flake inputs, introduce Rosetta, or refactor shared modules for this task. If a pinned module/package is insufficient, explain the concrete incompatibility and make only the smallest necessary dependency change.
9. Keep all AeroSpace evaluation and launchd settings Darwin-only. Linux must not evaluate an unsupported Darwin package.

## Window behavior

- Use tiles by default with orientation determined by display aspect ratio.
- Set inner horizontal and vertical gaps to 6 and all outer gaps to 0. These are macOS logical units; visually check the result rather than treating them as physical Retina pixels.
- Keep focus-follows-mouse off. Preserve native Command shortcuts for editing and normal app behavior.
- Use the installed version's documented i3-style split configuration. If its i3 example disables tree normalization to make pending splits work, follow that example; verify horizontal/vertical splitting with a newly opened window.
- Provide floating mode for windows that need it. Retain built-in dialog heuristics; add app exceptions only for problems observed during verification.
- Do not impose app-to-workspace assignments that were not requested.
- Use AeroSpace's own fullscreen command so the window remains in its workspace; do not substitute macOS native fullscreen, which creates a native Space.

## Keybindings

Use Option (`alt` in AeroSpace) as the primary modifier. This preserves Command for Mac apps. Explicitly define all required bindings: custom binding tables do not inherit omitted default bindings.

| Shortcut | Required action |
| --- | --- |
| Option+H/J/K/L and Option+arrows | Focus left/down/up/right |
| Option+Shift+H/J/K/L and Option+Shift+arrows | Move window in that direction |
| Option+1…9 / Option+0 | Select workspace 1…9 / 10 |
| Option+Shift+1…9 / Option+Shift+0 | Send window to workspace without following |
| Option+Ctrl+1…9 | Select workspace 11…19 |
| Option+Ctrl+Shift+1…9 | Send window to workspace 11…19 without following |
| Option+Tab / Option+Shift+Tab | Next / previous workspace; do not substitute back-and-forth |
| Option+G / Option+V | Horizontal / vertical split for the next window |
| Option+Backspace | Toggle horizontal/vertical split orientation |
| Option+D | Toggle AeroSpace fullscreen |
| Option+Shift+F | Toggle floating/tiling |
| Option+T | Cycle horizontal accordion, horizontal tiles, vertical tiles |
| Option+R | Enter resize mode |
| Option+W | Close focused window normally, without force-killing the app |
| Option+Shift+C | Reload configuration |
| Option+Return | Open a new terminal window |
| Option+Ctrl+Shift+directions, both Vim and arrows | Move current workspace to the monitor in that direction |

Use documented commands supported by the installed version. Prefer native command sequences over scripts. Keep next/previous workspace order numerical across 1–19; explicitly enumerate the order if the installed version would otherwise sort names lexically. Persist these numbered workspaces if supported by the installed version.

For resize mode, preserve the Linux controls:

- Left/H shrinks width, Right/L grows width.
- Up shrinks height, Down grows height.
- K grows height, J shrinks height, matching the inspected Regolith Vim bindings.
- Normal step 6, Shift step 24, using the installed AeroSpace resize command's units.
- Escape, Return and Option+R return to main mode.

Reuse the terminal already configured on the Mac. Prefer Kitty if present in the existing setup; otherwise use Terminal.app. A launch must create a new window on the current workspace, not merely activate an existing window elsewhere. Resolve executable paths explicitly for GUI/launchd execution; do not rely on interactive shell initialization or a Linux terminal command.

If a requested action is unsupported, document the exact gap and nearest built-in alternative. In particular:

- Accordion is a substitute for tabbed/stacked layouts, not an identical tab bar.
- Do not fake parent/child container selection with unrelated directional focus.
- Do not label a dedicated workspace as a true scratchpad. Leave scratchpad unmapped if there is no native equivalent; document it rather than adding a stateful shell service.
- The Linux move-and-follow workspace chord used a second modifier. It is not required in this first version because reusing Option changes that modifier relationship.

Check shortcut conflicts with macOS, existing keyboard tools, keyboard layout and terminal Option behavior. Avoid silently changing input sources or global Command bindings. If Option affects an actively used input method, report the conflict and settle a replacement modifier with me.

## Displays and macOS behavior

Make laptop-only operation work first. Then inspect connected displays using the installed AeroSpace CLI.

- If the portrait external display is present, assign workspace 3 to its actual stable identity and workspaces 1–2 to the built-in display. Use documented monitor matching and a built-in/available-display fallback when the external display is absent.
- If the external display is absent, do not invent a monitor name or force all workspaces to one monitor. Leave assignment to AeroSpace and document the optional follow-up once the monitor is connected.
- Other workspaces should remain movable; do not force-pin all 19 workspaces.
- Verify docking/undocking and that windows on disconnected displays remain reachable. Do not promise automatic restoration of manual layouts unless tested.
- Keep display arrangement compatible with AeroSpace's off-screen workspace hiding. Inspect for hidden windows appearing on the neighboring display.
- Explain that AeroSpace workspaces are independent of native macOS Spaces. Use one native Space per display for this workflow; preserve pre-existing Spaces rather than deleting them.
- Inspect Stage Manager and competing window managers. Avoid running two tilers; preserve their config and provide a reversible way to stop the competing process. Do not uninstall unrelated apps.
- Inspect `Displays have separate Spaces`. Do not automatically flip it: disabling it can improve AeroSpace behavior but changes native fullscreen behavior on multiple monitors. Document the tradeoff and change it only after a concrete choice from me if needed.
- Leave the menu bar visible and usable around the MacBook notch. Custom bars, borders and Gruvbox styling are deferred.

## Installation and human steps

Use the existing Nix installation and activation workflow. If Nix is absent, report that prerequisite before making machine-wide installer changes. No Homebrew fallback for AeroSpace.

Accessibility and background-item permissions may need manual interaction. Identify the exact Nix app/service requesting permission and tell me the shortest UI steps. Do not attempt to write the TCC database or bypass macOS permission controls. Keep SIP enabled.

If permissions block GUI validation, finish the build, config, activation instructions and rollback notes first. Mark live checks pending and resume them after permission is granted. An evaluation success alone is not a working desktop.

## Verification and acceptance

Use targeted checks and existing repository tooling; no new testing framework.

1. Record versions, selected flake target, actual changed files, prior config backups, and previous Home Manager generation.
2. Evaluate and build the Mac activation package on the Mac using its actual flake selector. Example only: `home-manager build --flake '.#neo@mac'`. Use the repository's existing Git/submodule flake reference if required. Include new files in the flake source using the repository's established workflow.
3. Check that the Linux target still evaluates with the platform boundary intact; do not try to build Darwin GUI packages on Linux or require a full Linux rebuild on the Mac.
4. Apply with the existing Home Manager switch command. Validate generated TOML using AeroSpace's own config-loading/reload mechanism. Do not assume a generic TOML parser supports the syntax version AeroSpace uses.
5. Verify exactly one AeroSpace process and one owning login service; inspect launchd status and errors. Confirm executable/config ownership comes from Nix/Home Manager.
6. With disposable windows, test focus, movement, both split directions, layout cycling, float/fullscreen toggles, resize mode exit, and normal close. Do not close existing work or force-quit apps for testing.
7. Verify workspace 10 via 0, workspace 11 and 19 via Ctrl combinations, send-without-follow, and next/previous numerical order. Confirm a newly opened terminal lands on the current workspace.
8. Verify 6-unit gaps, zero configured outer gaps, keyboard focus, native Command shortcuts, and dialogs.
9. If attached, test landscape/portrait placement and moving a workspace between monitors. Test disconnect/reconnect only with my participation; do not claim this passed from config inspection.
10. Apply again to confirm idempotence. Check login persistence at the next user-assisted logout/login; do not log me out automatically.

Record each acceptance item as passed, failed, or pending with a reason. Fix failures within this scope before finishing. Runtime checks requiring missing hardware or macOS permissions stay explicitly pending.

## Rollback and deliverables

Deliver the minimal Nix diff plus a short README section containing:

- Exact build, switch, reload, and service-inspection commands for this machine.
- A compact keybinding reference and known i3 differences.
- Permission steps, monitor follow-up, and acceptance results.
- An emergency procedure that stops the owning launchd service before quitting AeroSpace, so KeepAlive does not restart it. Verify the installed version's normal exit restores hidden windows; otherwise document recovery without killing other apps.
- Exact restoration steps using the recorded previous Home Manager generation and unmanaged config backups. Restore changed macOS settings from recorded prior values. Do not remove Home Manager or Nix to undo one window manager.

Do not commit, push, install SketchyBar/Raycast/Karabiner/yabai, change Night Shift/screenshots, or migrate the entire desktop theme as part of this task.

## References and version policy

Checked on 2026-10-16. The pinned module and installed app are authoritative at implementation time; current online examples can be newer than the lockfile.

- Home Manager AeroSpace module: https://github.com/nix-community/home-manager/blob/master/modules/programs/aerospace.nix
- AeroSpace setup, configuration, layouts, monitors and workspace model: https://nikitabobko.github.io/AeroSpace/guide
- AeroSpace command reference: https://nikitabobko.github.io/AeroSpace/commands
- AeroSpace project/status: https://github.com/nikitabobko/AeroSpace

This handoff was written from Linux. No Mac package build, macOS activation, permission grant or physical display test has been performed yet.
