{
  flake.modules.nixos.incus = {pkgs, ...}: {
    virtualisation.incus = {
      enable = true;
      ui.enable = true;
      preseed = {
        config = {
          "core.https_address" = "0.0.0.0:8443";
        };
      };
    };

    # Incus on NixOS is unsupported using iptables, therefore
    networking.nftables.enable = true;

    networking.firewall.allowedTCPPorts = [8443];
  };
}
