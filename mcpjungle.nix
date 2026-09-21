{ stdenvNoCC, fetchurl, lib }:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mcpjungle";
  version = "0.4.6";

  src = fetchurl {
    url = "https://github.com/mcpjungle/MCPJungle/releases/download/${finalAttrs.version}/mcpjungle_Linux_x86_64.tar.gz";
    hash = "sha256-ZOCtH0wkRX6SXxxTVkiyqHeZRoaLiBOlzbyPTthc7GU=";
  };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    install -Dm755 mcpjungle "$out/bin/mcpjungle"
  '';

  meta = {
    description = "Self-hosted MCP registry and Streamable HTTP gateway";
    homepage = "https://github.com/mcpjungle/MCPJungle";
    license = lib.licenses.mpl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "mcpjungle";
  };
})
