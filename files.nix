{ ... }: {

  home.file = {
    ".config/kitty/themes".source = ./kitty/themes;
    ".config/nvim" = {
      source = ./nvim;
      recursive = true;
    };
  };

  home.file.".config/nvim-minimal" = {
    source = ./nvim-vm;
    recursive = true;
  };

  home.file.".config/macchina" = { source = ./macchina; };
}

