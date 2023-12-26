{
  description = "NixOS config flake";

  inputs = {
    # Nixpkgs - https://github.com/NixOS/nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    # Home Manager - https://github.com/nix-community/home-manager
    home-manager.url = "github:nix-community/home-manager/release-23.11"; 
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Atomic, declarative, and reproducible secret provisioning for NixOS based on sops.
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # For VS Code Remote to work on NixOS
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # Community VS Code Extensions
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    # For managing KDE Plasma
    plasma-manager.url = "github:pjones/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";
  };

  outputs = { self, nixpkgs, vscode-server, home-manager, plasma-manager, nix-vscode-extensions, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (self) outputs;
      stateVersion = "23.11";
      hmStateVersion = "23.11";
      # Gets the same version of VS Code being installed by hmStateVersion
      # some extensions require specific versions of VS Code
      vscodeVersion = pkgs.vscode.version;
      vscode-pkgs = inputs.nix-vscode-extensions.extensions.${system}.forVSCodeVersion vscodeVersion;
    in
    {
      nixosConfigurations = {
        default = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [
            ./configuration.nix
          ];
        };
      };
      homeConfigurations = {
        tk = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {inherit vscode-pkgs;};
          modules = [
            ./home.nix
            inputs.plasma-manager.homeManagerModules.plasma-manager
            inputs.sops-nix.homeManagerModule
          ];
        };
      };
    };
}
