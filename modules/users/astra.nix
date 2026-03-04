{
  inputs,
  self,
  lib,
  ...
}: {
  flake.modules = lib.mkMerge [
    (self.factory.user "astra" true)
    {
      nixos.astra = {
        users.users.astra = {
          extraGroups = ["networkmanager"];
          openssh.authorizedKeys.keys = [
            (builtins.readFile ../../pub_keys/anya.pub)
            (builtins.readFile ../../pub_keys/beltanimal.pub)
            (builtins.readFile ../../pub_keys/mbp.pub)
            (builtins.readFile ../../pub_keys/hummingbird.pub)
          ];
        };
      };
      homeManager.astra = {pkgs, ...}: {
        home.username = "astra";

        home.packages = with pkgs; [
          # Desktop Applications
          onedrivegui # OneDrive GUI client
          unstable.spotify # Music Streaming
          brave # Backup Browser
          gimp # Photoshop Alternative
        ];
      };
    }
  ];
}
