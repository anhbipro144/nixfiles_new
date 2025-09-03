{ pkgs, config, nixgl, ... }:

let nixglPkgs = nixgl.packages.${pkgs.system};
in {

  nixGL = {
    packages = nixglPkgs;
    defaultWrapper = "mesa";
  };

  programs = {
    kitty = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.kitty;
      extraConfig = ''
        background_opacity 0.8
        confirm_os_window_close -1
      '';
    };

  };

}
