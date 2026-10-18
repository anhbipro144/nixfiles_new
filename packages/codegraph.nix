{ lib, stdenv, fetchurl, makeWrapper, autoPatchelfHook, coreutils, git }:
let
  releases = {
    x86_64-linux = {
      target = "linux-x64";
      hash = "sha256-7wr0FgkhKPsczHI3hgALft9KaXH+YErNCL+Wbk83uCg=";
    };
    aarch64-darwin = {
      target = "darwin-arm64";
      hash = "sha256-100b+0Bg22PsPCtyxOF/dsMZeK87rWrOQ3DRUBrAZi4=";
    };
  };
  release = releases.${stdenv.hostPlatform.system} or
    (throw "CodeGraph is packaged for x86_64-linux and aarch64-darwin only");
in stdenv.mkDerivation (finalAttrs: {
  pname = "codegraph";
  version = "1.6.2";

  src = fetchurl {
    url = "https://github.com/colbymchenry/codegraph/releases/download/v${finalAttrs.version}/codegraph-${release.target}.tar.gz";
    inherit (release) hash;
  };

  nativeBuildInputs = [ makeWrapper ]
    ++ lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
  buildInputs = lib.optional stdenv.hostPlatform.isLinux stdenv.cc.cc.lib;
  dontBuild = true;
  # Keep the complete upstream runtime, including Node's macOS code signature.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -a . "$out/"
    wrapProgram "$out/bin/codegraph" \
      --prefix PATH : ${lib.makeBinPath [ coreutils git ]} \
      --set CODEGRAPH_TELEMETRY 0 \
      --set CODEGRAPH_NO_UPDATE_CHECK 1 \
      --run 'for arg in "$@"; do
        case "$arg" in
          -*) ;;
          upgrade) echo "CodeGraph is managed by Nix; update packages/codegraph.nix and rebuild Home Manager." >&2; exit 1 ;;
          *) break ;;
        esac
      done'
    runHook postInstall
  '';

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR/check-home"
    mkdir -p "$HOME"
    test "$("$out/bin/codegraph" --version)" = "${finalAttrs.version}"
    CODEGRAPH_TELEMETRY=1 "$out/bin/codegraph" telemetry status > telemetry.txt
    grep -q 'Telemetry: disabled' telemetry.txt
    for option in --no-color --; do
      if "$out/bin/codegraph" "$option" upgrade ${finalAttrs.version} > upgrade.txt 2>&1; then
        echo "CodeGraph's imperative upgrade command must be disabled" >&2
        exit 1
      fi
      grep -q 'managed by Nix' upgrade.txt
    done
    runHook postInstallCheck
  '';

  meta = {
    description = "Local code intelligence and knowledge graph for coding agents";
    homepage = "https://github.com/colbymchenry/codegraph";
    license = lib.licenses.mit;
    platforms = builtins.attrNames releases;
    mainProgram = "codegraph";
  };
})
