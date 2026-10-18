{ lib, stdenvNoCC, fetchurl, makeWrapper, nodejs_24, git, coreutils }:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hindsight-coding-agents";
  version = "0.8.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/@vectorize-io/hindsight-coding-agents/-/hindsight-coding-agents-${finalAttrs.version}.tgz";
    hash = "sha256-QHq9ZrpdRgOkYOz+Z5XUeg4Gh0OagA1Lx5MF8u4vXhs=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  postPatch = ''
    for script in dist/*.js; do
      if grep -qF 'autoUpdate: raw.autoUpdate ?? true' "$script"; then
        # File/per-bank settings override env vars upstream; enforce Nix ownership last.
        substituteInPlace "$script" --replace-fail \
          'autoUpdate: raw.autoUpdate ?? true' 'autoUpdate: false'
        # An unconfigured machine must not silently send sessions to the Cloud default.
        substituteInPlace "$script" --replace-fail \
          'const raw = applyLayer(withEnv, readRaw(o.path ?? CONFIG_PATH), o.harness);' \
          'const fileConfig = readRaw(o.path ?? CONFIG_PATH);
  const raw = applyLayer(withEnv, fileConfig, o.harness);
  if (!Object.keys(fileConfig).length && !raw.serverMode && !raw.apiUrl && !raw.apiToken) raw.disabled = true;'
      fi
      if grep -qF 'if (!preflightDaemon(cfg, harness)) return;' "$script"; then
        # Reuse a healthy existing daemon, but never bootstrap uvx/Python at runtime.
        substituteInPlace "$script" --replace-fail \
          'if (!preflightDaemon(cfg, harness)) return;' \
          'throw new Error("Nix-managed Hindsight requires an already-running backend; automatic daemon installation is disabled.");'
      fi
      if grep -qF '    syncCompanionSkill(harness);' "$script"; then
        # Codex's skill belongs to Home Manager; do not rewrite a shared Copilot skill.
        substituteInPlace "$script" --replace-fail \
          '    syncCompanionSkill(harness);' \
          '    if (harness !== "codex") syncCompanionSkill(harness);'
      fi
    done
  '';

  installPhase = ''
    runHook preInstall
    runtime="$out/lib/hindsight-coding-agents"
    mkdir -p "$runtime" "$out/bin"
    cp -a . "$runtime/"
    for entry in codex-sessionstart-hook codex-hook codex-stop-hook mcp-server; do
      makeWrapper ${nodejs_24}/bin/node "$out/bin/hindsight-$entry" \
        --add-flags "$runtime/dist/$entry.js" \
        --prefix PATH : ${lib.makeBinPath [ nodejs_24 git coreutils ]} \
        --set HINDSIGHT_AUTO_UPDATE false
    done
    # Expose diagnostics and version, without exposing the imperative installer/updater.
    cat > "$out/bin/hindsight-coding-agents" <<EOF
    #!${stdenvNoCC.shell}
    case "\''${1:---help}" in
      --version|version) echo ${finalAttrs.version} ;;
      status) shift; exec "$out/bin/hindsight-status" "\$@" ;;
      --help|-h) echo 'Usage: hindsight-coding-agents --version | status' ;;
      *) echo 'Hindsight is managed by Nix; update its package and rebuild Home Manager.' >&2; exit 1 ;;
    esac
    EOF
    chmod +x "$out/bin/hindsight-coding-agents"
    makeWrapper ${nodejs_24}/bin/node "$out/bin/hindsight-status" \
      --add-flags "$runtime/dist/status.js" \
      --prefix PATH : ${lib.makeBinPath [ nodejs_24 git coreutils ]} \
      --set HINDSIGHT_AUTO_UPDATE false
    runHook postInstall
  '';

  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$("$out/bin/hindsight-coding-agents" --version)" = "${finalAttrs.version}"
    for entry in codex-sessionstart-hook codex-hook codex-stop-hook mcp-server; do
      ${nodejs_24}/bin/node --check "$out/lib/hindsight-coding-agents/dist/$entry.js"
    done
    if "$out/bin/hindsight-coding-agents" update > update.txt 2>&1; then
      echo 'Imperative updates must be disabled' >&2
      exit 1
    fi
    grep -q 'managed by Nix' update.txt
    runHook postInstallCheck
  '';

  meta = {
    description = "Official Hindsight Coding Agents runtime with Nix-managed updates";
    homepage = "https://github.com/vectorize-io/hindsight/tree/main/hindsight-integrations/coding-agents";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" "aarch64-darwin" ];
    mainProgram = "hindsight-coding-agents";
  };
})
