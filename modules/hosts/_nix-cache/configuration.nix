{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "nix-cache";

  flake.modules.nixos.nix-cache = {pkgs, ...}: {
  };
}
