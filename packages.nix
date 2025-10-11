{ pkgs, lib, config, host, zenBrowser, ... }: {

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "google-chrome"
  ];

  targets.genericLinux.enable = true; # non-NixOS niceties
  home.packages = with pkgs;
    ([ zsh-powerlevel10k delta git ripgrep eza python3 bat mosh ]
      ++ lib.optionals (host == "main") [
        google-cloud-sdk
        rustc
        cargo
        pnpm
        fnm
        flameshot
        vectorcode
        xclip
        macchina


        # Browser
        zenBrowser
        google-chrome

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

        yarn

        # Anki
        noto-fonts
        noto-fonts-cjk-sans
        dejavu_fonts
        (config.lib.nixGL.wrap pkgs.anki-bin)


        # Etc
        lazysql
      ]);
}
