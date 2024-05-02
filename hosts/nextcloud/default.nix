{
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}:
let mypath = "/nextcloud"; in
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

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud28;
    hostName = "az-blue";
    autoUpdateApps.enable = true;
    configureRedis = true;
    config = {
    # Further forces Nextcloud to use HTTPS

    # Nextcloud PostegreSQL database configuration, recommended over using SQLite
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "${mypath}/nix-nextcloud/db"; # nextcloud will add /.s.PGSQL.5432 by itself
      dbname = "nextcloud";
      dbpassFile = "/var/nextcloud-db-pass";
      adminpassFile = "/var/nextcloud-admin-pass";
    };
  };

  #creates the correct user password files
  systemd.services.create-pass-files = {
      wantedBy = [ "multi-user.target" ];
      before = [ "nextcloud-setup.service" ]; # Ensures this runs before nextcloud-setup
      script = ''
          echo "PWD" > /var/nextcloud-db-pass
          echo "PWD" > /var/nextcloud-admin-pass
          chown nextcloud:nextcloud /var/nextcloud-db-pass
          chown postgres:nextcloud /var/nextcloud-admin-pass
          chmod 0644 /var/nextcloud-db-pass
          chmod 0644 /var/nextcloud-admin-pass
      '';
  };

  services.postgresql = {
    enable = true;
  # Ensure the database, user, and permissions always exist
    ensureDatabases = [ "nextcloud" ];
    dataDir = "${mypath}/nix-nextcloud/db";
  };

  systemd.services."nextcloud-setup" = {
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
