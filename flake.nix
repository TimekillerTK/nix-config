{
  description = "TK's Nix Configs";

  inputs = {
    # Nixpkgs Stable - https://github.com/NixOS/nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # Nixpkgs Version 2505 - https://github.com/NixOS/nixpkgs
    nixpkgs-v2505.url = "github:nixos/nixpkgs/nixos-25.05";

    # Nixpkgs Version 2411 - https://github.com/NixOS/nixpkgs
    nixpkgs-v2411.url = "github:nixos/nixpkgs/nixos-24.11";

    # Nixpkgs Unstable
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # Nixpkgs Caddy Pin to 2.8.4 due to issues with 2.10
    nixpkgs-caddy.url = "github:NixOS/nixpkgs/a880f49904d68b5e53338d1e8c7bf80f59903928";

    # Disko (Disk Config)
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager - https://github.com/nix-community/home-manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Atomic, declarative, and reproducible secret provisioning for NixOS based on sops.
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # For managing KDE Plasma 6
    plasma-manager6.url = "github:nix-community/plasma-manager";
    plasma-manager6.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager6.inputs.home-manager.follows = "home-manager";

    # NixOS Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Managing flatpaks declartively
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    # inherit (self) outputs;
    # lib = nixpkgs.lib // home-manager.lib;
    # Supported systems for your flake packages, shell, etc.
    # systems = [
    #   "aarch64-linux"
    #   "i686-linux"
    #   "x86_64-linux"
    #   "aarch64-darwin"
    #   "x86_64-darwin"
    # ];
    # # This is a function that generates an attribute by calling a function you
    # # pass to it, with each system as an argument
    # forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    # pkgsFor = lib.genAttrs systems (system:
    #   import nixpkgs {
    #     inherit system;
    #     config.allowUnfree = true;
    #   });
  in {
    # inherit lib;

    # Reusable nixos modules you might want to export (shareable)
    # nixosModules = import ./modules/nixos;
    # homeManagerModules = import ./modules/home-manager;

    # # Your custom packages and modifications, exported as overlays
    # overlays = import ./overlays {inherit inputs;};

    # # Your custom packages
    # # Accessible through 'nix build', 'nix shell', etc
    # packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;});

    # # Formatter for your nix files, available through 'nix fmt'
    # formatter = forEachSystem (pkgs: pkgs.alejandra);

    # # DevShells for each system
    # devShells = forEachSystem (pkgs: import ./shell.nix {inherit pkgs;});

    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      example = nixpkgs.lib.nixosSystem {
        modules = [./hosts/example/configuration.nix];
        specialArgs = {
          inherit inputs;
        };
      };
    };
  };
}
