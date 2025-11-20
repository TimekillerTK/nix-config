{...}: let
  node_exporter_port = 9000;
  nau_exporter_port = 9001;
in {
  # Sets up a node exporter for prometheus metrics
  # NOTE: this does NOT set up prometheus itself!
  services.prometheus = {
    exporters.node = {
      enable = true;
      port = node_exporter_port;
      enabledCollectors = ["systemd"];
      openFirewall = true;
    };
  };

  # For nix-auto-update
  services.static-web-server = {
    enable = true;
    root = "/var/lib/nix-auto-update";
    listen = "[::]:${toString nau_exporter_port}";
    configuration.general.directory-listing = false;
  };
  networking.firewall.allowedTCPPorts = [nau_exporter_port];
}
