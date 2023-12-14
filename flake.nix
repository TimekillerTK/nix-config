{
  description = "Nixos config flake";

  inputs = {
    # Unstable nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # For VS Code Remote to work on NixOS
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # For Home Manager
    home-manager.url = "github:nix-community/home-manager"; 
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, vscode-server, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
          modules = [ 
            ./hosts/default/configuration.nix
            home-manager.nixosModules.home-manager {
              home-manager.extraSpecialArgs  = { inherit inputs; };
              home-manager.users.tk = import ./hosts/default/home.nix;
            }
            vscode-server.nixosModules.default
            ({ config, pkgs, ... }: {
             services.vscode-server.enable = true;
            })
          ];
        };

    };
}

