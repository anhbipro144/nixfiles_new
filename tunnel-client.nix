{ config, lib, pkgs, ... }:
let
  yaml = pkgs.formats.yaml { };
  tunnelClient = pkgs.callPackage ./tunnel-client-package.nix { };
  profile = yaml.generate "mcpjungle.yaml" {
    config_version = 1;
    control_plane = {
      base_url = "https://api.openai.com";
      tunnel_id = "tunnel_6ab1279028948191ba3d2d718edae2fa";
      api_key = "env:CONTROL_PLANE_API_KEY";
    };
    health.listen_addr = "127.0.0.1:8080";
    admin_ui.open_browser = false;
    log = { level = "info"; format = "json"; };
    mcp.server_urls = [{ channel = "main"; url = "http://127.0.0.1:37373/mcp"; }];
  };
in {
  home.packages = [ tunnelClient ];

  # tunnel-client rejects Home Manager's config symlink because it resolves paths
  # within the profile directory. Install the generated file as a regular file.
  home.activation.tunnelClientProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm600 ${profile} ${lib.escapeShellArg "${config.xdg.configHome}/tunnel-client/mcpjungle.yaml"}
  '';
}
