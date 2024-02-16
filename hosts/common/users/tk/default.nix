{ pkgs, lib, ... }:
{
  # Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    tk = {
      isNormalUser = true;
      shell = pkgs.zsh;
      initialPassword = "Hello123!";
      extraGroups = [ "networkmanager" "wheel" ];
      openssh.authorizedKeys.keys = [
        (builtins.readFile ./mbp.pub)
        (builtins.readFile ./anya.pub)
        (builtins.readFile ./win_laptop.pub)
      ];
    };
  };

  # Passwordless Sudo
  security.sudo.extraRules = [
    {
      users = ["tk"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}