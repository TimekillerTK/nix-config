{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    # Required for VS Code Remote
    inputs.vscode-server.nixosModules.default

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
    ../common/optional/kde-plasma6-x11
    # ../common/optional/tailscale-client
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
    ];
    uninstallUnmanaged = true; # Manage non-Nix Flatpaks
    update.onActivation = true; # Auto-update on rebuild
  };

  # Firmware Updates
  # https://wiki.nixos.org/wiki/Fwupd
  services.fwupd.enable = true;

  # VS Code Server Module (for VS Code Remote)
  services.vscode-server.enable = true;

  # Actual SOPS keys
  sops.defaultSopsFile = ../common/secrets.yml;
  sops.secrets.smbcred = { };

  # Root Cert
  security.pki.certificateFiles = [
    ../common/root-ca.pem
  ];

  # Numlock on Login Screen (SDDM)
  services.xserver.displayManager.setupCommands = ''${pkgs.numlockx}/bin/numlockx on'';

  # Bluetooth configuration
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Steam
  programs.steam.enable = true;
  environment.sessionVariables = {
    # Fixes steam not picking up correct scaling on framework (?)
    STEAM_FORCE_DESKTOPUI_SCALING = "1.5";
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
    vim
    nvd # Nix/NixOS package version diff tool
    kdePackages.kdialog # pops up dialogs
  ];

  # Mounting fileshare
  fileSystems."/mnt/FreeNAS" = {
    device = "//freenas.cyn.internal/mediasnek2";
    fsType = "cifs";
    # noauto + x-systemd.automount - disables mounting this FS with mount -a & lazily mounts (when first accessed)
    # Remember to run `sudo umount /mnt/FreeNAS` before adding/removing "noauto" + "x-systemd.automount"
    options = [
      "credentials=/run/secrets/smbcred"
      "noserverino"
      "rw"
      "_netdev"
      "uid=1000"
      "gid=100"
      "file_mode=0770"   # File permissions to rwx for user and group
      "dir_mode=0770"    # Directory permissions to rwx for user and group
    ] ++ [
      "noauto"                      # prevent from being automatically mounted on BOOT
      "x-systemd.automount"         # create an automount unit, mount on ACCESS
      "x-systemd.idle-timeout=60"   # after not accessed for 60 seconds, systemd will attempt unmount
      "x-systemd.device-timeout=5s" # if device doesn't appear in 5 secs, fail the mount
      "x-systemd.mount-timeout=5s"  # if mount command doesn't succeed in 5 secs, fail the mount
    ];
    # NOTE: to query:
    #   systemctl list-units --type=automount
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}