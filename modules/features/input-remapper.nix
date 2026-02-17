{
  flake.modules.nixos.input-remapper = {pkgs, ...}: {
    # For remapping HIDs
    # TODO: Needs to be started with sudo permissions automatically on login (?)
    services.input-remapper = {
      enable = true;
      package = pkgs.unstable.input-remapper;
    };
  };

  flake.modules.homeManager.input-remapper = {
    home.file = {
      # Keypad Rebind keys
      ".config/input-remapper-2/presets/Razer Razer Nostromo/nostromo.json".source = ../../dotfiles/input-remapper/nostromo.json;
      ".config/input-remapper-2/presets/Razer Razer Tartarus V2/tartarus.json".source = ../../dotfiles/input-remapper/tartarus.json;
    };
  };
}

