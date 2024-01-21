{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd
    inputs.vscode-server.nixosModules.default

    # Generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix 

    # Others
    ../common/nix
  ];

  nixpkgs = {
    overlays = [
      # Flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.other-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    config = {
      allowUnfree = true;
    };
  };

  boot.loader.grub = {
    # efiSupport = true;
    # efiInstallAsRemovable = true;
    devices = [ "/dev/sda" ];
  };

  # VS Code Server Module (for VS Code Remote)
  services.vscode-server.enable = true;

  networking.hostName = "nix-test";

  # Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    tk = {
      initialPassword = "Hello123!";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        (builtins.readFile ../common/ssh/mbp.pub)
        (builtins.readFile ../common/ssh/anya.pub)
      ];
      extraGroups = ["wheel"];
    };
  };

  # SSH Config
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # System Packages
  environment.systemPackages = [
    # pkgs.spaget # Custom written package
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
