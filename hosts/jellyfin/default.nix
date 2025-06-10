{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
  ...
}: let
  wanPort = "wan"; # Physical wan
  lanPort = "lan"; # Physical LAN

  homePort = "home"; # VLAN 10
  guestPort = "guest"; # VLAN 20
  iotPort = "iot"; # VLAN 90

  wanMacAddress = "e8:ff:1e:de:5b:5b";
  lanMacAddress = "e8:ff:1e:de:5b:5a";

  routerLanIpAddress = "192.168.0.100/24";
  dnsServerIpAddress = "172.21.10.5";
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

  # All our DHCP reservation are considered secrets
  # sops.secrets.reservations_lan = {
  #   sopsFile = ./secrets.yml;
  # };
  sops.secrets.reservations_home = {
    sopsFile = ./secrets.yml;
  };
  sops.secrets.reservations_iot = {
    sopsFile = ./secrets.yml;
  };
  sops.secrets.reservations_guest = {
    sopsFile = ./secrets.yml;
  };

  # use default bash
  users.users.tk.shell = lib.mkForce pkgs.bash;
  users.users.tk.extraGroups = lib.mkForce ["networkmanager" "wheel"];

  # For network troubleshooting
  environment.systemPackages = with pkgs; [
    tcpdump
  ];

  # boot stuff (required)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_14;

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

    # Define links manually, not strictly necessary - but will prevent NICs 'swapping'
    # on boot
    links = {
      "10-wan" = {
        matchConfig.PermanentMACAddress = wanMacAddress;
        linkConfig.Name = wanPort;
      };
      "10-lan" = {
        matchConfig.PermanentMACAddress = lanMacAddress;
        linkConfig.Name = lanPort;
      };
    };

    # Defining VLANs
    netdevs = {
      "20-vlan10-home" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "home";
        };
        vlanConfig.Id = 10;
      };
      "20-vlan20-guest" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "guest";
        };
        vlanConfig.Id = 20;
      };
      "20-vlan90-iot" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "iot";
        };
        vlanConfig.Id = 90;
      };
    };

    networks = {
      # NIC1 (WAN)
      "30-net-wan" = {
        matchConfig.Name = wanPort;
        networkConfig = {
          DHCP = "ipv4";
          IPv4Forwarding = true;
        };

        # Make routing on this interface a dependency for network-online.target
        linkConfig.RequiredForOnline = "routable";
      };
      # NIC2 (LAN)
      "30-net-lan" = {
        matchConfig.Name = lanPort;
        vlan = ["home" "guest" "iot"];
        address = [
          routerLanIpAddress
        ];
      };

      "40-net-home" = {
        matchConfig.Name = homePort;
        address = [
          "172.21.10.1/24"
        ];
        dns = [dnsServerIpAddress];
        domains = ["cyn.internal"];
      };

      "40-net-guest" = {
        matchConfig.Name = guestPort;
        address = [
          "172.21.20.1/24"
        ];
        dns = ["1.1.1.1" "1.0.0.1"];
      };

      "40-net-iot" = {
        matchConfig.Name = iotPort;
        address = [
          "172.21.90.1/24"
        ];
        dns = ["1.1.1.1" "1.0.0.1"];
      };
    };
  };

  # NOTE: We're using `systemd.network` for configuring our network interfaces, so
  # just disabling some defaults we don't need here and setting the hostname &
  # nftables (firewall) rules
  networking = {
    # Setting Hostname
    hostName = "jellyfin";

    # We use systemd.network for DHCP, so we disable because there can be conflicts
    # between `networking` and `systemd.network` config options
    useDHCP = false;

    # Disable existing IPTables firewall & NAT
    nat.enable = false;
    firewall.enable = false; # Using nftables instead

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
            iifname vmap { lo: accept, ${wanPort} : jump inbound_world, ${lanPort} : jump inbound_private, ${homePort} : jump inbound_private }
          }

          chain forward {
            type filter hook forward priority 0; policy drop;
            ct state vmap { established : accept, related : accept, invalid : drop }

            # Allow traffic from individual VLANS, and the router to go to the Internet
            iifname { lo, ${lanPort}, ${homePort}, ${iotPort}, ${guestPort} } oifname { ${wanPort} } accept

            # Allow home to connect to IoT, but IoT cannot connect to home
            iifname { ${homePort} } oifname { ${iotPort} } counter accept

            # Allow home to connect to LAN, but LAN cannot connect to home
            iifname { ${homePort} } oifname { ${lanPort} } counter accept
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
    configFile = "/this/is/an/unused/fake/path"; # Fake path because it cannot be a NULL
    # \/ \/ \/ See workaround below \/ \/ \/
  };

  # ==============================================================================
  # === Workaround to the issue where kea cannot access the sops template file ===
  # ==============================================================================
  #
  # This is a workaround for systemd services which use DynamicUser. Normally, we would
  # specify our sops.templates."example.json" file and set permissions which grant a
  # user/group permissions to read this secrets file/template.
  #
  # With DynamicUser, this is difficult because we have a potential race condition, where
  # sops wants to grant permissions to a user which doesn't exist yet.
  #
  # !!! THIS MAY BREAK IN THE FUTURE PENDING KEA CHANGES IN NIXPKGS !!!
  #
  # This section overrides this part of the nix config for Kea DHCPv4
  # https://github.com/NixOS/nixpkgs/blob/6c64dabd3aa85e0c02ef1cdcb6e1213de64baee3/nixos/modules/services/networking/kea.nix#L369
  #
  # It uses LoadCredential to set a "CREDENTIALS_DIRECTORY", which is a path we need for ExecStart.
  # Next, it uses the CREDENTIALS_DIRECTORY as a location of our sops config template.
  #
  # Sources:
  # - https://github.com/Mic92/sops-nix/issues/412 (inspiration)
  # - https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#Credentials
  systemd.services.kea-dhcp4-server.serviceConfig = {
    LoadCredential = "kea-dhcpv4-config.conf:${config.sops.templates."kea-dhcpv4-config.conf".path}";
    ExecStart = lib.mkForce ''
      ${pkgs.kea}/bin/kea-dhcp4 -c ''${CREDENTIALS_DIRECTORY}/kea-dhcpv4-config.conf
    '';
  };

  # Config file loaded for Kea DHCPv4 server
  sops.templates."kea-dhcpv4-config.conf".content = ''
    // Kea uses extended JSON with comments and allows includes <?include "file.json"?>
    {
      "Dhcp4": {
        "interfaces-config": {
          "interfaces": [
            "home",
            "guest",
            "iot"
          ]
        },
        "lease-database": {
          "name": "/var/lib/kea/dhcp4.leases",
          "persist": true,
          "type": "memfile"
        },
        "subnet4": [
          {
            "id": 1,
            "interface": "home",
            "option-data": [
              {
                "name": "routers",
                "data": "172.21.10.1"
              },
              {
                "name": "domain-name-servers",
                "data": "172.21.10.5"
              },
              {
                "name": "domain-search",
                "data": "cyn.internal"
              }
            ],
            "pools": [
              {
                "pool": "172.21.10.10 - 172.21.10.254"
              }
            ],
            "subnet": "172.21.10.0/24",
            "reservations": [
              ${config.sops.placeholder.reservations_home}
            ]
          },
          {
            "id": 2,
            "interface": "guest",
            "option-data": [
              {
                "data": "172.21.20.1",
                "name": "routers"
              },
              {
                "name": "domain-name-servers",
                "data": "1.1.1.1, 1.0.0.1"
              }
            ],
            "pools": [
              {
                "pool": "172.21.20.10 - 172.21.20.254"
              }
            ],
            "subnet": "172.21.20.0/24",
            "reservations": [
              ${config.sops.placeholder.reservations_guest}
            ]
          },
          {
            "id": 3,
            "interface": "iot",
            "option-data": [
              {
                "data": "172.21.90.1",
                "name": "routers"
              },
              {
                "name": "domain-name-servers",
                "data": "1.1.1.1, 1.0.0.1"
              }
            ],
            "pools": [
              {
                "pool": "172.21.90.10 - 172.21.90.254"
              }
            ],
            "subnet": "172.21.90.0/24",
            "reservations": [
              ${config.sops.placeholder.reservations_iot}
            ]
          }
        ],
        "valid-lifetime": 86400
      }
    }
  '';

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
