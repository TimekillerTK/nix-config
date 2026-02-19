{
  # For defining the shell
  config.flake.factory.homeManager.shell = {username}: {pkgs, ...}: let
    myAliases = {
      # Replacements for some GNU Utils
      top = "${pkgs.bottom}/bin/btm";
      htop = "${pkgs.bottom}/bin/btm";
      ls = "${pkgs.eza}/bin/eza --icons -F --group-directories-first --git --group";
      lt = "${pkgs.unstable.eza}/bin/eza --tree --level=2 --long --icons --git";
      cat = "${pkgs.bat}/bin/bat -pp";
      du = "${pkgs.unstable.dust}/bin/dust";
      df = "${pkgs.unstable.duf}/bin/duf";
      grep = "${pkgs.ripgrep}/bin/rg";
      rg = "${pkgs.unstable.ripgrep}/bin/rg";
      vi = "${pkgs.vim}/bin/vim";
      cd = "z"; # zoxide
      cdi = "zi"; # zoxide

      # My custom Aliases
      ll = "ls -la";
    };

    # For when it's needed
    myEnvVars = {};
  in {
    home-manager.users."${username}" = {
      # Environment Variables
      home.sessionVariables = myEnvVars;

      # Zoxide configuration (cd replacement)
      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
        package = pkgs.unstable.zoxide;
      };

      programs.zsh = {
        enable = true;
        shellAliases = myAliases;

        # Added to end of ~/.zshrc
        initContent = ''
          # These fix zsh CTRL+LEFT & CTRL+RIGHT keybindings for
          # jumping by word
          bindkey '^[[1;5C' forward-word
          bindkey '^[[1;5D' backward-word
        '';

        # Added to the end of ~/.zshenv
        envExtra = ''
          # Needed for Granted: https://docs.commonfate.io/granted/internals/shell-alias
          alias assume="source /home/${username}/.nix-profile/bin/assume"
        '';
      };
    };
  };
}
