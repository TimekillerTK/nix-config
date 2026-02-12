{
  flake.modules.nixos.bb = {pkgs, ...}: {
    # Configure your system-wide user settings (groups, etc), add more users as needed.
    users.users = {
      bb = {
        isNormalUser = true;
        shell = pkgs.zsh;
        initialPassword = "Hello123!";
        extraGroups = ["networkmanager" "wheel"];
        openssh.authorizedKeys.keys = [
          (builtins.readFile ../../ssh_keys/anya.pub)
          (builtins.readFile ../../ssh_keys/beltanimal.pub)
          (builtins.readFile ../../ssh_keys/mbp.pub)
          (builtins.readFile ../../ssh_keys/hummingbird.pub)
        ];
      };
    };
  };
}
