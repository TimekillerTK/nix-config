{pkgs, ...}: {
  # Exception for jellyfin-media-player 1.12.0 which uses
  # this package
  nixpkgs.config.permittedInsecurePackages = [
    "qtwebengine-5.15.19"
  ];

  # Common packages installed via Home Manager
  home.packages = with pkgs; [
    # CLI
    unstable.fd
    unstable.eza
    unstable.bat
    unstable.dust
    unstable.ripgrep
    unstable.fzf

    bottom # top/htop replacement
    jq # JSON parsing utility
    tldr # man for dummies
    cachix # nix binary cache

    # Desktop Applications
    firefox
    vlc # VLC

    # INSECURE/BROKEN: https://github.com/NixOS/nixpkgs/issues/437865
    # Currently waiting for new jellyfin-media-player release, which
    # should happen at any time
    jmp_v1120.jellyfin-media-player

    unstable.vscode-fhs
    unstable.signal-desktop # Messaging app
    unstable.flameshot # Simple Screenshotting
    pinta # Simple MS Paint replacement
    prismlauncher # FOSS Minecraft launcher
    tartube-yt-dlp # YT downloader
    libreoffice-qt # Office Suite
    unstable.lutris # Games Launcher
    # hunspell # Need spellcheck? https://wiki.nixos.org/wiki/LibreOffice
    moonlight-qt # GameStreaming Client
    unstable.discord # Chat

    # Other
    # NOTE: When adding, you might need to force rebuild the font cache with:
    # -> fc-cache -f -v
    nerd-fonts.caskaydia-cove # Windows Terminal Font :)
    tdrop # terminal dropdown

    # Custom
    renamer
  ];
}
