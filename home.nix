{ pkgs, zenBrowser, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage.
  home.username = "neo";
  home.homeDirectory = "/home/neo";
  home.stateVersion = "25.05";

  programs = {
    home-manager.enable = true;
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
      antidote.enable = true;

      initContent = ''
        autoload -Uz compinit
        zmodload -i zsh/complist
        compinit -i

        zstyle ':completion:*' completer \
          _expand _complete _match _approximate _correct _complete:-fuzzy _ignored
        zstyle ':completion:*' special-dirs true
        _comp_options+=(globdots)

        setopt globdots
        # --- Plugin & Vi-Mode Loading BELOW THIS LINE ---
        # e.g., znap, starship, direnv, etc.

        # --- After jeffreytse/zsh-vi-mode is sourced: ---
        zvm_after_init_commands+=('bindkey -M viins "^N" menu-select')
        zvm_after_init_commands+=('bindkey -M viins "^P" menu-select')


        # Load Powerlevel10k theme
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        test -f ~/.p10k.zsh && source ~/.p10k.zsh
        
        bindkey -M menuselect '\r' .accept-line


        # Alisases
        # General
        alias cls='clear'

        # nautilus
        alias nau="nohup nautilus -w . > /dev/null &"

        # Better ls
        alias l="eza --icons=always"
        alias ls="eza --icons=always -a"
        alias ll="eza -lg --icons=always"
        alias la="eza -lag --icons=always"
        alias lt="eza -lTg --icons=always"


        alias nv="nvim"
        alias cd="z"

        node() { nix-shell -p nodejs --run "node $@"; }
        npm()  { nix-shell -p nodejs --run "npm $@"; }


        macchina
      '';

      antidote.plugins = [
        "zsh-users/zsh-syntax-highlighting"
        "marlonrichert/zsh-autocomplete"
        "lukechilds/zsh-nvm"
        "jeffreytse/zsh-vi-mode"
      ];

      antidote.useFriendlyNames = true;
    };

  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    nodejs
    zsh-powerlevel10k
    delta
    rustc
    cargo
    git
    ripgrep
    zenBrowser
    macchina
    eza
    gnumake
    gcc
    vectorcode
    xclip
    python3
    bat
  ];

  home.file = {
    ".config/nvim" = {
      source = ./nvim;
      recursive = true;
    };

    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/n/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

}
