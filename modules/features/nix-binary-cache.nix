{inputs, ...}: {
  # Nix Binary Cache implemented with harmonia
  flake.modules.nixos.nix-binary-cache = {
    imports = [
      inputs.harmonia.nixosModules.harmonia
    ];

    networking.firewall.allowedTCPPorts = [5000];

    # NOTE: This is harmonia-dev because we're using the nix flake
    # in our flake inputs to have the newer 3.0.0 version instead
    # of the 2.1.0 currently in nixpkgs
    #
    # Debugging commands from a client to see if it works:
    #
    #   nix path-info /nix/store/5xp8g23q7ii1vn00j1ps9wi5cprj9zlp-renamer-0.1.4 --store https://nix-cache.cyn.internal
    #   nix store info --store https://nix-cache.cyn.internal
    #   curl "http://nix-cache.cyn.internal/5xp8g23q7ii1vn00j1ps9wi5cprj9zlp.narinfo"
    #   nix build nixpkgs#renamer --dry-run
    services.harmonia-dev = {
      cache.enable = true;
      # This secret was generated following instructions on:
      # https://github.com/nix-community/harmonia/blob/4e9e03e04467b50575f6b05c8abee12407418106/README.md
      #
      # nix-store --generate-binary-cache-key nix-cache.cyn.internal /var/lib/secrets/harmonia.secret /var/lib/secrets/harmonia.pub
      cache.signKeyPaths = ["/var/lib/secrets/harmonia.secret"];
    };

    # Setting up the server to send remote builds for x86_64-linux to another
    # host, which will be our builder
    sops.secrets.builder_key = {};
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
