# Settings for KDE Plasma 6 environment for Wayland with Pipewire
# NOTE: Works on 24.11
# -> https://github.com/NixOS/nixpkgs/issues/292632
{
  flake.modules.nixos.kde-plasma = {pkgs, ...}: {
    # Enable Plasma 6
    services.desktopManager.plasma6.enable = true;

    # Enable the Wayland display server
    services.xserver.enable = true;

    services = {
      displayManager = {
        # For KDE Plasma 6, the defaults have changed.
        # KDE Plasma 6 runs on Wayland with the default session set
        # to 'plasma'. If you want to use the X11 session as your
        # default session, change it to 'plasmax11'.
        defaultSession = "plasma";

        # SDDM doesn't support Wayland well, runs awful even
        # on X11, has glitches and drives me bonkers, so
        # using gdm instead.
        gdm = {
          enable = true;
          autoSuspend = false;
        };
      };
    };

    # Login Screen - Numlock auto "On"
    programs.dconf.profiles.gdm.databases = [
      {
        settings = {
          "org/gnome/desktop/peripherals/keyboard" = {
            "numlock-state" = true;
            "remember-numlock-state" = true;
          };
        };
      }
    ];

    # Enable KDE Connect
    programs.kdeconnect.enable = true;

    # Enable colour management daemon, and add KDE options
    services.colord.enable = true;
    environment.systemPackages = with pkgs.kdePackages; [
      colord-kde
      kcolorchooser
      kcalc
    ];
  };
}
