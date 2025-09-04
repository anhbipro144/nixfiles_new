{ pkgs, ... }: {
  programs = {
    home-manager.enable = true;
    zoxide.enable = true;
    neovim.enable = true;

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


        if [ -f "$HOME/.config/home-manager/secrets/secrets.env" ]; then
          set -a
          . "$HOME/.config/home-manager/secrets/secrets.env"
          set +a
        fi



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
              nvim
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

        # Better ls
        l = "eza --icons=always";
        ls = "eza --icons=always -a";
        ll = "eza -lg --icons=always";
        la = "eza -lag --icons=always";
        lt = "eza -lTg --icons=always";

        # docker
        dc = "docker compose";

        #nvm
        nvm = "fnm";



        #nvim
        nv = "nvim";
        nvb="NVIM_APPNAME=nvim-base nvim";
        nvv="NVIM_APPNAME=nvim-minimal nvim";

        #Nixhome-manager switch --flake $HOME/.config/home-manager
        hms = "home-manager switch --flake $HOME/.config/home-manager#ubuntu@vm";

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

        # QT_XCB_GL_INTEGRATION = "none";
        # QT_QUICK_BACKEND = "software";
        # ANKI_DISABLE_HW_ACCEL = "1";
        # QTWEBENGINE_CHROMIUM_FLAGS =
        #   "--disable-gpu --disable-software-rasterizer";
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
}

