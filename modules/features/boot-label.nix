{inputs, ...}: {
  # Adds additional information for the boot entries of each NixOS configuration
  # which uses this feature. In this case, we want to add the shortened git SHA
  # for the nix flake of our git configuration
  flake.modules.nixos.boot-label = {config, ...}: {
    system.nixos.label = let
      # rev may be null, if the tree is dirty or not a git repo, so we account for that
      cfgRev = inputs.self.rev or "none";
      cfgShortRev =
        if cfgRev != "none"
        then builtins.substring 0 7 cfgRev
        else "pending";
      # -----------------------------------------------
      # NOTE: Expected format:
      #   label = "25.11.20260413.7e495b7.cfg:pending";
      #   label = "25.11.20260413.7e495b7.cfg:78c536f";
      #
      # Original label has this format:
      #   label = "25.11.20260413.7e495b7";
      # -----------------------------------------------
    in "${config.system.nixos.version}.cfg:${cfgShortRev}";
  };
}
