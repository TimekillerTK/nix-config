{ self, inputs, outputs, stateVersion, hmStateVersion, ... }: {
  # Helper function for generating host configs
  mkHost = { 
    hostname, 
    username  ? "tk",
    desktop   ? null, 
    gpu       ? null, 
    platform  ? "x86_64-linux", 
    theme     ? "default",
    type      ? "default"
  }: inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs outputs desktop hostname username stateVersion gpu platform theme; };
    modules = [
        ../hosts/default/${type}.nix
    ];
  };

  # Helper function for generating home-manager configs
  mkHome = { 
    hostname, 
    username ? "tk",
    desktop  ? null, 
    platform ? "x86_64-linux", 
    theme    ? "default",
    type     ? "home"
  }: inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.${platform};
    extraSpecialArgs = { inherit inputs outputs desktop hostname platform username hmStateVersion theme; };
    modules = [ 
      ../hosts/default/${type}.nix
    ];
  };

  # My helper function

}
