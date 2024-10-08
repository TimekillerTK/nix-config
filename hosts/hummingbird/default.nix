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
  # sops.secrets.smbcred = { };

  # Adding CA root & intermediate certs
  security.pki.certificateFiles = [
    ../common/root-ca.pem
  ];

  # Bluetooth configuration
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Add printer autodiscovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

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
    vim
  ];

  # # Mounting fileshare
  # fileSystems."/mnt/mediasnek" = {
  #   device = "//freenas.cyn.internal/mediasnek2";
  #   fsType = "cifs";
  #   # TODO: UID should come from the user dynamically
  #   # noauto + x-systemd.automount - disables mounting this FS with mount -a & lazily mounts (when first accessed)
  #   # Remember to run `sudo umount /mnt/FreeNAS` before adding/removing "noauto" + "x-systemd.automount"
  #   options = [ "credentials=/run/secrets/smbcred" "noserverino" "rw" "_netdev" "uid=1000"] ++ ["noauto" "x-systemd.automount"];
  # };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
