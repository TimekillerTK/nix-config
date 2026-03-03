{
  inputs,
  self,
  lib,
  ...
}: {
  flake.modules = lib.mkMerge [
    (self.factory.user "tk" true)
    {
      nixos.tk = {
        users.users.tk = {
          extraGroups = ["networkmanager"];
          openssh.authorizedKeys.keys = [
            (builtins.readFile ../../pub_keys/anya.pub)
            (builtins.readFile ../../pub_keys/beltanimal.pub)
            (builtins.readFile ../../pub_keys/mbp.pub)
            (builtins.readFile ../../pub_keys/hummingbird.pub)
          ];
        };
      };
      homeManager.tk = {pkgs, ...}: {
        imports = [
          inputs.self.modules.homeManager.system-cli
        ];
        home.username = "tk";

      };
    }
  ];
}
