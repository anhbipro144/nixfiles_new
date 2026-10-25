{ lib, stdenvNoCC, fetchurl, unzip }:
let
  version = "0.0.18";
  releases = {
    aarch64-darwin = {
      archive = "darwin-arm64";
      hash = "sha256-unoJlPfdFbyHCKoWAuz1Q3GkkjGaZBq5wz3ADx/Va/4=";
    };
    x86_64-linux = {
      archive = "linux-amd64";
      hash = "sha256-PIIwcxas2TyIo4S2KvHYHT9MsO+pdfnAv675IoZqBMQ=";
    };
  };
  release = releases.${stdenvNoCC.hostPlatform.system};
in stdenvNoCC.mkDerivation {
  pname = "tunnel-client";
  inherit version;

  src = fetchurl {
    url = "https://github.com/openai/tunnel-client/releases/download/v${version}/tunnel-client-v${version}-${release.archive}.zip";
    inherit (release) hash;
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" unpacked
    ${unzip}/bin/unzip -q "$src" -d unpacked
    binary=$(find unpacked -type f -name tunnel-client -print -quit)
    test -n "$binary"
    install -m755 "$binary" "$out/bin/tunnel-client"
    mkdir -p "$out/share/licenses/tunnel-client"
    for document in LICENSE NOTICE; do
      file=$(find unpacked -type f -name "$document" -print -quit)
      if [ -n "$file" ]; then
        install -m644 "$file" "$out/share/licenses/tunnel-client/$document"
      fi
    done
    runHook postInstall
  '';

  meta = {
    description = "OpenAI Secure MCP Tunnel client";
    homepage = "https://github.com/openai/tunnel-client";
    license = lib.licenses.asl20;
    platforms = builtins.attrNames releases;
    mainProgram = "tunnel-client";
  };
}
