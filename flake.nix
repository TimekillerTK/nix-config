{
  description = "Dendritic Pattern Test Config";

  inputs = {
    # Nixpkgs Stable - https://github.com/NixOS/nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # dendritic pattern
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    # # Nixpkgs Unstable
    # nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # # Home Manager - https://github.com/nix-community/home-manager
    # home-manager.url = "github:nix-community/home-manager/release-25.11";
    # home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-darwin"];

      flake.nixosConfigurations.mainmain = {
        inputs,
        self,
        ...
      }:
        inputs.nixpkgs.lib.nixosSystem {
          modules = [
            self.nixosModules.hostArondil
          ];
        };

      flake.nixosModules.mainmain = {pkgs, ...}: {
        imports = [
          # Include the results of the hardware scan.
          ./modules/hardware-configuration.nix
        ];

        nix.settings.experimental-features = ["nix-command" "flakes"];
        networking.hostName = "dendritic"; # Define your hostname.

        # Enable networking
        networking.networkmanager.enable = true;

        # Set your time zone.
        time.timeZone = "Europe/Amsterdam";

        # Select internationalisation properties.
        i18n.defaultLocale = "en_US.UTF-8";

        i18n.extraLocaleSettings = {
          LC_ADDRESS = "nl_NL.UTF-8";
          LC_IDENTIFICATION = "nl_NL.UTF-8";
          LC_MEASUREMENT = "nl_NL.UTF-8";
          LC_MONETARY = "nl_NL.UTF-8";
          LC_NAME = "nl_NL.UTF-8";
          LC_NUMERIC = "nl_NL.UTF-8";
          LC_PAPER = "nl_NL.UTF-8";
          LC_TELEPHONE = "nl_NL.UTF-8";
          LC_TIME = "nl_NL.UTF-8";
        };

        # Configure keymap in X11
        services.xserver.xkb = {
          layout = "us";
          variant = "";
        };

        # Define a user account. Don't forget to set a password with ‘passwd’.
        users.users.tk = {
          isNormalUser = true;
          description = "tk";
          extraGroups = ["networkmanager" "wheel"];
          packages = with pkgs; [];
        };

        # Allow unfree packages
        nixpkgs.config.allowUnfree = true;

        environment.systemPackages = with pkgs; [
          vim
        ];
        # Enable the OpenSSH daemon.
        services.openssh.enable = true;

        system.stateVersion = "25.05";
      };
    };
}
