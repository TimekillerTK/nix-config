{
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    # Required for VS Code Remote
    inputs.vscode-server.nixosModules.default

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/optional/sops
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

  # Actual SOPS keys
  sops.defaultSopsFile = ../common/secrets.yml;
  sops.secrets.smbcred = { };

  # use default bash
  # TODO: find a better way to do this
  users.users.tk.shell = lib.mkForce pkgs.bash;
  users.users.tk.extraGroups = lib.mkForce [ "networkmanager" "wheel" "docker" ];

  # VS Code Server Module (for VS Code Remote) 
  services.vscode-server.enable = true;

  # Hostname & Network Manager
  networking.hostName = "nextcloud";
  networking.networkmanager.enable = true;

  # System Packages
  environment.systemPackages = with pkgs; [
    vim
  ];

  services.nginx.virtualHosts = {
    "nc.cyn.internal" = {
      forceSSL = true;
      enableACME = true;
    };
  };

  services.nextcloud = {
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
      adminpassFile = "/nextcloudtemp/adminpass";
    };

    # Suggested by Nextcloud's health check.
    phpOptions."opcache.interned_strings_buffer" = "16";
  };

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
