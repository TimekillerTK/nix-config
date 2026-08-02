{
  flake.modules.nixos.incus = {pkgs, ...}: {
    virtualisation.incus = {
      enable = true;
      ui.enable = true;
    };

    # Incus on NixOS is unsupported using iptables, therefore
    networking.nftables.enable = true;

    networking.firewall.allowedTCPPorts = [8443];
  };
}
