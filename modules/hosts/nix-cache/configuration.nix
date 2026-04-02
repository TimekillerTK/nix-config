{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "nix-cache";

  flake.modules.nixos.nix-cache = {
    imports = [
      # Filesystems on this host are defined with disko
      inputs.disko.nixosModules.default
      ./_disko.nix

      inputs.self.modules.nixos.nix-binary-cache
      inputs.self.modules.nixos.system-minimal
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
    networking.hostName = "nix-cache";
  };

  # Adding this host to the prometheus targets for the grafana host
  flake.modules.nixos.grafana = {
    prometheusTargets = {
      harmonia = [
        "host.nix-cache.cyn.internal:5000"
      ];
    };
  };
}
