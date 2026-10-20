{ pkgs, ... }: {
  # NGROK_AUTHTOKEN is read from secrets/secrets.env (loaded by zsh), not from the Nix store.
  home.packages = [ pkgs.ngrok ];

  home.file."${if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else ".config"}/ngrok/ngrok.yml".text = ''
    version: "3"
    agent:
      console_ui_color: transparent
  '';
}
