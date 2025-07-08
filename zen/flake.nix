{
  description = "Zen-Browser flake (x86_64-linux)";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; };

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      zen = pkgs.stdenv.mkDerivation {
        pname = "zen-browser";
        version = "1.13b";

        src = pkgs.fetchurl {
          url =
            "https://github.com/zen-browser/desktop/releases/download/1.13b/zen.linux-x86_64.tar.xz";
          # run `nix-prefetch-url <url>` to fill in the sha256
          sha256 = "14d0icbhb3lgdsjgbv3j0ynmhp62xwllc38rjcf9f37dhsb5yx72";
        };

        nativeBuildInputs = [ pkgs.makeWrapper ];

        unpackPhase = "true"; # we’ll unpack by hand in installPhase

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
