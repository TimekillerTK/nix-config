{inputs, ...}: {
  # Defining one of our hosts as a build machine
  flake.modules.nixos.nix-build-machine-settings = {
    # Setting up the server to send remote builds for x86_64-linux to another
    # host, which will be our builder
    sops.secrets.builder_key = {
      sopsFile = ../../secrets/builder_key.yml;
    };
    nix.distributedBuilds = true;
    nix.buildMachines = [
      {
        hostName = "anya.cyn.internal";
        system = "x86_64-linux"; # what arch builds to send
        protocol = "ssh";
        maxJobs = 4; # concurrent builds on builder
        speedFactor = 2; # relative to local builds
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        mandatoryFeatures = [];
        sshUser = "tk"; # user on the builder
        sshKey = "/run/secrets/builder_key"; # private key used by nix daemon
      }
    ];

    nix.settings = {
      # WARNING: setting max-jobs to 0 will cause ALL builds to fail
      # if the remote builder is unavailable. Keep at value != 0 to ensure
      # we can still build if the remote builder is offline
      max-jobs = "auto";
      builders-use-substitutes = true; # let builder use caches, why not?
    };
  };
}
