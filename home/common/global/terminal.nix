{ pkgs, username, ... }:
{
  # Alacritty Config (Fast GPU-Accelerated Terminal)
  programs.alacritty = {
    enable = true;
    settings = {
      window.decorations = "None";
      window.opacity = 0.85;
      font.normal.family = "CaskaydiaCove Nerd Font Mono";
      font.normal.style = "Regular";
      font.size = 11.0;
      terminal.shell.program = "${pkgs.unstable.zellij}/bin/zellij";
      terminal.shell.args = ["attach" "--create" username];
      keyboard.bindings = [
        { key = "F";      mods = "Control";       mode = "~Search";     action = "SearchForward"; }
      ];
    };
  };

  # Zellij config
  programs.zellij = {
    enable = true;
    package = pkgs.unstable.zellij;
  };

  # TODO: Later when needed
  # # Config file for Zellij
  # home.file = {
    # ".config/zellij/config.kdl".source = ../../../dotfiles/zellij/config.kdl;
  # };

}
