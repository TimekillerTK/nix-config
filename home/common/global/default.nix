# Common Home Manager config for ALL users
{ ... }:
{
  imports = [
    ./sh.nix
    ./starship.nix
    ./terminal.nix
    ./packages.nix
  ];
}