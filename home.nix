{ config, pkgs, ... }:

{
  imports = [
    <plasma-manager/modules>
  ];

  home.username = "tk";
  home.homeDirectory = "/home/tk";

  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    vim
  ];

  # KDE Plasma Manager Settings/Shortcuts
  programs.plasma = {
    enable = true;

    # Change default hotkey to CTRL+Space
    #shortcuts = {
    #  "org.kde.krunner.desktop"."_launch" = ["Ctrl+Space" "Alt+F2" "Search"];
    #};

    # Testing...
    hotkeys.commands."demo-percent-in-command" = {
      name = "Demo";
      key = "Meta+O";
      command = ''konsole -e bash -c "echo sleeping 90%% && sleep 10"'';
    };
  };

  programs.home-manager.enable = true;
}