{
  description = "UniClipboard package flake";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      uniclipboard = let
        pname = "uniclipboard";
        version = "0.19.1";

        src = pkgs.fetchurl {
          url =
            "https://github.com/UniClipboard/UniClipboard/releases/download/v${version}/UniClipboard_${version}_amd64.AppImage";
          hash = "sha256-S2hV2lJioFssVQwcVFZFcVIRBrz8MyrRuVUdIHh4Hxo=";
        };

        appimageContents =
          pkgs.appimageTools.extractType2 { inherit pname version src; };

        patchedAppimageContents =
          pkgs.runCommand "${pname}-${version}-patched" { } ''
            cp -a ${appimageContents} $out
            chmod -R u+w $out
            substituteInPlace $out/AppRun \
              --replace-fail \
                'exec "$this_dir"/AppRun.wrapped "$@"' \
                'unset APPDIR APPIMAGE
            unset GBM_BACKENDS_PATH
            unset LIBVA_DRIVERS_PATH
            unset VDPAU_DRIVER_PATH
            unset VK_ICD_FILENAMES
            unset VK_LAYER_PATH
            unset __EGL_VENDOR_LIBRARY_DIRS
            unset __EGL_VENDOR_LIBRARY_FILENAMES
            unset EGL_VENDOR_LIBRARY_FILENAMES
            export PATH="$this_dir/usr/bin:$this_dir/usr/sbin:$PATH"
            export LD_LIBRARY_PATH="/usr/lib64:/usr/lib:$this_dir/usr/lib:$this_dir/usr/lib/x86_64-linux-gnu"
            export LIBGL_DRIVERS_PATH=/usr/lib64/dri
            export GDK_BACKEND=x11
            export GDK_RENDERING=image
            export GSK_RENDERER=cairo
            export LIBGL_ALWAYS_SOFTWARE=1
            export MESA_LOADER_DRIVER_OVERRIDE=swrast
            export WEBKIT_EXEC_PATH=/usr/libexec/webkit2gtk-4.1
            export WEBKIT_DISABLE_DMABUF_RENDERER=1
            export WEBKIT_DISABLE_COMPOSITING_MODE=1
            export WEBKIT_FORCE_COMPOSITING_MODE=0
            exec "$this_dir"/usr/bin/uniclipboard "$@"'
          '';
      in pkgs.appimageTools.wrapAppImage {
        inherit pname version;
        src = patchedAppimageContents;
        extraPkgs = pkgs: [
          pkgs.egl-wayland
          pkgs.libayatana-appindicator
          pkgs.libappindicator-gtk3
          pkgs.libcanberra-gtk3
          pkgs.libdrm
          pkgs.libglvnd
          pkgs.mesa
          pkgs.webkitgtk_4_1
        ];

        extraInstallCommands = ''
          install -Dm444 \
            ${patchedAppimageContents}/usr/share/applications/UniClipboard.desktop \
            $out/share/applications/uniclipboard.desktop

          cp -r \
            ${patchedAppimageContents}/usr/share/icons \
            $out/share/icons
        '';

        meta = {
          description = "Encrypted peer-to-peer clipboard synchronization";
          homepage = "https://uniclipboard.app";
          license = pkgs.lib.licenses.agpl3Only;
          sourceProvenance = with pkgs.lib.sourceTypes; [ binaryNativeCode ];
          mainProgram = "uniclipboard";
          platforms = [ "x86_64-linux" ];
        };
      };
    in {
      packages.${system} = {
        default = uniclipboard;
        uniclipboard = uniclipboard;
      };
    };
}
