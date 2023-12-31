{ config, pkgs, ... }:

let
  myAliases = {
    top = "${pkgs.htop}/bin/htop";
    ls = "${pkgs.eza}/bin/eza";
    cat = "${pkgs.bat}/bin/bat";
    du = "${pkgs.du-dust}/bin/dust";
    grep = "${pkgs.ripgrep}/bin/rg";
    ll = "ls -la";
    vi = "${pkgs.vim}/bin/vim";
  };
  myEnvVars = {
    PASTA = "Spaghetti";
    EDITOR = "vim";
    AWS_CONFIG_FILE = "${config.sops.templates."aws_config.toml"}";
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