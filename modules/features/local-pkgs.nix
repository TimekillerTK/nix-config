{
  inputs,
  withSystem,
  ...
}: {
  # This is a variable needed for pkgs-by-name-for-flake-parts,
  # it refers to the inputs.packages which is defined in our
  # flake.nix file
  perSystem = {
    pkgsDirectory = inputs.packages;
  };

  # config.pkgs is defined in the flake.nix file
  flake.modules.generic.local-pkgs = {
    nixpkgs.overlays = [
      (_final: prev: {
        local = withSystem prev.stdenv.hostPlatform.system ({config, ...}: config.packages);
      })
    ];
  };
}
