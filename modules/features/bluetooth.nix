{
  # Bluetooth settings
  flake.modules.nixos.bluetooth = {pkgs, ...}: {
    # -----------------------------------------------------------
    # --- To find more info about your bluetooth audio device ---
    # -----------------------------------------------------------
    #
    # First connect the bluetooth device, next:
    # -> pw-cli ls Device
    #     This will list all device objects, you will see the ID of the bluetooth device
    #     here, like for example 69
    # -> wpctl inspect 69
    #     This will get more information about said device, providing properties such as:
    #     - "device.name"
    #     - "device.product.id"
    #     - "device.vendor.id"
    #
    # -----------------------------------------
    # --- To find where changes are applied ---
    # -----------------------------------------
    #
    # -> systemctl --user status wireplumber.service
    #     Drop-In will have a /nix/store path to overrides.conf. Catting
    #     that file will show `Environment="XDG_DATA_DIRS` which willzfs
    #     point to the config directory.
    # -> cat /nix/store/xxx-wireplumber-configs/share/wireplumber/wireplumber.conf.d/name-of-file.conf
    #     In /nix/store/xxx-wireplumber-configs/share follow the path to
    #     share/wireplumber/wireplumber.conf.d/name-of-file.conf which is the file
    #     that contains the changes.
    # -> systemctl --user restart wireplumber pipewire
    #     Restart the wireplumber/pipewire services to see changes take effect
    # -> pactl list cards | grep -A 20 "bluez_card"
    #     Use this command WHILE HEADSET IS CONNECTED to check active Profiles
    # -----------------------------------------------------------

    # Limit Bluetooth to only use A2DP profiles, disabling Hands-Free mode
    # profiles entirely.
    #
    # Once this nix configuration is applied, don't forget to run:
    # -> systemctl --user restart wireplumber
    services.pipewire.wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-bluez.conf" ''
        monitor.bluez.properties = {
          bluez5.roles = [ a2dp_sink a2dp_source ]
        }
      '')
    ];

    # Bluetooth configuration
    hardware.bluetooth = {
      enable = true; # enables support for Bluetooth
      powerOnBoot = true; # powers up the default Bluetooth controller on boot
    };
  };
}
