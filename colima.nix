{ config, lib, pkgs, ... }:
let
  homeDir = config.home.homeDirectory;
  colimaHome = "${homeDir}/.colima";
  logDir = "${config.xdg.stateHome}/colima";
in {
  # Docker's Nix package includes the Compose and Buildx CLI plugins.
  home.packages = [ pkgs.colima pkgs.docker-client ];
  home.sessionVariables.COLIMA_HOME = colimaHome;

  home.activation.colimaLogDirectory =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg logDir}
    '' // { before = [ "setupLaunchAgents" ]; };

  # Pass settings on every supervised start; Colima must own its writable YAML.
  launchd.agents.colima = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.colima}/bin/colima"
        "start"
        "--foreground"
        "--save-config"
        "--runtime" "docker"
        "--arch" "aarch64"
        "--vm-type" "vz"
        "--mount-type" "virtiofs"
        "--cpus" "4"
        "--memory" "6"
        "--disk" "60"
        "--mount" "${homeDir}/persona:w"
        "--kubernetes=false"
        "--vz-rosetta=false"
        "--ssh-agent=false"
        "--ssh-config=false"
        "--activate"
      ];
      EnvironmentVariables = {
        HOME = homeDir;
        COLIMA_HOME = colimaHome;
        PATH = "${lib.makeBinPath [ pkgs.docker-client pkgs.coreutils ]}:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      WorkingDirectory = homeDir;
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      # Allow a clean VM shutdown when Home Manager unloads the agent.
      ExitTimeOut = 120;
      StandardOutPath = "${logDir}/stdout.log";
      StandardErrorPath = "${logDir}/stderr.log";
    };
  };
}
