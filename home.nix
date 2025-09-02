{ pkgs, zenBrowser, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage.
  home.username = "neo";
  home.homeDirectory = "/home/neo";
  home.stateVersion = "25.05";

  programs = {
    home-manager.enable = true;
    anki = {
      package = pkgs.anki;
      enable = true;
      language = "en_US";
    };
    neovim.enable = true;
    zoxide.enable = true;
    kitty = {
      enable = true;
      extraConfig = ''
        background_opacity 0.8
        confirm_os_window_close -1
      '';
    };

    zsh = {
      enable = true;

      initContent = ''
                    zstyle ':completion:*' completer \
                      _expand _complete _match _approximate _correct _complete:-fuzzy _ignored
                    zstyle ':completion:*' special-dirs true
                    _comp_options+=(globdots)

                    setopt globdots

                    zvm_after_init_commands+=('bindkey -M viins "^N" menu-select')
                    zvm_after_init_commands+=('bindkey -M viins "^P" menu-select')


                    # Load Powerlevel10k theme
                    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
                    test -f ~/.p10k.zsh && source ~/.p10k.zsh



                    bindkey -M menuselect '\r' .accept-line

                    ci() {
                      if [ $# -eq 0 ]; then
                        echo "Usage: zn <pattern>"
                        return 1
                      fi
                      z "$@" && nvim .
                    }



                chroma() {
                  docker run -d \
                    --name chromadb \
                    -p 8000:8000 \
                    -v ~/.chroma_data:/chroma/chroma \
                    -e IS_PERSISTENT=TRUE \
                    -e ANONYMIZED_TELEMETRY=TRUE \
                    chromadb/chroma:0.6.3 "$@"
                }


                    eval "$(fnm env --use-on-cd --shell zsh)"

                    macchina


        cd() {
          # Use the built-in 'command cd' if no arguments are given to go to the home directory.
          if [ $# -eq 0 ]; then
            command cd
            return
          fi

          local edit_mode=false
          local dir_args=()

          # Loop through all provided arguments.
          for arg in "$@"; do
            if [[ "$arg" == "-e" ]]; then
              # If an argument is '-e', set the edit_mode flag to true.
              edit_mode=true
            else
              # Otherwise, add the argument to our list of directory patterns.
              dir_args+=("$arg")
            fi
          done

          # If, after parsing, there are no directory patterns, show usage.
          # This handles the case where the only argument was '-e'.
          if [ ''${#dir_args[@]} -eq 0 ]; then
            echo "Usage: cd <pattern> [-e]"
            return 1
          fi

          # Attempt to change directory using 'z'.
          if z "''${dir_args[@]}"; then
            # If the directory change is successful and edit_mode is true, open Neovim.
            if [ "$edit_mode" = true ]; then
              nvim .
            fi
          else
            # If 'z' fails, return an error status.
            return 1
          fi
        }
      '';

      completionInit = ''
        autoload -Uz compinit
        zmodload -i zsh/complist
        compinit -i
      '';

      shellAliases = {
        # General
        cls = "clear";
        nau = "nohup nautilus -w . > /dev/null &";
        nv = "nvim";

        # Better ls
        l = "eza --icons=always";
        ls = "eza --icons=always -a";
        ll = "eza -lg --icons=always";
        la = "eza -lag --icons=always";
        lt = "eza -lTg --icons=always";

        #Nvim
        nvm = "fnm";

        #Nix
        hms = "home-manager switch --flake $HOME/.config/home-manager";

        #Shine-wa
        wadev =
          "cloud-sql-proxy --address 0.0.0.0 --port 3306 one-global-ocps-dev:asia-southeast1:ocps-dev-db ";
        waprod =
          "cloud-sql-proxy --address 0.0.0.0 --port 3303 one-global-ocps-prod:asia-southeast1:ocps-prod-db2";
        watest =
          "cloud-sql-proxy --address 0.0.0.0 --port 3302 one-global-ocps-test:asia-southeast1:ocps-test-db";

      };

      sessionVariables = {
        PATH = "$HOME/personal/work/WA:$PATH";

        QT_QUICK_BACKEND = "software";
        ANKI_DISABLE_HW_ACCEL = "1";
        QTWEBENGINE_CHROMIUM_FLAGS =
          "--disable-gpu --disable-software-rasterizer";
      };

      antidote = {
        enable = true;
        plugins = [
          "zsh-users/zsh-syntax-highlighting"
          "marlonrichert/zsh-autocomplete"
          "jeffreytse/zsh-vi-mode"
        ];
        useFriendlyNames = true;
      };
    };

  };

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.addons = with pkgs; [ fcitx5-unikey fcitx5-gtk ];
  };

  home.file = {
    ".config/nvim" = {
      source = ./nvim;
      recursive = true;
    };

  };

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    FPATH = "$HOME/.docker/completions:$FPATH";
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    zsh-powerlevel10k
    delta
    rustc
    cargo
    git
    ripgrep
    zenBrowser
    macchina
    eza
    vectorcode
    xclip
    python3
    bat
    flameshot
    fnm
    google-cloud-sdk

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
    mycli
    cmake
    pnpm
  ];

}
