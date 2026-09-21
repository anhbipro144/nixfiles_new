{ pkgs, lib, config, zenBrowser , ... }:
let
  mcp-language-server-lazy =
    pkgs.callPackage ./mcp-language-server-lazy.nix { };
  mcpjungle = pkgs.callPackage ./mcpjungle.nix { };
  libreofficeMcp = config.lib.nixGL.wrap pkgs.libreoffice-qt-stable;
in {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "google-chrome"
      "postman"
      "github-copilot-cli"
      "unrar"
      "antigravity-cli"
    ];

  targets.genericLinux.enable = true; # non-NixOS niceties
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
      # Flameshot 14 uses a per-monitor capture flow, avoiding the broken
      # virtual-desktop overlay from 13.x on our offset X11 displays.
      flameshot
      xclip
      rofi
      syncthing
      wine64

      # Browsers and web clients
      zenBrowser
      (config.lib.nixGL.wrap pkgs.google-chrome)
      (config.lib.nixGL.wrap pkgs.qutebrowser)
      webcord
      qbittorrent-enhanced
      yt-dlp

      # Office, documents, and fonts
      libreofficeMcp
      noto-fonts
      noto-fonts-cjk-sans
      dejavu_fonts
      (config.lib.nixGL.wrap pkgs.anki-bin)
      zotero

      # Music and video
      mpd
      (config.lib.nixGL.wrap pkgs.kid3)
      vlc

      # Cloud, API, and service clients
      google-cloud-sdk
      postman
      # gh
      gogcli
      jira-cli-go
      google-alloydb-auth-proxy
      grpcurl

      # General development tools
      rustc
      cargo
      go
      pnpm
      uv
      protobuf
      gnumake
      gcc
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
      codex
      ctx7
      antigravity-cli
      github-copilot-cli
      mcp-language-server-lazy
      mcpjungle

      # Security and credentials
      (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]))
      gnupg
      unrar

      # chatgpt

      # Python utilities
      python3Packages.tldextract
    ]);
}
