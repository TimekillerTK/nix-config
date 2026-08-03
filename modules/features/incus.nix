{
  flake.modules.nixos.incus = {
    pkgs,
    config,
    ...
  }: {
    # KVM kernel module for VM acceleration
    boot.kernelModules = ["kvm-amd"];

    virtualisation.incus = {
      enable = true;
      ui.enable = true;
      preseed = {
        config = {
          # Port we expose to access the Incus WebUI
          "core.https_address" = "0.0.0.0:8443";
        };
        profiles = [
          {
            # The default profile enables secureboot by default
            # this will not work with many VM images, so turning
            # it off
            name = "default";
            config = {
              "security.secureboot" = false;
            };
          }
        ];
      };
    };

    # Bootstrapping systemd service for the bridge networks - this
    # service always runs when the Incus service runs, and creates
    # the required bridge networks, if they don't exist.
    systemd.services.incus-networks = {
      description = "Create incus bridge networks";
      after = ["incus.service"];
      wants = ["incus.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
      path = [config.virtualisation.incus.package];
      script = ''
        incus network show incusbr0 >/dev/null 2>&1 || \
          incus network create incusbr0 bridge.external=true
        incus network show incusbr1 >/dev/null 2>&1 || \
          incus network create incusbr1 \
            ipv4.address=10.177.5.1/24 ipv4.nat=true \
            ipv6.address=fd42:b747:5cf7:97a9::1/64 ipv6.nat=true
        incus network show incusbr2 >/dev/null 2>&1 || \
          incus network create incusbr2 \
            ipv4.nat=false ipv6.address=none
      '';
    };

    # Docker daemon for Docker container support
    virtualisation.docker.enable = true;

    # Incus on NixOS is unsupported using iptables, therefore
    networking.nftables.enable = true;

    # NOTE: nftables ruleset will be flushed with any change to nftables rules, this results
    # in the Incus ruleset table (named "incus") being wiped, resulting in loss of
    # connectivity across VMs and containers.
    # source: https://wiki.nixos.org/wiki/Incus
    networking.nftables.flushRuleset = false;

    # Incus WebUI
    networking.firewall.allowedTCPPorts = [8443];

    # NOTE: By default the NixOS firewall will block DHCP requests to the Incus network
    # source: https://wiki.nixos.org/wiki/Incus
    networking.firewall.trustedInterfaces = ["incusbr0" "incusbr1" "incusbr2"];
  };
}
