{ inputs, outputs, config, pkgs, username, gitEmail, gitUser, ... }:
{
  imports = [

    # Required for Home Manager
    inputs.plasma-manager6.homeModules.plasma-manager

    # Repo Home Manager Modules
    ../common/global
    ../common/optional/plasma-manager.nix
    ../common/optional/astra-packages.nix
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

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Extra packages for this user
  home.packages = with pkgs; [
    # Desktop Applications
    unstable.xivlauncher # FFXIV Launcher
  ];

  # VS Code Settings files as symlinks
  home.file = {
    ".config/Code/User/keybindings.json".source = ../../dotfiles/vscode/keybindings.json;
    ".config/Code/User/settings.json".source = ../../dotfiles/vscode/settings.json;
  };

  programs.home-manager.enable = true;
  home.stateVersion = "23.11"; # Please read the comment before changing.
}
