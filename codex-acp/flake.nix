{
  description = "codex-acp package flake";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      codex-acp = pkgs.buildNpmPackage rec {
        pname = "codex-acp";
        version = "1.12.0";

        src = pkgs.fetchFromGitHub {
          owner = "agentclientprotocol";
          repo = "codex-acp";
          rev = "v${version}";
          hash = "sha256-GIMJm+kifPEMb7XLPSssUu87eEE+aaBr2jZUk8aPD2s=";
        };

        npmDepsHash = "sha256-BeRj6LpIpGV4ONEHE//nYXTfkB1nfVQpPeJF3LRlyRM=";

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
