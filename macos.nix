{ pkgs, lib, config, zoteroFirefox, ... }:
let
  mcpjungle = pkgs.callPackage ./mcpjungle.nix { };
  tunnelClient = pkgs.callPackage ./tunnel-client-package.nix { };
  # Match Zotero 10.0.4's Gecko runtime; ESR 153 changed actor modules expected by its patch script.
  zotero = pkgs.zotero.override {
    firefox-esr-153-unwrapped = zoteroFirefox;
  };
  gatewayDir = "${config.xdg.dataHome}/mcpjungle";
  # The Nixpkgs Anki package assigns its app version (26.08) to this helper,
  # while the helper's pyproject metadata is version 0.1.1.
  ankiPython = pkgs.python3.override {
    packageOverrides = _final: prev: {
      anki-mac-helper = prev.anki-mac-helper.overridePythonAttrs (_: {
        version = "0.1.1";
      });
    };
  };
  anki = pkgs.anki.override { python3 = ankiPython; };
  # Same table as System Settings > Keyboard > Modifier Keys. Usages: Control
  # 0x7000000e0, Command 0x7000000e3 and 0x7000000e7, Caps Lock 0x700000039,
  # Escape 0x700000029, Globe/Fn 0xff00000003 and 0xff0000000003.
  modifierMap = src: dst: ''<dict><key>HIDKeyboardModifierMappingSrc</key><integer>${toString src}</integer><key>HIDKeyboardModifierMappingDst</key><integer>${toString dst}</integer></dict>'';
  modifierMappings = [
    (modifierMap 30064771300 30064771300)
    (modifierMap 30064771299 30064771299)
    (modifierMap 30064771129 30064771113) # Caps Lock -> Escape
    (modifierMap 30064771296 30064771296)
    (modifierMap 280379760050179 30064771299) # Globe -> Command
    (modifierMap 1095216660483 30064771303) # Globe -> Command
    (modifierMap 30064771303 30064771303)
  ];
  # Globe acts as Command; inside Raycast, Command+N/P move the list down/up.
  hammerspoonConfig = ''
    hs.autoLaunch(true)
    hs.menuIcon(false)
    require("hs.ipc")

    -- Globe is mapped to Command; use the native input-source shortcut.
    inputSourceShortcut = hs.hotkey.bind({ "cmd" }, "space", function()
      hs.eventtap.keyStroke({ "ctrl" }, "space", 0)
    end)

    local raycast = "com.raycast.macos"
    local keys = { [hs.keycodes.map["n"]] = "down", [hs.keycodes.map["p"]] = "up" }

    local function raycastFocused()
      local app = hs.application.frontmostApplication()
      if app and app:bundleID() == raycast then return true end
      -- Raycast's panel takes key focus without becoming the frontmost app.
      local win = hs.window.focusedWindow()
      local winApp = win and win:application()
      return winApp ~= nil and winApp:bundleID() == raycast
    end

    raycastListKeys = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
      local flags = event:getFlags()
      local arrow = keys[event:getKeyCode()]
      if arrow and flags.cmd and not (flags.ctrl or flags.alt or flags.shift)
          and raycastFocused() then
        hs.eventtap.keyStroke({}, arrow, 0)
        return true
      end
      return false
    end):start()

    -- Globe is Command everywhere else; inside the League game client it is Control.
    local leagueGame = "com.riotgames.LeagueofLegends.GameClient"
    globeAsControlInLeague = hs.eventtap.new({
      hs.eventtap.event.types.keyDown,
      hs.eventtap.event.types.keyUp,
      hs.eventtap.event.types.flagsChanged,
    }, function(event)
      local app = hs.application.frontmostApplication()
      if not (app and app:bundleID() == leagueGame) then return false end
      local flags = event:getFlags()
      if not flags.cmd then return false end
      flags.cmd = nil
      flags.ctrl = true
      event:setFlags(flags)
      return false
    end):start()

  '';
  qutebrowser = pkgs.qutebrowser.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # Cocoa replays the Python entry script as a file-open event at startup.
      # Ignore only our own launcher; keep normal Finder file/URL handling.
      substituteInPlace qutebrowser/app.py --replace-fail \
        '        url = e.url()' \
        '        url = e.url()
        if (sys.platform == "darwin" and url.isLocalFile()
                and url.toLocalFile() == os.path.join(
                    os.path.dirname(sys.argv[0]), ".qutebrowser-wrapped")):
            return True
'
    '';
    # Nixpkgs' generated .app bundle omits the URL schemes from qutebrowser's
    # desktop entry, so macOS does not offer it as a default browser.
    postFixup = (old.postFixup or "") + ''
      appInfo="$out/Applications/qutebrowser.app/Contents/Info.plist"
      /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$appInfo"
      /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$appInfo"
      /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLName string Web site URL" "$appInfo"
      /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$appInfo"
      /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string http" "$appInfo"
      /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:1 string https" "$appInfo"
    '';
  });
in {
  imports = [ ./aerospace.nix ./colima.nix ];

  # Real app bundles let Spotlight discover Nix applications through macOS indexing.
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;

  # Home Manager copies native app bundles into its user Applications folder.
  programs.kitty.package = pkgs.kitty;
  programs.kitty.settings = {
    background_blur = 64;
    hide_window_decorations = "titlebar-only";
    # Keep repaint scheduling below a 120 Hz frame interval; this is not an FPS cap.
    repaint_delay = 2;
    sync_to_monitor = true;
  };
  home.file.".hammerspoon/init.lua".text = hammerspoonConfig;
  home.file.".qutebrowser".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.config/qutebrowser";
  home.file.".config/qutebrowser/userscripts".source =
    config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.local/share/qutebrowser/userscripts";
  home.file.".config/qutebrowser/greasemonkey".source =
    config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.local/share/qutebrowser/greasemonkey";

  home.sessionPath = [
    "/opt/homebrew/bin"
    "/usr/local/bin"
  ];
  # Keep apps with aarch64-darwin packages under Home Manager.
  home.packages = [
    qutebrowser
    anki
    pkgs.chatgpt
    pkgs.discord
    pkgs.flameshot
    pkgs.google-chrome
    pkgs.pngpaste
    pkgs.stats
    pkgs.tailscale
    zotero
  ];

  # Show RAM usage and memory pressure in the menu bar.
  home.activation.statsMenuBar =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      run /usr/bin/defaults write eu.exelban.Stats CPU_state -bool false
      run /usr/bin/defaults write eu.exelban.Stats RAM_state -bool true
      run /usr/bin/defaults write eu.exelban.Stats RAM_widget -string mini
      # The Nix-managed app cannot use Stats' DMG self-updater. Update it via Nix.
      run /usr/bin/defaults write eu.exelban.Stats update-interval -string Never
    '' // { before = [ "setupLaunchAgents" ]; };

  home.activation.keyboardModifiers =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      run /usr/bin/defaults -currentHost write -g \
        com.apple.keyboard.modifiermapping.0-0-0 -array \
        ${lib.escapeShellArgs modifierMappings}
      run /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

  # Write only these keys so Dock contents and other preferences stay intact.
  # A very long autohide-delay stops the Dock from appearing on hover.
  home.activation.dockAutohide =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      dockChanged=0
      if [ "$(/usr/bin/defaults read com.apple.dock autohide 2>/dev/null || true)" != "1" ]; then
        run /usr/bin/defaults write com.apple.dock autohide -bool true
        dockChanged=1
      fi
      if [ "$(/usr/bin/defaults read com.apple.dock autohide-delay 2>/dev/null || true)" != "86400" ]; then
        run /usr/bin/defaults write com.apple.dock autohide-delay -float 86400
        dockChanged=1
      fi
      if [ "$dockChanged" = 1 ]; then
        run /usr/bin/killall Dock || true
      fi
    '';

  # Disable only Spotlight's Option+Space entry so Raycast can use that hotkey;
  # importing a partial dictionary would replace unrelated system shortcuts.
  # Option = 524288; space has virtual keycode 49.
  home.activation.spotlightShortcut =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      shortcutBackupDir=${lib.escapeShellArg "${config.xdg.stateHome}/macos-shortcuts"}
      run mkdir -p "$shortcutBackupDir"
      if [ ! -e "$shortcutBackupDir/before-option-space.plist" ]; then
        run /usr/bin/defaults export com.apple.symbolichotkeys \
          "$shortcutBackupDir/before-option-space.plist"
      fi
      run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
        -dict-add 64 '<dict><key>enabled</key><false/><key>value</key><dict><key>type</key><string>standard</string><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>524288</integer></array></dict></dict>'
      run /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

  home.activation.serviceDirectories =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${
        lib.escapeShellArgs [
          gatewayDir
          config.services.mpd.playlistDirectory
          config.services.mpd.musicDirectory
        ]
      }
    '';
  launchd.agents.stats = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/open"
        "-a"
        "${pkgs.stats}/Applications/Stats.app"
      ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };
  launchd.agents.mcpjungle = {
    enable = true;
    config = {
      ProgramArguments = [
        "${mcpjungle}/bin/mcpjungle"
        "start"
        "--host"
        "127.0.0.1"
        "--port"
        "37373"
        "--sqlite-db-path"
        "${gatewayDir}/mcpjungle.db"
      ];
      EnvironmentVariables.PATH =
        "${config.home.profileDirectory}/bin:${config.home.homeDirectory}/.local/bin:${pkgs.nodejs_22}/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 2;
      StandardOutPath = "${gatewayDir}/stdout.log";
      StandardErrorPath = "${gatewayDir}/stderr.log";
    };
  };
  launchd.agents.tunnel-client = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/bash"
        "-c"
        "set -a; . ${config.home.homeDirectory}/.config/home-manager/secrets/secrets.env; exec ${tunnelClient}/bin/tunnel-client run --profile mcpjungle"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 5;
      StandardOutPath = "${gatewayDir}/tunnel-client.stdout.log";
      StandardErrorPath = "${gatewayDir}/tunnel-client.stderr.log";
    };
  };
}
