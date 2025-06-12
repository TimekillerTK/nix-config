{
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk
    ../common/optional/sops

  ];

  # Overlays
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.other-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  # use default bash
  # TODO: find a better way to do this
  users.users.tk.shell = lib.mkForce pkgs.bash;
  users.users.tk.extraGroups = lib.mkForce [ "networkmanager" "wheel"];

  # Enable IPv4 forwarding
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
  };

  # Hostname & Network Manager
  networking = {
    hostName = "dhcp-dns";
    # firewall.enable = false; # Using nftables

    # vlans = {
    #   lan = {
    #     interface = "enp0s19";
    #     id = 10;
    #   };
    #   iot = {
    #     interface = "enp0s19";
    #     id = 90;
    #   };
    #   guest = {
    #     interface = "enp0s19";
    #     id = 20;
    #   };
    # };

    # interfaces = {

    #   # Physical NICs
    #   enp0s18 = {
    #     useDHCP = true;
    #   };
    #   enp0s19 = {
    #     useDHCP = false;
    #     ipv4.addresses = [{
    #       address = "192.168.0.1";
    #       prefixLength = 24;
    #     }];
    #   };

    #   # VLAN NICs
    #   lan = {
    #     ipv4.addresses = [{
    #       address = "10.0.10.1";
    #       prefixLength = 24;
    #     }];
    #   };
    #   iot = {
    #     ipv4.addresses = [{
    #       address = "10.0.90.1";
    #       prefixLength = 24;
    #     }];
    #   };
    #   guest = {
    #     ipv4.addresses = [{
    #       address = "10.0.20.1";
    #       prefixLength = 24;
    #     }];
    #   };
    # };
  };

  # Kea DHCP config
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [ "ens19" ];
      };
      lease-database = {
        type = "memfile";
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
      };
      subnet4 = [
        {
          id = 1;
          subnet = "192.0.2.0/24";
          pools = [
            { pool = "192.0.2.100 - 192.0.2.240"; }
          ];
          # Reservations can be found in /etc/kea/dhcp4-server.conf
          #
          # TRY ENCRYPTING WITH THIS:
          # https://github.com/Mic92/sops-nix?tab=readme-ov-file#templates
          reservations = [
            {
              hw-address = "d2:a4:34:62:28:69";  # MAC address of the device
              ip-address = "192.0.2.149";        # Reserved IP address
            }
          ];
        }
      ];
      valid-lifetime = 86400; # 1-Day Lease
    };
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
