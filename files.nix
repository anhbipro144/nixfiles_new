{ ... }: {
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };

  home.file.".config/nvim-minimal" = {
    source = ./nvim-vm;
    recursive = true;
  };
}



