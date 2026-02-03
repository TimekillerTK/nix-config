# Common Home Manager config for ALL users
{...}: {
  imports = [
    ./sh.nix
    ./git.nix
    ./starship.nix
    ./terminal.nix
    ./packages.nix
    ./helix.nix
    ./yazi.nix
  ];
}
