{inputs, ...}: {
  flake.modules.generic.caddy_v284 = {pkgs, ...}: {
    nixpkgs.overlays = [
      (final: prev: {
        caddy_v284 = import inputs.nixpkgs-caddy {
          config = {allowUnfree = final.config.allowUnfree or false;};
          system = pkgs.stdenv.hostPlatform.system;
        };
      })
    ];
  };
}
