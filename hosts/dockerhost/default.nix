{
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}: 
{
  imports = [
    # Required for VS Code Remote
    inputs.vscode-server.nixosModules.default

    # SOPS
    inputs.sops-nix.nixosModules.sops

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk

  ];

  # TODO: Add Overlays
  # nixpkgs = {
  #   overlays = [
  #     # Flake exports (from overlays and pkgs dir):
  #     outputs.overlays.additions
  #     outputs.overlays.modifications
  #     outputs.overlays.other-packages

  #     # You can also add overlays exported from other flakes:
  #     # neovim-nightly-overlay.overlays.default

  #     # Or define it inline, for example:
  #     # (final: prev: {
  #     #   hi = final.hello.overrideAttrs (oldAttrs: {
  #     #     patches = [ ./change-hello-to-hi.patch ];
  #     #   });
  #     # })
  #   ];
  #   config = {
  #     allowUnfree = true;
  #   };
  # };
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
  sops.secrets.smbcred = { };
  sops.secrets.tailscale = { };

  # Tailscale
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale";
    extraUpFlags = [
      "--advertise-tags=tag:dockerhost"
      # "--advertise-routes=172.17.0.0/16"
      # "--advertise-exit-node"
    ];
  };

  # WIP!
  boot.loader.grub = {
    # efiSupport = true;
    # efiInstallAsRemovable = true;
    devices = [ "/dev/sda" ];
  };

  # use default bash
  # TODO: find a better way to do this
  users.users.tk.shell = lib.mkForce pkgs.bash;
  users.users.tk.extraGroups = lib.mkForce [ "networkmanager" "wheel" "docker" ];

  # VS Code Server Module (for VS Code Remote) 
  services.vscode-server.enable = true;
 
  # Hostname & Network Manager
  networking.hostName = "dev-dockerhost";
  networking.networkmanager.enable = true;
  networking.hosts = {
    "127.0.0.1" = [ "dev-dockerhost.cyn.local" "dev-torrent.cyn.local" "dev-whoami.cyn.local" "dev-pdf.cyn.local" ];
  };

  # System Packages
  environment.systemPackages = with pkgs; [
    vim
  ];

  # Enable Docker
  virtualisation.docker.enable = true;

  # Mounting fileshare
  fileSystems."/mnt/FreeNAS" = {
    device = "//freenas.cyn.internal/mediasnek2";
    fsType = "cifs";
    # TODO: UID should come from the user dynamically
    # noauto + x-systemd.automount - disables mounting this FS with mount -a & lazily mounts (when first accessed)
    # Remember to run `sudo umount /mnt/FreeNAS` before adding/removing "noauto" + "x-systemd.automount"
    options = [ "credentials=/run/secrets/smbcred" "noserverino" "rw" "_netdev" "uid=1000"] ++ ["noauto" "x-systemd.automount"];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
