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
    ../common/users/tk
    ../common/optional/sops

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
  sops.secrets.smbcred = { };

  # Enable IPv4 forwarding
  # NOTE: Required for Tailscale subnet forwarding
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
  };

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

  # services.nextcloud = {
  #   enable = true;
  #   package = pkgs.nextcloud28;
  #   hostName = "nc.cyn.internal";
  #   autoUpdateApps.enable = true;
  #   database.createLocally = true;
  #   configureRedis = true;
  #   maxUploadSize = "16G";
  #   config = {
  #     dbtype = "pgsql";
  #     adminuser = "admin";
  #     adminpassFile = "/nextcloudtemp/adminpass";
  #   };
  #   # Suggested by Nextcloud's health check.
  #   phpOptions."opcache.interned_strings_buffer" = "16";
  # };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
