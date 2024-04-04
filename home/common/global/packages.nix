{ pkgs, ... }:

{
  # All packages installed via Home Manager
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
    nextcloud-client # Personal cloud
    unstable.element-desktop # Matrix client
    unstable.logseq # Notes
    unstable.vscode-fhs 
    unstable.signal-desktop # Messaging app
    unstable.kooha # Simple screen recording
    unstable.flameshot # Simple Screenshotting

    # Other
    (nerdfonts.override { fonts = [ "CascadiaCode" ]; }) # only 1 font
    tdrop # terminal dropdown

  ];
}