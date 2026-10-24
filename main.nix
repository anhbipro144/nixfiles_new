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
    GOG_KEYRING_BACKEND = if pkgs.stdenv.hostPlatform.isDarwin then "keychain" else "file";
  };

  # Codex plugin archives do not include Context Mode's native SQLite addon.
  home.activation.contextModeBetterSqlite3 =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      pluginCacheRoot="${config.home.homeDirectory}/.codex/plugins/cache/context-mode/context-mode"
      nodeBin="${pkgs.nodejs_24}/bin/node"
      npmBin="${pkgs.nodejs_24}/bin/npm"

      if [ -d "$pluginCacheRoot" ] && [ -x "$nodeBin" ] && [ -x "$npmBin" ]; then
        for pluginRoot in "$pluginCacheRoot"/*; do
          [ -f "$pluginRoot/package.json" ] || continue

          if ! (cd "$pluginRoot" && "$nodeBin" -e 'const Database = require("better-sqlite3"); new Database(":memory:").close()') \
            >/dev/null 2>&1; then
            betterSqliteVersion="$($nodeBin -p "require(process.argv[1]).dependencies['better-sqlite3']" "$pluginRoot/package.json")"
            (
              export PATH="${pkgs.nodejs_24}/bin:${pkgs.python3}/bin:${pkgs.stdenv.cc}/bin:${pkgs.gnumake}/bin:${pkgs.pkg-config}/bin:$PATH"
              export PYTHON="${pkgs.python3}/bin/python3"
              "$npmBin" --prefix "$pluginRoot" install "better-sqlite3@$betterSqliteVersion" \
                --no-save --no-package-lock --ignore-scripts=false --legacy-peer-deps --no-audit --no-fund
              "$npmBin" --prefix "$pluginRoot" rebuild better-sqlite3 --ignore-scripts=false
              cd "$pluginRoot"
              "$nodeBin" -e 'const Database = require("better-sqlite3"); new Database(":memory:").close()'
            )
          fi

          # shortcut: remove npm bin links until Codex hook fingerprinting supports them.
          if [ -d "$pluginRoot/node_modules" ]; then
            "${pkgs.findutils}/bin/find" "$pluginRoot/node_modules" -type l -path '*/.bin/*' -delete
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
        tools = { node = "24"; };
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
      extraConfig =
        let
          kittyConfig = builtins.readFile ./kitty/kitty.conf;
        in
        if pkgs.stdenv.hostPlatform.isDarwin then
          lib.replaceStrings [ "listen_on unix:@mykitty" ]
            [ "listen_on unix:${config.home.homeDirectory}/.kitty-remote-control" ]
            kittyConfig
          + "\n"
          + ''
            # Globe is mapped to Command on macOS. Send these shortcuts to the shell.
            # Keep Ctrl+R for the zsh history list instead of Kitty's resize mode.
            map super+r send_key ctrl+r
            # Navigate history and completion menus with Globe+N/P.
            map super+n send_key ctrl+n
            map super+p send_key ctrl+p
            # Navigate Neovim splits with Globe+H/J/K/L.
            map super+h send_key ctrl+h
            map super+j send_key ctrl+j
            map super+k send_key ctrl+k
            map super+l send_key ctrl+l
            # Use Globe+D/U for Neovim's half-page scrolling keys.
            map super+d send_key ctrl+d
            map super+u send_key ctrl+u
            # Toggle Neovim's floating terminal with Globe+0.
            map super+0 send_key ctrl+0
          ''
        else
          kittyConfig;
    };
  };
}
