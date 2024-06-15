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

  # Custom packages for this user
  home.packages = with pkgs; [

    sops # Mozilla SOPS
    awscli2 # AWS CLI

    # Python
    python312
    unstable.poetry

    # pwsh
    powershell

    # Rust
    rustup
    unstable.lld # better linker by LLVM
    unstable.clang
    unstable.mold # even better linker 


    # Desktop Applications
    nextcloud-client # Personal cloud
    unstable.logseq # Notes
    unstable.element-desktop # Matrix client

    # Other
    mono # for running .NET applications

  ];

  # TODO: Temporary - to be changed to percentage in the future (generic)
  programs.plasma.hotkeys.commands."alacritty-dropdown" = {
    command = "tdrop -a -h 1296 alacritty"; # <- 1440p 90% Height
  };

  # VS Code Settings files as symlinks
  home.file = {
    ".config/Code/User/keybindings.json".source = ../../dotfiles/vscode/keybindings.json;
    ".config/Code/User/settings.json".source = ../../dotfiles/vscode/settings.json;
  };

  programs.home-manager.enable = true;
  home.stateVersion = "23.11"; # Please read the comment before changing.
}
