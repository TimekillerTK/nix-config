{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "dockerhost";

  flake.modules.nixos.dockerhost = {pkgs, ...}: let
    user = "tk";
  in {
    imports = [
      inputs.self.modules.generic.caddy_v284
      inputs.self.modules.nixos.system-cli

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

    # Newer LTS Kernel, pinned
    boot.kernelPackages = pkgs.linuxPackages_6_18;

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
        reverse_proxy 172.21.10.47:8096
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
      virtualHosts."grafana.cyn.internal".extraConfig = ''
        reverse_proxy 172.21.10.28:3000
      '';
      virtualHosts."prometheus.cyn.internal".extraConfig = ''
        reverse_proxy 172.21.10.28:9090
      '';

      # For our nix-cache, if it's offline, it will cause issues with
      # hosts trying to execute a nixos rebuild.
      #
      # This will instead change the 502s to 404s so that the fail will
      # cause other caches to be used instead
      virtualHosts."nix-cache.cyn.internal".extraConfig = ''
        @cacheInfo path /nix-cache-info
        handle @cacheInfo {
          respond `StoreDir: /nix/store
          WantMassQuery: 1
          Priority: 10` 200
        }

        @other path_regexp everything .*
        handle @other {
          reverse_proxy https://anya.cyn.internal:5000 {
            transport http {
              read_timeout 2s
              dial_timeout 1s
            }
          }
        }

        handle_errors {
          @bad502 expression `{http.error.status_code} == 502`
          @bad503 expression `{http.error.status_code} == 503`
          @bad504 expression `{http.error.status_code} == 504`

          handle @bad502 {
            respond 404
          }
          handle @bad503 {
            respond 404
          }
          handle @bad504 {
            respond 404
          }

          handle {
            respond 500
          }
        }
      '';
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
}
