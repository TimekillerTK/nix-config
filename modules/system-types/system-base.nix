{inputs, ...}: {
  # Base things every single host needs, regardless whether it's a custom server or a
  # desktop
  flake.modules.nixos.system-base = {
    imports = [
      inputs.self.modules.nixos.locale
      inputs.self.modules.generic.nix-settings
      inputs.self.modules.generic.unstable
      inputs.self.modules.generic.local-pkgs
    ];
    nixpkgs.config.allowUnfree = true;

    # Adding custom homelab CA root cert
    security.pki.certificateFiles = [
      ../../pub_keys/root-ca.pem
    ];

    # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
    system.stateVersion = "23.11";
  };

  flake.modules.homeManager.system-base = {config, ...}: {
    home.homeDirectory = "/home/${config.home.username}";
    # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "23.11";
  };
}
