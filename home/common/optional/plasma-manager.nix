{lib, ...}: {
  # KDE Plasma Manager Settings/Shortcuts
  programs.plasma = {
    enable = true;

    workspace = {
      clickItemTo = "select";
      lookAndFeel = "org.kde.breezedark.desktop";
    };

    shortcuts = {
      # Change default hotkey to CTRL+Space
      "org.kde.krunner.desktop"."_launch" = ["Ctrl+Space" "Alt+F2" "Search"];

      # Unbind conflicting keybindings
      "org.kde.spectacle.desktop"."_launch" = [];
      "org.kde.spectacle.desktop"."ActiveWindowScreenShot" = [];
      "org.kde.spectacle.desktop"."FullScreenScreenShot" = [];
      "org.kde.spectacle.desktop"."RectangularRegionScreenShot" = ["Ctrl+Alt+$" "Ctrl+Shift+C"]; # Ctrl+Alt+Shift+4
      "org.kde.spectacle.desktop"."WindowUnderCursorScreenShot" = [];
      kwin."Switch Window Left" = [];
      kwin."Switch Window Right" = [];
      kwin."Switch Window Down" = [];

      kwin = {
        # Hotkeys to move windows around
        "Window Maximize" = "Meta+Alt+Return";
        "Window Quick Tile Left" = "Meta+Alt+Left";
        "Window Quick Tile Right" = "Meta+Alt+Right";
        "Window Minimize" = "Meta+Alt+Down";

        # These just annoy me
        "ExposeAll" = [];
      };
    };

    # Window Rules, how windows should be arranged for an application
    # NOTE: This is a bit wonky while testing out and in prod, so just leaving this
    # for future reference, but disabled
    # window-rules = [
    #   {
    #     description = "Initial Size signal 1000x1000";
    #     match.window-class.value = "electron signal";
    #     apply = {
    #       size = {
    #         value = "2560,1200";
    #         apply = "force";
    #       };
    #       # ignoregeometry = {
    #       #   value = true;
    #       #   apply = "remember";
    #       # };
    #     };
    #   }
    # ];

    # Dropdown Wezterm
    hotkeys.commands."wezterm-dropdown" = {
      name = "Launch Wezterm";
      key = "Alt+Space";
      # NOTE: This is a script defined in home/common/global/alacritty-dropdown.sh
      command = lib.mkDefault ''wezterm-dropdown'';
    };

    # NOTE: Flameshot support for wayland is meh, especially for multi-monitor setups with fractional
    # scaling:
    # -> https://github.com/flameshot-org/flameshot/issues/3614
    # -> https://github.com/flameshot-org/flameshot/issues/2364
    # -> https://github.com/flameshot-org/flameshot/issues/3073
    # # Screenshot Tool (flameshot)
    # hotkeys.commands."flameshot" = {
    #   name = "Take Screenshot with Flameshot";
    #   # NOTE: 3 modifier keys are wonky
    #   key = "PrintScreen";
    #   command = lib.mkDefault ''
    #     env QT_AUTO_SCREEN_SCALE_FACTOR=1.25 QT_SCREEN_SCALE_FACTORS="" flameshot gui
    #   '';
    # };
  };
}
