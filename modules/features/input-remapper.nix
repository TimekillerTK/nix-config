{
  flake.modules.nixos.input-remapper = {pkgs, ...}: {
    # For remapping HIDs
    services.input-remapper = {
      enable = true;
      package = pkgs.unstable.input-remapper;
      # udev rules that trigger autoload when a device
      # is hotplugged after login.
      enableUdevRules = true;
    };
  };

  flake.modules.homeManager.input-remapper = {pkgs, config, ...}: let
    control = "${pkgs.unstable.input-remapper}/bin/input-remapper-control";
    configFile = "${config.home.homeDirectory}/.config/input-remapper-2/config.json";

    setAutoload = pkgs.writeShellScript "input-remapper-set-autoload" ''
      set -eu
      cfg=${pkgs.lib.escapeShellArg configFile}
      mkdir -p "$(dirname "$cfg")"
      [ -f "$cfg" ] || printf '{}' > "$cfg"
      ${pkgs.jq}/bin/jq '.autoload["Razer Razer Tartarus V2"] = "tartarus"' "$cfg" > "$cfg.tmp"
      mv "$cfg.tmp" "$cfg"
    '';
  in {
    home.file = {
      # Keypad Rebind keys
      ".config/input-remapper-2/presets/Razer Razer Nostromo/nostromo.json".source = ../../dotfiles/input-remapper/nostromo.json;
      ".config/input-remapper-2/presets/Razer Razer Tartarus V2/tartarus.json".source = ../../dotfiles/input-remapper/tartarus.json;
    };

    # Apply the configured presets on login. This both sets the daemon's
    # config dir (required for the udev hotplug rule to work later) and
    # injects the preset for devices already connected at boot.
    systemd.user.services.input-remapper-autoload = {
      Unit = {
        Description = "Apply input-remapper presets on login";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = [
          "${setAutoload}"
          "${control} --command stop-all"
          "${control} --command autoload"
        ];
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
