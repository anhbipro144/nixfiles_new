{ pkgs, config, nixgl, ... }:

let nixglPkgs = nixgl.packages.${pkgs.stdenv.hostPlatform.system};
in {

  targets.genericLinux.nixGL = {
    packages = nixglPkgs;
    defaultWrapper = "mesa";
  };

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.addons = with pkgs; [ qt6Packages.fcitx5-unikey fcitx5-gtk ];
  };

  # This fcitx5 autostart works for GNOME, should check if switch to other desktop 
  # systemd.user.startServices = "sd-switch";
  #
  # systemd.user.services.fcitx5 = {
  #   Unit = {
  #     Description = "Fcitx 5 input method";
  #     PartOf = [ "graphical-session.target" ];
  #     After = [ "graphical-session.target" ];
  #   };
  #
  #   Service = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.fcitx5}/bin/fcitx5"; # <-- NO -d
  #     Restart = "on-failure";
  #     RestartSec = 1;
  #
  #     # Kitty note: it uses GLFW; fcitx docs recommend this env var for kitty.
  #     Environment = [ "GLFW_IM_MODULE=ibus" ];
  #   };
  #
  #   Install = { WantedBy = [ "graphical-session.target" ]; };
  # };
  #
  home.sessionVariables = {
    # Kitty uses GLFW and must select Fcitx's IBus frontend at startup.
    GLFW_IM_MODULE = "ibus";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    JIRA_USER = "lanh.nguyen.tpv@one-line.com";
    JIRA_WEB = "oneline.atlassian.net";
    HINDSIGHT_API_LLM_PROVIDER = "github-copilot";
    HINDSIGHT_API_LLM_MODEL = "gpt-6-luna";
    HINDSIGHT_API_RETAIN_LLM_MODEL = "gpt-6-luna";
    HINDSIGHT_API_RETAIN_LLM_REASONING_EFFORT = "low";
    HINDSIGHT_API_CONSOLIDATION_LLM_MODEL = "gpt-6-luna";
    HINDSIGHT_API_CONSOLIDATION_LLM_REASONING_EFFORT = "low";
    GOG_CONFIG_DIR = "$HOME/.config/gogcli";
    GOG_DATA_DIR = "$HOME/.config/gogcli";
    GOG_KEYRING_BACKEND = "file";
  };

  # GNOME launches the configured terminal through systemd-run --user.
  systemd.user.sessionVariables = {
    GLFW_IM_MODULE = "ibus";
    HINDSIGHT_API_LLM_PROVIDER = "github-copilot";
    HINDSIGHT_API_LLM_MODEL = "gpt-6-luna";
    HINDSIGHT_API_RETAIN_LLM_MODEL = "gpt-6-luna";
    HINDSIGHT_API_RETAIN_LLM_REASONING_EFFORT = "low";
    HINDSIGHT_API_CONSOLIDATION_LLM_MODEL = "gpt-6-luna";
    HINDSIGHT_API_CONSOLIDATION_LLM_REASONING_EFFORT = "low";
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
      ExecStart = "${pkgs.callPackage ./mcpjungle.nix { }}/bin/mcpjungle start --host 127.0.0.1 --port 37373 --sqlite-db-path %h/.local/share/mcpjungle/mcpjungle.db";
      Environment = [
        "PATH=%h/.local/bin:${pkgs.nodejs_22}/bin:%h/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      ];
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Codex plugin archives do not include Context Mode's native SQLite addon.
  # Keep its per-version cache healthy after every Home Manager switch, using
  # the same mise-managed Node runtime that Codex uses for the plugin.
  home.activation.contextModeBetterSqlite3 =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      pluginCacheRoot="${config.home.homeDirectory}/.codex/plugins/cache/context-mode/context-mode"
      nodeBin="${config.home.homeDirectory}/.local/share/mise/installs/node/22.14.0/bin/node"
      npmBin="${config.home.homeDirectory}/.local/share/mise/installs/node/22.14.0/bin/npm"

      if [ -d "$pluginCacheRoot" ] && [ -x "$nodeBin" ] && [ -x "$npmBin" ]; then
        for pluginRoot in "$pluginCacheRoot"/*; do
          [ -f "$pluginRoot/package.json" ] || continue

          if ! "$nodeBin" -e 'const Database = require("better-sqlite3"); new Database(":memory:").close()' \
            >/dev/null 2>&1; then
            betterSqliteVersion="$($nodeBin -p "require(process.argv[1]).dependencies['better-sqlite3']" "$pluginRoot/package.json")"
            PATH="${config.home.homeDirectory}/.local/share/mise/installs/node/22.14.0/bin:${pkgs.python3}/bin:${pkgs.gcc}/bin:${pkgs.gnumake}/bin:${pkgs.pkg-config}/bin:$PATH" \
              PYTHON="${pkgs.python3}/bin/python3" \
              "$npmBin" --prefix "$pluginRoot" install "better-sqlite3@$betterSqliteVersion" \
                --no-save --no-package-lock --ignore-scripts=false --legacy-peer-deps --no-audit --no-fund
          fi
        done
      fi
    '';

  home.sessionPath = [
    "$HOME/personal/work"
    "$HOME/.docker/completions"
    "$HOME/.local/bin"
    "$HOME/go/bin"
  ];

  programs = {
    mise = {

      enable = true;
      enableZshIntegration = true;

      globalConfig = {
        tools = { node = [ "22.14.0" "24" "18.16.0" ]; };

        hooks = { postinstall = "corepack enable"; };

        settings = { experimental = true; };
      };
    };
    rmpc = {
      enable = true;

      # Keep config in your dotfiles repo and inject its contents:
      config = builtins.readFile ./rmpc/config.ron;
    };

    kitty = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.kitty;
      extraConfig = builtins.readFile ./kitty/kitty.conf;
    };

  };

}
