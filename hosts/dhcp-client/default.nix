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

  # Hostname & Network Manager
  networking.hostName = "dhcp-client";
  networking.networkmanager.enable = true;

  networking = {
    firewall.enable = false; # Using nftables

    vlans = {
      home = {
        interface = "ens19";
        id = 10;
      };
    };

    interfaces = {

      # Physical NICs
      ens19.useDHCP = true;

      # VLAN NICs
      home = {
        useDHCP = true;
      };
    };
  };

  # DHCP Client
  environment.systemPackages = with pkgs; [

    # Release the current DHCP lease for a network interface (e.g., eth0, wlan0)
    # -> sudo dhcpcd --release <interface>
    #
    # Request a new DHCP lease (renew)request a new DHCP lease (renew)
    # -> sudo dhcpcd --rebind <interface>
    dhcpcd
  ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
