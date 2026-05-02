{ ... }: {

  home.file = {
    ".config/kitty/themes".source = ./kitty/themes;
    ".config/nvim" = {
      source = ./nvim;
      recursive = true;
    };

    ".config/qutebrowser/config.py".source = ./qutebrowser/config.py;

    ".config/nvim-minimal" = {
      source = ./nvim-vm;
      recursive = true;
    };
    ".config/macchina" = { source = ./macchina; };
    ".config/jiratui" = { source = ./jiratui; };
  };

}
