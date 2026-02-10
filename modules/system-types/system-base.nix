{inputs, ...}: {
  # Base things every single host needs, regardless whether it's a custom server or a
  # desktop
  flake.modules.nixos.system-base = {
    imports = with inputs.self.modules.nixos; [
      locale
      nix-settings
    ];
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "25.11";
  };
}
