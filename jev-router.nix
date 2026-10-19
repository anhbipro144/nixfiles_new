{ config, lib, pkgs, ... }:
let
  cfg = config.programs.jevRouter;
  jevRouter = pkgs.callPackage ./packages/jev-router.nix { };
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
  exports = lib.concatStringsSep "\n" (lib.mapAttrsToList
    (variable: value: ''
      if [ "''${${variable}+set}" != set ]; then
        export ${variable}=${lib.escapeShellArg value}
      fi'')
    environment);
  codexShim = pkgs.writeShellScriptBin "codex" ''
    exec /usr/bin/env -u JEV_API_KEY -u TYPESAFE_API_KEY \
      ${lib.escapeShellArg "${config.home.profileDirectory}/bin/codex"} "$@"
  '';
  launcher = pkgs.writeShellScriptBin "jev-codex" ''
    ${exports}
    # Empty values also prevent upstream dotenv loading from enabling request dumps.
    export JEV_DEBUG= JEV_DUMP=
    PATH=${lib.escapeShellArg "${codexShim}/bin"}:${lib.escapeShellArg "${config.home.profileDirectory}/bin"}:"$PATH"
    export PATH
    exec ${jevRouter}/bin/jev-codex "$@"
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
    home.packages = [ launcher ];
  };
}
