{ pkgs, ... }:

{
  # Common packages installed via Home Manager
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
    tldr # man for dummies
    cachix # nix binary cache

    # Desktop Applications
    firefox
    vlc # VLC
    jellyfin-media-player
    unstable.vscode-fhs
    unstable.signal-desktop # Messaging app
    unstable.flameshot # Simple Screenshotting
    pinta # Simple MS Paint replacement
    prismlauncher # FOSS Minecraft launcher

    # Other
    (nerdfonts.override { fonts = [ "CascadiaCode" ]; }) # only 1 font
    tdrop # terminal dropdown

  ];
}
