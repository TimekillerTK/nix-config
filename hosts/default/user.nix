{ lib, config, pkgs, ... }:

let
  cfg = config.desktop-user;
in
{
  options.desktop-user = {
    enable
      = lib.mkEnableOption "enable user module";
    
    userName = lib.mkOption {
      default = "nixos_user";
      description = ''
        username
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.userName} = {
      isNormalUser = true;
      initialPassword = "12345";
      description = "Regular User";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [
        firefox
        kate
        vim
        git
      ];
      shell = pkgs.bash;
    };
  };
}
