{
  config.flake.factory.nix-auto-update = {
    desktop ? false,
    nau_exporter_port ? 9001,
  }: {
    pkgs,
    lib,
    ...
  }: {
    # System Packages
    environment.systemPackages = [
      pkgs.local.nix-auto-update
    ];
    # Checks for updates. If found, applies updates to the host & users home
    # directories (with home-manager). Then notifies the user on the desktop
    # that an update was applied.
    systemd.services.nix-auto-update = {
      description = "Keeps the system up-to-date";
      environment = {
        # Need to help the systemd service find the binaries
        # we're using such as:
        #
        # - nix
        # - nixos-rebuild
        # - sudo
        #
        # We will use an absolute path for home-manager because
        # that binary is usually in user home directories.
        PATH = lib.mkForce "/run/current-system/sw/bin:/run/wrappers/bin";
      };
      serviceConfig = let
        cli_flag =
          if desktop
          then "--boot"
          else "";
      in {
        Type = "oneshot";
        ExecStart = "${pkgs.local.nix-auto-update}/bin/nix-auto-update --source https://github.com/TimekillerTK/nix-config --branch dendritic ${cli_flag}";
        User = "root";

        # NOTE: Need to extend the timeout since compiling binaries on some systems
        # during an update can take a while.
        TimeoutStartSec = "30min";
      };
    };
    systemd.timers.nix-auto-update = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*:0/15"; # Run once every 15 minutes
        RandomizedDelaySec = "300"; # Random delay up to 5 minutes
      };
    };

    # For exposing a JSON file with information about last
    # nix-auto-update
    # NOTE: This is NOT secure to be deployed on a NixOS Network
    # Router, it can potentially expose to the internet.
    #
    # So... don't use it outside the LAN.
    services.static-web-server = {
      enable = true;
      root = "/var/lib/nix-auto-update";
      listen = "[::]:${toString nau_exporter_port}";
      configuration.general.directory-listing = false;
    };
    networking.firewall.allowedTCPPorts = [nau_exporter_port];
  };
}
