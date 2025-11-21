{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    # Required for disk configuration
    inputs.disko.nixosModules.default

    # NixOS Hardware
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd

    # Required for nix-flatpak
    inputs.nix-flatpak.nixosModules.nix-flatpak

    # Disko config
    ./disko.nix

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk
    ../common/users/astra
    ../common/users/bb
    ../common/optional/sops
    ../common/optional/zfs
    ../common/optional/kde-plasma6-wayland
    ../common/optional/input-remapper
    ../common/optional/mount-media
    ../common/optional/mount-important
    ../common/optional/tailscale-client
    ../common/optional/home-assistant-remote
    ../common/optional/nix-auto-update
    ../common/optional/prometheus-node-desktop
  ];

  # Overlays
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.other-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Enabling Flatpak
  services.flatpak = {
    enable = true;
    packages = [
      # Temporarily installed due to
      # https://github.com/logseq/logseq/issues/10851
      "com.logseq.Logseq"

      # FFXIV Launcher (Game)
      "dev.goats.xivlauncher"
    ];
    uninstallUnmanaged = true; # Manage non-Nix Flatpaks
    update.onActivation = true; # Auto-update on rebuild
  };

  # Firmware Updates
  # https://wiki.nixos.org/wiki/Fwupd
  services.fwupd.enable = true;

  # Actual SOPS keys
  sops.defaultSopsFile = ../common/secrets.yml;
  sops.secrets.smbcred = {};

  # Root Cert
  security.pki.certificateFiles = [
    ../common/root-ca.pem
  ];

  # Bluetooth configuration
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # For game streaming
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;
  };

  # Steam
  programs.steam.enable = true;
  environment.sessionVariables = {
    # Fixes steam not picking up correct scaling on framework (?)
    STEAM_FORCE_DESKTOPUI_SCALING = "1.5";
  };

  # By default laptops with closed lids automatically suspend, which
  # cuts off network connectivity. These changes prevent that on
  # the login screen.
  services.logind = {
    lidSwitch = "lock";
    lidSwitchDocked = "lock";
    lidSwitchExternalPower = "lock";
  };

  # Hostname & Network Manager
  networking.hostName = "beltanimal";
  networking.networkmanager = {
    enable = true;
  };

  # Generated with head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "75e25de8"; # required for ZFS!

  # System Packages
  environment.systemPackages = with pkgs; [
    kdePackages.kdialog # pops up dialogs
  ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
