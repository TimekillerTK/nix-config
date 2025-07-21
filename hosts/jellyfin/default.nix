{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk
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

  boot.kernelPackages = pkgs.linuxPackages_6_15;

  # Required for our user
  users.users.tk.shell = lib.mkForce pkgs.bash;
  users.users.tk.extraGroups = lib.mkForce [ "networkmanager" "wheel" ];

  # Hostname & Network Manager
  networking.hostName = "jellyfin";
  networking.networkmanager.enable = true;

  # Adding CA root cert
  security.pki.certificateFiles = [
    ../common/root-ca.pem
  ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
