{inputs, ...}: {
  # This module will allow unstable versions of nixpkgs to be used via
  # pkgs.unstable.<packagename>, as long as:
  # - inputs.self.modules.generic.unstable
  #
  # Is imported in the specific flake module:
  # - flake.modules.homeManager.<modulename>
  # - flake.modules.nixos.<modulename>
  #
  flake.modules.generic.unstable = {pkgs, ...}: {
    nixpkgs.overlays = [
      # _prev is underscored, because it is discarded, we
      # only care about final
      (final: _prev: {
        unstable = import inputs.nixpkgs-unstable {
          # ----------------------
          # The imported nixpkgs function (final) is passed the config
          # argument, where things such as allowUnfree = true are
          # specified.
          #
          # This is important for consistency, otherwise we will have situations
          # where we can install an unfree package via pkgs.<packagename>, but
          # not via pkgs.unstable.<packagename>
          inherit (final) config;

          # ----------------------
          # Accepted way of passing the system string from pkgs
          # to our unstable nixpkgs, which we want to target for
          # the same architecture
          system = pkgs.stdenv.hostPlatform.system;
        };
      })
    ];
  };
}
