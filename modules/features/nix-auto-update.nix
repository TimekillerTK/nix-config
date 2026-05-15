{
  config.flake.factory.nix-auto-update = {
    desktop ? false,
    nau_exporter_port ? 9001,
  }: {pkgs, ...}: {
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

    # This cron job accounts for the situation, where running a nixos-rebuild switch
    # from the above nix-auto-update systemd unit causes the unit to fail under
    # certain circumstances
    #
    # Instead of running nixos-rebuild switch in a systemd unit, we run `nixos-rebuild boot`
    # in the systemd service, and the `nixos-rebuild switch` in the below cron job.
    services.cron = let
      applyUpdate = pkgs.writeShellApplication {
        name = "nix-auto-update-apply";
        runtimeInputs = [pkgs.nix pkgs.coreutils-full];
        text = ''
          current=$(readlink -f /run/current-system)
          default=$(readlink -f /nix/var/nix/profiles/system)

          echo "----- $(date) -----"
          echo "current is: $current"
          echo "default is: $default"
          if [ "$current" != "$default" ]; then
            echo "Applying update to currently running system..."
            "$default/bin/switch-to-configuration" switch
            echo "Update applied."
          else
            echo "Running system config is the same as default boot config, nothing to do."
          fi
        '';
      };
    in {
      enable = true;
      systemCronJobs = [
        # Run every 5 minutes as root
        "*/5 * * * * root sh -c '${pkgs.lib.getExe applyUpdate} >> /tmp/nix-auto-update-apply-$(date +\\%d-\\%m-\\%Y).log 2>&1'"
      ];
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
