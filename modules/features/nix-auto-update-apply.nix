{
  flake.modules.nixos.nix-auto-update-apply = {pkgs, ...}: {
    # This is a cron job which runs every X minutes and applies the 'default' NixOS configuration
    # which has been created recently with a `nixos-rebuild boot` command
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
  };
}
