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
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd

    # Disko config
    ./disko.nix

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk
    ../common/optional/sops
    ../common/optional/zfs
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

  # VS Code Server Module (for VS Code Remote) 
  services.vscode-server.enable = true;

  # Actual SOPS keys
  sops.defaultSopsFile = ./secrets.yml;
  sops.secrets.smbcred = { };
  sops.secrets.tailscale = { };

  # TODO: This is busted, needs a fix
  # # Tailscale
  # services.tailscale = {
  #   enable = true;
  #   authKeyFile = "/run/secrets/tailscale";
  #   extraUpFlags = [
  #     "--advertise-tags=tag:usermachine"
  #   ];
  # };

  # Steam
  programs.steam.enable = true;

  # TODO: Test removing this, should be covered by nixos-hardware
  # Fingerprint reader service (does NOT work on login for KDE because of SDDM...)
  services.fprintd.enable = true;

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
  ];

  # Mounting fileshare
  fileSystems."/mnt/FreeNAS" = {
    device = "//freenas.cyn.internal/mediasnek2";
    fsType = "cifs";
    # TODO: UID should come from the user dynamically
    # noauto + x-systemd.automount - disables mounting this FS with mount -a & lazily mounts (when first accessed)
    # Remember to run `sudo umount /mnt/FreeNAS` before adding/removing "noauto" + "x-systemd.automount"
    options = [ "credentials=/run/secrets/smbcred" "noserverino" "rw" "_netdev" "uid=1000"] ++ ["noauto" "x-systemd.automount"];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}