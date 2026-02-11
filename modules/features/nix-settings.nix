{
  # This file defines nix specific settings
  flake.modules.generic.nix-settings = {
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

      # Enables nix command used in (for example):
      # - nix flake update
      #
      # Enables flakes when used in (for example):
      # - nixos-rebuilds switch --flake .#example
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # ------------------------------
      # NOTE: This will get rid of the warning that download buffer
      # being full during a rebuild, but this is fixed in Nix 2.33
      # so remove this once on Nix 2.33 (currently 2.31.2 in Nixpkgs)
      download-buffer-size = 512 * 1024 * 1024;

      # Users who get elevated permissions when interacting with the nix
      # daemon.
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
  };
}
