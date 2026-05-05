{ pkgs, lib, config, host, zenBrowser, ... }:
let
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
    builtins.elem (lib.getName pkg) [ "google-chrome" "postman" ];

  targets.genericLinux.enable = true; # non-NixOS niceties
  xdg.desktopEntries.nsgclient = lib.mkIf (host == "main") {
    name = "Citrix Secure Access";
    exec = "${nsgclientClean}/bin/nsgclient-clean %u";
    icon = "citrix-receiver";
    terminal = false;
    noDisplay = true;
    categories = [ "Network" "RemoteAccess" ];
    mimeType = [ "x-scheme-handler/application" "x-scheme-handler/citrixsso" ];
  };

  xdg.mimeApps = lib.mkIf (host == "main") {
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
    ([ zsh-powerlevel10k delta git ripgrep eza bat mosh nsgclientClean ]
      ++ lib.optionals (host == "main") [

        #Utils
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
        codex-acp
        gemini-cli

        # Search
        fd

        #Databases
        lazysql

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
      ]);
}
