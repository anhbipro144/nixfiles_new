{ pkgs, config, lib, nixgl, zenBrowser, zoteroFirefox, ... }:
let
  tunnelClient = pkgs.callPackage ./tunnel-client-package.nix { };
in {
  imports = [ ./desktop.nix ];


  targets.genericLinux = {
    enable = true;
    nixGL = {
      packages = nixgl.packages.${pkgs.stdenv.hostPlatform.system};
      defaultWrapper = "mesa";
    };
  };

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.addons = with pkgs; [ qt6Packages.fcitx5-unikey fcitx5-gtk ];
  };

  # Reserve Super+Space and Super+Shift+Space for Regolith's launchers.
  dconf.settings."org/gnome/desktop/wm/keybindings" = {
    switch-input-source = [ "XF86Keyboard" ];
    switch-input-source-backward = [ "<Shift>XF86Keyboard" ];
  };

  # Keep Fcitx's other user preferences editable.
  home.activation.clearFcitxLauncherShortcuts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "${config.xdg.configHome}/fcitx5/config" ]; then
      run ${pkgs.gnused}/bin/sed -i \
        -e '/^\[Hotkey\/EnumerateGroupForwardKeys\]$/,/^\[/ { /^0=Super+space$/d; }' \
        -e '/^\[Hotkey\/EnumerateGroupBackwardKeys\]$/,/^\[/ { /^0=Shift+Super+space$/d; }' \
        "${config.xdg.configHome}/fcitx5/config"
    fi
  '';

  home.sessionVariables = {
    GLFW_IM_MODULE = "ibus";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  # GNOME launches the configured terminal through systemd-run --user.
  systemd.user.sessionVariables = {
    GLFW_IM_MODULE = "ibus";
    inherit (config.home.sessionVariables)
      HINDSIGHT_API_LLM_PROVIDER HINDSIGHT_API_LLM_MODEL
      HINDSIGHT_API_RETAIN_LLM_MODEL HINDSIGHT_API_RETAIN_LLM_REASONING_EFFORT
      HINDSIGHT_API_CONSOLIDATION_LLM_MODEL
      HINDSIGHT_API_CONSOLIDATION_LLM_REASONING_EFFORT;
  };

  systemd.user.services.hindsight = {
    Unit = {
      Description = "Hindsight memory backend";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.uv}/bin/uvx --from hindsight-api==1.1.0 hindsight-api --host 127.0.0.1 --idle-timeout 0 --port 9077";
      EnvironmentFile = "%h/.hindsight/profiles/coding-agent.env";
      Environment = [
        "HF_HUB_OFFLINE=1"
        "HINDSIGHT_API_DATABASE_URL=pg0://hindsight-embed-coding-agent"
        "PATH=${lib.makeBinPath [ pkgs.nodejs_24 pkgs.git pkgs.coreutils ]}:%h/.local/bin:%h/.nix-profile/bin:/usr/bin:/bin"
      ];
      Restart = "always";
      RestartSec = 5;
      TimeoutStopSec = 120;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.mcpjungle = {
    Unit = {
      Description = "MCPJungle Streamable HTTP gateway";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/.local/share/mcpjungle";
      ExecStart = "${
          pkgs.callPackage ./mcpjungle.nix { }
        }/bin/mcpjungle start --host 127.0.0.1 --port 37373 --sqlite-db-path %h/.local/share/mcpjungle/mcpjungle.db";
      Environment = [
        "PATH=%h/.local/bin:${pkgs.nodejs_22}/bin:%h/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      ];
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.tunnel-client = {
    Unit = {
      Description = "OpenAI MCP tunnel-client";
      After = [ "network-online.target" "mcpjungle.service" ];
      Wants = [ "network-online.target" "mcpjungle.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.bash}/bin/bash -c 'set -a; . %h/.config/home-manager/secrets/secrets.env; exec ${tunnelClient}/bin/tunnel-client run --profile mcpjungle'";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  programs.kitty.package = config.lib.nixGL.wrap pkgs.kitty;
  home.packages = with pkgs; [
    flameshot
    xclip
    rofi
    wine64
    zenBrowser
    (config.lib.nixGL.wrap google-chrome)
    (config.lib.nixGL.wrap qutebrowser)
    webcord
    qbittorrent-enhanced
    (config.lib.nixGL.wrap libreoffice-qt-stable)
    (config.lib.nixGL.wrap anki-bin)
    # shortcut: use ESR 140 until nixpkgs fixes Zotero's runtime dependency.
    (config.lib.nixGL.wrap (zotero.override {
      firefox-esr-153-unwrapped = zoteroFirefox;
    }))
    (config.lib.nixGL.wrap kid3)
    vlc
    postman
    libsecret
    tailscale
  ];
}
