{ ... }:
{
  sops.secrets.tailscale = { };

  # Stop tailscale starting on boot
  # -> to start run `sudo systemctl start tailscaled`
  systemd.services.tailscaled.enable = false;

  # Tailscale
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale";
    extraUpFlags = [
      "--advertise-tags=tag:usermachine"
      "--accept-routes"
    ];
  };
}
