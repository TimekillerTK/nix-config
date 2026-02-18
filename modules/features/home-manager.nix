{inputs, ...}: {
  # This module is for setting home-manager settings and importing
  # the home-manager module part of the NixOS config
  #
  # When importing this module for a host, running either of these
  # commands:
  # - sudo nixos-rebuild switch --flake .#<hostname>
  # - nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --impure
  #
  # Will result in switching/building both the NixOS config and the home-manager
  # configs together.
  flake.modules.nixos.home-manager = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      ({...}: {
        home-manager = {
          # more verbose logging during home-manager activation
          verbose = true;

          # Makes home-manager reuse the nixpkgs/pkgs as the rest of the NixOS system, instead of
          # evaluating its own private Nixpkgs.
          useGlobalPkgs = true;
        };
      })
    ];
  };
}
