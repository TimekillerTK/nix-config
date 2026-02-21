{
  flake.modules.nixos.astra = {pkgs, ...}: {
    # Configure your system-wide user settings (groups, etc), add more users as needed.
    users.users = {
      astra = {
        isNormalUser = true;
        shell = pkgs.zsh;
        initialPassword = "Hello123!";
        extraGroups = ["networkmanager" "wheel"];
        openssh.authorizedKeys.keys = [
          (builtins.readFile ../../pub_keys/anya.pub)
          (builtins.readFile ../../pub_keys/beltanimal.pub)
          (builtins.readFile ../../pub_keys/mbp.pub)
          (builtins.readFile ../../pub_keys/hummingbird.pub)
        ];
      };
    };

    # Passwordless Sudo
    security.sudo.extraRules = [
      {
        users = ["astra"];
        commands = [
          {
            command = "ALL";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };
}
