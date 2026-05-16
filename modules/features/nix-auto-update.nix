{inputs, ...}: {
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
      path = [
        pkgs.sudo
        pkgs.nix
        pkgs.nixos-rebuild
        pkgs.home-manager
        pkgs.hostname
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.local.nix-auto-update}/bin/nix-auto-update --source https://github.com/TimekillerTK/nix-config --branch dendritic --boot";
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

    # This import is a cron job which accounts for the situation, where running a `nixos-rebuild
    # switch` (which is what nix-auto-update does) from the above nix-auto-update systemd unit causes
    # the unit to fail under certain circumstances
    #
    # Instead of running `nixos-rebuild switch` in a systemd unit, we run `nixos-rebuild boot`
    # in the systemd service, and the `nixos-rebuild switch` in the below cron job.
    #
    # NOTE: We only want this behaviour on servers, not desktops
    imports = lib.optional (!desktop) inputs.self.modules.nixos.nix-auto-update-apply;

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
