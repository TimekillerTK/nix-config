{ config, pkgs, ... }:

{

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
      pkgs.alacritty
      pkgs.tdrop # WM-Independent Dropdown Creator (terminal)
    ];
  };

  # # KDE Settings
  # programs.plasma = {
  #   enable = true;
  #   shortcuts = {
  #   	"tdrop.desktop"."_launch" = "Alt+S";
  #   };
  #   configFile = {
  #     "kglobalshortcutsrc"."tdrop.desktop"."_k_friendly_name" = "tdrop -a alacritty";
  #   };
  # };

  # home.username = "tk";
  # home.homeDirectory = "/home/tk";
  # home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  # home.packages = [
  #   pkgs.tmux
  #   pkgs.alacritty
  #   pkgs.tdrop # WM-Independent Dropdown Creator (terminal)
  # ];

  # Testing
  home.file."/home/tk/Atestfile".text = ''
    SOME FILE WITH SOME CONTENT
  '';

  home.sessionVariables = {
    EDITOR = "vim";
  };

  programs.zsh = {
    sessionVariables = {
      PASTA = "Spaghetti";
    };
  };

  # Testing
  # programs.bash = {
  #   sessionVariables = {
  #     PASTA = "spaghetti";
  #   };
  # };
  # systemd.user.sessionVariables.PASTA2 = "spaghetti";
}
