{
  lib,
  pkgs,
  ...
}: {
  systemd.services.nix-auto-update = {
    description = "Checks for updates. If found, applies updates to the host & users home directories (with home-manager). Then notifies the user on the desktop that an update was applied.";
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
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix-auto-update-host}/bin/nix-auto-update --repo https://github.com/TimekillerTK/nix-config";
      User = "root";

      # NOTE: Need a timeout since compiling binaries on some systems
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
}
