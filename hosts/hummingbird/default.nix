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
    ../common/optional/kde-plasma6-wayland
    ../common/optional/input-remapper
    ../common/optional/mount-media
    ../common/optional/mount-important
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

  # Numlock on boot
  boot.initrd.preLVMCommands = ''
    ${pkgs.kbd}/bin/setleds +num
  '';

  # Actual SOPS keys
  sops.defaultSopsFile = ./secrets.yml;
  sops.secrets.smbcred = {};

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

    # # Numlock on Wayland
    # numlockw
  ];

  # # Create a systemd user service
  # systemd.user.services.numlock-on-startup = {
  #   description = "Enable NumLock on startup";
  #   wantedBy = [ "default.target" ];
  #   after = [ "display-manager.service" ];

  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = "${pkgs.numlockw}/bin/numlockw --device-name 'Corsair CORSAIR K70 RGB MK.2 LOW PROFILE Mechanical Gaming Keyboard' --no-fake-uinput on";
  #   };
  # };

  # Override mediashare filesystem path
  mediaShare.mediaSharePath = "/mnt/mediasnek";

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
