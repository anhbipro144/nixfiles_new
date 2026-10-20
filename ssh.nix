{ config, lib, pkgs, ... }:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  homeSsh = "${config.home.homeDirectory}/.ssh";
in {
  age = lib.mkIf isLinux {
    identityPaths = [ "${config.home.homeDirectory}/.config/agenix/identity" ];
    secrets = {
      ssh_neo_ONE_key = {
        file = ./secrets/ssh/neo_ONE_key.age;
        path = "${homeSsh}/neo_ONE_key";
        mode = "0400";
      };
      ssh_neo_personal_key = {
        file = ./secrets/ssh/neo_personal_key.age;
        path = "${homeSsh}/neo_personal_key";
        mode = "0400";
      };
      ssh_neo_ubuntu_pem = {
        file = ./secrets/ssh/neo_ubuntu.pem.age;
        path = "${homeSsh}/neo_ubuntu.pem";
        mode = "0400";
      };
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ForwardAgent = false;
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
      };
    } // lib.optionalAttrs isLinux {
      homelab = {
        HostName = "100.106.118.50";
        User = "neo";
        IdentityFile = "${homeSsh}/neo_ONE_key";
        IdentitiesOnly = true;
      };
      "github.com-personal" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "${homeSsh}/neo_ONE_key";
        IdentitiesOnly = true;
      };
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "${homeSsh}/neo_personal_key";
        IdentitiesOnly = true;
      };
    } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      homelab = {
        HostName = "100.106.118.50";
        User = "neo";
        IdentityFile = "${homeSsh}/neo_mac_one";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
        IgnoreUnknown = "UseKeychain";
        UseKeychain = true;
      };
      "github.com-personal" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "${homeSsh}/neo_mac";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
        IgnoreUnknown = "UseKeychain";
        UseKeychain = true;
      };
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "${homeSsh}/neo_mac_one";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
        IgnoreUnknown = "UseKeychain";
        UseKeychain = true;
      };
    };
  };

  home.activation.sshDirectoryPermissions = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    run mkdir -p ${lib.escapeShellArg homeSsh}
    run chmod 700 ${lib.escapeShellArg homeSsh}
  '';
}
