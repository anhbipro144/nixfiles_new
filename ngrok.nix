{ pkgs, ... }: {
  # NGROK_AUTHTOKEN is read from secrets/secrets.env (loaded by zsh), not from the Nix store.
  home.packages = [ pkgs.ngrok ];
}
