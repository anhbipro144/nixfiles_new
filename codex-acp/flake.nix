{
  description = "codex-acp package flake";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      codex = pkgs.stdenvNoCC.mkDerivation {
        pname = "codex";
        version = "0.161.0";
        src = pkgs.fetchurl {
          url = "https://github.com/openai/codex/releases/download/rust-v0.161.0/codex-package-x86_64-unknown-linux-musl.tar.gz";
          hash = "sha256-BNirnby53w7fPGfcpQcqN0ur/fdiqbxK5kmuFAuOLPA=";
        };
        dontUnpack = true;
        installPhase = ''
          mkdir -p "$out"
          tar -xzf "$src" -C "$out"
        '';
        meta = {
          description = "OpenAI Codex CLI";
          homepage = "https://github.com/openai/codex";
          mainProgram = "codex";
          platforms = [ "x86_64-linux" ];
        };
      };

      codex-acp = pkgs.buildNpmPackage rec {
        pname = "codex-acp";
        version = "2.0.1";

        src = pkgs.fetchFromGitHub {
          owner = "agentclientprotocol";
          repo = "codex-acp";
          rev = "v${version}";
          hash = "sha256-nwBRPKofGb0MysC+3pTL6iGidTkabc2foJzucot6FGE=";
        };

        npmDepsHash = "sha256-5w4CVDA6zu33e6f1OssboxwHvpmp+BoEDjJJxXlsKVk=";

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
        codex = codex;
      };
    };
}
