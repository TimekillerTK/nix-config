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
  sops.defaultSopsFile = ./secrets.yml;
  sops.secrets.smbcred = { };
  sops.secrets.tailscale = { };

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
  networking.hostName = "tailscale";
  networking.networkmanager.enable = true;

  # Tailscale
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale";
    extraUpFlags = [
      "--advertise-tags=tag:router"
      "--advertise-routes=172.17.0.0/16"
    ];
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
