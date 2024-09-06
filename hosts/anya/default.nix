{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    # # Required for VS Code Remote
    # inputs.vscode-server.nixosModules.default

    # Required for disk configuration
    # inputs.disko.nixosModules.default

    # Disko config
    # ./disko.nix

    # Generated (nixos-generate-config) hardware configuration
    # ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk
    # ../common/optional/sops
    # ../common/optional/zfs
    ../common/optional/kde-plasma-x11
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

  # # VS Code Server Module (for VS Code Remote)
  # services.vscode-server.enable = true;

  # # Actual SOPS keys
  # sops.secrets.smbcred = { };
  # sops.secrets.tailscale = { };

  # Adding CA root & intermediate certs
  security.pki.certificateFiles = [
    ../common/root-ca.pem
  ];

  # # Bluetooth configuration
  # hardware.bluetooth.enable = true; # enables support for Bluetooth
  # hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Add printer autodiscovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # # Tailscale
  # services.tailscale = {
  #   enable = true;
  #   authKeyFile = "/run/secrets/tailscale";
  #   extraUpFlags = [
  #     "--advertise-tags=tag:usermachine"
  #     "--accept-routes"
  #   ];
  # };

  # Steam
  programs.steam.enable = true;

  # # Temporary
  # nixpkgs.config.permittedInsecurePackages = [
  #   "electron-27.3.11"
  # ];

  # For remapping HIDs
  # TODO: Needs to be started with sudo permissions automatically on login (?)
  services.input-remapper = {
    enable = true;
    package = pkgs.unstable.input-remapper;
  };

  # Hostname & Network Manager
  networking.hostName = "anya";
  networking.networkmanager = {
    enable = true;
  };

  # Generated with head -c4 /dev/urandom | od -A none -t x4
  # networking.hostId = "7d650d06"; # required for ZFS!

  # System Packages
  environment.systemPackages = with pkgs; [
    vim
    kdePackages.kdialog # pops up dialogs
  ];

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
