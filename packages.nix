{ pkgs, lib, config, zenBrowser, neovimPkgs, ... }:
let
  mcp-language-server-lazy =
    pkgs.callPackage ./mcp-language-server-lazy.nix { };
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
    ([ zsh-powerlevel10k git ripgrep eza bat mosh ] ++ [

      #Utils
      google-cloud-sdk
      rustc
      cargo
      pnpm
      # Flameshot 14 uses a per-monitor capture flow, avoiding the broken
      # virtual-desktop overlay from 13.x on our offset X11 displays.
      flameshot
      xclip
      macchina

      # Browser
      zenBrowser
      (config.lib.nixGL.wrap pkgs.google-chrome)

      #API client
      postman

      # Python
      uv

      # C++
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

      # Db CLIs
      mycli
      pgcli

      #Github cli
      # gh

      # Anki
      noto-fonts
      noto-fonts-cjk-sans
      dejavu_fonts
      (config.lib.nixGL.wrap pkgs.anki-bin)

      # AI CLIs
      codex
      mcp-language-server-lazy

      # Search
      fd

      #Databases
      lazysql

      #Music 
      mpd
      (config.lib.nixGL.wrap pkgs.kid3)

      #Java
      # jdk25_headless
      jdk25

      #Databases
      postgresql
      grpcurl

      #AI
      antigravity-cli
      github-copilot-cli
      # chatgpt

      # Etc
      (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]))
      gnupg
      rofi
      python3Packages.tldextract
      (config.lib.nixGL.wrap pkgs.qutebrowser)
      gogcli
      protobuf
      qbittorrent-enhanced
      webcord
      jira-cli-go
      yt-dlp # yt downloader
      vlc
      go
      ctx7
      wine64
      unrar
      google-alloydb-auth-proxy
      tree-sitter
      ast-grep
    ]);
}
