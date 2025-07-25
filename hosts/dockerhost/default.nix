{
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}:
let
  username = "tk";
in
{
  imports = [

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/${username}
    ../common/optional/sops
    ../common/optional/mount-media
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

  # SOPS Secrets
  sops.secrets.smbcred = { };

  # Newer LTS Kernel, pinned
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # use default bash
  # TODO: find a better way to do this
  users.users.tk.shell = lib.mkForce pkgs.bash;
  users.users.tk.extraGroups = lib.mkForce [ "networkmanager" "wheel" "docker" ];

  # Hostname & Network Manager
  networking.hostName = "dockerhost";
  networking.networkmanager.enable = true;

  # Enable Docker
  virtualisation.docker = {
    enable = true;
  };

  # Caddy Config
  services.caddy = {
    enable = true;
    package = pkgs.caddy_v284.caddy; # Pinned version 2.8.4
    acmeCA = "https://ca.cyn.internal/acme/acme/directory";
    virtualHosts."localhost".extraConfig = ''
      respond "Hello, world on localhost!"
    '';
    virtualHosts."dockerhost.cyn.internal".extraConfig = ''
      respond "Hello, world on dockerhost.cyn.internal!"
    '';
    virtualHosts."whoami.cyn.internal".extraConfig = ''
      reverse_proxy localhost:8010
    '';
    virtualHosts."pdf.cyn.internal".extraConfig = ''
      reverse_proxy localhost:8020
    '';
    virtualHosts."torrent.cyn.internal".extraConfig = ''
      reverse_proxy localhost:8030
    '';
    virtualHosts."jellyfin.cyn.internal".extraConfig = ''
      reverse_proxy localhost:8040
    '';
    virtualHosts."cookbook.cyn.internal".extraConfig = ''
      reverse_proxy localhost:8050
    '';
    virtualHosts."sync.cyn.internal".extraConfig = ''
      reverse_proxy localhost:8060
    '';
    virtualHosts."home.cyn.internal".extraConfig = ''
      reverse_proxy 172.21.10.80:8123
    '';
    virtualHosts."moxfin.cyn.internal".extraConfig = ''
      reverse_proxy https://172.21.10.6:8006 {
        transport http {
            tls_insecure_skip_verify
        }
      }
    '';
  };

  # Open HTTP/HTTPS ports
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Adding CA root cert
  security.pki.certificateFiles = [
    ../common/root-ca.pem
  ];

  # Override mediashare filesystem path
  mediaShare.mediaSharePath = "/mnt/TrueNAS";

  # systemd units
  systemd.services.docker-compose-app = {
    description = "Running Docker-Compose";
    after = [ "network.target" ];

    serviceConfig = {
      Type = "simple";
      User = username;
      WorkingDirectory = "/home/${username}/docker";
      ExecStart = "${pkgs.docker}/bin/docker compose up";
      ExecStop = "${pkgs.docker}/bin/docker compose down";
    };

    wantedBy = [ "multi-user.target" ];
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
