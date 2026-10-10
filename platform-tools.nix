{ pkgs, ... }:
let isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in {
  home.packages = [
    (pkgs.writeShellScriptBin "clipboard-copy" (if isDarwin then ''
      exec /usr/bin/pbcopy "$@"
    '' else ''
      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        exec ${pkgs.wl-clipboard}/bin/wl-copy "$@"
      else
        exec ${pkgs.xclip}/bin/xclip -selection clipboard "$@"
      fi
    ''))
    (pkgs.writeShellScriptBin "clipboard-paste" (if isDarwin then ''
      exec /usr/bin/pbpaste "$@"
    '' else ''
      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        exec ${pkgs.wl-clipboard}/bin/wl-paste --no-newline "$@"
      else
        exec ${pkgs.xclip}/bin/xclip -selection clipboard -o "$@"
      fi
    ''))
    (pkgs.writeShellScriptBin "desktop-open" (if isDarwin then ''
      exec /usr/bin/open "$@"
    '' else ''
      exec ${pkgs.xdg-utils}/bin/xdg-open "$@"
    ''))
    (if isDarwin then
      pkgs.writeScriptBin "qute-menu" ''
        #!${pkgs.python3}/bin/python3
        ${builtins.readFile ./scripts/macos-menu.py}
      ''
    else
      pkgs.writeShellScriptBin "qute-menu" ''
        exec ${pkgs.rofi}/bin/rofi -dmenu "$@"
      '')
  ];
}
