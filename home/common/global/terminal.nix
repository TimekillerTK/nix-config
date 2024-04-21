{ pkgs, ... }: 
{
  # Alacritty Config (Fast GPU-Accelerated Terminal)
  programs.alacritty = {
    enable = true;
    settings = {
      window.decorations = "None";
      window.opacity = 0.85;
      font.normal.family = "CaskaydiaCove Nerd Font Mono";
      font.normal.style = "Regular";
      font.size = 13.0; 
      shell.program = "${pkgs.tmux}/bin/tmux";
      key_bindings = [
        { key = "F";      mods = "Control";       mode = "~Search";     action = "SearchForward"; }
        { key = "T";      mods = "Control|Shift";                       chars = "\\x02\\x63";     } # open tab
        { key = "W";      mods = "Control|Shift";                       chars = "\\x02\\x26";     } # close tab
        { key = "Left";   mods = "Control|Shift";                       chars = "\\x02\\x70";     } # previous tab
        { key = "Right";  mods = "Control|Shift";                       chars = "\\x02\\x6E";     } # next tab
        { key = "Key1";   mods = "Control|Shift";                       chars = "\\x02\\x31";     } # jump to tab 1
        { key = "Key2";   mods = "Control|Shift";                       chars = "\\x02\\x32";     } # jump to tab 2
        { key = "Key3";   mods = "Control|Shift";                       chars = "\\x02\\x33";     } # jump to tab 3
        { key = "Key4";   mods = "Control|Shift";                       chars = "\\x02\\x34";     } # jump to tab 4
        { key = "Key5";   mods = "Control|Shift";                       chars = "\\x02\\x35";     } # jump to tab 5
        { key = "Key6";   mods = "Control|Shift";                       chars = "\\x02\\x36";     } # jump to tab 6
        { key = "Key7";   mods = "Control|Shift";                       chars = "\\x02\\x37";     } # jump to tab 7
        { key = "Key8";   mods = "Control|Shift";                       chars = "\\x02\\x38";     } # jump to tab 8
        { key = "Key9";   mods = "Control|Shift";                       chars = "\\x02\\x39";     } # jump to tab 9
        { key = "Key0";   mods = "Control|Shift";                       chars = "\\x02\\x30";     } # jump to tab 0
        { key = "Right";  mods = "Control";                             chars = "\\x1BF";         } # jump forward word <- this is busted somehow
        { key = "Left";   mods = "Control";                             chars = "\\x1BB";         } # jump backward word
        # TODO: Rebind ALT+F to a different key in tmux, then use that as the char
        # tmux default ALT+B works but ALT+F is busted!!!
      ];
    };
  };

  # tmux config (Terminal Multiplexer)
  programs.tmux = {
    enable = true;
    baseIndex = 1; # tmux tabs start at 1
    # keyMode = "vi";
    # NOTE: xterm-256color will not work well on Linux ()
    terminal = "screen-256color"; 
    newSession = true; # Required for plugins, otherwise 127 error
    extraConfig = ''
      # Fix ctrl+left/right jump word (???)
      # set-window-option -g xterm-keys on

      # Enable Mouse
      set -g mouse on

      # Bindkeys
      # unbind Left
      # unbind Down
      # unbind Up
      # unbind Right

      # unbind A-f
      # unbind C-Down
      # unbind C-Left
      # unbind C-Right
    '';
    plugins = with pkgs; [
      tmuxPlugins.catppuccin
    ];
  };
}