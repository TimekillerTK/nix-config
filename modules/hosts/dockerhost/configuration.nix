{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "dockerhost";

  flake.modules.nixos.dockerhost = {pkgs, ...}: let
    user = "tk";
  in {
    imports = [
      inputs.self.modules.nixos.caddy-reverse-proxy
      inputs.self.modules.nixos.system-cli
      inputs.self.modules.nixos.prometheus-node-server
      (inputs.self.factory.nix-auto-update {})

      (inputs.self.factory.mount-cifs {
        shareName = "mediasnek3";
        shareLocalPath = "TrueNAS";
        shareUsers = [user];
        shareSecret = user;
      })

      inputs.self.modules.nixos.home-manager
      inputs.self.modules.nixos.tk
    ];

    # To activate the home manager modules for this user
    # for this host
    home-manager.users.tk = {
      imports = [
        inputs.self.modules.homeManager.system-cli
      ];
    };

    # Enable Docker
    virtualisation.docker = {
      enable = true;
    };

    # Hostname
    networking.hostName = "dockerhost";
    users.users.tk.extraGroups = ["docker"];

    # Open HTTP/HTTPS ports
    networking.firewall.allowedTCPPorts = [80 443];

    # systemd units
    systemd.services.docker-compose-app = {
      description = "Running Docker-Compose";
      after = ["network.target"];

      serviceConfig = {
        Type = "simple";
        User = user;
        WorkingDirectory = "/home/${user}/docker";
        ExecStart = "${pkgs.docker}/bin/docker compose up";
        ExecStop = "${pkgs.docker}/bin/docker compose down";
      };

      wantedBy = ["multi-user.target"];
    };
  };

  # Adding this host to the prometheus targets for the grafana host
  flake.modules.nixos.grafana = {
    prometheusTargets = {
      blackbox_url = [
        "https://cookbook.cyn.internal"
        "https://pdf.cyn.internal"
        "https://torrent.cyn.internal"
        "https://jellyfin.cyn.internal"
        "https://sync.cyn.internal"
        "https://home.cyn.internal"
        "https://torrent.cyn.internal"
        "https://ca.cyn.internal/acme/acme/directory"
      ];
      nix_auto_update = [
        "http://dockerhost.cyn.internal:9001/statefile.json"
      ];
      node_systemd = [
        "dockerhost.cyn.internal:9000"
      ];
    };
  };
}
