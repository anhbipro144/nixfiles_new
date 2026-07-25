{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    codex-nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-neovim.url =
      "github:nixos/nixpkgs/27f6bed89e3b18ad1a53505daf493ce2deaf345a";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen.url = "path:./zen";
    uniclipboard = {
      url = "path:./uniclipboard";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-acp = {
      url = "path:./codex-acp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { nixpkgs, codex-nixpkgs, nixpkgs-neovim, home-manager, zen
    , uniclipboard, codex-acp, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixgl.overlays.default ];
      };
      neovimPkgs = import nixpkgs-neovim { inherit system; };
      codexPackage = codex-nixpkgs.legacyPackages.${system}.codex;

      zenBrowser = zen.packages.${system}.zen-browser;
      uniclipboardPackage = uniclipboard.packages.${system}.default;
      codexAcpPackage = codex-acp.packages.${system}.default;

      mkHome =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit neovimPkgs zenBrowser nixgl codexAcpPackage codexPackage;
          };
          modules = [
            ./base.nix
            ./files.nix
            ./packages.nix
            ./common.nix
            ./main.nix
            ({ ... }: { home.packages = [ uniclipboardPackage ]; })
          ];
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
      homeConfigurations."neo@main" = mkHome;
    };
}
