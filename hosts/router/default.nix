{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: 
let
  wanPort = "wan";
  lanPort = "lan";
  wanMacAddress = "0c:c4:7a:e3:98:17";
  lanMacAddress = "0c:c4:7a:e3:98:16";
  routerLanIpAddress = "172.17.0.1/16";
in {

  imports = [
    ../common/global
    ../common/users/tk
    ./hardware-configuration.nix
  ];

  # boot stuff (required)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # use default bash
  users.users.tk.shell = lib.mkForce pkgs.bash;

  # For network troubleshooting
  environment.systemPackages = with pkgs; [
    tcpdump
    nmap
    vim
    dig
  ];

  # Enable IPv4 forwarding
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
  };

  # Configuring Network Interfaces
  systemd.network = {
    enable = true;

    # Without this networkd activation would fail as it would be waiting until timeout
    # is reached for all managed interfaces to come online. It is not necessary to set
    # it if all managed interfaces are always connected but this is not my case. 
    # Basically allow unplugging ETH cables when needed...
    wait-online.anyInterface = true;

    # Define links manually, not necessary but can prevent NICs swapping on boot
    # in some circumstances.
    links = {
      "10-wan" = {
        matchConfig.PermanentMACAddress = wanMacAddress;
        linkConfig.Name = wanPort;
      };
      "20-lan" = {
        matchConfig.PermanentMACAddress = lanMacAddress;
        linkConfig.Name = lanPort;
      };
    };

    networks = {
      # NIC1 (WAN)
      "10-wan" = {
        matchConfig.Name = wanPort;
        networkConfig = {
          DHCP = "ipv4";
          IPForward = true;
        };

        # Setting Explicit DNS servers, though probably not needed
        # make routing on this interface a dependency for network-online.target
        linkConfig.RequiredForOnline = "routable";
      };
      # NIC2 (LAN)
      "20-lan" = {
        matchConfig.Name = lanPort;
        address = [
          routerLanIpAddress
        ];
      };
    };
  };

  # Mostly Firewall Rules
  networking = {
    hostName = "router";

    # Conflicts with systemd.network.enable
    # - will be explictly configured per interface if needed
    useDHCP = false;

    # Disable existing IPTables firewall & NAT
    nat.enable = false;
    firewall.enable = false;
    
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
            iifname { lo, $LANPORT } accept
          }
        }

        # Network address translation: What allows us to glue together a private network with the Internet even though we only have one routable address, as per IPv4 limitations
        table ip nat {
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;

            # Pretend that outbound traffic originates in this router so that Internet servers know where to send responses
            oifname $WANPORT masquerade
          }
        }
      '';
    };
  };

  # Ensure networkd waits for nftables (firewall) to start first
  # Plus other wants/after which were there by default
  systemd.services.systemd-networkd = {
    wants = [
      "nftables.service"
      "systemd-networkd.socket"
      "network.target"
    ];
    after = [ 
      "nftables.service"
      "systemd-networkd.socket"
      "systemd-udevd.service"
      "network-pre.target"
      "systemd-sysusers.service"
      "systemd-sysctl.service"
    ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
