{
  inputs,
  outputs,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    # Required for VS Code Remote
    inputs.vscode-server.nixosModules.default

    # Required for disk configuration
    inputs.disko.nixosModules.default

    # NixOS Hardware
    inputs.nixos-hardware.nixosModules.framework-16-7040-amd

    # Required for nix-flatpak
    inputs.nix-flatpak.nixosModules.nix-flatpak

    # Disko config
    ./disko.nix

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk
    ../common/users/astra
    ../common/users/bb
    ../common/optional/sops
    ../common/optional/zfs
    ../common/optional/kde-plasma6-wayland
    ../common/optional/input-remapper
    ../common/optional/mount-media
    ../common/optional/mount-important
    ../common/optional/tailscale-client
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

      # FFXIV Launcher (Game)
      "dev.goats.xivlauncher"
    ];
    uninstallUnmanaged = true; # Manage non-Nix Flatpaks
    update.onActivation = true; # Auto-update on rebuild
  };

  # Firmware Updates
  # https://wiki.nixos.org/wiki/Fwupd
  services.fwupd.enable = true;

  # VS Code Server Module (for VS Code Remote)
  services.vscode-server.enable = true;

  # Actual SOPS keys
  sops.defaultSopsFile = ../common/secrets.yml;
  sops.secrets.smbcred = { };

  # Root Cert
  security.pki.certificateFiles = [
    ../common/root-ca.pem
  ];

  # Bluetooth configuration
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  # Steam
  programs.steam.enable = true;
  environment.sessionVariables = {
    # Fixes steam not picking up correct scaling on framework (?)
    STEAM_FORCE_DESKTOPUI_SCALING = "1.5";
  };

  # SDDM settings for login screen (X11)
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --output DP-4 --mode 1920x1080 --primary
    ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --off
  '';

  # TODO: This conditional doesn't work
  # services.xserver.displayManager.setupCommands = ''
  #   if ${pkgs.xorg.xrandr}/bin/xrandr | grep "DP-4 connected"; then
  #     ${pkgs.xorg.xrandr}/bin/xrandr --output DP-4 --mode 1920x1080 --primary
  #     ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --off
  #   else
  #     ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --auto --primary
  #   fi
  # '';

  # By default laptops with closed lids automatically suspend, which
  # cuts off network connectivity. These changes prevent that on
  # the login screen.
  services.logind = {
    lidSwitch = "lock";
    lidSwitchDocked = "lock";
    lidSwitchExternalPower = "lock";
  };

  # homeassistant user for shutdown via SSH command
  users = {
    groups = { homeassistant = {}; }; # group for homeassistant user (required)
    users = {
      homeassistant = {
        shell = pkgs.zsh;
        isSystemUser = true;
        group = "homeassistant";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPbyRIFCnKqR6DXV2vJLd9s8JRjnvwyKJWw8VevEzfSC" # anya
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPnvtbzHUSBupBNOeoGlyQ5rT2JCd0FxenGVs53t61dw" # homeassistant
        ];
      };
    };
  };

  # Passwordless sudo for specific binaries for the homeassistant user
  # to allow user to shutdown/reboot/poweroff the machine
  security.sudo.extraRules = [
    {
      users = ["homeassistant"];
      commands = [
        { command = "/run/current-system/sw/bin/shutdown"; options = ["NOPASSWD"]; }
        { command = "/run/current-system/sw/bin/reboot"; options = ["NOPASSWD"]; }
        { command = "/run/current-system/sw/bin/poweroff"; options = ["NOPASSWD"]; }
      ];
    }
  ];

  # Hostname & Network Manager
  networking.hostName = "beltanimal";
  networking.networkmanager = {
    enable = true;
  };

  # Generated with head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "75e25de8"; # required for ZFS!

  # System Packages
  environment.systemPackages = with pkgs; [
    kdePackages.kdialog # pops up dialogs
  ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
