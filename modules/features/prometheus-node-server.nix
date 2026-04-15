{
  # Sets up a prometheus Node exporter which displays
  # metrics from a particular server to expose
  # systemd metrics aside from a ton of other things
  flake.modules.nixos.prometheus-node-server = let
    node_exporter_port = 9000;
  in {
    services.prometheus = {
      # Sets up a node exporter for prometheus node metrics
      exporters.node = {
        enable = true;
        port = node_exporter_port;
        enabledCollectors = ["systemd"];
        openFirewall = true;
      };
    };
  };
}
