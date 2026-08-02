{
  flake.modules.nixos.incus = {pkgs, ...}: {
    virtualisation.incus = {
      enable = true;
      ui.enable = true;
      preseed = {
        config = {
          # This makes the Incus WebUI listen on port 8443
          "core.https_address" = "0.0.0.0:8443";
        };
      };
    };
    # Incus on NixOS is unsupported using iptables, therefore
    networking.nftables.enable = true;

    # NOTE: nftables ruleset will be flushed with any change to nftables rules, this results
    # in the Incus ruleset table (named "incus") being wiped, resulting in loss of
    # connectivity across VMs and containers.
    # source: https://wiki.nixos.org/wiki/Incus
    networking.nftables.flushRuleset = false;

    # WebUI
    networking.firewall.allowedTCPPorts = [8443];

    # NOTE: By default the NixOS firewall will block DHCP requests to the Incus network
    # source: https://wiki.nixos.org/wiki/Incus
    networking.firewall.trustedInterfaces = ["incusbr0"];
  };
}
