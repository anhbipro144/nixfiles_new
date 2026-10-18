{ config, ... }: {
  programs.codex = {
    enable = true;
    package = null;
    settings = {
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
          last_revision = "5a92b7caaf0086d04b87cc03a82505c891aa8254";
          last_updated = "2026-09-23T12:31:55Z";
        };
        "open-code-review" = {
          source_type = "git";
          source = "https://github.com/alibaba/open-code-review.git";
        };
        ponytail = {
          source_type = "git";
          source = "https://github.com/DietrichGebert/ponytail.git";
          last_revision = "e3ba2aa6f1e6f0bc4d69eb09c9f0d0a93af56156";
          last_updated = "2026-09-22T04:07:28Z";
        };
      };

      mcp_servers = {
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
