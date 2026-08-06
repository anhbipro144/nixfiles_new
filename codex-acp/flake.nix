{
  description = "codex-acp package flake";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      codex-acp = pkgs.buildNpmPackage rec {
        pname = "codex-acp";
        version = "1.1.9";

        src = pkgs.fetchFromGitHub {
          owner = "agentclientprotocol";
          repo = "codex-acp";
          rev = "v${version}";
          hash = "sha256-c8Sgj9XNDAO25UOa+vEy619mSi3tG3NJHbKnV1QzOo8=";
        };

        npmDepsHash = "sha256-MsP8g4X4yX/K8nwNieQdgGaJfAf8FOc0D3OCypTx+w0=";

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
