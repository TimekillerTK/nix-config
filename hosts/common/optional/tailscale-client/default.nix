{ ... }:
{
  sops.secrets.tailscale = { };

  # Tailscale
  services.tailscale = {
    enable = false; # Disable tailscale from starting on boot
    authKeyFile = "/run/secrets/tailscale";
    extraUpFlags = [
      "--advertise-tags=tag:usermachine"
      "--accept-routes"
    ];
  };
}
