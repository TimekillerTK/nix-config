{
  inputs,
  outputs,
  pkgs,
  lib,
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
        # Source: https://oxcrag.net/projects/linux-router-part-1-routing-nat-and-nftables/
        # Our future selves will thank us for noting what cable goes where and labeling the relevant network interfaces if it isn't already done out-of-the-box.
        define WANPORT = ${wanPort}
        define LANPORT = ${lanPort}
        define IOTPORT = ${iotPort}
        define GUESTPORT = ${guestPort}
        define HOMEPORT = ${homePort}

        # We never expect to see the following address ranges on the Internet
        define BOGONS4 = {
          0.0.0.0/8,
          10.0.0.0/8,
          10.64.0.0/10,
          127.0.0.0/8,
          127.0.53.53,
          169.254.0.0/16,
          172.16.0.0/12,
          192.0.0.0/24,
          192.0.2.0/24,
          192.168.0.0/16,
          198.18.0.0/15,
          198.51.100.0/24,
          203.0.113.0/24,
          224.0.0.0/4,
          240.0.0.0/4,
          255.255.255.255/32
        }

        table inet filter {
          chain inbound_world {
            # Drop obviously spoofed inbound traffic (to turn on later)
            # ip saddr { $BOGONS4 } drop
          }

          chain inbound_private {
            # We want to allow remote access over ssh, incoming DNS traffic, and incoming DHCP traffic
	        	ip protocol . th dport vmap { tcp . 22 : accept, udp . 53 : accept, tcp . 53 : accept, udp . 67 : accept }
	        }

          chain inbound {
            # Default Deny
            type filter hook input priority 0; policy drop;

            # Allow established and related connections: Allows Internet servers to respond to requests from our Internal network
            ct state vmap { established : accept, related : accept, invalid : drop} counter

            # ICMP is - mostly - our friend. Limit incoming pings somewhat, but allow necessary information.
            icmp type echo-request counter limit rate 5/second accept
            ip protocol icmp icmp type { destination-unreachable, echo-reply, echo-request, source-quench, time-exceeded } accept

            # Drop obviously spoofed loopback traffic
            iifname "lo" ip daddr != 127.0.0.0/8 drop

            # Separate rules for traffic from Internet and from the internal network
            iifname vmap { lo: accept, $WANPORT : jump inbound_world, $LANPORT : jump inbound_private }
          }

          # Rules for sending traffic from one network interface to another
          chain forward {
            # Default deny, again
            type filter hook forward priority 0; policy drop;

            # Accept established and related traffic
            ct state vmap { established : accept, related : accept, invalid : drop }

            # Let traffic from this router and from the Internal network get out onto the Internet
            iifname { lo, $LANPORT, $IOTPORT, $GUESTPORT, $HOMEPORT } accept
          }
        }

        # Network address translation: What allows us to glue together a private network with the Internet even though we only have one routable address, as per IPv4 limitations
        table ip nat {
          chain prerouting {
            type nat hook prerouting priority dstnat; policy accept;

            # Redirect all DNS traffic destined to google DNS to local DNS server
            iifname $LANPORT ip daddr 8.8.8.8 udp dport 53 counter ct mark set 1 dnat to 172.17.0.40:53
            iifname $LANPORT ip daddr 8.8.8.8 tcp dport 53 counter ct mark set 1 dnat to 172.17.0.40:53
            iifname $LANPORT ip daddr 8.8.4.4 udp dport 53 counter ct mark set 1 dnat to 172.17.0.40:53
            iifname $LANPORT ip daddr 8.8.4.4 tcp dport 53 counter ct mark set 1 dnat to 172.17.0.40:53
          }
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;

            # Pretend that redirected DNS requests originate in this router, so clients can get a valid response
            ct mark 1 counter masquerade

            # Pretend that outbound traffic originates in this router so that Internet servers know where to send responses
            oifname $WANPORT masquerade
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
