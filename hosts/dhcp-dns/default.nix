{
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}:
let
  wanPort = "wan";
  lanPort = "lan"; # VLAN 10
  guestPort = "guest"; # VLAN 20
  iotPort = "iot"; # VLAN 90
  wanMacAddress = "be:9f:42:7c:a8:c4";
  lanMacAddress = "42:29:21:ca:3d:58";

  routerLanIpAddress = "172.21.10.1";
in {
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

  # # boot stuff (required)
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # use default bash
  users.users.tk.shell = lib.mkForce pkgs.bash;
  users.users.tk.extraGroups = lib.mkForce [ "networkmanager" "wheel"];

  # For network troubleshooting
  environment.systemPackages = with pkgs; [
    tcpdump
  ];

  # Enable IPv4 forwarding
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
  };


  # Hostname & Network Manager
  networking = {
    hostName = "dhcp-dns";
    firewall.enable = false; # Using nftables (SOON)

    vlans = {
      lan = {
        interface = "ens19";
        id = 10;
      };
      iot = {
        interface = "ens19";
        id = 90;
      };
      guest = {
        interface = "ens19";
        id = 20;
      };
    };

    interfaces = {

      # Physical NICs
      ens18 = {
        macAddress = wanMacAddress;
        useDHCP = true;
      };
      ens19 = {
        useDHCP = false;
        macAddress = lanMacAddress;
        ipv4.addresses = [{
          address = routerLanIpAddress;
          prefixLength = 24;
        }];
      };

      # VLAN NICs
      lan = {
        ipv4.addresses = [{
          address = "10.0.10.1";
          prefixLength = 24;
        }];
      };
      iot = {
        ipv4.addresses = [{
          address = "10.0.90.1";
          prefixLength = 24;
        }];
      };
      guest = {
        ipv4.addresses = [{
          address = "10.0.20.1";
          prefixLength = 24;
        }];
      };
    };
  };

  # Kea DHCP config
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [ "lan" "guest" "iot" ];
      };
      lease-database = {
        type = "memfile";
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
      };
      subnet4 = [
        {
          id = 1;
          subnet = "10.0.10.1/24";
          interface = "lan";
          pools = [{ pool = "10.0.10.90 - 10.0.10.95"; }];
        }
        {
          id = 2;
          subnet = "10.0.90.1/24";
          interface = "iot";
          pools = [{ pool = "10.0.90.150 - 10.0.90.160"; }];
        }
        {
          id = 3;
          subnet = "10.0.20.1/24";
          interface = "guest";
          pools = [{ pool = "10.0.20.10 - 10.0.20.20"; }];
        }
        # {
        #   id = 1;
        #   subnet = "192.0.2.0/24";
        #   pools = [
        #     { pool = "192.0.2.100 - 192.0.2.240"; }
        #   ];
        #   # Reservations can be found in /etc/kea/dhcp4-server.conf
        #   #
        #   # TRY ENCRYPTING WITH THIS:
        #   # https://github.com/Mic92/sops-nix?tab=readme-ov-file#templates
        #   reservations = [
        #     {
        #       hw-address = "d2:a4:34:62:28:69";  # MAC address of the device
        #       ip-address = "192.0.2.149";        # Reserved IP address
        #     }
        #   ];
        # }
      ];
      valid-lifetime = 86400; # 1-Day Lease
    };
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}


  # # Configuring Network Interfaces
  # systemd.network = {
  #   enable = true;

  #   # Without this networkd activation would fail as it would be waiting until timeout
  #   # is reached for all managed interfaces to come online. It is not necessary to set
  #   # it if all managed interfaces are always connected but this is not my case.
  #   # Basically allow unplugging ETH cables when needed...
  #   wait-online.anyInterface = true;

  #   # Define links manually, not necessary but can prevent NICs swapping on boot
  #   # in some circumstances.
  #   links = {
  #     "09-wan" = {
  #       matchConfig.PermanentMACAddress = wanMacAddress;
  #       linkConfig.Name = wanPort;
  #     };
  #     "10-lan" = {
  #       matchConfig.PermanentMACAddress = lanMacAddress;
  #       linkConfig.Name = lanPort;
  #     };
  #   };

  #   networks = {
  #     # NIC1 (WAN)
  #     "09-wan" = {
  #       matchConfig.Name = wanPort;
  #       networkConfig = {
  #         DHCP = "ipv4";
  #         IPv4Forwarding = true;
  #       };

  #       # Setting Explicit DNS servers, though probably not needed
  #       # make routing on this interface a dependency for network-online.target
  #       linkConfig.RequiredForOnline = "routable";
  #     };
  #     # NIC2 (LAN)
  #     "10-lan" = {
  #       matchConfig.Name = lanPort;
  #       address = [
  #         routerLanIpAddress
  #       ];
  #     };
  #   };
  # };