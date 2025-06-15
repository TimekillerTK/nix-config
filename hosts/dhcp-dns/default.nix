{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  wanPort = "wan"; # Physical wan
  lanPort = "lan"; # Physical LAN
  homePort = "home"; # VLAN 10
  guestPort = "guest"; # VLAN 20
  iotPort = "iot"; # VLAN 90
  wanMacAddress = "be:9f:42:7c:a8:c4";
  lanMacAddress = "42:29:21:ca:3d:58";

  routerLanIpAddress = "172.21.0.1";
  dnsServerIpAddress = "172.21.10.15";
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

  # Actual SOPS key
  sops.secrets."kea_reservations.json" = {
    mode = "0440";
    owner = "kea";
    group = "kea";
    path = "/var/lib/kea/reservations.json";
    format = "json";
    sopsFile = ./secrets.json;
    key = ""; # Full JSON file instead of a single key
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

  # Rename our network interfaces to have more understandable names
  boot.initrd.services.udev.rules = ''
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="${wanMacAddress}", NAME="${wanPort}"
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="${lanMacAddress}", NAME="${lanPort}"
  '';

  # Hostname & Network Manager
  networking = {
    hostName = "dhcp-dns";

    # Disable existing IPTables firewall & NAT
    nat.enable = false;
    firewall.enable = false; # Using nftables (SOON)

    # NOTE: will be explictly configured per interface if needed
    useDHCP = false;

    vlans = {
      home = {
        interface = lanPort;
        id = 10;
      };
      guest = {
        interface = lanPort;
        id = 20;
      };
      iot = {
        interface = lanPort;
        id = 90;
      };
    };

    interfaces = {
      # Physical NICs
      wan = {
        macAddress = wanMacAddress;
        useDHCP = true;
      };
      lan = {
        macAddress = lanMacAddress;
        useDHCP = false;
        ipv4.addresses = [{
          address = routerLanIpAddress;
          prefixLength = 24;
        }];
      };

      # VLAN NICs
      home = {
        ipv4.addresses = [{
          address = "172.21.10.1";
          prefixLength = 24;
        }];
      };
      guest = {
        ipv4.addresses = [{
          address = "172.21.20.1";
          prefixLength = 24;
        }];
      };
      iot = {
        ipv4.addresses = [{
          address = "172.21.90.1";
          prefixLength = 24;
        }];
      };
    };

    nftables = {
      # Enable NFTables & flush any existing rulesets
      enable = true;
      flushRuleset = true;

      # Actual NFTables rules
      ruleset = ''
        table inet filter {
          chain inbound_world {
          }

          chain inbound_private {
	        	ip protocol . th dport vmap { tcp . 22 : accept, udp . 53 : accept, tcp . 53 : accept, udp . 67 : accept }
	        }

          chain inbound {
            type filter hook input priority 0; policy drop;
            ct state vmap { established : accept, related : accept, invalid : drop} counter
            icmp type echo-request counter limit rate 5/second accept
            ip protocol icmp icmp type { destination-unreachable, echo-reply, echo-request, source-quench, time-exceeded } accept
            iifname "lo" ip daddr != 127.0.0.0/8 drop
            iifname vmap { lo: accept, ${wanPort} : jump inbound_world, ${lanPort} : jump inbound_private }
          }

          chain forward {
            type filter hook forward priority 0; policy drop;
            ct state vmap { established : accept, related : accept, invalid : drop }

            # Allow traffic from individual VLANS, and the router to go to the Internet
            iifname { lo, ${lanPort}, ${homePort}, ${iotPort}, ${guestPort} } oifname { ${wanPort} } accept

            # Allow home to connect to IoT, but IoT cannot connect to home
            iifname { ${homePort} } oifname { ${iotPort} } counter accept
          }
        }

        # Network address translation: What allows us to glue together a private network with the Internet even though we only have one routable address, as per IPv4 limitations
        table ip nat {
          chain prerouting {
            type nat hook prerouting priority dstnat; policy accept;
            iifname ${lanPort} ip daddr 8.8.8.8 udp dport 53 counter ct mark set 1 dnat to ${dnsServerIpAddress}:53
            iifname ${lanPort} ip daddr 8.8.8.8 tcp dport 53 counter ct mark set 1 dnat to ${dnsServerIpAddress}:53
            iifname ${lanPort} ip daddr 8.8.4.4 udp dport 53 counter ct mark set 1 dnat to ${dnsServerIpAddress}:53
            iifname ${lanPort} ip daddr 8.8.4.4 tcp dport 53 counter ct mark set 1 dnat to ${dnsServerIpAddress}:53
          }
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            ct mark 1 counter masquerade
            oifname ${wanPort} masquerade
          }
        }
      '';
    };
  };

  # Kea DHCP config
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [ "home" "guest" "iot" ];
      };
      lease-database = {
        type = "memfile";
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
      };
      subnet4 = [
        {
          id = 1;
          subnet = "172.21.10.0/24";
          interface = "home";
          pools = [{ pool = "172.21.10.90 - 172.21.10.95"; }];
          option-data = [{
            name = "routers";
            data = "172.21.10.1";
          }];
        }
        {
          id = 2;
          subnet = "172.21.20.0/24";
          interface = "guest";
          pools = [{ pool = "172.21.20.10 - 172.21.20.20"; }];
          option-data = [{
            name = "routers";
            data = "172.21.20.1";
          }];
        }
        {
          id = 3;
          subnet = "172.21.90.0/24";
          interface = "iot";
          pools = [{ pool = "172.21.90.150 - 172.21.90.160"; }];
          option-data = [{
            name = "routers";
            data = "172.21.90.1";
          }];
          reservations = (
            builtins.fromJSON (builtins.readFile config.sops.secrets."kea_reservations.json".path)
          ).reservations;
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
