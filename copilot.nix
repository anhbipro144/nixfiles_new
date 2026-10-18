{ ... }: {
  home.file.".copilot/mcp-config.json" = {
    force = true;
    source = ./copilot/mcp-config.json;
  };

  home.file.".copilot/settings.json" = {
    force = true;
    source = ./copilot/settings.json;
  };
}
