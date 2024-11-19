{ pkgs, lib, ... }:
{
  # Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    bb = {
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
}
