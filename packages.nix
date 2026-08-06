{ pkgs, lib, config, zenBrowser, neovimPkgs, ... }:
let
  veloxdb = pkgs.callPackage ./veloxdb.nix { };

  nsgclientClean = pkgs.writeShellScriptBin "nsgclient-clean" ''
    unset LD_LIBRARY_PATH
    unset NIX_LD
    unset NIX_LD_LIBRARY_PATH
    unset LD_PRELOAD
    unset LIBGL_DRIVERS_PATH
    unset __EGL_VENDOR_LIBRARY_DIRS
    unset __EGL_VENDOR_LIBRARY_FILENAMES
    unset EGL_VENDOR_LIBRARY_FILENAMES
    unset VK_ICD_FILENAMES
    unset VK_LAYER_PATH
    unset GBM_BACKENDS_PATH
    unset LIBVA_DRIVERS_PATH
    unset VDPAU_DRIVER_PATH
    unset QT_PLUGIN_PATH
    unset QML2_IMPORT_PATH
    unset GIO_EXTRA_MODULES
    unset GTK_PATH
    unset GI_TYPELIB_PATH

    exec /opt/Citrix/NSGClient/bin/NSGClient "$@"
  '';
in {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "google-chrome"
      "postman"
      "github-copilot-cli"
      "veloxdb"
      "unrar"
    ];

  targets.genericLinux.enable = true; # non-NixOS niceties
  xdg.desktopEntries.nsgclient = {
    name = "Citrix Secure Access";
    exec = "${nsgclientClean}/bin/nsgclient-clean %u";
    icon = "citrix-receiver";
    terminal = false;
    noDisplay = true;
    categories = [ "Network" "RemoteAccess" ];
    mimeType = [ "x-scheme-handler/application" "x-scheme-handler/citrixsso" ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/http" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/https" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/application" = [ "nsgclient.desktop" ];
      "x-scheme-handler/citrixsso" = [ "nsgclient.desktop" ];
    };
  };
  home.packages = with pkgs;
    ([ zsh-powerlevel10k delta git ripgrep eza bat mosh nsgclientClean ] ++ [

      #Utils
      google-cloud-sdk
      rustc
      cargo
      pnpm
      # nixos-unstable currently resolves to flameshot 14.0.rc1, which fails
      # to capture on this regolith-x11 session.
      neovimPkgs.flameshot
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
      gemini-cli

      # Search
      fd

      #Databases
      lazysql
      (config.lib.nixGL.wrap veloxdb)

      #Music 
      mpd

      #Java
      # jdk25_headless
      jdk25

      #Databases
      postgresql
      grpcurl

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
      github-copilot-cli
      ctx7
      wine64
      unrar
      google-alloydb-auth-proxy
    ]);
}
