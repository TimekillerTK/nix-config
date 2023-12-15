{ config, lib, pkgs, ... }:

let
  cfg = config.services.kdeShortcuts;
in

{
  options.services.kdeShortcuts = {
    enable = lib.mkEnableOption "KDE custom shortcuts";

    shortcut = lib.mkOption {
      type = lib.types.str;
      default = "Alt+S";
      description = "The keyboard shortcut to use.";
    };

    command = lib.mkOption {
      type = lib.types.str;
      default = "echo 'hello world'";
      description = "The command to run when the shortcut is activated.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure KDE to recognize the shortcut.
    # This is a simplified example. You might need to adjust paths or method.
    environment.etc."xdg/kdeglobals".text = lib.mkBefore ''
      [Shortcuts]
      ${cfg.shortcut}=${cfg.command}
    '';
  };
}