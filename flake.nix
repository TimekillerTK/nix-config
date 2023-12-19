{
  description = "NixOS config flake";

  inputs = {
    # Nixpkgs - https://github.com/NixOS/nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    # Home Manager - https://github.com/nix-community/home-manager
    home-manager.url = "github:nix-community/home-manager/release-23.11"; 
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # For VS Code Remote to work on NixOS
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # For managing KDE Plasma
    plasma-manager.url = "github:pjones/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";
  };

  outputs = { self, nixpkgs, vscode-server, home-manager, plasma-manager, ... }@inputs:
    let
      # system = "x86_64-linux";
      # pkgs = nixpkgs.legacyPackages.${system};
      # specialArgs = {
      #   inherit plasma-manager;
      # };
      inherit (self) outputs;
      stateVersion = "23.11";
      hmStateVersion = "23.11";
      libx = import ./lib { inherit self inputs outputs stateVersion hmStateVersion plasma-manager; };
    in
    {
      nixosConfigurations = {
        default = libx.mkHost { hostname = "test-nix"; };
        # default = nixpkgs.lib.nixosSystem {
        #   specialArgs = {inherit inputs;};
        #   modules = [
        #     ./configuration.nix
        #   ];
        # };
      };
      homeConfigurations = {
        tk  = libx.mkHome { hostname = "test-nix"; };
        # tk = home-manager.lib.homeManagerConfiguration {
        #   inherit pkgs;
        #   modules = [
        #     ./home.nix
        #   ];
        # };
      };
    };
}
