{inputs, ...}: let
  hostName = "incus";
in {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" hostName;

  flake.modules.nixos."${hostName}" = {
    pkgs,
    config,
    ...
  }: {
    imports = [
      inputs.self.modules.nixos.system-minimal
      inputs.self.modules.nixos.home-manager
      inputs.self.modules.nixos.tk

      inputs.self.modules.nixos.prometheus-node-desktop
    ];
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
