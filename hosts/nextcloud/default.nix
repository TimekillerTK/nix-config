{
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}: 
{
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

  # use default bash
  # TODO: find a better way to do this
  users.users.tk.shell = lib.mkForce pkgs.bash;
  users.users.tk.extraGroups = lib.mkForce [ "networkmanager" "wheel" "docker" ];
 
  # Hostname & Network Manager
  networking.hostName = "nextcloud";
  networking.networkmanager.enable = true;

  # System Packages
  environment.systemPackages = with pkgs; [
    vim
  ];

  nextcloud = {
    enable = true;
    hostName = "nc.cyn.internal";
    # Need to manually increment with every major upgrade.
    package = pkgs.nextcloud28;
    # Let NixOS install and configure the database automatically.
    database.createLocally = true;
    # Let NixOS install and configure Redis caching automatically.
    configureRedis = true;
    # Increase the maximum file upload size.
    maxUploadSize = "16G";
    https = true;
    autoUpdateApps.enable = true;
    config = {
      overwriteProtocol = "https";
      defaultPhoneRegion = "NL";
      dbtype = "pgsql";
      adminuser = "admin";
      # TODO: Temporarily touched, replace with SOPS
      adminpassFile = "/nextcloud_pw.txt";
    };
    # Suggested by Nextcloud's health check.
    phpOptions."opcache.interned_strings_buffer" = "16";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
