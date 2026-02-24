{
  description = "TK's Nix Configs";

  inputs = {
    # Nixpkgs Stable - https://github.com/NixOS/nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = {nixpkgs, ...}: {
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      example = nixpkgs.lib.nixosSystem {
        modules = [./hosts/example/configuration.nix];
      };
    };
  };
}
