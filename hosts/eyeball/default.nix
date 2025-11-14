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
            # targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
            targets = ["localhost:9090"];
          }
        ];
      }
      {
        job_name = "demo";
        static_configs = [
          {
            targets = [
              "demo.promlabs.com:10000"
              "demo.promlabs.com:10001"
              "demo.promlabs.com:10002"
            ];
          }
        ];
      }
    ];
    # exporters.node = {
    #   enable = true;
    #   port = 9000;
    #   enabledCollectors = ["systemd"];
    #   openFirewall = true;
    # };
  };

  # For accessing the WebUI remotely
  # TODO: Better way?
  networking.firewall.allowedTCPPorts = [9090];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
