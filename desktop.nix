{ pkgs, config, ... }:

let
  nsgclientClean = pkgs.callPackage ./nsgclient-clean.nix { };
  figmaLinuxNext = pkgs.appimageTools.wrapType2 rec {
    pname = "figma-linux-next";
    version = "0.17.0";

    src = pkgs.fetchurl {
      url =
        "https://github.com/arximus88/figma-linux-next/releases/download/v${version}/figma-linux-next_${version}_linux_x86_64.AppImage";
      hash = "sha256-sX1pv9WgWVCXYhIQqcbA7yupFACqEdJUF/YZTEQydWY=";
    };
  };
  figmaLinuxNextWrapped = config.lib.nixGL.wrap figmaLinuxNext;
in {
  home.packages = [ nsgclientClean figmaLinuxNextWrapped ];

  xdg.desktopEntries.nsgclient = {
    name = "Citrix Secure Access";
    exec = "${nsgclientClean}/bin/nsgclient-clean %u";
    icon = "citrix-receiver";
    terminal = false;
    noDisplay = true;
    categories = [ "Network" "RemoteAccess" ];
    mimeType = [ "x-scheme-handler/application" "x-scheme-handler/citrixsso" ];
  };

  # Launch Writer with the profile that contains the LibreOffice MCP extension.
  # The profile remains user-managed because the extension installer mutates it.
  xdg.dataFile."applications/libreoffice-mcp.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Version=1.0
    Name=LibreOffice Writer (MCP)
    Exec=${config.home.profileDirectory}/bin/libreoffice -env:UserInstallation=file:///home/neo/.local/share/mcp-libre-lo-profile-v3 --writer %U
    Icon=libreoffice-writer
    Terminal=false
    Categories=Office;WordProcessor;
    MimeType=application/vnd.openxmlformats-officedocument.wordprocessingml.document;application/msword;application/vnd.oasis.opendocument.text;application/rtf;
    StartupNotify=true
  '';

  xdg.dataFile."applications/figma-linux-next.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Figma Linux Next
    Exec=${figmaLinuxNextWrapped}/bin/figma-linux-next %U
    Terminal=false
    Categories=Graphics;Development;
    MimeType=x-scheme-handler/figma;
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/http" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/https" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/application" = [ "nsgclient.desktop" ];
      "x-scheme-handler/citrixsso" = [ "nsgclient.desktop" ];
      "x-scheme-handler/figma" = [ "figma-linux-next.desktop" ];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "libreoffice-mcp.desktop" ];
      "application/msword" = [ "libreoffice-mcp.desktop" ];
      "application/vnd.oasis.opendocument.text" = [ "libreoffice-mcp.desktop" ];
      "application/rtf" = [ "libreoffice-mcp.desktop" ];
    };
  };

  # Desktop apps may replace this managed symlink when changing associations.
  # Keep the declarative MIME defaults authoritative on every activation.
  xdg.configFile."mimeapps.list".force = true;
}
