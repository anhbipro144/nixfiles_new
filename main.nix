{ pkgs, lib, config, ... }: {
  imports = [ ./mcpjungle-config.nix ];

  home.sessionVariables = {
    JIRA_USER = "lanh.nguyen.tpv@one-line.com";
    JIRA_WEB = "oneline.atlassian.net";
    HINDSIGHT_API_LLM_PROVIDER = "github-copilot";
    HINDSIGHT_API_LLM_MODEL = "gpt-6-luna";
    HINDSIGHT_API_RETAIN_LLM_MODEL = "gpt-6-luna";
    HINDSIGHT_API_RETAIN_LLM_REASONING_EFFORT = "low";
    HINDSIGHT_API_CONSOLIDATION_LLM_MODEL = "gpt-6-luna";
    HINDSIGHT_API_CONSOLIDATION_LLM_REASONING_EFFORT = "low";
    GOG_CONFIG_DIR = "${config.home.homeDirectory}/.config/gogcli";
    GOG_DATA_DIR = "${config.home.homeDirectory}/.config/gogcli";
    GOG_KEYRING_BACKEND = "file";
  };

  # Codex plugin archives do not include Context Mode's native SQLite addon.
  home.activation.contextModeBetterSqlite3 =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      pluginCacheRoot="${config.home.homeDirectory}/.codex/plugins/cache/context-mode/context-mode"
      nodeBin="${config.home.homeDirectory}/.local/share/mise/installs/node/22.14.0/bin/node"
      npmBin="${config.home.homeDirectory}/.local/share/mise/installs/node/22.14.0/bin/npm"

      if [ -d "$pluginCacheRoot" ] && [ -x "$nodeBin" ] && [ -x "$npmBin" ]; then
        for pluginRoot in "$pluginCacheRoot"/*; do
          [ -f "$pluginRoot/package.json" ] || continue

          if ! (cd "$pluginRoot" && "$nodeBin" -e 'const Database = require("better-sqlite3"); new Database(":memory:").close()') \
            >/dev/null 2>&1; then
            betterSqliteVersion="$($nodeBin -p "require(process.argv[1]).dependencies['better-sqlite3']" "$pluginRoot/package.json")"
            PATH="${config.home.homeDirectory}/.local/share/mise/installs/node/22.14.0/bin:${pkgs.python3}/bin:${pkgs.stdenv.cc}/bin:${pkgs.gnumake}/bin:${pkgs.pkg-config}/bin:$PATH" \
              PYTHON="${pkgs.python3}/bin/python3" \
              "$npmBin" --prefix "$pluginRoot" install "better-sqlite3@$betterSqliteVersion" \
                --no-save --no-package-lock --ignore-scripts=false --legacy-peer-deps --no-audit --no-fund
          fi
        done
      fi
    '';

  home.sessionPath = [
    "${config.home.homeDirectory}/personal/work"
    "${config.home.homeDirectory}/.docker/completions"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/go/bin"
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
      config = builtins.readFile ./rmpc/config.ron;
    };
    kitty = {
      enable = true;
      extraConfig = if pkgs.stdenv.hostPlatform.isDarwin then
        lib.replaceStrings [ "listen_on unix:@mykitty" ]
        [ "listen_on unix:${config.home.homeDirectory}/.kitty-remote-control" ]
        (builtins.readFile ./kitty/kitty.conf)
      else
        builtins.readFile ./kitty/kitty.conf;
    };
  };
}
