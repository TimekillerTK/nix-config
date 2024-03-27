{ inputs, outputs, config, pkgs, ... }:

{
  imports = [

    inputs.plasma-manager.homeManagerModules.plasma-manager
    ./sh.nix
    ./git.nix
    ./terminal.nix
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

    # Other
    (nerdfonts.override { fonts = [ "CascadiaCode" ]; }) # only 1 font
    tdrop # terminal dropdown
  ];

  # KDE Plasma Manager Settings/Shortcuts
  programs.plasma = {
    enable = true;

    shortcuts = {
      # "tdrop.desktop"."_launch" = "Alt+Space";
      "org.kde.krunner.desktop"."_launch" = ["Ctrl+Space" "Alt+F2" "Search"];
    };
    # configFile = {
    #   "kglobalshortcutsrc"."tdrop.desktop"."_k_friendly_name" = "tdrop -a alacritty";
    # };
  };

  # VS Code Settings files as symlinks
  home.file = {
    ".config/Code/User/keybindings.json".source = ../../dotfiles/vscode/keybindings.json;
    ".config/Code/User/settings.json".source = ../../dotfiles/vscode/settings.json;
  };

  programs.home-manager.enable = true;
  home.stateVersion = "23.11"; # Please read the comment before changing.
}
