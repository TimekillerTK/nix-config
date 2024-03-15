{
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.vscode-server.nixosModules.default

    # Disko config
    ./disko.nix

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk
    ../optional/kde-plasma-x11
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
  
  # TODO: Move this and other ZFS options to common/optional/zfs/default.nix later
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.zfs.devNodes = lib.mkDefault "/dev/disk/by-id";

  # Automatic Scrub schedule
  services.zfs.autoScrub = {
    enable = true;
    interval = "Sat, 10:00";
  };

  # Automatic Snapshotting
  # NOTE: To target specific datasets, set in disko.nix!
  services.zfs.autoSnapshot = {
    enable = true;
    flags = "-k -p --utc";
  };

  # VS Code Server Module (for VS Code Remote) 
  services.vscode-server.enable = true;

  # Hostname & Network Manager
  networking.hostName = "anya";
  networking.networkmanager.enable = true;

  # System Packages
  environment.systemPackages = with pkgs; [
    vim
  ];

  # TODO: Later
  # # Mounting fileshare
  # fileSystems."/mnt/FreeNAS" = {
  #   device = "//freenas.cyn.internal/mediasnek2";
  #   fsType = "cifs";
  #   # TODO: UID should come from the user dynamically
  #   # noauto + x-systemd.automount - disables mounting this FS with mount -a & lazily mounts (when first accessed)
  #   # Remember to run `sudo umount /mnt/FreeNAS` before adding/removing "noauto" + "x-systemd.automount"
  #   options = [ "credentials=/run/secrets/smbcred" "noserverino" "rw" "_netdev" "uid=1000"] ++ ["noauto" "x-systemd.automount"];
  # };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}