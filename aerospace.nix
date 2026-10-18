{ lib, pkgs, config, ... }:
let
  workspaces = map toString (lib.range 1 19);
  workspaceOrder = lib.concatStringsSep " " workspaces;
  flameshotApp = "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/flameshot.app";
  flameshotLauncher = pkgs.writeText "flameshot-launch.js" ''
    ObjC.import('AppKit');
    function run(argv) {
      if (argv[0] === 'activate') {
        var app = $.NSRunningApplication.runningApplicationWithProcessIdentifier(Number(argv[1]));
        if (app && !app.isNil() && !app.terminated) app.activateWithOptions(3);
        return;
      }
      var error = Ref();
      var app = $.NSWorkspace.sharedWorkspace.launchApplicationAtURLOptionsConfigurationError(
        $.NSURL.fileURLWithPath(argv[1]),
        $.NSWorkspaceLaunchNewInstance,
        $({NSWorkspaceLaunchConfigurationArguments: ['gui']}),
        error
      );
      if (!app || app.isNil()) throw new Error('Could not launch Flameshot');
      return String(app.processIdentifier);
    }
  '';
  flameshotCapture = pkgs.writeShellScript "flameshot-capture" ''
    set -eu
    # Activate after the launch call returns: the accessory app can otherwise
    # leave its capture overlay hidden and keep the capture lock held.
    capture_pid=$(/usr/bin/osascript -l JavaScript ${flameshotLauncher} launch ${lib.escapeShellArg flameshotApp})
    /bin/sleep 0.3
    /usr/bin/osascript -l JavaScript ${flameshotLauncher} activate "$capture_pid"
  '';
  binding = name: value: { inherit name value; };
  directions = {
    h = "left";
    j = "down";
    k = "up";
    l = "right";
    left = "left";
    down = "down";
    up = "up";
    right = "right";
  };

  directionBindings = lib.concatLists (lib.mapAttrsToList (key: direction: [
    (binding "alt-${key}" "focus ${direction}")
    (binding "alt-shift-${key}" "move ${direction}")
    (binding "alt-ctrl-shift-${key}" "move-workspace-to-monitor ${direction}")
  ]) directions);

  workspaceBindings = lib.concatMap (number:
    let
      key = if number == 10 then "0" else toString number;
      workspace = toString number;
    in [
      (binding "alt-${key}" "workspace ${workspace}")
      (binding "alt-shift-${key}" "move-node-to-workspace ${workspace}")
    ]) (lib.range 1 10)
    ++ lib.concatMap (number:
      let
        key = toString number;
        workspace = toString (number + 10);
      in [
        (binding "alt-ctrl-${key}" "workspace ${workspace}")
        (binding "alt-ctrl-shift-${key}" "move-node-to-workspace ${workspace}")
      ]) (lib.range 1 9);
  resizeActions = {
    h = "width -";
    left = "width -";
    l = "width +";
    right = "width +";
    up = "height -";
    down = "height +";
    k = "height +";
    j = "height -";
  };
  resizeBindings = lib.concatLists (lib.mapAttrsToList (key: action: [
    (binding key "resize ${action}6")
    (binding "shift-${key}" "resize ${action}24")
  ]) resizeActions);
in {
  services.jankyborders = {
    enable = true;
    settings = {
      active_color = "0xffb0b0b0";
      inactive_color = "0x00000000";
      width = 3.0;
      style = "round";
      hidpi = "on";
    };
    errorLogFile = "/tmp/jankyborders.err.log";
    outLogFile = "/tmp/jankyborders.out.log";
  };

  programs.aerospace = {
    enable = true;
    package = pkgs.aerospace;
    launchd.enable = true;
    settings = {
      config-version = 2;
      start-at-login = false;
      persistent-workspaces = workspaces;
      on-window-detected = [
        {
          "if" = "test %{app-bundle-id} = com.apple.systempreferences";
          run = "layout tiling";
        }
      ];
      default-root-container-layout = "tiles";
      # Initial root orientation; existing trees are preserved when moved.
      default-root-container-orientation = "auto";
      enable-normalization-flatten-containers = false;
      enable-normalization-opposite-orientation-for-nested-containers = false;
      focus-follows-mouse.enabled = false;
      gaps = {
        inner.horizontal = 12;
        inner.vertical = 12;
        outer.left = 12;
        outer.right = 12;
        outer.top = 12;
        outer.bottom = 12;
      };
      mode.main.binding = builtins.listToAttrs
        (directionBindings ++ workspaceBindings) // {
        # Explicit global order, including empty workspaces, with wrapping.
        alt-tab = "echo -- ${workspaceOrder} | workspace --stdin --wrap-around next";
        alt-shift-tab = "echo -- ${workspaceOrder} | workspace --stdin --wrap-around prev";
        alt-g = "split horizontal";
        alt-v = "split vertical";
        alt-backspace = "split opposite";
        alt-d = "fullscreen";
        alt-shift-f = "layout floating tiling";
        # A layout argument list only alternates; conditions give a real cycle.
        alt-t = "(test %{window-layout} = h_accordion && layout h_tiles) || (test %{window-layout} = h_tiles && layout v_tiles) || layout h_accordion";
        alt-r = "mode resize";
        # Qt may expose qutebrowser as python3.14, so also detect its window title.
        alt-w = "exec-and-forget " + ''
          focusedWindow=$(${lib.getExe config.programs.aerospace.package} list-windows --focused --format '%{window-id} %{app-name} %{window-title}') || exit
          windowId=''${focusedWindow%% *}
          windowMetadata=''${focusedWindow#* }
          appName=''${windowMetadata%% *}
          windowTitle=''${windowMetadata#* }
          if [ "$appName" = qutebrowser ] || [ "''${windowTitle% - qutebrowser}" != "$windowTitle" ]; then
            ${lib.escapeShellArg "${config.home.profileDirectory}/bin/qutebrowser"} ':close'
          else
            ${lib.getExe config.programs.aerospace.package} close --window-id "$windowId"
          fi
        '';
        alt-shift-c = "reload-config";
        alt-shift-s = "exec-and-forget ${flameshotCapture}";
        alt-shift-enter = "exec-and-forget /usr/bin/open -a "
          + lib.escapeShellArg "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/qutebrowser.app";
        alt-enter = "exec-and-forget ${lib.getExe config.programs.kitty.package} --single-instance --directory ${lib.escapeShellArg config.home.homeDirectory}";
      };
      mode.resize.binding = builtins.listToAttrs resizeBindings // {
        esc = "mode main";
        enter = "mode main";
        alt-r = "mode main";
      };
      # Add observed monitor-name patterns only once the external is connected.
      # Force assignments for 1–3 will also disable moving those workspaces.
    };
  };
}
