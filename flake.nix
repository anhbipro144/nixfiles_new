{
  description = "Home Manager configuration";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen.url = "path:./zen";
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { nixpkgs, home-manager, zen, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          nixgl.overlay
          (final: prev: {
            kitty = prev.writeShellScriptBin "kitty" ''
              exec ${final.nixgl.nixGLIntel}/bin/nixGLIntel ${prev.kitty}/bin/kitty "$@"
            '';
          })
        ];
      };

      zenBrowser = zen.packages.${system}.zen-browser;
    in {
      homeConfigurations."neo" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = { inherit zenBrowser nixgl; };
        modules = [ ./home.nix ];

      };
    };
}
