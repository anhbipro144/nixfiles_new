{ config, lib, pkgs, ... }:
let
  home = config.home.homeDirectory;
  gateway = pkgs.callPackage ./mcpjungle.nix { };
  serverPath = "${home}/.local/bin:${pkgs.nodejs_22}/bin:${config.home.profileDirectory}/bin"
    + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ":/opt/homebrew/bin"
    + ":/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
  stdio = args: {
    transport = "stdio";
    session_mode = "stateless";
    command = "${pkgs.nodejs_22}/bin/npx";
    inherit args;
    env.PATH = serverPath;
  };
  servers = {
    openaiDeveloperDocs = {
      transport = "streamable_http";
      session_mode = "stateless";
      url = "https://developers.openai.com/mcp";
    };
    anki = (stdio [ "-y" "@ankimcp/anki-mcp-server" "--stdio" ]) // {
      description = "Interact with the local Anki collection through AnkiConnect";
      env = { PATH = serverPath; ANKI_CONNECT_URL = "http://127.0.0.1:8765"; };
    };
    atlassian = (stdio [ "-y" "mcp-remote@latest"
      "https://mcp.atlassian.com/v2/mcp" "--transport" "http-only" ]) // {
      description = "Atlassian Rovo MCP through mcp-remote OAuth bridge";
      session_mode = "stateful";
    };
    playwright = (stdio [ "@playwright/mcp@latest" "--cdp-endpoint=chrome" ]) // {
      description = "Playwright MCP connected to the running Chrome channel";
      session_mode = "stateful";
    };
    chrome-devtools = (stdio [ "-y" "chrome-devtools-mcp@latest"
      "--autoConnect" "--no-usage-statistics" "--no-performance-crux" ]) // {
      description = "Chrome DevTools MCP connected to the running Chrome browser";
      session_mode = "stateful";
    };
    figma_framelink = (stdio [ "-y" "figma-developer-mcp" "--stdio" ]) // {
      description = "Framelink MCP for Figma";
    };
    filesystem = (stdio [ "-y" "@modelcontextprotocol/server-filesystem" home "/tmp" ]) // {
      description = "Filesystem access to the home directory and /tmp";
    };
  };
in {
  xdg.configFile = lib.mapAttrs' (name: settings:
    lib.nameValuePair "mcpjungle/servers/${name}.json" {
      text = builtins.toJSON (settings // { inherit name; });
    }) servers;

  home.packages = [ (pkgs.writeShellScriptBin "mcpjungle-sync" ''
    exec ${pkgs.python3}/bin/python3 ${./scripts/mcpjungle-sync.py} \
      --config-dir ${lib.escapeShellArg "${config.xdg.configHome}/mcpjungle"} \
      --database ${lib.escapeShellArg "${config.xdg.dataHome}/mcpjungle/mcpjungle.db"} \
      --mcpjungle ${gateway}/bin/mcpjungle "$@"
  '') ];
}
