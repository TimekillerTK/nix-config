{inputs, ...}: {
  # This file defines nix specific settings
  flake.modules.generic.nix-settings = {
    config,
    lib,
    ...
  }: {
    # This will add all flake inputs as registry entries which allows using of
    # flake:nixpkgs (for example) from any flake on the system and they'll resolve
    # to the version defined by this nix config
    nix.registry =
      (lib.mapAttrs (_: flake: {inherit flake;}))
      ((lib.filterAttrs (_: lib.isType "flake")) inputs);

    # Sets NIX_PATH search path which is used by the non-flake methods
    nix.nixPath = ["/etc/nix/path"];

    # This builds the etc entries from the above nix.registry, keeping flake-based
    # and regular/older commands in sync.
    #
    # Makes older commands such as nix-shell consistent with our flake, awesome!
    environment.etc =
      lib.mapAttrs'
      (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      })
      config.nix.registry;

    # Nix automatic Garbage Collect
    nix.gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 60d";
    };

    nix.settings = {
      substituters = [
        # NOTE: A cache/substituter typically has a priority value of 40 by default
        # We set the priority to 30 for cache.nixos.org, since we always want it used
        # by default over cachix
        "https://cache.nixos.org?priority=30"

        # For prebuilt binaries for things that aren’t (or aren’t yet) on cache.nixos.org,
        # especially community overlays and/or fast‑moving packages.
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      # Users who get elevated permissions when interacting with the nix
      # daemon.
      trusted-users = [
        "root"
        "@wheel"
      ];

      # Enables nix command used in (for example):
      # - nix flake update
      #
      # Enables flakes command when used in (for example):
      # - nixos-rebuilds switch --flake .#example
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Doesn't work I think (need to test)
      # # Allow installing of unfree packages via nix build/nix shell
      # allow-unfree = true;

      # ------------------------------
      # NOTE: This will get rid of the warning that download buffer
      # being full during a rebuild, but this is fixed in Nix 2.33
      # so remove this once on Nix 2.33 (currently 2.31.2 in Nixpkgs)
      download-buffer-size = 512 * 1024 * 1024;
    };
  };
}
