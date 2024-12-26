{
  inputs,
  outputs,
  config,
  pkgs,
  username,
  ...
}: {
  imports = [
    # Required for Home Manager
    inputs.plasma-manager6.homeManagerModules.plasma-manager

    # Repo Home Manager Modules
    ../common/global/sh.nix
    ../common/global/starship.nix
    ../common/global/terminal.nix
    ../common/global/packages.nix
    ../common/optional/plasma-manager.nix
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

  # Enable numlock
  xsession.numlock.enable = true;

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Custom packages for this user
  home.packages = with pkgs; [
    # Packages here
  ];

  # VS Code Settings files as symlinks
  home.file = {
    ".config/Code/User/keybindings.json".source = ../../dotfiles/vscode/keybindings.json;
    ".config/Code/User/settings.json".source = ../../dotfiles/vscode/settings.json;
  };

  programs.home-manager.enable = true;
  home.stateVersion = "23.11"; # Please read the comment before changing.
}
