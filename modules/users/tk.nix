{
  inputs,
  self,
  lib,
  ...
}: {
  # TODO: This is not needed if we use home-manager as a NixOS module, is it?
  # Maybe need to open an issue if not
  #
  # If your anya setup works fine without it, maybe you should
  # flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "tk";

  flake.modules = lib.mkMerge [
    (self.factory.user "tk" true)
    {
      nixos.tk = {
        users.users.tk = {
          extraGroups = ["networkmanager"];
          openssh.authorizedKeys.keys = [
            (builtins.readFile ../../ssh_keys/anya.pub)
            (builtins.readFile ../../ssh_keys/beltanimal.pub)
            (builtins.readFile ../../ssh_keys/mbp.pub)
            (builtins.readFile ../../ssh_keys/hummingbird.pub)
          ];
        };
      };
      homeManager.tk = {pkgs, ...}: {
        imports = [
          inputs.self.modules.homeManager.system-desktop
        ];
        home.username = "tk";

        # Syncthing (personal cloud)
        services.syncthing = {
          enable = true;
        };

        # DirEnv configuration
        programs.direnv = {
          enable = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
        };
      };
    }
  ];
}
