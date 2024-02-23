{
  inputs,
  outputs,
  pkgs,
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

  # VS Code Server Module (for VS Code Remote)
  services.vscode-server.enable = true;

  # Enable ZSH
  programs.zsh.enable = true;

  # Hostname & Network Manager
  networking.hostName = "dockerhost";
  networking.networkmanager.enable = true;

  # System Packages
  environment.systemPackages = with pkgs; [
    # pkgs.spaget # Custom package from /pkgs
    # wip
    vim
    tcpdump
    nmap
    dig
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
