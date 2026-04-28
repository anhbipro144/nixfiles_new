{ pkgs, lib, config, host, zenBrowser, ... }:
let
  mkWarpCmd = name: body:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail

      if ! command -v warp-cli >/dev/null 2>&1; then
        echo "warp-cli not found. Install Cloudflare WARP (package: cloudflare-warp) first." >&2
        exit 1
      fi

      ${body}
    '';

  overlay = final: prev: {
    jiratui = prev.jiratui.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace src/jiratui/widgets/work_item_details/details.py \
          --replace-fail "Select.BLANK" "Select.NULL"
      '';
    });
  };
in {
  nixpkgs.overlays = [ overlay ];
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "google-chrome"
      "cloudflare-warp"
      "postman"
    ];

  targets.genericLinux.enable = true; # non-NixOS niceties
  home.packages = with pkgs;
    ([ zsh-powerlevel10k delta git ripgrep eza bat mosh ]
      ++ lib.optionals (host == "main") [
        google-cloud-sdk
        rustc
        cargo
        pnpm
        flameshot
        vectorcode
        xclip
        macchina

        # Browser
        zenBrowser
        google-chrome
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
        codex-acp
        gemini-cli

        # Search
        fd

        #Databases
        lazysql

        #Music 
        mpd

        #Jira
        jiratui

        #Java
        # jdk25_headless
        jdk25

        #Databases
        postgresql
        grpcurl

        # Etc
        qutebrowser
        gogcli
        protobuf
        qbittorrent-enhanced
        volta
        webcord
        jira-cli-go
        yt-dlp # yt downloader
        vlc
        go



        # Warp
        (mkWarpCmd "warp-on" ''
          warp-cli connect
          ${pkgs.curl}/bin/curl -fsS https://www.cloudflare.com/cdn-cgi/trace/ | ${pkgs.gnugrep}/bin/grep '^warp=' || true
        '')
        (mkWarpCmd "warp-off" ''
          warp-cli disconnect
        '')
      ]);
}
