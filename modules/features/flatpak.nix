{
  inputs,
  lib,
  ...
}: {
  # Management of Flatpaks via Nix
  flake.modules.nixos.flatpak = {
    imports = [
      inputs.nix-flatpak.nixosModules.nix-flatpak
    ];
    services.flatpak = {
      enable = true;
      uninstallUnmanaged = lib.mkDefault true; # Manage non-Nix Flatpaks
      update.onActivation = lib.mkDefault true; # Auto-update on rebuild
    };
  };
}
