{inputs, ...}: {
  # Nix Binary Cache implemented with harmonia
  flake.modules.nixos.nix-binary-cache = {
    imports = [inputs.harmonia.nixosModules.harmonia];

    networking.firewall.allowedTCPPorts = [5000];

    # NOTE: This is harmonia-dev because we're using the nix flake
    # in our flake inputs to have the newer 3.0.0 version instead
    # of the 2.1.0 currently in nixpkgs
    services.harmonia-dev = {
      cache.enable = true;
      cache.signKeyPaths = ["/var/lib/secrets/harmonia.secret"];
    };
  };
}
