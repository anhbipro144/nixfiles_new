{ lib, stdenv, fetchurl, autoPatchelfHook, dpkg
, gtk3, glib, cairo, pango, gdk-pixbuf
, webkitgtk_4_1, libsoup_3
, dbus, openssl
, libx11, libxext
}:

stdenv.mkDerivation rec {
  pname = "veloxdb";
  version = "0.1.0-8";

  src = fetchurl {
    url = "https://github.com/abeni16/veloxdb/releases/download/veloxdb_${version}/veloxdb_${version}_amd64.deb";
    hash = "sha256-0vJpqmNCK6rYHcmCr/KbtxV+wRvgJefiXOSi9OnYuDw=";
  };

  nativeBuildInputs = [ autoPatchelfHook dpkg ];

  buildInputs = [
    gtk3
    glib
    cairo
    pango
    gdk-pixbuf
    webkitgtk_4_1
    libsoup_3
    dbus
    openssl
    libx11
    libxext
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share
    cp -r usr/share/* $out/share/ 2>/dev/null || true
    install -Dm755 usr/bin/veloxdb $out/bin/veloxdb
  '';

  meta = {
    description = "A fast, lightweight PostgreSQL/MySQL/SQLite GUI client";
    homepage = "https://veloxdb.dev";
    license = lib.licenses.unfree;
    mainProgram = "veloxdb";
    platforms = [ "x86_64-linux" ];
  };
}
