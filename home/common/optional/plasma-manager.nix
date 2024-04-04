
{ lib, ... }:
{
  # KDE Plasma Manager Settings/Shortcuts
  programs.plasma = {
    enable = true;

    shortcuts = {
      # Change default hotkey to CTRL+Space
      "org.kde.krunner.desktop"."_launch" = ["Ctrl+Space" "Alt+F2" "Search"];
      kwin = {
        # Hotkeys to move windows around
        "Window Maximize" = "Meta+Alt+Return";
        "Window Quick Tile Left" = "Meta+Alt+Left";
        "Window Quick Tile Right" = "Meta+Alt+Right";
        "Window Minimize" = "Meta+Alt+Down";

        # Unbind conflicting keybindings
        "Switch Window Left" = [ ];
        "Switch Window Right" = [ ];
        "Switch Window Down" = [ ];
        # TODO: Unbind CMD+PRINTSCREEN
        # TODO: Unbind PRINTSCREEN
      };
    };

    # TODO: Change to percentage in the future
    # Dropdown Alacritty
    hotkeys.commands."alacritty-dropdown" = {
      name = "Launch Alacritty";
      key = "Alt+Space";
      command = lib.mkDefault "tdrop -a alacritty"; # height set in home/<user>/<host>.nix
    };

    # Screenshot
    hotkeys.commands."flameshot" = {
      name = "Take Screenshot with Flameshot";
      key = "PrintScreen";
      command = lib.mkDefault ''
        env QT_AUTO_SCREEN_SCALE_FACTOR=1.25 QT_SCREEN_SCALE_FACTORS="" flameshot gui
      '';
    };

    # Screen recording
    hotkeys.commands."kooha" = {
      name = "Take Screen recording with Kooha";
      key = "Meta+PrintScreen";
      command = lib.mkDefault "kooha";
    };

    # TODO: Find what is going on here...
    # https://github.com/pjones/plasma-manager/issues/105
    # # Testing...
    # hotkeys.commands."demo-percent-in-command" = {
    #   name = "Demo";
    #   key = "Meta+O";
    #   command = ''konsole -e bash -c "echo 95%% && sleep 2"'';
    # };
  };
}