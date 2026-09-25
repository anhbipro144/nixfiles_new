{
  description = "codex-acp package flake";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      codex-acp = pkgs.buildNpmPackage rec {
        pname = "codex-acp";
        version = "1.13.1";

        src = pkgs.fetchFromGitHub {
          owner = "agentclientprotocol";
          repo = "codex-acp";
          rev = "v${version}";
          hash = "sha256-lVsj8RqE8XwCblOBSk3B4Nckx4h1o1BHMRrmpkhrIEw=";
        };

        npmDepsHash = "sha256-jXXvfg2bPZlvkNBZUw3ptpoOy9wOcvl2B8J0HnpX79c=";

        meta = {
          description = "ACP adapter for Codex CLI";
          homepage = "https://github.com/agentclientprotocol/codex-acp";
          license = pkgs.lib.licenses.asl20;
          mainProgram = "codex-acp";
          platforms = pkgs.lib.platforms.linux;
        };
      };
    in {
      packages.${system} = {
        default = codex-acp;
        codex-acp = codex-acp;
      };
    };
}
