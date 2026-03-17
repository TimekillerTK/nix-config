{
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
            (builtins.readFile ../../pub_keys/builder_key.pub)
          ];
        };
      };
      homeManager.tk = {
        imports = [
          # inputs.self.modules.homeManager.example
        ];
        home.username = "tk";

        programs.git.settings = {
          user.name = "TimekillerTK";
          user.email = "38417175+TimekillerTK@users.noreply.github.com";
          core.excludesfile = "/home/tk/.config/git/ignore";
          safe.directory = ["/home/tk/spaghetti"];
        };

        programs.zsh.shellAliases = {
          # VS Code CAN be absent or present, so we do not use a nix store path
          # but we still want to ensure we can still run it with `vscode`.
          vscode = "/home/tk/.nix-profile/bin/code";
        };

        # Added to the end of ~/.zshenv after initContent
        programs.zsh.envExtra = ''
          # Needed for Granted: https://docs.commonfate.io/granted/internals/shell-alias
          alias assume="source /home/tk/.nix-profile/bin/assume"
        '';
      };
    }
  ];
}
