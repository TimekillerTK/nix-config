{
  # For activating a tailscale client locally on a host.
  #
  # NOTE: Will not be active by default, needs to be started
  # when needed (see comments below)
  flake.modules.nixos.tailscale-client = {lib, ...}: {
    sops.secrets.tailscale = {};

    # Stop tailscale starting on boot
    # -> to start run `sudo systemctl start tailscaled`
    systemd.services.tailscaled.enable = lib.mkDefault false;

    # Tailscale
    services.tailscale = {
      enable = true;
      authKeyFile = "/run/secrets/tailscale";
      extraUpFlags = [
        "--advertise-tags=tag:usermachine"
        "--accept-routes"
      ];
    };
  };
}
