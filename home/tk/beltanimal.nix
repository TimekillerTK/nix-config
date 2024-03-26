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

  home.packages = with pkgs; [

    # CLI
    unstable.fd
    unstable.eza
    unstable.bat
    unstable.du-dust
    unstable.ripgrep
    unstable.fzf

    bottom # top/htop replacement
    jq # JSON parsing utility
    sops # Mozilla SOPS
    tldr # man for dummies
    awscli2 # AWS CLI
    cachix # nix binary cache

    # pwsh
    powershell
    
    # Python
    python312
    unstable.poetry

    # Desktop Applications
    firefox
    unstable.vscode-fhs
    unstable.signal-desktop # Messaging app/desktop

    # Fonts
    (nerdfonts.override { fonts = [ "CascadiaCode" ]; }) # only 1 font
  ];

  # Testing Symlink
  home.file = {
    ".testfile".source = /home/tk/file.txt;
  };

  programs.home-manager.enable = true;
  home.stateVersion = "23.11"; # Please read the comment before changing.
}
