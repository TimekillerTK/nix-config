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
    # Actual SOPS keys
    sops.secrets.id_ed25519 = {
      sopsFile = ../../../secrets/host_keys/nix_cache.yml;
      path = "/etc/ssh/ssh_host_ed25519_key";
      owner = "root";
      group = "root";
      mode = "0600";
    };

    # TODO: Work in progress testing, checking if this hostkey is set correctly
    services.openssh.hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
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
