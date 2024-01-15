{ inputs, outputs, config, pkgs, ... }:

{
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.other-packages
    ];
    # Allow unfree packages (Home Manager)
    config.allowUnfree = true;
  };

  home.username = outputs.username;
  home.homeDirectory = "/Users/${outputs.username}";

  home.stateVersion = "23.11"; # Please read the comment before changing.

  home.packages = with pkgs; [

    # CLI
    unstable.fd
    unstable.eza
    unstable.bat
    unstable.du-dust
    unstable.ripgrep

    bottom # top/htop replacement
    jq # JSON parsing utility
    sops # Mozilla SOPS
    tldr # man for dummies
    bitwarden-cli
    awscli2 # AWS CLI
    ncurses # for tmux/alacritty (might not be needed)
    cachix # nix binary cache

    # pwsh
    powershell

    # Python
    python310
    unstable.poetry

    # Desktop Applications
    slack
  ];

  # DirEnv configuration
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Starship Prompt for Terminal
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Placeholder";
    userEmail = "placeholderu@example.com";
    ignores = [
      "flake.nix"
      "flake.lock"
      ".envrc"
      ".direnv"
      ".devenv"
    ];
    extraConfig = {
      core.excludesfile = "/Users/${outputs.username}/.config/git/ignore";
    };
  };


  # # Alacritty Config (Fast GPU-Accelerated Terminal)
  programs.alacritty = {
    enable = true;
    settings = {
      window.decorations = "None";
      window.opacity = 0.85;
      font.normal.family = "CaskaydiaCove Nerd Font Mono";
      font.normal.style = "Regular";
      font.size = 18.0;
      shell.program = "/Users/${outputs.username}/.nix-profile/bin/tmux";
      shell.args = [ "new-session" "-A" "-s" "general" ];
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
        { key = "Right";  mods = "Command";                             chars = "\\x1BF";          } # jump forward word
        { key = "Left";   mods = "Command";                             chars = "\\x1BB";          } # jump backward word
      ];
    };
  };

  # tmux config (Terminal Multiplexer)
  programs.tmux = {
    enable = true;
    terminal = "xterm-256color"; # was needed on macOS
    baseIndex = 1; # tmux tabs start at 1
    keyMode = "vi";
    extraConfig = ''
      # Enable Mouse
      set -g mouse on

      # Bind keys Home/End for beginning of line/end of line on MacOS
      bind-key -n Home send Escape "OH"
      bind-key -n End send Escape "OF"
    '';
  };

  home.file = {};
  home.sessionVariables = {};

  programs.home-manager.enable = true;
}
