{ pkgs, ... }:
let
  desktopItem = pkgs.makeDesktopItem {
    name = "4kvideodownloaderplus";
    exec = "env LC_ALL=C 4kvideodownloaderplus.sh";
    icon = "4kvideodownloaderplus";
    desktopName = "4K Video Downloader+";
    genericName = "Video Downloader";
    comment = "Download videos from YouTube and other video sites";
    categories = [ "Network" "Utility" ];
  };
in
pkgs.stdenv.mkDerivation rec {
  pname = "4kvideodownloaderplus";
  version = "1.8.5";

  src = builtins.fetchurl {
    url = "https://dl.4kdownload.com/app/${pname}_${version}_amd64.tar.bz2";
    sha256 = "087svy9r0sv6hwwhs2r4vah97pml76zfjv79yjp5hpb785i2w54x";
  };

  # Include the custom icon in the derivation
  icon = ./4kvideodownloaderplus-icon.svg;

  # NOTE: Custom unpackPhase that directly extracts files into the build directory
  # workaround since gitlab fargate driver does not contain a directory bin/
  # which nix expects
  unpackPhase = ''
    mkdir -p $out/bin
    tar -xjvf $src -C $out/bin --strip-components=1 4kvideodownloaderplus
  '';

  installPhase = ''
    cp -r * $out/bin

    # Create icons directory
    mkdir -p $out/share/icons/hicolor/128x128/apps

    # Copy the custom icon
    cp ${icon} $out/share/icons/hicolor/128x128/apps/4kvideodownloaderplus.svg

    # Install desktop file
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications/
  '';

  meta = with pkgs.lib; {
    description = "Download videos from YouTube and other video sites";
    homepage = "https://www.4kdownload.com/products/videodownloader";
    license = licenses.unfree;
    # platforms = platforms.linux;
  };
}
