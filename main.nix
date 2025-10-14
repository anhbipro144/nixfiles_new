{ pkgs, config, nixgl, ... }:

let nixglPkgs = nixgl.packages.${pkgs.system};
in {

  nixGL = {
    packages = nixglPkgs;
    defaultWrapper = "mesa";
  };

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.addons = with pkgs; [ fcitx5-unikey fcitx5-gtk ];
  };

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  home.sessionPath =
    [ "$HOME/personal/work" "$HOME/.volta/bin" "$HOME/.docker/completions" ];

  programs = {
    kitty = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.kitty;
      extraConfig = ''
        map ctrl+equal change_font_size all +1.0
        map ctrl+minus change_font_size all -1.0
        background_opacity 0.8
        confirm_os_window_close -1
        allow_remote_control yes
        listen_on unix:@mykitty
        shell_integration enabled
        # kitty-scrollback.nvim Kitten alias
        # action_alias kitty_scrollback_nvim kitten /home/neo/.local/share/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py --nvim-args --clean --noplugin -n

        action_alias kitty_scrollback_nvim kitten /home/neo/.local/share/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py --nvim-args -u ~/.config/ksb-nvim/init.lua -n

        # Browse scrollback buffer in nvim
        map kitty_mod+h kitty_scrollback_nvim
        # Browse output of the last shell command in nvim
        map kitty_mod+g kitty_scrollback_nvim --config ksb_builtin_last_cmd_output
        # Show clicked command output in nvim
        mouse_map ctrl+shift+right press ungrabbed combine : mouse_select_command_output : kitty_scrollback_nvim --config ksb_builtin_last_visited_cmd_output
      '';
    };

  };

}
