{
  pkgs,
  username,
  ...
}: let
  # Custom Alacritty Terminal dropdown script, needed to use it for
  # proper Wayland Copy/Paste support with Helix IDE, alternative
  # used 'tdrop' was X11/XWayland
  alacritty_dropdown = pkgs.writeShellScriptBin "alacritty-dropdown" ''
    export KDOTOOL="${pkgs.kdotool}/bin/kdotool"
    export ALACRITTY="${pkgs.alacritty}/bin/alacritty"
    ${builtins.readFile ./alacritty-dropdown.sh}
  '';
in {
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
        {
          key = "F";
          mods = "Control";
          mode = "~Search";
          action = "SearchForward";
        }
      ];
    };
  };

  home.packages = [
    alacritty_dropdown
  ];

  # Zellij config
  programs.zellij = {
    enable = true;
    package = pkgs.unstable.zellij;

    # This option doesn't work that well.... need an alternative
    # settings = {
    #   copy_clipboard = "primary";
    # };
  };

  # TODO: Later when needed
  # # Config file for Zellij
  # home.file = {
  # ".config/zellij/config.kdl".source = ../../../dotfiles/zellij/config.kdl;
  # };
}
