{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk
  ];

  # Overlays
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.other-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  # Required for our user
  users.users.tk.shell = lib.mkForce pkgs.bash;

  # Hostname & Network Manager
  networking.hostName = "eyeball";
  networking.networkmanager.enable = true;

  # Adding CA root cert
  security.pki.certificateFiles = [
    ../common/root-ca.pem
  ];

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "5s";
    scrapeConfigs = [
      # JSON exporter metrics
      {
        job_name = "nix_auto_update";
        metrics_path = "/probe";
        static_configs = [
          {
            targets = [
              "http://anya.cyn.internal:9001/statefile.json"
              "http://hummingbird.cyn.internal:9001/statefile.json"
              "http://beltanimal-eth.cyn.internal:9001/statefile.json"
            ];
          } # What is serving target JSON file
        ];
        params = {
          module = ["default"];
        };
        # We need to help prometheus find
        # > http://<IPADDRESSHERE>:7979/probe?target=http://anya.cyn.internal:9001/statefile.json
        relabel_configs = [
          {
            source_labels = ["__address__"];
            target_label = "__param_target";
          }
          {
            source_labels = ["__param_target"]; # set instance label to target anya.cyn.internal:9001
            target_label = "instance";
          }
          {
            target_label = "__address__"; # replace anya.cyn.internal:9001 with localhost:7979 for scraping JSON exporter (NOT our target exposing the JSON file)
            replacement = "localhost:7979";
          }
        ];
      }

      # Prometheus metrics for prometheus
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = ["localhost:9090"];
          }
        ];
      }

      # Blocky DNS server metrics for prometheus
      {
        job_name = "blocky_dns";
        static_configs = [
          {
            targets = ["172.21.10.5:4000"];
          }
        ];
      }

      # ZFS Pool metrics for prometheus
      {
        job_name = "zfs";
        static_configs = [
          {
            targets = [
              "anya.cyn.internal:9134"
              "hummingbird.cyn.internal:9134"
              "beltanimal-eth.cyn.internal:9134"
            ];
          }
        ];
      }

      # Node exporter + systemd metrics
      {
        job_name = "node-systemd";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.exporters.node.port}"
              "anya.cyn.internal:${toString config.services.prometheus.exporters.node.port}"
              "hummingbird.cyn.internal:${toString config.services.prometheus.exporters.node.port}"
              "beltanimal-eth.cyn.internal:${toString config.services.prometheus.exporters.node.port}"
            ];
          }
        ];
      }

      # Blackbox exporter - HTTPS
      {
        job_name = "blackbox";
        metrics_path = "/probe";
        params.module = ["https_ca"];
        static_configs = [
          {
            targets = [
              "https://cookbook.cyn.internal"
              "https://pdf.cyn.internal"
              "https://torrent.cyn.internal"
              "https://jellyfin.cyn.internal"
              "https://sync.cyn.internal"
              "https://home.cyn.internal"
              "https://torrent.cyn.internal"
              "https://ca.cyn.internal/acme/acme/directory"
            ];
          }
        ];
        relabel_configs = [
          {
            source_labels = ["__address__"];
            target_label = "__param_target";
          }
          {
            source_labels = ["__param_target"];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "localhost:9115";
          }
        ];
      }

      # Blackbox exporter - DNS
      {
        job_name = "blackbox-dns";
        metrics_path = "/probe";
        params.module = ["dns_check"];
        static_configs = [
          {
            targets = [
              "1.1.1.1"
              "8.8.8.8"
              "172.21.10.5"
            ];
          }
        ];
        relabel_configs = [
          {
            source_labels = ["__address__"];
            target_label = "__param_target";
          }
          {
            source_labels = ["__param_target"];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "localhost:9115";
          }
        ];
      }
    ];
    exporters.node = {
      enable = true;
      port = 9000;
      enabledCollectors = ["systemd"];
      openFirewall = true;
    };
    exporters.json = {
      enable = true;
      port = 7979;
      openFirewall = true;
      configFile = pkgs.writeText "json-exporter.yml" ''
        # NOTE: The returned value here for status is a dummy value
        # not indicating anything, we need to match on the status
        # string to see whether it is:
        #
        # - InProgress
        # - ExitFail
        # - ExitSuccess
        modules:
          default:
            metrics:
            - name: nix_auto_update
              type: object
              help: Service Status
              path: '{$}' # pointing at root
              labels:
                status: '{ .status }'
              values:
                status: 1 # dummy, static value
      '';
    };
    exporters.blackbox = {
      enable = true;
      port = 9115;
      openFirewall = true;
      configFile = pkgs.writeText "blackbox.yml" ''
        modules:
          # NOTE: Our custom CA cert is added via security.pki.certificateFiles
          # and DOES NOT need to be added here to `tls_config`.
          https_ca: # <- arbitrary
            prober: http
            timeout: 5s
            http:
              method: GET
              fail_if_not_ssl: true
          dns_check: # <- arbitrary
            prober: dns
            timeout: 5s
            dns:
              transport_protocol: udp
              preferred_ip_protocol: ip4
              query_name: "example.com"
      '';
    };
  };

  services.grafana = {
    enable = true;
    settings = {
      analytics.reporting_enabled = false;
      server = {
        http_addr = "0.0.0.0"; # TODO: Change for prod
        http_port = 3000;
        enable_gzip = true; # recommended default
        domain = "grafana.cyn.internal";
        root_url = "%(protocol)s://%(domain)s/";
        protocol = "https";
      };
    };
    # Delcarative configuration for Grafana
    provision = {
      enable = true;
      dashboards.settings.providers = [
        {
          # Setting where to look for our dashboards
          name = "Declarative Dashboards";
          disableDeletion = true;
          options = {
            path = "/etc/grafana-dashboards";
            foldersFromFilesStructure = true;
          };
        }
      ];
      datasources.settings = {
        # When true, provisioned datasources from this file will be deleted automatically
        # when removed from services.grafana.provision.datasources.settings.datasources.
        prune = true;

        datasources = [
          # Provisioning a built-in data source
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://localhost:9090";
            isDefault = true;
            editable = false;
          }
        ];
      };
    };
  };

  # NOTE: https://grafana.com/grafana/dashboards/13659-blackbox-exporter-http-prober/
  # used for dashboard inspiration for HTTP
  # This is where our custom Grafana dashboard is
  environment.etc = {
    "grafana-dashboards/grafana-main-status.json" = {
      source = ./grafana-main-status.json;
    };
    "grafana-dashboards/grafana-blocky-dns.json" = {
      source = ./grafana-blocky-dns.json;
    };
  };

  # For accessing the WebUI remotely
  # TODO: Better way?
  networking.firewall.allowedTCPPorts = [80 3000 9090 9000];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
