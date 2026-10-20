{ lib, buildNpmPackage, fetchFromGitHub, nodejs_24 }:

buildNpmPackage {
  pname = "jev-router";
  version = "1.0.0-0ada4f8";

  src = fetchFromGitHub {
    owner = "flaviusapop";
    repo = "jev-router";
    rev = "0ada4f883127ea9e5cd0e00521b442ce804b17c9";
    hash = "sha256-+YE8nNmRoXCHdANLMPoR2fIQo/mx3bAxWQv5Y+OwMAE=";
  };

  nodejs = nodejs_24;
  patches = [ ./jev-router-shared-proxy.patch ];
  npmDepsHash = "sha256-swwrAAD/9AyfzOgHRZuIPoOwXEXjg8K1YaVtCKMP+xc=";
  dontNpmBuild = true;
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    npm test
    runHook postCheck
  '';

  meta = {
    description = "Per-turn model and reasoning-effort routing for Codex using TypeSafe Jev";
    homepage = "https://github.com/flaviusapop/jev-router";
    license = lib.licenses.mit;
    mainProgram = "jev-codex";
    platforms = [ "aarch64-darwin" ];
  };
}
