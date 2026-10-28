{ config, lib, pkgs, ... }:
let
  runtime = pkgs.callPackage ./packages/hindsight-coding-agents.nix { };
  dist = "${runtime}/lib/hindsight-coding-agents/dist";
  runtimePath = "${lib.makeBinPath [ pkgs.nodejs_24 pkgs.git pkgs.coreutils ]}:${config.home.profileDirectory}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
  hook = entry: timeout: {
    hooks = [{
      type = "command";
      command = "PATH=${lib.escapeShellArg runtimePath} ${runtime}/bin/hindsight-${entry}";
      inherit timeout;
    }];
  };
in {
  programs.claude-code = {
    enable = true;
    mutableSettings = true;
    context = config.programs.codex.context;
    skills = lib.mapAttrs (name: _: ./agents/skills + "/${name}")
      (lib.filterAttrs (name: type: type == "directory" && name != "hindsight-coding-agent")
        (builtins.readDir ./agents/skills)) // {
          hindsight-coding-agent = runtime + "/lib/hindsight-coding-agents/skill";
        };

    mcpServers = {
      codegraph = builtins.removeAttrs config.programs.codex.settings.mcp_servers.codegraph
        [ "startup_timeout_sec" "tool_timeout_sec" ];
      mcpjungle = {
        type = "http";
        url = config.programs.codex.settings.mcp_servers.mcpjungle.url;
      };
      hindsight = {
        command = "${pkgs.nodejs_24}/bin/node";
        args = [ "${dist}/mcp-server.js" ];
        env = {
          HINDSIGHT_MCP_HARNESS = "claude-code";
          HINDSIGHT_AUTO_UPDATE = "false";
          PATH = runtimePath;
        };
      };
    };

    settings = {
      hooks = {
        SessionStart = [ (hook "claude-sessionstart-hook" 30) ];
        UserPromptSubmit = [ (hook "claude-hook" 30) ];
        Stop = [ (hook "claude-stop-hook" 60) ];
      };
      extraKnownMarketplaces = {
        context-mode.source = { source = "github"; repo = "mksglu/context-mode"; };
        open-code-review.source = { source = "github"; repo = "alibaba/open-code-review"; };
        ponytail.source = { source = "github"; repo = "DietrichGebert/ponytail"; };
      };
      enabledPlugins = {
        "context-mode@context-mode" = true;
        "open-code-review@open-code-review" = true;
        "ponytail@ponytail" = true;
      };
    };
  };
}
