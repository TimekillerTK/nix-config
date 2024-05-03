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

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Repo Modules
    ../common/global
    ../common/users/tk
    ../common/optional/sops
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

  # SOPS Secrets
  sops.secrets.smbcred = { };

  # Newer LTS Kernel, pinned
  boot.kernelPackages = pkgs.linuxPackages_6_6;
  boot.kernel.sysctl = {
    # NOTE: Required for tailscale relay subnet traffic
    "net.ipv4.conf.all.forwarding" = true;
  };

  # use default bash
  # TODO: find a better way to do this
  users.users.tk.shell = lib.mkForce pkgs.bash;
  users.users.tk.extraGroups = lib.mkForce [ "networkmanager" "wheel" "docker" ];

  # VS Code Server Module (for VS Code Remote) 
  services.vscode-server.enable = true;
 
  # Hostname & Network Manager
  networking.hostName = "dockerhost2024";
  networking.networkmanager.enable = true;

  # System Packages
  environment.systemPackages = with pkgs; [
    vim
  ];

  # Enable Docker
  virtualisation.docker = {
    enable = true;
  };

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
