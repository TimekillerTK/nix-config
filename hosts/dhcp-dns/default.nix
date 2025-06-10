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
  networking.hostName = "dhcp-dns";
  networking.networkmanager.enable = true;

  # Kea DHCP config
  services.kea.dhcp4.settings = {
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
        # reservations = [
        #   {
        #     hw-address = "01:23:45:67:89:ab"; # MAC address of the device
        #     ip-address = "192.0.2.10";        # Reserved IP address
        #     hostname = "special-device";      # Optional: assign a hostname
        #   }
        # ];
      }
    ];
    valid-lifetime = 4000;
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
