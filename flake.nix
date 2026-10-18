{
  description = "Home Manager configuration for Linux and macOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-neovim.url = "github:nixos/nixpkgs/nixos-unstable";
    # Zotero 10.0.4 requires Firefox ESR 140.15.0, removed from current nixpkgs.
    nixpkgs-zotero.url = "github:nixos/nixpkgs/eaad089433ca2bb662274377d33df3d0e51ef28b";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen.url = "path:./zen";
    uniclipboard = {
      url = "path:./uniclipboard";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codexAcp = {
      url = "path:./codex-acp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { nixpkgs, nixpkgs-neovim, nixpkgs-zotero, home-manager, zen, uniclipboard, codexAcp
    , nixgl, ... }:
    let
      mkHome = { system, name, username ? "neo" }:
        let
          isLinux = nixpkgs.lib.hasSuffix "-linux" system;
          pkgs = import nixpkgs {
            inherit system;
            overlays = nixpkgs.lib.optional isLinux nixgl.overlays.default;
          };
        in home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            neovimPkgs = import nixpkgs-neovim { inherit system; };
            homeTarget = name;
          } // nixpkgs.lib.optionalAttrs isLinux {
            inherit nixgl;
            zoteroFirefox = (import nixpkgs-zotero { inherit system; }).firefox-esr-140-unwrapped;
            zenBrowser = zen.packages.${system}.zen-browser;
          };
          modules = [
            ./base.nix
            ./files.nix
            ./packages.nix
            ./common.nix
            ./main.nix
            ./codex.nix
            ./copilot.nix
            ./platform-tools.nix
            (if isLinux then ./linux.nix else ./macos.nix)
            {
              home.username = username;
              home.homeDirectory =
                "${if isLinux then "/home" else "/Users"}/${username}";
              home.packages = [
                codexAcp.packages.${system}.default
                codexAcp.packages.${system}.codex
              ] ++ nixpkgs.lib.optional isLinux
                uniclipboard.packages.${system}.default;
            }
          ];
        };
    in {
      homeConfigurations."neo@main" = mkHome {
        system = "x86_64-linux";
        name = "neo@main";
      };
      homeConfigurations."neo@mac" = mkHome {
        system = "aarch64-darwin";
        name = "neo@mac";
      };
    };
}
