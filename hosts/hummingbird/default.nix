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

    # Disko config
    ./disko.nix

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/astra
    ../common/optional/sops
    ../common/optional/zfs
    ../common/optional/kde-plasma6-x11
    ../common/optional/input-remapper
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

  # Actual SOPS keys
  sops.defaultSopsFile = ./secrets.yml;
  sops.secrets.smbcred = { };

  # Adding CA root & intermediate certs
  security.pki.certificateFiles = [
    ../common/root-ca.pem
  ];

  # Numlock on Login Screen (SDDM)
  services.xserver.displayManager.setupCommands = ''${pkgs.numlockx}/bin/numlockx on'';

  # Bluetooth configuration
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Add printer autodiscovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # OpenRGB (needs to run as root)
  services.hardware.openrgb.enable = true;

  # Steam
  programs.steam.enable = true;

  # Hostname & Network Manager
  networking.hostName = "hummingbird";
  networking.networkmanager = {
    enable = true;
  };

  # Generated with head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "16cc46d0"; # required for ZFS!

  # System Packages
  environment.systemPackages = with pkgs; [
    openrgb-with-all-plugins # RGB Control
    vim
  ];

  # Mounting fileshare
  fileSystems."/mnt/mediasnek" = {
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
