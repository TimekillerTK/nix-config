{ config, pkgs, inputs, ... }:

{
  imports = [
    ./sh.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    username = "tk";
    stateVersion = "23.11"; # Please read the comment before changing.
    homeDirectory = "/home/tk";
    packages = [
      pkgs.tmux
      pkgs.ripgrep
      pkgs.tdrop # WM-Independent Dropdown Creator (terminal)
      (pkgs.nerdfonts.override { fonts = [ "CascadiaCode" ]; }) # only 1 font
    ];
  };

  # Enable managing fonts via Home Manager
  fonts.fontconfig.enable = true;

  # Alacritty Config (Fast GPU-Accelerated Terminal)
  programs.alacritty = {
    enable = true;
    settings = {

    };
  };

  # Enable Starship for Terminal
  programs.starship.enable = true;

  # KDE Plasma Config
  programs.plasma = {
    enable = true;
    shortcuts = {
      "tdrop.desktop"."_launch" = "Alt+G";
    };
    configFile = {
      "kglobalshortcutsrc"."tdrop.desktop"."_k_friendly_name" = "tdrop -a alacritty";
    };
  };
  
  #########################
  # Testing Section below #
  #########################
  # -------------------------------------------#
  home.file."/home/tk/Btestfile".text = ''
    SOME FILE WITH SOME CONTENT
  '';
  home.file."/home/tk/Ctestfile".source = ./Ctestfile;
  # -------------------------------------------#

}
