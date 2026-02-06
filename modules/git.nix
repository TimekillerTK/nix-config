{
  flake.modules.homeManager.git = {pkgs, ...}: {
    programs.git = {
      enable = true;
    };
    home.packages = with pkgs; [
      unstable.devenv
    ];
    programs.home-manager.enable = true;
    home.username = "tk";
    home.homeDirectory = "/home/tk";
    home.stateVersion = "25.11";
  };
}
