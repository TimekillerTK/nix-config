{
  flake.modules.nixos.incus = {
    pkgs,
    ...
  }: {
    virtualisation.incus = {
      enable = true;
      ui.enable = true;
    };

    networking.firewall.allowedTCPPorts = [ 8443 ];
  };
}
