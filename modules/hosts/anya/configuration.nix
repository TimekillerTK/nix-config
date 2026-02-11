{inputs, ...}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "anya";
  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "anya";

  flake.modules.nixos.anya = {pkgs, ...}: {
    imports = [
      # Filesystems on this host are defined with disko
      inputs.disko.nixosModules.default
      ./_disko.nix

      inputs.self.modules.nixos.system-base

      inputs.self.modules.nixos.secrets
      inputs.self.modules.nixos.zfs
      inputs.self.modules.nixos.bluetooth
      # inputs.self.modules.nixos.flatpak
      # inputs.self.modules.nixos.anyahw

      inputs.self.modules.generic.unstable
      inputs.self.modules.generic.local-pkgs
    ];
    # imports = [
    #   # Required for disk configuration
    #   inputs.disko.nixosModules.default

    #   # Required for nix-flatpak
    #   inputs.nix-flatpak.nixosModules.nix-flatpak

    #   # Disko config
    #   ./disko.nix

    #   # Generated (nixos-generate-config) hardware configuration
    #   ./hardware-configuration.nix

    #   # Repo Modules
    #   ../common/global
    #   ../common/users/tk
    #   ../common/users/bb
    # OK  ../common/optional/sops
    # OK  ../common/optional/zfs
    #   ../common/optional/kde-plasma6-wayland
    #   ../common/optional/input-remapper
    #   ../common/optional/minecraft-server
    #   ../common/optional/mount-media
    #   ../common/optional/mount-important
    # OK  ../common/optional/disable-bt-handsfree
    #   ../common/optional/home-assistant-remote
    #   ../common/optional/nix-auto-update
    #   ../common/optional/prometheus-node-desktop
    #   # ../common/optional/tailscale-client
    # ];

    # # Overlays
    # nixpkgs = {
    #   overlays = [
    #     outputs.overlays.additions
    #     outputs.overlays.modifications
    #     outputs.overlays.other-packages
    #   ];
    #   config = {
    #     allowUnfree = true;
    #   };
    # };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";

    # # Install Logseq
    # services.flatpak.packages = [
    #   # Temporarily installed due to
    #   # https://github.com/logseq/logseq/issues/10851
    #   "com.logseq.Logseq"
    # ];

    # Actual SOPS keys
    sops.secrets.smbcred = {
      sopsFile = ../../../secrets/default.yml;
    };

    # Add printer autodiscovery
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # For game streaming
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
      openFirewall = true;
    };

    # Steam
    programs.steam.enable = true;

    # Hostname & Network Manager
    networking.hostName = "anya";
    networking.networkmanager = {
      enable = true;
    };

    # Enable QMK support (Keychron)
    hardware.keyboard.qmk.enable = true;
    hardware.keyboard.qmk.keychronSupport = true;

    # # Docker for when needed
    # virtualisation.docker.enable = true;
    # users.users.tk.extraGroups = lib.mkForce [ "networkmanager" "wheel" "docker" ];

    # TODO: This is for GDM Login Screen settings, should probably be adapted to the KDE plasma
    # module (and Gnome module) as its very specific to those configs.
    systemd.tmpfiles.rules = let
      monitorsXmlContent = builtins.readFile ./anya-monitors.xml;
      monitorsConfig = pkgs.writeText "gdm_monitors.xml" monitorsXmlContent;
    in [
      "L+ /run/gdm/.config/monitors.xml - - - - ${monitorsConfig}"
    ];

    # System Packages
    environment.systemPackages = [
      pkgs.devilutionx # Diablo I & Hellfire (best version)
      pkgs.kdePackages.kdialog # pops up dialogs
    ];

    # Generated with head -c4 /dev/urandom | od -A none -t x4
    networking.hostId = "7d650d06"; # required for ZFS!
  };
}
