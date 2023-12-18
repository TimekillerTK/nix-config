{
  description = "NixOS config flake";

  inputs = {
    # Unstable nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # For VS Code Remote to work on NixOS
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # For Home Manager
    home-manager.url = "github:nix-community/home-manager"; 
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # For managing KDE Plasma
    # plasma-manager.url = "github:pjones/plasma-manager";
    # plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    # plasma-manager.inputs.home-manager.follows = "home-manager";

  };

  outputs = { self, nixpkgs, vscode-server, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = {
        default = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [
            ./configuration.nix
            home-manager.nixosModules.home-manager {
              home-manager.extraSpecialArgs  = { inherit inputs; };
              home-manager.users.tk = import ./home.nix;
            }
          ];
        };
      };
    };
}
