{ inputs, outputs, config, pkgs, username, ... }:

{
  imports = [

    # Required for Home Manager
    inputs.plasma-manager.homeManagerModules.plasma-manager

    # Repo Home Manager Modules
    ../common/global
    ../common/optional/git.nix
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

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # TODO: Temporary - to be dhanged to percentage in the future (generic)
  programs.plasma.hotkeys.commands."alacritty-dropdown" = {
    command = "tdrop -a -h 1440 alacritty"; # <- 1600p 90% Height
  };

  # VS Code Settings files as symlinks
  home.file = {
    ".config/Code/User/keybindings.json".source = ../../dotfiles/vscode/keybindings.json;
    ".config/Code/User/settings.json".source = ../../dotfiles/vscode/settings.json;
  };

  programs.home-manager.enable = true;
  home.stateVersion = "23.11"; # Please read the comment before changing.
}
