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
  home.packages = [ runtime ];
  # The pinned Codex did not discover the HM plugin wrapper; use its native surfaces.
  programs.codex = {
    hooks = {
      SessionStart = [ (hook "codex-sessionstart-hook" 30) ];
      UserPromptSubmit = [ (hook "codex-hook" 30) ];
      Stop = [ (hook "codex-stop-hook" 60) ];
    };
    skills.hindsight-coding-agent = runtime + "/lib/hindsight-coding-agents/skill";
    settings.mcp_servers.hindsight = {
      command = "${pkgs.nodejs_24}/bin/node";
      args = [ "${dist}/mcp-server.js" ];
      env = {
        HINDSIGHT_MCP_HARNESS = "codex";
        HINDSIGHT_AUTO_UPDATE = "false";
        PATH = runtimePath;
      };
      env_vars = [
        "CODEX_HOME" "HINDSIGHT_CONFIG" "HINDSIGHT_SERVER_MODE"
        "HINDSIGHT_API_URL" "HINDSIGHT_API_TOKEN"
      ];
      startup_timeout_sec = 60;
      tool_timeout_sec = 120;
    };
  };
}
