{
  pkgs,
  lib,
  ...
}: let
  desktopItem = pkgs.makeDesktopItem {
    name = "4kvideodownloaderplus";
    exec = "env LC_ALL=C 4kvideodownloaderplus.sh";
    icon = "4kvideodownloaderplus";
    desktopName = "4K Video Downloader Plus";
    genericName = "Video Downloader";
    comment = "Download videos from YouTube and other video sites";
    categories = ["Network" "Utility"];
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
    # NOTE: Broken SVG?
    icon = ./4kvideodownloaderplus-icon.svg;

    # Need to patch elf headers, because 4kvideodownloader is built for generic linux
    # https://nix.dev/guides/faq#how-to-run-non-nix-executables
    nativeBuildInputs = with pkgs; [
      pkgs.autoPatchelfHook
      qt5.wrapQtAppsHook # required with qt5 buildInputs
    ];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib # This provides libstdc++.so.6
      libGL # This provides libGL.so.1
      xorg.libxcb # This provides libxcb.so.1 and libxcb-glx.so.0
      xorg.libX11 # This provides libX11.so.6
      xorg.xcbutil
      xorg.xcbutilwm
      xorg.xcbutilimage
      xorg.xcbutilkeysyms
      xorg.xcbutilrenderutil
      xorg.libXi
      xorg.libXrender
      xorg.libXcursor
      xorg.libXcomposite
      xorg.libXfixes
      xorg.libXdamage # For libXdamage.so.1
      xorg.libXrandr # For libXrandr.so.2
      xorg.libXtst # For libXtst.so.6
      qt5.qtbase # This should provide Qt-related dependencies
      qt5.qtbase.dev # Private headers (?)
      qt5.qtdeclarative # This might be needed for QtGraphicalEffects
      qt5.qtgraphicaleffects
      qt5.qtimageformats
      qt5.qtsvg
      qt5.qtx11extras
      qt5.qtwebengine # For QtWebEngine support
      alsaLib # This provides libasound.so.2
      nss # For libnss3.so, libnssutil3.so, and libnspr4.so
    ];

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

    # previously built successfully with this:
    # "--set QT_PLUGIN_PATH ${pkgs.qt5.qtbase}/${pkgs.qt5.qtbase.qtPluginPrefix}"
    qtWrapperArgs = let
      pluginPath = lib.makeSearchPathOutput "lib" "lib/qt-${pkgs.qt5.qtbase.version}/plugins" [
        pkgs.qt5.qtbase
        pkgs.qt5.qtsvg
        pkgs.qt5.qtimageformats
      ];
    in [
      "--set QT_PLUGIN_PATH ${pluginPath}"
      "--set QT_QPA_PLATFORM xcb"
      "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}"
    ];

    # Maybe not needed?
    # postInstall = ''
    #   wrapProgram $out/bin/4kvideodownloaderplus \
    #     --set QT_QPA_PLATFORM xcb
    #     --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs}
    # '';

    meta = with pkgs.lib; {
      description = "Download videos from YouTube and other video sites";
      homepage = "https://www.4kdownload.com/products/videodownloader";
      license = licenses.unfree;
      platforms = platforms.linux;
    };
  }
