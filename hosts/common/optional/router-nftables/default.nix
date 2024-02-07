# Settings NFTables
{ pkgs, ... }:
{

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

  # Override fallback DNS Servers
  services.resolved.fallbackDns = [
    "192.168.1.40"
  ];

  systemd.network = {
    enable = true;

    # Without this networkd activation would fail as it would be waiting until timeout
    # is reached for all managed interfaces to come online. It is not necessary to set
    # it if all managed interfaces are always connected but this is not my case. 
    # Basically allow unplugging ETH cables when needed...
    wait-online.anyInterface = true;
    
    networks = {
      # NIC2 `ens19` - `10.10.10.1/24` (LAN)
      "20-lan" = {
        matchConfig.Name = "ens19";
        address = [
          "10.10.10.1/24"
        ];
      };
      # NIC1 `ens18` - `192.168.1.4/24` (WAN)
      "10-wan" = {
        matchConfig.Name = "ens18";
        networkConfig = {
          DHCP = "ipv4";
          IPForward = true; # ?confirm
        };

        # Causes all DNS traffic which does not match another configured domain 
        # routing entry to be routed to DNS servers specified for this interface
        domains = ["~"];
        
        # Setting Explicit DNS servers, though probably not needed
        # make routing on this interface a dependency for network-online.target
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };

  networking = {
    # Conflicts with systemd.network.enable
    # - will be explictly configured per interface if needed
    useDHCP = false;

    # TODO: Hostname should be here too

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
            iifname ens19 drop
          }
        }
      '';
    };
  };
}