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
    nvim-mcp.url = "github:linw1995/nvim-mcp";
  };

  outputs = { nixpkgs, codex-nixpkgs, nixpkgs-neovim, home-manager, zen
    , uniclipboard, codex-acp, nixgl, nvim-mcp, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixgl.overlays.default ];
      };
      neovimPkgs = import nixpkgs-neovim { inherit system; };
      codexPackage = codex-nixpkgs.legacyPackages.${system}.codex;

      zenBrowser = zen.packages.${system}.zen-browser;
      nvimMcp = nvim-mcp.packages.${system}.default;
      uniclipboardPackage = uniclipboard.packages.${system}.default;
      codexAcpPackage = codex-acp.packages.${system}.default;

      mkHome = { host, user }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit neovimPkgs zenBrowser nixgl nvimMcp codexAcpPackage
              codexPackage host user;
          };
          modules = ([ ./base.nix ./files.nix ./packages.nix ./common.nix ]

            ++ (if host == "main" then [
              ./main.nix
              ({ ... }: { home.packages = [ uniclipboardPackage ]; })
            ] else
              [ ]) ++ (if host == "vm" then [ ./vm.nix ] else [ ]));
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
