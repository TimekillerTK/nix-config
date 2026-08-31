{
  # Sets up a reverse proxy on a host it's installed on which points to
  # specific hosts
  config.flake.factory.caddy-reverse-proxy = {dockerHost}: {...}: let
    # NOTE: This is set deliberately per each virtualHost, NOT a global
    # `cert_issuer` or `acmeCA` option.
    #
    # Caddy's `caddyhttp/autohttps.go` decides whether a hostname needs the
    # internal/self-signed issuer by checking whether it already has an EXPLICIT
    # automation policy. The global `cert_issuer`/`acmeCA` option only ever
    # produces a "catch-all" policy, which WILL never match.
    #
    # Every `.internal` name fails certmagic's public-cert qualification
    # (`.internal` isn't a publicly issuable TLD) -> each one then gets silently
    # reassigned to Caddy's internal CA with no warning or error.
    #
    # Putting `tls { issuer acme ... }` DIRECTLY in each virtualHost makes
    # the automation policy explicit and named per host, which auto-HTTPS
    # correctly recognizes, so it leaves the issuer alone.
    #
    # Works in Caddy v2.11.4 & confirmed via step-ca access logs (zero ACME
    # requests reaching it under the old global-option config).
    #
    # ===================================================================
    # Any new virtualHost added below -MUST- include this block,
    # or it will silently get a self-signed cert instead of one from
    # ca.cyn.internal (!)
    # ===================================================================
    acmeIssuer = ''
      tls {
        issuer acme https://ca.cyn.internal/acme/acme/directory

        # Sets automatic renewal to be more frequent than default
        # - cert max/default duration set in `modules/hosts/ca/ca.json`
        # - cert renewal is set here (168h - 16h) / 168 = 0.904762
        renewal_window_ratio 0.904762
      }
    '';
  in {
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

      # NOTE: Temporarily raised from the module's default (`level ERROR`)
      # to `level INFO` so cert issuance/renewal activity is visible in the
      # journal while verifying the per-virtualHost ACME issuer fix below.
      logFormat = "level INFO";

      virtualHosts."dockerhost.cyn.internal".extraConfig = ''
        ${acmeIssuer}
        respond "Hello, world on dockerhost.cyn.internal!"
      '';
      # TODO: Reactivate later, removed while testing. Also has a
      # separate/unrelated stale-ACME-account issue (see note above) that
      # will need to be resolved first. When re-enabled, include
      # `${acmeIssuer}` like the other virtualHosts below.
      # virtualHosts."backup-proxy.cyn.internal".extraConfig = ''
      #   ${acmeIssuer}
      #   respond "Hello, world on backup-proxy.cyn.internal!"
      # '';
      virtualHosts."whoami.cyn.internal".extraConfig = ''
        ${acmeIssuer}
        reverse_proxy ${dockerHost}:8010
      '';
      virtualHosts."pdf.cyn.internal".extraConfig = ''
        ${acmeIssuer}
        reverse_proxy ${dockerHost}:8020
      '';
      virtualHosts."torrent.cyn.internal".extraConfig = ''
        ${acmeIssuer}
        reverse_proxy ${dockerHost}:8030
      '';
      virtualHosts."jellyfin.cyn.internal".extraConfig = ''
        ${acmeIssuer}
        reverse_proxy 172.21.10.47:8096
      '';
      virtualHosts."cookbook.cyn.internal".extraConfig = ''
        ${acmeIssuer}
        reverse_proxy ${dockerHost}:8050
      '';
      virtualHosts."sync.cyn.internal".extraConfig = ''
        ${acmeIssuer}
        reverse_proxy ${dockerHost}:8060
      '';
      virtualHosts."home.cyn.internal".extraConfig = ''
        ${acmeIssuer}
        reverse_proxy 172.21.10.80:8123
      '';
      virtualHosts."grafana.cyn.internal".extraConfig = ''
        ${acmeIssuer}
        reverse_proxy 172.21.10.28:3000
      '';
      virtualHosts."prometheus.cyn.internal".extraConfig = ''
        ${acmeIssuer}
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
        ${acmeIssuer}
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
