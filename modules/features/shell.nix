{
  # For defining the shell and shell cli applications
  flake.modules.homeManager.shell = {pkgs, ...}: let
    myAliases = {
      # Replacements for some GNU Utils
      top = "${pkgs.unstable.bottom}/bin/btm";
      htop = "${pkgs.unstable.bottom}/bin/btm";
      ls = "${pkgs.unstable.eza}/bin/eza --icons -F --group-directories-first --git --group";
      lt = "${pkgs.unstable.eza}/bin/eza --tree --level=2 --long --icons --git";
      cat = "${pkgs.unstable.bat}/bin/bat -pp";
      du = "${pkgs.unstable.dust}/bin/dust";
      df = "${pkgs.unstable.duf}/bin/duf";
      grep = "${pkgs.unstable.ripgrep}/bin/rg";
      rg = "${pkgs.unstable.ripgrep}/bin/rg";
      vi = "${pkgs.unstable.vim}/bin/vim";
      cd = "z"; # zoxide
      cdi = "zi"; # zoxide

      # My custom Aliases
      ll = "ls -la";
    };

    # For when it's needed
    myEnvVars = {};
  in {
    # Environment Variables
    home.sessionVariables = myEnvVars;

    home.packages = with pkgs; [
      # CLI
      unstable.fd # find replacement
      unstable.eza # cd replacement
      unstable.bat # cat replacement
      unstable.dust # du replacement
      unstable.duf # df replacement
      unstable.ripgrep # grep replacement
      unstable.fzf # fuzzy finder
      unstable.bottom # new top

      # Other
      # NOTE: When adding, you might need to force rebuild the font cache with:
      # -> fc-cache -f -v
      nerd-fonts.caskaydia-cove # Windows Terminal Font :)
      tldr # man for dummies
    ];

    # Zoxide configuration (cd replacement)
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      package = pkgs.unstable.zoxide;
    };

    programs.zsh = {
      enable = true;
      shellAliases = myAliases;

      # Added to end of ~/.zshrc before envExtra
      initContent = ''
        # These fix zsh CTRL+LEFT & CTRL+RIGHT keybindings for
        # jumping by word
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word
      '';
    };
  };
}
