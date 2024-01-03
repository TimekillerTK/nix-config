# This file defines overlays
{inputs, ...}: {

  # This one brings our custom packages from the pkgs directory
  additions = final: prev: import ../pkgs {pkgs = final;};

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through -> pkgs.unstable
  other-packages = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
    v2305 = import inputs.nixpkgs-v2305 {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

}
