{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
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

  services.nextcloud = {
    enable = true;
    hostName = "nc.cyn.internal";
    # Need to manually increment with every major upgrade.
    package = pkgs.nextcloud30;
    # Let NixOS install and configure the database automatically.
    database.createLocally = true;
    # Let NixOS install and configure Redis caching automatically.
    configureRedis = true;
    # Increase the maximum file upload size.
    maxUploadSize = "16G";
    # https = true;
    autoUpdateApps.enable = true;
    extraAppsEnable = true;
    extraApps = with config.services.nextcloud.package.packages.apps; {
      # List of apps we want to install and are already packaged in
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
      inherit cookbook;
    };
    settings = {
      trusted_proxies = [ "172.17.10.216" ]; # NC Recommended setting
      overwriteprotocol = "https";
      default_phone_region = "NL";
    };
    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      # TODO: Temporarily touched, replace with SOPS
      adminpassFile = "/nextcloud_pw.txt";
    };
    # Suggested by Nextcloud's health check.
    phpOptions."opcache.interned_strings_buffer" = "16";
  };

  # Open HTTP/HTTPS ports
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
