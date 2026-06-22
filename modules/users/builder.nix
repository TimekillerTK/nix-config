{...}: {
  # Builder user intended for machines where you can send remote builds to
  flake.modules.nixos.builder = {
    users.users.builder = {
      isSystemUser = true;
      extraGroups = ["wheel"]; # FIXME: probably too board, check later
      openssh.authorizedKeys.keys = [
        (builtins.readFile ../../pub_keys/rpi.pub)
      ];
    };
    nix.settings.trusted-users = ["root" "builder"];
  };
}
