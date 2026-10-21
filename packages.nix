{ pkgs, lib, config, ... }:
let
  mcp-language-server-lazy =
    pkgs.callPackage ./mcp-language-server-lazy.nix { };
  mcpjungle = pkgs.callPackage ./mcpjungle.nix { };
  codegraph = pkgs.callPackage ./packages/codegraph.nix { };
  sonarqube-cli =
    let
      version = "1.8.0.5274";
      artifacts = {
        x86_64-linux = {
          platform = "linux-x86-64";
          os = "linux";
          hash = "sha256-+/05s3mNfBGhxcgTdzUfgrqK5r5lM1JD8Ls8keepIdE=";
        };
        aarch64-darwin = {
          platform = "macos-arm64";
          os = "macos";
          hash = "sha256-uk+y6o6YdC2zYRYuyEVCOdXWLIy6imxBMEytt/IVFWA=";
        };
      };
      artifact = artifacts.${pkgs.stdenvNoCC.hostPlatform.system}
        or (throw "sonarqube-cli is unsupported on ${pkgs.stdenvNoCC.hostPlatform.system}");
    in pkgs.stdenvNoCC.mkDerivation {
      pname = "sonarqube-cli";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://binaries.sonarsource.com/Distribution/sonarqube-cli/${version}/${artifact.os}/sonarqube-cli-${version}-${artifact.platform}.bin";
        inherit (artifact) hash;
      };
      dontUnpack = true;
      installPhase = ''
        install -Dm755 "$src" "$out/bin/sonar"
      '';
      meta = {
        description = "Command-line interface for SonarQube";
        mainProgram = "sonar";
        platforms = builtins.attrNames artifacts;
      };
    };
in {
  # Prefer this runtime over an existing ~/.local/bin/codegraph launcher.
  home.sessionPath = lib.mkBefore [ "${codegraph}/bin" ];

  home.activation.codegraphTelemetry =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      run ${codegraph}/bin/codegraph telemetry off
    '';

  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "google-chrome"
      "chatgpt"
      "discord"
      "postman"
      "raycast"
      "github-copilot-cli"
      "unrar"
      "antigravity-cli"
      "ngrok"
    ];

  home.packages = with pkgs;
    ([
      # Shell and core command-line tools
      zsh-powerlevel10k
      git
      ripgrep
      fd
      eza
      bat
      mosh
      macchina
      tree-sitter
      ast-grep
    ] ++ [
      # Desktop and system utilities
      syncthing

      # Browsers and web clients
      yt-dlp

      # Office, documents, and fonts
      noto-fonts
      noto-fonts-cjk-sans
      dejavu_fonts
      nerd-fonts.fira-code

      # Music and video
      mpd

      # Cloud, API, and service clients
      google-cloud-sdk
      gh
      gogcli
      sonarqube-cli
      jira-cli-go
      google-alloydb-auth-proxy
      google-cloud-sql-proxy
      grpcurl

      # General development tools
      rustc
      cargo
      go
      pnpm
      uv
      protobuf
      gnumake
      stdenv.cc
      pkg-config
      autoconf
      automake
      libtool
      bison
      flex
      clang-tools
      neocmakelsp
      cmake

      # Java
      # jdk25_headless
      jdk25

      # Database clients and servers
      mycli
      pgcli
      lazysql
      postgresql

      # AI and MCP tooling
      codegraph
      ctx7
      antigravity-cli
      github-copilot-cli
      mcp-language-server-lazy
      mcpjungle

      # Security and credentials
      (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]))
      gnupg
      unrar

      # Python utilities
      python3Packages.tldextract

      #Etc
      lazygit
      mautrix-meta
    ]);
}
