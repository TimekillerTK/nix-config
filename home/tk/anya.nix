{ inputs, outputs, config, pkgs, username, lib, gitUser, gitEmail, ... }:
{
  imports = [

    # Required for Home Manager
    inputs.plasma-manager6.homeManagerModules.plasma-manager

    # Repo Home Manager Modules
    ../common/global
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
    # unstable.logseq # Notes
    unstable.element-desktop # Matrix client
    unstable.makemkv # DVD Ripper
    handbrake # Media Transcoder
    unstable.xivlauncher # FFXIV Launcher
    unstable.rustdesk-flutter # TeamViewer alternative
    unstable.drawio # Diagram-creating software

    # Other
    mono # for running .NET applications
  ];

  # TODO: Temporary - to be changed to percentage in the future (generic)
  programs.plasma.hotkeys.commands."alacritty-dropdown" = {
    command = "tdrop -a -h 1296 alacritty"; # <- 1440p 90% Height
  };

  # TODO: Fix later - input-remapper is defined in hosts/ config, should be home-manager
  # # For automatically launching input-remapper on user login
  # xdg.configFile."autostart/input-mapper-autoload.desktop" = lib.mkIf nixosConfig.services.input-remapper.enable {
  #   source = "${nixosConfig.services.input-remapper.package}/share/applications/input-remapper-autoload.desktop";
  # };

  home.file = {
    # VS Code Settings files as symlinks
    ".config/Code/User/keybindings.json".source = ../../dotfiles/vscode/keybindings.json;
    ".config/Code/User/settings.json".source = ../../dotfiles/vscode/settings.json;

    # Keypad Rebind keys
    ".config/input-remapper-2/presets/Razer Razer Nostromo/nostromo.json".source = ../../dotfiles/input-remapper/nostromo.json;
    ".config/input-remapper-2/presets/Razer Razer Tartarus V2/tartarus.json".source = ../../dotfiles/input-remapper/tartarus.json;
  };

  programs.home-manager.enable = true;
  home.stateVersion = "23.11"; # Please read the comment before changing.
}
