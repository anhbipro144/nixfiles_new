{ pkgs, lib, config, ... }:
let
  mcpjungle = pkgs.callPackage ./mcpjungle.nix { };
  gatewayDir = "${config.xdg.dataHome}/mcpjungle";
in {
  # Home Manager owns Kitty's settings; Homebrew owns the native application.
  programs.kitty.package = null;
  home.file.".qutebrowser".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.config/qutebrowser";
  home.file.".config/qutebrowser/userscripts".source =
    config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.local/share/qutebrowser/userscripts";
  home.file.".config/qutebrowser/greasemonkey".source =
    config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.local/share/qutebrowser/greasemonkey";

  home.sessionPath = [
    "/opt/homebrew/bin"
    "/usr/local/bin"
    "/Applications/kitty.app/Contents/MacOS"
  ];
  # The Homebrew cask is disabled; Nix provides the ARM64 CLI and app bundle.
  home.packages = [ pkgs.qutebrowser ];

  home.activation.serviceDirectories =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${
        lib.escapeShellArgs [
          gatewayDir
          config.services.mpd.playlistDirectory
          config.services.mpd.musicDirectory
        ]
      }
    '';
  launchd.agents.mcpjungle = {
    enable = true;
    config = {
      ProgramArguments = [
        "${mcpjungle}/bin/mcpjungle"
        "start"
        "--host"
        "127.0.0.1"
        "--port"
        "37373"
        "--sqlite-db-path"
        "${gatewayDir}/mcpjungle.db"
      ];
      EnvironmentVariables.PATH =
        "${config.home.homeDirectory}/.local/bin:${pkgs.nodejs_22}/bin:${config.home.profileDirectory}/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 2;
      StandardOutPath = "${gatewayDir}/stdout.log";
      StandardErrorPath = "${gatewayDir}/stderr.log";
    };
  };
}
