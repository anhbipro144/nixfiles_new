{ pkgs, config, nixgl, ... }:

let nixglPkgs = nixgl.packages.${pkgs.stdenv.hostPlatform.system};
in {

  targets.genericLinux.nixGL = {
    packages = nixglPkgs;
    defaultWrapper = "mesa";
  };

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.addons = with pkgs; [ qt6Packages.fcitx5-unikey fcitx5-gtk ];
  };

  # This fcitx5 autostart works for GNOME, should check if switch to other desktop 
  # systemd.user.startServices = "sd-switch";
  #
  # systemd.user.services.fcitx5 = {
  #   Unit = {
  #     Description = "Fcitx 5 input method";
  #     PartOf = [ "graphical-session.target" ];
  #     After = [ "graphical-session.target" ];
  #   };
  #
  #   Service = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.fcitx5}/bin/fcitx5"; # <-- NO -d
  #     Restart = "on-failure";
  #     RestartSec = 1;
  #
  #     # Kitty note: it uses GLFW; fcitx docs recommend this env var for kitty.
  #     Environment = [ "GLFW_IM_MODULE=ibus" ];
  #   };
  #
  #   Install = { WantedBy = [ "graphical-session.target" ]; };
  # };
  #
  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    JIRA_USER = "lanh.nguyen.tpv@one-line.com";
    JIRA_WEB = "oneline.atlassian.net";
  };

  home.sessionPath = [
    "$HOME/personal/work"
    "$HOME/.volta/bin"
    "$HOME/.docker/completions"
    "$HOME/.local/bin"
    "$HOME/go/bin"
  ];

  programs = {
    rmpc = {
      enable = true;

      # Keep config in your dotfiles repo and inject its contents:
      config = builtins.readFile ./rmpc/config.ron;
    };

    kitty = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.kitty;
      extraConfig = ''
        include themes/Kanagawa_dragon.conf
        font_family      FiraCode Nerd Font

        background_opacity 0.6
        confirm_os_window_close -1
        allow_remote_control yes
        listen_on unix:@mykitty
        shell_integration enabled
        font_size 16.0

        # kitty-scrollback.nvim Kitten alias
        # action_alias kitty_scrollback_nvim kitten /home/neo/.local/share/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py --nvim-args --clean --noplugin -n

        action_alias kitty_scrollback_nvim kitten /home/neo/.local/share/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py --nvim-args -u ~/.config/ksb-nvim/init.lua -n

        # Browse scrollback buffer in nvim
        map kitty_mod+h kitty_scrollback_nvim

        # Browse output of the last shell command in nvim
        map kitty_mod+g kitty_scrollback_nvim --config ksb_builtin_last_cmd_output

        # Show clicked command output in nvim
        mouse_map ctrl+shift+right press ungrabbed combine : mouse_select_command_output : kitty_scrollback_nvim --config ksb_builtin_last_visited_cmd_output


        map ctrl+equal change_font_size all +1.0
        map ctrl+minus change_font_size all -1.0
      '';
    };

  };

}
