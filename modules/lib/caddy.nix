{inputs, ...}: {
  flake.modules.generic.caddy_v284 = {pkgs, ...}: {
    nixpkgs.overlays = [
      (final: prev: {
        caddy_v284 = import inputs.nixpkgs-caddy {
          inherit (final) config;
          system = pkgs.stdenv.hostPlatform.system;
        };
      })
    ];
  };
}
