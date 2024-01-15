{ config, lib, pkgs, ... }:
let
  newscript = pkgs.writeScriptBin "newscript" ''
#!${pkgs.stdenv.shell}
echo "HELLO WORLD BLABLA"
'';

in
{
  environment.systemPackages = [ 
    newscript
  ];
}
