{ pkgs, lib, ... }:
let
  passWithOtp = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
  qutePassPython = pkgs.python3.withPackages (ps: [ ps.tldextract ]);
  qutePassRuntimePath = lib.makeBinPath [
    passWithOtp
    pkgs.gnupg
    pkgs.rofi
  ];
in {

  home.file = {
    ".config/kitty/themes".source = ./kitty/themes;
    ".config/nvim" = {
      source = ./nvim;
      recursive = true;
    };

    ".config/qutebrowser/config.py".source = ./qutebrowser/config.py;

    ".local/share/qutebrowser/userscripts/qute-pass" = {
      executable = true;
      text = ''
        #!${qutePassPython}/bin/python3
        import os
        import runpy

        os.environ["PATH"] = "${qutePassRuntimePath}:" + os.environ.get("PATH", "")
        runpy.run_path(
            "${pkgs.qutebrowser}/share/qutebrowser/userscripts/qute-pass",
            run_name="__main__",
        )
      '';
    };

    ".config/nvim-minimal" = {
      source = ./nvim-vm;
      recursive = true;
    };
    ".config/macchina" = { source = ./macchina; };
    ".config/jiratui" = { source = ./jiratui; };
  };

}
