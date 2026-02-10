{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
  users,
  ...
}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "anya";
  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "anya";

  flake.modules.nixos.anya = {pkgs, ...}: {
    imports = [
      inputs.self.modules.nixos.secrets
      inputs.self.modules.generic.unstable
      inputs.self.modules.generic.local-pkgs
    ];
  };
  imports = [
    # Required for disk configuration
    inputs.disko.nixosModules.default

    # Required for nix-flatpak
    inputs.nix-flatpak.nixosModules.nix-flatpak

    # Disko config
    ./disko.nix

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk
    ../common/users/bb
    ../common/optional/sops
    ../common/optional/zfs
    ../common/optional/kde-plasma6-wayland
    ../common/optional/input-remapper
    ../common/optional/minecraft-server
    ../common/optional/mount-media
    ../common/optional/mount-important
    ../common/optional/disable-bt-handsfree
    ../common/optional/home-assistant-remote
    ../common/optional/nix-auto-update
    ../common/optional/prometheus-node-desktop
    # ../common/optional/tailscale-client
  ];

  # Overlays
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.other-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Enabling Flatpak
  services.flatpak = {
    enable = true;
    packages = [
      # Temporarily installed due to
      # https://github.com/logseq/logseq/issues/10851
      "com.logseq.Logseq"
    ];
    uninstallUnmanaged = true; # Manage non-Nix Flatpaks
    update.onActivation = true; # Auto-update on rebuild
  };

  # Actual SOPS keys
  sops.secrets.smbcred = {};

  # Adding CA root & intermediate certs
  security.pki.certificateFiles = [
    ../common/root-ca.pem
  ];

  # Bluetooth configuration
  hardware.bluetooth = {
    enable = true; # enables support for Bluetooth
    powerOnBoot = true; # powers up the default Bluetooth controller on boot
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
    monitorsXmlContent = builtins.readFile ../common/optional/gnome-wayland/anya-monitors.xml;
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

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
