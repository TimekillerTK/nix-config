{inputs, ...}: let
  hostName = "flooficus";
in {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" hostName;

  flake.modules.nixos."${hostName}" = {
    pkgs,
    config,
    lib,
    ...
  }: {
    imports = [
      inputs.lanzaboote.nixosModules.lanzaboote

      # Filesystems on this host are defined with disko
      inputs.disko.nixosModules.default
      ./_disko.nix

      inputs.self.modules.nixos.system-minimal
      inputs.self.modules.nixos.prometheus-node-desktop
      inputs.self.modules.nixos.zfs

      inputs.self.modules.nixos.home-manager
      inputs.self.modules.nixos.tk
    ];
    home-manager.users.tk = {
      imports = [
        inputs.self.modules.homeManager.system-minimal
      ];
      # Normal home-manager config stuff goes here
    };

    # Hostname
    networking.hostName = hostName;

    # Generated with head -c4 /dev/urandom | od -A none -t x4
    networking.hostId = "e0383bfd"; # required for ZFS!

    # Static IP for this host (important)
    networking.useDHCP = false;
    networking.interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "172.21.10.3";
          prefixLength = 24;
        }
      ];
    };
    networking.defaultGateway = "172.21.10.1";
    networking.nameservers = ["172.21.10.5" "172.21.10.7"];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";
  };

  # Adding this host to the prometheus targets for the grafana host
  flake.modules.nixos.grafana = {
    prometheusTargets = {
      zfs = [
        "${hostName}.cyn.internal:9134"
      ];
      node_systemd = [
        "${hostName}.cyn.internal:9000"
      ];
    };
  };
}
