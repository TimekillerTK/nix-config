{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
  users,
  ...
}: {
  imports = [
    # Required for VS Code Remote
    inputs.vscode-server.nixosModules.default

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

  # VS Code Server Module (for VS Code Remote)
  services.vscode-server.enable = true;

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

  # # Docker for when needed
  # virtualisation.docker.enable = true;
  # users.users.tk.extraGroups = lib.mkForce [ "networkmanager" "wheel" "docker" ];

  # System Packages
  environment.systemPackages = [
    pkgs.devilutionx # Diablo I & Hellfire (best version)
    pkgs.kdePackages.kdialog # pops up dialogs
    pkgs.nix-auto-update # for testing TODO remove later
  ];

  # ------ TODO: Remove later, testing area -----
  systemd.services.nix-auto-update = {
    description = "Checks for updates. If found, applies the updates to the host & users (home manager). Then notifies the user in the GUI that an update was applied.";
    environment = {
      # Need to help the systemd service find the binaries
      # we're using such as:
      #
      # - nix
      # - nixos-rebuild
      # - sudo
      #
      # We will use an absolute path for home-manager because
      # that binary is usually in user home directories.
      PATH = lib.mkForce "/run/current-system/sw/bin:/run/wrappers/bin";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix-auto-update}/bin/nix-auto-update";
      User = "root";
    };
  };
  systemd.timers.nix-auto-update = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*:0/15"; # Run once every 15 minutes
      RandomizedDelaySec = "300"; # Random delay up to 5 minutes
    };
  };
  # ---------------------------------------------

  # Generated with head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "7d650d06"; # required for ZFS!

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
