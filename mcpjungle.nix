{ stdenvNoCC, fetchurl, lib }:
let
  releases = {
    x86_64-linux = {
      archive = "Linux_x86_64";
      hash = "sha256-ZOCtH0wkRX6SXxxTVkiyqHeZRoaLiBOlzbyPTthc7GU=";
    };
    aarch64-darwin = {
      archive = "Darwin_arm64";
      hash = "sha256-SbWehUIEuv/W7MkBSwJMPjToiZ2BM11zq0j2o1j/AFk=";
    };
  };
  release = releases.${stdenvNoCC.hostPlatform.system};

in stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mcpjungle";
  version = "0.4.6";

  src = fetchurl {
    url =
      "https://github.com/mcpjungle/MCPJungle/releases/download/${finalAttrs.version}/mcpjungle_${release.archive}.tar.gz";
    inherit (release) hash;
  };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/bin"
    install -m755 mcpjungle "$out/bin/mcpjungle"
  '';

  meta = {
    description = "Self-hosted MCP registry and Streamable HTTP gateway";
    homepage = "https://github.com/mcpjungle/MCPJungle";
    license = lib.licenses.mpl20;
    platforms = builtins.attrNames releases;
    mainProgram = "mcpjungle";
  };
})
