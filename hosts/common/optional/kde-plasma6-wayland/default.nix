{ pkgs, ... }:
# Settings for KDE Plasma 6 environment for Wayland with Pipewire
# NOTE: Works on 24.11
# BUG?: Application Menu Does not Refresh List when Applications added/removed
# -> https://github.com/NixOS/nixpkgs/issues/292632
{

  # For USB Blu-Ray/DVD Players
  boot.kernelModules = [ "sg" ];

  # Enable the Wayland display server
  services.xserver.enable = true;  # Still needed for SDDM

  # Enable the KDE Plasma Desktop Environment
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # For KDE Plasma 6, the defaults have changed.
  # KDE Plasma 6 runs on Wayland with the default session set
  # to 'plasma'. If you want to use the X11 session as your
  # default session, change it to 'plasmax11'.
  services.displayManager.defaultSession = "plasma";

  # Enable KDE Connect
  programs.kdeconnect.enable = true;

  # Configure keymap in Wayland
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable colour management daemon, and add KDE options
  services.colord.enable = true;
  environment.systemPackages = with pkgs.kdePackages; [
    colord-kde
    kcolorchooser
    kcalc
  ];

  # Enable sound with pipewire
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable CUPS to print documents
  services.printing.enable = true;
  services.printing.drivers = [
    pkgs.brother-mfcl3750cdw.driver
    pkgs.brother-mfcl3750cdw.cupswrapper
  ];

  # Fix for allowing user to login to GUI session with ZSH as default shell
  # - users.users.user.shell is set to zsh, but
  #      programs.zsh.enable is not true. This will cause the zsh
  #      shell to lack the basic nix directories in its PATH and might make
  #      logging in as that user impossible. You can fix it with:
  #      programs.zsh.enable = true;
  programs.zsh.enable = true;

}
