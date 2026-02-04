{
  flake.homeModules.git = {pkgs, ...}: {
    programs.git = {
      enable = true;
    };
    programs.home-manager.enable = true;
    home.username = "tk";
    home.homeDirectory = "/home/tk";
    home.stateVersion = "25.11";
  };
}
