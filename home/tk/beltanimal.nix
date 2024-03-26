{ inputs, outputs, config, pkgs, ... }:

{
  imports = [
    ./sh.nix
    ./git.nix
    # ./terminal.nix # TODO: Change from MacOS
    ./starship.nix
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.other-packages
    ];
    # Allow unfree packages (Home Manager)
    config.allowUnfree = true;
  };

  home.username = outputs.username;
  home.homeDirectory = "/home/${outputs.username}";

  home.packages = [

    # CLI
    pkgs.unstable.fd
    pkgs.unstable.eza
    pkgs.unstable.bat
    pkgs.unstable.du-dust
    pkgs.unstable.ripgrep
    pkgs.unstable.fzf

    pkgs.bottom # top/htop replacement
    pkgs.jq # JSON parsing utility
    pkgs.sops # Mozilla SOPS
    pkgs.tldr # man for dummies
    pkgs.awscli2 # AWS CLI
    pkgs.cachix # nix binary cache

    # pwsh
    pkgs.powershell
    
    # Python
    pkgs.python312
    pkgs.unstable.poetry

    # Desktop Applications
    pkgs.firefox
    pkgs.unstable.vscode-fhs

    # Fonts
    (pkgs.nerdfonts.override { fonts = [ "CascadiaCode" ]; }) # only 1 font
  ];

  programs.home-manager.enable = true;
  home.stateVersion = "23.11"; # Please read the comment before changing.
}
