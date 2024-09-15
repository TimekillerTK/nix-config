{ pkgs, lib, ... }:
{
  # Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    astra = {
      isNormalUser = true;
      shell = pkgs.zsh;
      initialPassword = "Hello123!";
      extraGroups = [ "networkmanager" "wheel" ];
      openssh.authorizedKeys.keys = [
        (builtins.readFile ./anya.pub)
        (builtins.readFile ./beltanimal.pub)
        (builtins.readFile ./mbp.pub)
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
}