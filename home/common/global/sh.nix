{ config, pkgs, outputs, ... }:

let
  myAliases = {
    # Replacements for some GNU Utils
    top = "${pkgs.bottom}/bin/btm";
    htop = "${pkgs.bottom}/bin/btm";
    ls = "${pkgs.eza}/bin/eza --icons -F --group-directories-first --git";
    lt = "${pkgs.unstable.eza}/bin/eza --tree --level=2 --long --icons --git";
    cat = "${pkgs.bat}/bin/bat -pp";
    du = "${pkgs.du-dust}/bin/dust";
    df = "${pkgs.unstable.duf}/bin/duf";
    grep = "${pkgs.ripgrep}/bin/rg";
    rg = "${pkgs.unstable.ripgrep}/bin/rg";
    vi = "${pkgs.vim}/bin/vim";
    cd = "z";   # zoxide
    cdi = "zi"; # zoxide

    # My custom Aliases
    ll = "ls -la";
  };

  myEnvVars = {
    EDITOR = "vim";
  };
in
{
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
    initExtra = ''
      # For Zellij
      eval "$(${pkgs.zellij}/bin/zellij setup --generate-auto-start zsh)"
    '';
  };
}