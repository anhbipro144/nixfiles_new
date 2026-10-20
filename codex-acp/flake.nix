{
  description = "codex-acp package flake";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { nixpkgs, ... }:
    let
      releases = {
        x86_64-linux = {
          version = "0.161.0";
          target = "x86_64-unknown-linux-musl";
          hash = "sha256-BNirnby53w7fPGfcpQcqN0ur/fdiqbxK5kmuFAuOLPA=";
        };
        aarch64-darwin = {
          version = "0.163.0";
          target = "aarch64-apple-darwin";
          hash = "sha256-sDRPwuQfFeAHEUflhpAIBHuP9L8sSoiXl107rj8QOzQ=";
        };
      };
      packages = nixpkgs.lib.genAttrs (builtins.attrNames releases) (system:
        let
          pkgs = import nixpkgs { inherit system; };
          release = releases.${system};

          codex = pkgs.stdenvNoCC.mkDerivation {
            pname = "codex";
            inherit (release) version;
            src = pkgs.fetchurl {
              url =
                "https://github.com/openai/codex/releases/download/rust-v${release.version}/codex-package-${release.target}.tar.gz";
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
            version = "2.2.2";

            src = pkgs.fetchFromGitHub {
              owner = "agentclientprotocol";
              repo = "codex-acp";
              rev = "v${version}";
              hash = "sha256-9qIKaDZJ80PVO7/qBfbOE7un2Ukk92bZVrIaHG/K8P8=";
            };

            npmDepsHash = "sha256-4wXnQnPEUp0DtNphXBS5/WQkgErRD631xOB0KqDXf4U=";

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
