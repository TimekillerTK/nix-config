{
  # This module defines the option for PrometheusTargets used for the grafana host
  #
  # NOTE: For this to be usable, this MUST be imported for the config applied (grafana
  # in our case, we'll use 'example_host' for example), and then used in the relevant section:
  #
  # -> modules/hosts/example_host.nix
  # flake.modules.nixos.example_host = {config, ...}: {
  #   imports = [
  #     inputs.self.modules.generic.prometheusTargets
  #   ];
  #   services.prometheus.scrapeConfigs = [
  #     {
  #       job_name = "example_job";
  #       static_configs = [
  #         {
  #           targets = config.prometheusTargets;
  #         }
  #       ];
  #     }
  #   ];
  # };
  #
  # Then, for each host we want to keep track of, in the hosts nix module, we
  # add a `flake.modules.nixos.example_host` section:
  #
  # -> modules/hosts/host_to_keep_track_of.nix
  # flake.modules.nixos.example_host = {
  #   prometheusTargets = [
  #     "http://host.url.here:9001/statefile.json"
  #   ];
  # };
  #
  flake.modules.generic.prometheusTargets = {lib, ...}: {
    options.prometheusTargets = lib.mkOption {
      type = lib.types.submodule {
        options = {
          nix_auto_update = lib.mkOption {
            type = with lib.types; listOf str;
            default = [];
            description = "List of hosts to monitor for nix-auto-update,
              expected format 'http://<host>:9001/statefile.json'";
          };
          zfs = lib.mkOption {
            type = with lib.types; listOf str;
            default = [];
            description = "List of hosts to monitor for ZFS metrics, expected format '<host>:9134'";
          };
          node_systemd = lib.mkOption {
            type = with lib.types; listOf str;
            default = [];
            description = "List of hosts using Node Exporter + systemd metrics,
               expected format '<host>:9000'";
          };
          harmonia = lib.mkOption {
            type = with lib.types; listOf str;
            default = [];
            description = "Harmonia server(s) metrics to monitor, expected format '<host>:5000'";
          };
          blackbox_url = lib.mkOption {
            type = with lib.types; listOf str;
            default = [];
            description = "List of URLs to monitor with prometheus blackbox exporter, expected
              format https://<host>";
          };
        };
      };
      default = {};
      description = "All kinds of Prometheus targets";
    };
  };
}
