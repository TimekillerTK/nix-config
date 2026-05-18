{pkgs ? import <nixpkgs> {}, ...}:
pkgs.stdenv.mkDerivation {
  # This is my own package of dbus-app-launcher-bin, because the one in nixpkgs is marked as
  # broken.
  #
  # This is used by https://github.com/DvdGiessen/kwin-toggleterminal which has 'dropdown terminal'
  # -like functionality. However, it only works if the terminal is already running -
  # dbus-app-launcher solves that problem.
  #
  # NOTE: This ONLY fetches the binary itself which is already pre-built on GitHub for x86-64
  # linux. It does NOT rebuild it locally. This means that if there is ever a SHA mismatch error
  # then something fishy is going on, and should NOT be 'fixed' - just find another solution
  pname = "dbus-app-launcher-bin";
  version = "0.1.1.0";

  src = pkgs.fetchurl {
    url = "https://github.com/DvdGiessen/dbus-app-launcher/releases/download/v0.1.1.0/dbus-app-launcher-linux-x86_64-static";
    sha256 = "sha256-wZSz/dHiWhL36/HH4nNJwE7H+lBt15lYjCkH338t9lg=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    install -m755 $src $out/bin/dbus-app-launcher

    mkdir -p $out/share/dbus-1/services
    cat > $out/share/dbus-1/services/nl.dvdgiessen.dbusapplauncher.service <<EOF
    [D-BUS Service]
    Name=nl.dvdgiessen.dbusapplauncher
    Exec=$out/bin/dbus-app-launcher
    EOF
  '';
}
