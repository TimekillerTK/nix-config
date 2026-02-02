{inputs, ...}: {
  flake = {
    nixosConfigurations.main = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        ./test.nix
      ];
    };
  };
}
