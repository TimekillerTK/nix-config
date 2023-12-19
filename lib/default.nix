{ self, inputs, outputs, stateVersion, hmStateVersion, plasma-manager, ... }: {

  # Helper function for generating home-manager configs
  mkHome = { 
    hostname, 
    username ? "tk",
    desktop  ? null, 
    platform ? "x86_64-linux", 
    theme    ? "default",
  }: inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.${platform};
    extraSpecialArgs = { inherit inputs outputs desktop hostname platform username hmStateVersion theme plasma-manager; };
    modules = [ 
      ../home.nix
    ];
  };

  # Helper function for generating host configs
  mkHost = { 
    hostname, 
    username  ? "tk",
    desktop   ? null, 
    gpu       ? null, 
    platform  ? "x86_64-linux", 
    theme     ? "default",
  }: inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs outputs desktop hostname username stateVersion gpu platform theme; };
    modules = [
        ../configuration.nix
    ];
  };
}