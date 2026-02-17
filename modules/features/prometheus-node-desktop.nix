{
  # Sets up a prometheus Node exporter which displays
  # metrics from a particular desktop to expose zfs
  # and systemd metrics aside from a ton of other things
  flake.modules.nixos.prometheus-node-desktop = let
    node_exporter_port = 9000;
    nau_exporter_port = 9001;
    zfs_exporter_port = 9134;
  in {
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
  };
}
