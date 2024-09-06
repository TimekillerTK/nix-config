{
  description = "TK's Nix Configs";

  inputs = {
    # Nixpkgs Stable - https://github.com/NixOS/nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    # NixOS Generators - for building Proxmox VM Images
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-generators, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in
  {
    packages.x86_64-linux = {
      proxmox = nixos-generators.nixosGenerate {
        inherit system;
        specialArgs = {
          pkgs = pkgs;
          diskSize = 20 * 1024;
        };
        modules = [
          ./hosts/anya
          ({ ... }: { nix.registry.nixpkgs.flake = nixpkgs; })
        ];
        format = "proxmox";
      };
    };

  };
}
