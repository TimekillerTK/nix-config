{ inputs, outputs, config, pkgs, ... }:

{
  imports = [

    inputs.plasma-manager.homeManagerModules.plasma-manager
    ./sh.nix
    ./git.nix
    ./terminal.nix
    ./starship.nix
  ];

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
  home.homeDirectory = "/home/${outputs.username}";

  home.packages = with pkgs; [

    # CLI
    unstable.fd
    unstable.eza
    unstable.bat
    unstable.du-dust
    unstable.ripgrep
    unstable.fzf

    bottom # top/htop replacement
    jq # JSON parsing utility
    sops # Mozilla SOPS
    tldr # man for dummies
    awscli2 # AWS CLI
    cachix # nix binary cache

    # pwsh
    powershell
    
    # Python
    python312
    unstable.poetry

    # Desktop Applications
    firefox
    nextcloud-client # Personal cloud
    unstable.element-desktop # Matrix client
    unstable.logseq # Notes
    unstable.vscode-fhs 
    unstable.signal-desktop # Messaging app

    # Other
    (nerdfonts.override { fonts = [ "CascadiaCode" ]; }) # only 1 font
    tdrop # terminal dropdown
  ];

  # KDE Plasma Manager Settings/Shortcuts
  programs.plasma = {
    enable = true;

    shortcuts = {
      # Change default hotkey to CTRL+Space
      "org.kde.krunner.desktop"."_launch" = ["Ctrl+Space" "Alt+F2" "Search"];
      kwin = {
        # Hotkeys to move windows around
        "Window Maximize" = "Meta+Alt+Return";
        "Window Quick Tile Left" = "Meta+Alt+Left";
        "Window Quick Tile Right" = "Meta+Alt+Right";
        "Window Minimize" = "Meta+Alt+Down";

        # Unbind conflicting keybindings
        "Switch Window Left" = [ ];
        "Switch Window Right" = [ ];
        "Switch Window Down" = [ ];
      };
    };

    # TODO: Change to percentage in the future
    # Dropdown Alacritty
    hotkeys.commands."alacritty-dropdown" = {
      name = "Launch Alacritty";
      key = "Alt+Space";
      command = "tdrop -a -h 1296 alacritty"; # <- 1440p 90% Height
    };

    # TODO: Find what is going on here...
    # https://github.com/pjones/plasma-manager/issues/105
    # # Testing...
    # hotkeys.commands."demo-percent-in-command" = {
    #   name = "Demo";
    #   key = "Meta+O";
    #   command = ''konsole -e bash -c "echo 95%% && sleep 2"'';
    # };
  };



  # VS Code Settings files as symlinks
  home.file = {
    ".config/Code/User/keybindings.json".source = ../../dotfiles/vscode/keybindings.json;
    ".config/Code/User/settings.json".source = ../../dotfiles/vscode/settings.json;
  };

  programs.home-manager.enable = true;
  home.stateVersion = "23.11"; # Please read the comment before changing.
}
