{ config, lib, pkgs, ... }:
let
  cfg = config.programs.jevRouter;
  jevRouter = pkgs.callPackage ./packages/jev-router.nix { };
  proxyPort = 37374;
  proxyURL = "http://127.0.0.1:${toString proxyPort}";
  stateDir = "${config.home.homeDirectory}/.local/state/jev-router";
  environment = {
    JEV_CODEX_FAST_MODEL = cfg.codexModels.fast;
    JEV_CODEX_BALANCED_MODEL = cfg.codexModels.balanced;
    JEV_CODEX_STRONG_MODEL = cfg.codexModels.strong;
    JEV_CODEX_LONG_MODEL = cfg.codexModels.long;
    JEV_CODEX_FAST_EFFORT = cfg.codexEfforts.fast;
    JEV_CODEX_BALANCED_EFFORT = cfg.codexEfforts.balanced;
    JEV_CODEX_STRONG_EFFORT = cfg.codexEfforts.strong;
    JEV_CODEX_LONG_EFFORT = cfg.codexEfforts.long;
    JEV_DISABLE_TIERS = lib.concatStringsSep "," cfg.disabledTiers;
  };
  direct = pkgs.writeShellScriptBin "codex-direct" ''
    exec /usr/bin/env -u JEV_API_KEY -u TYPESAFE_API_KEY \
      ${lib.escapeShellArg "${config.home.profileDirectory}/bin/codex"} \
      --no-daemon --config 'model_provider="openai"' "$@"
  '';
  proxy = pkgs.writeShellScriptBin "jev-codex-proxy" ''
    exec ${pkgs.nodejs_24}/bin/node ${./scripts/jev-codex-proxy.mjs} \
      ${jevRouter}/lib/node_modules/@flaviusapop/jev-router \
      ${lib.escapeShellArg "${config.home.homeDirectory}/.config/home-manager/secrets/secrets.env"} \
      ${toString proxyPort}
  '';
  launcher = pkgs.writeShellScriptBin "jev-codex" ''
    set -o pipefail
    explicitModel=
    for arg in "$@"; do
      case "$arg" in
        -h|--help|-V|--version)
          exec /usr/bin/env -u JEV_API_KEY -u TYPESAFE_API_KEY \
            ${lib.escapeShellArg "${config.home.profileDirectory}/bin/codex"} "$@" ;;
        -m|--model|--model=*|-m?*) explicitModel=1 ;;
      esac
    done
    healthy() {
      ${pkgs.curl}/bin/curl --silent --fail --max-time 1 ${proxyURL}/_jev/health \
        | ${pkgs.jq}/bin/jq -e '.service == "jev-codex-proxy"' >/dev/null
    }
    if ! healthy; then
      /bin/launchctl kickstart "gui/$(/usr/bin/id -u)/org.nix-community.home.jev-codex-proxy" 2>/dev/null || true
      for attempt in {1..20}; do
        healthy && break
        /bin/sleep 0.1
      done
    fi
    if ! healthy; then
      echo '[jev] Local proxy unavailable. Use codex-direct to bypass Jev.' >&2
      exit 1
    fi
    if [ -z "$explicitModel" ]; then
      if ! ${pkgs.curl}/bin/curl --silent --fail --max-time 1 ${proxyURL}/_jev/health \
          | ${pkgs.jq}/bin/jq -e '.routing == true' >/dev/null; then
        echo '[jev] Routing key missing. Set JEV_API_KEY in your existing runtime env file, or use codex-direct.' >&2
        exit 1
      fi
      set -- --model jev-auto "$@"
    fi
    exec /usr/bin/env -u JEV_API_KEY -u TYPESAFE_API_KEY \
      ${lib.escapeShellArg "${config.home.profileDirectory}/bin/codex"} "$@"
  '';
in {
  options.programs.jevRouter = {
    codexModels = lib.mkOption {
      type = lib.types.submodule {
        options = lib.mapAttrs (_: model: lib.mkOption {
          type = lib.types.str;
          default = model;
        }) {
          fast = "gpt-6-luna";
          balanced = "gpt-6.1-sol";
          strong = "gpt-6.1-sol";
          long = "gpt-6.1-sol";
        };
      };
      default = { };
      description = "Codex model IDs used by Jev Router for each routing tier.";
    };

    codexEfforts = lib.mkOption {
      type = lib.types.submodule {
        options = lib.mapAttrs (_: effort: lib.mkOption {
          type = lib.types.enum [ "low" "medium" "high" "xhigh" "max" "ultra" ];
          default = effort;
        }) {
          fast = "low";
          balanced = "medium";
          strong = "high";
          long = "xhigh";
        };
      };
      default = { };
      description = "Reasoning effort sent to Codex for each routing tier.";
    };

    disabledTiers = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [ "haiku" "sonnet" "opus" "fable" ]);
      default = [ "fable" ];
      description = "Disabled Jev tiers; use an empty list to enable the long tier.";
    };
  };

  config = {
    home.packages = [ launcher direct ];
    programs.codex.settings = {
      model_provider = "jev";
      model_providers.jev = {
        name = "Jev Router";
        base_url = proxyURL;
        wire_api = "responses";
        requires_openai_auth = true;
        supports_websockets = false;
      };
    };
    home.activation.jevRouterState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg stateDir}
      run chmod 700 ${lib.escapeShellArg stateDir}
    '';
    launchd.agents.jev-codex-proxy = {
      enable = true;
      config = {
        ProgramArguments = [ "${proxy}/bin/jev-codex-proxy" ];
        EnvironmentVariables = environment // { JEV_DEBUG = ""; JEV_DUMP = ""; };
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 5;
        StandardOutPath = "${stateDir}/stdout.log";
        StandardErrorPath = "${stateDir}/stderr.log";
      };
    };
  };
}
