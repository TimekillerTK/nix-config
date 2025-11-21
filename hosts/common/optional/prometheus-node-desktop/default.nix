{...}: let
  node_exporter_port = 9000;
  nau_exporter_port = 9001;
  zfs_exporter_port = 9134;
in {
  # NOTE: this does NOT set up prometheus itself!
  services.prometheus = {
    # Sets up a node exporter for prometheus node metrics
    exporters.node = {
      enable = true;
      port = node_exporter_port;
      enabledCollectors = ["systemd"];
      openFirewall = true;
    };
    # Sets up an exporter for information about ZFS pool data
    exporters.zfs = {
      enable = true;
      port = zfs_exporter_port;
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
