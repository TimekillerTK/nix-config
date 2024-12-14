# This file defines overlays
{inputs, ...}: {

  # This one brings our custom packages from the 'pkgs' directory
  additions = final: prev: import ../pkgs {pkgs = final;};

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through -> pkgs.unstable / pkgs.v2305
  other-packages = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
    v2311 = import inputs.nixpkgs-v2311 {
      system = final.system;
      config.allowUnfree = true;
    };
    v2405 = import inputs.nixpkgs-v2405 {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://wiki.nixos.org/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

}
