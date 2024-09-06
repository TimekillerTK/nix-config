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
  {

    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    # packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; inherit nixos-generators; });
    # Used by devport-bird
    packages.x86_64-linux = {
      proxmox = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        specialArgs = {
          pkgs = nixpkgs;
          diskSize = 20 * 1024;
        };
        modules = [
          ./hosts/anya
        ];
        format = "proxmox";
      };
    };

  };
}
