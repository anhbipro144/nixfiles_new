{ pkgs, nixgl, ... }:
let nixglPkgs = nixgl.packages.${pkgs.system};
in {
  home.username = "neo";
  home.homeDirectory = "/home/neo";
  home.stateVersion = "25.05";

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
}
