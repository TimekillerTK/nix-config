{ pkgs, ... }:
let
  spaget = pkgs.writeScriptBin "spaget" ''
echo "HELLO WORLD FROM MY PACKAGE!!!"
'';
in
{
  environment.systemPackages = [ 
    spaget
  ];  
}