{ inputs, outputs, config, pkgs, username, ... }:
let
  gitUser = "Astram00n";
  gitEmail = ""; # To be filled later
in
{
  imports = [

    # Required for Home Manager
    inputs.plasma-manager6.homeManagerModules.plasma-manager

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

  # Enable numlock
  xsession.numlock.enable = true;

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Custom packages for this user
  home.packages = with pkgs; [
    # Potential Issues:
    # -> No notifications? https://github.com/NixOS/nixpkgs/issues/247168
    # -> Gnome Keyring REQUIRED? https://github.com/NixOS/nixpkgs/issues/102637
    mailspring # mail client

    # Desktop Applications
    libreoffice-qt # Office Suite
    # hunspell # Need spellcheck? https://nixos.wiki/wiki/LibreOffice
    makemkv # DVD Ripper
    handbrake # Media Transcoder
    unstable.xivlauncher # FFXIV Launcher
    onedrivegui # OneDrive GUI client
    openrgb-with-all-plugins # RGB Control
    spotify # Music Streaming
  ];

  # TODO: Temporary - to be dhanged to percentage in the future (generic)
  programs.plasma.hotkeys.commands."alacritty-dropdown" = {
    command = "tdrop -a -h 1296 alacritty"; # <- 1600p 90% Height
  };

  # VS Code Settings files as symlinks
  home.file = {
    ".config/Code/User/keybindings.json".source = ../../dotfiles/vscode/keybindings.json;
    ".config/Code/User/settings.json".source = ../../dotfiles/vscode/settings.json;
  };

  programs.home-manager.enable = true;
  home.stateVersion = "23.11"; # Please read the comment before changing.
}
