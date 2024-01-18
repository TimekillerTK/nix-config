{ config, lib, pkgs, ... }:
let
  mytestscript = pkgs.writeScriptBin "mytestscript" ''
echo "HELLO WORLD FROM MY PACKAGE!!!"
'';
in
{
  environment.systemPackages = [ 
    mytestscript
  ];  
}