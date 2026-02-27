{inputs, ...}: {
  # Things which all desktops need:
  # - set up CLI on all systems
  # - KDE Plasma desktop selected
  # - bluetooth options preselected
  # - input remapper for remapping keyboard keys
  # - flatpaks enabled
  # - sound with pipewire
  # - printer drivers and setup
  # - NAS fileshare mounts
  flake.modules.nixos.system-desktop = {pkgs, ...}: let
    brother-mfcl3750cdw = pkgs.callPackage ../../local-pkgs/brother-mfcl3750cdw {};
  in {
    imports = [
      inputs.self.modules.nixos.system-cli
      inputs.self.modules.nixos.kde-plasma
      inputs.self.modules.nixos.input-remapper
      inputs.self.modules.nixos.bluetooth
      inputs.self.modules.nixos.flatpak
      inputs.self.modules.nixos.prometheus-node-desktop
      inputs.self.modules.nixos.zfs
    ];

    # Configure keymap in Wayland
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # For USB Blu-Ray/DVD Players
    boot.kernelModules = ["sg"];

    # Enable sound with pipewire
    security.rtkit.enable = true;
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # Add printer autodiscovery
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Enable CUPS to print documents and install printer drivers
    services.printing.enable = true;
    services.printing.drivers = [
      brother-mfcl3750cdw.driver
      brother-mfcl3750cdw.cupswrapper
    ];

    # Steam
    programs.steam.enable = true;

    # Desktop Sharing and GameStreaming Server
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
      openFirewall = true;
    };
  };

  flake.modules.homeManager.system-desktop = {pkgs, ...}: {
    imports = [
      inputs.self.modules.homeManager.system-cli
      inputs.self.modules.homeManager.terminal
      inputs.self.modules.homeManager.input-remapper
    ];

    home.packages = with pkgs; [
      # Common Desktop Applications
      firefox # Firefox
      brave # Chromium-based browser
      vlc # VLC
      unstable.vscode-fhs # Text Editor Desktop
      unstable.signal-desktop # Messaging app
      unstable.flameshot # Simple Screenshotting
      pinta # Simple MS Paint replacement
      tartube-yt-dlp # YT downloader
      libreoffice-qt # Office Suite
      unstable.lutris # Games Launcher
      unstable.discord # Chat
      rustdesk-flutter # TeamViewer alternative
      moonlight-qt # GameStreaming Client
    ];
  };
}
