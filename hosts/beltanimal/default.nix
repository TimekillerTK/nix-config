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

    # SOPS
    inputs.sops-nix.nixosModules.sops

    # Disko config
    ./disko.nix

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk
    ../common/optional/kde-plasma-x11
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
  
  # TODO: Move this and other ZFS options to common/optional/zfs/default.nix later
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.zfs.devNodes = lib.mkDefault "/dev/disk/by-id";

  # Automatic Scrub schedule
  services.zfs.autoScrub = {
    enable = true;
    interval = "Sat, 10:00";
  };

  # Automatic Snapshotting
  # NOTE: To target specific datasets, set in disko.nix!
  services.zfs.autoSnapshot = {
    enable = true;
    flags = "-k -p --utc";
  };

  # VS Code Server Module (for VS Code Remote) 
  services.vscode-server.enable = true;

  # Hostname & Network Manager
  networking.hostName = "beltanimal";
  networking.networkmanager.enable = true;

  # SOPS Secrets
  sops = {
    defaultSopsFile = ./secrets.yml;
    age = {
      # This will automatically import SSH keys as age keys
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      # This is using an age key that is expected to already be in the filesystem
      keyFile = "/var/lib/sops-nix/key.txt";
      # This will generate a new key if the key specified above does not exist
      generateKey = true;
    };
  };

  # Actual SOPS keys
  sops.secrets.snekvirus_wm = { };

  # Wifi connections
  networking.wireless = {
    enable = true;
    environmentFile = "/run/secrets/snekvirus_wm";
    networks = {
      "SnekVirus_WM.exe" = {
        psk = "@SNEKVIRUS_WM@";
      };
    };
  };

  # Generated with head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "75e25de8"; # required for ZFS!

  # System Packages
  environment.systemPackages = with pkgs; [
    vim
  ];

  # TODO: Later
  # # Mounting fileshare
  # fileSystems."/mnt/FreeNAS" = {
  #   device = "//freenas.cyn.internal/mediasnek2";
  #   fsType = "cifs";
  #   # TODO: UID should come from the user dynamically
  #   # noauto + x-systemd.automount - disables mounting this FS with mount -a & lazily mounts (when first accessed)
  #   # Remember to run `sudo umount /mnt/FreeNAS` before adding/removing "noauto" + "x-systemd.automount"
  #   options = [ "credentials=/run/secrets/smbcred" "noserverino" "rw" "_netdev" "uid=1000"] ++ ["noauto" "x-systemd.automount"];
  # };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}