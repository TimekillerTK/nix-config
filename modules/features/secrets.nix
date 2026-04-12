{
  inputs,
  lib,
  ...
}: {
  flake.modules.nixos.secrets = {pkgs, ...}: {
    imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    # System Packages
    environment.systemPackages = with pkgs; [
      sops
    ];

    sops = {
      defaultSopsFile = lib.mkDefault ../../secrets/default.yml;
      age = {
        # This will automatically import SSH keys as age keys
        # it will be done in-memory and won't persist on disk
        sshKeyPaths = lib.mkDefault ["/etc/ssh/ssh_host_ed25519_key"];
      };
    };
  };
}
