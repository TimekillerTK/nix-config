# Common config for ALL hosts
{...}: {
  imports = [
    ./locale.nix
    ./nix_settings.nix
    ./ssh.nix
    ./packages.nix
  ];
}
