{ config, pkgs, zenBrowser, kittum, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage.
  home.username = "neo";
  home.homeDirectory = "/home/neo";
  home.stateVersion = "25.05"; 

  programs = {
    home-manager.enable = true;
    neovim.enable = true;
    zoxide.enable = true;
    kitty.enable = true;

    zsh = {
      enable = true;
      antidote.enable = true;

      initContent = ''
        # Load Powerlevel10k theme
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
            test -f ~/.p10k.zsh && source ~/.p10k.zsh


        # aliases
        alias nv="nvim"
        alias cd="z"
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
