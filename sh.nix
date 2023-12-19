{ config, pkgs, ... }:

let 
  myAliases = {
    ll = "ls -la";
  };
  myEnvVars = {
    PASTA = "Spaghetti";
    EDITOR = "vim";
  };
in
{
  # Environment Variables
  home.sessionVariables = myEnvVars;
  
  programs.zsh = {
    enable = true;
    shellAliases = myAliases;
  };
}