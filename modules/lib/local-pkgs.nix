{
  # This module will allow unstable versions of nixpkgs to be used via
  # pkgs.unstable.<packagename>, as long as either:
  # - inputs.self.modules.nixos.unstable
  # - inputs.self.modules.homeManager.unstable
  #
  # Are imported in the specific flake module
  #
  flake.modules.nixos.local-pkgs = {
    nixpkgs.overlays = [
      # This one brings our custom packages from the 'local-pkgs' directory
      (final: prev: import ../../local-pkgs {pkgs = final;})
    ];
  };

  # Same as above, but for home-manager
  flake.modules.homeManager.local-pkgs = {
    nixpkgs.overlays = [
      # This one brings our custom packages from the 'local-pkgs' directory
      (final: prev: import ../../local-pkgs {pkgs = final;})
    ];
  };
}
