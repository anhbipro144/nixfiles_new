{ ... }: {
  home.file.".config/nvim" = {
    # adjust path if your nvim dir is at repo root
    source = ./nvim;
    recursive = true;
  };

  home.file.".config/nvim-minimal" = {
    source = ./nvim-vm;
    recursive = true;
  };
}
