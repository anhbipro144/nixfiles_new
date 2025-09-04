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
    FPATH = "$HOME/.docker/completions:$FPATH";
  };

  programs = {
    neovim.enable = true;
    kitty = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.kitty;
      extraConfig = ''
        map ctrl+equal change_font_size all +1.0
        map ctrl+minus change_font_size all -1.0
        background_opacity 0.8
        confirm_os_window_close -1
      '';
    };

  };

}
