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

    # Dropdown Alacritty
    hotkeys.commands."alacritty-dropdown" = {
      name = "Launch Alacritty";
      key = "Alt+Space";

      # Tdrop does not support programs that use Wayland directly, but it does work under Wayland
      # if the program uses XWayland. If your program defaults to using Wayland, you can generally
      # force it to use XWayland by setting the environment variable `WAYLAND_DISPLAY`

      # NOTE: -m / --monitor-aware only works when combined with -t / --pointer-monitor-detection.

      # -t / --pointer-monitor-detection
      #        Use mouse pointer location for detecting which monitor is the current one so terminal will be displayed on it.
      #        Without this option, the monitor with currently active window is considered the current one. This option is
      #        only effective if -m / --monitor-aware option is enabled.
      command = lib.mkDefault ''env WAYLAND_DISPLAY="" tdrop -tm -h 90% alacritty'';
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
