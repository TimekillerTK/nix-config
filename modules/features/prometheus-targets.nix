{
  # This module defines the option for PrometheusTargets used for the grafana host
  #
  # NOTE: For this to be usable, this MUST be imported for the config applied:
  # - inputs.self.modules.generic.prometheusTargets
  #
  # Then actually assign the value in the hosts config
  flake.modules.generic.prometheusTargets = {lib, ...}: {
    options.prometheusTargets = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "Targets collected from multiple features.";
    };
  };
}
