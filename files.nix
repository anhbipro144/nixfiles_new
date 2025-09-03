{ ... }: {
  home.file.".config/nvim" = {
    # adjust path if your nvim dir is at repo root
    source = ./nvim;
    recursive = true;
  };
}
