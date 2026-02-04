{
  description = "Dendritic Pattern Example Test Config";

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

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      flake.nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          self.nixosModules.example
          self.nixosModules.examplehw
        ];
      };

      flake.nixosModules.example = {
        pkgs,
        modulesPath,
        ...
      }: {
        # imports = [
        #   # Include the results of the hardware scan.
        #   ./modules/hardware-configuration.nix
        # ];

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

        # # hardware-configuration.nix --------
        # imports = [
        #   (modulesPath + "/profiles/qemu-guest.nix")
        # ];
        # boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];
        # boot.initrd.kernelModules = [];
        # boot.kernelModules = [];
        # boot.extraModulePackages = [];

        # boot.loader.grub = {
        #   devices = ["/dev/sda"];
        # };

        # fileSystems."/" = {
        #   device = "/dev/disk/by-uuid/0119ab10-0458-4582-bb94-2a67176abcf2";
        #   fsType = "ext4";
        # };

        # swapDevices = [
        #   {device = "/dev/disk/by-uuid/cdf37e71-63a7-473e-9047-ba08b706f6ef";}
        # ];
        # networking.useDHCP = inputs.nixpkgs.lib.mkDefault true;
        # nixpkgs.hostPlatform = inputs.nixpkgs.lib.mkDefault "x86_64-linux";
      };

      flake.nixosModules.examplehw = {
        pkgs,
        modulesPath,
        ...
      }: {
        # hardware-configuration.nix --------
        imports = [
          (modulesPath + "/profiles/qemu-guest.nix")
        ];
        boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];
        boot.initrd.kernelModules = [];
        boot.kernelModules = [];
        boot.extraModulePackages = [];

        boot.loader.grub = {
          devices = ["/dev/sda"];
        };

        fileSystems."/" = {
          device = "/dev/disk/by-uuid/0119ab10-0458-4582-bb94-2a67176abcf2";
          fsType = "ext4";
        };

        swapDevices = [
          {device = "/dev/disk/by-uuid/cdf37e71-63a7-473e-9047-ba08b706f6ef";}
        ];
        networking.useDHCP = inputs.nixpkgs.lib.mkDefault true;
        nixpkgs.hostPlatform = inputs.nixpkgs.lib.mkDefault "x86_64-linux";
      };
    };
}
