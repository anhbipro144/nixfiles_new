{ pkgs, config, nixgl, zenBrowser, ... }: {
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
    # zotero temporarily removed: current nixpkgs pin's firefox-esr-153-unwrapped
    # source no longer matches what Zotero 10.0.4's build script expects when it
    # patches modules/ActorManagerParent.sys.mjs ("AboutTranslations: \{ and ^  },
    # not found ... -- aborting"). Upstream nixpkgs/Zotero packaging incompatibility,
    # re-add once fixed upstream.
    (config.lib.nixGL.wrap kid3)
    vlc
    postman
    libsecret
    tailscale
  ];
}
