{ buildGoModule, fetchFromGitHub }:

# Keep the upstream MCP interface, but avoid eagerly opening every file when
# typescript-language-server registers workspace watchers.
buildGoModule {
  pname = "mcp-language-server-lazy";
  version = "0.1.1-lazy-open";

  src = fetchFromGitHub {
    owner = "isaacphi";
    repo = "mcp-language-server";
    rev = "46e2950b7969334780675e7797e13f140d2d42ac";
    hash = "sha256-T0wuPSShJqVW+CcQHQuZnh3JOwqUxAKv1OCHwZMr7KM=";
  };

  vendorHash = "sha256-3NEG9o5AF2ZEFWkA9Gub8vn6DNptN6DwVcn/oR8ujW0=";
  subPackages = [ "." ];
  patches = [ ./patches/mcp-language-server-lazy-open.patch ];

  postInstall = ''
    mv "$out/bin/mcp-language-server" "$out/bin/mcp-language-server-lazy"
  '';
}
