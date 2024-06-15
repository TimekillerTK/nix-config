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
  boot.kernelPackages = pkgs.linuxPackages_6_6;

  # use default bash
  # TODO: find a better way to do this
  users.users.tk.shell = lib.mkForce pkgs.bash;
  users.users.tk.extraGroups = lib.mkForce [ "networkmanager" "wheel" "docker" ];

  # Hostname & Network Manager
  networking.hostName = "dockerhost";
  networking.networkmanager.enable = true;

  # System Packages
  environment.systemPackages = with pkgs; [
    vim
  ];

  # Enable Docker
  virtualisation.docker = {
    enable = true;
  };

  # Caddy Config
  services.caddy = {
    enable = true;
    acmeCA = "https://ca.cyn.internal/acme/acme/directory";
    virtualHosts."localhost".extraConfig = ''
      respond "Hello, world on localhost!"
    '';
    virtualHosts."dockerhost.cyn.internal".extraConfig = ''
      respond "Hello, world on dev-dockerhost.cyn.internal!"
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
    virtualHosts."nc.cyn.internal".extraConfig = ''
      reverse_proxy 172.17.10.63
    '';
  };

  # Open HTTP/HTTPS ports
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Adding CA root cert
  security.pki.certificateFiles = [
    ../common/root-ca.pem
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

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
