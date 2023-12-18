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

  # Testing
  home.file."/home/tk/Btestfile".text = ''
    SOME FILE WITH SOME CONTENT
  '';

  # ISSUE: This doesn't work
  home.sessionVariables = {
    EDITOR = "vim";
  };

  programs.bash = {
    enable = true;
    sessionVariables = {
      PASTA = "Spaghetti";
    };
  };
  
}
