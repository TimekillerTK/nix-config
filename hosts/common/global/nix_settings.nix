# Common Nix Settings config
{ config, lib, inputs, ... }:
{
  # This will add each flake input as a registry
  # To make nix3 commands consistent with your flake
  nix.registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  nix.nixPath = ["/etc/nix/path"];
  environment.etc =
    lib.mapAttrs'
    (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;

  # Required for deploy-rs if you want to deploy with normal user part of wheel instead of root
  nix.settings.trusted-users = [ "@wheel" ];

  nix.settings = {
    experimental-features = "nix-command flakes"; # enable nix flakes
    auto-optimise-store = true; # Deduplicate and optimize nix store

    # Enabling use of binary cache (Cachix)
    substituters = [
      "https://devenv.cachix.org"
    ];
    trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  # Nix automatic Garbage Collect
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 60d";
  };
}
