{inputs, ...}: {
  # Nix Binary Cache implemented with harmonia
  flake.modules.nixos.nix-binary-cache = {pkgs, ...}: {
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
    #
    services.harmonia-dev = {
      cache.enable = true;
      # This secret was generated following instructions on:
      # https://github.com/nix-community/harmonia/blob/4e9e03e04467b50575f6b05c8abee12407418106/README.md
      #
      # nix-store --generate-binary-cache-key nix-cache.cyn.internal /var/lib/secrets/harmonia.secret /var/lib/secrets/harmonia.pub
      #
      # Specifically the harmonia.secret
      cache.signKeyPaths = ["/run/secrets/harmonia_key"];

      # Enable nix daemon replacement
      daemon.enable = true;
    };

    sops.secrets.builder_key = {
      sopsFile = ../../secrets/builder_key.yml;
    };
    sops.secrets.harmonia_key = {
      sopsFile = ../../secrets/harmonia_key.yml;
    };

    # Setting up the builder user, which our build host will be able to use
    # to nix copy packages to this nix cache server
    users.groups.builder = {};
    users.users.builder = {
      group = "builder";
      isSystemUser = true;
      shell = pkgs.zsh;
      home = "/var/lib/builder";
      createHome = true;
      openssh.authorizedKeys.keys = [
        (builtins.readFile ../../pub_keys/anya-root-builder.pub)
      ];
    };

    # Users who are allowed to talk to the nix daemon
    nix.settings.allowed-users = ["builder"];

    # Users who are root-equivalent
    nix.settings.trusted-users = ["builder"];

    nix.settings.keep-derivations = false;
    nix.settings.keep-outputs = false;

    # Auto-dedup - useful for space savings
    nix.settings.auto-optimise-store = true;

    # We want to run gc manually on the cache server,
    # otherwise our stuff will be cleaned up regularly,
    # and our nix-cache server has lots of space.... right?
    nix.gc.automatic = false;

    # nix.distributedBuilds = true;
    # nix.buildMachines = [
    #   {
    #     hostName = "anya.cyn.internal";
    #     system = "x86_64-linux"; # what arch builds to send
    #     protocol = "ssh";
    #     maxJobs = 4; # concurrent builds on builder
    #     speedFactor = 2; # relative to local builds
    #     supportedFeatures = [
    #       "nixos-test"
    #       "benchmark"
    #       "big-parallel"
    #       "kvm"
    #     ];
    #     mandatoryFeatures = [];
    #     sshUser = "tk"; # user on the builder
    #     sshKey = "/run/secrets/builder_key"; # private key used by nix daemon
    #   }
    # ];

    # nix.settings = {
    #   # WARNING: setting max-jobs to 0 will cause ALL builds to fail
    #   # if the remote builder is unavailable. Keep at value != 0 to ensure
    #   # we can still build if the remote builder is offline
    #   max-jobs = "auto";

    #   # NOTE: Setting this to true causes issues with the post-build-hook
    #   # not copying anything to the nix store of the cache host
    #   builders-use-substitutes = false;
    # };
  };
}
