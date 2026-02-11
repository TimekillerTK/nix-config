{inputs, ...}: {
  # Base things every single host needs, regardless whether it's a custom server or a
  # desktop
  flake.modules.nixos.system-base = {
    imports = [
      inputs.self.modules.nixos.locale
      inputs.self.modules.generic.nix-settings
    ];
    nixpkgs.config.allowUnfree = true;

    # Adding custom homelab CA root cert
    security.pki.certificateFiles = [
      ../features/root-ca.pem
    ];

    # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
    system.stateVersion = "25.11";
  };
}
