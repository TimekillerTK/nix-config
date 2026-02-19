{
  inputs,
  self,
  lib,
  ...
}: {
  flake.modules = lib.mkMerge [
    (self.factory.user "bb" true)
    {
      nixos.bb = {
        # Configure your system-wide user settings (groups, etc), add more users as needed.
        users.users = {
          bb = {
            extraGroups = ["networkmanager"];
            openssh.authorizedKeys.keys = [
              (builtins.readFile ../../ssh_keys/anya.pub)
              (builtins.readFile ../../ssh_keys/beltanimal.pub)
              (builtins.readFile ../../ssh_keys/mbp.pub)
              (builtins.readFile ../../ssh_keys/hummingbird.pub)
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
