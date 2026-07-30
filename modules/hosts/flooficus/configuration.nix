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

    # Lanzaboote used here for redundant ESP partitions
    boot.loader.systemd-boot.enable = lib.mkForce false;
    environment.systemPackages = [pkgs.sbctl];
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      extraEfiSysMountPoints = ["/boot-fallback"];
    };
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
