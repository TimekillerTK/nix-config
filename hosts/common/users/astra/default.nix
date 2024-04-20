{ pkgs, lib, ... }:
{
  # Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    astra = {
      isNormalUser = true;
      shell = pkgs.zsh;
      initialPassword = "Hello123!";
      extraGroups = [ "networkmanager" "wheel" ];
    };
  };
}