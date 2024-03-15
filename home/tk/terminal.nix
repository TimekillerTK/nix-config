{ pkgs, ... }: 
# TODO: This is a MacOS Config!
{
  # Alacritty Config (Fast GPU-Accelerated Terminal)
  programs.alacritty = {
    enable = true;
    settings = {
      window.decorations = "None";
      window.opacity = 0.85;
      font.normal.family = "CaskaydiaCove Nerd Font Mono";
      font.normal.style = "Regular";
      font.size = 18.0; 
      shell.program = "${pkgs.tmux}/bin/tmux";
      key_bindings = [
        { key = "F";      mods = "Command";       mode = "~Search";     action = "SearchForward"; }
        { key = "T";      mods = "Command";                             chars = "\\x02\\x63";     } # open tab
        { key = "W";      mods = "Command";                             chars = "\\x02\\x26";     } # close tab
        { key = "Key1";   mods = "Command";                             chars = "\\x02\\x31";     } # jump to tab 1
        { key = "Key2";   mods = "Command";                             chars = "\\x02\\x32";     } # jump to tab 2
        { key = "Key3";   mods = "Command";                             chars = "\\x02\\x33";     } # jump to tab 3
        { key = "Key4";   mods = "Command";                             chars = "\\x02\\x34";     } # jump to tab 4
        { key = "Key5";   mods = "Command";                             chars = "\\x02\\x35";     } # jump to tab 5
        { key = "Key6";   mods = "Command";                             chars = "\\x02\\x36";     } # jump to tab 6
        { key = "Key7";   mods = "Command";                             chars = "\\x02\\x37";     } # jump to tab 7
        { key = "Key8";   mods = "Command";                             chars = "\\x02\\x38";     } # jump to tab 8
        { key = "Key9";   mods = "Command";                             chars = "\\x02\\x39";     } # jump to tab 9
        { key = "Key0";   mods = "Command";                             chars = "\\x02\\x30";     } # jump to tab 0
        { key = "Right";  mods = "Command";                             chars = "\\x1BF";         } # jump forward word
        { key = "Left";   mods = "Command";                             chars = "\\x1BB";         } # jump backward word
      ];
    };
  };

  # tmux config (Terminal Multiplexer)
  programs.tmux = {
    enable = true;
    terminal = "xterm-256color"; # was needed on macOS
    baseIndex = 1; # tmux tabs start at 1
    keyMode = "vi";
    newSession = true; # Required for plugins, otherwise 127 error
    extraConfig = ''
      # TODO fix colours 
      # set-option -sa terminal-overrides ",xterm*:Tc"
      # set -as terminal-overrides ',alacritty:RGB' # true-color support ????
  
      # Enable Mouse
      set -g mouse on
    '';
    plugins = with pkgs; [
      tmuxPlugins.catppuccin
    ];
  };
}