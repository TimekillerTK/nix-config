{
  description = "TK's Nix Configs";

  inputs = {
    # Nixpkgs Stable - https://github.com/NixOS/nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # dendritic pattern
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    # # Nixpkgs Unstable
    # nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # # Home Manager - https://github.com/nix-community/home-manager
    # home-manager.url = "github:nix-community/home-manager/release-25.11";
    # home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;}
    (inputs.import-tree ./modules);
  # imports = [
  #   ./hosts/dendritic
  # ];
}
