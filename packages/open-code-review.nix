{ lib, stdenv, fetchurl }:
let
  releases = {
    x86_64-linux = {
      target = "linux-amd64";
      hash = "sha256-OoJIuVkXeBT8OKGmu4d0KYUQPoOb/kWC2XrjDZad2RM=";
    };
    aarch64-darwin = {
      target = "darwin-arm64";
      hash = "sha256-CBPI1BMJ4AAYwoyUppeSgN+1P66AXMkn3w9TCUHTeLU=";
    };
  };
  release = releases.${stdenv.hostPlatform.system} or
    (throw "open-code-review is packaged for x86_64-linux and aarch64-darwin only");
in stdenv.mkDerivation (finalAttrs: {
  pname = "open-code-review";
  version = "1.13.1";

  src = fetchurl {
    url = "https://github.com/alibaba/open-code-review/releases/download/v${finalAttrs.version}/opencodereview-${release.target}";
    inherit (release) hash;
  };

  dontUnpack = true;
  dontBuild = true;
  # Static Go binary; stripping would invalidate the macOS code signature.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/ocr"
    runHook postInstall
  '';

  meta = {
    description = "AI-powered code review CLI";
    homepage = "https://github.com/alibaba/open-code-review";
    mainProgram = "ocr";
    platforms = builtins.attrNames releases;
  };
})
