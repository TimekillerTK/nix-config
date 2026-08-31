{inputs, ...}: {
  # Sets up a reverse proxy on a host it's installed on which points to
  # specific hosts
  config.flake.factory.caddy-reverse-proxy = {dockerHost}: {pkgs, ...}: {
    imports = [
      inputs.self.modules.generic.caddy_v284
    ];

    # NOTE: On a fresh host using caddy, this may be an issue:
    #
    # The account exists in Caddy's local storage but the CA server no longer recognizes it. On the CA side, the account
    # could have been deleted (Step CA DB corruption, server rebuild, etc.) or the account key may not match. When Caddy
    # sends a newOrder signed with the stored key, Step CA can't verify the JWS signature against any known account and
    # returns "malformed request."
    #
    # To fix, clear the ACME account state on dns-backup to force Caddy to re-register:
    # ssh tk@ip-address sudo systemctl stop caddy
    # ssh tk@ip-address sudo rm -rf /var/lib/caddy/.local/share/caddy/acme
    # ssh tk@ip-address sudo systemctl start caddy
    services.caddy = {
      enable = true;
      package = pkgs.caddy_v284.caddy; # Pinned version 2.8.4
      acmeCA = "https://ca.cyn.internal/acme/acme/directory";

      # Sets automatic renewal to be more frequent than default
      # - cert max/default duration set in `modules/hosts/ca/ca.json`
      # - cert renewal is set here (168h - 16h) / 168 = 0.904762
      globalConfig = ''
        renewal_window_ratio 0.904762
      '';

      virtualHosts."dockerhost.cyn.internal".extraConfig = ''
        respond "Hello, world on dockerhost.cyn.internal!"
      '';
      virtualHosts."backup-proxy.cyn.internal".extraConfig = ''
        respond "Hello, world on backup-proxy.cyn.internal!"
      '';
      virtualHosts."whoami.cyn.internal".extraConfig = ''
        reverse_proxy ${dockerHost}:8010
      '';
      virtualHosts."pdf.cyn.internal".extraConfig = ''
        reverse_proxy ${dockerHost}:8020
      '';
      virtualHosts."torrent.cyn.internal".extraConfig = ''
        reverse_proxy ${dockerHost}:8030
      '';
      virtualHosts."jellyfin.cyn.internal".extraConfig = ''
        reverse_proxy 172.21.10.47:8096
      '';
      virtualHosts."cookbook.cyn.internal".extraConfig = ''
        reverse_proxy ${dockerHost}:8050
      '';
      virtualHosts."sync.cyn.internal".extraConfig = ''
        reverse_proxy ${dockerHost}:8060
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
      #
      # NOTE: This can be removed if there is a nice fix/workaround
      # for this in nix, but currently there is not
      virtualHosts."nix-cache.cyn.internal".extraConfig = ''
        @cacheInfo path /nix-cache-info
        handle @cacheInfo {
          respond `StoreDir: /nix/store
          WantMassQuery: 1
          Priority: 10` 200
        }

        @other path_regexp everything .*
        handle @other {
          reverse_proxy http://172.21.10.229:5000 {
            transport http {
              dial_timeout 5s
              read_timeout 300s
              response_header_timeout 30s
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

    # Open HTTP/HTTPS ports
    networking.firewall.allowedTCPPorts = [80 443];
  };
}
