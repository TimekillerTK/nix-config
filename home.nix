{ config, pkgs, inputs, vscode-pkgs, ... }:

{
  imports = [
    ./sh.nix
    inputs.plasma-manager.homeManagerModules.plasma-manager
    # inputs.sops-nix.homeManagerModule
  ];

  # Git Config
  programs.git = {
    enable = true;
    userName = "TimekillerTK";
    userEmail = "erwartungen@protonmail.com";
  }; 

  # Allow unfree packages (Home Manager)
  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    username = "tk";
    stateVersion = "23.11"; # Please read the comment before changing.
    homeDirectory = "/home/tk";
    packages = with pkgs; [
      
      # CLI
      unstable.eza     # ls replacement
      ripgrep          # grep replacement
      du-dust          # du replacement
      bat              # cat replacement
      tdrop            # WM-Independent Dropdown Creator (terminal)
      htop             # better top
      sops             # secrets management 
      unstable.awscli2 # AWS CLI

      # Desktop
      # rustdesk         # TeamViewer alternative
      # discord
      # slack




      # Fonts
      (nerdfonts.override { fonts = [ "CascadiaCode" ]; }) # only 1 font
    ];
  };

  # Enable managing fonts via Home Manager
  fonts.fontconfig.enable = true;

  # Alacritty Config (Fast GPU-Accelerated Terminal)
  programs.alacritty = {
    enable = true;
    settings = {
      window.decorations = "None"; # buttonless on MacOS
      window.opacity = 0.85;
      font.normal.family = "CaskaydiaCove Nerd Font Mono";
      font.normal.style = "Regular";
      font.size = 14.0;
      shell.program = "/home/tk/.nix-profile/bin/tmux";
      shell.args = [ "new-session" "-A" "-s" "general" ];
      key_bindings = [
        { key = "F";      mods = "Control";       mode = "~Search";     action = "SearchForward"; }
        # Rebind open to Ctrl+T
        { key = "T";      mods = "Control|Shift";                       chars = "\\x02\\x63";     } # open tab
        { key = "W";      mods = "Control";                             chars = "\\x02\\x26";     } # close tab
        { key = "Key1";   mods = "Control";                             chars = "\\x02\\x31";     } # jump to tab 1
        { key = "Key2";   mods = "Control";                             chars = "\\x02\\x32";     } # jump to tab 2
        { key = "Key3";   mods = "Control";                             chars = "\\x02\\x33";     } # jump to tab 3
        { key = "Key4";   mods = "Control";                             chars = "\\x02\\x34";     } # jump to tab 4
        { key = "Key5";   mods = "Control";                             chars = "\\x02\\x35";     } # jump to tab 5
        { key = "Key6";   mods = "Control";                             chars = "\\x02\\x36";     } # jump to tab 6
        { key = "Key7";   mods = "Control";                             chars = "\\x02\\x37";     } # jump to tab 7
        { key = "Key8";   mods = "Control";                             chars = "\\x02\\x38";     } # jump to tab 8
        { key = "Key9";   mods = "Control";                             chars = "\\x02\\x39";     } # jump to tab 9
        { key = "Key0";   mods = "Control";                             chars = "\\x02\\x30";     } # jump to tab 0
      ];
    };
  };

  # tmux config (Terminal Multiplexer)
  programs.tmux = {
    enable = true;
    baseIndex = 1; # tmux tabs start at 1
    extraConfig = "set -g mouse on"; # mouse scroll up/down
  };

  # Enable Starship for Terminal
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # VS Code 
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;

    # To find an extension, click on extension in VS Code, it will open a link or use nix repl
    extensions = with vscode-pkgs.vscode-marketplace; [

      # Rust
      rust-lang.rust-analyzer

      # Python
      ms-python.python
      ms-python.vscode-pylance
      ms-python.black-formatter
      ms-python.isort

      # Powershell
      ms-vscode.powershell

      # Gitlab
      gitlab.gitlab-workflow

      # AWS
      amazonwebservices.aws-toolkit-vscode

      # Markdown
      yzhang.markdown-all-in-one
      davidanson.vscode-markdownlint

      # Other
      jnoortheen.nix-ide          # Nix Language
      mechatroner.rainbow-csv     # CSV 
      redhat.vscode-yaml          # YAML
      tamasfe.even-better-toml    # TOML
      donjayamanne.githistory     # git history
      ms-vscode-remote.remote-ssh
    ];

    keybindings = [

      # Enable Custom Keybinds
      { key = "ctrl+alt+up"; command = "editor.action.insertCursorAbove"; when = "editorTextFocus"; }
      { key = "ctrl+alt+down"; command = "editor.action.insertCursorBelow"; when = "editorTextFocus"; }
      { key = "shift+alt+up"; command = "editor.action.copyLinesUpAction"; when = "editorTextFocus && !editorReadonly"; }
      { key = "shift+alt+down"; command = "editor.action.copyLinesDownAction"; when = "editorTextFocus && !editorReadonly"; }

      # Disable Default Keybinds
      { key = "ctrl+shift+up"; command = "-editor.action.insertCursorAbove"; when = "editorTextFocus"; }
      { key = "ctrl+shift+down"; command = "-editor.action.insertCursorBelow"; when = "editorTextFocus"; }
      { key = "ctrl+shift+alt+up"; command = "-editor.action.copyLinesUpAction"; when = "editorTextFocus && !editorReadonly"; }
      { key = "ctrl+shift+alt+down"; command = "-editor.action.copyLinesDownAction"; when = "editorTextFocus && !editorReadonly"; }
    
    ];

    userSettings = { 
      "files.autoSave" = "afterDelay"; 
      "editor.fontFamily" = "'CaskaydiaCove Nerd Font', 'monospace', monospace";
    };
     
  };

  # KDE Plasma Config - https://github.com/pjones/plasma-manager
  # Run to get current KDE config: 
  # > nix run github:pjones/plasma-manager
  programs.plasma = {
    enable = true;
    workspace = {
      # NOTE: These theme/colour changes don't 100% work!
      theme = "breeze-dark";
      colorscheme = "BreezeDark";
    };
    shortcuts = {
      "tdrop.desktop"."_launch" = "Alt+Space";
      "org.kde.krunner.desktop"."_launch" = ["Ctrl+Space" "Alt+F2" "Search"];
    };
    configFile = {
      "kglobalshortcutsrc"."tdrop.desktop"."_k_friendly_name" = "tdrop -a alacritty";
    };
  };
  
  #########################
  # Testing Section below #
  #########################
  # -------------------------------------------#
  home.file."/home/tk/Btestfile".text = ''
    SOME FILE WITH SOME CONTENT
  '';
  home.file."/home/tk/Ctestfile".source = ./Ctestfile;
  # -------------------------------------------#

}
