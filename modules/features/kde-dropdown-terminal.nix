{
  # This feature provides dropdown terminal functionality, but specifically
  # for KDE Plasma.
  flake.modules.homeManager.kde-dropdown-terminal = {pkgs, ...}: {
    home.packages = with pkgs; [
      local.kwin-toggleterminal
    ];

    # Added to our KWin scripts
    home.file.".local/share/kwin/scripts/toggleterminal".source = "${pkgs.local.kwin-toggleterminal}/share/kwin/scripts/toggleterminal";

    # Hotkey configuration for kwin-toggleterminal KWin Hotkey #0 which
    # specifies WHICH TERMINAL we want to launch on first run and then toggle
    programs.plasma.configFile."kwinrc"."Script-toggleterminal" = {
      "0_windowClass".value = "org.wezfurlong.wezterm";
      "0_launchCommand".value = "/home/tk/.nix-profile/bin/wezterm";
      "0_hideOnFocusLoss".value = true;
    };

    # The actual shortcut
    programs.plasma.shortcuts.kwin."ToggleTerminal_0" = ["Alt+Space"];
  };

  flake.modules.nixos.kde-dropdown-terminal = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      local.dbus-app-launcher-bin
    ];

    # This makes dbus-app-launcher available on the dbus
    services.dbus = {
      enable = true;
      packages = [
        pkgs.local.dbus-app-launcher-bin
      ];
    };
  };
}
