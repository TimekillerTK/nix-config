{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {

  imports = [
    ../common/global
    ../common/users/tk
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # TODO: Ensure firewall is started BEFORE Network interfaces come up

  # For network troubleshooting (remove later ?)
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

  # use default bash
  users.users.tk.shell = lib.mkForce pkgs.bash;

  systemd.network = {
    enable = true;

    # Without this networkd activation would fail as it would be waiting until timeout
    # is reached for all managed interfaces to come online. It is not necessary to set
    # it if all managed interfaces are always connected but this is not my case. 
    # Basically allow unplugging ETH cables when needed...
    wait-online.anyInterface = true;

    networks = {
      # NIC1 `eth1` - `DHCP` (WAN)
      "10-wan" = {
        matchConfig.Name = "eth1";
        networkConfig = {
          DHCP = "ipv4";
          IPForward = true;
        };

        # Setting Explicit DNS servers, though probably not needed
        # make routing on this interface a dependency for network-online.target
        linkConfig.RequiredForOnline = "routable";
      };
      # NIC2 `eno1` - `172.17.0.1/16` (LAN)
      "20-lan" = {
        matchConfig.Name = "eno1";
        address = [
          "172.17.0.1/16"
        ];

        # Causes all DNS traffic which does not match another configured domain 
        # routing entry to be routed to DNS servers specified for this interface
        domains = ["~"];
      };
    };
  };

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
        table ip whatever {
          chain thingscomingintohost {
            type filter hook input priority 0; policy accept;
            ct state related,established accept
            iifname eth1 drop
          }
          chain lastminutemods {
            type nat hook postrouting priority 0; policy accept;
            oifname eth1 masquerade
          }
        }
      '';
    };
  };
  
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
