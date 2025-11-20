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
              path: '{$}'
              labels:
                status: '{ .status }'
              values:
                status: 1 # dummy, static value
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

  # This is where our custom Grafana dashboard is
  environment.etc = {
    "grafana-dashboards/grafana-nix-auto-update.json" = {
      source = ./grafana-nix-auto-update.json;
    };
  };

  # TODO: Testing....
  systemd.services.test = {
    description = "test";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/sleep 15 && ${pkgs.coreutils}/bin/cat /home/tk/hardware-configuration.nix'";
      User = "root";
      TimeoutStartSec = "30min";

      # This makes systemd consdier the service active even after the
      # process exits, which we use for prometheus systemd monitoring
      RemainAfterExit = "yes";
    };
  };
  systemd.timers.test = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*:0/15"; # Run once every 15 minutes
      RandomizedDelaySec = "300"; # Random delay up to 5 minutes
    };
  };

  # TODO: Systemd service for testing, remove later
  services.nginx.enable = true;

  # For accessing the WebUI remotely
  # TODO: Better way?
  networking.firewall.allowedTCPPorts = [80 3000 9090 9000];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
