{ config, pkgs,zenBrowser, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "n";
  home.homeDirectory = "/home/n";

programs.neovim = { enable = true; };
  
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };
 #Zoxide
  programs.zoxide = { enable = true; };

programs.zsh = {
  enable = true;
  antidote.enable = true;

initContent = ''
    # Load Powerlevel10k theme
    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        test -f ~/.p10k.zsh && source ~/.p10k.zsh

    alias nv="nvim"
  '';

  # Optional: use the default package (pkgs.antidote),
  # or override:
  # antidote.package = pkgs.antidote;
  # Define your plugin list:
  antidote.plugins = [
    "zsh-users/zsh-syntax-highlighting"
    "marlonrichert/zsh-autocomplete"
    "lukechilds/zsh-nvm"
    "jeffreytse/zsh-vi-mode"
  ];
  # Optional: enable friendly names instead of hash-based directory names:
  antidote.useFriendlyNames = true;
};


  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
  kitty
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
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
