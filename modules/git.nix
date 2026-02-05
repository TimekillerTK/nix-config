{
  flake.homeModules.git = {
    pkgs,
    config,
    ...
  }: {
    programs.git = {
      enable = true;
    };
    nixpkgs.overlays = [
      (final: _prev: {
        unstable = import config.systemConstants.nixpkgs-unstable {
          inherit (final) config;
          system = pkgs.stdenv.hostPlatform.system;
        };
      })
    ];
    home.packages = with pkgs; [
      unstable.devenv
    ];
    programs.home-manager.enable = true;
    home.username = "tk";
    home.homeDirectory = "/home/tk";
    home.stateVersion = "25.11";
  };
}
