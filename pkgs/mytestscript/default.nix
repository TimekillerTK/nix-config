{ config, lib, pkgs, ... }:
let
  ifExists = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  mytestscript = pkgs.writeScriptBin "mytestscript" ''
#!${pkgs.stdenv.shell}
echo "HELLO WORLD FROM MY PACKAGE!!!"
'';
in
{
  environment.systemPackages = [ 
    mytestscript
  ];  
}