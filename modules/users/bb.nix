{
  inputs,
  self,
  lib,
  ...
}: {
  flake.modules = lib.mkMerge [
    (self.factory.user "bb" false)
    {
      nixos.bb = {
        # Configure your system-wide user settings (groups, etc), add more users as needed.
        users.users = {
          bb = {
            extraGroups = ["networkmanager"];
            openssh.authorizedKeys.keys = [
              (builtins.readFile ../../pub_keys/anya.pub)
              (builtins.readFile ../../pub_keys/beltanimal.pub)
              (builtins.readFile ../../pub_keys/mbp.pub)
              (builtins.readFile ../../pub_keys/hummingbird.pub)
            ];
          };
        };
      };
      homeManager.bb = {
        imports = [
          inputs.self.modules.homeManager.system-desktop
        ];
      };
    }
  ];
}
