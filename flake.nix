{
  description = "Home Manager configuration";

  inputs = {
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
        overlays = [ nixgl.overlays.default ];
      };

      zenBrowser = zen.packages.${system}.zen-browser;

      mkHome = host:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit zenBrowser nixgl host; };
          modules =
            ([ ./base.nix ./files.nix ./packages.nix ./common.nix ./main.nix ]

              ++ (if host == "main" then
                [ ./modules/programs/main.nix ]
              else
                [ ])
              ++ (if host == "vm" then [ ./modules/programs/vm.nix ] else [ ]));
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
      homeConfigurations."neo@main" = mkHome "main";
      homeConfigurations."neo@vm" = mkHome "vm";
    };
}
