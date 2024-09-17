{ ... }:
# Settings for KDE Plasma 6 environment for Wayland with Pipewire
# NOTE: Works on 24.05
# BUG?: Application Menu Does not Refresh List when Applications added/removed
# -> https://github.com/NixOS/nixpkgs/issues/292632
{


  # Necessary for Wayland to work??
  security.polkit.enable = true;
  services.xserver.enable = true;

  # Wayland Support on Login Screen
  services.displayManager.sddm.wayland.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.desktopManager.plasma6.enable = true;

  # X server for interfacting X11 apps with Wayland protocol
  programs.xwayland.enable = true;

  # For KDE Plasma 6, the defaults have changed.
  # KDE Plasma 6 runs on Wayland with the default session set
  # to 'plasma'. If you want to use the X11 session as your
  # default session, change it to 'plasmax11'.
  services.displayManager.defaultSession = "plasma";

  # Enable KDE Connect
  programs.kdeconnect.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Fix for allowing user to login to GUI session with ZSH as default shell
  # - users.users.user.shell is set to zsh, but
  #      programs.zsh.enable is not true. This will cause the zsh
  #      shell to lack the basic nix directories in its PATH and might make
  #      logging in as that user impossible. You can fix it with:
  #      programs.zsh.enable = true;
  programs.zsh.enable = true;
}
