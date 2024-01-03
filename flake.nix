{
  description = "NixOS config flake";

  inputs = {
    # Nixpkgs Stable - https://github.com/NixOS/nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    # Nixpkgs Unstable
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

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

  outputs = { 
    self, 
    nixpkgs, 
    vscode-server, 
    home-manager, 
    plasma-manager, 
    nix-vscode-extensions, 
    nixpkgs-unstable,
     ... } @ inputs: let
    inherit (self) outputs;

    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # Overlay
    overlay-unstable = final: prev: {
      unstable = nixpkgs-unstable.legacyPackages.${prev.system};
    };
    # stateVersion = "23.11";
    # hmStateVersion = "23.11";
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
          ({ config, pkgs, ... }: {nixpkgs.overlays = [ overlay-unstable ]; }) # Overlay
          ./configuration.nix
        ];
      };
    };
    homeConfigurations = {
      tk = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {inherit vscode-pkgs inputs outputs;};
        modules = [
          ({ config, pkgs, ... }: {nixpkgs.overlays = [ overlay-unstable ]; }) # Overlay
          ./home.nix
        ];
      };
    };
  };
}
