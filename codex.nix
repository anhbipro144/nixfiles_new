{ pkgs, ... }:
let codegraph = pkgs.callPackage ./packages/codegraph.nix { };
in {
  imports = [ ./hindsight.nix ];
  programs.codex = {
    enable = true;
    mutableSettings = true;
    package = null;
    # The MCP server supplies its own exploration and indexing guidance.
    context = ''
      Use CodeGraph impact analysis before significant refactors in indexed repositories.
      Verify consequential CodeGraph findings against current source; use native search when the graph is missing, stale, or incomplete.
    '';
    settings = {
      model_provider = "openai";
      model = "gpt-6-luna";
      model_reasoning_effort = "high";
      approval_policy = "on-request";
      approvals_reviewer = "auto_review";
      sandbox_mode = "workspace-write";
      personality = "pragmatic";
      service_tier = "default";
      web_search = "live";

      features = {
        apps = false;
        hooks = true;
        plugins = true;
      };

      desktop = {
        conversationDetailMode = "STEPS_PROSE";
        followUpQueueMode = "steer";
        keepRemoteControlAwakeWhilePluggedIn = true;
        sansFontSize = 16;
      };

      apps = {
        _default.enabled = false;
        gmail.enabled = true;
      };

      notice.hide_rate_limit_model_nudge = true;

      marketplaces = {
        "context-mode" = {
          source_type = "git";
          source = "https://github.com/mksglu/context-mode.git";
        };
        "open-code-review" = {
          source_type = "git";
          source = "https://github.com/alibaba/open-code-review.git";
        };
        ponytail = {
          source_type = "git";
          source = "https://github.com/DietrichGebert/ponytail.git";
        };
      };

      mcp_servers = {
        codegraph = {
          command = "${codegraph}/bin/codegraph";
          args = [ "serve" "--mcp" ];
          env = {
            CODEGRAPH_TELEMETRY = "0";
            CODEGRAPH_NO_UPDATE_CHECK = "1";
          };
          startup_timeout_sec = 60;
          tool_timeout_sec = 120;
        };
        mcpjungle.url = "http://127.0.0.1:37373/mcp";
        chrome-devtools = {
          command = "npx";
          args = [
            "-y"
            "chrome-devtools-mcp@latest"
            "--autoConnect"
            "--no-usage-statistics"
            "--no-performance-crux"
          ];
          env_vars = [ "PATH" ];
          startup_timeout_sec = 60;
          tool_timeout_sec = 120;

        };
        # hindsight = {
        #   command = "npx";
        #   args = [
        #     "${config.home.homeDirectory}/.hindsight/coding-agents/dist/mcp-server.js"
        #   ];
        #   env_vars = [ "HINDSIGHT_MCP_HARNESS" ];
        # };
        # libreoffice = {
        #   command = "${config.home.profileDirectory}/bin/uv";
        #   args = [
        #     "--directory"
        #     "${config.home.homeDirectory}/projects/mcp-libre"
        #     "run"
        #     "fastmcp"
        #     "run"
        #     "${config.home.homeDirectory}/projects/mcp-libre/libreoffice_mcp_server.py"
        #   ];
        #   tool_approval.document.approval_mode = "approve";
        # };
      };

      plugins = {
        "context-mode@context-mode".enabled = true;
        "open-code-review-codex@open-code-review".enabled = true;
        "ponytail@ponytail".enabled = true;

        "browser@openai-bundled".enabled = false;
        "chrome@openai-bundled".enabled = false;
        "code-review@openai-bundled".enabled = true;
        "codex-app-tools@openai-bundled".enabled = false;

        "documents@openai-primary-runtime".enabled = false;
        "github@openai-curated".enabled = false;
        "pdf@openai-primary-runtime".enabled = false;
        "presentations@openai-primary-runtime".enabled = false;
        "spreadsheets@openai-primary-runtime".enabled = false;
        "template-creator@openai-primary-runtime".enabled = false;

        "unified-computer-use@openai-bundled".enabled = false;
        "visualize@openai-bundled".enabled = false;
      };

      tui = {
        session_picker_view = "dense";
        status_line = [
          "model-with-reasoning"
          "current-dir"
          "git-branch"
          "five-hour-limit"
          "weekly-limit"
        ];
        status_line_use_colors = true;
      };
    };
  };
}
