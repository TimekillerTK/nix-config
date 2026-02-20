{
  description = "Dendritic Pattern Example Test Config";

  inputs = {
    # Nixpkgs Stable - https://github.com/NixOS/nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # Nixpkgs Unstable
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # Nixpkgs Caddy Pin to 2.8.4 due to issues with 2.10
    nixpkgs-caddy.url = "github:NixOS/nixpkgs/a880f49904d68b5e53338d1e8c7bf80f59903928";

    # Home Manager - https://github.com/nix-community/home-manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # For managing KDE Plasma 6
    plasma-manager6.url = "github:nix-community/plasma-manager";
    plasma-manager6.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager6.inputs.home-manager.follows = "home-manager";

    # Atomic, declarative, and reproducible secret provisioning for NixOS based on sops.
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Managing flatpaks declartively
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # Disko (Disk Config)
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # dendritic pattern flake inputs
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
    packages = {
      url = "path:./local-pkgs";
      flake = false;
    };
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
}
