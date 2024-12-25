{ ... }:
{
  sops.secrets.tailscale = { };

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
