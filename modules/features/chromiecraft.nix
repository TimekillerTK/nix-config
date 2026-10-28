{
  # World of Warcraft 3.3.5a client for the ChromieCraft.
  #
  # To use:
  # - put the 3.3.5a client zip somewhere (your desktop or your NAS).
  # - in the imports statement of your host, add the following:
  #
  # (inputs.self.factory.chromiecraft {
  #   zip = "/path/to/ChromieCraft_3.3.5a.zip";
  #   installdir = "/path/to/whereyouwantit/folder";
  # })
  #
  # Then just run `chromiecraft` in cli or run the ChromieCraft desktop
  # entry.
  #
  # NOTE: The client deliberately does NOT live in /nix/store: WoW writes to its own
  # directory (WTF/, Interface/AddOns/, Cache/, Screenshots/) and the Wine
  # prefix must be writable as well.
  #
  # The client zip is only read once, on the first launch.
  config.flake.factory.chromiecraft = {
    zip,
    installdir,
  }: {pkgs, ...}: let
    launch = pkgs.writeShellApplication {
      name = "chromiecraft";
      runtimeInputs = [
        pkgs.unstable.wineWow64Packages.stagingFull
        pkgs.libarchive
        pkgs.local.wow-large-address-aware
      ];
      text = ''
        zip=${zip}
        installdir=${installdir}
        gamedir=$installdir/ChromieCraft_3.3.5a

        wtf=$gamedir/WTF/Config.wtf

        export WINEPREFIX=$installdir/wineprefix
        export WINEDEBUG=-all

        if [ ! -f "$gamedir/Wow.exe" ]; then
          echo "ChromieCraft client not found, extracting $zip to $installdir"
          echo "This only happens once and can take a few minutes."
          mkdir -p "$installdir"
          bsdtar -xvf "$zip" -C "$installdir"

          # Enable Large Address Aware so the 32-bit client can use >2GB RAM.
          wow-large-address-aware "$gamedir/Wow.exe"
        fi

        # NOTE: WoW's default true-fullscreen mode is broken under Wine on Wayland
        # (renders into only part of the window); seed windowed defaults.
        if [ ! -f "$wtf" ]; then
          mkdir -p "$gamedir/WTF"
          printf 'SET gxWindow "1"\n' > "$wtf"
        fi

        cd "$gamedir"
        exec wine Wow.exe "$@"
      '';
    };
  in {
    environment.systemPackages = [
      pkgs.unstable.wineWow64Packages.stagingFull
      pkgs.unstable.winetricks
      pkgs.local.wow-large-address-aware
      launch
      (pkgs.makeDesktopItem {
        name = "chromiecraft";
        desktopName = "ChromieCraft (WoW 3.3.5a)";
        comment = "World of Warcraft 3.3.5a client for ChromieCraft";
        exec = "${launch}/bin/chromiecraft";
        icon = "${./chromiecraft.png}";
        categories = ["Game"];
      })
    ];
  };
}
