{inputs, ...}: {
  # Things which all desktops need
  flake.modules.nixos.system-desktop = {pkgs, ...}: {
    imports = [
      inputs.self.modules.nixos.system-cli
      inputs.self.modules.nixos.kde-plasma
      inputs.self.modules.nixos.input-remapper
      inputs.self.modules.nixos.bluetooth
    ];

    # Configure keymap in Wayland
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # For USB Blu-Ray/DVD Players
    boot.kernelModules = ["sg"];

    # Enable sound with pipewire
    security.rtkit.enable = true;
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # Enable CUPS to print documents
    services.printing.enable = true;
    services.printing.drivers = [
      pkgs.local.brother-mfcl3750cdw-driver
      pkgs.local.brother-mfcl3750cdw-cups
    ];

    # Default shell used on desktops
    programs.zsh.enable = true;
  };
}
