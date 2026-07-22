{
  description = "codex-acp package flake";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      codex-acp = pkgs.buildNpmPackage rec {
        pname = "codex-acp";
        version = "1.1.5";

        src = pkgs.fetchFromGitHub {
          owner = "agentclientprotocol";
          repo = "codex-acp";
          rev = "v${version}";
          hash = "sha256-5vB/TxxS25F5OPh39Z+6Ofr8Xqdu4gQpwEhMWE1+DiQ=";
        };

        npmDepsHash = "sha256-AJ76gUBYuxMrSpnTI0ix9SOBRv4Q/pcTUNdPYnIWRIM=";

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
