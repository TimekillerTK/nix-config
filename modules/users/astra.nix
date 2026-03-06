{
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

        programs.git.settings = {
          user.name = "Astram00n";
          user.email = "39217853+Astram00n@users.noreply.github.com";
          core.excludesfile = "/home/astra/.config/git/ignore";
        };

        programs.zsh.shellAliases = {
          # VS Code CAN be absent or present, so we do not use a nix store path
          # but we still want to ensure we can still run it with `vscode`.
          vscode = "/home/astra/.nix-profile/bin/code";
        };
      };
    }
  ];
}
