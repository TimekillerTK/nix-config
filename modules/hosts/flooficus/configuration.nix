{inputs, ...}: let
  hostName = "flooficus";
in {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" hostName;

  flake.modules.nixos."${hostName}" = {
    pkgs,
    config,
    ...
  }: {
    imports = [
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

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";

    # Keeping fallback bootloader in sync, just in case one of the disks fail
    boot.loader.systemd-boot.extraInstallCommands = ''
      ${pkgs.rsync}/bin/rsync -a --delete /boot/ /boot-fallback/
    '';
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
