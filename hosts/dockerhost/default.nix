{
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    # Required for VS Code Remote
    inputs.vscode-server.nixosModules.default

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

  # WIP!
  boot.loader.grub = {
    # efiSupport = true;
    # efiInstallAsRemovable = true;
    devices = [ "/dev/sda" ];
  };

  # use default bash
  users.users.tk.shell = lib.mkForce pkgs.bash;

  # VS Code Server Module (for VS Code Remote)
  services.vscode-server.enable = true;

  # Hostname & Network Manager
  networking.hostName = "dev-dockerhost";
  networking.networkmanager.enable = true;

  # System Packages
  environment.systemPackages = with pkgs; [
    vim
    arion
    docker-client
  ];

  # Enable podman virtualization
  virtualisation.docker.enable = false;
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerSocket.enable = true;

  # The option definition `virtualisation.podman.defaultNetwork.dnsname' in 
  # `/nix/store/.../hosts/dockerhost' no longer has any effect; please remove it.
  # Use virtualisation.podman.defaultNetwork.settings.dns_enabled instead.
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;

  # Use your username instead of `myuser`
  users.extraUsers.tk.extraGroups = ["podman"];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
