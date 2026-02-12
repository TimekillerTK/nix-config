{inputs, ...}: {
  # Things which all desktops need
  flake.modules.nixos.system-desktop = {
    imports = [
      inputs.self.modules.nixos.system-base
    ];

    # Default shell used on desktops
    programs.zsh.enable = true;
  };
}
