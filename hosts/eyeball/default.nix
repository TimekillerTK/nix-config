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
    globalConfig.scrape_interval = "5s"; # TODO: change to ~1m for prod
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = ["localhost:9090"];
          }
        ];
      }
      {
        job_name = "node-systemd";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.prometheus.exporters.node.port}"];
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
  };

  # TODO: Systemd service for testing, remove later
  services.nginx.enable = true;

  # For accessing the WebUI remotely
  # TODO: Better way?
  networking.firewall.allowedTCPPorts = [9090 80];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
