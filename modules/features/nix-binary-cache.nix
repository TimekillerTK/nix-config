{inputs, ...}: {
  # Nix Binary Cache implemented with harmonia
  flake.modules.nixos.nix-binary-cache = {
    imports = [inputs.harmonia.nixosModules.harmonia];

    networking.firewall.allowedTCPPorts = [5000];

    services.harmonia-dev.cache.enable = true;
    services.harmonia.signKeyPaths = ["/var/lib/secrets/harmonia.secret"];
  };
}
