{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-neovim.url =
      "github:nixos/nixpkgs/27f6bed89e3b18ad1a53505daf493ce2deaf345a";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen.url = "path:./zen";
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { nixpkgs, nixpkgs-neovim, home-manager, zen, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixgl.overlays.default ];
      };
      neovimPkgs = import nixpkgs-neovim { inherit system; };

      zenBrowser = zen.packages.${system}.zen-browser;

      mkHome = { host, user }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit neovimPkgs zenBrowser nixgl host user; };
          modules = ([ ./base.nix ./files.nix ./packages.nix ./common.nix ]

            ++ (if host == "main" then [ ./main.nix ] else [ ])
            ++ (if host == "vm" then [ ./vm.nix ] else [ ]));
        };
    in {
      # homeConfigurations."neo" = home-manager.lib.homeManagerConfiguration {
      #   inherit pkgs;
      #
      #   # Optionally use extraSpecialArgs
      #   # to pass through arguments to home.nix
      #   extraSpecialArgs = { inherit zenBrowser nixgl; };
      #   modules = [ ./home.nix ];
      #
      # };
      homeConfigurations."neo@main" = mkHome {
        host = "main";
        user = "neo";
      };
      homeConfigurations."ubuntu@vm" = mkHome {
        host = "vm";
        user = "ubuntu";
      };
    };
}
