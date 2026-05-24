{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "tailscale";

  flake.modules.nixos.tailscale = {
    imports = [
      inputs.self.modules.nixos.system-minimal
      inputs.self.modules.nixos.prometheus-node-server
      # (inputs.self.factory.nix-auto-update {})

      inputs.self.modules.nixos.home-manager
      inputs.self.modules.nixos.tk
    ];
    home-manager.users.tk = {
      imports = [
        inputs.self.modules.homeManager.system-minimal
      ];
      # Normal home-manager config stuff goes here
    };

    # Secret key to authorize with tailscale
    sops.secrets.tailscale = {
      sopsFile = ../../../secrets/tailscale.yml;
    };

    # Enable IPv4 forwarding
    # NOTE: Required for Tailscale subnet forwarding
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
    };

    # Hostname & Network Manager
    networking.hostName = "tailscale";

    # Tailscale
    # TODO: This doesn't actually advertise the routes as it should
    # find a way to make this work, because the extraUpFlags don't
    # seem to work.
    # What works is the command instead:
    # -> sudo tailscale set --advertise-routes=172.21.10.0/24,192.168.0.0/24
    services.tailscale = {
      enable = true;
      authKeyFile = "/run/secrets/tailscale";
      extraUpFlags = [
        "--advertise-tags=tag:router"
        "--advertise-routes=172.21.10.0/24,192.168.0.0/24"
      ];
    };
  };

  # Adding this host to the prometheus targets for the grafana host
  flake.modules.nixos.grafana = {
    prometheusTargets = {
      nix_auto_update = [
        "http://host.ts.cyn.internal:9001/statefile.json"
      ];
      node_systemd = [
        "host.ts.cyn.internal:9000"
      ];
    };
  };
}
