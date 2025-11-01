{
  inputs,
  outputs,
  config,
  pkgs,
  username,
  lib,
  gitUser,
  gitEmail,
  ...
}: {
  imports = [
    # Required for Home Manager
    inputs.plasma-manager6.homeModules.plasma-manager

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
    python313
    unstable.poetry
    ruff
    uv

    # pwsh
    powershell

    # Rust
    rustup
    unstable.lld # better linker by LLVM
    unstable.clang
    unstable.mold # even better linker

    # Desktop Applications
    unstable.element-desktop # Matrix client
    unstable.makemkv # DVD Ripper
    handbrake # Media Transcoder
    unstable.xivlauncher # FFXIV Launcher
    rustdesk-flutter # TeamViewer alternative
    unstable.drawio # Diagram-creating software
    syncthingtray # Tray for Syncthing with Dolphin/Plasma integration

    # Other
    unstable.devenv # Nix powered dev environments
    mono # for running .NET applications
    granted # Switching AWS Accounts
    brave # Chromium-based browser

    # Games
    unstable.openrct2 # RollerCoaster Tycoon 2
    # openttd # Transport Tycoon Deluxe
  ];

  # Syncthing (personal cloud)
  services.syncthing = {
    enable = true;
  };

  # DirEnv configuration
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
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
