{pkgs, ...}:
# Settings for KDE Plasma 6 environment for Wayland with Pipewire
# NOTE: Works on 24.11
# -> https://github.com/NixOS/nixpkgs/issues/292632
{
  # For USB Blu-Ray/DVD Players
  boot.kernelModules = ["sg"];

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
        # settings = {
        #   "org.gnome.desktop.session" = {
        #     "idle-delay" = 300; # screen blanks/turns off after 5 mins, no suspend
        #   };
        #   "org.gnome.settings-daemon.plugins.power" = {
        #     "sleep-inactive-ac-type" = "nothing";
        #     "sleep-inactive-ac-timeout" = 0;
        #     "sleep-inactive-battery-type" = "nothing";
        #     "sleep-inactive-battery-timeout" = 0;
        #   };
        # };
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
