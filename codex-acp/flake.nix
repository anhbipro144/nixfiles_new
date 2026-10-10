{
  description = "codex-acp package flake";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { nixpkgs, ... }:
    let
      releases = {
        x86_64-linux = {
          target = "x86_64-unknown-linux-musl";
          hash = "sha256-BNirnby53w7fPGfcpQcqN0ur/fdiqbxK5kmuFAuOLPA=";
        };
        aarch64-darwin = {
          target = "aarch64-apple-darwin";
          hash = "sha256-8P7uhTfa+N1rTgo252RUmtFK/btBnYd1rquf6yAYIxM=";
        };
      };
      packages = nixpkgs.lib.genAttrs (builtins.attrNames releases) (system:
        let
          pkgs = import nixpkgs { inherit system; };
          release = releases.${system};

          codex = pkgs.stdenvNoCC.mkDerivation {
            pname = "codex";
            version = "0.161.0";
            src = pkgs.fetchurl {
              url =
                "https://github.com/openai/codex/releases/download/rust-v0.161.0/codex-package-${release.target}.tar.gz";
              inherit (release) hash;
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
              platforms = builtins.attrNames releases;
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
              platforms = builtins.attrNames releases;
            };
          };
        in {
          default = codex-acp;
          codex-acp = codex-acp;
          codex = codex;
        });
    in { inherit packages; };
}
