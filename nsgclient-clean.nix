{ writeShellScriptBin }:

writeShellScriptBin "nsgclient-clean" ''
  unset LD_LIBRARY_PATH
  unset NIX_LD
  unset NIX_LD_LIBRARY_PATH
  unset LD_PRELOAD
  unset LIBGL_DRIVERS_PATH
  unset __EGL_VENDOR_LIBRARY_DIRS
  unset __EGL_VENDOR_LIBRARY_FILENAMES
  unset EGL_VENDOR_LIBRARY_FILENAMES
  unset VK_ICD_FILENAMES
  unset VK_LAYER_PATH
  unset GBM_BACKENDS_PATH
  unset LIBVA_DRIVERS_PATH
  unset VDPAU_DRIVER_PATH
  unset QT_PLUGIN_PATH
  unset QML2_IMPORT_PATH
  unset GIO_EXTRA_MODULES
  unset GTK_PATH
  unset GI_TYPELIB_PATH

  exec /opt/Citrix/NSGClient/bin/NSGClient "$@"
''
