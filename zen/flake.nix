{
  description = "Zen-Browser flake (x86_64-linux)";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; };

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      zen = pkgs.stdenv.mkDerivation {
        pname = "zen-browser";
        version = "1.23b";

        src = pkgs.fetchurl {
          url =
            "https://github.com/zen-browser/desktop/releases/download/1.23b/zen.linux-x86_64.tar.xz";
          sha256 = "1w7wnf0n107s76vpjkwrpnh4x4rmf8idx1q739gvhq1aym89zmws";
        };

        nativeBuildInputs = [ pkgs.makeWrapper ];

        unpackPhase = "true";

        installPhase = ''
              mkdir -p $out/{bin,share/zen-browser,share/applications,share/icons/hicolor/128x128/apps}
                                tar -xJf $src -C $out/share/zen-browser --strip-components=1

                                ln -s $out/share/zen-browser/zen $out/bin/zen-browser


                      install -D \
                        $out/share/zen-browser/browser/chrome/icons/default/default128.png \
                        $out/share/icons/hicolor/128x128/apps/zen.png

            cat > $out/share/applications/zen-browser.desktop <<-EOF
          [Desktop Entry]
          Version=1.0
          Type=Application
          Name=Zen
          Comment=A calmer, privacy-focused browser
          Exec=$out/bin/zen-browser %U
          Icon=$out/share/icons/hicolor/128x128/apps/zen.png
          Terminal=false
          Categories=Network;WebBrowser;
          StartupNotify=true
          EOF

        '';
      };
    in { packages.${system}.zen-browser = zen; };
}
